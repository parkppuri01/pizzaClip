#!/usr/bin/env bash
#
# Build pizzaClip/AppIcon.icns from the 1024px source PNG.
#
# Why this exists: the source PNG (assets/pizzaClipAppIcon.png) lives outside the
# Xcode-bundled sources, and the .icns it produces is what actually ships. When
# the source was updated by hand it was easy to forget the sips+iconutil step and
# ship the *old* icon. release.sh now calls this every build so the icon can
# never go stale again.
#
# Usage: ./scripts/build-icon.sh

set -euo pipefail
cd "$(dirname "$0")/.."

SRC="assets/pizzaClipAppIcon.png"
OUT="pizzaClip/AppIcon.icns"

if [ ! -f "$SRC" ]; then
    echo "✗ Icon source not found: $SRC" >&2
    exit 1
fi

ICONSET="$(mktemp -d)/AppIcon.iconset"
mkdir -p "$ICONSET"

# macOS .icns expects these 10 size/scale variants.
gen() { sips -z "$2" "$2" "$SRC" --out "$ICONSET/icon_$1.png" >/dev/null; }
gen 16x16      16
gen 16x16@2x   32
gen 32x32      32
gen 32x32@2x   64
gen 128x128    128
gen 128x128@2x 256
gen 256x256    256
gen 256x256@2x 512
gen 512x512    512
gen 512x512@2x 1024

iconutil -c icns "$ICONSET" -o "$OUT"
rm -rf "$(dirname "$ICONSET")"
echo "✓ Built $OUT from $SRC"
