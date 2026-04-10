---
repo: cmdr
date: %Y->- (HEAD -> main)
commit: f53a5d5
type: feat
scope: hooks
tags: [commit-log]
---

# feat(hooks): implement Nix-managed git hook gate system (ADR-005)

Introduces a Nix-managed git hook gate system that enforces code quality,
commit conventions, and documentation sync across the entire idpbuilder
org. All hooks are generated as Nix derivations and deployed via
`unimart deli switch`, eliminating per-repo hook installation scripts.
The system includes a self-reconciling documentation pipeline that
automatically syncs docs changes to the cdc Obsidian vault and generates
Dataview-queryable commit-log entries. Architecture documented in ADR-005.
