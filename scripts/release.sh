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

SIGN_IDENTITY=$(grep "CODE_SIGN_IDENTITY:" project.yml | head -1 | sed 's/.*"\(.*\)".*/\1/')

# Re-sign Sparkle's embedded helpers with Developer ID + hardened runtime +
# secure timestamp. A plain `xcodebuild build` (unlike Xcode's Archive/Export)
# leaves the framework's nested XPC services, Updater.app and Autoupdate
# *ad-hoc* signed (TeamIdentifier=not set), which Apple's notary service
# rejects. We sign bottom-up (innermost first), then re-seal the outer .app.
echo "→ Re-signing embedded Sparkle helpers (Developer ID + runtime + timestamp)"
SPARKLE_FW="$APP/Contents/Frameworks/Sparkle.framework"
SPARKLE_V=$(ls -d "$SPARKLE_FW"/Versions/[A-Z] 2>/dev/null | head -1)
sparkle_resign() {
    codesign --force --options runtime --timestamp --sign "$SIGN_IDENTITY" "$1" \
        2>&1 | sed 's/^/    /'
}
if [ -d "$SPARKLE_FW" ] && [ -n "$SPARKLE_V" ]; then
    sparkle_resign "$SPARKLE_V/XPCServices/Downloader.xpc"
    sparkle_resign "$SPARKLE_V/XPCServices/Installer.xpc"
    sparkle_resign "$SPARKLE_V/Updater.app"
    sparkle_resign "$SPARKLE_V/Autoupdate"
    sparkle_resign "$SPARKLE_FW"
    # Re-seal the app last (nested changes invalidate the outer seal). Reapply
    # the empty entitlements so Release stays free of get-task-allow.
    codesign --force --options runtime --timestamp \
        --entitlements pizzaClip/pizzaClip.entitlements \
        --sign "$SIGN_IDENTITY" "$APP" 2>&1 | sed 's/^/    /'
else
    echo "✗ Sparkle.framework not found under $APP — aborting before notary" >&2
    exit 1
fi

echo "→ Verifying signature (Developer ID + hardened runtime, deep)"
codesign --verify --deep --strict "$APP" || { echo "✗ deep verify failed" >&2; exit 1; }
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

# ── Sparkle auto-update: sign the ZIP + emit an appcast <item> ───────────────
# The notarized+stapled ZIP above is exactly what Sparkle downloads and swaps in.
# We EdDSA-sign it with the private key in the login Keychain (generated once via
# Sparkle's generate_keys) and write a ready-to-paste appcast <item> to dist/.
# Publishing — `gh release` upload + pushing appcast.xml to the Vercel domain — is
# intentionally NOT automated yet: it needs the GitHub repo + Vercel domain, which
# are still TBD. See the TODO block below.
SIGN_UPDATE="./build/SourcePackages/artifacts/sparkle/Sparkle/bin/sign_update"
ZIP="dist/pizzaClip-${VERSION}.zip"
BUILD_NUMBER=$(grep "CURRENT_PROJECT_VERSION:" project.yml | head -1 | sed 's/.*"\([^"]*\)".*/\1/')
# Base URL the ZIP will be downloaded from. Override once hosting is decided, e.g.
#   DOWNLOAD_BASE_URL="https://github.com/<owner>/pizzaClip/releases/download/v${VERSION}" ./scripts/release.sh
DOWNLOAD_BASE_URL="${DOWNLOAD_BASE_URL:-https://REPLACE-WITH-DOWNLOAD-HOST.invalid}"

if [ -x "$SIGN_UPDATE" ]; then
    echo "→ Signing ZIP for Sparkle (EdDSA)"
    SIG_LINE=$("$SIGN_UPDATE" "$ZIP")
    echo "    $SIG_LINE"

    PUBDATE=$(LC_TIME=en_US.UTF-8 date -u "+%a, %d %b %Y %H:%M:%S +0000")
    APPCAST_ITEM="dist/appcast-item-${VERSION}.xml"
    cat > "$APPCAST_ITEM" <<EOF
        <item>
            <title>pizzaClip ${VERSION}</title>
            <pubDate>${PUBDATE}</pubDate>
            <sparkle:version>${BUILD_NUMBER}</sparkle:version>
            <sparkle:shortVersionString>${VERSION}</sparkle:shortVersionString>
            <sparkle:minimumSystemVersion>13.0</sparkle:minimumSystemVersion>
            <enclosure url="${DOWNLOAD_BASE_URL}/pizzaClip-${VERSION}.zip"
                       type="application/octet-stream"
                       ${SIG_LINE} />
        </item>
EOF
    echo "    appcast <item> → $APPCAST_ITEM"
else
    echo "⚠ sign_update not found ($SIGN_UPDATE)."
    echo "  Run: xcodebuild -project pizzaClip.xcodeproj -scheme pizzaClip \\"
    echo "       -resolvePackageDependencies -derivedDataPath ./build"
    echo "  Skipping Sparkle signing."
fi

# TODO — wire up once the GitHub repo + Vercel domain are confirmed:
#   1. Upload binaries to a host Sparkle can fetch without auth, e.g. a public
#      GitHub release:
#        gh release create "v${VERSION}" "$ZIP" "dist/pizzaClip-${VERSION}.dmg" \
#          --title "pizzaClip ${VERSION}" --notes-file dist/notes-${VERSION}.md
#      and re-run with DOWNLOAD_BASE_URL set to that release's download base.
#   2. Merge dist/appcast-item-${VERSION}.xml into the master appcast.xml and
#      deploy to https://<vercel-domain>/appcast.xml.
#   3. Set Info.plist SUFeedURL to that same https://<vercel-domain>/appcast.xml.

echo ""
echo "✓ Release $VERSION ready"
ls -lh "dist/pizzaClip-${VERSION}.zip" "dist/pizzaClip-${VERSION}.dmg" \
    | awk '{printf "  %-9s  %s\n", $5, $NF}'
echo "  installed → /Applications/pizzaClip.app"
