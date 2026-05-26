import XCTest
import AppKit
@testable import pizzaClip

final class ClipboardMonitorTests: XCTestCase {
    func test_textPaste_emitsTextItem() {
        let fake = FakePasteboard()
        var captured: [CapturedItem] = []
        let monitor = ClipboardMonitor(pasteboard: fake,
                                       frontmostBundleID: { "com.apple.Safari" },
                                       blacklistedBundleIDs: { [] },
                                       onCapture: { captured.append($0) })

        fake.put(string: "hello world", type: .string)
        monitor.tick()

        XCTAssertEqual(captured.count, 1)
        XCTAssertEqual(captured.first?.kind, .text)
        XCTAssertEqual(captured.first?.text, "hello world")
        XCTAssertEqual(captured.first?.sourceBundleID, "com.apple.Safari")
    }

    func test_concealedType_isDropped() {
        let fake = FakePasteboard()
        var captured: [CapturedItem] = []
        let monitor = ClipboardMonitor(pasteboard: fake,
                                       frontmostBundleID: { "com.1password.1password" },
                                       blacklistedBundleIDs: { [] },
                                       onCapture: { captured.append($0) })

        fake.put(string: "supersecret", type: .string)
        fake.put(data: Data(), type: NSPasteboard.PasteboardType("org.nspasteboard.ConcealedType"))
        monitor.tick()

        XCTAssertTrue(captured.isEmpty, "concealed type must drop the payload")
    }

    func test_blacklistedFrontmost_isDropped() {
        let fake = FakePasteboard()
        var captured: [CapturedItem] = []
        let monitor = ClipboardMonitor(pasteboard: fake,
                                       frontmostBundleID: { "com.bitwarden.desktop" },
                                       blacklistedBundleIDs: { ["com.bitwarden.desktop"] },
                                       onCapture: { captured.append($0) })

        fake.put(string: "vaulted", type: .string)
        monitor.tick()
        XCTAssertTrue(captured.isEmpty)
    }

    func test_imagePayload_emitsImageItem() {
        let fake = FakePasteboard()
        var captured: [CapturedItem] = []
        let monitor = ClipboardMonitor(pasteboard: fake,
                                       frontmostBundleID: { "com.apple.screencapture" },
                                       blacklistedBundleIDs: { [] },
                                       onCapture: { captured.append($0) })

        fake.put(data: Data([0x89, 0x50, 0x4E, 0x47]), type: .png)
        monitor.tick()

        XCTAssertEqual(captured.first?.kind, .image)
        XCTAssertNotNil(captured.first?.imageData)
    }

    func test_filePayload_emitsFileItem() {
        let fake = FakePasteboard()
        var captured: [CapturedItem] = []
        let monitor = ClipboardMonitor(pasteboard: fake,
                                       frontmostBundleID: { "com.apple.finder" },
                                       blacklistedBundleIDs: { [] },
                                       onCapture: { captured.append($0) })

        let url = URL(fileURLWithPath: "/tmp/foo.txt")
        fake.put(string: url.path, type: .fileURL)
        monitor.tick()

        XCTAssertEqual(captured.first?.kind, .file)
        XCTAssertEqual(captured.first?.text, "/tmp/foo.txt")
    }

    func test_filePayload_resolvesStandardFileURLString() {
        // Real Finder copies arrive on the pasteboard as URL strings, not raw
        // paths. The monitor must decode the `file://` URL so item.text holds a
        // usable filesystem path (otherwise PasteEngine writes garbage URLs back
        // and downstream apps can't paste the file).
        let fake = FakePasteboard()
        var captured: [CapturedItem] = []
        let monitor = ClipboardMonitor(pasteboard: fake,
                                       frontmostBundleID: { "com.apple.finder" },
                                       blacklistedBundleIDs: { [] },
                                       onCapture: { captured.append($0) })

        fake.put(string: "file:///tmp/with%20space.txt", type: .fileURL)
        monitor.tick()

        XCTAssertEqual(captured.first?.kind, .file)
        XCTAssertEqual(captured.first?.text, "/tmp/with space.txt")
    }

    func test_resolveFilePath_passesPlainPathThrough() {
        XCTAssertEqual(ClipboardMonitor.resolveFilePath("/tmp/foo.txt"), "/tmp/foo.txt")
    }

    func test_resolveFilePath_returnsNilForEmpty() {
        XCTAssertNil(ClipboardMonitor.resolveFilePath(""))
    }

    func test_identicalContent_acrossTwoChangeCounts_isDedupedAtMonitor() {
        // macOS sometimes fires two changeCount increments for a single
        // copy (screenshot tool, Finder, sync helpers re-touching the
        // board). Even though `changeCount` differs, the *content* is the
        // same — we should only emit once.
        let fake = FakePasteboard()
        var captured: [CapturedItem] = []
        let monitor = ClipboardMonitor(pasteboard: fake,
                                       frontmostBundleID: { "com.apple.screencapture" },
                                       blacklistedBundleIDs: { [] },
                                       onCapture: { captured.append($0) })

        let pngBytes = Data([0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A,
                             0x00, 0x00, 0x00, 0x0D, 0x49, 0x48, 0x44, 0x52])
        fake.put(data: pngBytes, type: .png)
        monitor.tick()

        // Same bytes, fresh changeCount — simulates macOS re-touching the
        // pasteboard milliseconds after the original write.
        fake.put(data: pngBytes, type: .png)
        monitor.tick()

        XCTAssertEqual(captured.count, 1, "identical image content must not double-emit")
    }

    func test_differentImageContent_emitsTwice() {
        // Two distinct screenshots in a row should both land in history.
        let fake = FakePasteboard()
        var captured: [CapturedItem] = []
        let monitor = ClipboardMonitor(pasteboard: fake,
                                       frontmostBundleID: { nil },
                                       blacklistedBundleIDs: { [] },
                                       onCapture: { captured.append($0) })

        fake.put(data: Data([0x89, 0x50, 0x4E, 0x47, 0x01]), type: .png)
        monitor.tick()
        fake.put(data: Data([0x89, 0x50, 0x4E, 0x47, 0x02]), type: .png)
        monitor.tick()

        XCTAssertEqual(captured.count, 2, "different image bytes must each emit")
    }

    func test_sameChangeCount_doesNotReemit() {
        let fake = FakePasteboard()
        var captured: [CapturedItem] = []
        let monitor = ClipboardMonitor(pasteboard: fake,
                                       frontmostBundleID: { nil },
                                       blacklistedBundleIDs: { [] },
                                       onCapture: { captured.append($0) })

        fake.put(string: "one", type: .string)
        monitor.tick()
        monitor.tick()
        XCTAssertEqual(captured.count, 1)
    }
}
