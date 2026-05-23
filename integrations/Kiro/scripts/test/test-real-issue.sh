#!/bin/bash

# Test the complete triage workflow on a real GitHub issue locally
# Usage: ./test-real-issue.sh <issue_number>

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║         Real Issue Triage Test (Local Simulation)         ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""

# Check if issue number is provided
if [ -z "$1" ]; then
    echo -e "${RED}❌ Error: Issue number is required${NC}"
    echo ""
    echo "Usage:"
    echo "  ./test-real-issue.sh <issue_number>"
    echo ""
    echo "Example:"
    echo "  ./test-real-issue.sh 5044"
    exit 1
fi

ISSUE_NUMBER=$1

# Load environment variables from .env file
if [ -f "../.env" ]; then
    echo -e "${GREEN}✓${NC} Loading environment variables from .env"
    export $(cat ../.env | grep -v '^#' | xargs)
else
    echo -e "${RED}❌ Error: .env file not found${NC}"
    echo "Please create scripts/.env with required credentials"
    exit 1
fi

# Check required environment variables
if [ -z "$GITHUB_TOKEN" ]; then
    echo -e "${RED}❌ Error: GITHUB_TOKEN not set in .env${NC}"
    exit 1
fi

if [ -z "$AWS_ACCESS_KEY_ID" ] || [ -z "$AWS_SECRET_ACCESS_KEY" ]; then
    echo -e "${RED}❌ Error: AWS credentials not set in .env${NC}"
    exit 1
fi

echo -e "${GREEN}✓${NC} Environment variables loaded"
echo ""

# Build TypeScript
echo -e "${YELLOW}Building TypeScript...${NC}"
cd ..
npm run build > /dev/null 2>&1
cd test
echo -e "${GREEN}✓${NC} Build complete"
echo ""

# Set test issue number
export TEST_ISSUE_NUMBER=$ISSUE_NUMBER

# Run the test
echo -e "${BLUE}Running triage workflow for issue #${ISSUE_NUMBER}...${NC}"
echo ""
node ../dist/test/test-real-issue.js

echo ""
echo -e "${GREEN}═══════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}✅ Test complete!${NC}"
echo ""
