#!/usr/bin/env bash
set -euo pipefail

# Generate a Tauri updater manifest for the universal DMG build.
# Usage:
#   scripts/generate-update-manifest.sh \
#     --file dist/bundle/RA-H.dmg \
#     --url https://updates.ra-h.app/dmg/RA-H.dmg \
#     --version 0.1.0 \
#     --out dist/update/latest.json \
#     [--notes release-notes.md] \
#     [--signature <base64 signature>]

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

FILE_PATH=""
DOWNLOAD_URL=""
VERSION=""
OUTPUT_PATH=""
NOTES_CONTENT=""
SIGNATURE="${TAURI_UPDATER_SIGNATURE:-}"

usage() {
  grep '^#' "$0" | cut -c 3-
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --file)
      FILE_PATH="$2"
      shift 2
      ;;
    --url)
      DOWNLOAD_URL="$2"
      shift 2
      ;;
    --version)
      VERSION="$2"
      shift 2
      ;;
    --out)
      OUTPUT_PATH="$2"
      shift 2
      ;;
    --notes)
      NOTES_CONTENT="$(cat "$2")"
      shift 2
      ;;
    --signature)
      SIGNATURE="$2"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown argument: $1" >&2
      usage
      exit 1
      ;;
  esac
done

if [ -z "$FILE_PATH" ] || [ -z "$DOWNLOAD_URL" ] || [ -z "$VERSION" ] || [ -z "$OUTPUT_PATH" ]; then
  echo "❌ Missing required arguments." >&2
  usage
  exit 1
fi

if [ ! -f "$FILE_PATH" ]; then
  echo "❌ File not found: $FILE_PATH" >&2
  exit 1
fi

ensure_signature() {
  if [ -n "$SIGNATURE" ]; then
    return
  fi

  if [ -n "${TAURI_PRIVATE_KEY:-}" ]; then
    if ! command -v tauri >/dev/null 2>&1; then
      echo "❌ Tauri CLI not found; cannot derive signature automatically." >&2
      exit 1
    fi
    echo "🔐 Generating signature via tauri signer"
    SIGNATURE="$(tauri signer sign \
      --private-key "$TAURI_PRIVATE_KEY" \
      ${TAURI_PRIVATE_KEY_PASSWORD:+--password "$TAURI_PRIVATE_KEY_PASSWORD"} \
      "$FILE_PATH" | tail -n 1)"
  fi

  if [ -z "$SIGNATURE" ]; then
    echo "❌ Provide --signature or set TAURI_PRIVATE_KEY/TAURI_UPDATER_SIGNATURE." >&2
    exit 1
  fi
}

ensure_signature

if ! command -v shasum >/dev/null 2>&1; then
  echo "❌ shasum not found. Install coreutils." >&2
  exit 1
fi

SHA512="$(shasum -a 512 "$FILE_PATH" | awk '{print $1}')"
PUB_DATE="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"

if ! command -v jq >/dev/null 2>&1; then
  echo "❌ jq is required to emit the manifest." >&2
  exit 1
fi

jq -n \
  --arg version "$VERSION" \
  --arg notes "$NOTES_CONTENT" \
  --arg pub_date "$PUB_DATE" \
  --arg url "$DOWNLOAD_URL" \
  --arg sha "$SHA512" \
  --arg sig "$SIGNATURE" \
  '{
    version: $version,
    notes: $notes,
    pub_date: $pub_date,
    platforms: {
      "darwin-aarch64": { signature: $sig, url: $url, sha512: $sha },
      "darwin-x86_64": { signature: $sig, url: $url, sha512: $sha }
    }
  }' >"$OUTPUT_PATH"

echo "✅ Update manifest written to $OUTPUT_PATH"
