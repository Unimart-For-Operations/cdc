---
source: meta
synced: 2026-05-31
---
# Getting Started with idpbuilder

Guide to setting up and working with the idpbuilder organization.

## Prerequisites

- Git 2.13+ (for submodule support)
- Nix 2.13+ (for reproducible builds)
- Basic terminal knowledge
- SSH key configured for GitHub

## Initial Setup

### 1. Clone the Meta Repo
```bash
git clone git@github.com:idpbuilder/meta.git ~/repos/github/idpbuilder/meta
cd ~/repos/github/idpbuilder/meta
```

### 2. Bootstrap
```bash
make bootstrap
```

This initializes all submodules, installs prerequisites, and sets up your environment.

### 3. Verify Installation
```bash
make status
unimart version
```

---

## Organization Structure

The org has four component repos:

| Repo | Purpose | Status |
|------|---------|--------|
| **cmdr** | Nix workstation config (Home Manager) | Active |
| **idpbuilder** | Kubernetes IDP builder | Active |
| **idpctl** | CLI tool | Deprecated → unimart |
| **docs** | Documentation hub (transitional) | Being phased out |

All repos live as git submodules under `/meta/`.

---

## Common Tasks

### Apply Your Workstation Config
```bash
cd cmdr
make switch
```

This deploys your Nix home-manager config and git hooks to `~/.githooks/`.

### Start the IDP Platform
```bash
cd idpbuilder
make up
```

### Seed Repos for Local Gitea Publish

By default, `unimart open` publishes repos found in `meta/repositories/`.

```bash
cd ~/repos/github/idpbuilder/meta
mkdir -p repositories
# clone or place git repos under repositories/
```

### Check Org Health
```bash
unimart stockroom status
unimart stockroom check
```

### Sync Documentation
```bash
# From any repo
make sync-docs

# Or use unimart
unimart newsstand sync
```

---

## Understanding the Sync Pipeline

Whenever you commit changes to `docs/` in any repo:

1. **Pre-commit hook** validates the commit message format
2. **Commit succeeds**
3. **Post-commit hook** fires:
   - Detects `docs/` changes
   - Syncs `docs/` to the cdc vault
   - Extracts `## Executive Summary` section
   - Auto-commits to cdc vault
4. **Cdc vault now has your docs** — ready to push to remote

This happens automatically. No manual action needed.

---

## Troubleshooting

### Hook didn't run?
Hooks are deployed to `~/.githooks/` by `unimart deli switch`. Re-run:
```bash
cd cmdr
make switch
```

### Submodule not initialized?
```bash
git submodule update --init --recursive
```

### Git config issue?
Check that `core.hooksPath` is set:
```bash
git config core.hooksPath
# Should output: /Users/cmdr/.githooks
```

---

## Next Steps

1. Read **[../AGENTS.md](../AGENTS.md)** for full org context
2. Read **[../Architecture/README.md](../Architecture/README.md)** to understand repo relationships
3. Visit a specific repo's `docs/Contributing/` for deeper context

---

## Getting Help

- Check the repo's `AGENTS.md` for repo-specific context
- See `Architecture/contracts.md` for interface specifications
- Review `Architecture/adr/` for design decisions
