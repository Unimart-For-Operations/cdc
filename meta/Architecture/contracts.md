---
source: meta
synced: 2026-05-31
---
# Cross-Repo Contracts

Formal specifications for interfaces between idpbuilder org repos. Validated by `make ci`.

---

## ORG_DIR Sibling Layout

**Type:** Convention
**Participants:** All repos

Every repo assumes it lives as a sibling of other org repos. The parent directory is discovered via:

```makefile
ORG_DIR := $(shell dirname "$(CURDIR)")
```

**Requirements:**
- All repos must be cloned as siblings under a common parent directory
- The meta repo tracks this layout via git submodules
- No repo may assume absolute paths; always derive relative to `ORG_DIR`

**Validated by:** `make ci` check [1/6] (submodule initialization)

---

## Theme Export

**Type:** Producer-Consumer
**Producer:** `cmdr/scripts/theme-export.sh`
**Consumer:** `internal/theme/theme.go` (in meta repo — unimart) -- `LoadFromOrg()`

### Producer Specification

The script accepts an optional theme name argument (default: `catppuccin-frappe`), evaluates the Nix theme module at `home/04-modules/_shared/theme/default.nix`, and writes JSON to stdout.

**Output schema:**

```json
{
  "name": "string",
  "palette": { "<color-name>": "<hex-string>" },
  "semantic": {
    "fg": "<hex>",
    "bg": "<hex>",
    "bgPanel": "<hex>",
    "accent": "<hex>",
    "warn": "<hex>",
    "ok": "<hex>"
  },
  "terminal": {
    "ansi": { "<ansi-color-name>": "<hex>" }
  },
  "fonts": { "<role>": { "<key>": "<value>" } }
}
```

**Required semantic keys:** `fg`, `bg`, `bgPanel`, `accent`, `warn`, `ok`

**Exit codes:**
- `0` -- success, JSON on stdout
- `2` -- nix not installed

### Consumer Specification

`LoadFromOrg(orgDir string, themeName string)` implements a two-strategy loader:

1. **Script execution** (preferred) -- looks for `<orgDir>/cmdr/scripts/theme-export.sh`, executes it with `themeName` as argument, parses stdout as JSON
2. **Static file fallback** -- checks `<orgDir>/theme.json` then `<orgDir>/cmdr/theme.json`
3. Returns error if neither strategy finds a theme

Parsing uses strict decode (disallow unknown fields) with tolerant fallback (ignore unknown fields) for forward compatibility.

**Validated by:** `make ci` check [6/6] (theme export contract)

---

## Docs Sync Pipeline

**Type:** Two-phase pipeline
**Central script:** `unimart-employee-handbooks/cdc/scripts/sync-docs.sh`
**Trigger:** `unimart newsstand sync`, `make sync-docs`, or post-commit hooks

### Phase 1: Pull (source repos --> cdc vault)

```
<orgDir>/cmdr/docs/        --> <orgDir>/unimart-employee-handbooks/cdc/cmdr/
<orgDir>/idpbuilder/docs/  --> <orgDir>/unimart-employee-handbooks/cdc/idpbuilder/
<orgDir>/docs/             --> <orgDir>/unimart-employee-handbooks/cdc/meta/
```

Uses `rsync -av --delete`. Skips repos whose `docs/` does not exist.

### Phase 2: Frontmatter Injection (cdc copies only)

Invokes `scripts/inject-frontmatter.sh` on each synced vault directory. Injects YAML frontmatter:

| Field | Value | Purpose |
|-------|-------|---------|
| `source` | Repo name (e.g. `cmdr`, `idpbuilder`, `meta`) | Identifies origin repo |
| `synced` | `YYYY-MM-DD` | Last sync date for Dataview |

Idempotent -- skips files already current. Preserves existing frontmatter fields.

### Docs Directory Convention

All source repos must maintain these subdirectories in `docs/`:

- `Contributing/`
- `Getting-Started/`
- `Reference/`

**Validated by:** `make ci` check [4/6] (docs directory structure)

---

## Hook Sharing

**Type:** Shared library
**Provider:** `~/.githooks/lib/sync.sh` via cmdr's Nix-managed git module
**Consumers:** All repos using the global post-commit hook

### Library API

```bash
commit_has_docs_changes
sync_docs_to_cdc
create_commit_log_entry
auto_commit_cdc
```

**Behavior:**
1. Checks the committed file list for `docs/` changes
2. Syncs the committing repo's docs to cdc
3. Creates a commit-log entry when the commit message has an executive summary
4. Auto-commits cdc changes

### Hook Installation Convention

Hooks are deployed globally by `unimart deli switch` through the cmdr git module.

**Validated by:** `make ci` check [5/6] (Makefile convention -- help, hooks, sync-docs)

---

## Makefile Convention

**Type:** Style convention
**Participants:** All repos

Every repo's Makefile must include:

| Element | Requirement |
|---------|-------------|
| `.DEFAULT_GOAL` | `:= help` |
| Color constants | `CYAN`, `GREEN`, `YELLOW`, `RED`, `RESET`, `BOLD` |
| Status indicators | `PASS` ([pass]), `FAIL` ([fail]), `WARN` ([warn]) |
| Silenced commands | Every recipe line prefixed with `@` |
| Help target | Hand-crafted `printf` with bold sections and box-drawing dividers |
| Required targets | `help`, `hooks`, `sync-docs` |
| ORG_DIR | Derived from `dirname $(CURDIR)` |

**Validated by:** `make ci` check [5/6] (Makefile convention)

---

## Upstream Tracking

**Type:** Cherry-pick workflow
**Repo:** idpbuilder
**Upstream:** `cnoe-io/idpbuilder`
**Remote name:** `upstream`

The idpbuilder repo is a private fork that tracks upstream changes via cherry-picking (no merge commits). This maintains a clean commit history while incorporating upstream improvements.

**Requirements:**
- `upstream` remote must point to `https://github.com/cnoe-io/idpbuilder.git` or equivalent
- Changes are cherry-picked, never merged
- Local modifications are kept in separate commits from upstream picks

See [ADR-002](adr/002-cherry-pick-upstream.md) for rationale.
