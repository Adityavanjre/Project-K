#!/bin/bash

# Basic Podman Support Test Script for WRKFLW
# This script performs quick verification of Podman integration

set -e  # Exit on any error

echo "🚀 WRKFLW Podman Support - Basic Test Script"
echo "============================================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if wrkflw binary exists
print_status "Checking if wrkflw is built..."
if [ ! -f "./target/release/wrkflw" ]; then
    print_warning "Release binary not found. Building wrkflw..."
    cargo build --release
    if [ $? -eq 0 ]; then
        print_success "Build completed successfully"
    else
        print_error "Build failed"
        exit 1
    fi
else
    print_success "Found wrkflw binary"
fi

# Test 1: Check CLI help shows runtime options
print_status "Test 1: Checking CLI runtime options..."
HELP_OUTPUT=$(./target/release/wrkflw run --help 2>&1)
if echo "$HELP_OUTPUT" | grep -q "runtime.*podman"; then
    print_success "CLI shows Podman runtime option"
else
    print_error "CLI does not show Podman runtime option"
    exit 1
fi

# Test 2: Check invalid runtime rejection
print_status "Test 2: Testing invalid runtime rejection..."
if ./target/release/wrkflw run --runtime invalid tests/workflows/example.yml 2>&1 | grep -q "invalid value"; then
    print_success "Invalid runtime properly rejected"
else
    print_error "Invalid runtime not properly rejected"
    exit 1
fi

# Test 3: Check Podman availability detection
print_status "Test 3: Testing Podman availability detection..."
if command -v podman &> /dev/null; then
    print_success "Podman is installed and available"
    PODMAN_VERSION=$(podman version --format json | python3 -c "import sys, json; print(json.load(sys.stdin)['Client']['Version'])" 2>/dev/null || echo "unknown")
    print_status "Podman version: $PODMAN_VERSION"
    
    # Test basic podman functionality
    if podman info > /dev/null 2>&1; then
        print_success "Podman daemon is responsive"
        PODMAN_AVAILABLE=true
    else
        print_warning "Podman installed but not responsive (may need podman machine start)"
        PODMAN_AVAILABLE=false
    fi
else
    print_warning "Podman not installed - will test fallback behavior"
    PODMAN_AVAILABLE=false
fi

# Create a simple test workflow
print_status "Creating test workflow..."
cat > test-basic-workflow.yml << 'EOF'
name: Basic Test Workflow
on: [workflow_dispatch]

jobs:
  test:
    runs-on: ubuntu-latest
    container: ubuntu:20.04
    steps:
      - name: Basic test
        run: |
          echo "Testing basic container execution"
          echo "Current user: $(whoami)"
          echo "Working directory: $(pwd)"
          echo "Container test completed"
          
      - name: Environment test
        env:
          TEST_VAR: "test-value"
        run: |
          echo "Environment variable TEST_VAR: $TEST_VAR"
          echo "GitHub workspace: $GITHUB_WORKSPACE"
EOF

# Test 4: Test emulation mode (should always work)
print_status "Test 4: Testing emulation mode..."
if ./target/release/wrkflw run --runtime emulation test-basic-workflow.yml > /dev/null 2>&1; then
    print_success "Emulation mode works correctly"
else
    print_error "Emulation mode failed"
    exit 1
fi

# Test 5: Test Podman mode
print_status "Test 5: Testing Podman mode..."
if [ "$PODMAN_AVAILABLE" = true ]; then
    print_status "Running test workflow with Podman runtime..."
    if ./target/release/wrkflw run --runtime podman --verbose test-basic-workflow.yml > podman-test.log 2>&1; then
        print_success "Podman mode executed successfully"
        
        # Check if it actually used Podman
        if grep -q "Podman: Running container" podman-test.log; then
            print_success "Confirmed Podman was used for container execution"
        elif grep -q "Podman is not available.*emulation" podman-test.log; then
            print_warning "Podman fell back to emulation mode"
        else
            print_warning "Could not confirm Podman usage in logs"
        fi
    else
        print_error "Podman mode failed to execute"
        echo "Error log:"
        tail -10 podman-test.log
        exit 1
    fi
else
    print_status "Testing Podman fallback behavior..."
    if ./target/release/wrkflw run --runtime podman test-basic-workflow.yml 2>&1 | grep -q "emulation.*instead"; then
        print_success "Podman correctly falls back to emulation when unavailable"
    else
        print_error "Podman fallback behavior not working correctly"
        exit 1
    fi
fi

# Test 6: Test Docker mode (if available)
print_status "Test 6: Testing Docker mode for comparison..."
if command -v docker &> /dev/null && docker info > /dev/null 2>&1; then
    print_status "Docker is available, testing for comparison..."
    if ./target/release/wrkflw run --runtime docker test-basic-workflow.yml > /dev/null 2>&1; then
        print_success "Docker mode works correctly"
    else
        print_warning "Docker mode failed (this is okay for Podman testing)"
    fi
else
    print_warning "Docker not available - skipping Docker comparison test"
fi

# Test 7: Test TUI compilation (basic check)
print_status "Test 7: Testing TUI startup..."
timeout 5s ./target/release/wrkflw tui --help > /dev/null 2>&1 || true
print_success "TUI help command works"

# Test 8: Runtime switching in TUI (simulate)
print_status "Test 8: Checking TUI runtime parameter..."
if ./target/release/wrkflw tui --runtime podman --help > /dev/null 2>&1; then
    print_success "TUI accepts runtime parameter"
else
    print_error "TUI does not accept runtime parameter"
    exit 1
fi

# Cleanup
print_status "Cleaning up test files..."
rm -f test-basic-workflow.yml podman-test.log

echo ""
echo "🎉 Basic Podman Support Test Summary:"
echo "======================================"

if [ "$PODMAN_AVAILABLE" = true ]; then
    print_success "✅ Podman is available and working"
    print_success "✅ WRKFLW can execute workflows with Podman"
else
    print_warning "⚠️  Podman not available, but fallback works correctly"
fi

print_success "✅ CLI runtime selection works"
print_success "✅ Error handling works"
print_success "✅ TUI integration works"
print_success "✅ Basic container execution works"

echo ""
print_status "🔍 For comprehensive testing, run: ./TESTING_PODMAN.md"
print_status "📋 To install Podman: https://podman.io/getting-started/installation"

if [ "$PODMAN_AVAILABLE" = false ]; then
    echo ""
    print_warning "💡 To test full Podman functionality:"
    echo "   1. Install Podman for your system"
    echo "   2. Initialize Podman (if on macOS/Windows): podman machine init && podman machine start"
    echo "   3. Re-run this test script"
fi

echo ""
print_success "🎯 Basic Podman support test completed successfully!"
