---
source: meta
synced: 2026-05-31
---
# Contributing to idpbuilder

Comprehensive guide for contributing to the idpbuilder organization.

## Table of Contents

- [Code Style and Conventions](#code-style-and-conventions)
- [Commit Workflow](#commit-workflow)
- [Working Across Repos](#working-across-repos)
- [Git Hooks and CI](#git-hooks-and-ci)

---

## Code Style and Conventions

All repos follow shared conventions:

### Commits
- **DCO Sign-off:** Always use `git commit -s`
- **Format:** Conventional commits (`feat(scope):`, `fix:`, `docs:`, `refactor:`, `chore:`)
- **Subject:** Imperative mood, under 72 characters
- **Body:** Clear explanation of the "why," not the "what"

### Documentation
- **Structure:** Every repo's `docs/` must have identical subdirectories:
  - `Contributing/` — Contributing guides
  - `Getting-Started/` — Onboarding
  - `Reference/` — API/CLI reference
  - `Architecture/` — Design decisions
- **Format:** Markdown with clear headings and relative links
- **Frontmatter:** Auto-injected by sync pipeline (source, synced date)

### Makefiles
All repos use the same Makefile convention:
- `.DEFAULT_GOAL := help`
- Color output with `CYAN`, `GREEN`, `YELLOW`, `RED`, `RESET`, `BOLD`
- Status indicators: `[pass]`, `[fail]`, `[warn]`
- Hand-crafted help with sectioned targets
- Required targets: `help`, `hooks`, `sync-docs`

---

## Commit Workflow

### 1. Make Your Changes
```bash
cd <repo>
# Edit files
```

### 2. Stage and Commit
```bash
git add <files>
git commit -s
```

**Pre-commit hooks will:**
- Format check (`nix fmt`, `go fmt`)
- Linting (`go vet`, `gitleaks`)
- Validate commit message format

**If pre-commit fails:** Fix the issue and commit again. Do NOT skip hooks.

### 3. Commit Message Format
```
feat(scope): short description

## Changes
- What changed
- What changed

## Executive Summary
One paragraph explaining the "why" of this change.
```

The `## Executive Summary` is extracted and added to the cdc vault's commit-log automatically.

### 4. Push
```bash
git push origin <branch>
```

**Pre-push hooks will:**
- Run `go build` and `go test` (if Go repo)
- Run `nix flake check` (if Nix repo)

---

## Working Across Repos

### Finding the Org Root
All repos derive their org context via:
```makefile
ORG_DIR := $(shell dirname "$(CURDIR)")
```

This works because all repos are siblings under the meta repo.

### Updating Multiple Repos
Use `unimart stockroom` commands:
```bash
unimart stockroom status      # Check all repos
unimart stockroom check       # Validate contracts
unimart stockroom drift       # Check for upstream drift
unimart stockroom update      # Update submodules
```

### Adding a New Repo
1. Clone the repo and add as submodule in meta
2. Create `docs/` with the standard structure
3. Create `Makefile` with the shared convention
4. Add repo to `.gitmodules` and `.docs-manifest.yml`
5. Validate with `unimart stockroom check`

---

## Git Hooks and CI

### Local Hooks (pre-commit, commit-msg, post-commit, pre-push)
Deployed to `~/.githooks/` via `unimart deli switch`. See meta's `Architecture/adr/005-git-hook-gates.md` for full gate inventory.

### Post-Commit Docs Sync
When you commit changes to `docs/`, the post-commit hook automatically:
1. Syncs your `docs/` to the cdc vault
2. Extracts your `## Executive Summary` into a commit-log entry
3. Auto-commits the vault (unless already running)

No manual sync needed — the hook handles it.

### CI Workflows
- **validate.yml** — Contract validation on push
- **drift-check.yml** — Daily submodule drift detection
- **tag.yml** — Manual org snapshot tagging

See meta's `AGENTS.md` for CI details.

---

## Further Reading

- [Architecture Overview](../Architecture/README.md) — How repos connect
- [Cross-Repo Contracts](../Architecture/contracts.md) — Interface specifications
- Full org context: **../AGENTS.md**
