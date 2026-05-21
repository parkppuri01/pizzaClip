import AppKit

public protocol Pasteboard: AnyObject {
    var changeCount: Int { get }
    func types() -> [NSPasteboard.PasteboardType]
    func data(forType type: NSPasteboard.PasteboardType) -> Data?
    func string(forType type: NSPasteboard.PasteboardType) -> String?
}

extension NSPasteboard: Pasteboard {
    public func types() -> [NSPasteboard.PasteboardType] {
        self.types ?? []
    }
}
