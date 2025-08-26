import Foundation

/// Main API protocol for the TurboLisp reader, designed for TextKit2 integration
public protocol TurboLispReaderAPI {
    /// Tokenize a viewport range, expanding to form boundaries for context
    func tokenizeViewport(text: String, requestedRange: NSRange) -> [TokenSpan]
    
    /// Check if the text represents a complete form (for REPL)
    func isFormComplete(text: String) -> FormCompletionStatus
    
    /// Calculate indentation for a given line
    func calculateIndent(forLine lineNumber: Int, in text: String) -> IndentInfo
    
    /// Find matching parenthesis
    func findMatchingParen(at position: Int, in text: String) -> Int?
    
    /// Check parenthesis balance up to a position
    func parenBalance(upTo position: Int, in text: String) -> FormBoundaryDetector.ParenBalance
    
    /// Get symbol information at a position
    func symbolAt(position: Int, in text: String) -> SymbolInfo?
    
    /// Get form boundaries at a position (useful for navigation)
    func formBoundariesAt(position: Int, in text: String) -> NSRange?
}

/// Status of form completion
public enum FormCompletionStatus: Equatable {
    case complete
    case incomplete(expecting: String)
    case invalid(error: String)
    
    public var isComplete: Bool {
        if case .complete = self { return true }
        return false
    }
}

/// Information about indentation
public struct IndentInfo: Equatable {
    public let level: Int
    public let isSpecialForm: Bool
    public let formName: String?
    
    public init(level: Int, isSpecialForm: Bool = false, formName: String? = nil) {
        self.level = level
        self.isSpecialForm = isSpecialForm
        self.formName = formName
    }
}

/// Information about a symbol
public struct SymbolInfo: Equatable {
    public let name: String
    public let range: NSRange
    public let type: SymbolType
    public let context: FormContext?
    
    public init(name: String, range: NSRange, type: SymbolType, context: FormContext? = nil) {
        self.name = name
        self.range = range
        self.type = type
        self.context = context
    }
}

/// Types of symbols
public enum SymbolType: Equatable {
    case function
    case specialForm
    case macro
    case variable
    case parameter
    case keyword
    case unknown
}

/// Context of a form
public struct FormContext: Equatable {
    public let formType: String?
    public let depth: Int
    public let isQuoted: Bool
    public let parentForm: String?
    
    public init(formType: String? = nil, depth: Int = 0, isQuoted: Bool = false, parentForm: String? = nil) {
        self.formType = formType
        self.depth = depth
        self.isQuoted = isQuoted
        self.parentForm = parentForm
    }
}

/// Information about a cached form
struct FormInfo {
    let range: NSRange
    let tokens: [TokenSpan]
    let context: FormContext
    let timestamp: Date
    
    init(range: NSRange, tokens: [TokenSpan], context: FormContext) {
        self.range = range
        self.tokens = tokens
        self.context = context
        self.timestamp = Date()
    }
}

// Token type mappings will be handled differently to avoid concurrency issues
// We'll use the existing TokenKind enum values directly in the tokenizer