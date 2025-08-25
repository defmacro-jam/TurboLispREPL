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

    func testMalformedStringIsTokenizedToEnd() {
        let source = "(print \"oops"
        let tokens = LispTokenizer.tokenize(source)
        XCTAssertEqual(tokens.map { $0.kind }, [
            TokenKind.paren.rawValue,
            TokenKind.string.rawValue
        ])
    }

    func testUnterminatedCommentReachesEOF() {
        let source = "; this comment never ends"
        let tokens = LispTokenizer.tokenize(source)
        XCTAssertEqual(tokens.count, 1)
        XCTAssertEqual(tokens.first?.kind, TokenKind.comment.rawValue)
    }
}
