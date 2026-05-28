#!/usr/bin/env bash
#
# Build a Release universal pizzaClip.app, package it as ZIP + DMG under dist/,
# and install a fresh copy to /Applications.
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
xcodebuild -project pizzaClip.xcodeproj -scheme pizzaClip \
    -destination 'platform=macOS' test -quiet 2>&1 | tail -3

echo "→ Cleaning build/"
rm -rf build

echo "→ Building Release universal binary (version $VERSION)"
xcodebuild -project pizzaClip.xcodeproj \
    -scheme pizzaClip \
    -configuration Release \
    -derivedDataPath ./build \
    clean build 2>&1 | tail -3

APP="build/Build/Products/Release/pizzaClip.app"
if [ ! -d "$APP" ]; then
    echo "✗ Build did not produce $APP" >&2
    exit 1
fi

echo "→ Verifying signature (Developer ID + hardened runtime)"
codesign -dvv "$APP" 2>&1 | grep -E "Identifier=|Authority=|Timestamp=|flags=" || true

mkdir -p dist
rm -f "dist/pizzaClip-${VERSION}.zip" "dist/pizzaClip-${VERSION}.dmg"

# Submit a temporary ZIP to Apple notary, wait, then staple the .app in-place.
NOTARY_PROFILE="pizzaClip notary"
SUBMIT_DIR=$(mktemp -d)
SUBMIT_ZIP="$SUBMIT_DIR/pizzaClip-submit.zip"

echo "→ Creating notary submission archive"
ditto -c -k --sequesterRsrc --keepParent "$APP" "$SUBMIT_ZIP"

echo "→ Submitting to Apple notary service (typically 1–5 min)"
NOTARY_OUT=$(xcrun notarytool submit "$SUBMIT_ZIP" \
    --keychain-profile "$NOTARY_PROFILE" \
    --wait 2>&1)
echo "$NOTARY_OUT"
rm -rf "$SUBMIT_DIR"

SUBMISSION_ID=$(echo "$NOTARY_OUT" | awk '$1 == "id:" {print $2; exit}')
NOTARY_STATUS=$(echo "$NOTARY_OUT" | awk '$1 == "status:" {print $2; exit}')
if [ "$NOTARY_STATUS" != "Accepted" ]; then
    echo ""
    echo "✗ Notarization failed (status=$NOTARY_STATUS). Fetching log…"
    xcrun notarytool log "$SUBMISSION_ID" --keychain-profile "$NOTARY_PROFILE" || true
    exit 1
fi

echo "→ Stapling notarization ticket to .app"
xcrun stapler staple "$APP"

echo "→ Packaging final ZIP + DMG (from stapled .app)"
# ZIP — preserves resource forks, recommended by Apple for .app distribution
ditto -c -k --sequesterRsrc --keepParent "$APP" "dist/pizzaClip-${VERSION}.zip"

# DMG with an Applications shortcut for drag-to-install UX
STAGING=$(mktemp -d)
cp -R "$APP" "$STAGING/"
ln -s /Applications "$STAGING/Applications"
hdiutil create -volname "pizzaClip $VERSION" \
    -srcfolder "$STAGING" \
    -ov -format UDZO \
    "dist/pizzaClip-${VERSION}.dmg" >/dev/null
rm -rf "$STAGING"

echo "→ Signing DMG with Developer ID"
SIGN_IDENTITY=$(grep "CODE_SIGN_IDENTITY:" project.yml | head -1 | sed 's/.*"\(.*\)".*/\1/')
codesign --sign "$SIGN_IDENTITY" --timestamp "dist/pizzaClip-${VERSION}.dmg"

echo "→ Submitting DMG to Apple notary service (2nd round, typically 1–5 min)"
DMG_NOTARY_OUT=$(xcrun notarytool submit "dist/pizzaClip-${VERSION}.dmg" \
    --keychain-profile "$NOTARY_PROFILE" \
    --wait 2>&1)
echo "$DMG_NOTARY_OUT"

DMG_SUBMISSION_ID=$(echo "$DMG_NOTARY_OUT" | awk '$1 == "id:" {print $2; exit}')
DMG_NOTARY_STATUS=$(echo "$DMG_NOTARY_OUT" | awk '$1 == "status:" {print $2; exit}')
if [ "$DMG_NOTARY_STATUS" != "Accepted" ]; then
    echo ""
    echo "✗ DMG notarization failed (status=$DMG_NOTARY_STATUS). Fetching log…"
    xcrun notarytool log "$DMG_SUBMISSION_ID" --keychain-profile "$NOTARY_PROFILE" || true
    exit 1
fi

echo "→ Stapling notarization ticket to DMG"
xcrun stapler staple "dist/pizzaClip-${VERSION}.dmg"

echo "→ Gatekeeper verdict"
spctl -a -t open --context context:primary-signature -vv "dist/pizzaClip-${VERSION}.dmg" 2>&1 | sed 's/^/    /' || true

echo "→ Installing to /Applications"
rm -rf /Applications/pizzaClip.app
cp -R "$APP" /Applications/

echo ""
echo "✓ Release $VERSION ready"
ls -lh "dist/pizzaClip-${VERSION}.zip" "dist/pizzaClip-${VERSION}.dmg" \
    | awk '{printf "  %-9s  %s\n", $5, $NF}'
echo "  installed → /Applications/pizzaClip.app"
