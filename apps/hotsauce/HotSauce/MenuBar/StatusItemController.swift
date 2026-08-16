import AppKit
import SwiftUI

/// 메뉴바 병 아이콘 + 좌클릭 팝업 / 우클릭 컨텍스트 메뉴.
final class StatusItemController: NSObject {
    private let statusItem: NSStatusItem
    private let engine: MetricsEngine
    private var panel: FocusablePanel?
    private let contextMenu = NSMenu()

    var onOpenSettings: (() -> Void)?
    #if !MAS
    /// 직접 배포(Sparkle) 전용. 앱스토어 빌드는 App Store 가 업데이트를 담당한다.
    var onCheckForUpdates: (() -> Void)?
    #endif

    init(engine: MetricsEngine) {
        self.engine = engine
        self.statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        super.init()

        if let button = statusItem.button {
            button.image = Self.bottleImage(for: .good)
            button.target = self
            button.action = #selector(statusItemClicked)
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        }

        buildContextMenu()

        engine.onStateChange = { [weak self] state in
            DispatchQueue.main.async {
                self?.statusItem.button?.image = Self.bottleImage(for: state)
            }
        }

        // 팝업이 떠 있는 채로(잠금 등) 설정에서 배너 토글을 바꾸면 즉시 크기를 맞춘다.
        // (닫혀 있을 때는 showPopup 이 열 때마다 최신 크기로 맞추므로 이걸로 충분)
        NotificationCenter.default.addObserver(
            self, selector: #selector(defaultsDidChange),
            name: UserDefaults.didChangeNotification, object: nil)
    }

    @objc private func defaultsDidChange() {
        DispatchQueue.main.async { [weak self] in
            guard let self, let panel = self.panel,
                  panel.isVisible, panel.frame.size != DS.popupSize else { return }
            panel.setContentSize(DS.popupSize)
            self.positionPanel(panel)
        }
    }

    /// 72px 병 PNG → 메뉴바 크기(18pt)로.
    private static func bottleImage(for state: LoadState) -> NSImage {
        let image = Assets.image(state.bottleAssetName)
        let copy = image.copy() as! NSImage
        copy.size = NSSize(width: 18, height: 18)
        copy.isTemplate = false  // 컬러 아이콘 유지
        return copy
    }

    // MARK: - 클릭 분기

    @objc private func statusItemClicked() {
        guard let event = NSApp.currentEvent else { return }
        if event.type == .rightMouseUp {
            showContextMenu()
        } else {
            togglePopup()
        }
    }

    private func showContextMenu() {
        statusItem.menu = contextMenu
        statusItem.button?.performClick(nil)
        statusItem.menu = nil  // 좌클릭이 다시 팝업으로 가도록 즉시 해제
    }

    private func buildContextMenu() {
        let settingsItem = NSMenuItem(
            title: L("Settings…", "설정…"),
            action: #selector(openSettingsClicked), keyEquivalent: ",")
        settingsItem.target = self
        contextMenu.addItem(settingsItem)

        #if !MAS
        let updateItem = NSMenuItem(
            title: L("Check for Updates…", "업데이트 확인…"),
            action: #selector(checkForUpdatesClicked), keyEquivalent: "")
        updateItem.target = self
        contextMenu.addItem(updateItem)
        #endif

        contextMenu.addItem(.separator())

        let quitItem = NSMenuItem(
            title: L("Quit HotSauce", "HotSauce 종료"),
            action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        contextMenu.addItem(quitItem)
    }

    @objc private func openSettingsClicked() { onOpenSettings?() }
    #if !MAS
    @objc private func checkForUpdatesClicked() { onCheckForUpdates?() }
    #endif

    // MARK: - 팝업

    func togglePopup() {
        if let panel, panel.isVisible {
            panel.orderOut(nil)
            engine.isPopupVisible = false
            return
        }
        showPopup()
    }

    private func showPopup() {
        let panel = self.panel ?? makePanel()
        self.panel = panel

        // 배너 토글로 팝업 높이가 달라질 수 있어 열 때마다 최신 크기로 맞춘다.
        panel.setContentSize(DS.popupSize)

        engine.isPopupVisible = true
        positionPanel(panel)
        panel.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        engine.replayBurstIfOverloaded()   // 위험 상태에서 팝업을 열면 폭발 재생
    }

    private func makePanel() -> FocusablePanel {
        var panelRef: FocusablePanel?
        let content = PopupView(
            engine: engine,
            onOpenSettings: { [weak self] in
                self?.panel?.orderOut(nil)
                self?.engine.isPopupVisible = false
                self?.onOpenSettings?()
            },
            onLockChanged: { locked in panelRef?.isLocked = locked })
        let hosting = NSHostingView(rootView: content)
        hosting.frame = NSRect(origin: .zero, size: DS.popupSize)

        let panel = FocusablePanel(
            contentRect: NSRect(origin: .zero, size: DS.popupSize),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false)
        panel.contentView = hosting
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = true
        panel.level = .statusBar
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        panel.isReleasedWhenClosed = false
        panel.onClose = { [weak self] in
            self?.engine.isPopupVisible = false
        }
        panelRef = panel   // PopupView 자물쇠 토글이 이 패널의 isLocked 를 제어
        return panel
    }

    private func positionPanel(_ panel: FocusablePanel) {
        guard let button = statusItem.button, let buttonWindow = button.window else { return }
        let buttonFrame = buttonWindow.frame
        var x = buttonFrame.midX - DS.popupSize.width / 2
        let y = buttonFrame.minY - DS.popupSize.height - 6

        if let screen = buttonWindow.screen {
            let visible = screen.visibleFrame
            x = min(max(x, visible.minX + 8), visible.maxX - DS.popupSize.width - 8)
        }
        panel.setFrameOrigin(NSPoint(x: x, y: y))
    }
}
