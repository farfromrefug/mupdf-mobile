#!/usr/bin/env bash
# scripts/build.sh — Build both iOS and Android targets.
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SCRIPTS_DIR="$REPO_ROOT/scripts"

# ─── Colour output ─────────────────────────────────────────────────────────
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RESET='\033[0m'

echo -e "${GREEN}==== MuPDF Mobile — full build ====${RESET}"

# ─── Submodule check ───────────────────────────────────────────────────────
if [ ! -f "$REPO_ROOT/mupdf/Makefile" ]; then
  echo -e "${YELLOW}⚠  MuPDF submodule not found. Initialising...${RESET}"
  git -C "$REPO_ROOT" submodule update --init --recursive
fi

# ─── iOS ───────────────────────────────────────────────────────────────────
echo -e "\n${GREEN}── Building iOS XCFramework...${RESET}"
"$SCRIPTS_DIR/build-ios.sh"

# ─── Android ───────────────────────────────────────────────────────────────
echo -e "\n${GREEN}── Building Android AAR...${RESET}"
"$SCRIPTS_DIR/build-android.sh"

echo -e "\n${GREEN}✅  All targets built successfully.${RESET}"
