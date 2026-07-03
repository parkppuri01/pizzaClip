import Foundation
import GRDB

public extension Notification.Name {
    /// Posted on the main thread whenever the persisted history changes via
    /// `insert`, `delete`, `togglePin`, or `clearAll`. `prune` does not fire
    /// its own notification because it is always called immediately after
    /// `insert` from the monitor's onCapture closure.
    static let pizzaClipHistoryChanged = Notification.Name("pizzaClipHistoryChanged")
}

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

        // Cheap path: bump an existing non-pinned row's timestamp when the
        // payload matches one we already have, instead of inserting a near-
        // identical duplicate. Generalised over kinds:
        //   - text  → same body text
        //   - file  → same absolute path
        //   - image → same source path (Finder copy); pure screenshots have
        //             no text and skip this (each capture is independent).
        // The file/image branch also matters because macOS sometimes emits
        // two pasteboard changeCount increments for a single Finder copy —
        // one carrying the resolved path, one the `.file/id=` ref URL. With
        // both ticks producing the same resolved path, this dedupes them.
        if let payload = captured.text, !payload.isEmpty {
            let kindRaw = captured.kind.rawValue
            let didBump: Bool = try queue.write { db in
                if let existing = try Item
                    .filter(Item.Columns.type == kindRaw
                            && Item.Columns.text == payload
                            && Item.Columns.pinned == false)
                    .order(Item.Columns.createdAt.desc)
                    .fetchOne(db) {
                    var row = existing
                    row.createdAt = capturedMs
                    try row.update(db)
                    return true
                }
                return false
            }
            if didBump {
                broadcastChange()
                return
            }
        }

        var blobRelative: String? = nil
        var thumb: Data? = nil
        if captured.kind == .image, let data = captured.imageData, let store = blobStore {
            // Pull the file extension from the source path when this came from
            // a Finder file copy (JPG/HEIC/GIF/…). For pure clipboard image
            // payloads (screenshots, in-memory image data) there's no path so
            // we default to PNG, which is what NSPasteboard.PasteboardType.png
            // delivers.
            let ext: String = {
                if let path = captured.text, !path.isEmpty {
                    let e = (path as NSString).pathExtension.lowercased()
                    if !e.isEmpty { return e }
                }
                return "png"
            }()
            let written = try store.write(data: data, fileExtension: ext)
            blobRelative = written.relativePath
            thumb = written.thumbnailPNG
        }

        try queue.write { db in
            let row = Item(
                id: captured.id.uuidString,
                type: captured.kind.rawValue,
                text: captured.text,
                blobPath: blobRelative,
                thumbPng: thumb,
                sourceBundle: captured.sourceBundleID,
                createdAt: capturedMs,
                pinned: false,
                pinnedAt: nil
            )
            try row.insert(db)
        }
        broadcastChange()
    }

    public func topN(_ n: Int) throws -> [Item] {
        try queue.read { db in
            try Item.order(Item.Columns.createdAt.desc).limit(n).fetchAll(db)
        }
    }

    /// Total number of rows. Cheap — runs a single SELECT COUNT(*). Used by
    /// the status bar to pick the right pizza-icon state.
    public func count() throws -> Int {
        try queue.read { db in try Item.fetchCount(db) }
    }

    public func topNRespectingPins(_ n: Int) throws -> [Item] {
        try queue.read { db in
            // Pinned items first, ordered by *when* they were pinned (earliest
            // pin = slot 1), then non-pinned by recency. This is the exact
            // order the popup numbers its slots in.
            try Item
                .order(Item.Columns.pinned.desc,
                       Item.Columns.pinnedAt.asc,
                       Item.Columns.createdAt.desc)
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
        broadcastChange()
    }

    public func togglePin(id: String) throws {
        try queue.write { db in
            guard var item = try Item.fetchOne(db, key: id) else { return }
            item.pinned.toggle()
            // Stamp the pin time so multiple pins keep a stable slot order
            // (first-pinned = slot 1). Cleared on unpin.
            item.pinnedAt = item.pinned ? Int64(Date().timeIntervalSince1970 * 1000) : nil
            try item.update(db)
        }
        broadcastChange()
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
        broadcastChange()
    }

    private func broadcastChange() {
        if Thread.isMainThread {
            NotificationCenter.default.post(name: .pizzaClipHistoryChanged, object: nil)
        } else {
            DispatchQueue.main.async {
                NotificationCenter.default.post(name: .pizzaClipHistoryChanged, object: nil)
            }
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
