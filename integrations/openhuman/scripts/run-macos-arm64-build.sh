#!/usr/bin/env bash
# Run the standalone macOS ARM64 Tauri build via nektos/act (self-hosted = your Mac).
# No prepare-release, no tagging, no GitHub release upload (includeUpdaterJson: false).
#
# Usage:
#   ./scripts/run-macos-arm64-build.sh          # dry-run
#   ./scripts/run-macos-arm64-build.sh --run    # full signed build on this machine
#
# Requires: act, jq, scripts/ci-secrets.json (copy from ci-secrets.example.json)

set -euo pipefail
cd "$(git rev-parse --show-toplevel)"

WORKFLOW=".github/workflows/macos-arm64-build.yml"
SECRETS_JSON="scripts/ci-secrets.json"
RUN_MODE="dryrun"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --run)
      RUN_MODE="run"
      shift
      ;;
    --dryrun|-n)
      RUN_MODE="dryrun"
      shift
      ;;
    --secrets-json)
      SECRETS_JSON="${2:-}"
      shift 2
      ;;
    *)
      echo "Unknown argument: $1" >&2
      exit 1
      ;;
  esac
done

if [[ ! -f "$SECRETS_JSON" ]]; then
  echo "Secrets JSON not found: $SECRETS_JSON" >&2
  exit 1
fi

if ! command -v act >/dev/null 2>&1; then
  echo "act is required. Install with: brew install act" >&2
  exit 1
fi

if ! command -v jq >/dev/null 2>&1; then
  echo "jq is required. Install with: brew install jq" >&2
  exit 1
fi

SECRETS_FILE="$(mktemp)"
VARS_FILE="$(mktemp)"
EVENT_JSON="$(mktemp)"
MERGED_SECRETS="$(mktemp)"
trap 'rm -f "$SECRETS_FILE" "$VARS_FILE" "$EVENT_JSON" "$MERGED_SECRETS"' EXIT

jq '
  .secrets |= (
    . + {
      APPLE_APP_SPECIFIC_PASSWORD: (
        if (.APPLE_APP_SPECIFIC_PASSWORD // "") | length > 0 then .APPLE_APP_SPECIFIC_PASSWORD
        else (.APPLE_PASSWORD // "") end
      )
    }
  )
' "$SECRETS_JSON" > "$MERGED_SECRETS"

jq -r '
def dotenv_escape:
  gsub("\""; "\\\"") | gsub("\r"; "\\r") | gsub("\n"; "\\n");
(.secrets // {}) | to_entries[] | select(.key != "GITHUB_TOKEN") | "\(.key)=\"\(.value | dotenv_escape)\""
' "$MERGED_SECRETS" > "$SECRETS_FILE"
jq -r '
def dotenv_escape:
  gsub("\""; "\\\"") | gsub("\r"; "\\r") | gsub("\n"; "\\n");
(.vars // {}) | to_entries[] | "\(.key)=\"\(.value | dotenv_escape)\""
' "$SECRETS_JSON" > "$VARS_FILE"

REPO_FULL="${GITHUB_REPOSITORY:-}"
if [[ -z "$REPO_FULL" ]]; then
  REPO_FULL="$(git remote get-url origin 2>/dev/null | sed -E 's#^git@github\.com:([^/]+)/([^/.]+)(\.git)?$#\1/\2#; s#^https://github\.com/([^/]+)/([^/.]+)(\.git)?$#\1/\2#')"
fi
if [[ -z "$REPO_FULL" || "$REPO_FULL" != */* ]]; then
  echo "Could not resolve GitHub owner/repo (set GITHUB_REPOSITORY or fix git remote origin)" >&2
  exit 1
fi
OWNER="${REPO_FULL%%/*}"
REPO_NAME="${REPO_FULL##*/}"

REF="$(git symbolic-ref -q HEAD || true)"
if [[ -z "$REF" ]]; then
  REF="refs/heads/main"
fi

jq -n \
  --arg ref "$REF" \
  --arg full "$REPO_FULL" \
  --arg owner "$OWNER" \
  --arg name "$REPO_NAME" \
  '{
    ref: $ref,
    inputs: {},
    repository: {
      full_name: $full,
      default_branch: "main",
      name: $name,
      owner: { login: $owner }
    },
    sender: { login: "local-dev" }
  }' > "$EVENT_JSON"

echo "Workflow: $WORKFLOW"
echo "Secrets:  $SECRETS_JSON"
echo "Ref:      $REF"
echo "Mode:     $RUN_MODE"
echo

# act -b copies the tree without .git — submodules must be materialized here first.
if [[ -d .git ]]; then
  echo "Syncing git submodules (required for skills/, etc.)..."
  git submodule update --init --recursive
fi
echo

ACT_ARGS=(
  workflow_dispatch
  -W "$WORKFLOW"
  --eventpath "$EVENT_JSON"
  --secret-file "$SECRETS_FILE"
  --var-file "$VARS_FILE"
  -b
  -P macos-latest=-self-hosted
)

if [[ "$RUN_MODE" == "dryrun" ]]; then
  echo "Dry-run only. Use --run for the full macOS ARM64 build."
  act "${ACT_ARGS[@]}" -n
else
  act "${ACT_ARGS[@]}"
fi
