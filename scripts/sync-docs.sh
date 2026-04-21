#!/usr/bin/env bash
# scripts/sync-docs.sh — Pull docs from source repos into cdc vault, inject frontmatter
#
# Two-phase pipeline:
#   Phase 1 (Pull):        Source repos → cdc vault
#     For each repo in SYNC_DIRS:
#       <repo>/docs/ → cdc/<repo>/   (rsync --delete)
#
#   Phase 2 (Frontmatter): Inject source/synced metadata for Obsidian Dataview
#     Adds YAML frontmatter directly into vault copies.
#     Frontmatter is committed to the cdc vault repo.
#
# Safe to run multiple times. Idempotent.
# Skips missing repos gracefully.

set -euo pipefail

# Colors
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
RESET='\033[0m'

# Resolve paths
# This script lives at: meta/unimart-employee-handbooks/cdc/scripts/sync-docs.sh
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VAULT_ROOT="$(dirname "$SCRIPT_DIR")"
ORG_DIR="$(dirname "$(dirname "$(dirname "$SCRIPT_DIR")")")"

SYNC_DIRS=("cmdr" "idpbuilder" "meta")

# Verify vault root
if [ ! -f "$VAULT_ROOT/00-INDEX.md" ]; then
	printf "${RED}x${RESET} Vault root not found at: %s\n" "$VAULT_ROOT"
	exit 1
fi

# ── Phase 1: Pull from source repos ──────────────────────────────────────

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Phase 1: Pull from source repos"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
printf "${CYAN}i${RESET} Org directory: %s\n" "$ORG_DIR"
printf "${CYAN}i${RESET} Vault root:    %s\n" "$VAULT_ROOT"
echo ""

PULL_COUNT=0
TOTAL_FILES=0

for repo in "${SYNC_DIRS[@]}"; do
	# For meta repo, docs live at ORG_DIR/docs. For others, at ORG_DIR/$repo/docs
	if [ "$repo" = "meta" ]; then
		src="$ORG_DIR/docs"
	else
		src="$ORG_DIR/$repo/docs"
	fi
	if [ -d "$src" ]; then
		printf "${YELLOW}!${RESET} Pulling %s/docs/ ...\n" "$repo"
		mkdir -p "$VAULT_ROOT/$repo"
		rsync -av --delete "$src/" "$VAULT_ROOT/$repo/"
		count=$(find "$VAULT_ROOT/$repo" -name '*.md' | wc -l | tr -d ' ')
		TOTAL_FILES=$((TOTAL_FILES + count))
		printf "  %s markdown files\n" "$count"
		PULL_COUNT=$((PULL_COUNT + 1))
	else
		printf "${YELLOW}!${RESET} Skipping %s (no docs/ at %s)\n" "$repo" "$src"
	fi
done

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
printf "${GREEN}v${RESET} Pulled from %s source repo(s) — %s markdown files\n" "$PULL_COUNT" "$TOTAL_FILES"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# ── Phase 2: Inject frontmatter ──────────────────────────────────────────
#
# Frontmatter is injected directly into vault copies and committed to the
# cdc repo. Source repos remain untouched.

INJECT_SCRIPT="$SCRIPT_DIR/inject-frontmatter.sh"
if [ -x "$INJECT_SCRIPT" ]; then
	echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
	echo "Phase 2: Inject frontmatter"
	echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
	echo ""

	for dir in "${SYNC_DIRS[@]}"; do
		target="$VAULT_ROOT/$dir"
		if [ -d "$target" ]; then
			bash "$INJECT_SCRIPT" "$target" "$dir"
		fi
	done

	echo ""
else
	printf "${YELLOW}!${RESET} Skipping frontmatter injection (script not found at %s)\n" "$INJECT_SCRIPT"
fi

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
printf "${GREEN}v${RESET} Sync complete\n"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
