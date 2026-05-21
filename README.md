# myclip

macOS clipboard history app. See `docs/superpowers/specs/2026-05-21-myclip-design.md`.

## Generate Xcode project

    xcodegen generate

## Build

    xcodebuild -project myclip.xcodeproj -scheme myclip -destination 'platform=macOS' build
