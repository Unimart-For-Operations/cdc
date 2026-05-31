---
source: meta
synced: 2026-05-31
---
# idpbuilder Organization

This is the meta coordination repo and unified CLI (`unimart`) for the [idpbuilder](https://github.com/idpbuilder) GitHub organization. All component repos are tracked as git submodules (with `ignore = dirty`).

## unimart CLI

The `unimart` binary is a Go CLI built from this repo. It is the primary interface after initial setup. Commands are organized into store aisles:

| Aisle | Domain | Key Commands |
|-------|--------|--------------|
| `deli` | Workstation config (Nix/HM) | `switch`, `doctor`, `bootstrap`, `hosts` |
| `freezer` | IDP platform lifecycle | `up`, `down`, `status`, `build`, `doctor`, `repos`, `config`, `theme` |
| `newsstand` | Documentation pipeline | `sync` |
| `stockroom` | Cross-repo coordination | `drift`, `update`, `status`, `check`, `sync` |

Top-level commands (not under any aisle):

| Command | Purpose |
|---------|---------|
| `open` | Bring the full IDP platform online (prereqs, build, create, publish, browser) |
| `close` | Tear down the IDP platform (symmetric inverse of `open`) |
| `reload` | Reconcile platform changes without teardown (re-run create + re-publish repos) |
| `version` | Print version information |

Source layout:
- `main.go` — entry point
- `cmd/` — Cobra commands (root, aisle parents, subcommands)
- `internal/host/` — host auto-detection (scans cmdr meta.nix files)
- `internal/platform/` — platform detection, command execution utilities
- `internal/submodule/` — dynamic submodule discovery (parses `.gitmodules` at runtime)
- `internal/builder/` — idpbuilder build and create orchestration
- `internal/cluster/` — Kind cluster inspection (ArgoCD apps, secrets, Gitea token)
- `internal/colima/` — Colima VM lifecycle (start, stop, status, socket path)
- `internal/container/` — container image loading (Kind + Podman)
- `internal/gitea/` — Gitea API client (repos, SSH keys, auth)
- `internal/prereqs/` — prerequisite checks and installers (Go, Docker, Kind, kubectl, Colima, Podman)
- `internal/repos/` — org repo discovery and Gitea publish
- `internal/theme/` — theme loading, k9s skin and tmux status generation

## Repositories

| Repo | Purpose | Language | Status |
|------|---------|----------|--------|
| [cmdr](cmdr/) | Nix flake + Home Manager workstation config | Nix | Active |
| [idpbuilder](idpbuilder/) | Kubernetes-based IDP builder (private fork of cnoe-io/idpbuilder) | Go | Active |
| [idpctl](idpctl/) | CLI lifecycle tool for idpbuilder | Go | **Deprecated — being absorbed into unimart** |
| [docs](docs/) | Documentation aggregation hub (legacy, being replaced by cdc) | Shell/Markdown | Transitional |
| [cdc](unimart-employee-handbooks/cdc/) | Obsidian vault — synced doc mirrors + org knowledge base | Markdown | Active |

## Distribution

unimart is distributed through three channels:

| Channel | Mechanism | When |
|---------|-----------|------|
| **Nix (primary)** | cmdr's flake imports `github:idpbuilder/meta` and includes `unimart` in `home.packages` via `04-modules/cli/graduated/unimart/` | Every `make switch` on every host |
| **make init** | `scripts/setup.sh` step 6/7 builds from source, symlinks to `~/.local/bin/` | Fresh clones before Nix is configured |
| **make install** | `go build` + symlink to `~/.local/bin/unimart` | Development iteration |

### Nix distribution details

The meta flake exposes `packages.<system>.unimart` via `buildGoModule`. cmdr's flake references it as a flake input (`meta.url = "github:idpbuilder/meta"`). The unimart module at `cmdr/home/04-modules/cli/graduated/unimart/default.nix` pulls the package into `home.packages`. Any host with `features = ["cli" ...]` gets unimart automatically.

**Version pinning**: cmdr's `flake.lock` pins the meta commit. To bump: push meta changes, then run `nix flake update meta` in cmdr + `make switch`.

**Circular dependency note**: meta has cmdr as a submodule; cmdr references meta's flake by GitHub URL (not submodule path). Nix evaluates these independently — no real cycle. But version bumps need care: always push meta first, then update cmdr's lock.

## Conventions

- **Nix-first**: The user's system is Nix-managed (nix-darwin + home-manager via cmdr). All CLI tooling via Nix. Homebrew only for Colima on macOS.
- **DCO sign-off**: All repos require `git commit -s` for Developer Certificate of Origin.
- **Git submodules**: All repos are tracked as submodules in this meta repo (`ignore = dirty`). Use `unimart stockroom` for submodule operations, or `make bootstrap` for first-time init.
- **Commit style**: Conventional commits — `feat(scope):`, `fix:`, `docs:`, `refactor:`.
- **Makefile convention**: All repos use a consistent Makefile style — color output, `.DEFAULT_GOAL := help`, hand-crafted sectioned help, `@`-silenced commands, `## description` comments, `[pass]/[fail]/[warn]` status indicators. After `unimart` is installed, Make targets delegate to it.

## Development

```bash
go build ./...                 # Compile (fast check for errors)
go test ./...                  # Run all tests
make install                   # Build + symlink to ~/.local/bin/unimart
make init                      # Full bootstrap (fresh clone, no Nix yet)
unimart stockroom check        # Run contract validation across org
```

**Go version:** See `go.mod` for the minimum version. The Nix devShell (`nix develop`) provides the correct Go toolchain.

**Adding a new command:** Follow the Cobra pattern in `cmd/`. Each aisle parent (`deli.go`, `freezer.go`, etc.) is a `cobra.Command` with no `RunE`. Subcommands register themselves via `init()` with `parentCmd.AddCommand()`. See `cmd/freezer_up.go` for the current pattern.

**Org directory resolution:** `resolveOrgDir()` in `cmd/root.go` detects the org root. It tries `--org-dir` flag → `UNIMART_ORG_DIR` env → walk up from CWD looking for `.gitmodules`.

Load the `unimart-dev` skill for the complete development workflow.

## Documentation Flow

All source repos have a uniform `docs/` directory. Content flows through a sync pipeline into the **cdc vault** (the Obsidian-native knowledge base at `unimart-employee-handbooks/cdc/`):

```
Source repos (cmdr, idpbuilder)
  → cdc vault (rsync --delete + frontmatter injection)
    → Obsidian reads vault directly
```

Each repo's `docs/` is the source of truth. The cdc vault mirrors them via `rsync --delete`, then injects YAML frontmatter (`source`, `synced` date) for Obsidian Dataview. Frontmatter is committed to the vault repo.

The legacy `docs/` submodule (documentation aggregation hub) is being replaced by cdc. During transition both exist; new work targets cdc.

The pipeline contract is defined in `.docs-manifest.yml`. Pre-commit hooks trigger sync automatically when docs files are staged. Sync can also be triggered via `unimart newsstand sync`.

Load the `docs-sync` skill for pipeline details.

## Infrastructure

### Physical Hosts

| Host | Platform | System | Username |
|------|----------|--------|----------|
| `apple-studio-m2-max` | macOS | `aarch64-darwin` | `cmdr` |
| `apple-macbook-m3-pro` | macOS | `aarch64-darwin` | `mortimera` |
| `cmdr` | Arch Linux | `x86_64-linux` | `cmdr` |
| `cachyos` | Arch Linux | `x86_64-linux` | `cmdr` |

**Known issue**: Both `arch/cmdr` and `arch/cachyos` have `username = "cmdr"`, so host auto-detection on Linux may select the wrong host based on directory enumeration order.

### Git Hooks

Hybrid dispatch architecture (ADR-005). All hooks are Nix-managed via `cmdr/home/04-modules/cli/graduated/git/default.nix` and deployed to `~/.githooks/` via `unimart deli switch`.

**Global hooks** (`~/.githooks/`) run universal gates. Per-repo extensions go in `.githooks/<hook-name>`.

| Hook | Gates | Speed |
|------|-------|-------|
| `pre-commit` | nix fmt, go fmt, go vet, gitleaks, theme lint (cmdr) | Fast |
| `commit-msg` | conventional commit, DCO sign-off, `## Changes`, `## Executive Summary` | Instant |
| `post-commit` | docs sync to cdc vault, commit-log entry, cdc auto-commit | Medium |
| `pre-push` | go build, go test, nix flake check | Slow |

**Shared libraries** (`~/.githooks/lib/`): `gates.sh`, `commit-msg.sh`, `sync.sh`.

**Comment character**: `core.commentChar = ";"` — so `##` markdown headers in commit messages survive `commit.cleanup`.

**Self-reconciling docs**: Post-commit hook detects docs/ changes, rsyncs to cdc vault, extracts executive summaries into `cdc/commit-log/` entries with Dataview-queryable frontmatter, and auto-commits the vault.

### CI Workflows

| Workflow | Trigger | What it validates |
|----------|---------|-------------------|
| `validate.yml` | push/PR to main | Submodule init, remote URLs, AGENTS.md, docs structure, Makefile convention, theme contract |
| `drift-check.yml` | scheduled | Submodule pointers vs remote HEAD |
| `tag.yml` | manual | Org snapshot tagging |

## Key Paths

```
~/repos/github/idpbuilder/              This directory (meta repo)
├── AGENTS.md                            This file
├── CHANGELOG.md                         Release history and migration log
├── .docs-manifest.yml                   Pipeline contract (sources, vault, agent tasks)
├── .goreleaser.yaml                     Cross-platform release config
├── main.go                              CLI entry point
├── go.mod / go.sum                      Go module
├── flake.nix                            Nix packaging + devShell + overlay
├── docs/                                Org documentation and Architecture/ (moved from root)
│   ├── README.md                        Org docs home
│   ├── Architecture/                    Cross-repo contracts and ADRs
│   │   ├── README.md                    Overview
│   │   ├── contracts.md                 Interface specifications
│   │   └── adr/                         Architecture Decision Records
│   │       ├── 001-submodule-org-structure.md
│   │       ├── 002-cherry-pick-upstream.md
│   │       ├── 003-docs-sync-pipeline.md
│   │       ├── 004-theme-export-contract.md
│   │       └── 005-git-hook-gates.md    Hook gate system (ADR-005)
│   ├── Contributing/                    Contributing guides
│   ├── Getting-Started/                 Onboarding
│   └── Reference/                       Org conventions and tooling reference
├── cmd/                                 Cobra command tree
│   ├── root.go                          Root command, color helpers, org-dir resolution
│   ├── version.go                       Version command with ldflags injection
│   ├── open.go                          Top-level: open for business (6-step IDP startup)
│   ├── close.go                         Top-level: close up shop (symmetric inverse of open)
│   ├── reload.go                        Top-level: reconcile changes without teardown
│   ├── helpers.go                       Shared prereq/docker/build helpers
│   ├── deli.go                          Aisle parent
│   ├── switch.go                        deli switch (Nix apply)
│   ├── hosts.go                         deli hosts (list host configs)
│   ├── doctor.go                        deli doctor (prerequisite checks)
│   ├── bootstrap.go                     deli bootstrap (full setup)
│   ├── freezer.go                       Aisle parent (--container-runtime flag)
│   ├── freezer_up.go                    freezer up (4-step platform startup)
│   ├── freezer_down.go                  freezer down (cluster teardown)
│   ├── freezer_status.go               freezer status (cluster + ArgoCD + secrets)
│   ├── freezer_build.go                freezer build (idpbuilder make build)
│   ├── freezer_doctor.go               freezer doctor (prerequisite checks)
│   ├── freezer_bootstrap.go            freezer bootstrap (install prerequisites)
│   ├── freezer_repos.go                freezer repos (list/clone/status)
│   ├── freezer_repos_publish.go        freezer repos publish-to-gitea
│   ├── freezer_config.go               freezer config (show/generate)
│   ├── freezer_theme.go                freezer theme (load/generate k9s+tmux)
│   ├── newsstand.go                     Aisle parent
│   ├── sync_docs.go                     newsstand sync + RunDocsSync() shared helper
│   ├── stockroom.go                     Aisle parent
│   ├── stockroom_cmds.go               stockroom status/drift/update (native Go)
│   ├── stockroom_check.go              stockroom check (CI contract validation)
│   └── stockroom_sync.go              stockroom sync (push repos to remotes)
├── internal/
│   ├── host/detect.go                   Host auto-detection (scans meta.nix)
│   ├── platform/detect.go              Platform detection, command execution
│   ├── platform/browser.go             Platform-aware OpenBrowser(url)
│   ├── submodule/submodule.go          Dynamic submodule discovery (.gitmodules parser)
│   ├── builder/builder.go              Build(), Create(), Delete(), KindDeleteCluster()
│   ├── cluster/cluster.go              IsClusterRunning(), GetArgoApps(), GetSecrets(), GetGiteaAdminToken()
│   ├── colima/colima.go                Start(), Stop(), IsRunning(), EnsureDockerHost(), SocketPath()
│   ├── container/runtime.go            LoadImageIntoKind(), GatherImagesFromIdpbuilder()
│   ├── gitea/gitea.go                  RepoExists(), CreateRepo(), ListUserKeys(), auth helpers
│   ├── prereqs/                         Prerequisite checks and installers
│   │   ├── prereqs.go                  CheckResult, Platform(), CommandExists(), HasNix(), HasBrew()
│   │   ├── docker.go                   CheckDocker(), CheckColima(), InstallDocker()
│   │   ├── go.go                       CheckGo(), InstallGo()
│   │   ├── kind.go                     CheckKind(), InstallKind()
│   │   ├── kubectl.go                  CheckKubectl()
│   │   ├── podman.go                   CheckPodman(), InstallPodman()
│   │   └── workspace.go               CheckWorkspaceIdpbuilder()
│   ├── repos/repos.go                  ListRemote(), ListLocal(), Clone(), SetRemoteAndPush()
│   └── theme/                           Theme loading and config generation
│       ├── theme.go                     LoadFromOrg(), GenerateK9sSkin(), GenerateTmuxStatus()
│       └── fixtures/theme-sample.json  Test fixture
├── scripts/setup.sh                     make init bootstrap script (7 steps)
├── Makefile                             HAS_UNIMART delegation + shell fallbacks
├── packages/                            Custom ArgoCD Application YAMLs (passed to idpbuilder -p)
├── cmdr/                                Nix workstation config (submodule)
├── idpbuilder/                          IDP builder (submodule)
├── idpctl/                              CLI lifecycle tool (submodule, being absorbed)
├── docs/                                Docs aggregation hub (submodule, transitional)
│   ├── cmdr/                            Mirror of cmdr/docs/
│   ├── idpbuilder/                      Mirror of idpbuilder/docs/
│   ├── idpctl/                          Mirror of idpctl/docs/
│   ├── meta/                            Mirror of meta/docs/
│   ├── scripts/                         Sync pipeline scripts
│   └── README.md                        Hub documentation
└── unimart-employee-handbooks/
    ├── cdc/                             Obsidian vault (submodule) — synced doc mirrors
    │   ├── scripts/sync-docs.sh         Sync pipeline (rsync + frontmatter)
    │   ├── commit-log/                  Auto-generated commit summaries (Dataview-queryable)
    │   ├── cmdr/                        Mirror of cmdr/docs/
    │   ├── idpbuilder/                  Mirror of idpbuilder/docs/
    │   ├── meta/                        Mirror of meta/docs/
    │   └── 00-INDEX.md                  Vault map of content (MOC)
    └── cmdr/.gitkeep                    Future personal vault stub
```

## Migration: idpctl → unimart

### Status: Phase 3 Complete — Working on Phase 4

This is a full rebranding. `idpctl` is being absorbed into unimart entirely — no separate binary. This is intentionally breaking.

### Phase 1: Nix Distribution (COMPLETE)

Goal: Every `make switch` on every host installs unimart automatically via Nix.

- Add `overlays.default` to meta's `flake.nix` exposing `pkgs.unimart`
- Add `meta` as a flake input to cmdr's `flake.nix` (uses `git+ssh://` for private repo auth)
- Create `cmdr/home/04-modules/cli/graduated/unimart/default.nix` referencing `inputs.meta.packages`
- Wire into `cmdr/home/03-features/cli.nix`
- Pin via `nix flake lock` in cmdr

**Private repo auth note**: The `github:` flake scheme uses the GitHub REST API, which requires an access token for private repos. Using `git+ssh://git@github.com/idpbuilder/meta.git` instead leverages the user's existing SSH key. Determinate Nix manages the daemon with `nix.enable = false` in nix-darwin, so `nix.settings.access-tokens` cannot be set declaratively.

### Phase 2: Port Freezer Commands (COMPLETE)

All idpctl commands reimplemented as native Go inside `cmd/freezer_*.go` and `internal/`:
- 10 cmd files: `freezer_up`, `freezer_down`, `freezer_status`, `freezer_build`, `freezer_doctor`, `freezer_bootstrap`, `freezer_repos`, `freezer_repos_publish`, `freezer_config`, `freezer_theme`
- 8 internal packages: `builder`, `cluster`, `colima`, `container`, `gitea`, `prereqs`, `repos`, `theme`
- 9 test files across `cluster`, `colima`, `gitea`, `prereqs`, `theme`
- Only 2 direct deps: `cobra` + `fatih/color` (same as idpctl — no Viper, no K8s client)
- All external tool interaction via `os/exec` — shells out to CLIs

### Phase 3: Deprecate idpctl (COMPLETE)

- Removed `idpctl` from all active validation loops (CI workflows, Makefile SUBMODULES, `stockroom check`)
- Updated theme consumer from `idpctl/internal/theme/theme.go` to `internal/theme/theme.go` (meta's own ported package)
- Removed idpctl from `.docs-manifest.yml` source list
- Updated all Architecture docs, ADRs, and contracts to reflect unimart as the theme consumer
- idpctl submodule retained in `.gitmodules` (still physically exists) but no longer treated as active

### Phase 4: Cross-Host Rollout

Create a runbook for updating all 4 hosts. May involve fresh clones + `make init`.

### Phase 5: Cleanup

- Remove duplicate Makefile shell fallbacks (unimart guaranteed via Nix)
- Update CI workflows
- Wire up goreleaser for GitHub Releases

### Rebranding Scope

| Category | Files | Binary/Command Refs |
|----------|-------|---------------------|
| Go source (idpctl) | 17 | ~33 |
| Go source (meta) | 3 | ~12 |
| Makefiles | 2 | ~10 |
| Shell scripts | 3 | ~12 |
| Markdown/docs | ~30 | ~160 |
| CI/workflows | 4 | ~8 |
| Nix files | 1 | ~1 |
| Config (.gitmodules, .docs-manifest) | 2 | ~2 |
| **Total** | **~59** | **~226** |

### Key Decisions Made

1. **Full rebranding** — `idpctl` gets absorbed entirely, intentionally breaking
2. **Nix flake input** (not inline `buildGoModule`) — cmdr references `github:idpbuilder/meta` as a flake input; version pinned via `flake.lock`, bumped with `nix flake update meta`
3. **Fresh clones may be needed** on all hosts ("major juggling" expected)
4. **`make init` remains the bootstrap path** for fresh clones before Nix is configured
5. **`~/.local/bin/unimart` (from make install) will coexist** with Nix-managed binary; Nix store path takes precedence if `~/.nix-profile/bin` is earlier in PATH

## Working in This Directory

This is the org coordination hub. Every component repo is a git submodule with its own `AGENTS.md`. **When working across repos, read the target repo's `AGENTS.md` first** — it has repo-specific architecture, build/test commands, and conventions.

The context forms a mesh: this file provides the org-wide map (repos, relationships, roadmap, conventions). Each repo's `AGENTS.md` provides local context and points back here. Together they give full situational awareness from any entry point.

| Entry Point | Read This First | Then This |
|-------------|----------------|-----------|
| `meta/` (this dir) | This file | Target repo's `AGENTS.md` |
| `cmdr/` | `cmdr/AGENTS.md` | This file for org context |
| `idpbuilder/` | `idpbuilder/AGENTS.md` | This file for org context |
| `idpctl/` | `idpctl/AGENTS.md` | This file + **note: idpctl is deprecated** |
| `docs/` | `docs/Contributing/AGENTS.md` | This file for pipeline context |
| `unimart-employee-handbooks/cdc/` | `cdc/AGENTS.md` | This file for org context |

Cross-repo contracts live in `Architecture/contracts.md`. Architecture Decision Records are in `Architecture/adr/`.

For on-demand deep knowledge, load these skills:
- `unimart-dev` — Build, test, add commands, dev workflow
- `nix-modules` — cmdr's tiered module system, host discovery, meta.nix
- `docs-sync` — Documentation sync pipeline (source repos → cdc vault)
- `upstream-mgmt` — idpbuilder's cherry-pick workflow from cnoe-io
- `makefile-convention` — Shared Makefile style guide
