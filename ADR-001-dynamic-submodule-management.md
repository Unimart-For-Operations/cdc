---
published: false
date: 2026-04-09
type: adr
status: accepted
tags: [architecture, decision, unimart, stockroom, submodules]
---

# ADR: Dynamic Submodule Management in unimart stockroom

## Status

Accepted

## Context

The `unimart stockroom` commands (`status`, `drift`, `update`, `check`) manage git
submodules across the idpbuilder organization. Three problems exist:

1. **Hardcoded submodule list.** `cmd/stockroom_cmds.go` defines
   `var submodules = []string{"cmdr", "idpbuilder", "idpctl", "docs"}`. The new
   `unimart-employee-handbooks/cdc` vault submodule is missing. Every future submodule
   requires a code change, rebuild, and Nix pin bump.

2. **No docs-sync integration.** `stockroom update` pulls submodule changes but does
   not trigger a docs sync. If cmdr's `docs/` changed upstream, the cdc vault is stale
   until the user manually runs `unimart newsstand sync`.

3. **No cdc commit workflow.** After sync, the cdc vault has dirty changes. The user
   must manually `cd` into cdc, commit, push, then update the meta submodule pointer.
   This is error-prone and breaks flow.

## Decision

### 1. Dynamic submodule discovery

Replace the hardcoded `var submodules` slice with a `.gitmodules` parser. All
stockroom commands will call `submodule.ParseGitmodules(orgDir)` at runtime.

A new package `internal/submodule/` encapsulates the `Submodule` type and associated
operations (init check, git execution, display name, doc change detection).

**Submodule struct:**

```go
type Submodule struct {
    Name string // [submodule "name"] section header
    Path string // path = value (relative to org root)
    URL  string // url = value
}
```

**Display name derivation:** `filepath.Base(s.Path)` — so
`unimart-employee-handbooks/cdc` renders as `cdc` in terminal output. Column widths
are computed dynamically from the longest display name.

**Source module detection:** Rather than a second hardcoded list, `IsSourceModule()`
checks if the submodule has a `docs/` directory at its path. This auto-discovers
source repos.

### 2. Docs sync integration in `stockroom update`

After pulling all submodules, `stockroom update` detects whether any source
submodule's `docs/` directory changed between the old and new HEAD:

```
git diff --name-only <oldRef>..<newRef> -- docs/
```

If any source submodule had docs changes, the sync pipeline runs automatically.

The sync logic from `cmd/sync_docs.go` is extracted into a reusable `RunDocsSync()`
function callable from both `newsstand sync` (standalone) and `stockroom update`
(post-pull).

### 3. Auto-commit cdc vault (no push)

After sync, if the cdc vault has changes:

```
git -C <cdc-path> add -A
git -C <cdc-path> commit -s -m "docs: sync from <changed-repos>"
```

The commit uses DCO sign-off (`-s`) and a conventional commit message listing which
source repos triggered the sync.

The cdc vault is NOT pushed — only committed locally. The updated cdc submodule
pointer is staged in meta alongside other submodule pointer updates.

### 4. `stockroom check` contract validation

The check command uses `ParseGitmodules()` for submodule-wide checks (init, remote
URLs, AGENTS.md, Makefile). Source-module-specific checks (docs structure) use
`IsSourceModule()` to auto-filter.

The `sourceModules` hardcoded slice is removed. The `requiredDocDirs` and
`requiredMakeTargets` constants remain — they define the contract, not which modules
are subject to it.

### 5. Constants

The cdc vault relative path is defined once:

```go
const cdcVaultRelPath = "unimart-employee-handbooks/cdc"
```

Used by sync, auto-commit, and any future vault operations.

## Implementation Steps

### Step 1: Create `internal/submodule/submodule.go`

New package providing:

- `Submodule` struct with `Name`, `Path`, `URL` fields
- `ParseGitmodules(orgDir string) ([]Submodule, error)` — reads `.gitmodules`, returns
  all entries. Uses line-by-line parsing (no external dependency). Handles section
  headers `[submodule "name"]` and key-value pairs `path = ...`, `url = ...`.
- `(s Submodule) DisplayName() string` — `filepath.Base(s.Path)`
- `(s Submodule) IsInitialized(orgDir string) bool` — checks `.git` exists at path
- `(s Submodule) Git(orgDir string, args ...string) (string, error)` — runs git in
  submodule dir, returns trimmed stdout (stderr to terminal)
- `(s Submodule) GitSilent(orgDir string, args ...string) (string, error)` — same but
  suppresses stderr
- `(s Submodule) IsSourceModule(orgDir string) bool` — checks if `<path>/docs/` exists
- `(s Submodule) HasDocChanges(orgDir, oldRef, newRef string) bool` — runs
  `git diff --name-only <old>..<new> -- docs/` and returns true if output is non-empty

### Step 2: Rewrite `cmd/stockroom_cmds.go`

- Remove `var submodules` slice
- Remove `isSubmoduleInit()` and `gitInSubmodule()` helper functions (moved to package)
- All three commands call `submodule.ParseGitmodules(dir)` at the top
- Add `maxDisplayWidth()` helper to compute column alignment
- `runStockroomStatus()`: iterate `Submodule` values, use `DisplayName()` for output
- `runStockroomDrift()`: same structural change
- `runStockroomUpdate()`:
  - Record `beforeRef` for each submodule before pulling
  - After pulling, record `afterRef`
  - Collect list of source submodules whose docs changed (via `HasDocChanges()`)
  - If any docs changed:
    - Call `RunDocsSync(dir)` (imported from sync_docs.go)
    - Auto-commit cdc vault with message listing changed repos
  - Stage all submodule paths (dynamic list, not hardcoded)

### Step 3: Update `cmd/stockroom_check.go`

- Replace `submodules` reference with `submodule.ParseGitmodules(dir)`
- Replace `sourceModules` hardcoded slice with filter using `IsSourceModule()`
- Adjust column widths for display names
- The Makefile convention check applies to all submodules that HAVE a Makefile (skip
  gracefully if absent, like cdc which has no Makefile)

### Step 4: Refactor `cmd/sync_docs.go`

- Extract sync execution into `RunDocsSync(orgDir string) error`
- The `newsstand sync` Cobra command calls `RunDocsSync()`
- `stockroom update` imports and calls the same function
- Define `const cdcVaultRelPath = "unimart-employee-handbooks/cdc"`

### Step 5: Tests

- `internal/submodule/submodule_test.go` — test `.gitmodules` parsing with the actual
  org `.gitmodules` content (all 5 submodules, nested path)
- Test `DisplayName()` for both flat and nested paths
- Test `IsSourceModule()` detection

## Consequences

### Positive

- Adding/removing submodules in `.gitmodules` automatically updates all stockroom
  commands. No code changes needed.
- `stockroom update` becomes a single command for the full workflow: pull → sync docs
  → commit vault → stage pointers.
- Display names adapt to any submodule nesting depth.
- Source module detection is automatic (presence of `docs/` directory).

### Negative

- `.gitmodules` parsing adds a runtime dependency on file format stability. Git's
  `.gitmodules` format is stable and well-documented, so this is low risk.
- Auto-commit in cdc means the user must be aware that `stockroom update` creates
  commits in a submodule. The commit message clearly identifies it as automated.
- The `stockroom check` Makefile convention check now runs on all submodules with
  Makefiles, including cdc (which may not have one). Handled by graceful skip.

### Neutral

- `newsstand sync` standalone behavior is unchanged (rsync + frontmatter, no commit).
- The `sourceModules` concept shifts from "hardcoded list" to "has docs/ directory"
  which is semantically equivalent today.
- DCO sign-off on auto-commits uses the user's git config identity.

## References

- `cmd/stockroom_cmds.go` — current hardcoded implementation
- `cmd/stockroom_check.go` — contract validation
- `cmd/sync_docs.go` — sync pipeline CLI
- `internal/platform/detect.go` — command execution utilities
- `.gitmodules` — submodule registry
- `unimart-employee-handbooks/cdc/scripts/sync-docs.sh` — sync pipeline script
