import Foundation

public enum CapturedKind: String, Codable {
    case text, image, file
}

public struct CapturedItem: Equatable {
    public let id: UUID
    public let kind: CapturedKind
    public let text: String?         // text → body; file → absolute path
    public let imageData: Data?      // image → PNG bytes
    public let sourceBundleID: String?
    public let createdAt: Date

    public init(id: UUID = UUID(),
                kind: CapturedKind,
                text: String? = nil,
                imageData: Data? = nil,
                sourceBundleID: String? = nil,
                createdAt: Date = Date()) {
        self.id = id
        self.kind = kind
        self.text = text
        self.imageData = imageData
        self.sourceBundleID = sourceBundleID
        self.createdAt = createdAt
    }
}
