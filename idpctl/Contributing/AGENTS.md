---
source: idpctl
synced: 2026-04-09
---
# idpctl

Go CLI tool for managing the [idpbuilder](https://github.com/idpbuilder/idpbuilder) development workspace lifecycle. Built with Cobra and Viper.

> **Org membership:** This repo is tracked as a git submodule in [idpbuilder/meta](https://github.com/idpbuilder/meta). See the meta repo's `Architecture/` for cross-repo contracts and ADRs.

## What It Does

Manages the full IDP lifecycle: `doctor` (check prereqs) → `bootstrap` (install tools) → `up` (start platform) → `status` (health check) → `down` (teardown). Also handles org repo management via `repos` subcommands.

## Architecture

```
cmd/          Cobra command definitions (one file per command)
internal/
├── builder/  Build, Create, Delete operations on idpbuilder binary
├── cluster/  Kind cluster queries, ArgoCD app status, secrets
├── colima/   Colima VM lifecycle, DOCKER_HOST management (macOS)
├── prereqs/  Platform detection, tool install (Nix primary, Homebrew fallback)
└── repos/    GitHub org repo listing, cloning, local status
```

Platform-aware: detects macOS vs Linux at runtime. On macOS, manages Colima VM for Docker. On Linux, expects native Docker daemon.

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
└── docs/                      # org documentation
```

Detection: `--org-dir` flag → `IDPCTL_ORG_DIR` env → CWD auto-detect → `~/idpbuilder` fallback.

## Code Style

- **Go**: Standard conventions, `go fmt`, `go vet`
- **Commits**: `git commit -s` (DCO sign-off required), conventional commits
- **Releases**: GoReleaser via GitHub Actions on `v*.*.*` tags

## Further Reading

- [docs/Contributing/README.md](docs/Contributing/README.md) — Architecture details, building, releasing
- [docs/Reference/README.md](docs/Reference/README.md) — Full command reference
