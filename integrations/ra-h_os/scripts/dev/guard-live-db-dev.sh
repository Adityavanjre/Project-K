#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
DEFAULT_DB="$HOME/Library/Application Support/RA-H/db/rah.sqlite"

DB_PATH="${SQLITE_DB_PATH:-}"
if [ -z "$DB_PATH" ] && [ -f "${ROOT_DIR}/.env.local" ]; then
  DB_PATH=$(grep -E '^SQLITE_DB_PATH=' "${ROOT_DIR}/.env.local" | sed 's/^SQLITE_DB_PATH=//' | sed 's/^"\(.*\)"$/\1/') || true
fi
if [ -z "$DB_PATH" ]; then
  DB_PATH="$DEFAULT_DB"
fi

if [ "$DB_PATH" != "$DEFAULT_DB" ]; then
  exit 0
fi

echo "⚠️  dev:mac is using the packaged live RA-H DB:"
echo "   $DB_PATH"
echo "   Prefer SQLITE_DB_PATH=<dev-db> for isolated development when possible."

owners="$("${ROOT_DIR}/scripts/database/rah-db-owners.sh" "$DB_PATH" || true)"
if [ -z "$owners" ]; then
  exit 0
fi

if [ "${RAH_ALLOW_LIVE_DB_DEV:-}" = "true" ]; then
  echo "RAH_ALLOW_LIVE_DB_DEV=true set; continuing despite live DB owners:"
  echo "$owners" | sed 's/^/  /'
  exit 0
fi

echo "❌ Refusing to start dev server against the live DB while these processes have it open:"
echo "$owners" | sed 's/^/  /'
echo "Close RA-H/MCP owners first, set SQLITE_DB_PATH to a dev DB, or override with RAH_ALLOW_LIVE_DB_DEV=true."
exit 1
