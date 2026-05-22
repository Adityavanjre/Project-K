#!/usr/bin/env bash
set -euo pipefail

# RA-H SQLite backup using VACUUM INTO
# Safer behavior: auto-read .env.local for SQLITE_DB_PATH, verify integrity, print table counts.

# Resolve DB path in this order:
# 1) $SQLITE_DB_PATH (env)
# 2) ./.env.local → SQLITE_DB_PATH
# 3) Default dev path under ~/Library
DB_PATH=${SQLITE_DB_PATH:-}
if [ -z "${DB_PATH}" ] && [ -f ".env.local" ]; then
  # Extract only the SQLITE_DB_PATH line (supports values with spaces)
  DB_PATH=$(grep -E '^SQLITE_DB_PATH=' .env.local | sed 's/^SQLITE_DB_PATH=//' | sed 's/^"\(.*\)"$/\1/') || true
fi
if [ -z "${DB_PATH}" ]; then
  DB_PATH="$HOME/Library/Application Support/RA-H/db/rah.sqlite"
fi

# Normalize and validate
if [ ! -f "$DB_PATH" ]; then
  echo "❌ Error: Resolved DB not found: $DB_PATH" >&2
  echo "Hint: Set SQLITE_DB_PATH in .env.local or export it inline: SQLITE_DB_PATH=\"/full/path/rah.sqlite\" npm run sqlite:backup" >&2
  exit 1
fi

echo "Resolved DB path: $DB_PATH"

OWNERS="$(bash "$(dirname "$0")/rah-db-owners.sh" "$DB_PATH" || true)"
if [ -n "$OWNERS" ]; then
  echo "⚠️  Live RA-H DB owners detected while creating a VACUUM INTO backup:"
  echo "$OWNERS" | sed 's/^/  /'
  echo "   Continuing because this backup path does not replace/delete DB, WAL, or SHM files."
fi

BACKUP_DIR="$(dirname "$0")/../backups"
mkdir -p "$BACKUP_DIR"

TS=$(date +"%Y%m%d_%H%M%S")
BASENAME="rah_backup_${TS}.sqlite"
DEST="$BACKUP_DIR/$BASENAME"

echo "Backing up → $DEST"

sqlite3 "$DB_PATH" <<SQL
PRAGMA optimize;
VACUUM INTO '$DEST';
SQL

echo "Verifying snapshot integrity..."
ICHECK=$(sqlite3 "$DEST" "PRAGMA integrity_check;")
echo "  $ICHECK"
if [ "$ICHECK" != "ok" ]; then
  echo "❌ Snapshot integrity check failed" >&2
  exit 2
fi

echo "Snapshot counts:"
sqlite3 "$DEST" "SELECT 'nodes',COUNT(*) FROM nodes UNION ALL SELECT 'edges',COUNT(*) FROM edges UNION ALL SELECT 'chunks',COUNT(*) FROM chunks;" | sed 's/^/  /'

SIZE=$(du -h "$DEST" | awk '{print $1}')
echo "✅ Backup complete: $BASENAME ($SIZE)"

echo "Recent backups:"
ls -lht "$BACKUP_DIR"/*.sqlite 2>/dev/null | head -5 || echo "  (none)"
