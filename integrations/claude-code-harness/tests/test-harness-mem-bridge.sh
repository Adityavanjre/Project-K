#!/bin/bash
# harness-mem wrapper scripts should resolve the sibling repo without hardcoded Desktop paths.

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "${TMP_DIR}"' EXIT

mkdir -p "${TMP_DIR}/claude-code-harness/scripts/lib"
mkdir -p "${TMP_DIR}/claude-code-harness/scripts/hook-handlers"
mkdir -p "${TMP_DIR}/harness-mem/scripts/hook-handlers"

cp "${ROOT_DIR}/scripts/lib/harness-mem-bridge.sh" "${TMP_DIR}/claude-code-harness/scripts/lib/harness-mem-bridge.sh"
cp "${ROOT_DIR}/scripts/hook-handlers/memory-session-start.sh" "${TMP_DIR}/claude-code-harness/scripts/hook-handlers/memory-session-start.sh"
cp "${ROOT_DIR}/scripts/harness-mem-client.sh" "${TMP_DIR}/claude-code-harness/scripts/harness-mem-client.sh"

cat > "${TMP_DIR}/harness-mem/scripts/hook-handlers/memory-session-start.sh" <<'EOF'
#!/bin/bash
set -euo pipefail
printf 'memory-session-start-ok\n'
EOF

cat > "${TMP_DIR}/harness-mem/scripts/harness-mem-client.sh" <<'EOF'
#!/bin/bash
set -euo pipefail
printf 'harness-mem-client-ok:%s\n' "${1:-none}"
EOF

chmod +x \
  "${TMP_DIR}/claude-code-harness/scripts/hook-handlers/memory-session-start.sh" \
  "${TMP_DIR}/claude-code-harness/scripts/harness-mem-client.sh" \
  "${TMP_DIR}/harness-mem/scripts/hook-handlers/memory-session-start.sh" \
  "${TMP_DIR}/harness-mem/scripts/harness-mem-client.sh"

wrapper_output="$(cd "${TMP_DIR}/claude-code-harness" && ./scripts/hook-handlers/memory-session-start.sh)"
client_output="$(cd "${TMP_DIR}/claude-code-harness" && ./scripts/harness-mem-client.sh health)"

[ "${wrapper_output}" = "memory-session-start-ok" ] || {
  echo "memory-session-start wrapper did not resolve sibling harness-mem repo"
  exit 1
}

[ "${client_output}" = "harness-mem-client-ok:health" ] || {
  echo "harness-mem-client wrapper did not resolve sibling harness-mem repo"
  exit 1
}

echo "OK"
