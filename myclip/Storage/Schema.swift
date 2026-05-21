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
        m.registerMigration("v2-fts5") { db in
            try db.execute(sql: """
                CREATE VIRTUAL TABLE items_fts USING fts5(text, content='items', content_rowid='rowid');
                INSERT INTO items_fts(rowid, text) SELECT rowid, text FROM items WHERE text IS NOT NULL;

                CREATE TRIGGER items_ai AFTER INSERT ON items BEGIN
                  INSERT INTO items_fts(rowid, text) VALUES (new.rowid, new.text);
                END;
                CREATE TRIGGER items_ad AFTER DELETE ON items BEGIN
                  INSERT INTO items_fts(items_fts, rowid, text) VALUES('delete', old.rowid, old.text);
                END;
                CREATE TRIGGER items_au AFTER UPDATE ON items BEGIN
                  INSERT INTO items_fts(items_fts, rowid, text) VALUES('delete', old.rowid, old.text);
                  INSERT INTO items_fts(rowid, text) VALUES (new.rowid, new.text);
                END;
            """)
        }
        return m
    }
}
