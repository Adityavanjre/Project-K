#!/usr/bin/env bash
set -euo pipefail

DB_PATH="${1:-}"
if [ -z "$DB_PATH" ]; then
  echo "Usage: $0 <path-to-rah.sqlite>" >&2
  exit 2
fi

if ! command -v lsof >/dev/null 2>&1; then
  echo "lsof is required to inspect live RA-H database owners." >&2
  exit 3
fi

paths=("$DB_PATH" "${DB_PATH}-wal" "${DB_PATH}-shm")
existing=()
for candidate in "${paths[@]}"; do
  if [ -e "$candidate" ]; then
    existing+=("$candidate")
  fi
done

if [ "${#existing[@]}" -eq 0 ]; then
  exit 0
fi

lsof -FnPc -- "${existing[@]}" 2>/dev/null | awk '
  /^p/ { pid=substr($0, 2); next }
  /^c/ { cmd=substr($0, 2); if (pid != "") print pid "\t" cmd }
' | sort -u
