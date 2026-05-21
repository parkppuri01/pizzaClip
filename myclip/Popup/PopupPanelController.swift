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

    init(store: HistoryStore, viewModel: PopupViewModel, pasteEngine: PasteEngine, blobStore: BlobStore?) {
        self.store = store
        self.viewModel = viewModel
        self.pasteEngine = pasteEngine
        self.blobStore = blobStore
    }

    deinit { uninstallKeyMonitor() }

    func toggle(anchorRect: NSRect? = nil) {
        if let panel = panel, panel.isVisible { close(); return }
        show(anchorRect: anchorRect)
    }

    func show(anchorRect: NSRect? = nil) {
        previousFrontmostBundleID = NSWorkspace.shared.frontmostApplication?.bundleIdentifier
        viewModel.query = ""
        viewModel.reload()

        let view = PopupView(
            vm: viewModel,
            onPick: { [weak self] item in self?.pick(item) },
            onClose: { [weak self] in self?.close() }
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

    func close() {
        uninstallKeyMonitor()
        panel?.orderOut(nil)
        panel = nil
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
        try? store.delete(id: item.id)
        viewModel.reload()
    }

    func togglePin(_ item: Item) {
        try? store.togglePin(id: item.id)
        viewModel.reload()
        // Keep the highlight on the same item — its row position changed since
        // pinned items float to the top of `topNRespectingPins`.
        if let newIdx = viewModel.items.firstIndex(where: { $0.id == item.id }) {
            viewModel.selectedIndex = newIdx
        }
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
        let queryIsEmpty = viewModel.query.isEmpty
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
            if queryIsEmpty, let item = viewModel.selectedItem() {
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
            // Bare digit 1-9 (no Cmd/Opt/Ctrl/Shift, empty query) → paste the
            // Nth non-pinned row of the currently displayed list and close.
            // While the user is searching, digits flow into the field as
            // characters so queries that start with a number still work.
            let interfering: NSEvent.ModifierFlags = [.command, .option, .control, .shift]
            let hasInterfering = !event.modifierFlags.intersection(interfering).isEmpty
            if queryIsEmpty, !hasInterfering,
               let chars = event.charactersIgnoringModifiers, chars.count == 1,
               let digit = Int(chars), digit >= 1, digit <= 9 {
                paste(slotInPopup: digit)
                return true
            }
            return false
        }
    }
}
