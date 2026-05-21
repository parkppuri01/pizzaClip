#!/usr/bin/env bash
#
# Build a Release universal myclip.app, package it as ZIP + DMG under dist/,
# and install a fresh copy to ~/Applications.
#
# Usage: ./scripts/release.sh

set -euo pipefail

cd "$(dirname "$0")/.."
REPO_ROOT="$(pwd -P)"

VERSION=$(grep "MARKETING_VERSION:" project.yml | head -1 | sed 's/.*"\([^"]*\)".*/\1/')
if [ -z "$VERSION" ]; then
    echo "✗ Could not read MARKETING_VERSION from project.yml" >&2
    exit 1
fi

echo "→ Generating Xcode project"
xcodegen generate >/dev/null

echo "→ Running tests"
xcodebuild -project myclip.xcodeproj -scheme myclip \
    -destination 'platform=macOS' test -quiet 2>&1 | tail -3

echo "→ Cleaning build/"
rm -rf build

echo "→ Building Release universal binary (version $VERSION)"
xcodebuild -project myclip.xcodeproj \
    -scheme myclip \
    -configuration Release \
    -derivedDataPath ./build \
    clean build 2>&1 | tail -3

APP="build/Build/Products/Release/myclip.app"
if [ ! -d "$APP" ]; then
    echo "✗ Build did not produce $APP" >&2
    exit 1
fi

echo "→ Verifying signature"
codesign -dv "$APP" 2>&1 | grep -E "Identifier=|Signature=" || true

echo "→ Packaging dist/"
mkdir -p dist
rm -f "dist/myclip-${VERSION}.zip" "dist/myclip-${VERSION}.dmg"

# ZIP — preserves resource forks, recommended by Apple for .app distribution
ditto -c -k --sequesterRsrc --keepParent "$APP" "dist/myclip-${VERSION}.zip"

# DMG with an Applications shortcut for drag-to-install UX
STAGING=$(mktemp -d)
cp -R "$APP" "$STAGING/"
ln -s /Applications "$STAGING/Applications"
hdiutil create -volname "myclip $VERSION" \
    -srcfolder "$STAGING" \
    -ov -format UDZO \
    "dist/myclip-${VERSION}.dmg" >/dev/null
rm -rf "$STAGING"

echo "→ Installing to ~/Applications"
mkdir -p ~/Applications
rm -rf ~/Applications/myclip.app
cp -R "$APP" ~/Applications/

echo ""
echo "✓ Release $VERSION ready"
ls -lh "dist/myclip-${VERSION}.zip" "dist/myclip-${VERSION}.dmg" \
    | awk '{printf "  %-9s  %s\n", $5, $NF}'
echo "  installed → $HOME/Applications/myclip.app"
