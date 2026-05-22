#!/bin/bash
set -e

# Ralph Single Iteration (Human-in-Loop Mode)
# Usage: ./ralph/ralph-once.sh
#
# Runs one iteration of Ralph interactively, allowing you to observe and steer

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
PRD_FILE="$SCRIPT_DIR/prd.json"
PROGRESS_FILE="$SCRIPT_DIR/progress.txt"
PROMPT_FILE="$SCRIPT_DIR/prompt.md"

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  🐕 Ralph Single Iteration (Interactive)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Verify required files exist
if [ ! -f "$PRD_FILE" ]; then
    echo "❌ Error: $PRD_FILE not found"
    echo "Create prd.json with your user stories first."
    exit 1
fi

if [ ! -f "$PROMPT_FILE" ]; then
    echo "❌ Error: $PROMPT_FILE not found"
    exit 1
fi

# Initialize progress file if needed
if [ ! -f "$PROGRESS_FILE" ]; then
    echo "# Ralph Progress Log" > "$PROGRESS_FILE"
    echo "Started: $(date)" >> "$PROGRESS_FILE"
    echo "" >> "$PROGRESS_FILE"
fi

echo "📋 PRD: $PRD_FILE"
echo "📝 Progress: $PROGRESS_FILE"
echo ""

cd "$PROJECT_DIR"

# Build the full prompt with current state
FULL_PROMPT="$(cat "$PROMPT_FILE")

---

## Current State

### prd.json
\`\`\`json
$(cat "$PRD_FILE")
\`\`\`

### progress.txt
\`\`\`
$(cat "$PROGRESS_FILE")
\`\`\`
"

# Run Claude Code with prompt via stdin
echo "$FULL_PROMPT" | claude --print --allowedTools "Edit,Write,Read,Bash,Glob,Grep"
