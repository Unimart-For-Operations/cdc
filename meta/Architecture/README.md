---
source: meta
synced: 2026-05-31
---
# Architecture Overview

The idpbuilder org consists of repos coordinated through this meta repo. Each repo is an independent git repository tracked as a submodule. idpctl is deprecated and being absorbed into unimart.

## Repo Relationships

```
                    ┌─────────────────┐
                    │   meta (this)   │
                    │  coordination   │
                    │  + unimart CLI  │
                    └──┬──┬──┬──┬────┘
                       │  │  │  │
            ┌──────────┘  │  │  └──────────┐
            │             │  │             │
            v             v  │             v
        ┌───────┐   ┌──────────┐       ┌──────┐
        │  cmdr │   │idpbuilder│       │ docs │
        │  Nix  │   │  Go/K8s  │       │mirror│
        └───┬───┘   └──────────┘       └──┬───┘
            │                              │
            │  theme JSON ──> meta/        │
            │                internal/     │
            │                theme/        │
            │                              │
            │  docs/ ──────────────────────>│
            │                idpbuilder ──>│
            │                              │
            │                              v
            │                       ┌────────────┐
            │                       │  Obsidian   │
            │                       │   vault     │
            │                       └────────────┘
            │
            └──> nix-darwin + home-manager (local machine)
```

## Data Flows

For the high-level mental model, see [Mental Model](mental-model.md). The editable Draw.io source is [mental-model.drawio](mental-model.drawio).

### 1. Theme Export (cmdr --> unimart)

cmdr evaluates its Nix theme module and exports a JSON representation via `scripts/theme-export.sh`. unimart consumes this through `internal/theme/theme.go`'s `LoadFromOrg()` function, which either runs the script directly or falls back to a static `theme.json` file.

**Producer:** `cmdr/scripts/theme-export.sh` (Nix eval --> stdout JSON)
**Consumer:** `internal/theme/theme.go` `LoadFromOrg(orgDir, themeName)` (in meta repo — unimart)
**Schema:** `{ name, palette, semantic, terminal.ansi, fonts }`
**Contract:** [contracts.md#theme-export](contracts.md#theme-export)

### 2. Documentation Sync (source repos --> cdc handbook)

A two-phase pipeline mirrors documentation from source repos into the cdc handbook/vault with frontmatter injection. Obsidian is optional; the vault remains committed Markdown.

**Phase 1 (Pull):** `rsync --delete` each source repo's `docs/` into `unimart-employee-handbooks/cdc/<repo>/`
**Phase 2 (Frontmatter):** Inject `source` and `synced` YAML fields for Dataview queries

**Central script:** `unimart-employee-handbooks/cdc/scripts/sync-docs.sh`
**Contract:** [contracts.md#docs-sync-pipeline](contracts.md#docs-sync-pipeline)

### 3. Git Hook Gates (cmdr --> all repos)

cmdr deploys global hooks to `~/.githooks/` through Home Manager. Pre-commit runs fast gates. Post-commit syncs source repo docs to cdc, creates commit-log entries, and auto-commits the vault.

**Library:** `~/.githooks/lib/sync.sh`
**Contract:** [contracts.md#hook-sharing](contracts.md#hook-sharing)

### 4. Upstream Tracking (cnoe-io --> idpbuilder)

The idpbuilder repo tracks the upstream cnoe-io/idpbuilder via a cherry-pick workflow (no merge commits). The `upstream` remote points to `cnoe-io/idpbuilder.git`.

**Contract:** [contracts.md#upstream-tracking](contracts.md#upstream-tracking)

## Directory Layout

```
idpbuilder/meta (this repo)
├── Architecture/
│   ├── README.md           This file
│   ├── contracts.md        Cross-repo interface specifications
│   └── adr/
│       ├── 001-submodule-org-structure.md
│       ├── 002-cherry-pick-upstream.md
│       ├── 003-docs-sync-pipeline.md
│       └── 004-theme-export-contract.md
├── .github/workflows/
│   ├── drift-check.yml     Daily submodule drift detection
│   ├── validate.yml        Contract validation on push
│   └── tag.yml             Manual org snapshot tagging
├── .gitmodules             Submodule definitions
├── .gitignore              Security-focused exclusions
├── AGENTS.md               AI coding agent context
├── Makefile                Org-level tooling
├── README.md               Repo overview
├── cmdr/                   Submodule: Nix workstation config
├── idpbuilder/             Submodule: IDP builder (Go)
├── idpctl/                 Submodule: CLI tool (Go) — DEPRECATED, absorbed into unimart
└── docs/                   Submodule: Docs aggregation hub
```

## Conventions

All repos follow shared conventions documented in the org-level [AGENTS.md](../AGENTS.md):

- **Conventional commits** with DCO sign-off
- **Makefile convention** with hand-crafted help, color output, status indicators
- **ORG_DIR detection** via `dirname $(CURDIR)` for sibling repo discovery
- **Docs directory structure** with `Contributing/`, `Getting-Started/`, `Reference/` subdirectories
