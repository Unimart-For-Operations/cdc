---
source: cmdr
synced: 2026-04-09
---
# cmdr

Declarative developer workstation managed by **Nix flakes** and **Home Manager**. Defines the complete environment (shell, editor, terminal, tools) for each physical machine the user owns.

> **Org membership:** This repo is tracked as a git submodule in [idpbuilder/meta](https://github.com/idpbuilder/meta). See the meta repo's `Architecture/` for cross-repo contracts and ADRs.

## Critical Concept

**You are editing the config for the machine you are on.** Each host has a `meta.nix` that maps a physical machine to its features. When the user runs `make switch`, the config for _this specific machine_ is applied. Modularity and the deep tree structure are both the challenge and the strength.

## Project Structure

```
flake.nix                            Flake entry point
home/
├── 01-core/                         Base Home Manager config (always applied)
├── 02-hosts/                        Per-machine host definitions
│   └── <hostname>/
│       ├── default.nix              Host entry point
│       └── meta.nix                 Feature flags for this machine
├── 03-features/                     Feature aggregation
│   ├── base.nix                     Always-on packages
│   ├── cli.nix                      CLI tool modules
│   ├── tui.nix                      TUI tool modules
│   └── gui.nix                      GUI application modules
├── 04-modules/                      Tiered module tree
│   ├── cli/{graduated,incubating,sandbox}/
│   ├── tui/{graduated,incubating,sandbox}/
│   ├── gui/{graduated,incubating,sandbox}/
│   ├── work/                        Work-specific modules
│   └── _shared/theme/              Catppuccin Frappe shared palette
└── 05-platforms/                    OS-specific config (darwin/linux)
```

## Tiered Module System

Modules live in `home/04-modules/` organized by tier:
- **graduated** — Stable, well-tested, part of the standard config
- **incubating** — Working but still being refined
- **sandbox** — Experimental, may break

Each module is a Nix file (usually `default.nix`) that configures one tool. Feature files (`cli.nix`, `tui.nix`, `gui.nix`) import all modules at their tier level. A host's `meta.nix` declares which features are enabled.

Load the `nix-modules` skill for the complete module inventory and host discovery details.

## Key Commands

```bash
make switch              # Apply config for this machine
make doctor              # Check system health
make bootstrap           # First-time setup
make new-host            # Scaffold a new host definition
make list                # List available hosts
make fmt                 # Format all Nix files
make check               # Run flake checks
make sync-docs           # Sync docs to hub + Obsidian
```

## Code Style

- **Nix**: `nixfmt` formatter, attribute sets alphabetized, one package per line
- **Shell**: POSIX-compatible where possible, shellcheck clean
- **Commits**: `git commit -s` (DCO sign-off), conventional commits (`feat(scope):`, `fix:`, `docs:`)

## Anti-Patterns

- Do NOT use `environment.systemPackages` — use `home.packages` or program-specific options
- Do NOT hardcode paths — use `config.home.homeDirectory` or `config.xdg.*`
- Do NOT mix host-specific logic into shared modules — use `meta.nix` feature flags
- Do NOT flatten the module tree — respect graduated/incubating/sandbox tiers
- Do NOT reference old feature names (`terminal.nix`, `languages.nix`, `cloud.nix`) — use `cli.nix`, `tui.nix`, `gui.nix`

## Further Reading

See [docs/Contributing/README.md](docs/Contributing/README.md) for the full contributing guide with architecture details, bootstrap workflow, and code style guidelines.
