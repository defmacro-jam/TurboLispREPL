import XCTest
@testable import TurboLispREPL

final class TokenizerTests: XCTestCase {
    func testTokenizesStringsCommentsAndParens() {
        let source = "(defun foo \"bar\" ; comment\n)"
        let tokens = LispTokenizer.tokenize(source)
        XCTAssertEqual(tokens.map { $0.kind }, [
            TokenKind.paren.rawValue,
            TokenKind.string.rawValue,
            TokenKind.comment.rawValue,
            TokenKind.paren.rawValue
        ])
    }
}
