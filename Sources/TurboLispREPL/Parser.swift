import Foundation

public enum ParserError: Error {
    case unexpectedEOF
    case unmatchedParen
}

public enum Parser {
    public static func parse(_ input: String) throws -> Expr {
        let tokens = Tokenizer.tokenize(input).filter { $0.kind != .comment }
        var index = 0
        func parseExpr() throws -> Expr {
            guard index < tokens.count else { throw ParserError.unexpectedEOF }
            let tok = tokens[index]; index += 1
            switch tok.kind {
            case .paren:
                if tok.value == "(" {
                    var list: [Expr] = []
                    while index < tokens.count {
                        let next = tokens[index]
                        if next.kind == .paren && next.value == ")" {
                            index += 1
                            break
                        }
                        list.append(try parseExpr())
                    }
                    return .list(list)
                } else {
                    throw ParserError.unmatchedParen
                }
            case .string:
                let inner = String(tok.value.dropFirst().dropLast())
                return .string(inner)
            default:
                return .symbol(tok.value)
            }
        }
        let expr = try parseExpr()
        return expr
    }
}

