import Foundation
#if canImport(CoreGraphics)
import CoreGraphics
#endif

public struct LineIndent {
    public let nsRange: NSRange
    public let firstHead: CGFloat
    public let head: CGFloat

    public init(nsRange: NSRange, firstHead: CGFloat, head: CGFloat) {
        self.nsRange = nsRange
        self.firstHead = firstHead
        self.head = head
    }
}

/// Simple indentation engine aware of `defun`, `let` and `if` forms.
public struct LispIndenter {
    public static func computeIndents(for text: String) -> [LineIndent] {
        let lines = text.split(separator: "\n", omittingEmptySubsequences: false)
        var results: [LineIndent] = []
        var depth = 0
        var specialFormStack: [Int] = []
        var position = 0
        for line in lines {
            let lineStr = String(line)
            let trimmed = lineStr.trimmingCharacters(in: .whitespaces)

            // Adjust for leading closing parens
            var tIdx = trimmed.startIndex
            while tIdx < trimmed.endIndex && trimmed[tIdx] == ")" {
                depth = max(0, depth - 1)
                if let last = specialFormStack.last, depth <= last { specialFormStack.removeLast() }
                tIdx = trimmed.index(after: tIdx)
            }

            var indent = depth * 2
            if let last = specialFormStack.last, last < depth {
                indent += 2
            }

            let nsRange = NSRange(location: position, length: lineStr.count)
            results.append(LineIndent(nsRange: nsRange, firstHead: CGFloat(indent), head: CGFloat(indent)))

            // Detect opening special form
            if trimmed.hasPrefix("(") {
                let afterParen = trimmed.dropFirst()
                let symbol = afterParen
                    .split(whereSeparator: { $0 == " " || $0 == "(" || $0 == ")" || $0 == "\n" })
                    .first
                if let sym = symbol, ["defun", "let", "if"].contains(String(sym)) {
                    specialFormStack.append(depth)
                }
            }

            // Update depth for next line
            for ch in lineStr {
                if ch == "(" {
                    depth += 1
                } else if ch == ")" {
                    depth = max(0, depth - 1)
                    if let last = specialFormStack.last, depth <= last { specialFormStack.removeLast() }
                }
            }

            position += lineStr.count + 1 // account for newline
        }
        return results
    }
}

