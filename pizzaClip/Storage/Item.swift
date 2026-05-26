import Foundation
import GRDB

public struct Item: Identifiable, Equatable, FetchableRecord, PersistableRecord, Codable {
    public static let databaseTableName = "items"

    public var id: String        // UUID string
    public var type: String      // "text" | "image" | "file"
    public var text: String?     // body or absolute file path
    public var blobPath: String? // relative path under blobs/
    public var thumbPng: Data?   // image only
    public var sourceBundle: String?
    public var createdAt: Int64  // unix ms
    public var pinned: Bool

    enum Columns {
        static let id = Column("id")
        static let type = Column("type")
        static let text = Column("text")
        static let blobPath = Column("blob_path")
        static let thumbPng = Column("thumb_png")
        static let sourceBundle = Column("source_bundle")
        static let createdAt = Column("created_at")
        static let pinned = Column("pinned")
    }

    enum CodingKeys: String, CodingKey {
        case id
        case type
        case text
        case blobPath = "blob_path"
        case thumbPng = "thumb_png"
        case sourceBundle = "source_bundle"
        case createdAt = "created_at"
        case pinned
    }
}
