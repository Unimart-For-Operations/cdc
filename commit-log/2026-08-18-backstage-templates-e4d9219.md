---
repo: backstage-templates
date: 2026-08-18
commit: e4d9219
type: fix
scope: 
tags: [commit-log]
---

# fix: use hyphen-free step id in nix-sandbox template

The gitea:commit step was id'd `commit-shared`, and ${{ steps.commit-shared.output... }}
references are parsed by Nunjucks as subtraction, rendering NaN/null and
failing the catalog:register input schema. Rename the step id to camelCase.
