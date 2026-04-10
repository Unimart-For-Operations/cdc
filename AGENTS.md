# cdc

Obsidian vault and knowledge base for the [idpbuilder](https://github.com/idpbuilder) organization. Contains synced documentation mirrors from all source repos, plus org-native content (ADRs, runbooks, etc.).

> **Org context:** Part of the [idpbuilder](https://github.com/idpbuilder) org, coordinated through the [meta](https://github.com/idpbuilder/meta) repo. Read meta's `AGENTS.md` for the full org map, conventions, roadmap, and cross-repo contracts (`Architecture/`). Sibling repos: **cmdr** (Nix workstation config), **idpbuilder** (K8s platform), **idpctl** (deprecated CLI → unimart), **docs** (legacy doc hub, being replaced by this vault).

## Critical Rule

**Do NOT edit files in `cmdr/`, `idpbuilder/`, or `idpctl/` subdirectories directly.** These are synced mirrors from source repos. Edit the source repo's `docs/` directory instead, then run the sync pipeline. The sync will overwrite anything you put here.

## What's Editable vs Mirrored

| Path | Editable? | Description |
|------|-----------|-------------|
| `cmdr/` | NO — synced | Mirror of cmdr's docs/ |
| `idpbuilder/` | NO — synced | Mirror of idpbuilder's docs/ |
| `idpctl/` | NO — synced | Mirror of idpctl's docs/ |
| `Contributing/` | YES | Vault-specific contributing docs |
| `commit-log/` | YES (auto-generated) | Commit summaries with Dataview frontmatter, created by post-commit hook |
| `templates/` | YES | Obsidian note templates (default, project-prd, meeting, adr, runbook) |
| `scripts/` | YES | Sync pipeline tooling |
| `00-INDEX.md` | YES | Vault map of content (MOC) |
| `Welcome.md` | YES | Vault landing page |
| `AGENTS.md` | YES | This file |
| `.obsidian/` | YES | Obsidian config (not Nix-managed, lives in this repo) |

## Sync Pipeline

The sync pipeline runs from `scripts/sync-docs.sh`:

1. **Pull**: `rsync --delete` from each source repo's `docs/` → vault subdirectories
2. **Frontmatter**: Inject YAML frontmatter (`source`, `synced` date) for Obsidian Dataview

Frontmatter is committed to this repo (not ephemeral). Source repos are always the source of truth.

### Triggering Sync

```bash
# From the meta repo
unimart newsstand sync
make sync-docs

# Automatic: post-commit hook syncs when docs/ files are in the commit,
# creates commit-log entries from executive summaries, and auto-commits the vault

# Direct
bash scripts/sync-docs.sh
```

## Structure

```
./
├── AGENTS.md              This file
├── 00-INDEX.md            Vault map of content (MOC)
├── Welcome.md             Landing page
├── .obsidian/             Obsidian config (stock, not Nix-managed)
├── templates/             Note templates
├── scripts/
│   ├── sync-docs.sh       Sync pipeline (rsync + frontmatter)
│   └── inject-frontmatter.sh
├── commit-log/            Auto-generated commit summaries (Dataview-queryable)
├── Contributing/          Vault-specific docs
├── cmdr/                  Mirror of cmdr/docs/
├── idpbuilder/            Mirror of idpbuilder/docs/
└── idpctl/                Mirror of idpctl/docs/
```

## Obsidian Configuration

The `.obsidian/` directory lives in this repo's git history — it is NOT managed by Nix. Stock Obsidian config with no custom themes, plugins, or fonts.
