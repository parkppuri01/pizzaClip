import AppKit

/// Drives a browser through a page and photographs it, one screenful at a time.
///
/// The user does nothing after picking the region: the page is scrolled to the top,
/// stepped down by a fixed amount, and each stop is captured once the pixels stop
/// changing. Because the page reports its own offset, the tiles are assembled by
/// coordinate (`TileComposer`) instead of being matched against each other — the
/// single Vision call in here exists only to learn the pixels-per-CSS-pixel ratio,
/// which browser zoom makes unknowable any other way.
@available(macOS 14.0, *)
final class BrowserScrollSession {

    enum Outcome {
        case image(CGImage)
        /// The user pressed [Cancel]; the page has been scrolled back.
        case cancelled
        /// Nothing was captured because automation or JavaScript-over-Apple-Events
        /// is switched off. The caller offers onboarding + the manual fallback.
        case setupRequired(BrowserScrollDriver.DriverError)
        /// Something else went wrong before there was enough to save.
        case failed
    }

    /// Gap between the two grabs of a settle comparison.
    private static let settleInterval: TimeInterval = 0.12
    /// How long a single stop may spend waiting for the page to stop repainting.
    /// A page with a permanently animating element never settles, so this is a
    /// ceiling, not an expectation: when it expires the newest grab is used.
    private static let settleLimit: TimeInterval = 1.0
    /// Runaway guard, independent of the pixel ceiling: a page whose reported offset
    /// creeps forward by a few pixels per step would otherwise scroll forever.
    private static let maxTiles = 400
    /// Memory the captured tiles may occupy before the session stops early and saves
    /// what it has. The tile *count* is not a budget — a Retina region the height of
    /// a laptop screen is ~20MB, so 400 of them is several gigabytes — and this is
    /// the guard that actually binds. Generous enough that a normal long page never
    /// meets it; small enough that PICkle can't be the reason a Mac starts swapping.
    private static let maxCapturedBytes = 1_500_000_000
    /// Smallest step we will take, in CSS pixels. A region shorter than its own
    /// sticky-header pad would otherwise produce a zero or negative step.
    private static let minimumStep: Double = 40
    /// Slack the driver adds on top of the measured pinned chrome when it reports a
    /// pad. Subtracting it back out recovers the chrome height for the diagnostic
    /// in `reportHeaderClearance` — the two must stay in step.
    private static let padMargin: Double = 40

    private let driver: BrowserScrollDriver
    private let grabber: ScrollFrameGrabber
    private let maxHeightPixels: Int
    /// The display's own pixels-per-point, used as the calibration fallback and as
    /// the sanity range for the measured ratio.
    private let backingScale: Double
    /// Height of the captured region in *captured pixels*. The step has to be derived
    /// from this rather than from the page's viewport: the user is free to drag a
    /// region over one column of a tall window, and stepping by a viewport that the
    /// region only shows part of would march straight past the rows in between.
    private let regionHeightPixels: Double

    private var isCancelled = false
    private var isStopping = false
    private let cancelLock = NSLock()
    /// Overlap the driver asked for, in CSS pixels. Kept only so the assembly step
    /// can say whether the tiles really did overlap by that much.
    private var measuredPad: Double = 0

    init(driver: BrowserScrollDriver, grabber: ScrollFrameGrabber,
         regionHeightPixels: CGFloat, maxHeightPixels: Int, backingScale: CGFloat) {
        self.driver = driver
        self.grabber = grabber
        self.regionHeightPixels = Double(regionHeightPixels)
        self.maxHeightPixels = maxHeightPixels
        self.backingScale = Double(backingScale)
    }

    /// Throw the session away. The page is scrolled back to where the user left it
    /// and `completion` reports `.cancelled`; nothing is saved.
    func cancel() {
        cancelLock.lock()
        isCancelled = true
        isStopping = true
        cancelLock.unlock()
    }

    /// Stop early but keep what has been captured — ⇧⌥W pressed again, or the
    /// display configuration changing under the region. The tiles in hand are all
    /// good; only the ones we hadn't reached yet are lost.
    func finishEarly() {
        cancelLock.lock()
        isStopping = true
        cancelLock.unlock()
    }

    private var cancelled: Bool {
        cancelLock.lock()
        defer { cancelLock.unlock() }
        return isCancelled
    }

    /// Either kind of stop request: leave the capture loop at the next check.
    private var stopping: Bool {
        cancelLock.lock()
        defer { cancelLock.unlock() }
        return isStopping
    }

    /// Run the whole session. `progress` (0…100) and `completion` are called on the
    /// main queue; `completion` runs exactly once.
    func run(progress: @escaping (Int) -> Void, completion: @escaping (Outcome) -> Void) {
        Task { [weak self] in
            guard let self else { return }
            let outcome = await self.capture(progress: progress)
            await MainActor.run { completion(outcome) }
        }
    }

    // MARK: - The session

    private func capture(progress: @escaping (Int) -> Void) async -> Outcome {
        var tiles: [TileComposer.Tile] = []
        var originalY: Double?

        let start: BrowserScrollDriver.Metrics
        do {
            start = try await driver.prepare()
        } catch {
            // Nothing has been captured, so there is nothing to weigh against
            // offering the user a way forward — and the two things that stop this
            // call working are both switches they have to throw themselves. Treat
            // *any* first-call failure as a setup problem rather than trusting an
            // error message to say so: those are localised, and a user whose browser
            // reported it in Korean would otherwise get a bare failure alert with no
            // fallback offered.
            ScrollSessionLog.write("browser: prepare failed — \(error)")
            return .setupRequired((error as? BrowserScrollDriver.DriverError) ?? .badResponse)
        }

        do {
            ScrollSessionLog.write(String(format:
                "browser: prepared y=%.0f vh=%.0f total=%.0f", start.y, start.viewport, start.total))
            originalY = start.y

            // A page that fits on one screen is a plain region shot; taking it here
            // rather than erroring keeps ⇧⌥W meaning the same thing everywhere.
            guard start.isScrollable else {
                ScrollSessionLog.write("browser: page does not scroll — saving a single frame")
                let frame = try await grabber.grab()
                return .image(frame)
            }

            let pad = try await driver.stickyPad()
            measuredPad = pad
            // Provisionally, CSS pixels and points are the same size (browser zoom at
            // 100%), which is what makes the backing scale a usable stand-in until
            // tile 1 exists and the ratio can be measured for real.
            var pxPerCss = backingScale
            var step = self.step(pad: pad, viewport: start.viewport, pxPerCss: pxPerCss)
            ScrollSessionLog.write(String(format:
                "browser: pad=%.0fcss region=%.0fpx vh=%.0fcss step=%.0fcss",
                pad, regionHeightPixels, start.viewport, step))

            // To the top, then down in fixed steps.
            var current = try await driver.scroll(to: 0)
            var capturedBytes = 0
            let firstFrame = try await settledFrame()
            tiles.append(TileComposer.Tile(image: firstFrame, y: current.y))
            capturedBytes += bytes(of: firstFrame)
            await report(progress, current)

            while !stopping {
                let moved = try await driver.scroll(to: current.y + step)
                // The page refused to go further: everything below is already in the
                // tile we hold, so there is nothing left to photograph.
                guard moved.y > current.y + 0.5 else {
                    ScrollSessionLog.write(String(format: "browser: bottom at y=%.0f", moved.y))
                    break
                }
                current = moved
                let frame = try await settledFrame()
                tiles.append(TileComposer.Tile(image: frame, y: current.y))
                capturedBytes += bytes(of: frame)
                await report(progress, current)

                // With two tiles a known distance apart the real ratio is knowable,
                // and at anything but 100% zoom it is not the backing scale. Re-derive
                // the step from it now, while there are still tiles left to take.
                if tiles.count == 2 {
                    pxPerCss = calibrate(tiles)
                    let corrected = self.step(pad: pad, viewport: start.viewport, pxPerCss: pxPerCss)
                    if abs(corrected - step) >= 1 {
                        ScrollSessionLog.write(String(format:
                            "browser: step %.0f → %.0fcss after calibration", step, corrected))
                        step = corrected
                    }
                }

                if current.y >= current.maxY - 1 { break }
                if tiles.count >= Self.maxTiles {
                    ScrollSessionLog.write("browser: stopped at the \(Self.maxTiles)-tile guard")
                    break
                }
                if capturedBytes >= Self.maxCapturedBytes {
                    ScrollSessionLog.write("browser: stopped at the memory budget "
                        + "(\(capturedBytes / 1_048_576)MB in \(tiles.count) tiles)")
                    break
                }
                // Stop before the canvas would blow past the ceiling rather than
                // capture tiles the composer is only going to throw away.
                let projected = Int((current.y - (tiles.first?.y ?? 0)) * pxPerCss) + frame.height
                if projected >= maxHeightPixels {
                    ScrollSessionLog.write("browser: reached the height ceiling")
                    break
                }
            }
        } catch {
            // Anything failing after `prepare` succeeded is a real fault, not a
            // missing permission — the tab closed, the browser quit, the page went
            // away mid-scroll.
            ScrollSessionLog.write("browser: aborted — \(error)")
            // Fewer than two tiles is not a capture; anything more is worth keeping,
            // because a tab closed halfway through still leaves a usable page.
            guard tiles.count >= 2 else {
                await restore(originalY)
                return cancelled ? .cancelled : .failed
            }
        }

        await restore(originalY)
        if cancelled {
            ScrollSessionLog.write("browser: cancelled by the user")
            return .cancelled
        }
        return assemble(&tiles)
    }

    /// How far to jump between tiles, in CSS pixels.
    ///
    /// The limit is whichever shows less of the page — the browser's viewport or the
    /// **region the user actually dragged**. Stepping by the viewport when the region
    /// is a short strip inside a tall window would skip everything between them, and
    /// the composer would have nothing to paint that band with.
    private func step(pad: Double, viewport: Double, pxPerCss: Double) -> Double {
        let regionCss = regionHeightPixels / max(pxPerCss, 0.01)
        return max(Self.minimumStep, min(viewport, regionCss) - pad)
    }

    /// Bytes a captured frame occupies. ScreenCaptureKit hands back 32-bit BGRA, so
    /// this is exact rather than an estimate.
    private func bytes(of frame: CGImage) -> Int {
        max(frame.bytesPerRow, frame.width * 4) * frame.height
    }

    /// Put the page back where the user had it. Best effort — a failure here is not
    /// worth losing the capture over, and by this point the browser may be gone —
    /// but it is recorded, because a page left parked somewhere the user didn't put
    /// it is exactly the kind of thing they'd otherwise blame on the page.
    private func restore(_ y: Double?) async {
        guard let y else { return }
        do {
            _ = try await driver.scroll(to: y)
        } catch {
            ScrollSessionLog.write(String(format:
                "browser: could not restore the scroll position to %.0f — %@",
                y, String(describing: error)))
        }
    }

    private func report(_ progress: @escaping (Int) -> Void,
                        _ metrics: BrowserScrollDriver.Metrics) async {
        let fraction = (metrics.y + metrics.viewport) / max(metrics.total, 1)
        let percent = min(100, max(0, Int((fraction * 100).rounded())))
        await MainActor.run { progress(percent) }
    }

    /// One frame of the region, taken once the page has stopped repainting it.
    ///
    /// A programmatic jump lands instantly but the *painting* does not: virtualised
    /// pages fill the newly exposed band in over the next few hundred milliseconds,
    /// and a tile grabbed too early freezes that half-drawn state into the image.
    /// Two consecutive identical grabs are the available proof it has finished.
    private func settledFrame() async throws -> CGImage {
        var previous = try await grabber.grab()
        let deadline = Date().addingTimeInterval(Self.settleLimit)
        while Date() < deadline {
            try await Task.sleep(nanoseconds: UInt64(Self.settleInterval * 1_000_000_000))
            if stopping { return previous }
            let next = try await grabber.grab()
            if ScrollStitcher.framesMatch(previous, next) { return next }
            previous = next
        }
        ScrollSessionLog.write("browser: tile never settled — using the newest grab")
        return previous
    }

    // MARK: - Assembly

    /// Flatten the tiles into one image.
    ///
    /// Takes the array `inout` and empties it, which is load-bearing rather than
    /// tidy: `compose` releases each tile as it draws it, and that only frees
    /// anything if this is the last place holding them. A long page's tiles weigh as
    /// much as the finished image, so leaving them alive across the canvas
    /// allocation would double the peak for no reason.
    private func assemble(_ tiles: inout [TileComposer.Tile]) -> Outcome {
        guard !tiles.isEmpty else { return .failed }
        guard tiles.count > 1 else {
            let single = tiles[0].image
            tiles.removeAll()
            return .image(single)
        }

        let pxPerCss = calibrate(tiles)
        guard let layout = TileComposer.layout(tiles: tiles, pxPerCss: pxPerCss,
                                               maxHeightPixels: maxHeightPixels) else {
            ScrollSessionLog.write("browser: no usable tile layout")
            return .failed
        }
        reportHeaderClearance(layout, pxPerCss: pxPerCss)
        if layout.gapPixels > 0 {
            // The step outran what the region can show. The image is whole — tiles
            // were pulled up to close it — but this many rows are printed twice.
            ScrollSessionLog.write("browser: closed \(layout.gapPixels)px of gap by "
                + "overlapping tiles; the step overshot the region")
        }

        var boxed: [TileComposer.Tile?] = tiles.map { $0 }
        let tileCount = tiles.count
        // From here `boxed` is the only owner, so nilling an entry really releases it.
        tiles.removeAll()
        guard let image = TileComposer.compose(tiles: &boxed, pxPerCss: pxPerCss,
                                               maxHeightPixels: maxHeightPixels) else {
            ScrollSessionLog.write("browser: composing \(tileCount) tile(s) failed")
            return .failed
        }
        ScrollSessionLog.write(String(format:
            "browser: composed %d tile(s) → %dx%dpx (pxPerCss=%.3f dropped=%d redundant=%d)",
            tileCount, image.width, image.height, pxPerCss,
            layout.droppedTiles, layout.redundantTiles))
        return .image(image)
    }

    /// The overlap each tile is cut back by has to be at least as tall as the pinned
    /// chrome, or a slice of header survives in the middle of the image. It always
    /// is when the page honours our steps; this records the case where it didn't —
    /// scroll snapping, a page that resized itself — instead of leaving a mystery
    /// band in the output with nothing to explain it.
    private func reportHeaderClearance(_ layout: TileComposer.Layout, pxPerCss: Double) {
        let headerPixels = Int((max(0, measuredPad - Self.padMargin) * pxPerCss).rounded())
        let smallestCut = layout.placements.dropFirst().map(\.cut).min() ?? 0
        guard headerPixels > 0, smallestCut < headerPixels else { return }
        ScrollSessionLog.write(
            "browser: smallest tile overlap \(smallestCut)px is under the \(headerPixels)px "
            + "of pinned chrome — expect a header remnant at a seam")
    }

    /// Captured pixels per CSS pixel, measured once.
    ///
    /// It is *not* simply the display's backing scale: browser zoom changes it, and
    /// at 110% zoom a canvas laid out at 2.0 would drift a pixel every ten tiles
    /// until the seams walked visibly out of line. So the first two tiles — whose
    /// CSS distance apart the page told us exactly — are registered once, and the
    /// ratio falls out of that one measurement.
    ///
    /// A wild answer is rejected rather than used: browser zoom tops out around
    /// 25…500%, so anything outside that band is a failed registration, not a zoom
    /// level, and the backing scale is the better guess.
    private func calibrate(_ tiles: [TileComposer.Tile]) -> Double {
        let deltaCss = tiles[1].y - tiles[0].y
        guard deltaCss > 1,
              let measured = ScrollStitcher.verticalOffset(from: tiles[0].image, to: tiles[1].image),
              measured > 0 else {
            ScrollSessionLog.write(String(format:
                "browser: calibration failed (Δy=%.1fcss) — using backing scale %.2f",
                deltaCss, backingScale))
            return backingScale
        }
        let ratio = Double(measured) / deltaCss
        guard ratio >= backingScale * 0.25, ratio <= backingScale * 5 else {
            ScrollSessionLog.write(String(format:
                "browser: calibration %.3f out of range — using backing scale %.2f",
                ratio, backingScale))
            return backingScale
        }
        ScrollSessionLog.write(String(format:
            "browser: calibrated pxPerCss=%.4f (%dpx over %.1fcss, backing %.2f)",
            ratio, measured, deltaCss, backingScale))
        return ratio
    }

}
