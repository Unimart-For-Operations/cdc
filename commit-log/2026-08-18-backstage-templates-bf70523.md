---
repo: backstage-templates
date: 2026-08-18
commit: bf70523
type: fix
scope: 
tags: [commit-log]
---

# fix: include :8443 port in nix-sandbox terminal links

The nginx ingress is only reachable on the host via mapped port 8443
(127.0.0.1:8443 -> kind:443), but the scaffold output link and the
per-sandbox catalog-info.yaml link omitted the port, so the browser hit
127.0.0.1:443 where nothing listens.
