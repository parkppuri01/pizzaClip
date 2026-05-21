import Foundation
import GRDB

public final class HistoryStore {
    private let queue: DatabaseWriter
    private let blobStore: BlobStore?

    public init(queue: DatabaseWriter, blobStore: BlobStore? = nil) throws {
        self.queue = queue
        self.blobStore = blobStore
        try Schema.migrator().migrate(queue)
    }

    public func insert(_ captured: CapturedItem) throws {
        let capturedMs = Int64(captured.createdAt.timeIntervalSince1970 * 1000)

        var blobRelative: String? = nil
        var thumb: Data? = nil
        if captured.kind == .image, let png = captured.imageData, let store = blobStore {
            let written = try store.write(png: png)
            blobRelative = written.relativePath
            thumb = written.thumbnailPNG
        }

        try queue.write { db in
            // Dedupe: bump the timestamp on an existing non-pinned text row with the
            // same body rather than inserting a duplicate.
            if captured.kind == .text, let text = captured.text {
                if let existing = try Item
                    .filter(Item.Columns.type == "text"
                            && Item.Columns.text == text
                            && Item.Columns.pinned == false)
                    .order(Item.Columns.createdAt.desc)
                    .fetchOne(db) {
                    var bumped = existing
                    bumped.createdAt = capturedMs
                    try bumped.update(db)
                    return
                }
            }

            let row = Item(
                id: captured.id.uuidString,
                type: captured.kind.rawValue,
                text: captured.text,
                blobPath: blobRelative,
                thumbPng: thumb,
                sourceBundle: captured.sourceBundleID,
                createdAt: capturedMs,
                pinned: false
            )
            try row.insert(db)
        }
    }

    public func topN(_ n: Int) throws -> [Item] {
        try queue.read { db in
            try Item.order(Item.Columns.createdAt.desc).limit(n).fetchAll(db)
        }
    }

    public func topNNonPinned(_ n: Int) throws -> [Item] {
        try queue.read { db in
            try Item
                .filter(Item.Columns.pinned == false)
                .order(Item.Columns.createdAt.desc)
                .limit(n)
                .fetchAll(db)
        }
    }

    public func topNRespectingPins(_ n: Int) throws -> [Item] {
        try queue.read { db in
            try Item
                .order(Item.Columns.pinned.desc, Item.Columns.createdAt.desc)
                .limit(n)
                .fetchAll(db)
        }
    }

    public func delete(id: String) throws {
        try queue.write { db in
            if let item = try Item.fetchOne(db, key: id) {
                if let path = item.blobPath { try? blobStore?.remove(relativePath: path) }
                _ = try Item.deleteOne(db, key: id)
            }
        }
    }

    public func togglePin(id: String) throws {
        try queue.write { db in
            guard var item = try Item.fetchOne(db, key: id) else { return }
            item.pinned.toggle()
            try item.update(db)
        }
    }

    public func prune(cap: Int) throws {
        try queue.write { db in
            // Fetch only id + blob_path so we don't pull kilobytes of thumb_png
            // BLOBs into memory just to drop the tail.
            let stale = try Row.fetchAll(db, sql: """
                SELECT id, blob_path FROM items
                WHERE pinned = 0
                ORDER BY created_at DESC
                LIMIT -1 OFFSET ?
                """, arguments: [cap])
            for row in stale {
                if let path: String = row["blob_path"] {
                    try? blobStore?.remove(relativePath: path)
                }
                let id: String = row["id"]
                _ = try Item.deleteOne(db, key: id)
            }
        }
    }

    public func clearAll() throws {
        try queue.write { db in
            let paths = try String.fetchAll(db, sql: """
                SELECT blob_path FROM items WHERE blob_path IS NOT NULL
                """)
            for path in paths { try? blobStore?.remove(relativePath: path) }
            try Item.deleteAll(db)
        }
    }

    public func search(_ query: String, limit: Int) throws -> [Item] {
        let trimmed = query.trimmingCharacters(in: .whitespaces)
        if trimmed.isEmpty { return try topNRespectingPins(limit) }

        let escaped = trimmed.replacingOccurrences(of: "\"", with: "\"\"")
        let ftsQuery = "\"\(escaped)\"*"  // prefix match, quoted to defang FTS5 operators

        return try queue.read { db in
            try Item.fetchAll(db, sql: """
                SELECT items.* FROM items
                JOIN items_fts ON items_fts.rowid = items.rowid
                WHERE items_fts MATCH ?
                ORDER BY items.pinned DESC, items.created_at DESC
                LIMIT ?
                """, arguments: [ftsQuery, limit])
        }
    }
}
