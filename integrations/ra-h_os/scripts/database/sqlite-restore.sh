#!/usr/bin/env bash
set -euo pipefail

# Restore RA-H SQLite database from a backup snapshot

if [ $# -lt 1 ]; then
  echo "Usage: $0 <backup.sqlite>" >&2
  exit 1
fi

SRC="$1"
if [ ! -f "$SRC" ]; then
  echo "Backup file not found: $SRC" >&2
  exit 1
fi

# Resolve target DB path in this order:
# 1) $SQLITE_DB_PATH (env)
# 2) ./.env.local → SQLITE_DB_PATH
# 3) Default dev path under ~/Library
DB_PATH=${SQLITE_DB_PATH:-}
if [ -z "${DB_PATH}" ] && [ -f ".env.local" ]; then
  DB_PATH=$(grep -E '^SQLITE_DB_PATH=' .env.local | sed 's/^SQLITE_DB_PATH=//' | sed 's/^"\(.*\)"$/\1/') || true
fi
if [ -z "${DB_PATH}" ]; then
  DB_PATH="$HOME/Library/Application Support/RA-H/db/rah.sqlite"
fi

DB_DIR="$(dirname "$DB_PATH")"
mkdir -p "$DB_DIR"

echo "Source backup: $SRC"
echo "Target DB:     $DB_PATH"

OWNERS="$(bash "$(dirname "$0")/rah-db-owners.sh" "$DB_PATH" || true)"
if [ -n "$OWNERS" ] && [ "${RAH_ALLOW_LIVE_DB_RESTORE:-}" != "true" ]; then
  echo "❌ Refusing restore while RA-H DB owners are live:" >&2
  echo "$OWNERS" | sed 's/^/  /' >&2
  echo "Close RA-H/MCP/dev processes first, or set RAH_ALLOW_LIVE_DB_RESTORE=true if you have deliberately quiesced them." >&2
  exit 4
fi

echo "Verifying backup integrity before restore..."
ICHECK=$(sqlite3 "$SRC" "PRAGMA integrity_check;")
echo "  $ICHECK"
if [ "$ICHECK" != "ok" ]; then
  echo "❌ Backup integrity check failed — aborting restore" >&2
  exit 2
fi

TS=$(date +"%Y%m%d_%H%M%S")
SAFE_COPY="$DB_DIR/rah_pre_restore_${TS}.sqlite"
echo "Creating safety copy: $SAFE_COPY"
cp -f "$DB_PATH" "$SAFE_COPY" 2>/dev/null || true

echo "Restoring backup..."
cp -f "$SRC" "$DB_PATH"

echo "Integrity check on restored DB..."
RCHECK=$(sqlite3 "$DB_PATH" "PRAGMA integrity_check;")
echo "  $RCHECK"
if [ "$RCHECK" != "ok" ]; then
  echo "❌ Restored DB integrity check failed" >&2
  exit 3
fi

echo "Restored counts:"
sqlite3 "$DB_PATH" "SELECT 'nodes',COUNT(*) FROM nodes UNION ALL SELECT 'edges',COUNT(*) FROM edges UNION ALL SELECT 'chunks',COUNT(*) FROM chunks;" | sed 's/^/  /'

echo "✅ Restore complete."
