import Foundation

public enum TokenKind: Int {
    case string
    case comment
    case paren
}

public struct TokenSpan {
    public let location: Int
    public let length: Int
    /// Numeric token kind for easier bridging.
    public let kind: Int
    public let attrs: [NSAttributedString.Key: Any]

    public init(location: Int, length: Int, kind: TokenKind, attrs: [NSAttributedString.Key: Any] = [:]) {
        self.location = location
        self.length = length
        self.kind = kind.rawValue
        self.attrs = attrs
    }
}

/// Minimal tokenizer that recognizes strings, comments and parentheses.
public struct LispTokenizer {
    public static func tokenize(_ text: String) -> [TokenSpan] {
        var tokens: [TokenSpan] = []
        let characters = Array(text)
        var index = 0
        while index < characters.count {
            let ch = characters[index]
            switch ch {
            case ";":
                let start = index
                while index < characters.count && characters[index] != "\n" { index += 1 }
                tokens.append(TokenSpan(location: start, length: index - start, kind: .comment))
            case "\"":
                let start = index
                index += 1
                while index < characters.count {
                    let c = characters[index]
                    if c == "\\" {
                        index += 2
                        continue
                    }
                    if c == "\"" { index += 1; break }
                    index += 1
                }
                tokens.append(TokenSpan(location: start, length: index - start, kind: .string))
            case "(", ")":
                tokens.append(TokenSpan(location: index, length: 1, kind: .paren))
                index += 1
            default:
                index += 1
            }
        }
        return tokens
    }
}

