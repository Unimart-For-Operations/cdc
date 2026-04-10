---
source: idpctl
synced: 2026-04-10
---
# idpctl

> **DEPRECATED:** idpctl is being absorbed into [unimart](https://github.com/idpbuilder/meta) (`unimart freezer` commands). New features should be implemented in meta's `cmd/freezer_cmds.go`, not here. See the migration plan in meta's `AGENTS.md` (Phase 2: Port Freezer Commands).

Go CLI tool for managing the [idpbuilder](https://github.com/idpbuilder/idpbuilder) development workspace lifecycle. Built with Cobra. Config is all Cobra flags + env vars + runtime auto-detection (no Viper, no config files).

> **Org context:** Part of the [idpbuilder](https://github.com/idpbuilder) org, coordinated through the [meta](https://github.com/idpbuilder/meta) repo. Read meta's `AGENTS.md` for the full org map, conventions, roadmap, and cross-repo contracts (`Architecture/`). Sibling repos: **cmdr** (Nix workstation config), **idpbuilder** (K8s platform), **docs** (doc hub, transitional), **cdc** (Obsidian vault).

## What It Does

Manages the full IDP lifecycle: `doctor` (check prereqs) → `bootstrap` (install tools) → `up` (start platform) → `status` (health check) → `down` (teardown). Also handles org repo management via `repos` subcommands.

## Architecture

```
cmd/          Cobra command definitions (one file per command)
internal/
├── builder/    Build, Create, Delete operations on idpbuilder binary
├── cluster/    Kind cluster queries, ArgoCD app status, secrets
├── colima/     Colima VM lifecycle, DOCKER_HOST management (macOS)
├── container/  Container runtime detection and management
├── gitea/      Gitea API client, repo operations
├── prereqs/    Platform detection, tool install (Nix primary, Homebrew fallback)
├── repos/      GitHub org repo listing, cloning, local status
└── theme/      Theme loading from cmdr (JSON export consumer)
```

Platform-aware: detects macOS vs Linux at runtime. On macOS, manages Colima VM for Docker. On Linux, expects native Docker daemon.

Dependencies are minimal: only `cobra` and `fatih/color` as direct deps. All external tool interaction is via shelling out to CLIs.

## Key Commands

```bash
make build    # Format, vet, compile with version ldflags
make test     # Run go test ./...
make fmt      # Run go fmt ./...
make vet      # Run go vet ./...
make clean    # Remove binary
```

## Organization Directory

idpctl expects a parent directory containing all org repos:

```
~/repos/github/idpbuilder/     # org directory
├── idpbuilder/                # main project (required)
├── idpctl/                    # this tool
├── cmdr/                      # nix workstation config
├── docs/                      # org documentation
└── unimart-employee-handbooks/
    └── cdc/                   # Obsidian vault
```

Detection: `--org-dir` flag → `IDPCTL_ORG_DIR` env → CWD auto-detect → `~/idpbuilder` fallback.

## Code Style

- **Go**: Standard conventions, `go fmt`, `go vet`
- **Commits**: `git commit -s` (DCO sign-off required), conventional commits

## Further Reading

- [docs/Contributing/README.md](docs/Contributing/README.md) — Architecture details, building, releasing
- [docs/Reference/README.md](docs/Reference/README.md) — Full command reference
