import Foundation
#if canImport(AppKit)
import AppKit
#endif

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
public protocol LispTokenizerProtocol {
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
    /// `(first line indent, body indent)` measured in spaces. Rules are
    /// constructed from `Resources/SpecialForms.json`.
    #if canImport(CoreGraphics)
    private let indentationTable: [String: (first: CGFloat, body: CGFloat)]
    #else
    private let indentationTable: [String: (first: Double, body: Double)]
    #endif

    private let tokenizer: LispTokenizerProtocol
    #if canImport(AppKit)
    private let layoutManager: NSLayoutManager
    #endif
    private let lineCache: LineCache?

    #if canImport(AppKit)
    public init(tokenizer: LispTokenizerProtocol,
                layoutManager: NSLayoutManager,
                lineCache: LineCache? = nil) {
        self.tokenizer = tokenizer
        self.layoutManager = layoutManager
        self.lineCache = lineCache
        self.indentationTable = LispIndenter.buildIndentationTable()
    }
    #else
    public init(tokenizer: LispTokenizerProtocol,
                lineCache: LineCache? = nil) {
        self.tokenizer = tokenizer
        self.lineCache = lineCache
        self.indentationTable = LispIndenter.buildIndentationTable()
    }
    #endif

    #if canImport(AppKit)
    /// Applies indentation to the supplied `textStorage` within `range`.
    public func indent(_ textStorage: NSTextStorage, in range: NSRange) {
        tokenizer.reset(with: textStorage.string)
        #if canImport(CoreGraphics)
        var stack: [CGFloat] = [0]
        #else
        var stack: [Double] = [0]
        #endif

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

    #if canImport(CoreGraphics)
    private func applyIndent(_ rule: (first: CGFloat, body: CGFloat),
                             range: NSRange,
                             in textStorage: NSTextStorage) {
        let paragraph = NSMutableParagraphStyle()
        paragraph.firstLineHeadIndent = rule.first
        paragraph.headIndent = rule.body
        textStorage.addAttribute(.paragraphStyle, value: paragraph, range: range)
    }
    #else
    private func applyIndent(_ rule: (first: Double, body: Double),
                             range: NSRange,
                             in textStorage: NSTextStorage) {
        let paragraph = NSMutableParagraphStyle()
        paragraph.firstLineHeadIndent = CGFloat(rule.first)
        paragraph.headIndent = CGFloat(rule.body)
        textStorage.addAttribute(.paragraphStyle, value: paragraph, range: range)
    }
    #endif
    #endif
}

private extension LispIndenter {
    /// Load special form names from the bundled JSON file.
    static func loadSpecialForms() -> [String] {
        guard let url = Bundle.module.url(forResource: "SpecialForms", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let names = try? JSONDecoder().decode([String].self, from: data) else {
            return []
        }
        return names
    }

    #if canImport(CoreGraphics)
    static func buildIndentationTable() -> [String: (first: CGFloat, body: CGFloat)] {
        var table: [String: (first: CGFloat, body: CGFloat)] = [:]
        for form in loadSpecialForms() {
            table[form] = (first: 2, body: 2)
        }
        return table
    }
    #else
    static func buildIndentationTable() -> [String: (first: Double, body: Double)] {
        var table: [String: (first: Double, body: Double)] = [:]
        for form in loadSpecialForms() {
            table[form] = (first: 2, body: 2)
        }
        return table
    }
    #endif
}
