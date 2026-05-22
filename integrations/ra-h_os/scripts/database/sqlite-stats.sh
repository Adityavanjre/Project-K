#!/usr/bin/env bash
set -euo pipefail

DB_PATH=${1:-rah_trial.db}

if [ ! -f "$DB_PATH" ]; then
  echo "Error: Database file not found: $DB_PATH" >&2
  exit 1
fi

if command -v brew >/dev/null 2>&1; then
  SQLITE_BIN="$(brew --prefix sqlite 2>/dev/null)/bin/sqlite3"
  if [ ! -x "$SQLITE_BIN" ]; then
    SQLITE_BIN="sqlite3"
  fi
else
  SQLITE_BIN="sqlite3"
fi

echo "Using sqlite3 at: $SQLITE_BIN"
"$SQLITE_BIN" --version

"$SQLITE_BIN" "$DB_PATH" < "$(dirname "$0")/sqlite-verify.sql"

