---
source: meta
synced: 2026-05-31
---
# Physical Host Provisioning

`meta` is the control plane for turning a physical machine into an idpbuilder development unit. The project is intentionally unconventional, but each layer has a conventional boundary.

## Layers

| Layer | Owner | Responsibility |
|-------|-------|----------------|
| Physical installer | external M.2 / future archiso | Boot media, disk layout, base OS, networking, initial user, SSH/Git bootstrap. |
| Host desired state | `cmdr` | Nix/Home Manager configuration, feature modules, desktop/session modules, shell/editor/tooling. |
| Operator interface | `unimart` | Orchestrates host setup, platform lifecycle, repo inventory, docs sync, and validation. |
| Platform substrate | `idpbuilder` | Local Kubernetes IDP: Kind, ArgoCD, Gitea, ingress, package reconciliation. |
| Knowledge base | `unimart-employee-handbooks/cdc` | Self-documenting handbook/vault generated and synced by the control plane. |

The installer should get the host to a booted, reachable base system. `unimart` and `cmdr` should converge everything after that.

## Host Contract

Each host declares two semantic fields in `cmdr/home/02-hosts/<distro>/<host>/meta.nix`:

```nix
role = "developer-workstation";
capabilities = [ "baseline" "terminal-dev" "operator" "idp-local" "desktop" ];
```

`role` describes what the unit is meant to become. `capabilities` describe what the unit can do. These fields are semantic declarations for `meta`/`unimart` planning and documentation; they do not directly import Nix modules.

Concrete Nix imports remain controlled by:

- `features = [ "cli" "tui" "gui" ];`
- `desktop = [ "hyprland" "dms" ];`
- `sandbox = [ "wezterm" ];`
- `work = true;`

Common roles:

- `tty-engineer`: terminal-only engineering unit.
- `developer-workstation`: full local development workstation.
- `platform-operator`: workstation expected to run and operate the local IDP.

Common capabilities:

- `baseline`: shell, git, SSH, core utilities.
- `terminal-dev`: editor, tmux, terminal UX, AI coding tools.
- `operator`: Kubernetes/container/platform tooling.
- `idp-local`: can stand up idpbuilder locally.
- `desktop`: owns a graphical session.
- `work`: loads employer-specific configuration.

## Handbook Contract

The `cdc` vault is the user's generated employee handbook. Obsidian is the preferred UI, but Markdown remains the source format and must be useful from a terminal.

Rules:

- Generated/synced knowledge should land in `unimart-employee-handbooks/cdc`.
- Source repo docs remain the source of truth for project documentation.
- Each source repo documents itself in its own `docs/` directory; cdc mirrors those docs into the employee handbook.
- The vault may contain generated frontmatter and operational notes for Obsidian.
- The system must remain useful without Obsidian installed.

## First Installer Target

The external M.2 should initially provide a boring handoff:

```bash
git clone --recurse-submodules git@github.com:idpbuilder/meta.git
cd meta
make init
unimart deli hosts
unimart deli plan <host>
unimart deli doctor
```

Only after that flow is reliable should destructive disk-install automation be added.

`unimart deli plan [host]` is the planning contract for installer work. It reads the target host's `role` and `capabilities`, prints the expected phases, and performs no mutations.
