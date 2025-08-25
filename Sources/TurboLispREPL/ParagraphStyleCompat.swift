#if os(Linux)
import Foundation

public struct SimpleParagraphStyle {
    public var headIndent: CGFloat = 0
    public init() {}
}

public typealias NSParagraphStyle = SimpleParagraphStyle
public typealias NSMutableParagraphStyle = SimpleParagraphStyle
#else
import Foundation
#endif

