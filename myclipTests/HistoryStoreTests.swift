import XCTest
import AppKit
import GRDB
@testable import myclip

final class HistoryStoreTests: XCTestCase {
    private func makeStore() throws -> HistoryStore {
        let queue = try DatabaseQueue() // in-memory
        return try HistoryStore(queue: queue)
    }

    func test_insert_thenTopN_returnsNewestFirst() throws {
        let store = try makeStore()
        let a = CapturedItem(kind: .text, text: "first",
                             createdAt: Date(timeIntervalSince1970: 1_700_000_000.000))
        let b = CapturedItem(kind: .text, text: "second",
                             createdAt: Date(timeIntervalSince1970: 1_700_000_001.000))
        try store.insert(a)
        try store.insert(b)

        let top = try store.topN(10)
        XCTAssertEqual(top.map(\.text), ["second", "first"])
    }

    func test_insert_dedupesIdenticalText() throws {
        let store = try makeStore()
        try store.insert(CapturedItem(kind: .text, text: "hi"))
        try store.insert(CapturedItem(kind: .text, text: "hi"))

        let top = try store.topN(10)
        XCTAssertEqual(top.count, 1, "identical text within history should dedupe")
    }

    func test_togglePin_movesItemAboveNonPinned() throws {
        let store = try makeStore()
        try store.insert(CapturedItem(kind: .text, text: "a",
                                      createdAt: Date(timeIntervalSince1970: 1_700_000_000)))
        try store.insert(CapturedItem(kind: .text, text: "b",
                                      createdAt: Date(timeIntervalSince1970: 1_700_000_001)))
        let aID = try XCTUnwrap(store.topN(10).first(where: { $0.text == "a" })?.id)

        try store.togglePin(id: aID)
        let ordered = try store.topNRespectingPins(10)
        XCTAssertEqual(ordered.first?.text, "a", "pinned item should be on top")
        XCTAssertTrue(ordered.first?.pinned == true)
    }

    func test_prune_dropsOldestNonPinned_keepsPinned() throws {
        let store = try makeStore()
        for i in 0..<5 {
            try store.insert(CapturedItem(kind: .text, text: "t\(i)",
                                          createdAt: Date(timeIntervalSince1970: 1_700_000_000 + Double(i))))
        }
        let pinned = try XCTUnwrap(store.topN(10).first(where: { $0.text == "t0" })?.id)
        try store.togglePin(id: pinned)

        try store.prune(cap: 3)

        let remaining = try store.topN(10).map(\.text)
        XCTAssertTrue(remaining.contains("t0"), "pinned t0 must survive")
        XCTAssertEqual(remaining.count, 4, "3 newest non-pinned + 1 pinned")
    }

    func test_insertImage_writesBlobAndStoresPath() throws {
        let tmp = FileManager.default.temporaryDirectory
            .appendingPathComponent("histblob-\(UUID().uuidString)")
        let blobs = BlobStore(rootDirectory: tmp)
        let queue = try DatabaseQueue()
        let store = try HistoryStore(queue: queue, blobStore: blobs)

        let image = NSImage(size: NSSize(width: 64, height: 64))
        image.lockFocus()
        NSColor.blue.setFill()
        NSRect(x: 0, y: 0, width: 64, height: 64).fill()
        image.unlockFocus()
        let png = image.tiffRepresentation
            .flatMap { NSBitmapImageRep(data: $0)?.representation(using: .png, properties: [:]) }!

        try store.insert(CapturedItem(kind: .image, imageData: png))

        let top = try store.topN(10)
        XCTAssertEqual(top.count, 1)
        XCTAssertEqual(top.first?.type, "image")
        let relative = try XCTUnwrap(top.first?.blobPath)
        XCTAssertTrue(FileManager.default.fileExists(atPath: tmp.appendingPathComponent(relative).path))
        XCTAssertNotNil(top.first?.thumbPng)
    }
}
