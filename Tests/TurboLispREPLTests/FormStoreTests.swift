import XCTest
@testable import TurboLispREPL

final class FormStoreTests: XCTestCase {
    func testInsertQueryAndShiftAfterEdit() {
        let store = FormStore()
        store.upsert(start: 0, end: 5)
        store.upsert(start: 10, end: 15)
        XCTAssertEqual(store.intersecting(start: 0, end: 20).count, 2)

        // Insert three characters at position 5; second range should shift.
        store.applyEdit(at: 5, oldLength: 0, newLength: 3)
        let ranges = store.intersecting(start: 0, end: 20)
        XCTAssertEqual(ranges.count, 2)

        guard let shifted = ranges.first(where: { $0.start > 10 }) else {
            return XCTFail("Expected shifted range")
        }
        XCTAssertEqual(shifted.start, 13)
        XCTAssertEqual(shifted.end, 18)
    }

    func testDeletionRemovesIntersectingRanges() {
        let store = FormStore()
        store.upsert(start: 0, end: 5)
        store.upsert(start: 10, end: 15)

        // Delete five characters starting at 2; first range is removed and
        // second range shifts backward.
        store.applyEdit(at: 2, oldLength: 5, newLength: 0)
        let ranges = store.intersecting(start: 0, end: 20)
        XCTAssertEqual(ranges.count, 1)
        XCTAssertEqual(ranges.first?.start, 5)
        XCTAssertEqual(ranges.first?.end, 10)
    }
}

