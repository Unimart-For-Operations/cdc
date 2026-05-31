---
source: meta
synced: 2026-05-31
---
# ADR-004: Theme Export Contract

**Status:** Accepted
**Date:** 2026-04-03
**Deciders:** cmdr

## Context

cmdr manages the workstation's visual theme via Nix (currently Catppuccin Frappe). unimart, the unified Go CLI built from the meta repo, needs to apply consistent theming to its TUI output, tmux status bar generation, and k9s skin generation. The theme definition lives in cmdr's Nix modules and needs to be consumed by non-Nix tools.

## Decision

Establish a **producer-consumer contract** where cmdr exports theme data as JSON and unimart imports it.

### Producer (cmdr)

`scripts/theme-export.sh` evaluates the Nix theme module and writes JSON to stdout:

```bash
./scripts/theme-export.sh [theme-name]  # default: catppuccin-frappe
```

**JSON schema:**

```json
{
  "name": "string",
  "palette": { "<color-name>": "<hex>" },
  "semantic": {
    "fg": "<hex>", "bg": "<hex>", "bgPanel": "<hex>",
    "accent": "<hex>", "warn": "<hex>", "ok": "<hex>"
  },
  "terminal": { "ansi": { "<name>": "<hex>" } },
  "fonts": { "<role>": { "<key>": "<value>" } }
}
```

The `semantic` section is the stable contract surface. `palette`, `terminal`, and `fonts` are passed through but consumers should not rely on specific keys within them.

### Consumer (unimart)

`internal/theme/theme.go` (in the meta repo) provides `LoadFromOrg(orgDir, themeName)`:

1. **Preferred:** Execute `<orgDir>/cmdr/scripts/theme-export.sh` with theme name
2. **Fallback:** Read static `<orgDir>/theme.json` or `<orgDir>/cmdr/theme.json`
3. **Parsing:** Strict decode with tolerant fallback (forward-compatible with new fields)

Current consumers of the loaded theme:
- `GenerateTmuxStatus()` -- uses `semantic.fg`, `semantic.accent`, `semantic.bgPanel`
- `GenerateK9sSkin()` -- uses `semantic.fg`, `semantic.bgPanel`, `semantic.accent`, `semantic.warn`, `semantic.ok`

Both provide hardcoded Catppuccin Frappe defaults if semantic keys are missing.

### Static File Workflow

For environments without Nix (CI, fresh clones), the theme can be pre-generated:

```bash
# In cmdr/
./scripts/theme-export.sh > ../theme.json
# Or
./scripts/theme-export.sh > theme.json
```

The `.workspace/` directory at the org root can hold generated artifacts like `theme.json`.

## Alternatives Considered

### Hardcode theme in unimart
Duplicate color values in Go. Rejected because:
- Theme changes in cmdr would require manual sync to unimart
- No single source of truth
- Violates DRY across repos

### Shared config file checked into both repos
Maintain a `theme.json` in both cmdr and meta. Rejected because:
- Two copies to keep in sync
- No guarantee of consistency

### Nix-generated Go code
Have Nix generate a `.go` file with theme constants. Rejected because:
- Requires Nix in the unimart build pipeline
- Tight coupling between Nix eval and Go compilation
- Over-engineered for the current use case

## Consequences

**Positive:**
- Single source of truth in cmdr's Nix modules
- unimart gets live theme data when Nix is available
- Static file fallback works in CI and Nix-less environments
- Forward-compatible parsing handles schema evolution

**Negative:**
- Requires cmdr cloned as sibling for live export
- Nix eval adds startup latency to theme loading
- Schema changes in cmdr can break unimart if semantic keys are removed

**Mitigations:**
- `make ci` validates both producer and consumer exist
- Tolerant JSON parsing handles additive schema changes
- Required semantic keys (`fg`, `bg`, `bgPanel`, `accent`, `warn`, `ok`) are documented in contracts.md
- Consumer defaults ensure graceful degradation
