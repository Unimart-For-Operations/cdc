---
repo: meta
date: 2026-04-21
commit: dacbda7
type: refactor
scope: docs
tags: [commit-log]
---

# refactor(docs): unify directory tree structure across org — move Architecture/ into docs/

All org repos now follow identical docs/ structure. Meta no longer has separate top-level Architecture/ — all org documentation (contracts, ADRs, guides, onboarding) lives in meta/docs/ with the same structure as cmdr and idpbuilder. The sync pipeline now ingests docs from three sources (cmdr, idpbuilder, meta) into the cdc Obsidian vault. This unifies the org's knowledge base and ensures all repos follow the same documentation pattern.
