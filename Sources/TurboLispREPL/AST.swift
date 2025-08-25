import Foundation

public enum Expr: Equatable {
    case symbol(String)
    case string(String)
    case list([Expr])
}

