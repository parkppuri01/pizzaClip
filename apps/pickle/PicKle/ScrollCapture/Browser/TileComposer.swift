import CoreGraphics

/// Assembles browser tiles by coordinate.
///
/// The manual stitcher has to *discover* how far the page moved and can be wrong;
/// here the page told us, so a tile's position on the canvas is arithmetic:
/// `round(y × pxPerCss)`. There is no registration, no guard, no pending band and
/// no seam — the failure modes those exist to contain cannot occur.
///
/// The only real work is deciding how much of each tile's **top** to throw away.
/// Tiles deliberately overlap by `pad`, because a page's sticky header repaints at
/// the top of every single tile and would otherwise be stamped down the middle of
/// the finished image once per tile.
enum TileComposer {

    /// One captured frame plus the scroll offset it was taken at.
    struct Tile {
        let image: CGImage
        /// Scroll offset the page reported for this frame, in CSS pixels.
        let y: Double
    }

    /// Just the numbers a layout needs. Deliberately image-free: `compose` works out
    /// the whole layout from these and then releases each tile as it draws it, which
    /// it could not do if the layout input were still holding every `CGImage`.
    struct Geometry {
        let y: Double
        let width: Int
        let height: Int
    }

    /// Where a tile ends up, in canvas pixels. Split out from the drawing so the
    /// layout can be asserted directly (harness scenario C) without allocating a
    /// 30,000px canvas.
    struct Placement {
        let index: Int
        /// Canvas row the tile's own row 0 is drawn at. Normally the tile's true
        /// coordinate; pulled up to the paint frontier when honouring the true one
        /// would leave a gap (see `Layout.gapPixels`).
        let top: Int
        /// Rows discarded from the top of the tile: pinned chrome plus whatever
        /// the previous tile already covered.
        let cut: Int
        /// First canvas row this tile paints (`top + cut`).
        var drawTop: Int { top + cut }
    }

    struct Layout {
        let placements: [Placement]
        let width: Int
        let height: Int
        /// Tiles left out: a size mismatch, or everything past the height ceiling.
        let droppedTiles: Int
        /// Tiles skipped because an earlier one already covered all of them — a
        /// duplicate offset, or a step smaller than the overlap. Not a fault.
        let redundantTiles: Int
        /// Rows that would have been left unpainted had every tile been placed at
        /// its true coordinate, and that were closed by pulling tiles up instead.
        /// Non-zero means the step overshot what the region can actually show, and
        /// the image now duplicates that many rows rather than showing a black band.
        let gapPixels: Int
    }

    /// Work out where every tile lands.
    ///
    /// The rule is one line — **each tile contributes only the rows no earlier tile
    /// already painted** — and it does three jobs at once:
    ///
    /// * The sticky header is discarded. Tiles are captured a `pad` apart *less* than
    ///   a screenful precisely so that the overlap is taller than the pinned chrome;
    ///   cutting the overlap therefore always cuts the header with it, and the copy
    ///   that survives is the earlier tile's — which shows the real content that the
    ///   header is sitting on top of in the later one.
    /// * There is no gap and no double-write, by construction: every tile starts
    ///   exactly at the paint frontier. A pad-sized fixed cut can't promise that,
    ///   because `round(y × pxPerCss)` for two tiles a step apart can land a pixel
    ///   further apart than the step, and that pixel would be an unpainted line
    ///   straight across the finished image.
    /// * The last tile needs no special case. The page clamps the final request at
    ///   its own bottom, so that tile overlaps its predecessor by an arbitrary amount
    ///   — which is just a larger cut.
    ///
    /// - Parameters:
    ///   - geometry: in capture order, `y` non-decreasing.
    ///   - pxPerCss: measured once per session (see `BrowserScrollSession`).
    ///   - maxHeightPixels: the shared 30,000px safety ceiling.
    static func layout(_ geometry: [Geometry], pxPerCss: Double, maxHeightPixels: Int) -> Layout? {
        guard let firstTile = geometry.first else { return nil }
        let width = firstTile.width
        // Positions are relative to the first tile, not to the page origin: a page
        // that refuses to scroll all the way back to 0 (a scroll-snap container, an
        // anchor link) still produces a correctly assembled image, just one that
        // starts where the capture did.
        let baseY = firstTile.y
        var placements: [Placement] = []
        var covered = 0
        var dropped = 0
        var redundant = 0
        var gap = 0

        for (index, tile) in geometry.enumerated() {
            guard tile.width == width else { dropped += 1; continue }
            let height = tile.height
            let trueTop = index == 0 ? 0 : Int(((tile.y - baseY) * pxPerCss).rounded())
            // Second line of defence. If the page moved further than the region can
            // show — the region is shorter than the viewport, or the page reflowed —
            // the tile's true coordinate sits below what has been painted, and
            // honouring it would leave a black band. Pull the tile up to the frontier
            // instead: some rows get shown twice, which is a far smaller lie than a
            // hole, and the amount is reported so it can't pass unnoticed.
            let top = min(trueTop, covered)
            gap += max(0, trueTop - covered)
            let cut = max(0, covered - top)
            // Entirely behind the paint frontier — a duplicate offset, or a step so
            // small the previous tile already showed all of it.
            guard cut < height else { redundant += 1; continue }
            guard top + height <= maxHeightPixels else {
                dropped += geometry.count - index
                break
            }
            placements.append(Placement(index: index, top: top, cut: cut))
            covered = top + height
        }
        guard !placements.isEmpty else { return nil }
        return Layout(placements: placements, width: width, height: covered,
                      droppedTiles: dropped, redundantTiles: redundant, gapPixels: gap)
    }

    /// Convenience for callers that already hold the tiles (the offline harness).
    static func layout(tiles: [Tile], pxPerCss: Double, maxHeightPixels: Int) -> Layout? {
        layout(tiles.map { Geometry(y: $0.y, width: $0.image.width, height: $0.image.height) },
               pxPerCss: pxPerCss, maxHeightPixels: maxHeightPixels)
    }

    /// Draw the tiles onto one canvas. `tiles` is emptied as it goes, and nothing
    /// else holds a reference: a session that scrolled a long page is already holding
    /// the finished image in pieces, so every tile still alive when the canvas is
    /// allocated is a second copy of that much memory.
    static func compose(tiles: inout [Tile?], pxPerCss: Double,
                        maxHeightPixels: Int) -> CGImage? {
        var geometry: [Geometry] = []
        geometry.reserveCapacity(tiles.count)
        for tile in tiles {
            guard let tile else { return nil }
            geometry.append(Geometry(y: tile.y, width: tile.image.width, height: tile.image.height))
        }
        guard let layout = layout(geometry, pxPerCss: pxPerCss, maxHeightPixels: maxHeightPixels),
              let ctx = newContext(width: layout.width, height: layout.height) else { return nil }
        for placement in layout.placements {
            guard let tile = tiles[placement.index] else { continue }
            let height = tile.image.height
            let keep = height - placement.cut
            // `cropping(to:)` measures from the image's TOP-left corner (proven in
            // the harness), so cutting the top is a rect at y = cut.
            if keep >= 1,
               let visible = tile.image.cropping(to: CGRect(x: 0, y: placement.cut,
                                                            width: layout.width, height: keep)) {
                // CGContext draws from the bottom-left; canvas rows count from the top.
                ctx.draw(visible, in: CGRect(x: 0, y: layout.height - placement.drawTop - keep,
                                             width: layout.width, height: keep))
            }
            // Released here, not at the end: the canvas is already allocated, so this
            // is exactly where holding the whole tile set would cost the most.
            tiles[placement.index] = nil
        }
        for index in tiles.indices { tiles[index] = nil }
        return ctx.makeImage()
    }

    /// An opaque 8-bit sRGB bitmap context — the same surface the manual stitcher
    /// composes into, so both paths write PNGs with identical colour handling.
    private static func newContext(width: Int, height: Int) -> CGContext? {
        CGContext(data: nil, width: width, height: height,
                  bitsPerComponent: 8, bytesPerRow: 0,
                  space: CGColorSpace(name: CGColorSpace.sRGB) ?? CGColorSpaceCreateDeviceRGB(),
                  bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue)
    }
}
