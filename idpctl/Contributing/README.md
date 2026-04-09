---
source: idpctl
synced: 2026-04-09
---
# Contributing

## Architecture

### Package Structure

```
main.go                          Entry point
cmd/                             Cobra command definitions
├── root.go                      Root command, global flags, org-dir detection
├── doctor.go                    Prerequisite and workspace health checks
├── bootstrap.go                 Interactive prerequisite installation
├── up.go                        Full platform startup sequence
├── down.go                      Platform teardown
├── build.go                     Build idpbuilder from source
├── status.go                    Platform status display
├── repos.go                     Repository management (list/clone/status)
└── version.go                   Version info (injected via ldflags)

internal/
├── builder/
│   └── builder.go               Build, Create, Delete operations on idpbuilder
├── cluster/
│   └── cluster.go               Kind cluster queries, ArgoCD app status, secrets
├── colima/
│   └── colima.go                Colima VM lifecycle, DOCKER_HOST management
├── prereqs/
│   ├── detect.go                Platform detection, command helpers, pkg managers
│   ├── docker.go                Docker CLI + Colima check and install
│   ├── go.go                    Go check and install
│   ├── kind.go                  Kind check and install
│   ├── kubectl.go               kubectl check
│   └── workspace.go             Org directory and repo validation
└── repos/
    └── repos.go                 GitHub org repo listing, cloning, local status
```

### Platform Awareness

idpctl is designed to work on both macOS and Linux with different Docker strategies:

| Concern | macOS (Darwin) | Linux |
|---|---|---|
| Docker daemon | Colima (Lima VM running Docker) | Native Docker daemon (systemd) |
| Docker CLI | Nix or Homebrew | Nix or Homebrew |
| Container runtime install | Homebrew (Colima) | User-managed (distro package manager) |
| `DOCKER_HOST` | `unix://~/.config/colima/default/docker.sock` | Default Docker socket |
| `--stop-colima` flag | Available on `down` | Not registered |
| Colima checks | Shown in `doctor` and `status` | Skipped |

Platform is detected at runtime via `runtime.GOOS`. Commands adapt their step counts, flag registration, and check sets accordingly.

### Docker Host Management

On macOS, the user's shell may have `DOCKER_HOST` pointing to a Docker Desktop socket or other incorrect location. idpctl handles this automatically:

1. **`up` command**: After starting Colima, calls `ensureDockerHost()` which:
   - Sets `DOCKER_HOST=unix://~/.config/colima/default/docker.sock` via `os.Setenv`
   - Verifies the socket file exists
   - Switches the Docker CLI context to `colima` as a convenience

2. **`status` and `doctor` commands**: Call `EnsureDockerHost()` before any checks that shell out to `docker`, `kind`, or `kubectl` — these inherit the process environment and need the correct socket.

3. **`down` command**: Calls `EnsureDockerHost()` before cluster deletion so `kind delete cluster` can reach the Docker daemon.

This is necessary because `os.Setenv` affects the current process and all child processes spawned after the call — so setting it once at the top of a command propagates correctly to all subsequent `exec.Command` calls.

**Note:** `colima status` writes its output to stderr via structured logging, not stdout. idpctl uses `CombinedOutput()` (not `Output()`) when checking Colima's status to capture this correctly.

## Building from Source

### Makefile Targets

| Target | Description |
|---|---|
| `make build` | Format, vet, then compile with version ldflags |
| `make test` | Run `go test ./...` |
| `make fmt` | Run `go fmt ./...` |
| `make vet` | Run `go vet ./...` |
| `make clean` | Remove the compiled binary |

### Version Injection

The build injects version metadata via Go linker flags (`-ldflags -X`):

| Variable | Source |
|---|---|
| `cmd.Version` | `git describe --always --tags --dirty --broken` (or `dev`) |
| `cmd.GitCommit` | `git rev-parse --short HEAD` (or `unknown`) |
| `cmd.BuildDate` | UTC ISO 8601 timestamp |

## Releasing

Releases are automated via [GoReleaser](https://goreleaser.com/) and GitHub Actions.

**Trigger:** Push a tag matching `v*.*.*`:

```bash
git tag v0.1.0
git push origin v0.1.0
```

**What happens:**

1. GitHub Actions workflow (`.github/workflows/release.yaml`) triggers on the tag.
2. GoReleaser builds cross-platform binaries (`linux`/`darwin` x `amd64`/`arm64`) with `CGO_ENABLED=0`.
3. Produces `tar.gz` archives named `idpctl-<os>-<arch>.tar.gz`.
4. Generates `checksums.txt`.
5. Creates a GitHub Release with changelog (excludes `docs:`, `test:`, `ci:`, `chore:` commits).

**CI on pull requests** (`.github/workflows/pr.yaml`):

- Runs `make build`, `make test`, `go vet` on `ubuntu-latest`.

## Commits

This repository requires [DCO sign-off](https://developercertificate.org/) on all commits: `git commit -s`
