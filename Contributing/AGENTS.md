# cdc contributing

Generated employee handbook and Obsidian vault for the [idpbuilder](https://github.com/idpbuilder) GitHub organization. This repo mirrors documentation from source repos and also contains vault-native operational notes.

> **Org membership:** This repo is tracked as a git submodule in [idpbuilder/meta](https://github.com/idpbuilder/meta). See the meta repo's `.docs-manifest.yml` for the pipeline contract.

## Critical Rule

**Do NOT edit files in synced mirror directories directly.** Edit the source repo's `docs/` directory instead, then run the sync pipeline.

## How It Works

Two-phase sync pipeline (`scripts/sync-docs.sh`):

1. **Pull**: `rsync --delete` from each source repo's `docs/` into this vault's mirror directories
2. **Frontmatter**: Inject YAML frontmatter (`source`, `synced` date) directly into mirrored copies

Frontmatter is committed to the vault. Obsidian is optional; Markdown must remain usable from a terminal.

## Triggering Sync

```bash
# From the meta repo
unimart newsstand sync
make sync-docs

# Automatic: post-commit hooks sync docs/ changes and auto-commit cdc

# Direct from this vault
bash scripts/sync-docs.sh
```

## Structure

```
./
├── cmdr/                Mirror of cmdr/docs/
├── idpbuilder/          Mirror of idpbuilder/docs/
├── meta/                Mirror of meta/docs/
├── Contributing/        Vault-specific docs
├── commit-log/          Auto-generated commit summaries
├── scripts/
│   ├── sync-docs.sh
│   └── inject-frontmatter.sh
├── templates/
├── 00-INDEX.md
└── Welcome.md
```

## Key Paths

| Path | Editable? | Description |
|------|-----------|-------------|
| `cmdr/` | NO — synced | Mirror of cmdr's docs/ |
| `idpbuilder/` | NO — synced | Mirror of idpbuilder's docs/ |
| `meta/` | NO — synced | Mirror of meta's docs/ |
| `Contributing/` | YES | Vault-specific docs |
| `commit-log/` | YES | Auto-generated commit summaries |
| `scripts/` | YES | Sync pipeline tooling |
| `templates/` | YES | Obsidian templates |
| `00-INDEX.md` | YES | Vault map of content |
| `Welcome.md` | YES | Vault landing page |
