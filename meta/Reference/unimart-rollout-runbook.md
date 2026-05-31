---
source: meta
synced: 2026-05-31
---
# unimart Cross-Host Rollout Runbook (Phase 4 + Phase 5)

Operational runbook for finishing the idpctl -> unimart migration across all hosts in the idpbuilder organization.

This runbook is written for the current host fleet:
- `apple-studio-m2-max` (macOS, `aarch64-darwin`, user `cmdr`)
- `apple-macbook-m3-pro` (macOS, `aarch64-darwin`, user `mortimera`)
- `cmdr` (Arch Linux, `x86_64-linux`, user `cmdr`)
- `cachyos` (Arch Linux, `x86_64-linux`, user `cmdr`)

## Scope

### Phase 4: Cross-Host Rollout

Goal: all hosts can run `unimart` from Nix-managed configuration and complete baseline health checks.

### Phase 5: Cleanup

Goal: remove transitional migration debt once Phase 4 is verified on all hosts.

## Safety Rules

- Use a dedicated branch for rollout work in `meta` and `cmdr`.
- Do not run destructive git commands (`reset --hard`, force-checkout) during rollout.
- Keep at least one known-good host untouched until two hosts are green.
- If any host fails post-switch validation, stop and rollback that host before continuing.

## Prerequisites

Run from `meta/` on each host:

```bash
unimart version
unimart stockroom status
unimart stockroom check
```

Expected baseline:
- `stockroom check` passes.
- Dirty working trees are understood and intentional.
- `cmdr` input `meta` is pinned to the commit you intend to roll out.

## Rollout Strategy

Use a canary sequence to limit blast radius:

1. `apple-studio-m2-max` (primary macOS canary)
2. `cmdr` (primary Linux canary)
3. `apple-macbook-m3-pro`
4. `cachyos`

Do not advance to the next host until the current host passes the validation gate.

## Validation Gate (Required Per Host)

A host is green only if all commands below pass:

```bash
unimart deli doctor
unimart deli switch
unimart stockroom check
unimart open --skip-build --no-browser
unimart close --yes
```

If `unimart open --skip-build --no-browser` is too heavy for a given maintenance window, use this reduced gate:

```bash
unimart deli doctor
unimart deli switch
unimart stockroom check
unimart freezer doctor
```

The full gate is still required before declaring rollout complete.

## Per-Host Procedure

On each host:

1. Ensure clean working context for orchestration repos.
```bash
cd ~/repos/github/idpbuilder/meta
unimart stockroom status
```

2. Update local repos and submodule pointers to target rollout state.
```bash
git pull --ff-only
git submodule update --init --recursive
unimart stockroom status
```

3. Apply workstation configuration.
```bash
unimart deli switch
```

4. Confirm `unimart` resolves from the expected path order.
```bash
which -a unimart
unimart version
```

5. Run validation gate commands.

6. Capture host result in rollout log (template below).

## Rollout Log Template

Copy into your tracking issue or PR description:

```md
- Host: <hostname>
- Date: <YYYY-MM-DD>
- Operator: <name>
- Meta commit: <sha>
- Cmdr lock includes meta commit: yes/no
- Gate results:
  - unimart deli doctor: pass/fail
  - unimart deli switch: pass/fail
  - unimart stockroom check: pass/fail
  - unimart open --skip-build --no-browser: pass/fail
  - unimart close --yes: pass/fail
- Notes: <issues, timings, follow-ups>
```

## Latest Execution Record

- Host: `apple-studio-m2-max`
- Date: `2026-04-24`
- Operator: `cmdr`
- Meta commit: `417e4a4` (`unimart v0.1.0-37-g417e4a4-dirty`)
- Cmdr lock includes meta commit: `unknown` (not explicitly re-verified in this run)
- Gate results:
  - `unimart deli doctor`: `pass`
  - `unimart deli switch`: `pass`
  - `unimart stockroom check`: `pass` (with existing warn-level policy findings)
  - `unimart open --skip-build --no-browser`: `pass`
  - `unimart close --yes`: `pass`
- Notes:
  - Existing warn-only checks remain: `idpbuilder` missing `help` target; `docs` missing `sync-docs` target.
  - During `open`, transient ArgoCD session EOF errors appeared while services converged; create completed successfully and platform reached ready state.

## Rollback Procedure (Per Host)

If a host fails after `deli switch`:

1. Revert `cmdr` to prior known-good lock state.
2. Run `unimart deli switch` again from the known-good state.
3. Re-run `unimart deli doctor`.
4. Defer that host and continue only if at least one canary host remains green.

Minimal rollback commands:

```bash
cd ~/repos/github/idpbuilder/cmdr
git checkout <known-good-branch-or-tag>
nix flake lock --recreate-lock-file  # only if policy requires lock reset
cd ../meta
unimart deli switch
unimart deli doctor
```

Use the exact rollback approach your branch policy requires (pin rollback via branch, tag, or lockfile commit).

## Phase 5 Cleanup Checklist

Start only after all hosts are green.

1. Remove obsolete shell fallback paths in `meta/Makefile` that duplicate guaranteed `unimart` behavior.
2. Remove stale idpctl references from active docs in `meta/docs/` where unimart is now authoritative.
3. Keep `idpctl` submodule only if explicitly needed for history; otherwise plan archival/removal.
4. Tighten `stockroom check` warnings into hard failures where policy should be mandatory.
5. Align CI workflows with post-migration assumptions (no idpctl dependency in active gates).
6. Publish release/tag for the first fully migrated snapshot.

## Definition of Done

Migration is complete when all statements are true:

- All four hosts pass the full validation gate.
- `cmdr` lockfile pins the intended `meta` commit and is deployed on all hosts.
- Day-to-day workflows use `unimart` commands only.
- No active CI or docs path depends on idpctl as the operational CLI.
- A snapshot tag marks the known-good post-migration state.

## Known Risk: Linux Host Auto-Detection

Two Linux hosts currently share `username = "cmdr"`, which can cause ambiguous auto-detection.

Mitigation during rollout:
- Prefer explicit host targeting flags/options where available.
- Execute rollout from the intended host's own checkout.
- Record selected host identity in the rollout log.

Follow-up hardening:
- Add deterministic tie-breaking or explicit host override in host detection logic.
