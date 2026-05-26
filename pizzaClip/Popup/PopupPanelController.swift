import AppKit
import SwiftUI

/// Borderless NSPanel that *can* accept key + main status. The defaults on a
/// styleMask-less NSPanel are too restrictive — SwiftUI inputs (TextField,
/// onTapGesture, onHover) need a key window with main status to behave.
final class FocusablePanel: NSPanel {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { true }
}

final class PopupPanelController {
    private var panel: FocusablePanel?
    private var previousFrontmostBundleID: String?
    private let store: HistoryStore
    private let viewModel: PopupViewModel
    private let pasteEngine: PasteEngine
    private let blobStore: BlobStore?
    private var keyMonitor: Any?
    private var historyObserver: NSObjectProtocol?
    private var resignKeyObserver: NSObjectProtocol?

    init(store: HistoryStore, viewModel: PopupViewModel, pasteEngine: PasteEngine, blobStore: BlobStore?) {
        self.store = store
        self.viewModel = viewModel
        self.pasteEngine = pasteEngine
        self.blobStore = blobStore

        // While the popup is visible, refresh the list whenever the store
        // changes — new captures arriving in the background, pins/deletes
        // triggered from within the popup, etc.
        historyObserver = NotificationCenter.default.addObserver(
            forName: .pizzaClipHistoryChanged, object: nil, queue: .main
        ) { [weak self] _ in
            guard self?.panel?.isVisible == true else { return }
            self?.viewModel.reload()
        }
    }

    deinit {
        uninstallKeyMonitor()
        if let o = historyObserver { NotificationCenter.default.removeObserver(o) }
        if let o = resignKeyObserver { NotificationCenter.default.removeObserver(o) }
    }

    func toggle(anchorRect: NSRect? = nil) {
        if let panel = panel, panel.isVisible { close(); return }
        show(anchorRect: anchorRect)
    }

    /// Easter egg entry point: ensures the popup is visible, then fires a
    /// fresh pizza burst inside it. Safe to call whether or not the popup is
    /// already open.
    func showWithPizzaBurst(anchorRect: NSRect? = nil) {
        let wasHidden = panel?.isVisible != true
        if wasHidden {
            show(anchorRect: anchorRect)
        }
        // Defer the trigger by one runloop tick so SwiftUI has a chance to
        // mount `PizzaBurst` before we mutate its observed `pizzaBurstID`.
        // Without this, an `.onChange` registered during the same tick as
        // the first body evaluation can silently miss the very first burst.
        DispatchQueue.main.async { [weak self] in
            self?.viewModel.triggerPizzaBurst()
        }
    }

    func show(anchorRect: NSRect? = nil) {
        previousFrontmostBundleID = NSWorkspace.shared.frontmostApplication?.bundleIdentifier
        // Clear any stale easter-egg trigger from a previous session so a
        // fresh popup mount doesn't replay the last burst. `showWithPizzaBurst`
        // sets a new UUID *after* show() returns, so legitimate triggers
        // survive this reset.
        viewModel.pizzaBurstID = nil
        viewModel.reload()

        let view = PopupView(
            vm: viewModel,
            onPick: { [weak self] item in self?.pick(item) },
            onClose: { [weak self] in self?.close() },
            onSettings: { [weak self] in
                // Dismiss the popup *without* re-activating the previous app —
                // otherwise the just-opened Settings window loses focus to
                // whatever was frontmost before we opened the popup. Defer the
                // open-settings notification to the next runloop tick so panel
                // teardown finishes before SwiftUI tries to raise its window.
                self?.close(restorePreviousApp: false)
                DispatchQueue.main.async {
                    NotificationCenter.default.post(name: .pizzaClipOpenSettings, object: nil)
                }
            },
            onClearAll: { [weak self] in
                // Close the popup first — otherwise NSAlert taking key status
                // would trip our resignKey observer and tear the popup down
                // mid-confirmation. Same flow Settings uses (warn → post).
                self?.close(restorePreviousApp: false)
                DispatchQueue.main.async {
                    let alert = NSAlert()
                    alert.messageText = "Clear all clipboard history?"
                    alert.alertStyle = .warning
                    alert.addButton(withTitle: "Clear")
                    alert.addButton(withTitle: "Cancel")
                    if alert.runModal() == .alertFirstButtonReturn {
                        NotificationCenter.default.post(name: .pizzaClipClearAll, object: nil)
                    }
                }
            },
            onPasteAll: { [weak self] in self?.pasteAllReverse() }
        )
        let hosting = NSHostingView(rootView: view)

        let panel = FocusablePanel(
            contentRect: NSRect(x: 0, y: 0, width: Theme.panelWidth, height: Theme.panelHeight),
            styleMask: [.borderless, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        panel.isFloatingPanel = true
        panel.level = .floating
        panel.hidesOnDeactivate = false
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = true
        panel.acceptsMouseMovedEvents = true
        panel.contentView = hosting
        panel.contentView?.wantsLayer = true
        panel.contentView?.layer?.cornerRadius = Theme.panelRadius
        panel.contentView?.layer?.masksToBounds = true

        let target = targetFrame(anchorRect: anchorRect)
        // Start a touch above the target and fully transparent so the panel
        // "drops down" from the menu bar icon.
        let start = target.offsetBy(dx: 0, dy: 24)
        panel.setFrame(start, display: false)
        panel.alphaValue = 0

        NSApp.activate(ignoringOtherApps: true)
        panel.makeKeyAndOrderFront(nil)

        NSAnimationContext.runAnimationGroup { ctx in
            ctx.duration = 0.18
            ctx.timingFunction = CAMediaTimingFunction(name: .easeOut)
            panel.animator().setFrame(target, display: true)
            panel.animator().alphaValue = 1
        }

        self.panel = panel
        installKeyMonitor()

        // Clicking another window resigns the panel's key status; treat that
        // as "user moved on" and dismiss without reactivating the previously
        // frontmost app (the click already raised whatever they clicked, so
        // re-activating would steal focus back).
        resignKeyObserver = NotificationCenter.default.addObserver(
            forName: NSWindow.didResignKeyNotification,
            object: panel,
            queue: .main
        ) { [weak self] _ in
            self?.close(restorePreviousApp: false)
        }
    }

    private func targetFrame(anchorRect: NSRect?) -> NSRect {
        let w = Theme.panelWidth, h = Theme.panelHeight
        if let anchor = anchorRect {
            // Center under the status icon; keep at least 8pt of margin from the
            // right edge of the screen.
            let screen = NSScreen.screens.first(where: { $0.frame.contains(anchor.origin) })
                ?? NSScreen.main!
            let visible = screen.visibleFrame
            var x = anchor.midX - w / 2
            x = min(max(x, visible.minX + 8), visible.maxX - w - 8)
            let y = anchor.minY - h - 4
            return NSRect(x: x, y: y, width: w, height: h)
        }
        // Fallback — screen center, biased upward (Spotlight style).
        let visible = NSScreen.main!.visibleFrame
        return NSRect(x: visible.midX - w / 2,
                      y: visible.midY - h / 2 + visible.height * 0.10,
                      width: w, height: h)
    }

    /// Closes the popup. When `restorePreviousApp` is true (default) the app
    /// that was frontmost when the popup opened is reactivated — that's what
    /// keeps the auto-paste flow intact. Set to false when the popup is being
    /// dismissed because we're handing focus to another pizzaClip surface
    /// (e.g. the Settings window), so we don't yank focus away from that.
    func close(restorePreviousApp: Bool = true) {
        uninstallKeyMonitor()
        if let o = resignKeyObserver {
            NotificationCenter.default.removeObserver(o)
            resignKeyObserver = nil
        }
        panel?.orderOut(nil)
        panel = nil
        guard restorePreviousApp else { return }
        if let id = previousFrontmostBundleID,
           let app = NSRunningApplication.runningApplications(withBundleIdentifier: id).first {
            app.activate(options: [.activateIgnoringOtherApps])
        }
    }

    func pick(_ item: Item) {
        let prev = previousFrontmostBundleID
        pasteEngine.write(item, blobStore: blobStore)
        close()
        pasteEngine.pasteIntoPreviousApp(bundleID: prev)
    }

    func delete(_ item: Item) {
        // The store posts .pizzaClipHistoryChanged, which triggers viewModel.reload()
        // — and reload() now keeps the highlight on the same item (or clamps to
        // the new range if the deleted row was the one selected).
        try? store.delete(id: item.id)
    }

    func togglePin(_ item: Item) {
        // Same story as delete — reload runs via notification and the
        // by-ID selection-restore in PopupViewModel keeps the highlight on
        // this row even after it floats above non-pinned items.
        try? store.togglePin(id: item.id)
    }

    func pasteDirect(slot: Int) {
        guard slot >= 1, slot <= 9 else { return }
        previousFrontmostBundleID = NSWorkspace.shared.frontmostApplication?.bundleIdentifier
        guard let items = try? viewModel.topNNonPinned(9),
              items.indices.contains(slot - 1) else { return }
        let item = items[slot - 1]
        pasteEngine.write(item, blobStore: blobStore)
        pasteEngine.pasteIntoPreviousApp(bundleID: previousFrontmostBundleID)
    }

    /// Paste the top-9 non-pinned items into the previous app in
    /// chronological copy order: slot 9 (oldest) first, then 8, 7, …, 1
    /// (most recent) last. Triggered by bare `0` inside the popup or by
    /// clicking the "9 → 1 full paste" row.
    func pasteAllReverse() {
        let prev = previousFrontmostBundleID
        guard let topItems = try? viewModel.topNNonPinned(9), !topItems.isEmpty else {
            close(); return
        }
        // topItems[0] is the most recent (slot 1). Reverse so the oldest of
        // the top 9 lands in the target app first.
        let sequence = Array(topItems.reversed())
        close()
        pasteEngine.pasteSequence(sequence, blobStore: blobStore, bundleID: prev)
    }

    /// Slot paste from inside an open popup — picks the Nth non-pinned row of
    /// the currently displayed list (matches the visible slot badges). Reuses
    /// the previousFrontmostBundleID recorded on open instead of re-reading
    /// frontmost (which is now ourselves).
    private func paste(slotInPopup n: Int) {
        let nonPinned = viewModel.items.filter { !$0.pinned }
        guard nonPinned.indices.contains(n - 1) else { return }
        pick(nonPinned[n - 1])
    }

    // MARK: - Keyboard handling

    private func installKeyMonitor() {
        if let existing = keyMonitor {
            NSEvent.removeMonitor(existing); self.keyMonitor = nil
        }
        keyMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard let self else { return event }
            guard self.panel?.isVisible == true else { return event }
            if self.handleKey(event) { return nil }
            return event
        }
    }

    private func uninstallKeyMonitor() {
        if let m = keyMonitor { NSEvent.removeMonitor(m); keyMonitor = nil }
    }

    private func handleKey(_ event: NSEvent) -> Bool {
        let isCmd = event.modifierFlags.contains(.command)

        switch event.keyCode {
        case 53: // esc
            close(); return true
        case 36, 76: // return / numpad enter
            if let item = viewModel.selectedItem() { pick(item) }
            return true
        case 125: // down arrow
            viewModel.moveDown(); return true
        case 126: // up arrow
            viewModel.moveUp(); return true
        case 51: // backspace
            if let item = viewModel.selectedItem() {
                delete(item); return true
            }
            return false
        default:
            // ⌘P → pin/unpin the highlighted item. Check keyCode (35 = P,
            // layout-stable for ANSI) plus chars (works for layouts that map
            // P elsewhere).
            if isCmd, (event.keyCode == 35 || event.charactersIgnoringModifiers == "p") {
                if let item = viewModel.selectedItem() {
                    togglePin(item); return true
                }
                return true   // swallow even when nothing is selected
            }
            // Bare digit (no Cmd/Opt/Ctrl/Shift):
            //   0      → paste 9 → 1 full sequence
            //   1 - 9  → paste the Nth non-pinned row of the visible list
            let interfering: NSEvent.ModifierFlags = [.command, .option, .control, .shift]
            let hasInterfering = !event.modifierFlags.intersection(interfering).isEmpty
            if !hasInterfering,
               let chars = event.charactersIgnoringModifiers, chars.count == 1,
               let digit = Int(chars) {
                if digit == 0 {
                    pasteAllReverse()
                    return true
                } else if (1...9).contains(digit) {
                    paste(slotInPopup: digit)
                    return true
                }
            }
            return false
        }
    }
}
