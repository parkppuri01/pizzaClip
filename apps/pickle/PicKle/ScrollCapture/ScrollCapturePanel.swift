import AppKit
import SwiftUI

/// A panel that must NEVER become key. The user is scrolling someone else's app;
/// if our controls stole key status that app would resign active and could scroll
/// its content back to the top (or close a viewer). The buttons still take clicks
/// while non-key, which is all we need.
final class ScrollNonKeyPanel: NSPanel {
    override var canBecomeKey: Bool { false }
    override var canBecomeMain: Bool { false }
}

/// Live text for the control panel. The stitcher pushes the running height here
/// from the main queue; SwiftUI redraws the label.
final class ScrollCapturePanelModel: ObservableObject {
    @Published var heightPixels: Int = 0
    /// Filming is over and the image is being composed and written. Flattening
    /// tens of thousands of pixels takes seconds, so the panel stays up saying so
    /// rather than vanishing and leaving the app looking hung.
    @Published var isSaving = false
    /// A browser is scrolling itself. The user has nothing to do but wait, so the
    /// panel drops the hint and the [Done] button and shows how far along it is —
    /// which is only knowable here, because the page reported its own total height.
    @Published var isAutomatic = false
    /// Share of the page captured so far, 0…100. Automatic sessions only.
    @Published var percent = 0
    /// A join just landed with no overlap. Shown in place of the hint for a moment,
    /// because the cause — scrolling faster than we can photograph — is something
    /// the user can still fix, but only while they remember doing it.
    @Published var showsSeamWarning = false
}

/// The two windows that stay on screen for the duration of a scrolling capture:
/// a full-screen dimmer with the filmed region punched out of it, and a floating
/// control panel with the live height and the [Done] / [Cancel] buttons.
///
/// Both are `sharingType = .none`, so neither shows up in the frames — the
/// grabber's content filter excludes every window PICkle owns as well, but the
/// dimmer covers the capture region's own screen, so this one really matters: a
/// 25% black wash baked into every frame would ruin the whole capture.
final class ScrollCapturePanel {
    private let model = ScrollCapturePanelModel()
    private var dimmer: NSPanel?
    private var controls: ScrollNonKeyPanel?

    private let region: NSRect
    private let screen: NSScreen
    private let onDone: () -> Void
    private let onCancel: () -> Void

    /// Width of the region outline, in points, drawn just outside the region.
    private static let borderWidth: CGFloat = 2
    /// Gap between the region and the control panel.
    private static let panelGap: CGFloat = 12
    /// How long a seam warning stays up. Long enough to read mid-scroll, short
    /// enough that it isn't still there when the next stretch goes fine.
    private static let seamWarningDuration: TimeInterval = 2.5

    private var seamReset: DispatchWorkItem?

    init(region: NSRect, screen: NSScreen,
         onDone: @escaping () -> Void, onCancel: @escaping () -> Void) {
        self.region = region
        self.screen = screen
        self.onDone = onDone
        self.onCancel = onCancel
    }

    /// Show the dimmer + controls. The initial height reads as the region's own
    /// pixel height, which is what a zero-scroll session would save.
    ///
    /// - Parameter automatic: a browser is driving itself; show progress and only
    ///   the way out, instead of the live height and [Done].
    func show(automatic: Bool = false) {
        model.heightPixels = Int((region.height * screen.backingScaleFactor).rounded())
        model.isAutomatic = automatic
        showDimmer()
        showControls()
    }

    /// Update the live "so far" height. Main queue only.
    func updateHeight(_ pixels: Int) {
        model.heightPixels = pixels
    }

    /// Update the automatic session's progress, 0…100. Main queue only.
    func updatePercent(_ percent: Int) {
        model.percent = percent
    }

    /// Say a seam just happened, then go quiet again. Each new seam restarts the
    /// clock rather than queueing, so a burst during one fast flick reads as a
    /// single steady warning instead of a flicker.
    func flashSeamWarning() {
        seamReset?.cancel()
        model.showsSeamWarning = true
        let reset = DispatchWorkItem { [weak self] in self?.model.showsSeamWarning = false }
        seamReset = reset
        DispatchQueue.main.asyncAfter(deadline: .now() + Self.seamWarningDuration, execute: reset)
    }

    /// Filming stopped: undim the screen (nothing is being watched any more) but
    /// keep the controls up, switched to "saving" with the buttons off, until the
    /// PNG has actually landed.
    func beginSaving() {
        dimmer?.orderOut(nil); dimmer = nil
        model.isSaving = true
    }

    func dismiss() {
        seamReset?.cancel(); seamReset = nil
        dimmer?.orderOut(nil); dimmer = nil
        controls?.orderOut(nil); controls = nil
    }

    // MARK: - Dimmer

    /// One window covering the capture region's screen: everything outside the
    /// region is washed 25% black, the region itself is punched fully transparent,
    /// and the hole is outlined in green. Only this screen is dimmed — other
    /// monitors stay untouched, which keeps the session to a single extra window.
    private func showDimmer() {
        let frame = screen.frame
        let panel = NSPanel(contentRect: frame,
                            styleMask: [.borderless, .nonactivatingPanel],
                            backing: .buffered, defer: false)
        panel.isFloatingPanel = true
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = false
        // NSPanel hides itself when the app deactivates by default — and PICkle
        // deactivates the instant the user clicks the window they want to scroll,
        // which is every single session. Without this the dimmer blinks out at
        // exactly the moment it becomes useful.
        panel.hidesOnDeactivate = false
        // Above the shield so it clears full-screen apps, but below the controls.
        panel.level = NSWindow.Level(rawValue: Int(CGShieldingWindowLevel()))
        panel.sharingType = .none
        // Every click and every scroll wheel event has to reach the app underneath —
        // the whole feature is the user scrolling *through* this window.
        panel.ignoresMouseEvents = true
        panel.collectionBehavior = [.canJoinAllSpaces, .stationary, .fullScreenAuxiliary, .ignoresCycle]
        // Global region rect → this window's own coordinate space.
        let hole = NSRect(x: region.minX - frame.minX, y: region.minY - frame.minY,
                          width: region.width, height: region.height)
        panel.contentView = ScrollRegionDimView(
            frame: NSRect(origin: .zero, size: frame.size),
            hole: hole, lineWidth: Self.borderWidth)
        panel.orderFrontRegardless()
        dimmer = panel
    }

    // MARK: - Controls

    private func showControls() {
        let hosting = NSHostingView(rootView: ScrollCaptureControls(
            model: model, onDone: onDone, onCancel: onCancel))
        hosting.layout()
        let size = hosting.fittingSize

        let panel = ScrollNonKeyPanel(contentRect: NSRect(origin: .zero, size: size),
                                      styleMask: [.borderless, .fullSizeContentView, .nonactivatingPanel],
                                      backing: .buffered, defer: false)
        panel.isFloatingPanel = true
        panel.level = NSWindow.Level(rawValue: Int(CGShieldingWindowLevel()) + 1)   // above the dimmer
        panel.hidesOnDeactivate = false
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = true
        panel.sharingType = .none
        panel.collectionBehavior = [.canJoinAllSpaces, .stationary, .fullScreenAuxiliary, .ignoresCycle]
        panel.contentView = hosting
        panel.contentView?.wantsLayer = true
        panel.contentView?.layer?.cornerRadius = Theme.panelRadius
        panel.contentView?.layer?.masksToBounds = true
        panel.setFrame(controlsFrame(size: size), display: false)
        panel.orderFrontRegardless()
        controls = panel
    }

    /// Park the controls outside the region — below it by preference, above if
    /// there's no room — and keep the whole panel inside the visible screen so it
    /// never hides under the menu bar or the Dock.
    private func controlsFrame(size: CGSize) -> NSRect {
        let visible = screen.visibleFrame
        let gap = Self.panelGap + Self.borderWidth
        var y = region.minY - gap - size.height
        if y < visible.minY { y = region.maxY + gap }
        y = min(max(y, visible.minY + 8), visible.maxY - size.height - 8)
        var x = region.midX - size.width / 2
        x = min(max(x, visible.minX + 8), visible.maxX - size.width - 8)
        return NSRect(x: x, y: y, width: size.width, height: size.height)
    }
}

/// Dims the screen everywhere except the region being filmed, and outlines the
/// hole in green so the capture area is unmistakable.
private final class ScrollRegionDimView: NSView {
    private let hole: NSRect
    private let lineWidth: CGFloat

    init(frame: NSRect, hole: NSRect, lineWidth: CGFloat) {
        self.hole = hole
        self.lineWidth = lineWidth
        super.init(frame: frame)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func draw(_ dirtyRect: NSRect) {
        // Even-odd winding turns "whole view" + "region" into "whole view MINUS
        // region", so the wash lands everywhere but the capture area, which stays
        // fully transparent — the user watches the real content as they scroll it.
        let wash = NSBezierPath(rect: bounds)
        wash.appendRect(hole)
        wash.windingRule = .evenOdd
        NSColor.black.withAlphaComponent(0.25).setFill()
        wash.fill()
        // Outline drawn entirely OUTSIDE the hole: the path sits 1pt out and the
        // 2pt stroke straddles it, so it reaches the region's edge without ever
        // tinting a pixel inside it.
        let outline = NSBezierPath(rect: hole.insetBy(dx: -lineWidth / 2, dy: -lineWidth / 2))
        outline.lineWidth = lineWidth
        ScrollCaptureStyle.outline.setStroke()
        outline.stroke()
    }
}

/// Contents of the floating control panel.
private struct ScrollCaptureControls: View {
    @ObservedObject var model: ScrollCapturePanelModel
    @ObservedObject private var loc = LocalizationManager.shared
    let onDone: () -> Void
    let onCancel: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: model.isAutomatic ? "arrow.down.circle" : "arrow.down.doc")
                    .foregroundStyle(AppColors.accent)
                Text(model.isAutomatic ? L("scroll.panel.auto.title") : L("scroll.panel.title"))
                    .font(.system(size: 13, weight: .semibold))
                Spacer(minLength: 16)
                Text(model.isAutomatic
                     ? String(format: L("scroll.panel.auto.progress"), model.percent)
                     : String(format: L("scroll.panel.height"), model.heightPixels))
                    .font(.system(size: 12, weight: .medium).monospacedDigit())
                    .foregroundStyle(AppColors.accent)
            }
            if model.isSaving {
                HStack(spacing: 6) {
                    ProgressView().controlSize(.small)
                    Text(L("scroll.panel.saving"))
                        .font(.caption)
                        .foregroundStyle(AppColors.secondaryLabel)
                }
            } else if model.showsSeamWarning {
                HStack(spacing: 6) {
                    Image(systemName: "exclamationmark.triangle.fill")
                    Text(L("scroll.panel.seam"))
                }
                .font(.caption)
                .foregroundStyle(.orange)
            } else {
                Text(model.isAutomatic ? L("scroll.panel.auto.hint") : L("scroll.panel.hint"))
                    .font(.caption)
                    .foregroundStyle(AppColors.secondaryLabel)
            }
            HStack(spacing: 8) {
                Spacer()
                Button(L("scroll.panel.cancel"), action: onCancel)
                    .disabled(model.isSaving)
                // No [Done] while a browser drives itself: there is nothing to end
                // early that the page won't reach on its own in a moment.
                if !model.isAutomatic {
                    // Prominent, but deliberately NOT `.defaultAction`: this panel can
                    // never become key, so a Return shortcut would be a lie.
                    Button(L("scroll.panel.done"), action: onDone)
                        .buttonStyle(.borderedProminent)
                        .tint(AppColors.accent)
                        .disabled(model.isSaving)
                }
            }
        }
        .padding(14)
        .frame(width: 290)
        .background(.regularMaterial)
        .id(loc.language)
    }
}
