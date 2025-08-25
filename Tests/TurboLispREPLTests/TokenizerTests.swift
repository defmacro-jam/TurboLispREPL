import XCTest
@testable import TurboLispREPL

final class TokenizerTests: XCTestCase {
    func testTokenizationTranscript() {
        let code = """
(defun greet ()
  (print "Hello") ; Greet
)
"""
        let tokens = Tokenizer.tokenize(code)
        let transcript = tokens.map { "\($0.kind.rawValue):\($0.value)" }.joined(separator: "\n")
        let expected = #"""
paren:(
symbol:defun
symbol:greet
paren:(
paren:)
paren:(
symbol:print
string:"Hello"
paren:)
comment:; Greet
paren:)
"""#
        XCTAssertEqual(transcript, expected)
    }

    func testPrinterRoundTripFuzz() throws {
        for _ in 0..<100 {
            let expr = randomExpr(depth: 3)
            let printed = Printer.print(expr)
            let parsed = try Parser.parse(printed)
            XCTAssertEqual(parsed, expr)
        }
    }

    private func randomExpr(depth: Int) -> Expr {
        if depth == 0 {
            return Bool.random() ? .symbol(randomSymbol()) : .string(randomString())
        }
        let choice = Int.random(in: 0...2)
        switch choice {
        case 0:
            return .symbol(randomSymbol())
        case 1:
            return .string(randomString())
        default:
            let count = Int.random(in: 0...3)
            var items: [Expr] = []
            for _ in 0..<count {
                items.append(randomExpr(depth: depth - 1))
            }
            return .list(items)
        }
    }

    private func randomSymbol() -> String {
        let letters = Array("abcdefghijklmnopqrstuvwxyz")
        let length = Int.random(in: 1...3)
        return String((0..<length).map { _ in letters.randomElement()! })
    }

    private func randomString() -> String {
        let letters = Array("abcdefghijklmnopqrstuvwxyz")
        let length = Int.random(in: 0...3)
        return String((0..<length).map { _ in letters.randomElement()! })
    }
}

