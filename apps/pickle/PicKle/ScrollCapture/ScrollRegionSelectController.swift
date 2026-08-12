import AppKit

/// A borderless, transparent **non-activating** panel that can become key (so it
/// receives the mouse drag and Esc) WITHOUT the app having to become active.
/// Accessory (LSUIElement) apps can't reliably activate themselves over another
/// app, so a plain NSWindow never gets the drag; a `.nonactivatingPanel` does.
final class ScrollSelectionWindow: NSPanel {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { true }
}

/// The selection layer for scrolling capture: drag to draw the rectangle that
/// will be filmed while the user scrolls. Reports the chosen rect (in this
/// view's coordinates) on mouse-up, or cancels on Esc / a too-small drag.
///
/// Deliberately simpler than a one-shot region capture: no frozen backdrop, since
/// the region has to stay live so the user can see what they're about to scroll.
final class ScrollSelectionView: NSView {
    var onCommit: ((NSRect) -> Void)?
    var onCancel: (() -> Void)?

    private var startPoint: NSPoint?
    private var selection: NSRect = .zero
    /// Last cursor position, used to place the live dimension badge.
    private var lastDragPoint: NSPoint?

    /// Where to draw the "+" crosshair, in THIS view's coords. nil = the mouse
    /// isn't over this overlay's screen, so we draw nothing. The controller pushes
    /// the live mouse location here every tick (see `updateCrosshair`) because we
    /// can't rely on the system cursor: macOS only lets the *active* app change the
    /// pointer, and PICkle deliberately never activates.
    private var crosshairPoint: NSPoint?

    /// Position the drawn crosshair from a global (screen) mouse location. Each
    /// per-screen overlay keeps it only while the mouse is actually over its screen,
    /// so the "+" never lingers on a monitor the cursor has left.
    func updateCrosshair(global: NSPoint) {
        guard let win = window, win.frame.contains(global) else {
            if crosshairPoint != nil { crosshairPoint = nil; needsDisplay = true }
            return
        }
        let p = convert(win.convertPoint(fromScreen: global), from: nil)
        if crosshairPoint != p { crosshairPoint = p; needsDisplay = true }
    }

    override var acceptsFirstResponder: Bool { true }
    override func acceptsFirstMouse(for event: NSEvent?) -> Bool { true }
    override var isFlipped: Bool { false }

    override func mouseDown(with event: NSEvent) {
        let p = convert(event.locationInWindow, from: nil)
        startPoint = p
        lastDragPoint = p
        selection = NSRect(origin: p, size: .zero)
        needsDisplay = true
    }

    override func mouseDragged(with event: NSEvent) {
        guard let s = startPoint else { return }
        var p = convert(event.locationInWindow, from: nil)
        // Clamp to this screen's bounds: AppKit keeps delivering the drag to the
        // window that received mouseDown even after the cursor crosses onto another
        // monitor, which would push the selection off-screen and capture black.
        p.x = min(max(p.x, 0), bounds.width)
        p.y = min(max(p.y, 0), bounds.height)
        selection = NSRect(x: min(s.x, p.x), y: min(s.y, p.y),
                           width: abs(p.x - s.x), height: abs(p.y - s.y))
        lastDragPoint = p
        needsDisplay = true
    }

    override func mouseUp(with event: NSEvent) {
        let r = selection
        startPoint = nil
        lastDragPoint = nil
        selection = .zero
        needsDisplay = true
        // A click with no drag (or a stray micro-drag) reads as "never mind".
        if r.width >= 1, r.height >= 1 { onCommit?(r) } else { onCancel?() }
    }

    override func draw(_ dirtyRect: NSRect) {
        // Near-invisible fill (1% black) so the overlay still RECEIVES the mouse drag.
        // A fully transparent window lets clicks pass THROUGH to the app underneath,
        // so the drag never builds a selection (it looked like the capture "let go").
        // Visually the screen still looks unchanged, like ⌘⇧4 — no dim, no freeze.
        NSColor.black.withAlphaComponent(0.01).setFill()
        bounds.fill()
        if selection.width > 0, selection.height > 0 {
            // Pickle-green outline around the selection. A thin dark underlay keeps it
            // visible over any background (no dimming to provide contrast here).
            NSColor.black.withAlphaComponent(0.55).setStroke()
            let under = NSBezierPath(rect: selection); under.lineWidth = 3; under.stroke()
            ScrollCaptureStyle.outline.setStroke()
            let path = NSBezierPath(rect: selection); path.lineWidth = 1.5; path.stroke()
            // Live pixel dimensions near the cursor (×backing scale = real pixels, Retina ×2).
            if let cursor = lastDragPoint {
                let scale = window?.backingScaleFactor ?? 2
                let wpx = Int((selection.width * scale).rounded())
                let hpx = Int((selection.height * scale).rounded())
                drawDimensionBadge("\(wpx) × \(hpx)", near: cursor)
            }
        }
        // The "+" at the mouse, drawn ON TOP of whatever pointer the system shows.
        if let c = crosshairPoint { drawCrosshair(at: c) }
    }

    /// A small ⇧⌘4-style "+" crosshair centred on the mouse, with a tiny gap at the
    /// centre so the exact target point stays visible. A dark underlay keeps it
    /// legible on any background; the arms are pickle-green to match the selection
    /// outline. Centred on the mouse location = the system arrow's tip, so the two
    /// sit together (the arrow we can't hide, the crosshair we always can show).
    private func drawCrosshair(at p: NSPoint) {
        let arm: CGFloat = 11      // length of each arm out from the centre
        let gap: CGFloat = 3       // empty gap at the centre so the exact point shows
        func strokeArms(_ color: NSColor, _ width: CGFloat) {
            color.setStroke()
            let path = NSBezierPath()
            path.lineWidth = width
            path.move(to: NSPoint(x: p.x - arm, y: p.y)); path.line(to: NSPoint(x: p.x - gap, y: p.y))
            path.move(to: NSPoint(x: p.x + gap, y: p.y)); path.line(to: NSPoint(x: p.x + arm, y: p.y))
            path.move(to: NSPoint(x: p.x, y: p.y - arm)); path.line(to: NSPoint(x: p.x, y: p.y - gap))
            path.move(to: NSPoint(x: p.x, y: p.y + gap)); path.line(to: NSPoint(x: p.x, y: p.y + arm))
            path.stroke()
        }
        strokeArms(NSColor.black.withAlphaComponent(0.6), 3)   // dark underlay
        strokeArms(ScrollCaptureStyle.outline, 1.5)            // pickle-green
    }

    /// A small rounded "W × H" badge near the cursor. Clamped to the view so it
    /// never spills off the screen edge while dragging.
    private func drawDimensionBadge(_ text: String, near point: NSPoint) {
        let font = NSFont.monospacedDigitSystemFont(ofSize: 12, weight: .semibold)
        let attrs: [NSAttributedString.Key: Any] = [.font: font, .foregroundColor: NSColor.white]
        let str = NSAttributedString(string: text, attributes: attrs)
        let textSize = str.size()
        let padX: CGFloat = 8, padY: CGFloat = 4
        let boxW = textSize.width + padX * 2, boxH = textSize.height + padY * 2
        // Sit just below-right of the cursor (view is bottom-left origin).
        var x = point.x + 14
        var y = point.y - boxH - 14
        x = min(max(x, 4), bounds.width - boxW - 4)
        y = min(max(y, 4), bounds.height - boxH - 4)
        let box = NSRect(x: x, y: y, width: boxW, height: boxH)
        NSColor.black.withAlphaComponent(0.75).setFill()
        NSBezierPath(roundedRect: box, xRadius: 5, yRadius: 5).fill()
        str.draw(at: NSPoint(x: x + padX, y: y + padY))
    }
}

/// Drives the region drag that opens a scrolling-capture session. One overlay
/// window **per screen** (a single union-frame window only ever renders on one
/// monitor, so the main display couldn't be selected at all); the drag decides
/// which screen wins, and that screen is handed back with the rect because the
/// grabber needs its display ID and backing scale.
final class ScrollRegionSelectController {
    private var overlays: [ScrollSelectionWindow] = []
    private var keyMonitor: Any?
    private var minimumSide: CGFloat = 0
    /// Drives the drawn "+" crosshair. See `startCrosshairTracking`.
    private var crosshairTimer: Timer?

    private var onSelect: ((NSRect, NSScreen) -> Void)?
    private var onCancel: (() -> Void)?

    var isActive: Bool { !overlays.isEmpty }

    /// Put an overlay on every screen and wait for a drag. `onSelect` gets the
    /// rect in global (bottom-left origin) Cocoa coordinates plus the screen it
    /// was drawn on; drags shorter than `minimumSide` on either axis cancel.
    func begin(minimumSide: CGFloat,
               onSelect: @escaping (NSRect, NSScreen) -> Void,
               onCancel: @escaping () -> Void) {
        guard overlays.isEmpty else { return }
        self.minimumSide = minimumSide
        self.onSelect = onSelect
        self.onCancel = onCancel

        let shield = Int(CGShieldingWindowLevel())
        for screen in NSScreen.screens {
            let win = ScrollSelectionWindow(contentRect: screen.frame,
                                            styleMask: [.borderless, .nonactivatingPanel],
                                            backing: .buffered, defer: false)
            win.isFloatingPanel = true
            win.isOpaque = false
            win.backgroundColor = .clear
            win.hasShadow = false
            // NSPanel auto-hides on app deactivation; the overlay must survive it,
            // since PICkle is never the active app while a selection is up.
            win.hidesOnDeactivate = false
            win.level = NSWindow.Level(rawValue: shield)
            win.sharingType = .none          // keep the overlay out of the capture
            win.collectionBehavior = [.canJoinAllSpaces, .stationary, .fullScreenAuxiliary, .ignoresCycle]

            let view = ScrollSelectionView(frame: NSRect(origin: .zero, size: screen.frame.size))
            view.onCommit = { [weak self] rectInView in
                self?.commit(rectInView: rectInView, screen: screen)
            }
            view.onCancel = { [weak self] in self?.cancel() }
            win.contentView = view
            win.orderFrontRegardless()
            overlays.append(win)
        }
        // Make the overlay key so keyDown (Esc) routes into our local monitor. A
        // `.nonactivatingPanel` can become key WITHOUT activating the app — and we
        // deliberately do NOT call NSApp.activate here: activating PICkle would
        // deactivate the frontmost app, and some apps (e.g. Telegram) close their
        // full-screen photo viewer the instant they resign active. The mouse drag
        // works regardless via acceptsFirstMouse.
        if let key = overlays.first {
            key.makeKeyAndOrderFront(nil)
            if let v = key.contentView { key.makeFirstResponder(v) }
        }
        installKeyMonitor()
        startCrosshairTracking()
    }

    /// Tear the overlays down without firing either callback. Safe to call more
    /// than once, so the coordinator can clean up regardless of who ended the drag.
    func dismiss() {
        if let m = keyMonitor { NSEvent.removeMonitor(m); keyMonitor = nil }
        crosshairTimer?.invalidate(); crosshairTimer = nil
        for win in overlays { win.orderOut(nil) }
        overlays.removeAll()
        onSelect = nil
        onCancel = nil
    }

    // MARK: - Outcomes

    private func commit(rectInView: NSRect, screen: NSScreen) {
        guard !overlays.isEmpty else { return }
        // View coords (origin = this screen's bottom-left) → global Cocoa coords.
        let global = NSRect(x: rectInView.minX + screen.frame.minX,
                            y: rectInView.minY + screen.frame.minY,
                            width: rectInView.width, height: rectInView.height)
        guard global.width >= minimumSide, global.height >= minimumSide else { cancel(); return }
        let cb = onSelect
        dismiss()
        // Let the compositor drop the overlay before the caller starts filming.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.06) { cb?(global, screen) }
    }

    private func cancel() {
        guard !overlays.isEmpty else { return }
        let cb = onCancel
        dismiss()
        cb?()
    }

    // MARK: - Keyboard

    private func installKeyMonitor() {
        keyMonitor = NSEvent.addLocalMonitorForEvents(matching: [.keyDown]) { [weak self] event in
            guard let self, !self.overlays.isEmpty else { return event }
            if event.keyCode == 53 { self.cancel(); return nil }   // Esc
            return event
        }
    }

    // MARK: - Crosshair

    /// Keep the drawn "+" glued to the mouse. We poll the global mouse location at
    /// 60fps rather than relying on `mouseMoved`: an inactive app's overlay doesn't
    /// reliably receive mouseMoved, but reading `NSEvent.mouseLocation` always
    /// works, on every screen, even mid-drag. The overlay whose screen the mouse is
    /// on draws the "+"; the others clear theirs.
    ///
    /// We draw it ourselves because `NSCursor` / cursor rects only take effect while
    /// the app is *active*, and PICkle deliberately never activates (activating
    /// closes other apps' full-screen viewers — the 1.2.0 lesson). The system arrow
    /// stays visible alongside it; that's the accepted trade-off.
    private func startCrosshairTracking() {
        pushCrosshair()
        let t = Timer(timeInterval: 1.0 / 60.0, repeats: true) { [weak self] _ in self?.pushCrosshair() }
        RunLoop.current.add(t, forMode: .common)   // .common so it ticks during the drag too
        crosshairTimer = t
    }

    private func pushCrosshair() {
        let mouse = NSEvent.mouseLocation
        for win in overlays {
            (win.contentView as? ScrollSelectionView)?.updateCrosshair(global: mouse)
        }
    }
}

/// Shared chrome for the scrolling-capture overlays, so the selection outline and
/// the live region outline are provably the same green.
enum ScrollCaptureStyle {
    /// Pickle green, matching `AppColors.accent`'s light-mode value. Drawn with
    /// AppKit (not SwiftUI) over arbitrary desktop content, so it stays fixed
    /// rather than adapting to our own window's appearance.
    static let outline = NSColor(srgbRed: 0.43, green: 0.68, blue: 0.31, alpha: 1)
}
