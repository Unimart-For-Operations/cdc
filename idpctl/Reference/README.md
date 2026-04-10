---
source: idpctl
synced: 2026-04-10
---
# Command Reference

## Command Tree

```
idpctl
├── doctor                      Check prerequisites and workspace health
├── bootstrap [-y]              Install missing prerequisites
├── up [flags] [-- extra-args]  Start the full IDP platform
├── down [flags]                Tear down the IDP cluster
├── build                       Build idpbuilder from source
├── status [--secrets]          Show platform status and health
├── repos                       Manage organization repositories
│   ├── list                    List remote repos in the org
│   ├── clone [repo-name]      Clone one or all repos
│   └── status                  Show git status of local repos
└── version                     Print version information
```

## Global Flags

| Flag | Short | Type | Default | Description |
|---|---|---|---|---|
| `--org-dir` | | `string` | auto-detect | Path to the idpbuilder organization directory |
| `--verbose` | `-v` | `bool` | `false` | Enable verbose output |
| `--container-runtime` | | `string` | `docker` | Container runtime to use: `docker` (default) or `podman` (experimental) |

---

## idpctl doctor

Check all prerequisites and workspace health.

```bash
idpctl doctor
```

**What it checks:**

| Category | Checks |
|---|---|
| Prerequisites | Go, Docker CLI, Colima (macOS only), Kind, kubectl |
| Package managers | Homebrew, Nix |
| Workspace | Org directory exists, idpbuilder repo cloned, binary built, Makefile present |

**Output format:**

Each check is reported with a color-coded tag:

- `[pass]` — installed and working
- `[warn]` — installed but not fully functional (e.g., Docker CLI present but daemon not reachable)
- `[fail]` — missing or broken

**Exit code:** Non-zero if any check fails.

**Example output:**

```
Prerequisites:
  [pass] go (go1.24.1)
  [pass] docker (27.5.1)
  [pass] colima (0.8.1) — running
  [pass] kind (kind v0.27.0)
  [pass] kubectl (v1.32.3)

Package Managers:
  [pass] homebrew
  [pass] nix

Workspace:
  [pass] org directory (/Users/you/repos/github/idpbuilder)
  [pass] idpbuilder repo
  [warn] idpbuilder binary — not built — run: idpctl build

! 1 warning(s)
```

---

## idpctl bootstrap

Interactively install missing prerequisites.

```bash
idpctl bootstrap
idpctl bootstrap -y    # Skip confirmation prompts
```

| Flag | Short | Type | Default | Description |
|---|---|---|---|---|
| `--yes` | `-y` | `bool` | `false` | Skip confirmation prompts |

**Installation strategy:**

| Prerequisite | Primary (Nix) | Fallback (Homebrew) | Notes |
|---|---|---|---|
| Go | `nix profile install nixpkgs#go` | `brew install go` | |
| Docker CLI | `nix profile install nixpkgs#docker-client` | `brew install docker` | CLI only, no daemon |
| Colima | — | `brew install colima` | macOS only, requires Homebrew (VM lifecycle) |
| Kind | `nix profile install nixpkgs#kind` | `brew install kind` | |

**Behavior:**

1. Detects available package managers (Nix, Homebrew). Fails if neither is available.
2. For each prerequisite: checks if already installed (skips if so), prompts for confirmation, runs the installer, verifies the install succeeded.
3. Reports total count of newly installed prerequisites.

Colima is intentionally installed via Homebrew even when Nix is available. Colima manages a Lima VM and its lifecycle integrates tightly with macOS system services, making Homebrew the better fit.

---

## idpctl up

Start the full IDP platform.

```bash
idpctl up
idpctl up --skip-build
idpctl up --cpu 6 --memory 12 --disk 100
idpctl up -- --recreate    # Pass extra args to idpbuilder create
```

| Flag | Type | Default | Description |
|---|---|---|---|
| `--skip-build` | `bool` | `false` | Skip the build step (use existing binary) |
| `--cpu` | `int` | `4` | Colima VM CPU count (macOS only) |
| `--memory` | `int` | `8` | Colima VM memory in GB (macOS only) |
| `--disk` | `int` | `60` | Colima VM disk in GB (macOS only) |

Arguments after `--` are passed through to `idpbuilder create`.

**Startup sequence:**

| Step | macOS | Linux |
|---|---|---|
| **[1/4] Check prerequisites** | Go, Docker, Colima, Kind, kubectl | Go, Docker, Kind, kubectl |
| **[2/4] Ensure Docker** | Start Colima VM, set `DOCKER_HOST`, verify daemon | Verify Docker daemon is reachable |
| **[3/4] Build idpbuilder** | `make build` in idpbuilder directory | Same |
| **[4/4] Create IDP** | `./idpbuilder create` | Same |

After successful startup, prints service URLs:

```
Service URLs:
  ArgoCD:  https://argocd.cnoe.localtest.me:8443
  Gitea:   https://gitea.cnoe.localtest.me:8443
```

---

## idpctl down

Tear down the IDP platform.

```bash
idpctl down
idpctl down -y                # Skip confirmation
idpctl down --stop-colima     # Also stop the Colima VM (macOS)
idpctl down --stop-colima -y  # No confirmation, full teardown
```

| Flag | Type | Default | Platform | Description |
|---|---|---|---|---|
| `--yes` / `-y` | `bool` | `false` | all | Skip confirmation prompts |
| `--stop-colima` | `bool` | `false` | macOS only | Also stop the Colima VM |

**Teardown behavior:**

| Step | macOS | Linux |
|---|---|---|
| **[1/N] Delete IDP** | Delete Kind cluster | Delete Kind cluster |
| **[2/2] Stop Colima** | If `--stop-colima` is set | N/A |

**Cluster deletion strategy:**

1. If the `idpbuilder` binary exists, runs `./idpbuilder delete` for a clean teardown (removes cluster + any idpbuilder-managed resources).
2. If the binary is not built, falls back to `kind delete cluster` directly.

---

## idpctl build

Build idpbuilder from source.

```bash
idpctl build
idpctl build -v    # Verbose — show make output
```

Runs `make build` in the idpbuilder repository directory. Verifies the Makefile exists before building and checks that the binary was produced after building.

---

## idpctl status

Show IDP platform status.

```bash
idpctl status
idpctl status --secrets
```

| Flag | Type | Default | Description |
|---|---|---|---|
| `--secrets` | `bool` | `false` | Show credentials (passwords) |

**Sections displayed:**

| Section | Description |
|---|---|
| **Colima** (macOS) / **Docker** (Linux) | VM or daemon status |
| **Cluster** | Kind cluster name and running state |
| **ArgoCD Applications** | Sync status and health of all ArgoCD applications |
| **Service URLs** | ArgoCD and Gitea URLs |
| **Credentials** | ArgoCD and Gitea admin passwords (with `--secrets`) |

**Application health indicators:**

- `[ok]` — Synced and Healthy
- `[--]` — Not fully synced or not Healthy
- `[!!]` — Degraded or Missing

**Example output:**

```
Colima:
  [ok] running

Cluster:
  [ok] Kind cluster: localdev

ArgoCD Applications:
  [ok] argocd                         sync=Synced    health=Healthy
  [ok] gitea                          sync=Synced    health=Healthy
  [ok] nginx                          sync=Synced    health=Healthy

Service URLs:
  ArgoCD:     https://argocd.cnoe.localtest.me:8443
  Gitea:      https://gitea.cnoe.localtest.me:8443

  (use --secrets to show credentials)
```

---

## idpctl repos

Manage organization repositories. Requires the [GitHub CLI (`gh`)](https://cli.github.com/) to be installed and authenticated.

### idpctl repos list

List all repositories in the GitHub organization.

```bash
idpctl repos list
idpctl repos list --org cnoe-io
```

| Flag | Type | Default | Description |
|---|---|---|---|
| `--org` | `string` | `idpbuilder` | GitHub organization name |

Displays repository name, description, and flags (private, fork).

### idpctl repos clone

Clone repositories from the organization.

```bash
idpctl repos clone              # Clone all repos
idpctl repos clone idpbuilder   # Clone a specific repo
idpctl repos clone --org cnoe-io idpbuilder
```

Clones into the organization directory. Skips repos that already exist locally.

### idpctl repos status

Show git status of all locally cloned repos.

```bash
idpctl repos status
```

Scans the organization directory for git repositories and displays the current branch and clean/dirty status for each.

---

## idpctl version

Print version information.

```bash
idpctl version
```

Output:

```
idpctl version dev (commit: abc1234, built: 2025-01-15T10:30:00Z)
```

Version metadata is injected at build time via Go linker flags. Development builds show `version dev`.

---

## Configuration

### Organization Directory

idpctl expects an organization directory containing cloned repositories from the idpbuilder GitHub org. The directory structure looks like:

```
~/repos/github/idpbuilder/     # org directory
├── idpbuilder/                # main project (required)
├── idpctl/                    # this tool
├── cmdr/                      # nix workstation config
└── docs/                      # org documentation
```

**Detection priority:**

1. `--org-dir` flag (explicit override)
2. `IDPCTL_ORG_DIR` environment variable
3. Current working directory (if it contains an `idpbuilder/` subdirectory)
4. Parent of current working directory (if you're inside a sub-repo)
5. `~/idpbuilder` (fallback default)

```bash
# Explicit flag
idpctl --org-dir /path/to/org doctor

# Environment variable
export IDPCTL_ORG_DIR=/path/to/org
idpctl doctor

# Auto-detect (run from within the org directory or any sub-repo)
cd ~/repos/github/idpbuilder
idpctl doctor
```

### Colima Resources

The `up` command starts Colima with resource defaults tuned for running Kind with the full IDP stack:

| Resource | Default | Flag |
|---|---|---|
| CPU | 4 cores | `--cpu` |
| Memory | 8 GB | `--memory` |
| Disk | 60 GB | `--disk` |

Override for larger deployments:

```bash
idpctl up --cpu 8 --memory 16 --disk 120
```

### Environment Variables

| Variable | Description |
|---|---|
| `IDPCTL_ORG_DIR` | Override the organization directory path |
| `DOCKER_HOST` | Managed by idpctl on macOS — set to Colima's socket automatically |
