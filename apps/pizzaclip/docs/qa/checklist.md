# pizzaClip Manual QA Checklist

Run before any release tag. Tick each box as it passes; record any failure in a follow-up commit.

App version: 0.1.6 · Last updated: 2026-05-29

---

## Install & first launch

- [ ] `./scripts/release.sh` produces `dist/pizzaClip-0.1.6.{zip,dmg}` and installs `/Applications/pizzaClip.app`.
- [ ] `defaults read /Applications/pizzaClip.app/Contents/Info CFBundleShortVersionString` reports **0.1.6** (Info.plist reads from `$(MARKETING_VERSION)` in project.yml).
- [ ] `codesign -dvv /Applications/pizzaClip.app 2>&1 | grep -E "Authority|Runtime|flags"` shows `Developer ID Application: jaekeun park (R684FN2S7J)` + `flags=0x10000(runtime)` (0.1.6: Developer ID + hardened runtime + timestamped signature).
- [ ] `spctl -a -t open --context context:primary-signature -v dist/pizzaClip-0.1.6.dmg` returns `accepted` / `source=Notarized Developer ID` (0.1.6: DMG itself is signed + notarized + stapled, not just the .app inside).
- [ ] `xcrun stapler validate /Applications/pizzaClip.app` reports "The validate action worked!" (0.1.6: notarization ticket stapled).
- [ ] `/Applications/pizzaClip.app` shows the new pizzaClip app icon in Finder (kill Finder if cached: `killall Finder`).
- [ ] Spotlight (⌘ Space) finds "pizzaClip" with the new icon.
- [ ] Launch the app: no Dock icon appears, clipboard glyph shows in the menu bar.
- [ ] System Accessibility prompt appears **exactly once** on first launch ever — even after relaunch it does not pop again (UserDefaults-gated).
- [ ] **(0.1.6) Developer ID migration alert**: an existing 0.1.5 user (with `didShowAccessibilityPrompt=true`) launching 0.1.6 for the first time sees an NSAlert "권한 재승인이 필요합니다 (0.1.5 → 0.1.6)" with steps to remove + re-add pizzaClip in Accessibility. Buttons: "시스템 설정 열기" (opens Accessibility pane) or "나중에" (dismiss). Flag `didMigrateToDeveloperID` set on first show — alert never appears again. Fresh installs do **not** see this alert.
- [ ] `~/Library/Application Support/pizzaClip/db.sqlite` is created on first clipboard event. `blobs/` appears once an image is copied.
- [ ] Quit and relaunch — no second prompt; menu bar icon comes back.

## Status bar icon

- [ ] **Left-click** toggles the popup. The popup slides down from below the menu bar icon with a fade-in.
- [ ] **Right-click** (or Ctrl-click) opens the menu: Open Popup · Settings… · Grant Accessibility… · Quit pizzaClip.
- [ ] Left-click while popup is open closes it.
- [ ] Menu → "Open Popup" also opens the popup with the same slide-down animation.
- [ ] Menu → "Grant Accessibility…" opens System Settings → Privacy & Security → Accessibility (no extra system prompt).

### Pizza icon (0.1.6 — PNG asset set, 10 stages)

- [ ] On fresh launch with empty history: icon is **PizzaIcon0** (designed empty state).
- [ ] After each copy 1…7: icon swaps to PizzaIcon1, PizzaIcon2, …, PizzaIcon7 in lockstep with the item count (slices 1 through 7).
- [ ] On the 8th item: icon is **PizzaIcon8** (single pizza box, lid open — capacity reached). The old "8 slices" art is gone — the box appears one item earlier than in 0.1.5.
- [ ] On the 9th item and beyond: icon is **PizzaIcon9** (stacked pizza boxes — overflow). Removing items steps back through 8 → 7 → 6 ….
- [ ] Settings → Clear all (or popup Clear all) → icon returns to PizzaIcon0.
- [ ] Toggle System Settings → Appearance Light/Dark — PNG painted colors stay intact (template rendering disabled, so no auto-tint).

### Pizza easter egg (0.1.6 — pizza + 피자 exact-match)

- [ ] Copy the literal single word **"pizza"** (case-insensitive, surrounding whitespace OK: `pizza`, `Pizza`, ` PIZZA `) → popup auto-opens and 🍕 emojis burst out from the bottom, peak around mid-height, then fall back down. Animation lasts ~2.4s.
- [ ] **(0.1.6)** Copy the literal Korean word **"피자"** (exact match, surrounding whitespace OK: `피자`, ` 피자 `) → same 🍕 burst as the English trigger.
- [ ] Copy a sentence containing "pizza" / "피자" (e.g. `Pizza party`, `피자 먹자`, `I love PIZZA`) → **no auto-open, no burst** (exact match only).
- [ ] Particles stay inside the popup's rounded rectangle (no escape past the chrome).
- [ ] List rows and footer buttons remain interactive while pizzas are flying (overlay does not block hits).
- [ ] After a burst plays, close the popup with ⎋ and re-open it via the menu-bar icon or ⌘⇧V → **no burst replay** (0.1.4 fix: stale burst trigger is cleared on each show).
- [ ] Copy `pizza` again while the popup is already open → a fresh burst starts on top of any remaining particles from the previous one.
- [ ] Copy `pizza` twice in a row → second capture is dropped by the monitor signature dedupe, so no second burst (expected behavior).
- [ ] Copy a non-pizza string (e.g. `hello world`) → no auto-open, no burst.

## Capture

- [ ] Copy text in Safari → ⌘⇧V → popup shows it at top.
- [ ] Copy the same text twice → only one history row exists (dedupe).
- [ ] ⌘⇧⌃4 screenshot → image item labelled **"Capture Image"** with a real thumbnail.
- [ ] ⌘C an image file in Finder (JPG / HEIC / PNG / GIF) → image item labelled with just the **file name** (`sample.jpg`, not the full path) and thumbnail. Full path is still preserved on the pasteboard at paste time. Pasting into Messages / Slack inserts the image; pasting into Finder copies the file.
- [ ] ⌘C a non-image file in Finder (.txt / .pdf / etc.) → file row labelled with the filename only; pasting into another Finder window creates a copy at the original path.
- [ ] **No `file:///.file/id=…` ever appears** in row titles, even momentarily — Finder reference URLs are resolved at capture time (0.1.1 fix).
- [ ] Copy the same file from Finder twice in a row → **one** row, not two (path-based dedupe, 0.1.1).
- [ ] Take two screenshots in quick succession → one row each (content-signature dedupe at the monitor catches macOS firing changeCount twice for one shot; 0.1.1).
- [ ] Verify blob storage retains original format: open `~/Library/Application Support/pizzaClip/blobs/` and confirm `.jpg`/`.heic`/`.gif` files (not all converted to `.png`).
- [ ] Copy in 1Password (or any blacklisted app) → no entry appears in history.
- [ ] Copy a password from a manager that uses `org.nspasteboard.ConcealedType` → no entry appears.

## Popup — visuals

- [ ] Title bar at the top reads "pizzaClip — Clipboard History" with a **🍕 pizza emoji** to its left (replaced the old white clipboard glyph).
- [ ] Close button (×) on the top-right has **no blue focus ring** — just a grey glyph.
- [ ] Below the title there is a **"9 → 1 full paste"** row with a coral `0` shortcut badge on the left and a down-arrow glyph on the right. No search field is shown anywhere in the popup.
- [ ] Hovering the full-paste row keeps it visually static (no extra highlight required) and the cursor changes to indicate it is clickable.
- [ ] Footer line 1: `↵ Paste(or Num)` · `⌫ Delete` · `⌘P Pin` — symbols grey, action words in **coral** · right side: 🗑 `Clear all` · `⌘, Settings`, both grey (0.1.1).
- [ ] Footer line 2: small drive glyph + abbreviated storage path (e.g. `~/Library/Application Support/pizzaClip`).
- [ ] Slot badges 1–9 appear only on the 9 newest **non-pinned** items.
- [ ] Pinned items show the coral pin glyph and sort above non-pinned.
- [ ] Popup has 14pt rounded corners, hairline border, translucent HUD material.
- [ ] Toggle System Settings → Appearance between Light and Dark → popup re-renders correctly.

## Popup — keyboard

- [ ] ↑ / ↓ moves the selection. When the selection reaches the bottom of the visible area, the list auto-scrolls to keep it centered (i.e. arrow ↓ past row 9 still works).
- [ ] ↵ pastes the selected item into the previously focused app.
- [ ] ⌫ deletes the selected row (and its blob if it was an image). No search field exists, so there is no editing-vs-delete ambiguity.
- [ ] ⌘P toggles pin on the selected item. The item floats to the top **and the highlight follows it** there.
- [ ] ⎋ closes the popup; focus returns to the app that was frontmost before opening.
- [ ] **Bare digits 1–9** (no modifiers) → paste the Nth non-pinned visible row and close. Matches slot badges.
- [ ] **Bare digit 0** (no modifiers) → closes the popup and pastes the top-9 non-pinned items into the previously focused app in chronological copy order: slot 9 (oldest of the top 9) first, then 8 … 1 (most recent) last. Same action as clicking the "9 → 1 full paste" row.
- [ ] Full-paste sequence: open a fresh text document, copy 9 distinct strings A→B→…→I (I being the most recent), press ⌘⇧V then 0 → the document ends up containing `A B C D E F G H I` in that order, and the final pasteboard holds `I` (slot 1).
- [ ] Full-paste with fewer than 9 history items → only the available non-pinned items are pasted, still in oldest-first order. Pinned items are skipped.
- [ ] Without Accessibility granted: bare 0 leaves only the **most-recent** item on the pasteboard (no auto-paste). Slot pastes still work the same way they did before.

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
- [ ] Auto-paste leaves the original frontmost app focused (no `pizzaClip` activation flash that lingers).
- [ ] Re-recording the popup hotkey in Settings → Shortcuts applies immediately (no restart).

## Settings — General

- [ ] History cap stepper range is **1 to 20** (step 1). Default for fresh install is **9**.
- [ ] Changing the cap takes effect on the next capture; older non-pinned items are pruned, pinned items survive.

## Settings — Shortcuts

- [ ] All ten KeyboardShortcuts.Recorder fields (popup + slots 1–9) accept new bindings and apply immediately.

### Input source (0.1.5 — right ⌘ Hangul toggle)

- [ ] "Input source" section sits **between** "Popup" and "Direct paste" sections in the Shortcuts tab.
- [ ] Default state on fresh install: checkbox **off**, no key tap is intercepted.
- [ ] Enable the checkbox while Accessibility is **not** granted → an alert appears explaining the requirement; clicking "Open System Settings" opens the Accessibility pane; the checkbox is auto-reverted to **off**.
- [ ] Grant Accessibility, then enable the checkbox → no alert, checkbox stays **on**.
- [ ] In any text field (Safari URL bar, TextEdit, Slack, Notes…) cleanly tap **right ⌘** by itself → the active input source flips between Hangul and the Latin keyboard. Repeat tap flips back.
- [ ] Type **right ⌘ + C** (or any chord using right ⌘) → behaves as the normal shortcut, **no** input source toggle fires.
- [ ] Hold right ⌘ for a second, then release without pressing anything else → still toggles (clean tap detection works on slow release).
- [ ] **Left ⌘** alone tap → does **not** toggle (only right ⌘ is the trigger).
- [ ] Disable the checkbox → next right ⌘ tap is a no-op. Re-enable → toggle resumes without restart.
- [ ] Quit and relaunch the app with the checkbox on → toggle is auto-armed on launch (state persists in UserDefaults under `rightCommandHangulToggle`).
- [ ] **(0.1.6) Permission auto-recovery**: launch pizzaClip with checkbox ON but Accessibility revoked → tap silently fails to install (logged). Open System Settings → Accessibility → toggle pizzaClip ON without touching pizzaClip's own checkbox. Within ~2 seconds the right-⌘ tap starts working — no need to come back to pizzaClip Settings and re-toggle the checkbox. Distributed notification `com.apple.accessibility.api` + NSWorkspace activation + 2 s polling all serve as recovery signals.
- [ ] System Settings → Keyboard → Input Sources has at least one Korean source (e.g. 2-Set Korean) **and** one Latin source (e.g. ABC) enabled. With only one input source available, tap does nothing (expected — nothing to toggle to).
- [ ] Perceived latency: tap → switch feels instantaneous, well under 60 ms (one display frame at 60 Hz).

## Settings — Privacy

- [ ] Blacklist textarea accepts comma-separated bundle IDs. Adding an entry blocks captures from that app on the next copy without restart.

## Settings — Storage

- [ ] "Location" row shows the current storage path. "Open in Finder" reveals it.
- [ ] "Change…" opens a folder picker; choosing a folder writes the path to UserDefaults and shows a "Restart required" alert.
- [ ] "Reset to default" reverts to `~/Library/Application Support/pizzaClip/` and shows the same restart alert; the button is disabled when already on the default.
- [ ] Restarting the app uses the new folder for `db.sqlite` and `blobs/`. Old data is **not** auto-migrated (documented expectation).
- [ ] "Export history to text…" writes a `pizzaClip-history.txt` with all rows (pinned first, then newest first), each preceded by a header line containing date, type, source bundle, and pin indicator.
- [ ] "Clear all history" wipes both DB rows and image blob files (including pinned items, per current spec).

## Persistence

- [ ] Quit and relaunch — history (including pins) is restored.
- [ ] Image items still render their thumbnails after relaunch.
- [ ] Pinned items keep their pinned state and position after relaunch.

## Storage layout

- [ ] Open `~/Library/Application Support/pizzaClip/` in Finder.
- [ ] Contains `db.sqlite` (text + metadata + thumbnails) and `blobs/` (full-resolution PNGs).
- [ ] `blobs/` is **flat** — each PNG sits directly inside, named `<uuid>.png` (no 2-char prefix subfolders).
- [ ] After "Clear all history" the `blobs/` folder is empty (or only contains files from concurrent inserts).

## Edge cases

- [ ] Open the popup with zero history items → list is empty; ↵ does nothing; typing in search works.
- [ ] Type a query that matches nothing → list empty, footer still shows shortcut hints.
- [ ] Pin 12 items, set cap to 20 → those 12 pins survive even as new copies arrive and prune the non-pinned tail.
- [ ] Copy a multi-megabyte text payload → app stays responsive (storage layer is async via GRDB queue).
- [ ] Without Accessibility granted: selecting an item still puts payload on the clipboard; user can ⌘V manually. No alert pops on every paste.
