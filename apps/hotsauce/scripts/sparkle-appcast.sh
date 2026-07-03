#!/bin/bash
# Sparkle auto-update: EdDSA-sign a built HotSauce DMG and emit a ready-to-paste
# appcast <item> (plus a full appcast.xml) under dist/.
#
# The private EdDSA key lives in the login Keychain (pizzaClip/PicKle 과 같은
# 키쌍 재사용). Sparkle's `sign_update` reads it automatically.
#
# Usage:
#   DOWNLOAD_BASE_URL=https://pizza-clip.com/hotsauce ./scripts/sparkle-appcast.sh [dmg]
#
# If no DMG path is given, defaults to the newest HotSauce-*.dmg in ~/Downloads.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

DMG="${1:-}"
if [ -z "$DMG" ]; then
    DMG="$(ls -t "$HOME"/Downloads/HotSauce-*.dmg 2>/dev/null | head -1 || true)"
fi
if [ -z "$DMG" ] || [ ! -f "$DMG" ]; then
    echo "✗ No DMG found. Pass one explicitly: ./scripts/sparkle-appcast.sh <dmg>" >&2
    exit 1
fi
echo "→ DMG: $DMG"

SIGN_UPDATE="$(find build -type f -name sign_update -path '*sparkle*/bin/*' 2>/dev/null | head -1 || true)"
if [ -z "$SIGN_UPDATE" ]; then
    SIGN_UPDATE="$(find build -type f -name sign_update 2>/dev/null | head -1 || true)"
fi
if [ -z "$SIGN_UPDATE" ] || [ ! -x "$SIGN_UPDATE" ]; then
    echo "✗ sign_update not found under build/. Resolve Sparkle first:" >&2
    echo "    xcodebuild -project HotSauce.xcodeproj -scheme HotSauce \\" >&2
    echo "      -resolvePackageDependencies -derivedDataPath build \\" >&2
    echo "      -clonedSourcePackagesDirPath build/SourcePackages" >&2
    exit 1
fi
echo "→ sign_update: $SIGN_UPDATE"

VERSION="$(grep 'MARKETING_VERSION:' project.yml | head -1 | sed 's/.*"\([^"]*\)".*/\1/')"
BUILD_NUMBER="$(grep 'CURRENT_PROJECT_VERSION:' project.yml | head -1 | sed 's/.*"\([^"]*\)".*/\1/')"
[ -n "$VERSION" ] || { echo "✗ Could not read MARKETING_VERSION from project.yml" >&2; exit 1; }
echo "→ Version $VERSION (build $BUILD_NUMBER)"

mkdir -p dist

echo "→ Signing DMG for Sparkle (EdDSA)"
SIG_LINE="$("$SIGN_UPDATE" "$DMG")"
echo "    $SIG_LINE"

# 릴리스 노트: dist/notes-<version>.md 하나로 Sparkle + 사이트 공용.
# 주의: md_to_html 은 **볼드** 인라인 마크다운을 지원하지 않음 — 별표 금지.
md_to_html() {
    awk '
        function esc(s) { gsub(/&/,"\\&amp;",s); gsub(/</,"\\&lt;",s); gsub(/>/,"\\&gt;",s); return s }
        function closelist() { if (inlist) { print "</ul>"; inlist=0 } }
        BEGIN { inlist=0 }
        { line=$0; sub(/\r$/,"",line) }
        line ~ /^[[:space:]]*$/ { closelist(); next }
        line ~ /^## /  { closelist(); sub(/^## /,"",line); print "<h3>" esc(line) "</h3>"; next }
        line ~ /^# /   { closelist(); sub(/^# /,"",line);  print "<h2>" esc(line) "</h2>"; next }
        line ~ /^[-*] / { if (!inlist){print "<ul>"; inlist=1} sub(/^[-*] /,"",line); print "<li>" esc(line) "</li>"; next }
        { closelist(); print "<p>" esc(line) "</p>" }
        END { closelist() }
    ' "$1"
}
NOTES="dist/notes-${VERSION}.md"
[ -f "$NOTES" ] || printf '# HotSauce %s\n\n- 버그 수정 및 개선\n' "$VERSION" > "$NOTES"
NOTES_HTML="$(md_to_html "$NOTES")"

DMG_NAME="$(basename "$DMG")"
DOWNLOAD_BASE_URL="${DOWNLOAD_BASE_URL:-https://pizza-clip.com/hotsauce}"

PUBDATE="$(LC_TIME=en_US.UTF-8 date -u "+%a, %d %b %Y %H:%M:%S +0000")"
APPCAST_ITEM="dist/appcast-item-${VERSION}.xml"
cat > "$APPCAST_ITEM" <<EOF
        <item>
            <title>HotSauce ${VERSION}</title>
            <pubDate>${PUBDATE}</pubDate>
            <sparkle:version>${BUILD_NUMBER}</sparkle:version>
            <sparkle:shortVersionString>${VERSION}</sparkle:shortVersionString>
            <sparkle:minimumSystemVersion>13.0</sparkle:minimumSystemVersion>
            <description><![CDATA[
${NOTES_HTML}
]]></description>
            <enclosure url="${DOWNLOAD_BASE_URL}/${DMG_NAME}"
                       type="application/octet-stream"
                       ${SIG_LINE} />
        </item>
EOF
echo "    appcast <item> → $APPCAST_ITEM"

APPCAST="dist/appcast.xml"
cat > "$APPCAST" <<EOF
<?xml version="1.0" encoding="utf-8"?>
<rss version="2.0" xmlns:sparkle="http://www.andymatuschak.org/xml-namespaces/sparkle">
    <channel>
        <title>HotSauce</title>
        <link>https://pizza-clip.com/hotsauce/appcast.xml</link>
        <description>HotSauce updates</description>
        <language>en</language>
$(cat "$APPCAST_ITEM")
    </channel>
</rss>
EOF
echo "    full appcast → $APPCAST"

echo ""
echo "✓ Sparkle signing done for HotSauce $VERSION"
echo "  Next steps (manual):"
echo "    1. DMG + appcast.xml 을 pizzaClip web 레포 web/public/hotsauce/ 에 복사"
echo "    2. git push → Vercel 자동 배포 → https://pizza-clip.com/hotsauce/appcast.xml"
