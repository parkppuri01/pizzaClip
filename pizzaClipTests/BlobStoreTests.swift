import XCTest
import AppKit
@testable import pizzaClip

final class BlobStoreTests: XCTestCase {
    private func tmpDir() -> URL {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("blobstore-\(UUID().uuidString)")
        try? FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }

    func test_writePNG_storesFileAndProducesThumbnail() throws {
        let store = BlobStore(rootDirectory: tmpDir())
        let image = NSImage(size: NSSize(width: 800, height: 600))
        image.lockFocus()
        NSColor.red.setFill()
        NSRect(x: 0, y: 0, width: 800, height: 600).fill()
        image.unlockFocus()

        let png = try XCTUnwrap(image.pngData())

        let written = try store.write(png: png)
        XCTAssertTrue(FileManager.default.fileExists(atPath: written.fileURL.path))
        XCTAssertNotNil(written.thumbnailPNG)
        XCTAssertLessThan(written.thumbnailPNG.count, 60_000)
    }

    func test_remove_deletesFile() throws {
        let store = BlobStore(rootDirectory: tmpDir())
        let written = try store.write(png: Data([0x89, 0x50, 0x4E, 0x47])) // not valid PNG, ok for round-trip
        try store.remove(relativePath: written.relativePath)
        XCTAssertFalse(FileManager.default.fileExists(atPath: written.fileURL.path))
    }
}

private extension NSImage {
    func pngData() -> Data? {
        guard let tiff = tiffRepresentation,
              let rep = NSBitmapImageRep(data: tiff) else { return nil }
        return rep.representation(using: .png, properties: [:])
    }
}
