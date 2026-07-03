#!/bin/bash
# Build a signed + notarized + stapled DMG for HotSauce distribution.
# Assumes a Release build already exists at build/Build/Products/Release/HotSauce.app.
#
# Signing identity + notary profile come from scripts/release.local.sh (gitignored).
# Copy scripts/release.local.sh.example → scripts/release.local.sh and fill it in.
# (PicKle 의 release-test-dmg.sh 와 동일한 파이프라인.)
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

[ -f "$ROOT/scripts/release.local.sh" ] && source "$ROOT/scripts/release.local.sh"

APP="build/Build/Products/Release/HotSauce.app"
IDENTITY="${HOTSAUCE_SIGN_IDENTITY:?set HOTSAUCE_SIGN_IDENTITY in scripts/release.local.sh}"
NOTARY_PROFILE="${HOTSAUCE_NOTARY_PROFILE:?set HOTSAUCE_NOTARY_PROFILE in scripts/release.local.sh}"
ENTITLEMENTS="HotSauce/HotSauce.entitlements"
VERSION="$(/usr/libexec/PlistBuddy -c 'Print CFBundleShortVersionString' "$APP/Contents/Info.plist")"
OUT="$HOME/Downloads/HotSauce-${VERSION}.dmg"
WORK="$(mktemp -d)"

# Re-sign Sparkle's embedded helpers (Developer ID + hardened runtime + timestamp).
# A plain `xcodebuild build` leaves the framework's nested XPC services,
# Updater.app and Autoupdate *ad-hoc* signed → Apple notary rejects.
# Sign bottom-up (innermost first), then re-seal the outer .app.
SPARKLE_FW="$APP/Contents/Frameworks/Sparkle.framework"
if [ -d "$SPARKLE_FW" ]; then
    echo "→ [1/7] Re-signing embedded Sparkle helpers"
    SPARKLE_V="$(ls -d "$SPARKLE_FW"/Versions/[A-Z] 2>/dev/null | head -1)"
    sparkle_resign() {
        codesign --force --options runtime --timestamp --sign "$IDENTITY" "$1"
    }
    if [ -n "$SPARKLE_V" ]; then
        [ -d "$SPARKLE_V/XPCServices/Downloader.xpc" ] && sparkle_resign "$SPARKLE_V/XPCServices/Downloader.xpc"
        [ -d "$SPARKLE_V/XPCServices/Installer.xpc" ]  && sparkle_resign "$SPARKLE_V/XPCServices/Installer.xpc"
        [ -d "$SPARKLE_V/Updater.app" ] && sparkle_resign "$SPARKLE_V/Updater.app"
        [ -f "$SPARKLE_V/Autoupdate" ]  && sparkle_resign "$SPARKLE_V/Autoupdate"
        sparkle_resign "$SPARKLE_FW"
    fi
fi

echo "→ [1/7] Re-signing app with secure timestamp + hardened runtime"
codesign --force --options runtime --timestamp \
    --entitlements "$ENTITLEMENTS" \
    --sign "$IDENTITY" "$APP"
codesign --verify --deep --strict --verbose=2 "$APP"

echo "→ [2/7] Zipping app for notarization"
SUBMIT_ZIP="$WORK/HotSauce.zip"
ditto -c -k --keepParent "$APP" "$SUBMIT_ZIP"

echo "→ [3/7] Submitting app to Apple notary (1–5 min)…"
xcrun notarytool submit "$SUBMIT_ZIP" --keychain-profile "$NOTARY_PROFILE" --wait

echo "→ [4/7] Stapling app"
xcrun stapler staple "$APP"

echo "→ [5/7] Building DMG"
STAGE="$WORK/stage"
mkdir -p "$STAGE"
cp -R "$APP" "$STAGE/"
ln -s /Applications "$STAGE/Applications"
rm -f "$OUT"
hdiutil create -volname "HotSauce" -srcfolder "$STAGE" -ov -format UDZO "$OUT" >/dev/null
codesign --force --timestamp --sign "$IDENTITY" "$OUT"

echo "→ [6/7] Submitting DMG to Apple notary (2nd round, 1–5 min)…"
xcrun notarytool submit "$OUT" --keychain-profile "$NOTARY_PROFILE" --wait

echo "→ [7/7] Stapling DMG"
xcrun stapler staple "$OUT"

echo "=== gatekeeper check ==="
spctl -a -t open --context context:primary-signature -vv "$OUT" || true

rm -rf "$WORK"
echo "DONE: $OUT"
ls -lh "$OUT"
