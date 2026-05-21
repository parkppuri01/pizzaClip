import XCTest
import AppKit
@testable import myclip

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
