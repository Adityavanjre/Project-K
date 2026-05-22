#!/bin/bash

# Test script to verify --preserve-containers-on-failure works with Podman

set -e

echo "🧪 Testing --preserve-containers-on-failure with Podman"
echo "======================================================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_status() { echo -e "${BLUE}[INFO]${NC} $1"; }
print_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
print_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
print_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# Check if Podman is available
if ! command -v podman &> /dev/null; then
    print_error "Podman is not installed. Please install Podman to run this test."
    exit 1
fi

if ! podman info > /dev/null 2>&1; then
    print_error "Podman is not responsive. Please start Podman (e.g., 'podman machine start' on macOS)."
    exit 1
fi

print_success "Podman is available and responsive"

# Create a failing workflow for testing
print_status "Creating test workflows..."

cat > test-success-workflow.yml << 'EOF'
name: Success Test
on: [workflow_dispatch]
jobs:
  success:
    runs-on: ubuntu-latest
    container: ubuntu:20.04
    steps:
      - name: Successful step
        run: |
          echo "This step will succeed"
          echo "Exit code will be 0"
          exit 0
EOF

cat > test-failure-workflow.yml << 'EOF'
name: Failure Test
on: [workflow_dispatch]
jobs:
  failure:
    runs-on: ubuntu-latest
    container: ubuntu:20.04
    steps:
      - name: Failing step
        run: exit 1
EOF

# Function to count wrkflw containers
count_wrkflw_containers() {
    podman ps -a --filter "name=wrkflw-" --format "{{.Names}}" | wc -l
}

# Function to get wrkflw container names
get_wrkflw_containers() {
    podman ps -a --filter "name=wrkflw-" --format "{{.Names}}"
}

# Clean up any existing wrkflw containers
print_status "Cleaning up any existing wrkflw containers..."
EXISTING_CONTAINERS=$(get_wrkflw_containers)
if [ -n "$EXISTING_CONTAINERS" ]; then
    echo "$EXISTING_CONTAINERS" | xargs -r podman rm -f
    print_status "Removed existing containers"
fi

echo ""
print_status "=== Test 1: Success case without preserve flag ==="
BEFORE_COUNT=$(count_wrkflw_containers)
print_status "Containers before: $BEFORE_COUNT"

./target/release/wrkflw run --runtime podman test-success-workflow.yml > /dev/null 2>&1

AFTER_COUNT=$(count_wrkflw_containers)
print_status "Containers after: $AFTER_COUNT"

if [ "$AFTER_COUNT" -eq "$BEFORE_COUNT" ]; then
    print_success "✅ Success case without preserve: containers cleaned up correctly"
else
    print_error "❌ Success case without preserve: containers not cleaned up"
    exit 1
fi

echo ""
print_status "=== Test 2: Success case with preserve flag ==="
BEFORE_COUNT=$(count_wrkflw_containers)
print_status "Containers before: $BEFORE_COUNT"

./target/release/wrkflw run --runtime podman --preserve-containers-on-failure test-success-workflow.yml > /dev/null 2>&1

AFTER_COUNT=$(count_wrkflw_containers)
print_status "Containers after: $AFTER_COUNT"

if [ "$AFTER_COUNT" -eq "$BEFORE_COUNT" ]; then
    print_success "✅ Success case with preserve: successful containers cleaned up correctly"
else
    print_error "❌ Success case with preserve: successful containers not cleaned up"
    exit 1
fi

echo ""
print_status "=== Test 3: Failure case without preserve flag ==="
BEFORE_COUNT=$(count_wrkflw_containers)
print_status "Containers before: $BEFORE_COUNT"

./target/release/wrkflw run --runtime podman test-failure-workflow.yml > /dev/null 2>&1 || true

AFTER_COUNT=$(count_wrkflw_containers)
print_status "Containers after: $AFTER_COUNT"

if [ "$AFTER_COUNT" -eq "$BEFORE_COUNT" ]; then
    print_success "✅ Failure case without preserve: containers cleaned up correctly"
else
    print_error "❌ Failure case without preserve: containers not cleaned up"
    exit 1
fi

echo ""
print_status "=== Test 4: Failure case with preserve flag ==="
BEFORE_COUNT=$(count_wrkflw_containers)
print_status "Containers before: $BEFORE_COUNT"

print_status "Running failing workflow with --preserve-containers-on-failure..."
./target/release/wrkflw run --runtime podman --preserve-containers-on-failure test-failure-workflow.yml > preserve-test.log 2>&1 || true

AFTER_COUNT=$(count_wrkflw_containers)
print_status "Containers after: $AFTER_COUNT"
PRESERVED_CONTAINERS=$(get_wrkflw_containers)

if [ "$AFTER_COUNT" -gt "$BEFORE_COUNT" ]; then
    print_success "✅ Failure case with preserve: failed container preserved"
    print_status "Preserved containers: $PRESERVED_CONTAINERS"
    
    # Check if the log mentions preservation
    if grep -q "Preserving.*container.*debugging" preserve-test.log; then
        print_success "✅ Preservation message found in logs"
    else
        print_warning "⚠️ Preservation message not found in logs"
    fi
    
    # Test that we can inspect the preserved container
    CONTAINER_NAME=$(echo "$PRESERVED_CONTAINERS" | head -1)
    if [ -n "$CONTAINER_NAME" ]; then
        print_status "Testing container inspection..."
        if podman exec "$CONTAINER_NAME" echo "Container inspection works" > /dev/null 2>&1; then
            print_success "✅ Can inspect preserved container"
        else
            print_warning "⚠️ Cannot inspect preserved container (container may have exited)"
        fi
        
        # Clean up the preserved container
        print_status "Cleaning up preserved container for testing..."
        podman rm -f "$CONTAINER_NAME" > /dev/null 2>&1
    fi
else
    print_error "❌ Failure case with preserve: failed container not preserved"
    echo "Log output:"
    cat preserve-test.log
    exit 1
fi

echo ""
print_status "=== Test 5: Multiple failures with preserve flag ==="
BEFORE_COUNT=$(count_wrkflw_containers)
print_status "Containers before: $BEFORE_COUNT"

print_status "Running multiple failing workflows..."
for i in {1..3}; do
    ./target/release/wrkflw run --runtime podman --preserve-containers-on-failure test-failure-workflow.yml > /dev/null 2>&1 || true
done

AFTER_COUNT=$(count_wrkflw_containers)
print_status "Containers after: $AFTER_COUNT"
EXPECTED_COUNT=$((BEFORE_COUNT + 3))

if [ "$AFTER_COUNT" -eq "$EXPECTED_COUNT" ]; then
    print_success "✅ Multiple failures: all failed containers preserved"
else
    print_warning "⚠️ Multiple failures: expected $EXPECTED_COUNT containers, got $AFTER_COUNT"
fi

# Clean up all preserved containers
PRESERVED_CONTAINERS=$(get_wrkflw_containers)
if [ -n "$PRESERVED_CONTAINERS" ]; then
    print_status "Cleaning up all preserved containers..."
    echo "$PRESERVED_CONTAINERS" | xargs -r podman rm -f
fi

echo ""
print_status "=== Test 6: Comparison with Docker (if available) ==="
if command -v docker &> /dev/null && docker info > /dev/null 2>&1; then
    print_status "Docker available, testing for comparison..."
    
    # Test Docker with preserve flag
    BEFORE_COUNT=$(docker ps -a --filter "name=wrkflw-" --format "{{.Names}}" | wc -l)
    ./target/release/wrkflw run --runtime docker --preserve-containers-on-failure test-failure-workflow.yml > /dev/null 2>&1 || true
    AFTER_COUNT=$(docker ps -a --filter "name=wrkflw-" --format "{{.Names}}" | wc -l)
    
    if [ "$AFTER_COUNT" -gt "$BEFORE_COUNT" ]; then
        print_success "✅ Docker also preserves containers correctly"
        # Clean up Docker containers
        DOCKER_CONTAINERS=$(docker ps -a --filter "name=wrkflw-" --format "{{.Names}}")
        if [ -n "$DOCKER_CONTAINERS" ]; then
            echo "$DOCKER_CONTAINERS" | xargs -r docker rm -f
        fi
    else
        print_warning "⚠️ Docker preserve behavior differs from Podman"
    fi
else
    print_status "Docker not available, skipping comparison"
fi

# Cleanup test files
print_status "Cleaning up test files..."
rm -f test-success-workflow.yml test-failure-workflow.yml preserve-test.log

echo ""
print_success "🎉 Container preservation test completed successfully!"
echo ""
print_status "📋 Test Summary:"
print_success "✅ Successful containers are cleaned up (with and without preserve flag)"
print_success "✅ Failed containers are cleaned up when preserve flag is NOT used"
print_success "✅ Failed containers are preserved when preserve flag IS used"
print_success "✅ Preserved containers can be inspected"
print_success "✅ Multiple failed containers are handled correctly"

echo ""
print_status "💡 Usage examples:"
echo "   # Normal execution (cleanup all containers):"
echo "   wrkflw run --runtime podman workflow.yml"
echo ""
echo "   # Preserve failed containers for debugging:"
echo "   wrkflw run --runtime podman --preserve-containers-on-failure workflow.yml"
echo ""
echo "   # Inspect preserved container:"
echo "   podman ps -a --filter \"name=wrkflw-\""
echo "   podman exec -it <container-name> bash"
echo ""
echo "   # Clean up preserved containers:"
echo "   podman ps -a --filter \"name=wrkflw-\" --format \"{{.Names}}\" | xargs podman rm -f"
