---
source: meta
synced: 2026-05-31
---
# ADR-002: Cherry-Pick Upstream Workflow

**Status:** Accepted
**Date:** 2026-04-03
**Deciders:** cmdr

## Context

The idpbuilder repo is a private fork of [cnoe-io/idpbuilder](https://github.com/cnoe-io/idpbuilder). We need to incorporate upstream improvements while maintaining local modifications (private features, org-specific configuration, additional CI workflows).

## Decision

Track upstream changes via **cherry-picking** rather than merge commits. The idpbuilder repo maintains an `upstream` remote pointing to `cnoe-io/idpbuilder` and selectively cherry-picks commits or ranges from upstream branches.

### Workflow

1. Fetch upstream: `git fetch upstream`
2. Review new commits: `git log upstream/main --oneline`
3. Cherry-pick individual commits or ranges: `git cherry-pick <sha>` or `git cherry-pick <start>..<end>`
4. Resolve conflicts, keeping local modifications where they diverge
5. Commit with DCO sign-off

### Conventions

- Cherry-picked commits retain their original commit message, prefixed or noted in the body
- Local modifications are kept in separate commits from upstream picks
- The `upstream` remote is never merged -- only cherry-picked

## Alternatives Considered

### Merge upstream
Regular `git merge upstream/main`. Rejected because:
- Creates noisy merge commits that obscure the local commit history
- Conflict resolution is all-or-nothing per merge
- Harder to skip specific upstream changes we don't want

### Rebase onto upstream
Rebase local changes on top of upstream. Rejected because:
- Rewrites local commit history, breaking submodule pointers in meta
- Force-push required after every rebase
- Risk of losing local modifications during complex rebases

### Maintain as independent fork (no upstream tracking)
Stop pulling upstream changes. Rejected because:
- Miss important bug fixes, security patches, and features
- Increasing divergence makes future reconciliation harder

## Consequences

**Positive:**
- Clean, linear commit history
- Granular control over which upstream changes to adopt
- Local modifications preserved without merge noise
- Submodule pointers in meta remain stable

**Negative:**
- Manual effort to cherry-pick (no automated sync)
- Must track which upstream commits have been picked
- Cherry-pick conflicts require individual resolution

**Mitigations:**
- idpbuilder Makefile has upstream management targets
- Periodic review cadence to avoid falling too far behind
