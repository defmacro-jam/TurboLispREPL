import Foundation

/// Main implementation of the TurboLisp reader API
public class TurboLispReader: TurboLispReaderAPI {
    
    private let tokenizer = ContextAwareTokenizer()
    private var formCache: [NSRange: FormInfo] = [:]
    private let cacheTimeout: TimeInterval = 1.0  // Cache for 1 second
    
    public init() {}
    
    /// Tokenize a viewport range, expanding to form boundaries for context
    public func tokenizeViewport(text: String, requestedRange: NSRange) -> [TokenSpan] {
        // Step 1: Expand to form boundaries
        let expandedRange = FormBoundaryDetector.expandToFormBoundaries(requestedRange, in: text)
        
        // Step 2: Check cache
        if let cached = formCache[expandedRange],
           Date().timeIntervalSince(cached.timestamp) < cacheTimeout {
            // Return only tokens in requested range
            return cached.tokens.filter { tokenIntersects($0, with: requestedRange) }
        }
        
        // Step 3: Determine context
        let context = tokenizer.contextAt(position: expandedRange.location, in: text)
        
        // Step 4: Tokenize complete form
        let allTokens = tokenizer.tokenize(text: text, range: expandedRange, context: context)
        
        // Step 5: Cache results
        formCache[expandedRange] = FormInfo(
            range: expandedRange,
            tokens: allTokens,
            context: context
        )
        
        // Clean old cache entries
        cleanCache()
        
        // Step 6: Return only requested range
        return allTokens.filter { tokenIntersects($0, with: requestedRange) }
    }
    
    /// Check if the text represents a complete form
    public func isFormComplete(text: String) -> FormCompletionStatus {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            return .incomplete(expecting: "form")
        }
        
        // Check parenthesis balance
        let balance = FormBoundaryDetector.checkBalance(upTo: text.count, in: text)
        
        switch balance {
        case .balanced:
            // Additional check: ensure we have at least one complete form
            if hasCompleteForm(text) {
                return .complete
            } else {
                return .incomplete(expecting: "complete form")
            }
            
        case .unbalanced(let extraOpen, _) where extraOpen > 0:
            return .incomplete(expecting: "\(extraOpen) closing parenthes\(extraOpen == 1 ? "is" : "es")")
            
        case .unbalanced(_, let extraClose) where extraClose > 0:
            return .invalid(error: "\(extraClose) extra closing parenthes\(extraClose == 1 ? "is" : "es")")
            
        default:
            return .invalid(error: "Invalid parenthesis structure")
        }
    }
    
    /// Calculate indentation for a given line
    public func calculateIndent(forLine lineNumber: Int, in text: String) -> IndentInfo {
        let lines = text.components(separatedBy: "\n")
        guard lineNumber >= 0 && lineNumber < lines.count else {
            return IndentInfo(level: 0)
        }
        
        // Find the position of the line start
        var position = 0
        for i in 0..<lineNumber {
            position += lines[i].count + 1  // +1 for newline
        }
        
        // Get context at this position
        let context = tokenizer.contextAt(position: position, in: text)
        
        // Calculate indent based on depth and form type
        var indentLevel = context.depth * 2
        
        // Special handling for certain forms
        if let formType = context.formType {
            if ["defun", "defmacro", "let", "let*", "labels", "flet"].contains(formType) {
                // These forms typically have special indentation rules
                indentLevel += 2
            }
        }
        
        return IndentInfo(
            level: indentLevel,
            isSpecialForm: context.formType != nil,
            formName: context.formType
        )
    }
    
    /// Find matching parenthesis
    public func findMatchingParen(at position: Int, in text: String) -> Int? {
        guard position >= 0 && position < text.count else { return nil }
        
        let index = text.index(text.startIndex, offsetBy: position)
        let char = text[index]
        
        if char == "(" {
            return findClosingParen(from: position, in: text)
        } else if char == ")" {
            return findOpeningParen(from: position, in: text)
        }
        
        return nil
    }
    
    /// Check parenthesis balance up to a position
    public func parenBalance(upTo position: Int, in text: String) -> FormBoundaryDetector.ParenBalance {
        return FormBoundaryDetector.checkBalance(upTo: position, in: text)
    }
    
    /// Get symbol information at a position
    public func symbolAt(position: Int, in text: String) -> SymbolInfo? {
        guard position >= 0 && position < text.count else { return nil }
        
        // Find symbol boundaries
        var start = position
        var end = position
        
        // Scan backward for symbol start
        while start > 0 {
            let prevIndex = text.index(text.startIndex, offsetBy: start - 1)
            let prevChar = text[prevIndex]
            if isSymbolChar(prevChar) {
                start -= 1
            } else {
                break
            }
        }
        
        // Scan forward for symbol end
        while end < text.count {
            let nextIndex = text.index(text.startIndex, offsetBy: end)
            let nextChar = text[nextIndex]
            if isSymbolChar(nextChar) {
                end += 1
            } else {
                break
            }
        }
        
        guard start < end else { return nil }
        
        let symbolStart = text.index(text.startIndex, offsetBy: start)
        let symbolEnd = text.index(text.startIndex, offsetBy: end)
        let symbolName = String(text[symbolStart..<symbolEnd])
        
        // Get context to determine symbol type
        let context = tokenizer.contextAt(position: position, in: text)
        let symbolType = classifySymbol(symbolName, context: context)
        
        return SymbolInfo(
            name: symbolName,
            range: NSRange(location: start, length: end - start),
            type: symbolType,
            context: context
        )
    }
    
    /// Get form boundaries at a position
    public func formBoundariesAt(position: Int, in text: String) -> NSRange? {
        guard position >= 0 && position <= text.count else { return nil }
        
        // Use FormBoundaryDetector to find the enclosing form
        let range = NSRange(location: position, length: 0)
        let boundaries = FormBoundaryDetector.expandToFormBoundaries(range, in: text)
        
        // Check if we found valid boundaries
        if boundaries.length > 0 {
            return boundaries
        }
        
        return nil
    }
    
    // MARK: - Private Helpers
    
    private func tokenIntersects(_ token: TokenSpan, with range: NSRange) -> Bool {
        let tokenRange = NSRange(location: token.location, length: token.length)
        return NSIntersectionRange(tokenRange, range).length > 0
    }
    
    private func hasCompleteForm(_ text: String) -> Bool {
        // Simple check: must start with ( and have balanced parens
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.starts(with: "(") || trimmed.starts(with: "'(") || trimmed.starts(with: "`(")
    }
    
    private func findClosingParen(from position: Int, in text: String) -> Int? {
        var depth = 1
        var index = text.index(text.startIndex, offsetBy: position + 1)
        var currentPosition = position + 1
        
        while index < text.endIndex {
            let char = text[index]
            
            // Skip strings
            if char == "\"" {
                index = skipString(from: index, in: text)
                currentPosition = text.distance(from: text.startIndex, to: index)
                continue
            }
            
            // Skip comments
            if char == ";" {
                index = skipToEndOfLine(from: index, in: text)
                currentPosition = text.distance(from: text.startIndex, to: index)
                continue
            }
            
            if char == "(" {
                depth += 1
            } else if char == ")" {
                depth -= 1
                if depth == 0 {
                    return currentPosition
                }
            }
            
            index = text.index(after: index)
            currentPosition += 1
        }
        
        return nil
    }
    
    private func findOpeningParen(from position: Int, in text: String) -> Int? {
        var depth = 1
        guard position > 0 else { return nil }
        
        var index = text.index(text.startIndex, offsetBy: position - 1)
        var currentPosition = position - 1
        
        while currentPosition >= 0 {
            let char = text[index]
            
            // Skip strings (backward)
            if char == "\"" && !isEscaped(at: index, in: text) {
                index = skipStringBackward(from: index, in: text)
                currentPosition = text.distance(from: text.startIndex, to: index)
                if currentPosition <= 0 { break }
                index = text.index(before: index)
                currentPosition -= 1
                continue
            }
            
            if char == ")" {
                depth += 1
            } else if char == "(" {
                depth -= 1
                if depth == 0 {
                    return currentPosition
                }
            }
            
            if currentPosition == 0 { break }
            index = text.index(before: index)
            currentPosition -= 1
        }
        
        return nil
    }
    
    private func isSymbolChar(_ char: Character) -> Bool {
        return char.isLetter || char.isNumber || 
               "-+*/<>=!?_".contains(char)
    }
    
    private func classifySymbol(_ name: String, context: FormContext) -> SymbolType {
        if name.starts(with: ":") {
            return .keyword
        }
        
        let specialForms = ["defun", "defmacro", "let", "let*", "if", "when", "unless"]
        if specialForms.contains(name.lowercased()) {
            return .specialForm
        }
        
        // More classification logic can be added here
        return .unknown
    }
    
    private func skipString(from index: String.Index, in text: String) -> String.Index {
        var currentIndex = text.index(after: index)  // Skip opening quote
        
        while currentIndex < text.endIndex {
            let char = text[currentIndex]
            if char == "\\" && text.index(after: currentIndex) < text.endIndex {
                currentIndex = text.index(after: text.index(after: currentIndex))
            } else if char == "\"" {
                return text.index(after: currentIndex)
            } else {
                currentIndex = text.index(after: currentIndex)
            }
        }
        
        return currentIndex
    }
    
    private func skipStringBackward(from index: String.Index, in text: String) -> String.Index {
        guard index > text.startIndex else { return index }
        var currentIndex = text.index(before: index)  // Skip closing quote
        
        while currentIndex > text.startIndex {
            let char = text[currentIndex]
            if char == "\"" && !isEscaped(at: currentIndex, in: text) {
                return currentIndex
            }
            currentIndex = text.index(before: currentIndex)
        }
        
        return text.startIndex
    }
    
    private func skipToEndOfLine(from index: String.Index, in text: String) -> String.Index {
        var currentIndex = index
        
        while currentIndex < text.endIndex && text[currentIndex] != "\n" {
            currentIndex = text.index(after: currentIndex)
        }
        
        return currentIndex
    }
    
    private func isEscaped(at index: String.Index, in text: String) -> Bool {
        guard index > text.startIndex else { return false }
        
        var backslashCount = 0
        var checkIndex = text.index(before: index)
        
        while checkIndex >= text.startIndex && text[checkIndex] == "\\" {
            backslashCount += 1
            if checkIndex == text.startIndex { break }
            checkIndex = text.index(before: checkIndex)
        }
        
        return backslashCount % 2 == 1
    }
    
    private func cleanCache() {
        let now = Date()
        formCache = formCache.filter { _, info in
            now.timeIntervalSince(info.timestamp) < cacheTimeout
        }
    }
}