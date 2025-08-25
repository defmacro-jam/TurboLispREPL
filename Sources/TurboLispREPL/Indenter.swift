import Foundation

public enum Indenter {
    public static func styles(for code: String, indentWidth: Int = 2) -> [NSParagraphStyle] {
        var level = 0
        var styles: [NSParagraphStyle] = []
        let lines = code.split(separator: "\n", omittingEmptySubsequences: false)
        for lineSub in lines {
            var line = String(lineSub)
            if let commentIndex = line.firstIndex(of: ";") {
                line = String(line[..<commentIndex])
            }
            var i = line.startIndex
            while i < line.endIndex {
                let c = line[i]
                if c == " " || c == "\t" {
                    i = line.index(after: i)
                    continue
                }
                if c == ")" {
                    level = max(0, level - 1)
                    i = line.index(after: i)
                    continue
                }
                break
            }
            var style = NSMutableParagraphStyle()
            style.headIndent = CGFloat(level * indentWidth)
            styles.append(style)
            var inString = false
            while i < line.endIndex {
                let c = line[i]
                if c == "\"" {
                    inString.toggle()
                } else if !inString {
                    if c == "(" { level += 1 }
                    else if c == ")" { level = max(0, level - 1) }
                }
                i = line.index(after: i)
            }
        }
        return styles
    }
}

