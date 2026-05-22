#!/bin/bash

# Enhanced script to manage versions and publish all wrkflw crates using cargo-workspaces

set -e

# Parse command line arguments
COMMAND=${1:-""}
VERSION_TYPE=${2:-""}
DRY_RUN=""

show_help() {
    echo "Usage: $0 <command> [options]"
    echo ""
    echo "Commands:"
    echo "  version <type>     Update versions across workspace"
    echo "                     Types: patch, minor, major"
    echo "  publish           Publish all crates to crates.io"
    echo "  release <type>    Update versions and publish (combines version + publish)"
    echo "  help              Show this help message"
    echo ""
    echo "Options:"
    echo "  --dry-run         Test without making changes (for publish/release)"
    echo ""
    echo "Examples:"
    echo "  $0 version minor                    # Bump to 0.7.0"
    echo "  $0 publish --dry-run               # Test publishing"
    echo "  $0 release minor --dry-run         # Test version bump + publish"
    echo "  $0 release patch                   # Release patch version"
}

# Parse dry-run flag from any position
for arg in "$@"; do
    if [[ "$arg" == "--dry-run" ]]; then
        DRY_RUN="--dry-run"
    fi
done

case "$COMMAND" in
    "help"|"-h"|"--help"|"")
        show_help
        exit 0
        ;;
    "version")
        if [[ -z "$VERSION_TYPE" ]]; then
            echo "❌ Error: Version type required (patch, minor, major)"
            echo ""
            show_help
            exit 1
        fi
        ;;
    "publish")
        # publish command doesn't need version type
        ;;
    "release")
        if [[ -z "$VERSION_TYPE" ]]; then
            echo "❌ Error: Version type required for release (patch, minor, major)"
            echo ""
            show_help
            exit 1
        fi
        ;;
    *)
        echo "❌ Error: Unknown command '$COMMAND'"
        echo ""
        show_help
        exit 1
        ;;
esac

# Check if cargo-workspaces is installed
if ! command -v cargo-workspaces &> /dev/null; then
    echo "❌ cargo-workspaces not found. Installing..."
    cargo install cargo-workspaces
fi

# Check if we're logged in to crates.io (only for publish operations)
if [[ "$COMMAND" == "publish" ]] || [[ "$COMMAND" == "release" ]]; then
    if [ ! -f ~/.cargo/credentials.toml ] && [ ! -f ~/.cargo/credentials ]; then
        echo "❌ Not logged in to crates.io. Please run: cargo login <your-token>"
        exit 1
    fi
fi

# Function to update versions
update_versions() {
    local version_type=$1
    echo "🔄 Updating workspace versions ($version_type)..."
    
    if [[ "$DRY_RUN" == "--dry-run" ]]; then
        echo "🧪 DRY RUN: Simulating version update"
        echo ""
        echo "Current workspace version: $(grep '^version =' Cargo.toml | cut -d'"' -f2)"
        echo "Would execute: cargo workspaces version $version_type"
        echo ""
        echo "This would update all crates and their internal dependencies."
        echo "✅ Version update simulation completed (no changes made)"
    else
        cargo workspaces version "$version_type"
        echo "✅ Versions updated successfully"
    fi
}

# Function to test build
test_build() {
    echo "🔨 Testing workspace build..."
    if cargo build --workspace; then
        echo "✅ Workspace builds successfully"
    else
        echo "❌ Build failed. Please fix errors before publishing."
        exit 1
    fi
}

# Function to publish crates
publish_crates() {
    echo "📦 Publishing crates to crates.io..."
    
    if [[ "$DRY_RUN" == "--dry-run" ]]; then
        echo "🧪 DRY RUN: Testing publication"
        cargo workspaces publish --dry-run
        echo "✅ All crates passed dry-run tests!"
        echo ""
        echo "To actually publish, run:"
        echo "  $0 publish"
    else
        cargo workspaces publish
        echo "🎉 All crates published successfully!"
        echo ""
        echo "Users can now install wrkflw with:"
        echo "  cargo install wrkflw"
    fi
}

# Function to show changelog info
show_changelog_info() {
    echo "📝 Changelog will be generated automatically by GitHub Actions workflow"
}

# Execute commands based on the operation
case "$COMMAND" in
    "version")
        update_versions "$VERSION_TYPE"
        show_changelog_info
        ;;
    "publish")
        test_build
        publish_crates
        ;;
    "release")
        echo "🚀 Starting release process..."
        echo ""
        
        # Step 1: Update versions
        update_versions "$VERSION_TYPE"
        
        # Step 2: Test build
        test_build
        
        # Step 3: Show changelog info
        show_changelog_info
        
        # Step 4: Publish (if not dry-run)
        if [[ "$DRY_RUN" != "--dry-run" ]]; then
            echo ""
            read -p "🤔 Continue with publishing? (y/N): " -n 1 -r
            echo
            if [[ $REPLY =~ ^[Yy]$ ]]; then
                publish_crates
            else
                echo "⏸️  Publishing cancelled. To publish later, run:"
                echo "  $0 publish"
            fi
        else
            echo ""
            publish_crates
        fi
        ;;
esac
