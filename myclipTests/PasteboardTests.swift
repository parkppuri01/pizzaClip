import XCTest
import AppKit
@testable import myclip

final class PasteboardTests: XCTestCase {
    func test_fakePasteboard_reportsChangeCountAndTypes() {
        let fake = FakePasteboard()
        XCTAssertEqual(fake.changeCount, 0)

        fake.put(string: "hello", type: .string)
        XCTAssertEqual(fake.changeCount, 1)
        XCTAssertEqual(fake.types(), [.string])
        XCTAssertEqual(fake.string(forType: .string), "hello")
    }
}
