import XCTest
@testable import TurboLispREPL

#if canImport(AppKit)
import AppKit

final class IndenterTests: XCTestCase {
    func testIndentationForSpecialForms() {
        let code = """
(defun foo ()
  (let ((a 1)
        (b 2))
    (if (> a b)
        a
        b)))
"""
        
        // Create tokenizer and other required components
        let tokenizer = StandardLispTokenizer()
        let textStorage = NSTextStorage(string: code)
        let layoutManager = NSLayoutManager()
        let textContainer = NSTextContainer()
        layoutManager.addTextContainer(textContainer)
        textStorage.addLayoutManager(layoutManager)
        
        // Create indenter
        let indenter = LispIndenter(tokenizer: tokenizer, layoutManager: layoutManager)
        
        // Apply indentation
        let range = NSRange(location: 0, length: code.count)
        indenter.indent(textStorage, in: range)
        
        // Verify that the text storage has paragraph style attributes applied
        var hasIndentation = false
        textStorage.enumerateAttribute(.paragraphStyle, in: range, options: []) { value, range, stop in
            if let _ = value as? NSParagraphStyle {
                hasIndentation = true
            }
        }
        
        XCTAssertTrue(hasIndentation, "Indentation should be applied to the text")
        
        // Verify tokenizer works correctly
        tokenizer.reset(with: code)
        var tokenCount = 0
        while let _ = tokenizer.nextToken() {
            tokenCount += 1
        }
        XCTAssertGreaterThan(tokenCount, 0, "Should have parsed some tokens")
    }
    
    func testTokenizerProtocolImplementation() {
        let tokenizer = StandardLispTokenizer()
        let source = "(defun test ())"
        
        tokenizer.reset(with: source)
        
        // First token should be opening paren with symbol "defun"
        if let token = tokenizer.nextToken() {
            switch token.kind {
            case .open(let symbol):
                XCTAssertEqual(symbol, "defun")
            default:
                XCTFail("First token should be opening paren")
            }
        } else {
            XCTFail("Should have a first token")
        }
        
        // Continue getting tokens
        var tokens: [LispToken] = []
        while let token = tokenizer.nextToken() {
            tokens.append(token)
        }
        
        XCTAssertGreaterThan(tokens.count, 0, "Should have more tokens")
    }
}

#else

// Fallback tests for non-macOS platforms
final class IndenterTests: XCTestCase {
    func testTokenizerBasicFunctionality() {
        let source = "(defun foo \"bar\" ; comment\n)"
        let tokens = LispTokenizer.tokenize(source)
        
        // Verify we get some tokens
        XCTAssertGreaterThan(tokens.count, 0, "Should parse some tokens")
        
        // Check that we have the expected token kinds
        let hasParens = tokens.contains { $0.kind == TokenKind.paren.rawValue }
        let hasString = tokens.contains { $0.kind == TokenKind.string.rawValue }
        let hasComment = tokens.contains { $0.kind == TokenKind.comment.rawValue }
        
        XCTAssertTrue(hasParens, "Should have parenthesis tokens")
        XCTAssertTrue(hasString, "Should have string token")
        XCTAssertTrue(hasComment, "Should have comment token")
    }
    
    func testStandardLispTokenizer() {
        let tokenizer = StandardLispTokenizer()
        let source = "(let ((x 1)))"

        tokenizer.reset(with: source)

        var tokenCount = 0
        while let _ = tokenizer.nextToken() {
            tokenCount += 1
        }

        XCTAssertGreaterThan(tokenCount, 0, "Should parse tokens")
    }

    func testStandardLispTokenizerHandlesComments() {
        let tokenizer = StandardLispTokenizer()
        let source = "; hello\n()"
        tokenizer.reset(with: source)

        guard let token = tokenizer.nextToken() else {
            XCTFail("Expected a comment token")
            return
        }

        switch token.kind {
        case .comment(let text):
            XCTAssertEqual(text, "; hello")
        default:
            XCTFail("First token should be a comment")
        }
    }

    func testDeeplyNestedForms() {
        let depth = 50
        let source = String(repeating: "(", count: depth) + String(repeating: ")", count: depth)
        let tokenizer = StandardLispTokenizer()
        tokenizer.reset(with: source)
        var openCount = 0
        var closeCount = 0
        while let token = tokenizer.nextToken() {
            switch token.kind {
            case .open:
                openCount += 1
            case .close:
                closeCount += 1
            default:
                break
            }
        }
        XCTAssertEqual(openCount, depth, "All opening parens should be tokenized")
        XCTAssertEqual(closeCount, depth, "All closing parens should be tokenized")
    }

    func testUnmatchedParentheses() {
        let missingClose = "(foo (bar 1)"
        let extraClose = "(foo 1))"
        let tokenizer = StandardLispTokenizer()

        tokenizer.reset(with: missingClose)
        var openCount = 0
        var closeCount = 0
        while let token = tokenizer.nextToken() {
            switch token.kind {
            case .open:
                openCount += 1
            case .close:
                closeCount += 1
            default:
                break
            }
        }
        XCTAssertTrue(openCount > closeCount, "Missing closing paren should leave more opens than closes")

        tokenizer.reset(with: extraClose)
        openCount = 0
        closeCount = 0
        while let token = tokenizer.nextToken() {
            switch token.kind {
            case .open:
                openCount += 1
            case .close:
                closeCount += 1
            default:
                break
            }
        }
        XCTAssertTrue(closeCount > openCount, "Extra closing paren should yield more closes than opens")
    }
}

#endif