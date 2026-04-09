# docs

Documentation aggregation hub for the [idpbuilder](https://github.com/idpbuilder) GitHub organization. This repo **mirrors** documentation from source repos — it is not the source of truth.

> **Org membership:** This repo is tracked as a git submodule in [idpbuilder/meta](https://github.com/idpbuilder/meta). See the meta repo's `.docs-manifest.yml` for the pipeline contract.

## Critical Rule

**Do NOT edit files in `cmdr/`, `idpbuilder/`, or `idpctl/` subdirectories directly.** These are synced mirrors. Edit the source repo's `docs/` directory instead, then run the sync pipeline.

## How It Works

Two-phase sync pipeline (`scripts/sync-docs.sh`):

1. **Pull**: `rsync --delete` from each source repo's `docs/` → this repo's subdirectories
2. **Frontmatter**: Inject YAML frontmatter (`source`, `synced` date) directly into mirrored copies

Obsidian reads this directory via symlink (`~/Documents/cmdr/Professional/idpbuilder` → here). Frontmatter is ephemeral local state — never committed, overwritten on every sync.

Load the `docs-sync` skill for complete pipeline details.

## Triggering Sync

```bash
# From this repo
make sync

# From the meta repo
make sync-docs

# From any source repo
make sync-docs

# Automatic: pre-commit hooks trigger sync when docs/ files are staged
```

## Structure

```
./
├── cmdr/                Mirror of cmdr/docs/
├── idpbuilder/          Mirror of idpbuilder/docs/
├── idpctl/              Mirror of idpctl/docs/
├── Contributing/        Hub-specific docs (not mirrored from any source)
├── scripts/
│   ├── sync-docs.sh            Two-phase sync pipeline
│   ├── inject-frontmatter.sh   Frontmatter injection for Obsidian
│   └── hooks/
│       └── pre-commit-docs-sync.sh  Shared pre-commit hook library
├── README.md
└── Makefile
```

## Key Paths

| Path | Editable? | Description |
|------|-----------|-------------|
| `cmdr/` | NO — synced | Mirror of cmdr's docs/ |
| `idpbuilder/` | NO — synced | Mirror of idpbuilder's docs/ |
| `idpctl/` | NO — synced | Mirror of idpctl's docs/ |
| `Contributing/` | YES | Hub-specific contributing docs |
| `scripts/` | YES | Sync pipeline tooling |
| `README.md` | YES | This repo's own README |
| `Makefile` | YES | Sync and hook targets |
