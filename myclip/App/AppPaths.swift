import Foundation

enum AppPaths {
    static let storageDirectoryDefaultsKey = "storageDirectory"

    static var supportDirectory: URL {
        let dir: URL
        if let custom = UserDefaults.standard.string(forKey: storageDirectoryDefaultsKey),
           !custom.isEmpty {
            dir = URL(fileURLWithPath: (custom as NSString).expandingTildeInPath, isDirectory: true)
        } else {
            let base = FileManager.default.urls(for: .applicationSupportDirectory,
                                                in: .userDomainMask).first!
            dir = base.appendingPathComponent("myclip", isDirectory: true)
        }
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }

    static var databaseURL: URL { supportDirectory.appendingPathComponent("db.sqlite") }
    static var blobsDirectory: URL { supportDirectory.appendingPathComponent("blobs", isDirectory: true) }
}
