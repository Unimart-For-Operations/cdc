---
source: meta
synced: 2026-05-31
---
# ADR-005: Git Hook Gate System

**Status:** Accepted
**Date:** 2026-04-10
**Deciders:** cmdr

## Context

The idpbuilder org has 5 active repos (meta, cmdr, idpbuilder, docs, cdc) plus deprecated idpctl, that all need consistent commit hygiene, secret scanning, and documentation sync. Previously:

- A global pre-commit hook (`~/.githooks/pre-commit`) was deployed via cmdr's Nix config, running `nix fmt --check` and `nix flake check`.
- `core.hooksPath = ~/.githooks` was set globally, **shadowing all per-repo `.git/hooks/`**.
- Per-repo hooks installed by `make hooks` (docs sync, gitleaks, etc.) never executed — they were dead code.
- No commit message validation existed (conventional commits and DCO sign-off were convention-only).
- No automated documentation sync between source repos and the cdc vault.

This created a gap: commit standards were documented but not enforced, docs sync required manual invocation, and per-repo hooks were a maintenance fiction.

## Decision

Implement a **hybrid dispatch** hook architecture with four hook types, managed entirely through Nix/Home Manager and deployed via `unimart deli switch`.

### Architecture

**Global hooks** (`~/.githooks/`) handle universal gates. All hooks are Nix-managed string literals in `cmdr/home/04-modules/cli/graduated/git/default.nix`, deployed to `~/.githooks/` via `home.file`.

**Shared libraries** (`~/.githooks/lib/`) provide reusable gate functions:
- `gates.sh` — repo detection, format checks, vet, gitleaks, build, test, flake check, dispatch
- `commit-msg.sh` — conventional commit, DCO, section validation
- `sync.sh` — docs sync to cdc vault, executive summary extraction, commit-log entries

**Repo-local hooks** (`.githooks/<hook-name>` in any repo) are extension points. The global hook dispatches to them after running universal gates. Currently only cmdr needs one (theme lint is handled inline).

### Gate Inventory

| Hook | Gate | Detection | Speed |
|------|------|-----------|-------|
| pre-commit | `nix fmt --check` | `flake.nix` exists | Fast |
| pre-commit | `go fmt` check | `go.mod` exists | Fast |
| pre-commit | `go vet` | `go.mod` exists | Fast |
| pre-commit | gitleaks secret scan | `command -v gitleaks` | Fast |
| pre-commit | theme lint | cmdr-specific script exists | Fast |
| commit-msg | conventional commit format | always | Instant |
| commit-msg | DCO sign-off | always | Instant |
| commit-msg | `## Changes` section | always (skip merge) | Instant |
| commit-msg | `## Executive Summary` section | always (skip merge) | Instant |
| post-commit | docs sync to cdc vault | docs/ in commit | Medium |
| post-commit | commit-log entry creation | exec summary exists | Fast |
| post-commit | cdc vault auto-commit | vault has changes | Fast |
| pre-push | `go build ./...` | `go.mod` exists | Medium |
| pre-push | `go test ./...` | `go.mod` exists | Slow |
| pre-push | `nix flake check` | `flake.nix` exists | Slow |

### Commit Template

Structured template with `core.commentChar = ";"` so `##` markdown headers survive `commit.cleanup = strip`:

```
<type>(<scope>): <subject>

## Changes

<describe what changed and why>

## Executive Summary

<1-2 paragraphs for the docs ecosystem>
```

### Self-Reconciling Docs Pipeline

The post-commit hook creates a closed loop:

1. Developer commits in any source repo (with `## Executive Summary`)
2. Post-commit detects if `docs/` files changed → rsyncs to cdc vault + injects frontmatter
3. Extracts executive summary → creates `cdc/commit-log/<date>-<repo>-<hash>.md` with Dataview-queryable frontmatter
4. Auto-commits the cdc vault (with `--no-verify` to skip commit-msg validation, re-entry guard via `_HOOK_POST_COMMIT_RUNNING` env var)

### Key Design Choices

- **`nix flake check` moved from pre-commit to pre-push** — too slow for commit-time feedback
- **Post-commit is best-effort** — no `set -e`, commit already happened, failures are non-fatal warnings
- **All gates degrade gracefully** — missing tools produce `[warn]` not `[fail]`
- **Merge commits exempt** from section requirements (conventional commit, Changes, Executive Summary)
- **`--no-verify` always available** for WIP commits
- **Re-entry guard** prevents infinite recursion when cdc auto-commit triggers post-commit

## Consequences

### Positive

- Every commit across the org follows the same standards — enforced, not just documented
- Documentation flows automatically from source repos to cdc vault on every commit
- Executive summaries create a queryable activity log in Obsidian
- Single Nix file manages the entire hook system — one `unimart deli switch` deploys everything
- Per-repo dead hooks eliminated — global dispatch replaces the shadowed `.git/hooks/` pattern
- Gitleaks now runs on every commit (previously shadowed)

### Negative

- All hook logic lives in Nix string literals — no syntax highlighting, harder to edit than standalone scripts
- `core.commentChar = ";"` affects all git operations globally (rebase instructions, etc.)
- Post-commit hook adds latency after every commit (docs sync + vault commit)
- Developer must write `## Changes` and `## Executive Summary` for every non-merge commit

### Neutral

- Per-repo `.githooks/` directories are extension points but currently unused (cmdr's theme lint is handled inline in the global hook)
- Dataview community plugin must be installed manually in Obsidian to query commit-log entries
- Old per-repo hook installers (`make hooks`, `scripts/install-hooks.sh`) become dead code — cleanup tracked separately
