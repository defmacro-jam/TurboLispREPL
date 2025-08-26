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

    func testSymbolExtractionAllowsSpecialCharacters() {
        let tokenizer = StandardLispTokenizer()
        let source = "(* 1 2) (+ 3 4) (contains? xs) (save! y) (:keyword 42)"
        tokenizer.reset(with: source)

        var symbols: [String] = []
        while let token = tokenizer.nextToken() {
            if case .open(let sym) = token.kind {
                symbols.append(sym)
            }
        }

        XCTAssertEqual(symbols, ["*", "+", "contains?", "save!", ":keyword"])
    }
}
