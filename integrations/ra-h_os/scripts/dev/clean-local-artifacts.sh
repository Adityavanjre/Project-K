#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

INFO() { printf "[clean-local] %s\n" "$1"; }

maybe_remove_dir() {
  local target="$1"
  if [ -d "$target" ]; then
    rm -rf "$target"
    INFO "Removed directory $target"
  fi
}

maybe_remove_file() {
  local target="$1"
  if [ -f "$target" ]; then
    rm -f "$target"
    INFO "Removed file $target"
  fi
}

INFO "Cleaning generated artifacts (safe-only)"

maybe_remove_dir "$REPO_ROOT/dist/local-app"
maybe_remove_dir "$REPO_ROOT/dist/runtime"
maybe_remove_dir "$REPO_ROOT/dist/.staging"
maybe_remove_dir "$REPO_ROOT/.next"
maybe_remove_dir "$REPO_ROOT/apps/mac/dist"

maybe_remove_file "$REPO_ROOT/dist/index.html"
maybe_remove_file "$REPO_ROOT/logs/helper-interactions.log"
maybe_remove_file "$REPO_ROOT/logs/next-dev.log"
maybe_remove_file "$REPO_ROOT/app/api/logs/requests.log"

INFO "Cleanup complete"
