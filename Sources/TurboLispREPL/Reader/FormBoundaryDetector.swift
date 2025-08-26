import Foundation

/// Detects form boundaries in Lisp code for context-aware tokenization
public struct FormBoundaryDetector {
    
    /// Find the complete form(s) containing the given range
    /// Expands outward from the requested range to encompass complete S-expressions
    public static func expandToFormBoundaries(_ range: NSRange, in text: String) -> NSRange {
        guard !text.isEmpty else { return NSRange(location: 0, length: 0) }
        
        // Convert to String indices for easier manipulation
        let startIndex = text.index(text.startIndex, offsetBy: min(range.location, text.count))
        let endIndex = text.index(text.startIndex, offsetBy: min(NSMaxRange(range), text.count))
        
        // Find the start of the enclosing form
        let formStart = scanBackwardForFormStart(from: startIndex, in: text)
        
        // Find the end of the enclosing form
        let formEnd = scanForwardForFormEnd(from: endIndex, in: text)
        
        // Convert back to NSRange
        let startOffset = text.distance(from: text.startIndex, to: formStart)
        let endOffset = text.distance(from: text.startIndex, to: formEnd)
        
        return NSRange(location: startOffset, length: endOffset - startOffset)
    }
    
    /// Scan backward to find the start of the enclosing form
    static func scanBackwardForFormStart(from position: String.Index, in text: String) -> String.Index {
        var currentIndex = position
        var parenDepth = 0
        var inString = false
        var inLineComment = false
        var inBlockComment = false
        var blockCommentDepth = 0
        
        // If we're at the beginning, return it
        if currentIndex <= text.startIndex {
            return text.startIndex
        }
        
        // Move back one to start checking
        currentIndex = text.index(before: currentIndex)
        
        while currentIndex > text.startIndex {
            let char = text[currentIndex]
            let prevChar = currentIndex > text.startIndex ? text[text.index(before: currentIndex)] : nil
            
            // Handle block comments
            if !inString && !inLineComment {
                if char == "|" && prevChar == "#" {
                    if inBlockComment {
                        blockCommentDepth += 1
                    } else if blockCommentDepth == 0 {
                        // Entering a block comment (going backward)
                        inBlockComment = true
                        blockCommentDepth = 1
                    }
                } else if char == "#" && text.index(after: currentIndex) < text.endIndex && 
                          text[text.index(after: currentIndex)] == "|" {
                    if inBlockComment {
                        blockCommentDepth -= 1
                        if blockCommentDepth == 0 {
                            inBlockComment = false
                        }
                    }
                }
            }
            
            // Skip if in block comment
            if inBlockComment {
                currentIndex = text.index(before: currentIndex)
                continue
            }
            
            // Handle line comments (scanning backward)
            if char == "\n" {
                inLineComment = false
            } else if !inString && char == ";" {
                // Check if we're entering a comment (need to scan forward from here to EOL)
                var checkIndex = currentIndex
                inLineComment = true
                while checkIndex < position && text[checkIndex] != "\n" {
                    checkIndex = text.index(after: checkIndex)
                }
                // If our original position was within this comment line, we're in a comment
                if checkIndex >= position {
                    currentIndex = text.index(before: currentIndex)
                    continue
                }
                inLineComment = false
            }
            
            // Skip if in line comment
            if inLineComment {
                currentIndex = text.index(before: currentIndex)
                continue
            }
            
            // Handle strings
            if char == "\"" && prevChar != "\\" {
                inString = !inString
            }
            
            // Handle parentheses (only if not in string)
            if !inString {
                if char == ")" {
                    parenDepth += 1  // Going backward, ) increases depth
                } else if char == "(" {
                    if parenDepth > 0 {
                        parenDepth -= 1
                    } else {
                        // Found the start of the enclosing form
                        return currentIndex
                    }
                }
            }
            
            if currentIndex == text.startIndex {
                break
            }
            currentIndex = text.index(before: currentIndex)
        }
        
        // Reached beginning of text
        return text.startIndex
    }
    
    /// Scan forward to find the end of the enclosing form
    static func scanForwardForFormEnd(from position: String.Index, in text: String) -> String.Index {
        var currentIndex = position
        var parenDepth = 0
        var inString = false
        var inLineComment = false
        var inBlockComment = false
        var blockCommentDepth = 0
        
        while currentIndex < text.endIndex {
            let char = text[currentIndex]
            let prevChar = currentIndex > text.startIndex ? text[text.index(before: currentIndex)] : nil
            
            // Handle block comments
            if !inString && !inLineComment {
                if prevChar == "#" && char == "|" {
                    inBlockComment = true
                    blockCommentDepth = 1
                } else if inBlockComment && prevChar == "|" && char == "#" {
                    blockCommentDepth -= 1
                    if blockCommentDepth == 0 {
                        inBlockComment = false
                    }
                } else if inBlockComment && prevChar == "#" && char == "|" {
                    blockCommentDepth += 1
                }
            }
            
            // Skip if in block comment
            if inBlockComment {
                currentIndex = text.index(after: currentIndex)
                continue
            }
            
            // Handle line comments
            if !inString {
                if char == ";" {
                    inLineComment = true
                } else if char == "\n" {
                    inLineComment = false
                }
            }
            
            // Skip if in line comment
            if inLineComment {
                currentIndex = text.index(after: currentIndex)
                continue
            }
            
            // Handle strings
            if char == "\"" && prevChar != "\\" {
                inString = !inString
            }
            
            // Handle parentheses (only if not in string)
            if !inString {
                if char == "(" {
                    parenDepth += 1
                } else if char == ")" {
                    if parenDepth > 0 {
                        parenDepth -= 1
                    } else {
                        // Found the end of the enclosing form
                        return text.index(after: currentIndex)
                    }
                }
            }
            
            currentIndex = text.index(after: currentIndex)
        }
        
        // Reached end of text
        return text.endIndex
    }
    
    /// Check if parentheses are balanced up to a given position
    public static func checkBalance(upTo position: Int, in text: String) -> ParenBalance {
        var openCount = 0
        var inString = false
        var inLineComment = false
        var inBlockComment = false
        var blockCommentDepth = 0
        
        let endIndex = text.index(text.startIndex, offsetBy: min(position, text.count))
        var currentIndex = text.startIndex
        
        while currentIndex < endIndex {
            let char = text[currentIndex]
            let prevChar = currentIndex > text.startIndex ? text[text.index(before: currentIndex)] : nil
            
            // Handle block comments
            if !inString && !inLineComment {
                if prevChar == "#" && char == "|" {
                    inBlockComment = true
                    blockCommentDepth = 1
                } else if inBlockComment && prevChar == "|" && char == "#" {
                    blockCommentDepth -= 1
                    if blockCommentDepth == 0 {
                        inBlockComment = false
                    }
                } else if inBlockComment && prevChar == "#" && char == "|" {
                    blockCommentDepth += 1
                }
            }
            
            if !inBlockComment {
                // Handle line comments
                if !inString {
                    if char == ";" {
                        inLineComment = true
                    } else if char == "\n" {
                        inLineComment = false
                    }
                }
                
                if !inLineComment {
                    // Handle strings
                    if char == "\"" && prevChar != "\\" {
                        inString = !inString
                    }
                    
                    // Count parentheses
                    if !inString {
                        if char == "(" {
                            openCount += 1
                        } else if char == ")" {
                            openCount -= 1
                            if openCount < 0 {
                                return .unbalanced(extraClose: abs(openCount))
                            }
                        }
                    }
                }
            }
            
            currentIndex = text.index(after: currentIndex)
        }
        
        if openCount == 0 {
            return .balanced
        } else {
            return .unbalanced(extraOpen: openCount)
        }
    }
    
    /// Represents the balance state of parentheses
    public enum ParenBalance: Equatable {
        case balanced
        case unbalanced(extraOpen: Int = 0, extraClose: Int = 0)
        
        public var isBalanced: Bool {
            if case .balanced = self { return true }
            return false
        }
    }
}