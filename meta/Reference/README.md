---
source: meta
synced: 2026-05-31
---
# Reference

Quick reference for org-level conventions and tooling.

## Runbooks

- [unimart Cross-Host Rollout Runbook](unimart-rollout-runbook.md) - Phase 4 and Phase 5 execution plan for idpctl -> unimart migration

## Directory Structure

```
~/repos/github/idpbuilder/
├── meta/                           Coordination repo (this one)
│   ├── docs/                       Org documentation (you are here)
│   ├── Architecture/               ← MOVED to docs/Architecture/
│   ├── cmd/                        Go source for unimart CLI
│   ├── internal/                   unimart internals
│   ├── cmdr/                       Submodule: Nix workstation config
│   ├── idpbuilder/                 Submodule: IDP builder
│   ├── idpctl/                     Submodule: Deprecated CLI
│   ├── docs/                       Submodule: Docs hub (legacy)
│   └── unimart-employee-handbooks/ Submodule: cdc Obsidian vault
└── ...
```

## Key Commands

### Org Operations
```bash
unimart stockroom status         # Health check all repos
unimart stockroom check          # Validate contracts
unimart stockroom drift          # Check upstream drift
unimart stockroom update         # Update submodules

make bootstrap                   # First-time setup
make ci                          # Run all CI checks locally
```

### Repo Operations
```bash
unimart deli switch              # Deploy cmdr config
unimart deli doctor              # Check system health
unimart deli hosts               # List available hosts

unimart freezer up               # Start IDP platform
unimart freezer status           # Check platform status
unimart freezer down             # Tear down platform

unimart newsstand sync           # Sync docs to cdc vault
```

## Git Workflow

### Standard Commit Flow
```bash
# Edit files
git add <files>
git commit -s

# Pre-commit hook fires (format, lint)
# Commit succeeds
# Post-commit hook fires (docs sync to cdc)
git push
# Pre-push hook fires (build, test)
```

### Commit Message Format
```
feat(scope): short description

## Changes
- What changed
- What changed

## Executive Summary
One paragraph explaining why.
```

## Conventions

### Commit Format
- **Format:** Conventional commits (`feat:`, `fix:`, `docs:`, `refactor:`, `chore:`)
- **Scope:** Component/repo name in parentheses
- **Sign-off:** `git commit -s` (DCO required)
- **Subject:** Imperative, under 72 chars
- **Sections:** `## Changes` and `## Executive Summary` required

### Docs Structure
All repos' `docs/` must have:
- `README.md`
- `Contributing/README.md` + `Contributing/AGENTS.md`
- `Getting-Started/README.md`
- `Reference/README.md`
- `Architecture/` (optional)

### Makefile Pattern
```makefile
.DEFAULT_GOAL := help
CYAN := \033[0;36m
# ... color definitions

help:
	@printf "$(BOLD)Targets:$(RESET)\n"
	@printf "  $(CYAN)target$(RESET)  description\n"

.PHONY: help hooks sync-docs
```

## Git Hooks

All hooks deployed to `~/.githooks/`:

| Hook | Gates | Speed |
|------|-------|-------|
| `pre-commit` | fmt, lint, secrets | Fast |
| `commit-msg` | conventional, DCO, sections | Instant |
| `post-commit` | docs sync, commit-log, auto-commit cdc | Medium |
| `pre-push` | build, test, flake check | Slow |

See `Architecture/adr/005-git-hook-gates.md` for full details.

## Docs Sync Pipeline

When you commit to `docs/`:
1. Hooks detect `docs/` changes
2. `rsync` copies `docs/` → cdc vault
3. `inject-frontmatter.sh` adds `source` and `synced` fields
4. Cdc auto-commits
5. You push cdc to remote

The pipeline is **automatic** — no manual action needed.

## CI Workflows

| Workflow | Trigger | What |
|----------|---------|------|
| `validate.yml` | push/PR | Contract validation |
| `drift-check.yml` | scheduled | Submodule drift |
| `tag.yml` | manual | Org snapshots |

## Common Issues

### Hook didn't run?
Hooks are Nix-managed. Redeploy:
```bash
cd cmdr && make switch
```

### Docs not syncing?
Check that hook is running:
```bash
git config core.hooksPath
# Should show: /Users/cmdr/.githooks
```

### Submodule out of date?
```bash
git submodule update --init --recursive
```

---

For more details, see:
- [Architecture Overview](../Architecture/README.md)
- [Cross-Repo Contracts](../Architecture/contracts.md)
- Full org context: **../AGENTS.md**
