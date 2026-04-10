---
repo: idpbuilder
date: %Y->- (HEAD -> main)
commit: 79a488c
type: feat
scope: hooks
tags: [commit-log]
---

# feat(hooks): adopt Nix-managed hook system, update docs

Adopts the org-wide Nix-managed git hook gate system for idpbuilder.
Hook installation is now handled by `unimart deli switch` instead of
per-repo make targets. Documentation updated to reflect the new hook
architecture and provide better org-level context for AI agents.
