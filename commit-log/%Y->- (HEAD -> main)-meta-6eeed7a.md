---
repo: meta
date: %Y->- (HEAD -> main)
commit: 6eeed7a
type: feat
scope: hooks
tags: [commit-log]
---

# feat(hooks): add ADR-005 git hook gate system, update org docs

Completes the org-wide rollout of the Nix-managed git hook gate system
(ADR-005). Every repo in the idpbuilder org now enforces consistent
code quality gates, commit conventions, and documentation sync through
globally-deployed hooks. The ADR documents the architecture for future
contributors, and all AGENTS.md files across the org form a coherent
context mesh with cross-references and accurate hook documentation.
