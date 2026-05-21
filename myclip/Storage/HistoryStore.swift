import Foundation
import GRDB
import Combine

public final class HistoryStore {
    private let queue: DatabaseWriter
    @Published public private(set) var snapshot: [Item] = []

    public init(queue: DatabaseWriter) throws {
        self.queue = queue
        try Schema.migrator().migrate(queue)
        try reloadSnapshot()
    }

    public func insert(_ captured: CapturedItem) throws {
        let capturedMs = Int64(captured.createdAt.timeIntervalSince1970 * 1000)

        try queue.write { db in
            // Dedupe rule: if newest non-pinned text item has the same body, just bump its timestamp.
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
                blobPath: nil,            // BlobStore wires this up in Task 6
                thumbPng: nil,
                sourceBundle: captured.sourceBundleID,
                createdAt: capturedMs,
                pinned: false
            )
            try row.insert(db)
        }
        try reloadSnapshot()
    }

    public func topN(_ n: Int) throws -> [Item] {
        try queue.read { db in
            try Item
                .order(Item.Columns.createdAt.desc)
                .limit(n)
                .fetchAll(db)
        }
    }

    public func delete(id: String) throws {
        try queue.write { db in
            _ = try Item.deleteOne(db, key: id)
        }
        try reloadSnapshot()
    }

    public func togglePin(id: String) throws {
        try queue.write { db in
            guard var item = try Item.fetchOne(db, key: id) else { return }
            item.pinned.toggle()
            try item.update(db)
        }
        try reloadSnapshot()
    }

    public func topNRespectingPins(_ n: Int) throws -> [Item] {
        try queue.read { db in
            try Item
                .order(Item.Columns.pinned.desc, Item.Columns.createdAt.desc)
                .limit(n)
                .fetchAll(db)
        }
    }

    public func prune(cap: Int) throws {
        try queue.write { db in
            let nonPinned = try Item
                .filter(Item.Columns.pinned == false)
                .order(Item.Columns.createdAt.desc)
                .fetchAll(db)
            guard nonPinned.count > cap else { return }
            let toDelete = nonPinned[cap...]
            for item in toDelete {
                // BlobStore cleanup wires in Task 6
                _ = try Item.deleteOne(db, key: item.id)
            }
        }
        try reloadSnapshot()
    }

    private func reloadSnapshot() throws {
        snapshot = try topN(500)
    }
}
