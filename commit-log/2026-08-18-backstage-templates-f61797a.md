---
repo: backstage-templates
date: 2026-08-18
commit: f61797a
type: fix
scope: 
tags: [commit-log]
---

# fix: prefill repoUrl in nix-sandbox template

The Nix Sandbox scaffolder form previously used a free-text Repository
picker, which invited pasting a full clone URL and caused gitea:commit
to fail with a 404. Replace it with a prefilled gitea: repo URL string so
the correct shared repo is always selected.
