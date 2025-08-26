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

/// Concrete implementation of LispTokenizerProtocol from LispIndenter.swift
public final class StandardLispTokenizer: LispTokenizerProtocol {
    private var source: String = ""
    private var characters: [Character] = []
    private var currentIndex: Int = 0
    
    public init() {}
    
    public func reset(with source: String) {
        self.source = source
        self.characters = Array(source)
        self.currentIndex = 0
    }
    
    public func nextToken() -> LispToken? {
        // Skip whitespace except newlines (they might be significant for indentation)
        while currentIndex < characters.count {
            let ch = characters[currentIndex]
            if ch == " " || ch == "\t" || ch == "\r" {
                currentIndex += 1
            } else {
                break
            }
        }
        
        guard currentIndex < characters.count else { return nil }
        
        let startIndex = currentIndex
        let ch = characters[currentIndex]
        
        switch ch {
        case "(":
            currentIndex += 1
            // Look ahead for the symbol after the paren
            var symbol = ""
            var peekIndex = currentIndex
            
            // Skip whitespace after paren
            while peekIndex < characters.count {
                let peekCh = characters[peekIndex]
                if peekCh == " " || peekCh == "\t" || peekCh == "\n" || peekCh == "\r" {
                    peekIndex += 1
                } else {
                    break
                }
            }
            
            // Extract the symbol
            while peekIndex < characters.count {
                let peekCh = characters[peekIndex]
                if peekCh.isLetter || peekCh.isNumber || peekCh == "-" || peekCh == "_" {
                    symbol.append(peekCh)
                    peekIndex += 1
                } else {
                    break
                }
            }
            
            let range = NSRange(location: startIndex, length: 1)
            return LispToken(kind: .open(symbol: symbol), range: range)
            
        case ")":
            currentIndex += 1
            let range = NSRange(location: startIndex, length: 1)
            return LispToken(kind: .close, range: range)
            
        case ";":
            // Comment - skip to end of line
            while currentIndex < characters.count && characters[currentIndex] != "\n" {
                currentIndex += 1
            }
            let range = NSRange(location: startIndex, length: currentIndex - startIndex)
            let commentText = String(characters[startIndex..<currentIndex])
            return LispToken(kind: .comment(commentText), range: range)
            
        case "\"":
            // String literal
            currentIndex += 1
            var stringContent = "\""
            while currentIndex < characters.count {
                let c = characters[currentIndex]
                stringContent.append(c)
                if c == "\\" && currentIndex + 1 < characters.count {
                    currentIndex += 1
                    if currentIndex < characters.count {
                        stringContent.append(characters[currentIndex])
                    }
                } else if c == "\"" {
                    currentIndex += 1
                    break
                }
                currentIndex += 1
            }
            let range = NSRange(location: startIndex, length: currentIndex - startIndex)
            return LispToken(kind: .atom(stringContent), range: range)
            
        case "\n":
            currentIndex += 1
            // Skip newlines as they're not tokens in this context
            return nextToken()
            
        default:
            // Regular atom - collect until whitespace or parens
            var atom = ""
            while currentIndex < characters.count {
                let c = characters[currentIndex]
                if c == " " || c == "\t" || c == "\n" || c == "\r" || c == "(" || c == ")" {
                    break
                }
                atom.append(c)
                currentIndex += 1
            }
            
            if !atom.isEmpty {
                let range = NSRange(location: startIndex, length: atom.count)
                return LispToken(kind: .atom(atom), range: range)
            }
            
            return nil
        }
    }
    
    /// Static helper method to get all tokens at once (for backward compatibility)
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

/// For backward compatibility, keep the static interface
public struct LispTokenizer {
    public static func tokenize(_ text: String) -> [TokenSpan] {
        return StandardLispTokenizer.tokenize(text)
    }
}