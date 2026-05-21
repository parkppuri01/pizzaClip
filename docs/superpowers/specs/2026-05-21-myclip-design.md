# myclip — macOS Clipboard History App Design

**Date:** 2026-05-21
**Status:** Draft (pending user review)
**Owner:** jekeun.p@gmail.com

## 1. Purpose

A personal macOS clipboard history utility. Every copy (text, image including screenshots, file references) is captured automatically. The user opens a popup via a global hotkey, picks an item, and it is auto-pasted into the previously focused application. Direct hotkeys (⌘⌥⌃1–9) paste the Nth most-recent item without opening the popup.

Success criteria:

- Captures ⌘C and screenshot clipboard events with no perceptible lag.
- Popup opens within 100ms of the hotkey and does not steal focus from the previous app.
- Selecting an item auto-pastes into the prior frontmost app via synthesized ⌘V.
- History survives reboots; capped at a user-configurable item count (default 200).
- Sensitive clipboard contents (concealed type, blacklisted apps) are silently dropped.

Non-goals:

- iCloud / cross-device sync.
- Rich text (RTF) preservation — only plain text is stored for text content.
- Sharing or exporting history to other apps.
- App Store distribution (personal use; signing only what local Gatekeeper needs).

## 2. Tech Stack

- **Language / UI:** Swift 5.9+, SwiftUI for views, AppKit shell for window/focus control.
- **Min macOS:** 13 (Ventura). Avoids SwiftData (macOS 14+) to keep the floor low.
- **Persistence:** SQLite via [GRDB.swift](https://github.com/groue/GRDB.swift). FTS5 virtual table for full-text search of clipboard text.
- **Global hotkeys + shortcut UI:** [`KeyboardShortcuts`](https://github.com/sindresorhus/KeyboardShortcuts) (sindresorhus).
- **Build:** Xcode project, single app target. `LSUIElement = YES` so no Dock icon.

## 3. Architecture Overview

```
+--------------------------------------------------------------+
|                       AppDelegate (AppKit)                   |
|  - NSStatusItem (menu bar icon)                              |
|  - Registers global hotkeys via KeyboardShortcuts            |
|  - Owns PopupPanelController, ClipboardMonitor, PasteEngine  |
+--------------------------------------------------------------+
       |                |                  |              |
       v                v                  v              v
+-------------+ +-----------------+ +-------------+ +-----------+
| Clipboard   | | Popup Panel     | | Paste       | | Settings  |
| Monitor     | | Controller      | | Engine      | | Window    |
| (Timer +    | | (NSPanel.non-   | | (CGEvent    | | (SwiftUI  |
|  NSPaste-   | |  activating +   | |  ⌘V into    | |  Form)    |
|  board)     | |  SwiftUI view)  | |  prev app)  | |           |
+-------------+ +-----------------+ +-------------+ +-----------+
       |                |                  |              |
       +----------------+------------------+--------------+
                                |
                                v
                +----------------------------------+
                |          HistoryStore            |
                |  GRDB SQLite + FTS5 + blob dir   |
                |  ~/Library/Application Support/  |
                |     myclip/{db.sqlite, blobs/}   |
                +----------------------------------+
```

### Module responsibilities (one purpose each)

- **`ClipboardMonitor`** — polls `NSPasteboard.general.changeCount` every 400ms; on change, classifies the payload and emits a `CapturedItem` to `HistoryStore`. Handles the concealed-type and app-blacklist checks. Does not touch UI.
- **`HistoryStore`** — the single source of truth for items. CRUD over GRDB. Methods: `insert(item)`, `delete(id)`, `togglePin(id)`, `setMostRecent(id)`, `search(query, limit)`, `topN(n)`. Publishes a Combine `@Published` snapshot for UI binding.
- **`PopupPanelController`** — manages the `NSPanel(.nonactivatingPanel)`, its SwiftUI content view (`PopupView`), open/close lifecycle, focus restoration, and frame positioning. Calls `PasteEngine` on selection.
- **`PasteEngine`** — given an item, writes its payload to `NSPasteboard.general`, reactivates the recorded previous frontmost app, then synthesizes ⌘V via `CGEvent`. Exposes a `pasteDirect(slot: Int)` for the 1–9 hotkeys. Falls back to "clipboard-only" mode if Accessibility permission is denied.
- **`SettingsWindow`** — SwiftUI settings: hotkeys (via `KeyboardShortcuts.Recorder`), history cap, app blacklist (drag-drop apps or pick from running list), launch at login, paste delay.
- **`AppDelegate`** — composition root. Wires modules. Handles permission prompts (Accessibility) and the menu bar icon menu.

### Data flow

1. User ⌘C in Safari → macOS updates `NSPasteboard.general`.
2. `ClipboardMonitor` ticks, sees changed `changeCount`, reads pasteboard.
3. Checks: concealed type? blacklisted app (via `NSWorkspace.shared.frontmostApplication.bundleIdentifier` recorded on the previous tick)? If yes → drop.
4. Otherwise, build `CapturedItem { id, type, textOrBlobRef, sourceBundleID, timestamp }`. Image blobs written to `blobs/<uuid>.png`; thumbnail (256px PNG) stored inline in DB.
5. `HistoryStore.insert` → DB write → publishes new snapshot. If item count > cap, prune oldest non-pinned.
6. User hits ⌘⇧V → `AppDelegate` records `prevFrontmostBundleID = NSWorkspace.shared.frontmostApplication?.bundleIdentifier` BEFORE showing popup → `PopupPanelController.show()`.
7. User picks item / presses ↵ → `PasteEngine.paste(item, restoring: prevFrontmostBundleID)`.
8. `PasteEngine`: writes payload to pasteboard → `NSRunningApplication(bundleIdentifier: prev).activate()` → ~50ms delay → synthesize ⌘V down/up → close popup.

### Error & permission handling

- **Accessibility permission missing:** Detected at first paste attempt and on launch. Show a one-time alert with "Open System Settings" deep link (`x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility`). Until granted, selection puts item on clipboard only and shows a transient toast: "Granted Accessibility to enable auto-paste."
- **DB open failure:** Log + show a non-modal alert; fall back to an in-memory store for the session so the app stays usable.
- **Pasteboard read failure on a specific type:** Skip that representation; do not crash the monitor.
- **Image blob write failure:** Drop the item, log; do not insert a dangling DB row.

## 4. Data Model (SQLite)

```sql
CREATE TABLE items (
  id            TEXT PRIMARY KEY,            -- UUID
  type          TEXT NOT NULL,               -- 'text' | 'image' | 'file'
  text          TEXT,                        -- for text/file (file = absolute path)
  blob_path     TEXT,                        -- for image: relative path under blobs/
  thumb_png     BLOB,                        -- for image: 256px PNG, ~10-30KB
  source_bundle TEXT,                        -- bundle id of source app
  created_at    INTEGER NOT NULL,            -- unix ms
  pinned        INTEGER NOT NULL DEFAULT 0   -- 0/1
);
CREATE INDEX idx_items_created ON items(created_at DESC);
CREATE INDEX idx_items_pinned  ON items(pinned, created_at DESC);

CREATE VIRTUAL TABLE items_fts USING fts5(text, content='items', content_rowid='rowid');
-- triggers keep items_fts in sync with items.text
```

Pruning rule: when `count(pinned=0) > cap`, delete oldest by `created_at`, also unlinking `blob_path`.

## 5. UI / Visual Design

Target aesthetic: **Claude Desktop app** — calm, minimal, slightly warm, system-aware.

### Popup window (`PopupView` inside `NSPanel`)

- **Frame:** 440 × 480pt, rounded 14pt corners, 1px hairline border using `separatorColor`. `NSVisualEffectView` background, `.hudWindow` material, `.behindWindow` blending.
- **Position:** screen center, vertically biased upward (≈40% from top), like Spotlight.
- **Animation:** fade + 8pt slide-down on open (120ms ease-out), reverse on close (80ms).
- **Search field (top, 44pt):** rounded 10pt, magnifier glyph, placeholder "Search clipboard…", autofocus on open. Typing filters; empty query shows full ordered list.
- **List rows (64pt height, 8pt horizontal padding, 4pt vertical gap):**
  - Left: 28pt type glyph (`doc.text` / `photo` / `folder`) in `secondaryLabel`.
  - Center: title (1 line, 13pt, `label`) + subtitle (1 line, 11pt, `secondaryLabel`). For text → first 80 chars, newlines collapsed. For image → "Image · 1280×720 · 142 KB". For file → file name + parent dir.
  - Right: source app icon (16pt) over relative time ("just now", "3m"), pin glyph (toggles on click).
  - Hover/selection: rounded 8pt fill at `controlAccentColor.opacity(0.12)`, 1.5pt accent ring on keyboard focus.
- **Sections:** if any pinned items exist, render them first under a small "Pinned" header (11pt, `tertiaryLabel`), then "History" header.
- **Footer (28pt, 11pt text, `secondaryLabel`):** `↵ Paste · ⌫ Delete · ⌘P Pin · ⌘, Settings`.
- **Accent color:** Claude's coral/orange `#D97757` for selection ring, pin icon when active, and the slot badge.
- **Slot badge:** Shown on the **9 most-recent non-pinned items** as a small `1`–`9` chip on the row's right side (tooltip: "⌘⌥⌃1"). Pinned items never get a slot badge — the 1–9 hotkeys always map to recency, not popup position.

### Menu bar icon

Monochrome SF Symbol `doc.on.clipboard`. Right-click menu: Open Popup · Open Settings · Quit. Left-click also opens popup.

### Settings window

`NSWindow` + SwiftUI `Form`, left sidebar with sections: **General · Shortcuts · Privacy · Storage**. Mirrors Claude Desktop's settings layout.

- General: launch at login, popup width/height, history cap (slider 50–500).
- Shortcuts: KeyboardShortcuts.Recorder for `togglePopup` and slots 1–9.
- Privacy: list of bundle IDs to exclude (add via "+" button which lists running apps, or drag .app onto the list).
- Storage: "Open data folder", "Clear all history" (with confirm).

### Dark / light mode

Everything driven by system semantic colors and materials. No hardcoded color values except the accent.

## 6. Hotkeys (defaults)

| Action | Default |
|---|---|
| Open popup | ⌘⇧V |
| Paste Nth most-recent | ⌘⌥⌃1 … ⌘⌥⌃9 |
| Inside popup: next/prev | ↓ / ↑ |
| Inside popup: paste selected | ↵ |
| Inside popup: delete selected | ⌫ |
| Inside popup: toggle pin | ⌘P |
| Inside popup: close | ⎋ |

All configurable in Settings → Shortcuts.

## 7. Privacy & Capture Rules

A captured pasteboard is **dropped** (not stored, not even briefly) when any of:

1. It declares the UTI `org.nspasteboard.ConcealedType` (the de-facto standard used by 1Password, Bitwarden, etc.).
2. It declares `org.nspasteboard.TransientType` or `org.nspasteboard.AutoGeneratedType`.
3. The current frontmost app's bundle ID is in the user blacklist. Defaults seeded: `com.1password.1password`, `com.agilebits.onepassword7`, `com.bitwarden.desktop`, `com.apple.keychainaccess`.

Stored data lives only under `~/Library/Application Support/myclip/`. No network calls. No analytics.

## 8. Testing Strategy

- **Unit tests (XCTest):**
  - `HistoryStore`: insert/prune/pin/search round-trips against an in-memory GRDB queue. FTS query correctness.
  - `ClipboardMonitor`: feed synthetic pasteboards (an in-memory adapter behind a `PasteboardReader` protocol) and assert classifier output + drop rules.
  - `PasteEngine`: payload-to-pasteboard mapping (no CGEvent in unit tests — that goes to manual QA).
- **Integration / manual QA checklist** (in repo as `docs/qa/checklist.md`):
  - Copy text in Safari → popup shows it → ↵ pastes into Notes.
  - Take ⌘⇧⌃4 screenshot → appears as image item with thumbnail.
  - ⌘C a file in Finder → file item, pasting into Finder elsewhere creates the file there.
  - Copy in 1Password → no entry appears.
  - ⌘⌥⌃3 from any app pastes the 3rd most-recent item without opening popup.
  - Toggle Accessibility off → selection puts item on clipboard, shows toast.
  - Restart app → history persists, pins retained.

## 9. Open Risks / Decisions Deferred

- **Sandboxing:** Initial version is **not** sandboxed (simpler Accessibility flow, full file paths preserved). If we later distribute, revisit; clipboard monitoring is compatible with sandbox but app blacklist by bundle ID needs entitlements review.
- **Code signing:** Developer ID Application signing locally for Gatekeeper. No notarization for the personal build.
- **Long-text DB bloat:** Mitigated by item cap. If a user copies massive payloads (>5MB text), we truncate the stored text to 5MB and keep a "truncated" flag.
- **Multiple monitors:** Popup centers on the screen containing the current mouse cursor.

## 10. Out of Scope (Confirmed)

- iCloud sync
- RTF / styled text preservation
- Cross-machine
- Plugins / extensions
- Cloud backup
