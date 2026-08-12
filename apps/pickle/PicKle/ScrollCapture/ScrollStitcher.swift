import CoreGraphics
import Foundation
import Vision

/// Tunables for the "do these two regions look the same?" test, which gates both
/// the deferred commit and the registration guard. Grid sampling keeps it to a
/// few milliseconds even on a full-frame comparison.
private enum ScrollCompare {
    /// Sample one pixel per this many, on both axes.
    static let stride = 16
    /// Per-sample gray difference (0…255) that counts as "changed".
    static let tolerance = 10
    /// Samples within one row allowed to differ before that ROW is called changed.
    static let rowDifferingFraction = 0.20
    /// Rows that must agree for the registration guard and the stillness test. Loose
    /// on purpose: a sticky header, a video, or a lazy-loading thumbnail occupies a
    /// minority of rows and must not veto an otherwise perfect match.
    static let overlapMinRowFraction = 0.60
    /// Rows that must agree to call a pending band finished. Stricter, so a
    /// half-painted band keeps waiting instead of being frozen into the image.
    static let pendingMinRowFraction = 0.80
}

/// Turns a stream of scrolling frames into one tall image.
///
/// **Memory is the whole design.** Eight frames a second of a Retina region is
/// tens of megabytes a second, so we never keep the stream: we keep the first
/// frame, the confirmed slices, and one frame for registration. Everything runs on
/// a private serial queue; the caller gets progress back on the main queue.
///
/// **Deferred commit is the other half.** Virtualised pages (YouTube, long feeds)
/// reveal a band as flat background and paint the real content in 0.1–0.5s later.
/// Committing each newly revealed strip on sight bakes those blanks in forever —
/// a device capture came back with 22 black bands. So newly revealed rows are held
/// *pending* until a later frame shows them unchanged, which is the only available
/// proof that the page has finished drawing them. Pending rows cost no extra
/// memory: they live in the registration frame we already hold, and are extracted
/// from whichever frame finally confirms them.
final class ScrollStitcher {

    /// What `append` reports back once a frame has been folded in.
    struct Progress {
        /// Height of the image as it would be composed right now (committed +
        /// pending), in pixels.
        let heightPixels: Int
        /// Confirmed slices so far. Reported here rather than exposed as a property
        /// so the caller can cache it on the main queue instead of reaching into
        /// the serial queue (which would block main behind a Vision registration).
        let stripCount: Int
        /// Running total of joins where the two frames shared no content. The panel
        /// watches this for *increases* and says so at the moment it happens — a
        /// seam is caused by scrolling too fast, and told about afterwards it is
        /// just bad news, told about now it is something the user can act on.
        let seamCount: Int
        /// The safety ceiling was hit — the caller should finish the session.
        let reachedLimit: Bool
    }

    /// The outcome of flattening a session. `empty` and `failed` are deliberately
    /// distinct: finishing before the first frame lands is a normal, silent
    /// non-result, while a failed flatten is worth telling the user about.
    enum Composition {
        /// No frame was ever captured — nothing to save and nothing to report.
        case empty
        /// Frames existed but couldn't be flattened (canvas allocation failed).
        case failed
        case image(CGImage)
    }

    /// Ignore anything smaller: sub-pixel jitter and compression noise register as
    /// one or two pixels even on a perfectly still screen.
    private static let minimumStep = 3
    /// Dropped frames in a row before giving up on continuity and starting over.
    private static let rejectsBeforeReAnchor = 2
    /// Upward readings in a row before the image is actually rewound. One is almost
    /// always a misregistration; two in a row against the *same* reference is the
    /// user scrolling back, and the second reading is the whole distance travelled.
    private static let upsBeforeRewind = 2
    /// Sampled gray spread below which a band counts as featureless. A flat band
    /// looks "unchanged" between two frames however far the page scrolled, so this
    /// is what stops a plain white page bottom from being mistaken for a footer and
    /// deleted from every single frame.
    private static let flatBandSpread = 12

    private let queue = DispatchQueue(label: "com.Team-jAm.PICkle.scroll-stitch", qos: .userInitiated)
    private let maxHeightPixels: Int

    /// The very first frame — the top of the finished image.
    private var first: CGImage?
    /// Confirmed slices, in order, each detached from its parent frame. Optional so
    /// `render` can drop each one the instant it's on the canvas.
    private var strips: [CGImage?] = []
    /// The most recent frame. It is both the registration reference and the home of
    /// the pending rows, so exactly one full frame is alive here at a time.
    private var previous: CGImage?
    /// Rows at the bottom of `previous` that are revealed but not yet confirmed.
    private var pendingPx = 0
    /// Rows revealed by the previous accepted step — the band most likely to still
    /// be mid-paint, which registration has to look past.
    private var lastDy = 0
    private var committedHeight = 0
    /// Frames that scrolled so far the two didn't overlap — the stitch has a visible
    /// seam there. Counted for the log; the frame is still appended.
    private var seams = 0
    /// Frames dropped because the overlap didn't match the offset Vision claimed.
    private var rejected = 0
    /// Consecutive dropped frames. A streak is fatal without recovery: `previous`
    /// never advances, the true offset grows past a frame, and nothing can register
    /// again — which is exactly how build 23 produced a one-frame-tall capture.
    private var consecutiveRejects = 0
    private var reAnchors = 0
    /// Upward readings against the current reference, for the rewind debounce.
    private var consecutiveUps = 0
    /// Rows of pinned chrome at the top and bottom of every frame, or -1 until
    /// they've been measured. Measured once, on the first pair of frames proven to
    /// be a known distance apart — anything that did not move on a frame that did is
    /// pinned by definition. Cached rather than re-derived per frame because a
    /// standstill makes *every* row look pinned, and a re-measurement that landed on
    /// one would start cropping the page itself away.
    private var pinnedTop = -1
    private var pinnedBottom = -1
    /// The pinned bands themselves, put back at the very top and very bottom of the
    /// finished image — Deepin's crop-and-restore, which is what keeps a sticky
    /// header out of the middle of the stitch while still showing it once.
    private var topBand: CGImage?
    private var bottomBand: CGImage?
    private var rewinds = 0
    /// Rows a rewind couldn't take back because they belong to the first frame. The
    /// next downward scroll re-covers them before anything new is appended.
    private var rewindOvershoot = 0
    /// One line per session is enough for the full-frame registration fallback.
    private var loggedFullFrameFallback = false
    /// Diagnostics only (see the removal note in the plan): how often each check is
    /// what stopped a frame, so a device session says *why* it degraded.
    private var pendingHeldCount = 0
    private var misregisteredCount = 0
    private var registrationFailures = 0
    private var reachedLimit = false

    init(maxHeightPixels: Int) {
        self.maxHeightPixels = maxHeightPixels
    }

    /// Fold `frame` into the running image. `completion` runs on the main queue.
    func append(_ frame: CGImage, completion: @escaping (Progress) -> Void) {
        queue.async {
            let progress = self.ingest(frame)
            DispatchQueue.main.async { completion(progress) }
        }
    }

    /// One last frame, taken a beat after the user finished. If the page hasn't
    /// moved, its copy of the pending rows is strictly fresher than the one we're
    /// holding, so take it — this is what rescues a capture ended mid-fling, where
    /// the bottom of the page was still blank when [Done] was pressed.
    func settle(with frame: CGImage, completion: @escaping () -> Void) {
        queue.async {
            self.settleAtFinish(frame)
            DispatchQueue.main.async { completion() }
        }
    }

    /// Flatten everything captured so far into a single image. `completion` runs on
    /// the main queue. The stitcher is emptied whatever the outcome, so the frames
    /// are released as soon as the caller has its result.
    func compose(completion: @escaping (Composition) -> Void) {
        queue.async {
            let result = self.render()
            ScrollSessionLog.write("stitch summary: \(self.seams) seam(s), \(self.rejected) reject(s), "
                + "\(self.reAnchors) re-anchor(s), \(self.rewinds) rewind(s), "
                + "\(self.misregisteredCount) misregistration(s), "
                + "\(self.registrationFailures) registration failure(s), "
                + "\(self.pendingHeldCount) frame(s) held pending")
            self.reset()
            DispatchQueue.main.async { completion(result) }
        }
    }

    /// Throw everything away (cancelled session).
    func discard() {
        queue.async { self.reset() }
    }

    // MARK: - Accumulation (serial queue only)

    private func ingest(_ incoming: CGImage) -> Progress {
        let frame = body(of: incoming)
        guard let reference = previous else {
            first = frame
            previous = frame
            committedHeight = frame.height
            pendingPx = 0
            return progress()
        }
        guard !reachedLimit else { return progress() }
        // A different frame size means the display changed under us mid-session.
        guard frame.width == reference.width, frame.height == reference.height else { return progress() }

        let h = frame.height, w = frame.width
        // Once the pinned chrome has been cropped off there is none left to hide from
        // Vision, so the window is the whole body. Before that, it's measured per
        // frame exactly as it always was.
        let sticky = pinnedTop > 0 ? 0 : Self.stickyTopRows(reference, frame, cap: h / 3)
        // A pinned *footer* poisons registration exactly the way a pinned header
        // does — same screen rows, same razor-sharp correlation peak at dy = 0 — so
        // until it has been cropped away for good it has to be kept out of the
        // window too. Zero as soon as the bands are cached, and zero all along on
        // the overwhelming majority of pages, which have no pinned footer at all.
        let foot = pinnedBottom > 0 ? 0 : Self.stickyBottomRows(reference, frame, cap: h / 3)
        let win = window(h, sticky: sticky, foot: foot)
        guard let measured = offset(from: reference, to: frame, top: win.top, height: win.height) else {
            registrationFailures += 1
            ScrollSessionLog.write("registration returned nothing (pending=\(pendingPx) sticky=\(sticky))")
            return progress()
        }

        // Scrolled back up. Not new content to stitch — a correction: the user is
        // undoing a stretch they went past too fast, and expects the image to follow
        // them back rather than to grow a second copy of what they just saw.
        if measured <= -Self.minimumStep {
            // Clamp exactly as the forward path does. An unclamped reading is a
            // registration artefact, not a distance, and it would take a bite out of
            // the confirmed image proportional to how wrong it is.
            rewindIfConfirmed(by: min(-measured, h), frame: frame, win: win)
            return progress()
        }
        consecutiveUps = 0

        // Not scrolling. A standstill is the one moment the page can be *proven* to
        // have finished painting.
        if measured < Self.minimumStep {
            settleOrRecover(reference: reference, frame: frame, measured: measured, win: win)
            return progress()
        }

        // Can't reveal more than a frame's worth in one step: past that the two
        // frames share no content, so the offset is a guess and the join shows.
        let dy = min(measured, h)
        // A rewind that ran into the first frame left the image *ahead* of where the
        // frame is, so the first stretch of scrolling back down re-covers rows the
        // canvas already has. Those aren't new content and must not be appended a
        // second time — `dy` still describes the frame-to-frame move (registration
        // and the guard below depend on that), `revealed` is what's actually new.
        var revealed = dy
        if rewindOvershoot > 0 {
            let absorbed = min(rewindOvershoot, dy)
            rewindOvershoot -= absorbed
            revealed -= absorbed
            if revealed < Self.minimumStep {
                previous = frame
                lastDy = 0
                return progress()
            }
        }
        if dy >= Int(Double(h) * 0.95) { seams += 1 }

        // Safety ceiling — stop taking new content rather than run the machine out
        // of memory. Whatever is pending still flushes when the session composes.
        guard committedHeight + pendingPx + revealed <= maxHeightPixels else {
            reachedLimit = true
            return progress()
        }

        // Verify the offset inside the SAME window registration used: pinned chrome
        // excluded at the top, maybe-unpainted band excluded at the bottom. Checking
        // the raw overlap instead would fail on both counts — the chrome sits at
        // different content positions in the two frames, and the pending band is
        // content we positively expect to have changed.
        let guardHeight = win.height - dy
        if guardHeight >= ScrollCompare.stride {
            let inReference = CGRect(x: 0, y: win.top + dy, width: w, height: guardHeight)
            let inFrame = CGRect(x: 0, y: win.top, width: w, height: guardHeight)
            let agreement = Self.rowsAgreeing(reference, inReference, frame, inFrame) ?? -1
            guard agreement >= ScrollCompare.overlapMinRowFraction else {
                rejected += 1
                consecutiveRejects += 1
                ScrollSessionLog.write(String(format:
                    "REJECT guard dy=%dpx rowsAgree=%.2f (need %.2f) "
                    + "sticky=%d pending=%d window=%d streak=%d",
                    dy, agreement, ScrollCompare.overlapMinRowFraction,
                    sticky, pendingPx, win.height, consecutiveRejects))
                if consecutiveRejects >= Self.rejectsBeforeReAnchor { reAnchor(to: frame) }
                return progress()
            }
        }
        consecutiveRejects = 0

        // Pending rows must never reach up into the pinned chrome: those rows aren't
        // page content, and committing them stamps a copy of the header into the
        // middle of the stitched image every time the band saturates.
        let usable = max(h - sticky, h / 2)
        // Rows that scrolled off the top of the frame can never be confirmed now.
        // Commit the newest copy we have, which is the one in `reference`.
        let overflow = max(0, pendingPx + revealed - usable)
        if overflow > 0 {
            commit(from: reference, rect: CGRect(x: 0, y: h - pendingPx, width: w, height: overflow))
            pendingPx -= overflow
        }
        // The old pending band sits `dy` higher in the new frame. Same in both =
        // the page has stopped changing it, so commit the fresher copy. Different =
        // still painting, so it stays pending along with the newly revealed rows.
        if pendingPx > 0 {
            let inReference = CGRect(x: 0, y: h - pendingPx, width: w, height: pendingPx)
            let inFrame = CGRect(x: 0, y: h - pendingPx - dy, width: w, height: pendingPx)
            let bandAgreement = Self.rowsAgreeing(reference, inReference, frame, inFrame) ?? -1
            if bandAgreement >= ScrollCompare.pendingMinRowFraction {
                commit(from: frame, rect: inFrame)
                pendingPx = revealed
            } else {
                pendingHeldCount += 1
                pendingPx += revealed
            }
        } else {
            pendingPx = revealed
        }
        // The first accepted step is the only trustworthy chance to measure pinned
        // chrome, and it has to be taken before anything has been committed.
        previous = pinnedTop < 0 ? adoptPinnedChrome(reference: reference, frame: frame) : frame
        lastDy = dy
        return progress()
    }

    // MARK: - Pinned chrome (measure once, crop every frame, restore at the ends)

    /// Strip the pinned bands off an incoming frame. The identity function until the
    /// bands have been measured, which is most of the first second of a session.
    private func body(of frame: CGImage) -> CGImage {
        guard pinnedTop > 0 || pinnedBottom > 0 else { return frame }
        let height = frame.height - pinnedTop - pinnedBottom
        guard height >= 1,
              let cropped = frame.cropping(to: CGRect(x: 0, y: pinnedTop,
                                                      width: frame.width, height: height))
        else { return frame }
        return cropped
    }

    /// Measure the pinned bands from the first pair of frames known to be a real
    /// distance apart, cache them, and retro-fit everything captured so far.
    ///
    /// Why here and not per frame: pinned chrome is *defined* as what doesn't move
    /// when the page does, so it can only be measured across a frame pair that
    /// moved. At a standstill every row qualifies. And why only once: a later
    /// measurement that happened to land on a still moment would report the whole
    /// frame as chrome and start cropping the page away.
    ///
    /// Returns the frame to keep as the new reference — cropped, so that it is the
    /// same shape as every frame that follows it.
    private func adoptPinnedChrome(reference: CGImage, frame: CGImage) -> CGImage {
        let h = frame.height, w = frame.width
        let cap = h / 3
        let top = Self.stickyTopRows(reference, frame, cap: cap)
        let bottom = Self.stickyBottomRows(reference, frame, cap: cap)
        pinnedTop = top
        pinnedBottom = bottom
        guard top > 0 || bottom > 0 else { return frame }
        // Retro-fitting only works while `first` is still the entire capture. It
        // always is — nothing can be committed before the first accepted step — but
        // the invariant is worth one line to enforce rather than to assume.
        guard strips.isEmpty, let firstFrame = first, firstFrame.height == h else {
            pinnedTop = 0
            pinnedBottom = 0
            return frame
        }
        if top > 0, let band = firstFrame.cropping(to: CGRect(x: 0, y: 0, width: w, height: top)) {
            topBand = Self.detached(band)
        }
        if bottom > 0,
           let band = frame.cropping(to: CGRect(x: 0, y: h - bottom, width: w, height: bottom)) {
            bottomBand = Self.detached(band)
        }
        first = Self.detached(body(of: firstFrame)) ?? firstFrame
        committedHeight = first?.height ?? committedHeight
        // The pending *count* survives the crop unchanged. Cropping moves the whole
        // picture up by `bottom` — both the committed region's last row and the
        // reference's last row — so the number of rows between them is the same as
        // it was. Subtracting the footer here instead would open a gap in the output
        // exactly one footer tall.
        pendingPx = min(pendingPx, h - top - bottom)
        ScrollSessionLog.write("pinned chrome: top=\(top)px bottom=\(bottom)px "
            + "(frame \(w)x\(h), cropped body \(first?.height ?? 0)px)")
        return body(of: frame)
    }

    // MARK: - Rewind

    /// The user scrolled back up. Undo that much of the image — but only once a
    /// second frame agrees, and only if the pixels actually line up at the offset
    /// claimed.
    ///
    /// Both conditions earn their keep. A single negative reading is far more often a
    /// misregistration than a real reversal, and because the reference is *not*
    /// advanced on the first one, the second reading measures the whole distance
    /// travelled rather than just the last hop. Verifying the overlap then separates
    /// a genuine reversal from two bad readings in a row, which would otherwise saw
    /// the bottom off a perfectly good capture.
    private func rewindIfConfirmed(by up: Int, frame: CGImage, win: (top: Int, height: Int)) {
        consecutiveUps += 1
        guard consecutiveUps >= Self.upsBeforeRewind, let reference = previous else { return }
        let w = frame.width
        let guardHeight = win.height - up
        // Too little overlap left to check is NOT permission to proceed. This is the
        // one operation that destroys already-confirmed image, and the readings it
        // fires on — the big ones — are exactly the readings that shrink the window
        // below the checkable minimum. An unverifiable rewind is treated as a bad
        // frame instead, which routes it to the same re-anchor recovery as any other.
        guard guardHeight >= ScrollCompare.stride else {
            consecutiveUps = 0
            rejected += 1
            consecutiveRejects += 1
            ScrollSessionLog.write(
                "REJECT rewind up=\(up)px — only \(guardHeight)px of window left to verify "
                + "against (streak=\(consecutiveRejects))")
            if consecutiveRejects >= Self.rejectsBeforeReAnchor { reAnchor(to: frame) }
            return
        }
        // Moving up means the new frame holds the reference's content shifted DOWN
        // by `up` — the mirror of the forward guard.
        let inReference = CGRect(x: 0, y: win.top, width: w, height: guardHeight)
        let inFrame = CGRect(x: 0, y: win.top + up, width: w, height: guardHeight)
        let agreement = Self.rowsAgreeing(reference, inReference, frame, inFrame) ?? -1
        guard agreement >= ScrollCompare.overlapMinRowFraction else {
            consecutiveUps = 0
            rejected += 1
            consecutiveRejects += 1
            ScrollSessionLog.write(String(format:
                "REJECT rewind up=%dpx rowsAgree=%.2f (need %.2f) streak=%d",
                up, agreement, ScrollCompare.overlapMinRowFraction, consecutiveRejects))
            if consecutiveRejects >= Self.rejectsBeforeReAnchor { reAnchor(to: frame) }
            return
        }
        rewindOvershoot = rewind(by: up)
        rewinds += 1
        ScrollSessionLog.write("REWIND \(up)px — committed=\(committedHeight)px"
            + (rewindOvershoot > 0 ? ", \(rewindOvershoot)px above the first frame" : ""))
        previous = frame
        pendingPx = 0
        lastDy = 0
        consecutiveUps = 0
        consecutiveRejects = 0
    }

    /// Take `pixels` rows off the bottom of everything captured so far: the pending
    /// band first (it isn't on the canvas yet), then committed slices newest-first,
    /// splitting the last one if the cut lands inside it.
    ///
    /// The first frame is the floor. Scrolling above where the capture started is
    /// *prepending*, which v1 doesn't do, so the excess is returned rather than
    /// applied — the caller absorbs it out of the next downward scroll so that
    /// coming back down doesn't append a second copy of what's already there.
    private func rewind(by pixels: Int) -> Int {
        var remaining = pixels
        let fromPending = min(pendingPx, remaining)
        pendingPx -= fromPending
        remaining -= fromPending
        let floor = first?.height ?? 0
        while remaining > 0, committedHeight > floor, let slice = strips.last ?? nil {
            let removable = min(remaining, slice.height, committedHeight - floor)
            if removable >= slice.height {
                strips.removeLast()
            } else {
                let keep = slice.height - removable
                guard let head = slice.cropping(to: CGRect(x: 0, y: 0, width: slice.width,
                                                           height: keep)),
                      let detachedHead = Self.detached(head) else { break }
                strips[strips.count - 1] = detachedHead
            }
            committedHeight -= removable
            remaining -= removable
        }
        return remaining
    }

    /// Rows of the frame that registration and verification both work on: below any
    /// pinned chrome at the top, above whichever reaches higher of the pinned chrome
    /// at the bottom and the band that may still be mid-paint.
    private func window(_ h: Int, sticky: Int, foot: Int) -> (top: Int, height: Int) {
        (sticky, h - sticky - max(foot, min(pendingPx, min(lastDy, h / 2))))
    }

    /// Start over from `frame`, keeping whatever is already confirmed. The skipped
    /// span is lost to a seam — an honest degradation, and far better than a session
    /// that silently stops accepting frames and saves a single screenful.
    private func reAnchor(to frame: CGImage) {
        flushPending()
        seams += 1
        reAnchors += 1
        previous = frame
        pendingPx = 0
        lastDy = 0
        consecutiveRejects = 0
        ScrollSessionLog.write("RE-ANCHOR — committed=\(committedHeight)px, dropped pending, expect a seam")
    }

    /// The standstill path. Confirms the page really didn't move — a misregistration
    /// reports ~0 just as readily as a genuine stop — then commits the pending band
    /// if it looks the same two frames running.
    private func settleOrRecover(reference: CGImage, frame: CGImage,
                                 measured: Int, win: (top: Int, height: Int)) {
        let h = frame.height, w = frame.width
        // Judge stillness over the registration window, not `h - pendingPx`: once
        // pending saturates, that region is empty and *everything* reads as still,
        // including a frame the page has flown past.
        let stillRect = CGRect(x: 0, y: win.top, width: w, height: max(win.height, 0))
        let reallyStill = win.height < ScrollCompare.stride
            || Self.regionsMatch(reference, stillRect, frame, stillRect,
                                 minRows: ScrollCompare.overlapMinRowFraction)
        if pendingPx > 0, reallyStill {
            let band = CGRect(x: 0, y: h - pendingPx, width: w, height: pendingPx)
            if Self.regionsMatch(reference, band, frame, band,
                                 minRows: ScrollCompare.pendingMinRowFraction) {
                commit(from: frame, rect: band)
                pendingPx = 0
                // Advance the reference. Everything is committed so there's no
                // pending band to lose, and leaving the OLD frame in place keeps its
                // half-painted rows around to poison the next registration.
                previous = frame
                consecutiveRejects = 0
                return
            }
        }
        if reallyStill {
            // Still changing. Adopt the fresher frame so the NEXT still tick has
            // something current to match against — safe only at a dead stop, where
            // there is no accumulated sub-threshold scroll to lose.
            if measured == 0 { previous = frame }
            consecutiveRejects = 0
            return
        }
        // Registration said "not moving" but the page plainly did. That's the same
        // dead end as a rejected overlap, so it feeds the same recovery counter —
        // without this, a garbage negative dy parks here forever.
        consecutiveRejects += 1
        misregisteredCount += 1
        ScrollSessionLog.write(String(format:
            "MISREGISTERED dy=%d but window moved (pending=%d window=%d streak=%d)",
            measured, pendingPx, win.height, consecutiveRejects))
        if consecutiveRejects >= Self.rejectsBeforeReAnchor { reAnchor(to: frame) }
    }

    /// See `settle(with:completion:)`. Unlike the mid-session path this does not
    /// require the band to be unchanged — we are out of time, and the newest frame
    /// is by definition the best-rendered copy of those rows we will ever have.
    private func settleAtFinish(_ incoming: CGImage) {
        // The footer is whatever it looks like in the very last frame we take.
        if pinnedBottom > 0, incoming.height > pinnedBottom,
           let band = incoming.cropping(to: CGRect(x: 0, y: incoming.height - pinnedBottom,
                                                   width: incoming.width, height: pinnedBottom)),
           let detachedBand = Self.detached(band) {
            bottomBand = detachedBand
        }
        let frame = body(of: incoming)
        guard pendingPx > 0, let reference = previous,
              frame.width == reference.width, frame.height == reference.height else { return }
        let sticky = pinnedTop > 0 ? 0 : Self.stickyTopRows(reference, frame, cap: frame.height / 3)
        let foot = pinnedBottom > 0 ? 0 : Self.stickyBottomRows(reference, frame, cap: frame.height / 3)
        let win = window(frame.height, sticky: sticky, foot: foot)
        guard let measured = offset(from: reference, to: frame, top: win.top, height: win.height),
              abs(measured) < Self.minimumStep else { return }
        let settledHeight = frame.height - pendingPx
        if settledHeight >= ScrollCompare.stride {
            let rect = CGRect(x: 0, y: 0, width: frame.width, height: settledHeight)
            guard Self.regionsMatch(reference, rect, frame, rect,
                                    minRows: ScrollCompare.pendingMinRowFraction) else { return }
        }
        commit(from: frame, rect: CGRect(x: 0, y: frame.height - pendingPx,
                                         width: frame.width, height: pendingPx))
        pendingPx = 0
    }

    /// Commit whatever is still unconfirmed, from the newest frame we hold. Better
    /// a possibly-mid-render tail than a truncated image.
    private func flushPending() {
        guard pendingPx > 0, let previous else { return }
        commit(from: previous, rect: CGRect(x: 0, y: previous.height - pendingPx,
                                            width: previous.width, height: pendingPx))
        pendingPx = 0
    }

    @discardableResult
    private func commit(from image: CGImage, rect: CGRect) -> Bool {
        guard rect.height >= 1,
              let slice = image.cropping(to: rect),
              let strip = Self.detached(slice) else { return false }
        strips.append(strip)
        committedHeight += Int(rect.height)
        return true
    }

    private func progress() -> Progress {
        Progress(heightPixels: bandHeight + committedHeight + pendingPx,
                 stripCount: strips.count, seamCount: seams, reachedLimit: reachedLimit)
    }

    /// Rows the restored pinned bands add back to the finished image.
    private var bandHeight: Int { (topBand?.height ?? 0) + (bottomBand?.height ?? 0) }

    private func render() -> Composition {
        flushPending()
        guard let first else { return .empty }
        // Never scrolled → the session is just a plain region shot. The bands were
        // never cropped off in that case, so there is nothing to put back either.
        guard !strips.isEmpty else { return .image(first) }
        let width = first.width
        // Pinned chrome goes back on at the ends — shown once each, at the only two
        // places it can be true, instead of stamped through the middle of the image
        // once per frame.
        let head = topBand
        let foot = bottomBand
        let height = (head?.height ?? 0) + committedHeight + (foot?.height ?? 0)
        guard let ctx = Self.newContext(width: width, height: height) else { return .failed }
        var top = 0
        if let head {
            ctx.draw(head, in: CGRect(x: 0, y: height - head.height, width: width, height: head.height))
            top = head.height
            topBand = nil
        }
        ctx.draw(first, in: CGRect(x: 0, y: height - top - first.height,
                                   width: width, height: first.height))
        self.first = nil
        top += first.height
        // Release each slice the moment it's on the canvas. Peak memory here is the
        // canvas plus `makeImage`'s copy of it; without this the whole strip set —
        // roughly a slab the size of the canvas again — would still be resident at
        // that exact moment.
        for index in strips.indices {
            guard let image = strips[index] else { continue }
            // CGContext draws bottom-left-origin; `top` counts down from the image top.
            ctx.draw(image, in: CGRect(x: 0, y: height - top - image.height,
                                       width: width, height: image.height))
            top += image.height
            strips[index] = nil
        }
        if let foot {
            ctx.draw(foot, in: CGRect(x: 0, y: height - top - foot.height,
                                      width: width, height: foot.height))
            bottomBand = nil
        }
        return ctx.makeImage().map(Composition.image) ?? .failed
    }

    private func reset() {
        first = nil
        strips.removeAll()
        previous = nil
        pendingPx = 0
        lastDy = 0
        committedHeight = 0
        seams = 0
        rejected = 0
        consecutiveRejects = 0
        consecutiveUps = 0
        reAnchors = 0
        rewinds = 0
        rewindOvershoot = 0
        loggedFullFrameFallback = false
        pinnedTop = -1
        pinnedBottom = -1
        topBand = nil
        bottomBand = nil
        pendingHeldCount = 0
        misregisteredCount = 0
        registrationFailures = 0
        reachedLimit = false
    }

    // MARK: - Vision

    /// Scroll distance between the two frames, measured only inside `window`.
    ///
    /// The cropping is not an optimisation — it is the difference between working and
    /// not. Anything that occupies the *same screen rows* in both frames correlates
    /// perfectly at dy = 0 and outvotes the scrolling body, and there are two such
    /// things. Isolation probe, true step 240px:
    ///
    ///     plain 240 · +lazy 240 · +sticky header 0 · +header+lazy 841
    ///
    /// so the window excludes both — pinned chrome at the top (`stickyTopRows`), the
    /// maybe-unpainted band at the bottom. It is the same rows of each frame, so the
    /// content offset inside it is still exactly dy and the sign convention holds.
    ///
    /// The bottom exclusion is `lastDy`, not the whole pending run: older pending
    /// rows have had frames to catch up, and excluding all of them shrinks the window
    /// below dy so there is no shared content left to lock onto. The half-frame floor
    /// keeps that from happening during a fling either.
    private func offset(from reference: CGImage, to frame: CGImage,
                        top: Int, height: Int) -> Int? {
        guard height >= ScrollCompare.stride, top >= 0, top + height <= frame.height,
              top > 0 || height < frame.height,
              let a = reference.cropping(to: CGRect(x: 0, y: top, width: frame.width, height: height)),
              let b = frame.cropping(to: CGRect(x: 0, y: top, width: frame.width, height: height))
        else {
            // Falling back to the whole frame means any pinned chrome is back in the
            // measurement, which is the failure mode §4.2 exists to prevent. It is
            // still better than no reading at all, but a session that did this is a
            // session whose numbers deserve suspicion — so say so, once.
            if !loggedFullFrameFallback {
                loggedFullFrameFallback = true
                ScrollSessionLog.write("registration fell back to the FULL frame "
                    + "(window top=\(top) height=\(height) of \(frame.height)) — "
                    + "pinned chrome is no longer excluded")
            }
            return Self.verticalOffset(from: reference, to: frame)
        }
        return Self.verticalOffset(from: a, to: b)
    }

    /// How far the page scrolled down between two frames, in pixels. nil when Vision
    /// couldn't register them at all.
    ///
    /// **Sign convention — measured, not assumed.** Proven offline with
    /// `scratchpad/stitch-harness.swift` on a synthetic page sliced at a known step.
    /// `VNImageTranslationAlignmentObservation.alignmentTransform` maps the
    /// **request's** image (`targetedCGImage` — here the newer frame) onto the
    /// **handler's** image (here the older frame). Vision's y axis points up, so a
    /// downward scroll — content sliding up the screen — comes back as a *negative*
    /// `ty` whose magnitude is exactly the scroll distance in pixels:
    ///
    ///     dy = round(-ty)
    ///
    /// The harness reassembled every slice byte-for-byte identical to the source
    /// under that rule, failed outright under `+ty`, and matched randomized 30…228px
    /// steps within ±1px. `tx` is ignored on purpose, and not only because v1 is
    /// vertical-only: the same harness saw a bogus 600px `tx` on a pair whose `ty`
    /// was exact, because horizontally repetitive content has no unique match.
    /// Internal rather than private for one caller: the browser session calibrates
    /// CSS pixels against captured pixels with a *single* registration between its
    /// first two tiles, then never uses Vision again.
    static func verticalOffset(from previous: CGImage, to frame: CGImage) -> Int? {
        let request = VNTranslationalImageRegistrationRequest(targetedCGImage: frame, options: [:])
        let handler = VNImageRequestHandler(cgImage: previous, options: [:])
        do { try handler.perform([request]) }
        catch {
            ScrollSessionLog.write("registration failed: \(error)")
            return nil
        }
        guard let observation = request.results?.first as? VNImageTranslationAlignmentObservation else {
            return nil
        }
        let dy = Int((-observation.alignmentTransform.ty).rounded())
        // v1 *records* confidence rather than acting on it: what counts as a
        // trustworthy score for real scrolling content is unmeasured, and a guessed
        // threshold would silently drop good frames. Only a flat zero — Vision
        // saying it matched nothing at all — is treated as no measurement. The
        // overlap check in `ingest` is what actually catches a bad offset.
        guard observation.confidence > 0 else { return nil }
        return dy
    }

    // MARK: - Region comparison

    /// Fraction of sample ROWS in which the two regions agree, or nil if they can't
    /// be sampled.
    ///
    /// Deciding per row and then taking a majority is the whole point. A single
    /// global budget — which is what build 23 shipped — is blown by any band that
    /// stays put while the page scrolls: YouTube's fixed top bar alone put ~10% of
    /// samples permanently over a 1% budget, so *every* scrolling frame was rejected
    /// and the capture came out exactly one frame tall.
    private static func rowsAgreeing(_ a: CGImage, _ rectA: CGRect,
                                     _ b: CGImage, _ rectB: CGRect) -> Double? {
        guard let sa = graySamples(of: a, rect: rectA),
              let sb = graySamples(of: b, rect: rectB),
              sa.count == sb.count, !sa.isEmpty else { return nil }
        let cols = max(1, Int(rectA.width) / ScrollCompare.stride)
        let rows = sa.count / cols
        guard rows >= 1 else { return nil }
        var agreeing = 0
        for r in 0..<rows {
            var differing = 0
            for c in 0..<cols
            where abs(Int(sa[r * cols + c]) - Int(sb[r * cols + c])) >= ScrollCompare.tolerance {
                differing += 1
            }
            if Double(differing) <= Double(cols) * ScrollCompare.rowDifferingFraction { agreeing += 1 }
        }
        return Double(agreeing) / Double(rows)
    }

    /// Do these two regions look like the same content, allowing a minority of rows
    /// to disagree? Used to decide that a lazily-painted band has settled, and to
    /// sanity-check a registration result.
    private static func regionsMatch(_ a: CGImage, _ rectA: CGRect,
                                     _ b: CGImage, _ rectB: CGRect,
                                     minRows: Double) -> Bool {
        // An empty region has nothing to disagree about.
        guard rectA.height >= 1, rectB.height >= 1 else { return true }
        guard let fraction = rowsAgreeing(a, rectA, b, rectB) else { return false }
        return fraction >= minRows
    }

    /// Do two whole frames of the same size look like the same picture?
    ///
    /// The browser session's settle loop uses this and nothing else: after a
    /// programmatic jump it re-grabs the region until two consecutive grabs agree,
    /// which is the same "the page has stopped painting" proof the manual path uses
    /// on its pending band, applied to the whole tile.
    static func framesMatch(_ a: CGImage, _ b: CGImage) -> Bool {
        guard a.width == b.width, a.height == b.height else { return false }
        let rect = CGRect(x: 0, y: 0, width: a.width, height: a.height)
        return regionsMatch(a, rect, b, rect, minRows: ScrollCompare.pendingMinRowFraction)
    }

    /// Leading rows that look unchanged between two frames at zero offset — a sticky
    /// header, toolbar, or any pinned chrome.
    ///
    /// Vision must not see them. A pixel-identical band gives a razor-sharp
    /// correlation peak at dy = 0 that outvotes the entire scrolling body: in the
    /// harness's isolation probe, adding nothing but a 120px header to a 1200px frame
    /// turned a true 240px step into 0. Capped so that a standstill — where every row
    /// agrees — can't swallow the whole window.
    private static func stickyTopRows(_ a: CGImage, _ b: CGImage, cap: Int) -> Int {
        let full = CGRect(x: 0, y: 0, width: a.width, height: a.height)
        guard let sa = graySamples(of: a, rect: full), let sb = graySamples(of: b, rect: full),
              sa.count == sb.count else { return 0 }
        let cols = max(1, a.width / ScrollCompare.stride)
        let rows = sa.count / cols
        var leading = 0
        while leading < rows {
            var differing = 0
            for c in 0..<cols
            where abs(Int(sa[leading * cols + c]) - Int(sb[leading * cols + c])) >= ScrollCompare.tolerance {
                differing += 1
            }
            if Double(differing) > Double(cols) * ScrollCompare.rowDifferingFraction { break }
            leading += 1
        }
        // Round up by one cell: the detector works in `stride` steps, and even the
        // 8 leftover rows of a 120px header are still a pixel-identical strip.
        return leading == 0 ? 0 : min((leading + 1) * ScrollCompare.stride, cap)
    }

    /// Trailing rows that look unchanged between two frames at zero offset — a
    /// pinned footer, tab bar, or floating toolbar along the bottom edge.
    ///
    /// The mirror of `stickyTopRows` with one extra condition, and that condition is
    /// the whole difference between working and ruinous: **a featureless band is not
    /// evidence of anything.** Page bottoms are routinely a slab of flat background,
    /// and flat pixels match flat pixels however far the page moved. Cropping them as
    /// "chrome" would delete a real strip of the page from every frame and then stamp
    /// one stale copy of it at the end of the image. So a candidate footer has to
    /// carry some actual detail before it is believed.
    private static func stickyBottomRows(_ a: CGImage, _ b: CGImage, cap: Int) -> Int {
        let full = CGRect(x: 0, y: 0, width: a.width, height: a.height)
        guard let sa = graySamples(of: a, rect: full), let sb = graySamples(of: b, rect: full),
              sa.count == sb.count else { return 0 }
        let cols = max(1, a.width / ScrollCompare.stride)
        let rows = sa.count / cols
        var trailing = 0
        while trailing < rows {
            let row = rows - 1 - trailing
            var differing = 0
            for c in 0..<cols
            where abs(Int(sa[row * cols + c]) - Int(sb[row * cols + c])) >= ScrollCompare.tolerance {
                differing += 1
            }
            if Double(differing) > Double(cols) * ScrollCompare.rowDifferingFraction { break }
            trailing += 1
        }
        guard trailing > 0 else { return 0 }
        let height = min((trailing + 1) * ScrollCompare.stride, cap)
        guard height >= ScrollCompare.stride else { return 0 }
        let band = CGRect(x: 0, y: a.height - height, width: a.width, height: height)
        return isFlat(b, rect: band) ? 0 : height
    }

    /// Is this region a single flat colour, as far as the sampler can tell?
    private static func isFlat(_ image: CGImage, rect: CGRect) -> Bool {
        guard let samples = graySamples(of: image, rect: rect), !samples.isEmpty,
              let low = samples.min(), let high = samples.max() else { return true }
        return Int(high) - Int(low) < flatBandSpread
    }

    /// Grid-sample a region down to one gray byte per `ScrollCompare.stride` pixels
    /// on each axis. `.none` interpolation makes this true point sampling — a
    /// nearest-neighbour pick per cell rather than an average — so fine detail like
    /// text on a flat background still registers instead of blurring into it.
    ///
    /// Both sides of a comparison go through this identical path, so whichever end
    /// of the buffer CoreGraphics writes first, the two agree.
    private static func graySamples(of image: CGImage, rect: CGRect) -> [UInt8]? {
        guard let crop = image.cropping(to: rect) else { return nil }
        let w = max(1, crop.width / ScrollCompare.stride)
        let h = max(1, crop.height / ScrollCompare.stride)
        guard let ctx = CGContext(data: nil, width: w, height: h,
                                  bitsPerComponent: 8, bytesPerRow: w,
                                  space: CGColorSpaceCreateDeviceGray(),
                                  bitmapInfo: CGImageAlphaInfo.none.rawValue) else { return nil }
        ctx.interpolationQuality = .none
        ctx.draw(crop, in: CGRect(x: 0, y: 0, width: w, height: h))
        guard let data = ctx.data else { return nil }
        return Array(UnsafeBufferPointer(start: data.assumingMemoryBound(to: UInt8.self), count: w * h))
    }

    // MARK: - Pixels

    /// Copy an image into a buffer of its own.
    ///
    /// `CGImage.cropping(to:)` does NOT copy — it returns a window onto the parent's
    /// pixel buffer, so holding the crop holds the entire frame alive. Without this
    /// redraw the "keep only the confirmed slices" ceiling is fiction: every frame of
    /// the session would still be resident, which is gigabytes after a few minutes.
    private static func detached(_ image: CGImage) -> CGImage? {
        guard let ctx = newContext(width: image.width, height: image.height) else { return nil }
        ctx.draw(image, in: CGRect(x: 0, y: 0, width: image.width, height: image.height))
        return ctx.makeImage()
    }

    /// An opaque 8-bit sRGB bitmap context. Screen content has no transparency, so
    /// an ignored alpha channel avoids premultiplication rounding on every redraw
    /// and lets the final PNG be written without an alpha plane.
    private static func newContext(width: Int, height: Int) -> CGContext? {
        CGContext(data: nil, width: width, height: height,
                  bitsPerComponent: 8, bytesPerRow: 0,
                  space: CGColorSpace(name: CGColorSpace.sRGB) ?? CGColorSpaceCreateDeviceRGB(),
                  bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue)
    }
}
