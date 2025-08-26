import Foundation

/// Tokenizer that understands Lisp form context for accurate token classification
public class ContextAwareTokenizer {
    
    /// Special forms that affect how arguments are tokenized
    private static let specialForms = Set([
        "defun", "defmacro", "defvar", "defparameter", "defconstant",
        "let", "let*", "lambda", "if", "when", "unless", "cond",
        "case", "typecase", "quote", "function", "setq", "setf",
        "progn", "prog1", "prog2", "block", "return-from", "tagbody",
        "go", "catch", "throw", "unwind-protect", "labels", "flet"
    ])
    
    /// Tokenize with understanding of surrounding form context
    public func tokenize(text: String, range: NSRange, context: FormContext? = nil) -> [TokenSpan] {
        var tokens: [TokenSpan] = []
        var position = range.location
        let endPosition = NSMaxRange(range)
        
        // Convert to String.Index for easier manipulation
        guard position >= 0 && endPosition <= text.count else { return [] }
        
        var currentIndex = text.index(text.startIndex, offsetBy: position)
        let endIndex = text.index(text.startIndex, offsetBy: endPosition)
        
        var inString = false
        var inLineComment = false
        var inBlockComment = false
        var blockCommentDepth = 0
        var formStack: [String] = []
        
        while currentIndex < endIndex {
            let char = text[currentIndex]
            let charPosition = text.distance(from: text.startIndex, to: currentIndex)
            
            // Handle block comments
            if !inString && !inLineComment {
                if currentIndex < text.index(before: endIndex) {
                    let nextChar = text[text.index(after: currentIndex)]
                    if char == "#" && nextChar == "|" {
                        // Start of block comment
                        let commentStart = charPosition
                        currentIndex = text.index(after: currentIndex) // Skip |
                        blockCommentDepth = 1
                        inBlockComment = true
                        
                        // Find end of block comment
                        while currentIndex < endIndex && blockCommentDepth > 0 {
                            if currentIndex < text.index(before: endIndex) {
                                let curr = text[currentIndex]
                                let next = text[text.index(after: currentIndex)]
                                if curr == "|" && next == "#" {
                                    blockCommentDepth -= 1
                                    currentIndex = text.index(after: currentIndex)
                                } else if curr == "#" && next == "|" {
                                    blockCommentDepth += 1
                                    currentIndex = text.index(after: currentIndex)
                                }
                            }
                            currentIndex = text.index(after: currentIndex)
                        }
                        
                        let commentLength = text.distance(from: text.startIndex, to: currentIndex) - commentStart
                        tokens.append(TokenSpan(
                            location: commentStart,
                            length: commentLength,
                            kind: .comment
                        ))
                        inBlockComment = false
                        continue
                    }
                }
            }
            
            // Handle line comments
            if !inString && char == ";" {
                let commentStart = charPosition
                inLineComment = true
                
                // Find end of line
                while currentIndex < endIndex && text[currentIndex] != "\n" {
                    currentIndex = text.index(after: currentIndex)
                }
                
                let commentLength = text.distance(from: text.startIndex, to: currentIndex) - commentStart
                tokens.append(TokenSpan(
                    location: commentStart,
                    length: commentLength,
                    kind: .comment
                ))
                inLineComment = false
                continue
            }
            
            // Handle strings
            if char == "\"" {
                let stringStart = charPosition
                currentIndex = text.index(after: currentIndex)
                inString = true
                
                // Find end of string
                while currentIndex < endIndex && inString {
                    let ch = text[currentIndex]
                    if ch == "\\" && text.index(after: currentIndex) < endIndex {
                        // Skip escaped character
                        currentIndex = text.index(after: currentIndex)
                    } else if ch == "\"" {
                        inString = false
                    }
                    currentIndex = text.index(after: currentIndex)
                }
                
                let stringLength = text.distance(from: text.startIndex, to: currentIndex) - stringStart
                tokens.append(TokenSpan(
                    location: stringStart,
                    length: stringLength,
                    kind: .string
                ))
                continue
            }
            
            // Handle parentheses
            if char == "(" || char == ")" {
                tokens.append(TokenSpan(
                    location: charPosition,
                    length: 1,
                    kind: .paren
                ))
                
                if char == "(" {
                    // Look ahead for the form name
                    var lookAhead = text.index(after: currentIndex)
                    while lookAhead < endIndex && text[lookAhead].isWhitespace {
                        lookAhead = text.index(after: lookAhead)
                    }
                    
                    if lookAhead < endIndex {
                        let formName = extractSymbol(from: lookAhead, in: text, upTo: endIndex)
                        if !formName.isEmpty {
                            formStack.append(formName.lowercased())
                        }
                    }
                } else if char == ")" && !formStack.isEmpty {
                    formStack.removeLast()
                }
                
                currentIndex = text.index(after: currentIndex)
                continue
            }
            
            // Skip whitespace
            if char.isWhitespace {
                currentIndex = text.index(after: currentIndex)
                continue
            }
            
            // Handle other characters (symbols, numbers, etc.)
            let tokenStart = charPosition
            let symbol = extractSymbol(from: currentIndex, in: text, upTo: endIndex)
            
            if !symbol.isEmpty {
                let tokenLength = symbol.count
                
                // Classify the token based on context
                let tokenKind = classifyToken(symbol, formStack: formStack, position: tokens.count)
                
                tokens.append(TokenSpan(
                    location: tokenStart,
                    length: tokenLength,
                    kind: tokenKind
                ))
                
                // Advance position
                currentIndex = text.index(currentIndex, offsetBy: tokenLength)
            } else {
                currentIndex = text.index(after: currentIndex)
            }
        }
        
        return tokens
    }
    
    /// Extract a symbol starting from a position
    private func extractSymbol(from startIndex: String.Index, in text: String, upTo endIndex: String.Index) -> String {
        var result = ""
        var currentIndex = startIndex
        
        while currentIndex < endIndex {
            let char = text[currentIndex]
            
            // Check for token terminators
            if char.isWhitespace || char == "(" || char == ")" || 
               char == "\"" || char == ";" || char == "'" || 
               char == "`" || char == "," || char == "@" {
                break
            }
            
            result.append(char)
            currentIndex = text.index(after: currentIndex)
        }
        
        return result
    }
    
    /// Classify a token based on its context
    private func classifyToken(_ token: String, formStack: [String], position: Int) -> TokenKind {
        // Check if it's a keyword (starts with :)
        if token.starts(with: ":") {
            return .comment  // Using comment style for keywords temporarily
        }
        
        // Check if it's a number
        if isNumber(token) {
            return .string  // Using string style for numbers temporarily
        }
        
        // Check if it's a special form
        if Self.specialForms.contains(token.lowercased()) {
            return .comment  // Using comment style for special forms temporarily
        }
        
        // Check position in form
        if position == 0 && !formStack.isEmpty {
            // First position in a form - likely a function name
            return .string  // Using string style for function names temporarily
        }
        
        // Default to regular token (will be styled as normal text)
        return .paren  // Using paren style for regular symbols temporarily
    }
    
    /// Check if a token represents a number
    private func isNumber(_ token: String) -> Bool {
        // Simple number check - can be enhanced
        if token.isEmpty { return false }
        
        // Check for integer
        if Int(token) != nil { return true }
        
        // Check for float
        if Double(token) != nil { return true }
        
        // Check for ratio (e.g., 1/2)
        if token.contains("/") {
            let parts = token.split(separator: "/")
            if parts.count == 2 {
                return Int(parts[0]) != nil && Int(parts[1]) != nil
            }
        }
        
        // Check for hex, octal, binary
        if token.starts(with: "#x") || token.starts(with: "#o") || token.starts(with: "#b") {
            return true
        }
        
        return false
    }
    
    /// Determine the context at a specific position in the text
    public func contextAt(position: Int, in text: String) -> FormContext {
        var depth = 0
        var formStack: [String] = []
        var inQuote = false
        
        guard position >= 0 && position <= text.count else {
            return FormContext()
        }
        
        let endIndex = text.index(text.startIndex, offsetBy: position)
        var currentIndex = text.startIndex
        
        while currentIndex < endIndex {
            let char = text[currentIndex]
            
            // Skip strings and comments
            if char == "\"" {
                currentIndex = skipString(from: currentIndex, in: text, upTo: endIndex)
                continue
            }
            
            if char == ";" {
                currentIndex = skipLineComment(from: currentIndex, in: text, upTo: endIndex)
                continue
            }
            
            // Handle quotes
            if char == "'" {
                inQuote = true
            }
            
            // Handle parentheses
            if char == "(" {
                depth += 1
                
                // Extract form name
                var lookAhead = text.index(after: currentIndex)
                while lookAhead < endIndex && text[lookAhead].isWhitespace {
                    lookAhead = text.index(after: lookAhead)
                }
                
                if lookAhead < endIndex {
                    let formName = extractSymbol(from: lookAhead, in: text, upTo: endIndex)
                    if !formName.isEmpty {
                        formStack.append(formName.lowercased())
                    }
                }
            } else if char == ")" {
                depth = max(0, depth - 1)
                if !formStack.isEmpty {
                    formStack.removeLast()
                }
                inQuote = false
            }
            
            currentIndex = text.index(after: currentIndex)
        }
        
        return FormContext(
            formType: formStack.last,
            depth: depth,
            isQuoted: inQuote,
            parentForm: formStack.count > 1 ? formStack[formStack.count - 2] : nil
        )
    }
    
    /// Skip over a string literal
    private func skipString(from startIndex: String.Index, in text: String, upTo endIndex: String.Index) -> String.Index {
        var currentIndex = text.index(after: startIndex) // Skip opening quote
        
        while currentIndex < endIndex {
            let char = text[currentIndex]
            if char == "\\" && text.index(after: currentIndex) < endIndex {
                currentIndex = text.index(after: text.index(after: currentIndex))
            } else if char == "\"" {
                return text.index(after: currentIndex)
            } else {
                currentIndex = text.index(after: currentIndex)
            }
        }
        
        return currentIndex
    }
    
    /// Skip over a line comment
    private func skipLineComment(from startIndex: String.Index, in text: String, upTo endIndex: String.Index) -> String.Index {
        var currentIndex = startIndex
        
        while currentIndex < endIndex && text[currentIndex] != "\n" {
            currentIndex = text.index(after: currentIndex)
        }
        
        if currentIndex < endIndex {
            currentIndex = text.index(after: currentIndex) // Skip newline
        }
        
        return currentIndex
    }
}