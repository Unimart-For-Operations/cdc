# cdc

Documentation vault for the [idpbuilder](https://github.com/idpbuilder) organization.

## Synced Mirrors

These directories are mirrors of source repo `docs/` directories. **Do not edit here** — changes are overwritten on next sync. Edit the source repo instead.

| Directory | Source |
|-----------|--------|
| [[cmdr/]] | [idpbuilder/cmdr](https://github.com/idpbuilder/cmdr) `docs/` |
| [[idpbuilder/]] | [idpbuilder/idpbuilder](https://github.com/idpbuilder/idpbuilder) `docs/` |
| [[idpctl/]] | [idpbuilder/idpctl](https://github.com/idpbuilder/idpctl) `docs/` |

## Hub Content

| Directory | Description |
|-----------|-------------|
| [[Contributing/]] | Organization-wide contributing guides |
| [[templates/]] | Note templates (PRD, ADR, runbook, meeting) |

## Sync Pipeline

Source repos are the **source of truth**. The sync pipeline copies docs from each repo into this vault:

```
source repo docs/ → rsync → cdc vault subdirectory → frontmatter injection
```

Trigger sync via `unimart newsstand sync` or through pre-commit hooks in source repos.
