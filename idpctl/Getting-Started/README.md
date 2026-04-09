---
source: idpctl
synced: 2026-04-09
---
# Getting Started

## Install

### One-line installer

```bash
curl -fsSL https://raw.githubusercontent.com/idpbuilder/idpctl/main/install.sh | bash
```

This detects your OS and architecture, downloads the latest release from GitHub, and installs the binary to `~/.local/bin`. Override the install directory:

```bash
INSTALL_DIR=/usr/local/bin curl -fsSL https://raw.githubusercontent.com/idpbuilder/idpctl/main/install.sh | bash
```

### Build from source

```bash
git clone https://github.com/idpbuilder/idpctl.git
cd idpctl
make build
```

This produces an `idpctl` binary in the current directory with embedded version metadata from git. Move it to a directory on your `PATH`, or symlink it:

```bash
ln -sf "$(pwd)/idpctl" ~/.local/bin/idpctl
```

## Quick Start

```bash
# 1. Check what's installed and what's missing
idpctl doctor

# 2. Install any missing prerequisites
idpctl bootstrap

# 3. Start the full IDP platform (Colima + build + cluster)
idpctl up

# 4. Check platform health, app status, and service URLs
idpctl status

# 5. Show service credentials
idpctl status --secrets

# 6. Tear down the cluster
idpctl down

# 7. Tear down the cluster and stop the Colima VM (macOS)
idpctl down --stop-colima
```

## Prerequisites

idpctl manages the following prerequisites:

| Tool | Required | Install method | Purpose |
|---|---|---|---|
| **Go** | 1.21+ | Nix (primary), Homebrew (fallback) | Building idpbuilder from source |
| **Docker CLI** | any | Nix `docker-client` (primary), Homebrew `docker` (fallback) | Container management (CLI only, no daemon) |
| **Colima** | any | Homebrew only | Docker daemon via Lima VM (macOS only) |
| **Kind** | any | Nix (primary), Homebrew (fallback) | Kubernetes-in-Docker cluster management |
| **kubectl** | any | Expected pre-installed | Kubernetes cluster interaction |
| **gh** | any | Expected pre-installed | GitHub CLI for `repos` commands |

`idpctl bootstrap` installs Go, Docker CLI, Colima (macOS), and Kind. kubectl and gh are expected to be pre-installed.

Nix is preferred over Homebrew for all tools except Colima. Colima requires Homebrew because it manages a Lima VM whose lifecycle integrates with macOS system services.
