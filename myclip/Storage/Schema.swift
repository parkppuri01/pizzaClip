import GRDB

enum Schema {
    static func migrator() -> DatabaseMigrator {
        var m = DatabaseMigrator()
        m.registerMigration("v1") { db in
            try db.create(table: "items") { t in
                t.column("id", .text).primaryKey()
                t.column("type", .text).notNull()
                t.column("text", .text)
                t.column("blob_path", .text)
                t.column("thumb_png", .blob)
                t.column("source_bundle", .text)
                t.column("created_at", .integer).notNull()
                t.column("pinned", .integer).notNull().defaults(to: 0)
            }
            try db.execute(sql: """
                CREATE INDEX idx_items_created ON items(created_at DESC);
                CREATE INDEX idx_items_pinned  ON items(pinned, created_at DESC);
            """)
        }
        return m
    }
}
