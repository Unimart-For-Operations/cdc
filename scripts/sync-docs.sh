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

sync_meta_docs() {
	local dest="$1"
	local docs_src="${ORG_DIR}/docs"

	# Reset the mirror first so removed files disappear even though meta is
	# assembled from root files plus the legacy docs hub's meta-owned sections.
	rm -rf "$dest"
	mkdir -p "$dest"

	# meta/docs is currently the legacy docs hub submodule. Only sync the
	# meta-owned docs from its root; exclude mirrored repos, scripts, and git
	# metadata so cdc/meta does not become a nested docs hub.
	rsync -av --delete --delete-excluded \
		--exclude='.git' \
		--exclude='.gitignore' \
		--exclude='Makefile' \
		--exclude='cmdr/' \
		--exclude='idpbuilder/' \
		--exclude='idpctl/' \
		--exclude='scripts/' \
		"$docs_src/" "$dest/"

	# Root-level control-plane docs are owned by meta and should be visible in
	# the handbook even though they do not live under meta/docs. Overlay these
	# after the docs sync so --delete cannot remove them.
	for file in README.md AGENTS.md TOOLING.md PROVISIONING.md CHANGELOG.md; do
		if [ -f "${ORG_DIR}/${file}" ]; then
			rsync -av "${ORG_DIR}/${file}" "$dest/"
		fi
	done
}

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
	# For meta, assemble root control-plane docs plus meta-owned docs. For
	# others, source docs live at ORG_DIR/$repo/docs.
	if [ "$repo" = "meta" ]; then
		src="$ORG_DIR"
	else
		src="$ORG_DIR/$repo/docs"
	fi
	if [ -d "$src" ]; then
		printf "${YELLOW}!${RESET} Pulling %s/docs/ ...\n" "$repo"
		mkdir -p "$VAULT_ROOT/$repo"
		if [ "$repo" = "meta" ]; then
			sync_meta_docs "$VAULT_ROOT/$repo"
		else
			rsync -av --delete "$src/" "$VAULT_ROOT/$repo/"
		fi
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
