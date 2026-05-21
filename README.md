# myclip

A personal macOS clipboard history app. Menu-bar only. Captures text, images (including screenshots), and file references. Pick from a Spotlight-style popup; auto-pastes into the previously focused app. Direct hotkeys for slots 1–9.

## Requirements

- macOS 13 (Ventura) or later
- Xcode 15+ (any recent Xcode works; project pins Swift 5.9)
- [XcodeGen](https://github.com/yonaskolb/XcodeGen) — `brew install xcodegen`

## Build

```sh
xcodegen generate
xcodebuild -project myclip.xcodeproj -scheme myclip -destination 'platform=macOS' build
```

The `.xcodeproj` is intentionally gitignored — regenerate it from `project.yml`.

## Test

```sh
xcodebuild -project myclip.xcodeproj -scheme myclip -destination 'platform=macOS' test
```

## Run

Open `myclip.xcodeproj` in Xcode and ⌘R, or launch the built `myclip.app` from `DerivedData`. The first launch will prompt for Accessibility permission — granting it enables auto-paste.

## Permissions

- **Accessibility** — required to synthesize ⌘V into the previously focused app. Without it, the selected item still lands on the clipboard, but you'll need to press ⌘V yourself.

## Hotkeys (defaults)

| Action | Default |
|---|---|
| Open popup | ⌘⇧V |
| Inside popup: next / prev | ↓ / ↑ |
| Inside popup: paste selected | ↵ |
| Inside popup: delete selected (when search is empty) | ⌫ |
| Inside popup: toggle pin | ⌘P |
| Inside popup: close | ⎋ |
| Paste Nth most-recent | assign in Settings → Shortcuts |

All shortcuts are reconfigurable.

## Data

Stored at `~/Library/Application Support/myclip/`:
- `db.sqlite` — clipboard rows + FTS5 search index
- `blobs/` — image PNG files

No network traffic. No telemetry. Sensitive payloads (concealed pasteboard types, blacklisted apps) are dropped before insertion.

## Architecture

- `myclip/App/` — AppKit composition root (`AppDelegate`, paths, status item)
- `myclip/Clipboard/` — `ClipboardMonitor` polling + `PasteboardReader` abstraction
- `myclip/Storage/` — GRDB-backed `HistoryStore` + FTS5 + `BlobStore`
- `myclip/Paste/` — `PasteEngine` (writes pasteboard, synthesizes ⌘V)
- `myclip/Popup/` — `NSPanel(.nonactivatingPanel)` + SwiftUI `PopupView`
- `myclip/Settings/` — SwiftUI settings tabs (General / Shortcuts / Privacy / Storage)
- `myclip/Shortcuts/` — `KeyboardShortcuts.Name` extensions
- `myclip/Permissions/` — Accessibility trust helpers
- `myclip/DesignSystem/` — colors, theme constants

See `docs/superpowers/specs/2026-05-21-myclip-design.md` for the design rationale and `docs/superpowers/plans/2026-05-21-myclip.md` for the task-by-task implementation log.

## QA

Manual QA checklist: `docs/qa/checklist.md`.
