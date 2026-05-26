import AppKit

/// Status-bar icon that reflects the number of items in clipboard history.
///
/// Maps history count → pre-rendered PNG in Assets.xcassets:
///   0     → PizzaIcon0 (empty)
///   1…8   → PizzaIcon1…PizzaIcon8 (1 through 8 slices)
///   9+    → PizzaIcon9 (full pizza, overflow)
///
/// Loaded as `template-rendering-intent: original` so the painted cheese/crust
/// colors survive instead of being collapsed by the menu-bar template tint.
enum PizzaIcon {
    static let defaultPointSize: CGFloat = 18

    static func image(forCount count: Int, size: CGFloat = defaultPointSize) -> NSImage {
        let n = max(0, min(9, count))
        let name = "PizzaIcon\(n)"
        let image = NSImage(named: name) ?? NSImage(size: NSSize(width: size, height: size))
        image.size = NSSize(width: size, height: size)
        image.isTemplate = false
        image.accessibilityDescription = "pizzaClip — \(count) items"
        return image
    }
}
