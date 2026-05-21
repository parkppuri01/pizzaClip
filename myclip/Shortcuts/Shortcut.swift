import KeyboardShortcuts

extension KeyboardShortcuts.Name {
    static let togglePopup = Self("togglePopup", default: .init(.v, modifiers: [.command, .shift]))
    static func slot(_ n: Int) -> Self { Self("slot\(n)") }
}
