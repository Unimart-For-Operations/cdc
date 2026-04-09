---
source: idpbuilder
synced: 2026-04-09
---
# idpbuilder

Private fork of [cnoe-io/idpbuilder](https://github.com/cnoe-io/idpbuilder) — a Kubernetes-based Internal Developer Platform builder. The GitHub fork relationship was intentionally broken to allow private hosting.

> **Org membership:** This repo is tracked as a git submodule in [idpbuilder/meta](https://github.com/idpbuilder/meta). See the meta repo's `Architecture/` for cross-repo contracts and ADRs.

## Architecture

Two-phase system: **CLI phase** parses flags and creates a Kind cluster, then starts **three Kubernetes controllers**:
- `LocalbuildReconciler` — bootstraps core packages (ArgoCD, Gitea, ingress-nginx)
- `RepositoryReconciler` — creates and manages Gitea repositories
- `CustomPackageReconciler` — handles custom ArgoCD applications with `cnoe://` URL rewriting

Three-stage manifest pipeline: build time (kustomize/helm generate) → compile time (go:embed) → runtime (deploy to Kind).

See [docs/Architecture/README.md](docs/Architecture/README.md) for the full design.

## Key Commands

```bash
make build               # Compile the binary (generates CRDs, embeds manifests)
make test                # Run unit tests
make e2e                 # Run end-to-end tests
make embedded-resources  # Regenerate embedded manifests from hack/ scripts
make fetch-upstream      # Fetch latest from cnoe-io/idpbuilder
make upstream-status     # Show ahead/behind counts vs upstream
make cherry-pick COMMIT=<sha>  # Cherry-pick a specific upstream commit
make sync-docs           # Sync docs to hub + Obsidian
```

## Upstream Management

Changes from upstream are cherry-picked, not merged. Load the `upstream-mgmt` skill for the full workflow.

**Important:** The Go module path is `github.com/cnoe-io/idpbuilder` — this matches upstream intentionally. References to `cnoe-io` in Go source files and `go.mod` are expected and correct.

## Key Directories

| Path | Purpose |
|------|---------|
| `hack/` | Manifest generation scripts per component |
| `pkg/controllers/` | The three reconcilers |
| `pkg/controllers/localbuild/resources/` | Generated embedded manifests (do NOT edit) |
| `pkg/build/build.go` | Main orchestration (`Build.Run()`) |
| `api/` | CRD type definitions |

## Code Style

- **Go**: Standard Go conventions, `go fmt`, `go vet`
- **Commits**: `git commit -s` (DCO sign-off required), conventional commits

## Further Reading

- [docs/Contributing/README.md](docs/Contributing/README.md) — Dev setup, testing, component upgrades
- [docs/Reference/upstream-management.md](docs/Reference/upstream-management.md) — Cherry-pick workflow
