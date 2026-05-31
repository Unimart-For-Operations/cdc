---
source: meta
synced: 2026-05-31
---
# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- **Phase 3 — Deprecate idpctl**:
  - Removed idpctl from all active validation loops: CI workflows (`validate.yml`, `drift-check.yml`, `tag.yml`), Makefile `SUBMODULES`, and docs validation loop
  - Updated theme consumer check from `idpctl/internal/theme/theme.go` to `internal/theme/theme.go` (meta's own ported package) in `stockroom check`, Makefile, and `validate.yml`
  - Removed idpctl from `.docs-manifest.yml` source list and frontmatter source field
  - Removed idpctl `safe.directory` entry from `containers/test-init.sh`
  - Updated all Architecture docs (README, contracts, ADRs 001/003/004/005) to reflect unimart as theme consumer
  - idpctl submodule retained in `.gitmodules` but marked deprecated in all documentation
- `stockroom sync` command — push all org repos to their configured remotes
- `stockroom check` command added to README stockroom section

### Added
- Nix distribution: meta flake exposes `overlays.default` for cmdr consumption
- cmdr unimart module at `04-modules/cli/graduated/unimart/default.nix`
- cmdr flake input `meta` referencing `github:idpbuilder/meta`
- CHANGELOG.md tracking release history and migration progress
- **Phase 2 — Port all idpctl commands to unimart freezer**:
  - 10 cmd files: `freezer_up`, `freezer_down`, `freezer_status`, `freezer_build`, `freezer_doctor`, `freezer_bootstrap`, `freezer_repos`, `freezer_repos_publish`, `freezer_config`, `freezer_theme`
  - 8 internal packages: `builder`, `cluster`, `colima`, `container`, `gitea`, `prereqs`, `repos`, `theme`
  - 9 test files across `cluster`, `colima`, `gitea`, `prereqs`, `theme`
  - `--container-runtime` persistent flag on freezer parent command
  - Shared helpers in `cmd/root.go`: `idpbuilderDir()`, `promptString()`, `promptYesNo()`
- **`unimart open` — top-level command to bring the full IDP platform online**:
  - 6-step sequence: prereqs, Colima, build, create, publish repos to Gitea, open browser
  - `cmd/open.go`: opinionated defaults (`--dev-password`, `--no-exit=false`, HTTPS publish)
  - `cmd/helpers.go`: extracted shared prereq/docker/build logic from `freezer_up`
  - `internal/platform/browser.go`: platform-aware `OpenBrowser(url)` helper
  - `packages/.gitkeep`: custom ArgoCD Application YAML directory (starts empty)
  - Flags: `--skip-build`, `--no-browser`, `--recreate`; extra args pass through to `idpbuilder create`
- **`unimart close` — symmetric inverse of `open`**:
  - `cmd/close.go`: tears down IDP cluster, optionally stops Colima on macOS
  - Flags: `--stop-colima` (macOS only), `--yes` to skip confirmation
- **Gitea org management** — `internal/gitea/gitea.go`:
  - `OrgExists()`, `CreateOrg()`, `EnsureOrg()` for managing Gitea organizations
  - Publish flow now creates `idpbuilder` org and publishes repos under it (not `giteaAdmin`)
  - Meta repo itself is now included in the publish flow

### Fixed
- `internal/repos/repos.go` — fixed 5 bugs in `SetRemoteAndPush`:
  - Missing `.Dir` on git commands (ran in process CWD instead of submodule dir)
  - No TLS handling for self-signed certs (added `GIT_SSL_NO_VERIFY=true`)
  - No HTTP authentication for non-interactive pushes (embedded token in push URL)
  - Clobbering `origin` remote with Gitea URL (now uses dedicated `gitea` remote)
  - Pre-push hooks firing on mirror pushes (added `--no-verify`)
- Credentials text in `open.go` summary now distinguishes ArgoCD (`admin`) from Gitea (`giteaAdmin`)
- Default publish owner changed from `giteaAdmin` to `idpbuilder` org in both `open.go` and `freezer_repos_publish.go`

### Changed
- AGENTS.md: added distribution section, infrastructure details, migration plan with rebranding scope audit
- AGENTS.md: updated to reflect Phase 2 completion (source layout, key paths, migration status)
- AGENTS.md: added top-level commands table (`open`, `close`, `version`), `packages/` dir, `browser.go`, `close.go` to key paths
- README.md: updated freezer command reference (no longer stubs), added cdc to repos table
- README.md: added "Open for Business" and "Close Up Shop" sections
- `cmd/freezer_up.go`: refactored to use shared helpers from `cmd/helpers.go`

### Removed
- `cmd/freezer_cmds.go` — stub file replaced by 10 individual command files

## [0.2.0] — 2026-04-07

### Added
- `stockroom check` command — native Go port of 6-step CI contract validation
- Full Makefile delegation via `HAS_UNIMART` for: `status`, `drift`, `update`, `ci`, `sync-docs`

### Fixed
- Infinite recursion: stockroom commands reimplemented natively instead of shelling back to Make
- `git describe --tags` stderr noise suppressed via `CommandOutputSilent`
- `result` symlink gitignore (bare `result` in addition to `result/`)

## [0.1.0] — 2026-04-04

### Added
- Go module `github.com/idpbuilder/meta` with Cobra CLI scaffold
- Root command with `--org-dir` and `--verbose` flags, org-dir auto-detection
- Four aisle parent commands: `deli`, `freezer`, `newsstand`, `stockroom`
- `deli` subcommands: `switch`, `hosts`, `doctor`, `bootstrap` (all working)
- `freezer` subcommands: `up`, `down`, `status`, `build`, `doctor`, `repos`, `config` (stubs)
- `newsstand sync` — triggers docs sync pipeline
- `stockroom status/drift/update` — native Go submodule management
- `version` command with ldflags injection (`Version`, `GitCommit`, `BuildDate`)
- `internal/host/` — host auto-detection scanning cmdr `meta.nix` files
- `internal/platform/` — platform detection, command execution utilities
- `flake.nix` with `buildGoModule`, devShell, and `nixfmt-rfc-style` formatter
- `.goreleaser.yaml` for cross-platform release builds
- `scripts/setup.sh` — 7-step bootstrap (`make init`), builds unimart at step 6
- `Makefile` with CLI build targets and shell fallbacks for pre-unimart environments

## [0.0.1] — 2026-04-03

### Added
- Meta repo initialized with git submodules: cmdr, idpbuilder, idpctl, docs
- `.gitmodules` with `ignore = dirty` for all submodules
- Architecture docs and ADRs
- CI workflows: `validate.yml`, `drift-check.yml`, `tag.yml`
- `.docs-manifest.yml` pipeline contract

[Unreleased]: https://github.com/idpbuilder/meta/compare/v0.2.0...HEAD
[0.2.0]: https://github.com/idpbuilder/meta/compare/v0.1.0...v0.2.0
[0.1.0]: https://github.com/idpbuilder/meta/compare/v0.0.1...v0.1.0
[0.0.1]: https://github.com/idpbuilder/meta/releases/tag/v0.0.1
