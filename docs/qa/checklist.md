# myclip Manual QA Checklist

Run before any release tag. Tick each box as it passes; record any failure in a follow-up commit.

## Setup
- [ ] App launches with no Dock icon; menu bar shows the clipboard glyph.
- [ ] First launch prompts for Accessibility permission. Granting it requires no app restart (subsequent auto-paste should work; if not, restart once and re-verify).
- [ ] `~/Library/Application Support/myclip/db.sqlite` is created after the first clipboard event.

## Capture
- [ ] Copy text in Safari → ⌘⇧V → popup shows it at top, source app icon is Safari.
- [ ] Copy text twice in a row (same body) → only one history row exists (dedupe).
- [ ] ⌘⇧⌃4 screenshot → appears as an Image item with a thumbnail.
- [ ] ⌘C a file in Finder → file row labeled with the file name + parent dir; pasting into another Finder window creates a copy.
- [ ] Copy text in 1Password (or any app on the blacklist) → no entry appears in history.
- [ ] Copy a password from a manager that uses `org.nspasteboard.ConcealedType` → no entry appears.

## Popup interaction
- [ ] Pressing ↵ pastes the selected item into the previously focused app.
- [ ] ↑ / ↓ moves the selection ring.
- [ ] ⌫ when the search field is empty deletes the selected item; with text in the field, ⌫ deletes characters.
- [ ] ⌘P toggles pin; pinned items show the coral pin glyph.
- [ ] Pinned items appear above non-pinned items in the popup.
- [ ] ⎋ closes the popup.
- [ ] Slot badges 1–9 appear on the most-recent 9 non-pinned items; pinned items don't get a badge.

## Hotkeys
- [ ] ⌘⇧V opens/toggles the popup.
- [ ] After assigning slot 1–3 in Settings → Shortcuts, hitting the slot hotkey from any app pastes the Nth most-recent non-pinned item without showing the popup.
- [ ] Auto-paste leaves the original frontmost app focused (no `myclip` activation flash).

## Settings
- [ ] General → History cap stepper takes effect on next capture; older non-pinned items are pruned.
- [ ] Shortcuts → re-recording the popup hotkey applies immediately (no restart).
- [ ] Privacy → adding a bundle ID to the blacklist takes effect immediately on the next capture.
- [ ] Storage → "Open data folder" reveals `~/Library/Application Support/myclip/` in Finder.
- [ ] Storage → "Clear all history" wipes both rows and blob files; pinned items are also removed (current spec).

## Persistence
- [ ] Quit and relaunch the app → history (including pins) is restored.
- [ ] Quit while a screenshot is in history → on relaunch, the thumbnail still renders.

## Visual
- [ ] Toggle System Settings → Appearance between Light and Dark → popup re-renders correctly in both.
- [ ] Selection ring uses the coral accent in both modes.
- [ ] Popup has 14pt rounded corners, hairline border, and translucent material.
