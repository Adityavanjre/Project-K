#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
OUTPUT_PATH="${1:-$REPO_ROOT/dist/resources/rah_seed.sqlite}"
SQLITE_SCRIPT="$REPO_ROOT/scripts/database/sqlite-ensure-app-schema.sh"

if [ ! -x "$SQLITE_SCRIPT" ]; then
  echo "Error: $SQLITE_SCRIPT not found or not executable" >&2
  exit 1
fi

mkdir -p "$(dirname "$OUTPUT_PATH")"
rm -f "$OUTPUT_PATH" "$OUTPUT_PATH-wal" "$OUTPUT_PATH-shm"

sqlite3 "$OUTPUT_PATH" "VACUUM;" >/dev/null 2>&1 || true

bash "$SQLITE_SCRIPT" "$OUTPUT_PATH"

echo "✅ Seed database ready at $OUTPUT_PATH"
