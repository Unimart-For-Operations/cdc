---
source: meta
synced: 2026-05-31
---
# ADR-001: Submodule Org Structure

**Status:** Accepted
**Date:** 2026-04-03
**Deciders:** cmdr

## Context

The idpbuilder org has repos (cmdr, idpbuilder, docs, plus deprecated idpctl) cloned as siblings under `~/repos/github/idpbuilder/`. Cross-repo contracts (theme export, docs sync, hook sharing, Makefile conventions) had developed organically but were entirely implicit -- no single place documented what each repo expected from its siblings.

The org root directory was not version-controlled, making it impossible to:
- Track known-good combinations of repo states
- Validate cross-repo contracts in CI
- Detect drift between submodule pointers and remote HEAD
- Onboard contributors who need to understand the multi-repo layout

## Decision

Create a meta repo (`idpbuilder/meta`) at the org root that tracks all repos as **git submodules**. The meta repo owns:
- Cross-repo architecture documentation and ADRs
- Contract validation via `make ci`
- Drift detection via `make drift` and GitHub Actions
- Org snapshot tags representing known-good submodule pointer combinations

Each submodule uses relative URLs (`../foo.git`) that resolve against the parent remote, and remains an independently-developed repo with its own branching, tagging, and release process.

## Alternatives Considered

### Monorepo
Merge all repos into one. Rejected because:
- cmdr (Nix) and idpbuilder (Go/K8s) have fundamentally different build systems
- idpbuilder is a fork of cnoe-io/idpbuilder; monorepo would break the cherry-pick workflow
- Repos have different access patterns and release cadences

### Loose convention (status quo)
Keep relying on AGENTS.md and tribal knowledge. Rejected because:
- No CI-enforced contract validation
- No drift detection
- No reproducible "known-good" state

### Repo manifest (like Android repo tool)
Use a manifest XML to define repo layout. Rejected because:
- Adds external tooling dependency
- Git submodules are native and well-understood
- Our repo count (4) doesn't justify manifest complexity

## Consequences

**Positive:**
- Single `git clone --recurse-submodules` bootstraps the entire org
- `make ci` validates all cross-repo contracts
- Org snapshot tags create reproducible checkpoints
- Architecture docs live alongside the code they describe

**Negative:**
- Submodule pointer updates require explicit commits in the meta repo
- Contributors must understand git submodule workflows
- Two-step process: commit in child repo, then update pointer in meta

**Mitigations:**
- `make update` automates pulling latest and staging submodule pointers
- `make drift` and CI workflow detect stale pointers
- README documents the workflow clearly
