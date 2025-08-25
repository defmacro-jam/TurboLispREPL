import Foundation

/// Token description returned by `LispTokenizer`.
public struct LispToken {
    public enum Kind {
        case open(symbol: String)
        case close
        case atom(String)
    }
    public let kind: Kind
    public let range: NSRange
}

/// Protocol describing a tokenizer capable of producing `LispToken`s.
public protocol LispTokenizer {
    /// Resets the tokenizer to read tokens from `source`.
    func reset(with source: String)
    /// Retrieves the next token if available.
    func nextToken() -> LispToken?
}

/// Abstraction for caching line information so the editor can quickly
/// re-compute layout when scrolling.
public protocol LineCache {
    /// Records a checkpoint for the given range and source text.
    func checkpoint(range: NSRange, text: String)
}

/// Indents Lisp source code based on forms produced by a `LispTokenizer`.
public final class LispIndenter {
    /// Indentation rules for common special forms. The tuple represents
    /// `(first line indent, body indent)` measured in spaces.
    private let indentationTable: [String: (first: CGFloat, body: CGFloat)] = [
        "defun": (first: 2, body: 2),
        "let":   (first: 2, body: 2),
        "if":    (first: 2, body: 2)
    ]

    private let tokenizer: LispTokenizer
    private let layoutManager: NSLayoutManager
    private let lineCache: LineCache?

    public init(tokenizer: LispTokenizer,
                layoutManager: NSLayoutManager,
                lineCache: LineCache? = nil) {
        self.tokenizer = tokenizer
        self.layoutManager = layoutManager
        self.lineCache = lineCache
    }

    /// Applies indentation to the supplied `textStorage` within `range`.
    public func indent(_ textStorage: NSTextStorage, in range: NSRange) {
        tokenizer.reset(with: textStorage.string)
        var stack: [CGFloat] = [0]

        while let token = tokenizer.nextToken() {
            switch token.kind {
            case .open(let symbol):
                let base = stack.last ?? 0
                let rule = indentationTable[symbol] ?? (first: base + 2, body: base + 2)
                stack.append(rule.body)
                applyIndent(rule, range: token.range, in: textStorage)
            case .close:
                if stack.count > 1 { stack.removeLast() }
            case .atom:
                break
            }
        }

        layoutManager.invalidateLayout(forCharacterRange: range, actualCharacterRange: nil)
        lineCache?.checkpoint(range: range, text: textStorage.string)
    }

    private func applyIndent(_ rule: (first: CGFloat, body: CGFloat),
                             range: NSRange,
                             in textStorage: NSTextStorage) {
        let paragraph = NSMutableParagraphStyle()
        paragraph.firstLineHeadIndent = rule.first
        paragraph.headIndent = rule.body
        textStorage.addAttribute(.paragraphStyle, value: paragraph, range: range)
    }
}
