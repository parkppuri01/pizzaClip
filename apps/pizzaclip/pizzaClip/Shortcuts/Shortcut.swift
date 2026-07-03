import KeyboardShortcuts

extension KeyboardShortcuts.Name {
    static let togglePopup = Self("togglePopup", default: .init(.v, modifiers: [.command, .shift]))

    static func slot(_ n: Int) -> Self {
        let digit: KeyboardShortcuts.Key
        switch n {
        case 1: digit = .one
        case 2: digit = .two
        case 3: digit = .three
        case 4: digit = .four
        case 5: digit = .five
        case 6: digit = .six
        case 7: digit = .seven
        case 8: digit = .eight
        case 9: digit = .nine
        default: return Self("slot\(n)")
        }
        return Self("slot\(n)", default: .init(digit, modifiers: [.command, .option, .control]))
    }
}
