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

/// Basic tokenizer used for syntax highlighting. Returns `TokenSpan`s
/// describing strings, comments, and parentheses.
public enum LispTokenizer {
    public static func tokenize(_ source: String) -> [TokenSpan] {
        var tokens: [TokenSpan] = []
        let chars = Array(source)
        var index = 0

        while index < chars.count {
            let ch = chars[index]
            switch ch {
            case "(", ")":
                tokens.append(TokenSpan(location: index, length: 1, kind: .paren))
                index += 1
            case ";":
                let start = index
                index += 1
                while index < chars.count && chars[index] != "\n" { index += 1 }
                tokens.append(TokenSpan(location: start, length: index - start, kind: .comment))
            case "\"":
                let start = index
                index += 1
                while index < chars.count {
                    let c = chars[index]
                    if c == "\\" {
                        index += 2
                    } else if c == "\"" {
                        index += 1
                        break
                    } else {
                        index += 1
                    }
                }
                tokens.append(TokenSpan(location: start, length: index - start, kind: .string))
            default:
                index += 1
            }
        }

        return tokens
    }
}

/// Concrete implementation of `LispTokenizerProtocol` used by the indenter.
public final class StandardLispTokenizer: LispTokenizerProtocol {
    private var characters: [Character] = []
    private var currentIndex: Int = 0

    public init() {}

    public func reset(with source: String) {
        self.characters = Array(source)
        self.currentIndex = 0
    }

    private func isSymbolChar(_ ch: Character) -> Bool {
        return ch.isLetter || ch.isNumber || "-_*+?!:".contains(ch)
    }

    public func nextToken() -> LispToken? {
        // Skip whitespace including newlines
        while currentIndex < characters.count {
            let ch = characters[currentIndex]
            if ch == " " || ch == "\t" || ch == "\n" || ch == "\r" {
                currentIndex += 1
                continue
            }
            break
        }

        guard currentIndex < characters.count else { return nil }
        let startIndex = currentIndex
        let ch = characters[currentIndex]

        switch ch {
        case "(":
            currentIndex += 1
            // Peek for symbol after '('
            var peek = currentIndex
            // Skip whitespace
            while peek < characters.count && (characters[peek] == " " || characters[peek] == "\t" || characters[peek] == "\n" || characters[peek] == "\r") {
                peek += 1
            }
            var symbolEnd = peek
            while symbolEnd < characters.count && isSymbolChar(characters[symbolEnd]) {
                symbolEnd += 1
            }
            let symbol = String(characters[peek..<symbolEnd])
            currentIndex = peek
            return LispToken(kind: .open(symbol: symbol), range: NSRange(location: startIndex, length: 1))
        case ")":
            currentIndex += 1
            return LispToken(kind: .close, range: NSRange(location: startIndex, length: 1))
        case ";":
            currentIndex += 1
            while currentIndex < characters.count && characters[currentIndex] != "\n" {
                currentIndex += 1
            }
            let text = String(characters[startIndex..<currentIndex])
            return LispToken(kind: .comment(text), range: NSRange(location: startIndex, length: currentIndex - startIndex))
        case "\"":
            currentIndex += 1
            while currentIndex < characters.count {
                let c = characters[currentIndex]
                if c == "\\" {
                    currentIndex += 2
                } else if c == "\"" {
                    currentIndex += 1
                    break
                } else {
                    currentIndex += 1
                }
            }
            let text = String(characters[startIndex..<currentIndex])
            return LispToken(kind: .atom(text), range: NSRange(location: startIndex, length: currentIndex - startIndex))
        default:
            var atom = ""
            while currentIndex < characters.count {
                let c = characters[currentIndex]
                if c == " " || c == "\t" || c == "\n" || c == "\r" || c == "(" || c == ")" { break }
                atom.append(c)
                currentIndex += 1
            }
            guard !atom.isEmpty else { return nextToken() }
            return LispToken(kind: .atom(atom), range: NSRange(location: startIndex, length: atom.count))
        }
    }
}

public extension StandardLispTokenizer {
    /// Convenience method mirroring `LispTokenizer.tokenize` so callers can
    /// obtain `TokenSpan` values using the StandardLispTokenizer implementation.
    static func tokenize(_ source: String) -> [TokenSpan] {
        return LispTokenizer.tokenize(source)
    }
}
