import AppKit
import SwiftUI

final class PopupPanelController {
    private var panel: NSPanel?
    private var hostingView: NSHostingView<PopupView>?
    private var previousFrontmostBundleID: String?
    private let viewModel: PopupViewModel
    private let pasteEngine: PasteEngine
    private let blobStore: BlobStore?

    init(viewModel: PopupViewModel, pasteEngine: PasteEngine, blobStore: BlobStore?) {
        self.viewModel = viewModel
        self.pasteEngine = pasteEngine
        self.blobStore = blobStore
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
            onClose: { [weak self] in self?.close() }
        )
        let hosting = NSHostingView(rootView: view)
        self.hostingView = hosting

        let panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 440, height: 480),
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
            let origin = NSPoint(x: rect.midX - 220,
                                 y: rect.midY - 240 + rect.height * 0.10)
            panel.setFrameOrigin(origin)
        }
        panel.orderFrontRegardless()
        panel.makeKey()

        self.panel = panel
    }

    func close() {
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

    func pasteDirect(slot: Int) {
        previousFrontmostBundleID = NSWorkspace.shared.frontmostApplication?.bundleIdentifier
        guard let items = try? viewModel.topNNonPinned(slot) else { return }
        guard slot >= 1, slot <= items.count else { return }
        let item = items[slot - 1]
        pasteEngine.write(item, blobStore: blobStore)
        pasteEngine.pasteIntoPreviousApp(bundleID: previousFrontmostBundleID)
    }
}
