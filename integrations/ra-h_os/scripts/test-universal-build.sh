#!/usr/bin/env bash
set -euo pipefail

# Smoke test the universal binaries by loading them under both architectures.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
DIST_ROOT="${DIST_ROOT:-$REPO_ROOT/dist/local-app}"
APP_DIR="$DIST_ROOT/app"
NODE_BIN="$DIST_ROOT/bin/node"

assert_exists() {
  local path="$1"
  if [ ! -e "$path" ]; then
    echo "❌ Missing required artifact: $path" >&2
    exit 1
  fi
}

check_universal() {
  local path="$1"
  if ! file "$path" | grep -q "arm64"; then
    echo "❌ $path is missing arm64 slice" >&2
    exit 1
  fi
  if ! file "$path" | grep -q "x86_64"; then
    echo "❌ $path is missing x86_64 slice" >&2
    exit 1
  fi
}

run_dual_arch_node() {
  local arch="$1"
  local script="$2"

  if [ "$arch" = "x86_64" ]; then
    arch -x86_64 "$NODE_BIN" -e "$script"
  else
    arch -arm64 "$NODE_BIN" -e "$script"
  fi
}

main() {
  assert_exists "$NODE_BIN"
  assert_exists "$APP_DIR/node_modules/better-sqlite3/build/Release/better_sqlite3.node"
  assert_exists "$DIST_ROOT/vendor/sqlite-extensions/vec0.dylib"

  echo "ℹ️  Verifying universal slices"
  check_universal "$NODE_BIN"
  check_universal "$APP_DIR/node_modules/better-sqlite3/build/Release/better_sqlite3.node"
  check_universal "$DIST_ROOT/vendor/sqlite-extensions/vec0.dylib"

  echo "ℹ️  Running runtime smoke tests"
  run_dual_arch_node arm64 "console.log('arm64 runtime ok')"
  run_dual_arch_node x86_64 "console.log('x86 runtime ok')"

  (
    cd "$APP_DIR"
    run_dual_arch_node arm64 "require('./node_modules/better-sqlite3'); console.log('better-sqlite3 arm64 ok')"
    run_dual_arch_node x86_64 "require('./node_modules/better-sqlite3'); console.log('better-sqlite3 x86 ok')"
  )

  echo "✅ Universal build smoke test passed"
}

main "$@"
