import Foundation
import AppKit

public struct WrittenBlob {
    public let relativePath: String   // e.g. "ab/abc...uuid.png"
    public let fileURL: URL
    public let thumbnailPNG: Data
}

public final class BlobStore {
    public let rootDirectory: URL

    public init(rootDirectory: URL) {
        self.rootDirectory = rootDirectory
        try? FileManager.default.createDirectory(at: rootDirectory,
                                                 withIntermediateDirectories: true)
    }

    /// Convenience for PNG payloads — the common case for screenshots / clipboard
    /// image data that's already PNG-encoded.
    public func write(png: Data) throws -> WrittenBlob {
        try write(data: png, fileExtension: "png")
    }

    /// Writes arbitrary image bytes verbatim with the supplied extension.
    /// Used for Finder-copied image files so we don't re-encode JPG/HEIC/etc.
    /// to PNG (which can 10× the storage size and drop alpha/animation).
    /// Thumbnail is always PNG (small, alpha-supporting, universal).
    public func write(data: Data, fileExtension: String) throws -> WrittenBlob {
        let id = UUID().uuidString
        let ext = fileExtension.lowercased().isEmpty ? "png" : fileExtension.lowercased()
        let relative = "\(id).\(ext)"
        let url = rootDirectory.appendingPathComponent(relative)
        try data.write(to: url)
        let thumb = makeThumbnail(from: data) ?? Data()
        return WrittenBlob(relativePath: relative, fileURL: url, thumbnailPNG: thumb)
    }

    public func remove(relativePath: String) throws {
        let url = rootDirectory.appendingPathComponent(relativePath)
        try FileManager.default.removeItem(at: url)
    }

    private func makeThumbnail(from data: Data) -> Data? {
        guard let img = NSImage(data: data) else { return nil }
        let maxSide: CGFloat = 256
        let size = img.size
        let scale = min(maxSide / max(size.width, 1), maxSide / max(size.height, 1), 1)
        let targetW = Int((size.width * scale).rounded())
        let targetH = Int((size.height * scale).rounded())
        guard targetW > 0, targetH > 0 else { return nil }

        guard let rep = NSBitmapImageRep(
            bitmapDataPlanes: nil,
            pixelsWide: targetW,
            pixelsHigh: targetH,
            bitsPerSample: 8,
            samplesPerPixel: 4,
            hasAlpha: true,
            isPlanar: false,
            colorSpaceName: .deviceRGB,
            bytesPerRow: 0,
            bitsPerPixel: 0
        ) else { return nil }
        rep.size = NSSize(width: targetW, height: targetH)

        NSGraphicsContext.saveGraphicsState()
        guard let ctx = NSGraphicsContext(bitmapImageRep: rep) else {
            NSGraphicsContext.restoreGraphicsState()
            return nil
        }
        NSGraphicsContext.current = ctx
        img.draw(in: NSRect(x: 0, y: 0, width: targetW, height: targetH),
                 from: .zero,
                 operation: .copy,
                 fraction: 1.0)
        NSGraphicsContext.restoreGraphicsState()

        return rep.representation(using: .png, properties: [:])
    }
}
