import XCTest
@testable import TurboLispREPL

final class IndenterTests: XCTestCase {
    func testIndentationForSpecialForms() {
        let code = """
(defun foo ()
  (let ((a 1)
        (b 2))
    (if (> a b)
        a
        b)))
"""
        let indents = LispIndenter.computeIndents(for: code)
        let values = indents.map { Int($0.head) }
        XCTAssertEqual(values, [0,4,8,6,8,8])
    }
}
