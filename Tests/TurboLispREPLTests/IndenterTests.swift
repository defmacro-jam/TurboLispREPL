import XCTest
@testable import TurboLispREPL

final class IndenterTests: XCTestCase {
    func testIndentationLevels() {
        let code = """
(defun foo (x)
  (let ((y 1))
    (if x
        y
        0))
)
"""
        let styles = Indenter.styles(for: code)
        XCTAssertEqual(styles.count, 6)
        XCTAssertEqual(styles[0].headIndent, 0)
        XCTAssertEqual(styles[1].headIndent, 2)
        XCTAssertEqual(styles[2].headIndent, 4)
        XCTAssertEqual(styles[3].headIndent, 6)
        XCTAssertEqual(styles[4].headIndent, 6)
        XCTAssertEqual(styles[5].headIndent, 0)
    }
}

