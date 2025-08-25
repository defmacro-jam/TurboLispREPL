import Foundation

public enum Printer {
    public static func print(_ expr: Expr) -> String {
        switch expr {
        case .symbol(let s):
            return s
        case .string(let s):
            return "\"\(s)\""
        case .list(let elems):
            return "(" + elems.map { print($0) }.joined(separator: " ") + ")"
        }
    }
}

