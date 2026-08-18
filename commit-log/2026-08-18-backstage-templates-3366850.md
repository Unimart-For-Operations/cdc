---
repo: backstage-templates
date: 2026-08-18
commit: 3366850
type: fix
scope: 
tags: [commit-log]
---

# fix: use query-string repoUrl format in nix-sandbox template

The prefilled repoUrl broke gitea:commit because parseRepoUrl expects
host?owner=X&repo=Y, not gitea:host/owner/repo. Switch the default to the
pickle-compatible query-string format.
