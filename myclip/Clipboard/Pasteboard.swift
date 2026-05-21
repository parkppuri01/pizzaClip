import AppKit

public protocol PasteboardReader: AnyObject {
    var changeCount: Int { get }
    func types() -> [NSPasteboard.PasteboardType]
    func data(forType type: NSPasteboard.PasteboardType) -> Data?
    func string(forType type: NSPasteboard.PasteboardType) -> String?
}

extension NSPasteboard: PasteboardReader {
    public func types() -> [NSPasteboard.PasteboardType] {
        self.types ?? []
    }
}
