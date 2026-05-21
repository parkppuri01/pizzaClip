import AppKit
import SwiftUI

final class PopupPanelController {
    private var panel: NSPanel?
    private var hostingView: NSHostingView<PopupView>?
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

    deinit {
        uninstallKeyMonitor()
    }

    func toggle() {
        if let panel = panel, panel.isVisible { close(); return }
        show()
    }

    func show() {
        previousFrontmostBundleID = NSWorkspace.shared.frontmostApplication?.bundleIdentifier
        viewModel.query = ""
        viewModel.reload()

        let view = PopupView(
            vm: viewModel,
            onPick: { [weak self] item in self?.pick(item) },
            onClose: { [weak self] in self?.close() },
            onDelete: { [weak self] item in self?.delete(item) },
            onTogglePin: { [weak self] item in self?.togglePin(item) }
        )
        let hosting = NSHostingView(rootView: view)
        self.hostingView = hosting

        let panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: Theme.panelWidth, height: Theme.panelHeight),
            styleMask: [.borderless, .nonactivatingPanel, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        panel.isFloatingPanel = true
        panel.level = .floating
        panel.becomesKeyOnlyIfNeeded = true
        panel.hidesOnDeactivate = false
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = true
        panel.contentView = hosting

        if let screen = NSScreen.main {
            let rect = screen.visibleFrame
            let origin = NSPoint(x: rect.midX - Theme.panelWidth / 2,
                                 y: rect.midY - Theme.panelHeight / 2 + rect.height * 0.10)
            panel.setFrameOrigin(origin)
        }
        panel.orderFrontRegardless()
        panel.makeKey()

        self.panel = panel

        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.contentView?.wantsLayer = true
        panel.contentView?.layer?.cornerRadius = Theme.panelRadius
        panel.contentView?.layer?.masksToBounds = true
        installKeyMonitor()
    }

    func close() {
        uninstallKeyMonitor()
        panel?.orderOut(nil)
        panel = nil
        hostingView = nil
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
    }

    func pasteDirect(slot: Int) {
        previousFrontmostBundleID = NSWorkspace.shared.frontmostApplication?.bundleIdentifier
        guard let items = try? viewModel.topNNonPinned(slot) else { return }
        guard slot >= 1, slot <= items.count else { return }
        let item = items[slot - 1]
        pasteEngine.write(item, blobStore: blobStore)
        pasteEngine.pasteIntoPreviousApp(bundleID: previousFrontmostBundleID)
    }

    // MARK: - Keyboard handling

    private func installKeyMonitor() {
        if let existing = keyMonitor {
            NSEvent.removeMonitor(existing); self.keyMonitor = nil
        }
        keyMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard let self else { return event }
            guard self.panel?.isVisible == true else { return event }
            if self.handleKey(event) { return nil }   // swallow
            return event
        }
    }

    private func uninstallKeyMonitor() {
        if let m = keyMonitor { NSEvent.removeMonitor(m); keyMonitor = nil }
    }

    private func handleKey(_ event: NSEvent) -> Bool {
        // Don't intercept while typing arrows/return inside the search field when there
        // are zero rows. Otherwise we route arrows / return / delete-on-empty / pin / esc
        // to the popup actions; the TextField still gets every other character.
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
            // Only repurpose backspace when the search field is empty — otherwise the
            // user is editing the query and expects normal character deletion.
            if queryIsEmpty, let item = viewModel.selectedItem() {
                delete(item); return true
            }
            return false
        default:
            if isCmd, event.charactersIgnoringModifiers == "p",
               let item = viewModel.selectedItem() {
                togglePin(item); return true
            }
            return false
        }
    }
}
