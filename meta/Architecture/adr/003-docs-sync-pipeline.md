---
source: meta
synced: 2026-05-31
---
# ADR-003: Docs Sync Pipeline

**Status:** Accepted
**Date:** 2026-04-03
**Deciders:** cmdr

## Context

Documentation lives in each source repo's `docs/` directory (cmdr, idpbuilder, meta). We need a way to:
1. Aggregate docs from all repos into a single browsable location
2. Sync to an Obsidian vault for personal knowledge management with Dataview queries
3. Trigger sync automatically when docs change

## Decision

Implement a **two-phase sync pipeline** centered on the cdc vault:

### Phase 1: Pull (source repos --> cdc vault)
`rsync --delete` each source repo's `docs/` into `unimart-employee-handbooks/cdc/<repo>/`. Source repos remain the source of truth.

### Phase 2: Frontmatter Injection
Inject `source` and `synced` YAML frontmatter into cdc mirror copies only (not source repos). This enables Obsidian Dataview queries like "show all docs synced from cmdr in the last week."

### Triggering

- **Manual:** `unimart newsstand sync` or `make sync-docs` from meta
- **Automatic:** post-commit hooks detect committed `docs/` changes, sync cdc, create commit-log entries, and auto-commit the vault
- **Script:** `unimart-employee-handbooks/cdc/scripts/sync-docs.sh`

### Key Design Choices

- **rsync --delete** ensures mirrors are exact copies (removes stale files)
- **Frontmatter only in cdc copies** -- source repos stay clean
- **Idempotent injection** -- skips files already current (same source, today's date)
- **Graceful degradation** -- skips missing repos, missing vault, missing scripts

## Alternatives Considered

### Git-based sync (subtree or submodule)
Use git subtree or submodules to mirror docs. Rejected because:
- Adds git complexity to every source repo
- Obsidian doesn't need git history, just current files
- rsync is simpler and handles deletions cleanly

### Obsidian git plugin
Let Obsidian pull directly from repos. Rejected because:
- Would need to configure multiple repo sources in Obsidian
- No frontmatter injection for Dataview
- Mixes Obsidian vault management with git workflows

### CI-based sync
Run sync in GitHub Actions. Rejected because:
- Obsidian vault is local-only (not on CI runners)
- Sync needs to happen immediately when committing, not after push
- Pre-commit hooks are more responsive

## Consequences

**Positive:**
- Single `unimart newsstand sync` syncs everything
- Post-commit hooks keep mirrors fresh automatically
- Obsidian Dataview queries work via frontmatter metadata
- Source repos remain the single source of truth

**Negative:**
- Requires all repos cloned as siblings (ORG_DIR convention)
- cdc is a git submodule and must be initialized
- rsync requires local filesystem access (no remote sync)

**Mitigations:**
- ORG_DIR convention is enforced by meta repo submodule layout
- Obsidian is optional because cdc remains Markdown-first
