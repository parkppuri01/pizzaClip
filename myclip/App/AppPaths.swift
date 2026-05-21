import Foundation

enum AppPaths {
    static var supportDirectory: URL {
        let base = FileManager.default.urls(for: .applicationSupportDirectory,
                                            in: .userDomainMask).first!
        let dir = base.appendingPathComponent("myclip", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }
    static var databaseURL: URL { supportDirectory.appendingPathComponent("db.sqlite") }
    static var blobsDirectory: URL { supportDirectory.appendingPathComponent("blobs", isDirectory: true) }
}
