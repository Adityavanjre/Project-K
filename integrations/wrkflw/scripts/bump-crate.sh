#!/bin/bash

# Script to bump individual crate versions and update workspace dependencies
# Usage: ./scripts/bump-crate.sh <crate-name> <version-type>
# Example: ./scripts/bump-crate.sh wrkflw-models patch
# Example: ./scripts/bump-crate.sh wrkflw-models 0.7.5

set -e

CRATE_NAME="$1"
VERSION_TYPE="$2"

if [[ -z "$CRATE_NAME" || -z "$VERSION_TYPE" ]]; then
    echo "Usage: $0 <crate-name> <version-type>"
    echo "  crate-name: Name of the crate to bump (e.g., wrkflw-models)"
    echo "  version-type: patch|minor|major or specific version (e.g., 0.7.5)"
    echo ""
    echo "Available crates:"
    ls crates/ | grep -v README.md
    exit 1
fi

CRATE_DIR="crates/${CRATE_NAME#wrkflw-}"
if [[ ! -d "$CRATE_DIR" ]]; then
    echo "Error: Crate directory '$CRATE_DIR' not found"
    echo "Available crates:"
    ls crates/ | grep -v README.md
    exit 1
fi

echo "Bumping $CRATE_NAME with $VERSION_TYPE..."

# Get current version from the crate's Cargo.toml
CURRENT_VERSION=$(grep "^version" "$CRATE_DIR/Cargo.toml" | head -1 | sed 's/.*= *"\([^"]*\)".*/\1/' | sed 's/.*workspace *= *true.*//')

if [[ "$CURRENT_VERSION" == "" ]]; then
    # If using workspace version, get it from workspace Cargo.toml
    CURRENT_VERSION=$(grep "^version" Cargo.toml | head -1 | sed 's/.*= *"\([^"]*\)".*/\1/')
    echo "Current workspace version: $CURRENT_VERSION"
else
    echo "Current crate version: $CURRENT_VERSION"
fi

# Calculate new version
if [[ "$VERSION_TYPE" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    NEW_VERSION="$VERSION_TYPE"
else
    # Use semver logic for patch/minor/major
    IFS='.' read -ra VERSION_PARTS <<< "$CURRENT_VERSION"
    MAJOR="${VERSION_PARTS[0]}"
    MINOR="${VERSION_PARTS[1]}"
    PATCH="${VERSION_PARTS[2]}"

    case "$VERSION_TYPE" in
        "patch")
            NEW_VERSION="$MAJOR.$MINOR.$((PATCH + 1))"
            ;;
        "minor")
            NEW_VERSION="$MAJOR.$((MINOR + 1)).0"
            ;;
        "major")
            NEW_VERSION="$((MAJOR + 1)).0.0"
            ;;
        *)
            echo "Error: Invalid version type. Use patch|minor|major or specify exact version"
            exit 1
            ;;
    esac
fi

echo "New version: $NEW_VERSION"

# Update the crate's Cargo.toml to use explicit version instead of workspace
sed -i.bak "s/version\.workspace = true/version = \"$NEW_VERSION\"/" "$CRATE_DIR/Cargo.toml"

# Update the workspace Cargo.toml with the new version
if grep -q "$CRATE_NAME.*version.*=" Cargo.toml; then
    sed -i.bak "s/\($CRATE_NAME.*version = \"\)[^\"]*\"/\1$NEW_VERSION\"/" Cargo.toml
else
    echo "Warning: $CRATE_NAME not found in workspace dependencies"
fi

# Clean up backup files
rm -f "$CRATE_DIR/Cargo.toml.bak" Cargo.toml.bak

echo ""
echo "✅ Successfully bumped $CRATE_NAME to version $NEW_VERSION"
echo ""
echo "Next steps:"
echo "1. Review the changes: git diff"
echo "2. Test the build: cargo check"
echo "3. Commit the changes: git add . && git commit -m 'bump: $CRATE_NAME to $NEW_VERSION'"
echo "4. Create a tag: git tag v$NEW_VERSION-$CRATE_NAME"
echo "5. Push: git push origin main --tags"
echo ""
echo "To publish individual crate:"
echo "  cd $CRATE_DIR && cargo publish"
