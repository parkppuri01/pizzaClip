# myclip Manual QA Checklist

Run before any release tag. Tick each box as it passes; record any failure in a follow-up commit.

App version: 0.1.1 · Last updated: 2026-05-24

---

## Install & first launch

- [ ] `./scripts/release.sh` produces `dist/myclip-0.1.1.{zip,dmg}` and installs `~/Applications/myclip.app`.
- [ ] `defaults read ~/Applications/myclip.app/Contents/Info CFBundleShortVersionString` reports **0.1.1** (Info.plist now reads from `$(MARKETING_VERSION)` in project.yml).
- [ ] `~/Applications/myclip.app` shows the custom clipboard icon in Finder (kill Finder if cached: `killall Finder`).
- [ ] Spotlight (⌘ Space) finds "myclip" with the new icon.
- [ ] Launch the app: no Dock icon appears, clipboard glyph shows in the menu bar.
- [ ] System Accessibility prompt appears **exactly once** on first launch ever — even after relaunch it does not pop again (UserDefaults-gated).
- [ ] `~/Library/Application Support/myclip/db.sqlite` is created on first clipboard event. `blobs/` appears once an image is copied.
- [ ] Quit and relaunch — no second prompt; menu bar icon comes back.

## Status bar icon

- [ ] **Left-click** toggles the popup. The popup slides down from below the menu bar icon with a fade-in.
- [ ] **Right-click** (or Ctrl-click) opens the menu: Open Popup · Settings… · Grant Accessibility… · Quit myclip.
- [ ] Left-click while popup is open closes it.
- [ ] Menu → "Open Popup" also opens the popup with the same slide-down animation.
- [ ] Menu → "Grant Accessibility…" opens System Settings → Privacy & Security → Accessibility (no extra system prompt).

### Pizza icon (0.1.1)

- [ ] On fresh launch with empty history: icon is a thin gold crust ring (no slices).
- [ ] After 1 copy: one beige slice at the 12 o'clock position. After 2: two adjacent slices clockwise. Continues clockwise as more items arrive.
- [ ] At 8 items: full beige pizza inside the crust ring (no empty wedges).
- [ ] On the 9th item: icon flips to a closed pizza box (rounded rectangle with a horizontal seam).
- [ ] Removing items via popup ⌫ updates the icon back down through the slice states.
- [ ] Settings → Clear all (or popup Clear all) → icon returns to the empty crust ring.
- [ ] Toggle System Settings → Appearance Light/Dark — empty wedges stay transparent so the menu-bar background shows through correctly in both modes.

## Capture

- [ ] Copy text in Safari → ⌘⇧V → popup shows it at top.
- [ ] Copy the same text twice → only one history row exists (dedupe).
- [ ] ⌘⇧⌃4 screenshot → image item labelled **"Capture Image"** with a real thumbnail.
- [ ] ⌘C an image file in Finder (JPG / HEIC / PNG / GIF) → image item labelled with just the **file name** (`sample.jpg`, not the full path) and thumbnail. Full path is still preserved on the pasteboard at paste time. Pasting into Messages / Slack inserts the image; pasting into Finder copies the file.
- [ ] ⌘C a non-image file in Finder (.txt / .pdf / etc.) → file row labelled with the filename only; pasting into another Finder window creates a copy at the original path.
- [ ] **No `file:///.file/id=…` ever appears** in row titles, even momentarily — Finder reference URLs are resolved at capture time (0.1.1 fix).
- [ ] Copy the same file from Finder twice in a row → **one** row, not two (path-based dedupe, 0.1.1).
- [ ] Take two screenshots in quick succession → one row each (content-signature dedupe at the monitor catches macOS firing changeCount twice for one shot; 0.1.1).
- [ ] Verify blob storage retains original format: open `~/Library/Application Support/myclip/blobs/` and confirm `.jpg`/`.heic`/`.gif` files (not all converted to `.png`).
- [ ] Copy in 1Password (or any blacklisted app) → no entry appears in history.
- [ ] Copy a password from a manager that uses `org.nspasteboard.ConcealedType` → no entry appears.

## Popup — visuals

- [ ] Title bar at the top reads "MyClip — Clipboard History" with a **white** clipboard glyph to its left.
- [ ] Close button (×) on the top-right has **no blue focus ring** — just a grey glyph.
- [ ] Search field auto-receives focus on open — typing flows into it without clicking.
- [ ] Footer line 1: `↵ Paste(or Num)` · `⌫ Delete` · `⌘P Pin` — symbols grey, action words in **coral** · right side: 🗑 `Clear all` · `⌘, Settings`, both grey (0.1.1).
- [ ] Footer line 2: small drive glyph + abbreviated storage path (e.g. `~/Library/Application Support/myclip`).
- [ ] Slot badges 1–9 appear only on the 9 newest **non-pinned** items.
- [ ] Pinned items show the coral pin glyph and sort above non-pinned.
- [ ] Popup has 14pt rounded corners, hairline border, translucent HUD material.
- [ ] Toggle System Settings → Appearance between Light and Dark → popup re-renders correctly.

## Popup — keyboard

- [ ] ↑ / ↓ moves the selection. When the selection reaches the bottom of the visible area, the list auto-scrolls to keep it centered (i.e. arrow ↓ past row 9 still works).
- [ ] ↵ pastes the selected item into the previously focused app.
- [ ] ⌫ when the search field is empty → deletes the selected row (and its blob if it was an image).
- [ ] ⌫ when the search field has text → deletes characters from the query (normal editing).
- [ ] ⌘P toggles pin on the selected item. The item floats to the top **and the highlight follows it** there.
- [ ] ⎋ closes the popup; focus returns to the app that was frontmost before opening.
- [ ] **Bare digits 1–9** (no modifiers, empty search field) → paste the Nth non-pinned visible row and close. Matches slot badges.
- [ ] Digits while typing a search query → flow into the field normally (e.g. "1password" search works).

## Popup — mouse

- [ ] Hovering a row highlights it but **does not** auto-scroll the viewport.
- [ ] Mouse wheel scrolls the list natively. As rows pass under the cursor, highlight follows the row currently beneath it.
- [ ] Clicking a row picks it (same as ↵).
- [ ] Clicking the storage path in the footer reveals the data folder in Finder.
- [ ] Clicking `⌘, Settings` in the footer opens the Settings window and closes the popup.
- [ ] Clicking 🗑 `Clear all` in the footer closes the popup and shows a warning NSAlert ("Clear all clipboard history?"). Confirming wipes history + blobs; cancelling leaves everything intact (0.1.1).
- [ ] **Clicking any other window** while the popup is open closes the popup and lets that window take focus (resignKey auto-close, 0.1.1).
- [ ] Right after pressing an arrow key, brief mouse motion does NOT clobber the keyboard selection (0.25s hover-ignore window).

## Hotkeys

- [ ] ⌘⇧V opens/toggles the popup (default).
- [ ] ⌘⌥⌃1 from any app pastes the most-recent non-pinned item with no popup shown.
- [ ] ⌘⌥⌃3 / ⌘⌥⌃9 work the same for the 3rd / 9th most-recent.
- [ ] Auto-paste leaves the original frontmost app focused (no `myclip` activation flash that lingers).
- [ ] Re-recording the popup hotkey in Settings → Shortcuts applies immediately (no restart).

## Settings — General

- [ ] History cap stepper range is **1 to 20** (step 1). Default for fresh install is **9**.
- [ ] Changing the cap takes effect on the next capture; older non-pinned items are pruned, pinned items survive.

## Settings — Shortcuts

- [ ] All ten KeyboardShortcuts.Recorder fields (popup + slots 1–9) accept new bindings and apply immediately.

## Settings — Privacy

- [ ] Blacklist textarea accepts comma-separated bundle IDs. Adding an entry blocks captures from that app on the next copy without restart.

## Settings — Storage

- [ ] "Location" row shows the current storage path. "Open in Finder" reveals it.
- [ ] "Change…" opens a folder picker; choosing a folder writes the path to UserDefaults and shows a "Restart required" alert.
- [ ] "Reset to default" reverts to `~/Library/Application Support/myclip/` and shows the same restart alert; the button is disabled when already on the default.
- [ ] Restarting the app uses the new folder for `db.sqlite` and `blobs/`. Old data is **not** auto-migrated (documented expectation).
- [ ] "Export history to text…" writes a `myclip-history.txt` with all rows (pinned first, then newest first), each preceded by a header line containing date, type, source bundle, and pin indicator.
- [ ] "Clear all history" wipes both DB rows and image blob files (including pinned items, per current spec).

## Persistence

- [ ] Quit and relaunch — history (including pins) is restored.
- [ ] Image items still render their thumbnails after relaunch.
- [ ] Pinned items keep their pinned state and position after relaunch.

## Storage layout

- [ ] Open `~/Library/Application Support/myclip/` in Finder.
- [ ] Contains `db.sqlite` (text + metadata + thumbnails) and `blobs/` (full-resolution PNGs).
- [ ] `blobs/` is **flat** — each PNG sits directly inside, named `<uuid>.png` (no 2-char prefix subfolders).
- [ ] After "Clear all history" the `blobs/` folder is empty (or only contains files from concurrent inserts).

## Edge cases

- [ ] Open the popup with zero history items → list is empty; ↵ does nothing; typing in search works.
- [ ] Type a query that matches nothing → list empty, footer still shows shortcut hints.
- [ ] Pin 12 items, set cap to 20 → those 12 pins survive even as new copies arrive and prune the non-pinned tail.
- [ ] Copy a multi-megabyte text payload → app stays responsive (storage layer is async via GRDB queue).
- [ ] Without Accessibility granted: selecting an item still puts payload on the clipboard; user can ⌘V manually. No alert pops on every paste.
