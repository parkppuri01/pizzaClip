import SwiftUI
import AppKit

/// pizzaClip brand palette, pulled from the project color chart:
///   포인트 #A2371F (brick red) · 메뉴 #FFB703 (amber) · 폰트 #102138 (navy)
///
/// The popup is a translucent HUD panel that follows the system appearance, so
/// the two brand colors are defined as *adaptive* pairs: a richer/darker value
/// for Light mode (readable on bright glass) and a brighter value for Dark mode
/// (vivid on dark glass). The split keeps small accent text legible in both.
enum AppColors {
    /// Primary brand accent — brick red. Drives selection, the app tint, and the
    /// footer action words. Lightened to a vivid terracotta in Dark mode.
    static let accent = Color(light: 0xA2371F, dark: 0xD55C38)

    /// Playful gold — the numeric slot badges and the pin marker. Used as *text /
    /// stroke*, so it's deepened to a readable goldenrod on light glass and kept
    /// bright on dark glass.
    static let amber = Color(light: 0xB57500, dark: 0xFFB703)

    /// Bright amber for *filled* chips (e.g. the "0" full-paste badge). Stays
    /// bright in both modes since dark navy text sits on top of it.
    static let amberFill = Color(light: 0xF5A800, dark: 0xFFB703)

    /// Deep navy ink — used as the label *on* the bright amber chip.
    static let inkOnAmber = Color(hex: 0x102138)

    // System-derived neutrals — already adapt to light/dark on their own.
    static let separator = Color(NSColor.separatorColor)
    static let secondaryLabel = Color(NSColor.secondaryLabelColor)
    static let tertiaryLabel = Color(NSColor.tertiaryLabelColor)
}

extension Color {
    /// Solid color from a `0xRRGGBB` literal.
    init(hex: Int) {
        self.init(
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255
        )
    }

    /// Appearance-adaptive color: `light` under Aqua, `dark` under Dark Aqua.
    /// Re-resolves whenever the rendering view's effective appearance flips, so a
    /// single declaration covers both day and night mode.
    init(light: Int, dark: Int) {
        self.init(nsColor: NSColor(name: nil) { appearance in
            let isDark = appearance.bestMatch(from: [.aqua, .darkAqua]) == .darkAqua
            let hex = isDark ? dark : light
            return NSColor(
                red: CGFloat((hex >> 16) & 0xFF) / 255,
                green: CGFloat((hex >> 8) & 0xFF) / 255,
                blue: CGFloat(hex & 0xFF) / 255,
                alpha: 1
            )
        })
    }
}
