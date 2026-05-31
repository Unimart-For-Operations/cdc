---
source: meta
synced: 2026-05-31
---
# Tooling Contract

`unimart` is the canonical operator interface for the meta control plane. `make` is the bootstrap and developer convenience layer.

## Ownership

| Task | Canonical Interface | Notes |
|------|---------------------|-------|
| Fresh machine onboarding | `make init` | Works before `unimart` is installed. |
| Workstation apply/check/list | `unimart deli ...` | Delegates into the configured host system. |
| IDP platform lifecycle | `unimart open`, `unimart close`, `unimart freezer ...` | Cluster, runtime, build, repo publishing. |
| Documentation sync | `unimart newsstand sync` | Syncs source repo docs into the cdc handbook; `make sync-docs` delegates after install. |
| Repo coordination | `unimart stockroom ...` | Status, drift, update, sync, contract checks. |
| CLI development | `make build`, `make install`, `make dev`, `make fmt`, `make vet` | Local Go development loop. |
| CI contract validation | `unimart stockroom check` | `make ci` and `make check` delegate after install. |
| Shell completion | `unimart completion <shell>` | `make completion` installs a generated completion file locally. |

## Make Targets

Make targets should fall into one of two categories:

- Bootstrap/development targets that require source checkout context: `init`, `build`, `install`, `dev`, `fmt`, `vet`, `test`.
- Compatibility delegates to `unimart`: `status`, `drift`, `update`, `sync-docs`, `ci`, `check`.

Do not add new operational behavior only to `Makefile`. Add it to `unimart` first, then add a Make delegate only if it helps bootstrap or muscle memory.

## Completion

Generate completion directly:

```bash
unimart completion zsh > ~/.local/share/zsh/site-functions/_unimart
unimart completion bash > ~/.local/share/bash-completion/completions/unimart
unimart completion fish > ~/.config/fish/completions/unimart.fish
```

Or use the Make wrapper:

```bash
make completion
make completion COMPLETION_SHELL=bash
make completion COMPLETION_SHELL=fish
```

For Nix-managed hosts, completion should eventually be installed by the `cmdr` unimart module rather than by hand.
