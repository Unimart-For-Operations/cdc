---
source: meta
synced: 2026-05-31
---
# docs

Documentation for the meta control plane and legacy documentation hub for the [idpbuilder](https://github.com/idpbuilder) GitHub organization.

> **Transitional:** This hub is being replaced by the **cdc vault** (`unimart-employee-handbooks/cdc/`). During transition both exist; new work targets cdc. See meta's `AGENTS.md` for the full documentation flow.

> **Org context:** Part of the [idpbuilder](https://github.com/idpbuilder) org, coordinated through the [meta](https://github.com/idpbuilder/meta) repo. Read meta's `AGENTS.md` for the full org map, conventions, roadmap, and cross-repo contracts (`Architecture/`). Sibling repos: **cmdr** (Nix workstation config), **idpbuilder** (K8s platform), **idpctl** (deprecated CLI → unimart), **cdc** (Obsidian vault — the replacement for this hub).

## Critical Rule

**Do NOT edit files in `cmdr/`, `idpbuilder/`, or `idpctl/` subdirectories directly.** Those are legacy synced mirrors. Edit the source repo's `docs/` directory instead, then run the cdc sync pipeline.

## How It Works

Current sync pipeline (`unimart newsstand sync` → `unimart-employee-handbooks/cdc/scripts/sync-docs.sh`):

1. **Pull**: `rsync --delete` from each source repo's `docs/` → `unimart-employee-handbooks/cdc/<repo>/`
2. **Frontmatter**: Inject YAML frontmatter (`source`, `synced` date) directly into cdc mirror copies

The cdc vault is committed Markdown. Obsidian is optional; terminal reading must still work.

Load the `docs-sync` skill for complete pipeline details.

## Triggering Sync

```bash
# From the meta repo
unimart newsstand sync
make sync-docs

# Automatic: post-commit hooks trigger sync when docs/ files are in the commit
```

## Structure

```
./
├── cmdr/                Mirror of cmdr/docs/
├── idpbuilder/          Mirror of idpbuilder/docs/
├── idpctl/              Legacy mirror of deprecated idpctl docs
├── Contributing/        Hub-specific docs (not mirrored from any source)
├── scripts/
│   ├── sync-docs.sh            Two-phase sync pipeline
│   └── inject-frontmatter.sh   Frontmatter injection for Obsidian
├── README.md
└── Makefile
```

## Key Paths

| Path | Editable? | Description |
|------|-----------|-------------|
| `cmdr/` | NO — synced | Mirror of cmdr's docs/ |
| `idpbuilder/` | NO — synced | Mirror of idpbuilder's docs/ |
| `idpctl/` | NO — legacy | Deprecated idpctl mirror |
| `Contributing/` | YES | Hub-specific contributing docs |
| `scripts/` | YES | Sync pipeline tooling |
| `README.md` | YES | This repo's own README |
| `Makefile` | YES | Sync and hook targets |
