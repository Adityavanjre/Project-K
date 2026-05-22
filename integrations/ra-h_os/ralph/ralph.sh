#!/bin/bash
set -e

# Ralph Autonomous Agent Loop for RA-H
# Usage: ./ralph/ralph.sh [max_iterations]
#
# Runs Claude Code in a loop to implement user stories from prd.json
# Each iteration: picks a story → implements → verifies → commits → updates status

MAX_ITERATIONS=${1:-10}
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
PRD_FILE="$SCRIPT_DIR/prd.json"
PROGRESS_FILE="$SCRIPT_DIR/progress.txt"
PROMPT_FILE="$SCRIPT_DIR/prompt.md"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}  🐕 Ralph Autonomous Agent Loop${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

# Verify required files exist
if [ ! -f "$PRD_FILE" ]; then
    echo -e "${RED}❌ Error: $PRD_FILE not found${NC}"
    echo "Create prd.json with your user stories first."
    exit 1
fi

if [ ! -f "$PROMPT_FILE" ]; then
    echo -e "${RED}❌ Error: $PROMPT_FILE not found${NC}"
    exit 1
fi

# Initialize progress file if needed
if [ ! -f "$PROGRESS_FILE" ]; then
    echo "# Ralph Progress Log" > "$PROGRESS_FILE"
    echo "Started: $(date)" >> "$PROGRESS_FILE"
    echo "" >> "$PROGRESS_FILE"
fi

echo -e "${YELLOW}📋 PRD:${NC} $PRD_FILE"
echo -e "${YELLOW}📝 Progress:${NC} $PROGRESS_FILE"
echo -e "${YELLOW}🔄 Max iterations:${NC} $MAX_ITERATIONS"
echo ""

cd "$PROJECT_DIR"

for i in $(seq 1 $MAX_ITERATIONS); do
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${GREEN}🔁 Iteration $i of $MAX_ITERATIONS${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""

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

    # Run Claude Code with the prompt via stdin
    # Using --print for non-interactive mode
    OUTPUT=$(echo "$FULL_PROMPT" | claude --print \
        --allowedTools "Edit,Write,Read,Bash,Glob,Grep" 2>&1) || true

    echo "$OUTPUT"

    # Check for completion signal
    if echo "$OUTPUT" | grep -q "<promise>COMPLETE</promise>"; then
        echo ""
        echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        echo -e "${GREEN}✅ Ralph complete! All stories passing.${NC}"
        echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        exit 0
    fi

    # Brief pause between iterations
    echo ""
    echo -e "${YELLOW}⏳ Pausing 3s before next iteration...${NC}"
    sleep 3
done

echo ""
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${YELLOW}⚠️  Max iterations ($MAX_ITERATIONS) reached${NC}"
echo -e "${YELLOW}    Check progress.txt for status${NC}"
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
exit 1
