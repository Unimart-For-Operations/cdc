---
repo: docs
date: %Y->- (HEAD -> main)
commit: 209b05e
type: feat
scope: hooks
tags: [commit-log]
---

# feat(hooks): adopt Nix-managed hook system, remove dead hook script

Completes the docs hub migration to the Nix-managed hook system.
The dead pre-commit hook script that triggered docs sync is removed —
sync now happens automatically via the global post-commit hook when
docs/ files change. This repo is transitional (being replaced by
the cdc Obsidian vault) but remains functional during the migration.
