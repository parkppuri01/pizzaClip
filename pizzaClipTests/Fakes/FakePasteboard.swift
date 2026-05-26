import AppKit
@testable import pizzaClip

final class FakePasteboard: PasteboardReader {
    private(set) var changeCount: Int = 0
    private var contents: [NSPasteboard.PasteboardType: Data] = [:]
    private var strings: [NSPasteboard.PasteboardType: String] = [:]

    func put(string: String, type: NSPasteboard.PasteboardType) {
        strings[type] = string
        contents[type] = Data(string.utf8)
        changeCount += 1
    }

    func put(data: Data, type: NSPasteboard.PasteboardType) {
        contents[type] = data
        strings.removeValue(forKey: type)
        changeCount += 1
    }

    func clear() {
        contents.removeAll()
        strings.removeAll()
        changeCount += 1
    }

    func types() -> [NSPasteboard.PasteboardType] { Array(contents.keys) }
    func data(forType type: NSPasteboard.PasteboardType) -> Data? { contents[type] }
    func string(forType type: NSPasteboard.PasteboardType) -> String? { strings[type] }
}
