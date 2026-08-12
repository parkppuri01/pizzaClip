import AppKit
import ScreenCaptureKit

/// Repeatedly photographs one fixed screen rectangle while the user scrolls the
/// content underneath it.
///
/// ScreenCaptureKit rather than `screencapture`: we need many silent, shutter-free
/// grabs a second of the *same* rect, which the interactive OS tool can't do.
/// `SCScreenshotManager` is macOS 14+, which is what gates the whole feature.
@available(macOS 14.0, *)
final class ScrollFrameGrabber {
    enum GrabError: Error {
        /// The selected screen vanished from ScreenCaptureKit's display list
        /// (monitor unplugged, or the display ID couldn't be read at all).
        case displayUnavailable
    }

    /// The capture rect in **display-local, top-left-origin points**, which is what
    /// `SCStreamConfiguration.sourceRect` wants. AppKit hands us bottom-left-origin
    /// global coordinates, so both axes need translating (see `init`).
    private let sourceRect: CGRect
    private let displayID: CGDirectDisplayID
    private let pixelWidth: Int
    private let pixelHeight: Int
    /// Captured pixels per point (2 on Retina). The saved PNG needs it to record a
    /// matching DPI, so the stitched image opens at 1× like every other capture.
    let scale: CGFloat
    /// Built once on the first grab and reused: resolving shareable content costs
    /// ~100ms, and neither the display nor our own window list changes mid-session.
    private var filter: SCContentFilter?

    /// - Parameters:
    ///   - region: the capture rect in global AppKit coordinates (bottom-left origin).
    ///   - screen: the screen `region` was drawn on; supplies the display ID and
    ///     the backing scale that turns points into native pixels.
    init(region: NSRect, screen: NSScreen) {
        let frame = screen.frame
        // Global bottom-left origin → display-local top-left origin.
        sourceRect = CGRect(x: region.minX - frame.minX,
                            y: frame.maxY - region.maxY,
                            width: region.width, height: region.height)
        scale = screen.backingScaleFactor
        pixelWidth = max(1, Int((region.width * scale).rounded()))
        pixelHeight = max(1, Int((region.height * scale).rounded()))
        displayID = (screen.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? NSNumber)?
            .uint32Value ?? CGMainDisplayID()
    }

    /// One frame of the region at native pixel resolution.
    func grab() async throws -> CGImage {
        let filter = try await contentFilter()
        let config = SCStreamConfiguration()
        config.sourceRect = sourceRect
        config.width = pixelWidth
        config.height = pixelHeight
        // The pointer must not be in the frame: it moves independently of the
        // content, so Vision would try to register against it and the stitch
        // would wobble. It would also be baked into the saved image twice over.
        config.showsCursor = false
        config.captureResolution = .best
        // Downscale only. `true` scales in BOTH directions, so a region whose
        // point→pixel rounding lands a hair under `width`/`height` would be blown
        // up to fill them — resampling every frame and blurring the registration
        // for no gain. We only ever want native pixels or fewer.
        config.scalesToFit = false
        return try await SCScreenshotManager.captureImage(contentFilter: filter, configuration: config)
    }

    /// The target display with **every window PICkle owns** excluded, so the region
    /// dimmer and the control panel never land in a frame. Belt and braces: those
    /// windows also set `sharingType = .none`.
    private func contentFilter() async throws -> SCContentFilter {
        if let filter { return filter }
        let content = try await SCShareableContent.current
        guard let display = content.displays.first(where: { $0.displayID == displayID }) else {
            throw GrabError.displayUnavailable
        }
        let pid = ProcessInfo.processInfo.processIdentifier
        let ours = content.windows.filter { $0.owningApplication?.processID == pid }
        let built = SCContentFilter(display: display, excludingWindows: ours)
        filter = built
        return built
    }
}
