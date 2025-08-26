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

<<<<<<< HEAD
    func testTokenizerSkipsConsecutiveNewlines() {
        let source = "(foo)\n\n\n(bar)"
        let tokenizer = StandardLispTokenizer()
        tokenizer.reset(with: source)

        var kinds: [LispToken.Kind] = []
        while let token = tokenizer.nextToken() {
            kinds.append(token.kind)
        }

        XCTAssertEqual(kinds.count, 6, "Expected six tokens ignoring newlines")

        guard kinds.count == 6 else { return }
        switch kinds[0] {
        case .open(let symbol):
            XCTAssertEqual(symbol, "foo")
        default:
            XCTFail("First token should open 'foo'")
        }
        switch kinds[1] {
        case .atom(let value):
            XCTAssertEqual(value, "foo")
        default:
            XCTFail("Second token should be atom 'foo'")
        }
        if case .close = kinds[2] {
            // OK
        } else {
            XCTFail("Third token should be close")
        }
        switch kinds[3] {
        case .open(let symbol):
            XCTAssertEqual(symbol, "bar")
        default:
            XCTFail("Fourth token should open 'bar'")
        }
        switch kinds[4] {
        case .atom(let value):
            XCTAssertEqual(value, "bar")
        default:
            XCTFail("Fifth token should be atom 'bar'")
        }
        if case .close = kinds[5] {
            // OK
        } else {
            XCTFail("Sixth token should be close")
        }
=======
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
>>>>>>> main
    }
}
