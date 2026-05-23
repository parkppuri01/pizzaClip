import AppKit

/// Status-bar icon rendered with Core Graphics — no PNG assets.
///
/// The icon represents the number of items currently in clipboard history:
///   0     → just the crust ring (no slices yet)
///   1…8   → that many beige slice wedges placed clockwise from 12 o'clock
///   9+    → closed pizza box (overflow, history is full)
///
/// Empty wedges are left fully transparent so the menu-bar background shows
/// through — that's the "그냥 그부분이 비어있도록" the user asked for.
/// Colors are hard-coded here rather than going through DesignSystem so the
/// icon stays self-contained and trivial to tweak.
enum PizzaIcon {
    static let defaultPointSize: CGFloat = 18

    private static let crust   = NSColor(srgbRed: 0.91, green: 0.72, blue: 0.38, alpha: 1).cgColor
    private static let slice   = NSColor(srgbRed: 0.96, green: 0.83, blue: 0.55, alpha: 1).cgColor
    private static let divider = NSColor(srgbRed: 0.40, green: 0.25, blue: 0.10, alpha: 0.45).cgColor
    private static let box     = NSColor(srgbRed: 0.84, green: 0.62, blue: 0.35, alpha: 1).cgColor
    private static let boxSeam = NSColor(srgbRed: 0.50, green: 0.34, blue: 0.16, alpha: 1).cgColor

    /// Builds the icon for the given history item count.
    static func image(forCount count: Int, size: CGFloat = defaultPointSize) -> NSImage {
        let n = max(0, count)
        let image = NSImage(size: NSSize(width: size, height: size), flipped: false) { rect in
            guard let ctx = NSGraphicsContext.current?.cgContext else { return false }
            if n >= 9 {
                drawBox(ctx, in: rect)
            } else {
                drawPizza(ctx, in: rect, filled: n)
            }
            return true
        }
        image.accessibilityDescription = "myclip — \(n) items"
        return image
    }

    // MARK: - Pizza

    private static func drawPizza(_ ctx: CGContext, in rect: CGRect, filled n: Int) {
        let r = rect.insetBy(dx: 1, dy: 1)
        let center = CGPoint(x: r.midX, y: r.midY)
        let outerR = r.width / 2
        let innerR = outerR * 0.82          // crust thickness ≈ 18% of radius
        let wedge:  CGFloat = .pi / 4       // 45°

        // Beige slice wedges — clockwise from 12 o'clock. Each filled wedge i
        // spans [trailing, leading] in math (y-up) angle space; CG with
        // clockwise=true sweeps decreasing-angle, so leading→trailing visually
        // traces the wedge through the inner arc.
        //
        // Empty wedges are intentionally NOT drawn — they stay fully
        // transparent so the menu-bar background shows through, matching the
        // user's "missing slice = empty hole" mental model.
        if n > 0 {
            ctx.setFillColor(slice)
            for i in 0..<n {
                let leading  = .pi / 2 + wedge / 2 - CGFloat(i) * wedge
                let trailing = leading - wedge
                ctx.beginPath()
                ctx.move(to: center)
                ctx.addArc(center: center, radius: innerR,
                           startAngle: leading, endAngle: trailing, clockwise: true)
                ctx.closePath()
                ctx.fillPath()
            }
        }

        // Crust ring — drawn as an annulus on top of the slices so the slice
        // wedges look tucked inside the crust rather than overlapping it.
        ctx.setFillColor(crust)
        ctx.beginPath()
        ctx.addEllipse(in: r)
        ctx.addEllipse(in: CGRect(x: center.x - innerR, y: center.y - innerR,
                                  width: innerR * 2, height: innerR * 2))
        ctx.fillPath(using: .evenOdd)

        // Dividers between adjacent filled slices so e.g. n=3 reads as "3
        // slices" not "one 135° pie chunk". We draw only the n+1 spokes that
        // border the filled region — drawing all 8 would put faint spokes
        // into empty wedges and make n=0 look like a wheel.
        if n > 0 {
            ctx.setStrokeColor(divider)
            ctx.setLineWidth(0.5)
            for i in 0...n {
                let a = .pi / 2 + wedge / 2 - CGFloat(i) * wedge
                ctx.beginPath()
                ctx.move(to: center)
                ctx.addLine(to: CGPoint(x: center.x + innerR * cos(a),
                                        y: center.y + innerR * sin(a)))
                ctx.strokePath()
            }
        }
    }

    // MARK: - Box (overflow state)

    private static func drawBox(_ ctx: CGContext, in rect: CGRect) {
        // Rounded rectangle with a horizontal seam ~2/3 up the body to suggest
        // a closed pizza-box lid. Intentionally austere — at 22pt anything
        // more elaborate (text on the lid, perspective, etc.) just smudges.
        let r = rect.insetBy(dx: 1.5, dy: 3)
        ctx.setFillColor(box)
        ctx.addPath(CGPath(roundedRect: r, cornerWidth: 1.5, cornerHeight: 1.5, transform: nil))
        ctx.fillPath()

        let seamY = r.minY + r.height * 0.66
        ctx.setStrokeColor(boxSeam)
        ctx.setLineWidth(0.7)
        ctx.beginPath()
        ctx.move(to: CGPoint(x: r.minX + 1, y: seamY))
        ctx.addLine(to: CGPoint(x: r.maxX - 1, y: seamY))
        ctx.strokePath()
    }
}
