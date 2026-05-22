#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
REPO_DIR="$(cd "${ROOT_DIR}/.." && pwd)"
PORT="${PORT:-3000}"
HOST="127.0.0.1"
NEXT_LOG="${REPO_DIR}/logs/next-dev.log"

mkdir -p "${REPO_DIR}/logs"

"${REPO_DIR}/scripts/dev/guard-live-db-dev.sh"

cleanup() {
  if [[ -n "${NEXT_PID:-}" ]]; then
    echo "Shutting down Next.js dev server (pid ${NEXT_PID})"
    kill "${NEXT_PID}" 2>/dev/null || true
    wait "${NEXT_PID}" 2>/dev/null || true
  fi
}
trap cleanup EXIT INT TERM

echo "Starting Next.js dev server on http://${HOST}:${PORT}"
HOST="${HOST}" PORT="${PORT}" npm run dev > "${NEXT_LOG}" 2>&1 &
NEXT_PID=$!
sleep 1

echo -n "Waiting for Next.js to become ready"
for _ in $(seq 1 90); do
  if nc -z "${HOST}" "${PORT}" 2>/dev/null; then
    echo " ✓"
    break
  fi
  echo -n "."
  sleep 1
done

if ! nc -z "${HOST}" "${PORT}" 2>/dev/null; then
  echo " ✗ Next.js did not start within 90s. Last log lines:"
  tail -n 40 "${NEXT_LOG}" || true
  exit 1
fi

echo "Next.js ready. Launching Tauri shell."
RAH_ATTACH_DEV_SERVER=true \
RAH_DEV_SERVER_PORT="${PORT}" \
PORT="${PORT}" \
HOST="${HOST}" \
npm run tauri:dev --workspace @ra-h/mac-shell
