import Foundation

public struct Token {
    public enum Kind: String {
        case paren
        case string
        case comment
        case symbol
    }
    public let kind: Kind
    public let value: String
}

public enum Tokenizer {
    public static func tokenize(_ input: String) -> [Token] {
        var tokens: [Token] = []
        var index = input.startIndex
        let end = input.endIndex
        while index < end {
            let char = input[index]
            if char == ";" {
                let start = index
                while index < end && input[index] != "\n" {
                    index = input.index(after: index)
                }
                let comment = String(input[start..<index])
                tokens.append(Token(kind: .comment, value: comment))
            } else if char == "\"" {
                var j = input.index(after: index)
                while j < end && input[j] != "\"" {
                    j = input.index(after: j)
                }
                if j < end { j = input.index(after: j) }
                let str = String(input[index..<j])
                tokens.append(Token(kind: .string, value: str))
                index = j
                continue
            } else if char == "(" || char == ")" {
                tokens.append(Token(kind: .paren, value: String(char)))
                index = input.index(after: index)
                continue
            } else if char.isWhitespace {
                index = input.index(after: index)
                continue
            } else {
                var j = index
                while j < end {
                    let c = input[j]
                    if c.isWhitespace || c == "(" || c == ")" || c == ";" {
                        break
                    }
                    j = input.index(after: j)
                }
                let symbol = String(input[index..<j])
                tokens.append(Token(kind: .symbol, value: symbol))
                index = j
                continue
            }
            index = input.index(after: index)
        }
        return tokens
    }
}

extension Character {
    var isWhitespace: Bool {
        return unicodeScalars.allSatisfy { CharacterSet.whitespacesAndNewlines.contains($0) }
    }
}

