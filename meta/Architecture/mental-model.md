---
source: meta
synced: 2026-05-31
---
# Mental Model

This repo is a control plane for turning a physical machine into an idpbuilder development unit. The project is intentionally unconventional, but each layer should stay conventional and boring.

## One Sentence

`meta` owns orchestration, `cmdr` owns host desired state, `idpbuilder` owns the local IDP substrate, and `cdc` owns the generated handbook.

## Control Plane Map

```mermaid
flowchart TB
  human[Engineer / Operator]
  media[External M.2 installer]
  host[Physical host]
  meta[meta control plane]
  unimart[unimart operator CLI]
  cmdr[cmdr host desired state]
  idpbuilder[idpbuilder platform substrate]
  cdc[cdc employee handbook]
  obsidian[Obsidian optional UI]
  repos[Org repos / submodules]

  human --> media
  media --> host
  human --> unimart
  unimart --> meta
  meta --> repos
  unimart --> cmdr
  cmdr --> host
  unimart --> idpbuilder
  idpbuilder --> host
  repos --> cdc
  unimart --> cdc
  cdc --> obsidian
  cdc --> terminal[Terminal Markdown reading]
```

## Layer Cake

```mermaid
flowchart BT
  l0[Layer 0: Physical installer\nboot media, disk, base OS, network, user]
  l1[Layer 1: Baseline capability\nshell, git, ssh, editor, opencode]
  l2[Layer 2: Operator capability\nunimart, kubectl, kind, containers]
  l3[Layer 3: Developer experience\ntmux, nvim, TUI, GUI, desktop]
  l4[Layer 4: Local IDP runtime\nKind, ArgoCD, Gitea, ingress]
  l5[Layer 5: Real infra future\ncloud, remote clusters, registries, GitOps]

  l0 --> l1 --> l2 --> l3 --> l4 --> l5
```

The external installer should only get the host to Layer 0. `cmdr` and `unimart` converge the rest.

## Repo Roles

```mermaid
flowchart LR
  meta[meta\ncontrol plane + unimart]
  cmdr[cmdr\nNix/Home Manager]
  idpbuilder[idpbuilder\nKubernetes IDP]
  cdc[cdc\nemployee handbook]
  docs[docs\nlegacy hub]

  meta -->|submodule inventory| cmdr
  meta -->|submodule inventory| idpbuilder
  meta -->|submodule inventory| cdc
  meta -. transitional .-> docs
  cmdr -->|theme + hooks + host modules| meta
  idpbuilder -->|platform lifecycle| meta
  meta -->|docs sync orchestration| cdc
```

## Host Capability Contract

Hosts declare intent in `cmdr/home/02-hosts/<distro>/<host>/meta.nix`.

```nix
role = "developer-workstation";
capabilities = [ "baseline" "terminal-dev" "operator" "idp-local" "desktop" ];

features = [ "cli" "tui" "gui" ];
desktop = [ "hyprland" "dms" ];
```

```mermaid
flowchart TD
  metaNix[host meta.nix]
  semantic[role + capabilities\nplanning contract]
  concrete[features + desktop + sandbox + work\nNix import contract]
  plan[unimart deli plan]
  switch[unimart deli switch]
  host[converged host]

  metaNix --> semantic --> plan
  metaNix --> concrete --> switch --> host
  plan -. dry run .-> host
```

`role` and `capabilities` explain what the unit should become. `features`, `desktop`, `sandbox`, and `work` choose the concrete Nix modules that make it real.

## Tool Ownership

```mermaid
flowchart LR
  setup[scripts/setup.sh\nlowest bootstrap primitive]
  make[Make\nbootstrap + dev wrapper]
  unimart[unimart\ncanonical operator]
  nix[Nix/Home Manager\ndesired state]
  idp[idpbuilder\nplatform creation]

  make --> setup
  make --> unimart
  unimart --> nix
  unimart --> idp
```

Make is the ladder. `unimart` is the cockpit. Nix is the convergence engine.

## Documentation Flow

```mermaid
flowchart TB
  cmdrDocs[cmdr/docs]
  idpDocs[idpbuilder/docs]
  metaDocs[meta docs + root control-plane docs]
  sync[unimart newsstand sync\ncdc/scripts/sync-docs.sh]
  cdcMirrors[cdc mirrors\ncmdr / idpbuilder / meta]
  frontmatter[source + synced frontmatter]
  handbook[employee handbook]
  commitlog[cdc/commit-log]
  obsidian[Obsidian optional]
  terminal[Terminal Markdown]

  cmdrDocs --> sync
  idpDocs --> sync
  metaDocs --> sync
  sync --> cdcMirrors --> frontmatter --> handbook
  handbook --> obsidian
  handbook --> terminal
  hook[post-commit hook] --> sync
  hook --> commitlog
```

Source repos self-document. `cdc` is the generated handbook. Obsidian is a UI, not a dependency.

## Operating Loops

```mermaid
flowchart TD
  edit[Edit source]
  test[Run local checks]
  commit[git commit -s]
  pre[pre-commit fast gates]
  post[post-commit docs sync]
  cdcCommit[cdc auto-commit]
  push[git push]
  prepush[pre-push slow gates]

  edit --> test --> commit --> pre --> post --> cdcCommit --> push --> prepush
```

The spooky part is intentional: committing source changes can create a second cdc commit. Keep that behavior visible and predictable.

## Decision Rules

- If it provisions or operates hosts/platforms/repos/docs, it belongs in `unimart`.
- If it makes `unimart` available or helps local development, it may live in Make.
- If it describes desired host state, it belongs in `cmdr`.
- If it creates the IDP runtime, it belongs in `idpbuilder`.
- If it is generated knowledge or handbook content, it belongs in `cdc`.
- If it is a synced mirror, do not edit it directly.

## Shape To Preserve

The system should feel like this:

```text
external M.2 boots the machine
meta knows the fleet and contracts
unimart operates the control plane
cmdr converges the host
idpbuilder stands up the platform
cdc explains what happened
```

That is the mental model. Everything else is implementation detail.
