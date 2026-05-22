#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'
TMP_FILE="$(mktemp)"

printf "[audit] scanning for accidental API keys (sk-)...\n"
if rg --hidden --no-messages --files-with-matches "sk-" \
  --glob '!.git/**' --glob '!node_modules/**' --glob '!dist/**' --glob '!apps/mac/src-tauri/target/**' \
  > "$TMP_FILE"; then
  printf "${RED}Found potential secrets:${NC}\n"
  cat "$TMP_FILE"
  rm -f "$TMP_FILE"
  exit 1
else
  status=$?
  if [ "$status" -ne 1 ]; then
    rm -f "$TMP_FILE"
    exit "$status"
  fi
  printf "${GREEN}No sk- tokens found.${NC}\n"
fi
rm -f "$TMP_FILE"

printf "[audit] checking tracked files > 50MB...\n"
LARGE_FILES=$(git ls-tree -r HEAD --long | awk '$4 > 52428800 {printf "%s\t%s\n", $4, $5}')
if [ -n "$LARGE_FILES" ]; then
  printf "${RED}Large tracked files detected (>50MB):${NC}\n%s\n" "$LARGE_FILES"
  exit 1
else
  printf "${GREEN}No tracked blobs exceed 50MB.${NC}\n"
fi

printf "[audit] done.\n"
