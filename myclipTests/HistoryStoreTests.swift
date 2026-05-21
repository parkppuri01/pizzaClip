import XCTest
import GRDB
@testable import myclip

final class HistoryStoreTests: XCTestCase {
    private func makeStore() throws -> HistoryStore {
        let queue = try DatabaseQueue() // in-memory
        return try HistoryStore(queue: queue)
    }

    func test_insert_thenTopN_returnsNewestFirst() throws {
        let store = try makeStore()
        let a = CapturedItem(kind: .text, text: "first")
        let b = CapturedItem(kind: .text, text: "second")
        try store.insert(a)
        Thread.sleep(forTimeInterval: 0.005)
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
}
