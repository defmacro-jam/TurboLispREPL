# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Commands

### Building and Testing
```bash
# Build the Swift package
swift build

# Run all tests
swift test

# Run a specific test
swift test --filter TokenizerTests
swift test --filter IndenterTests
```

### Known Build Issue
The ViewportOrchestrator class has missing protocol conformance methods that need to be implemented for NSTextViewportLayoutControllerDelegate. The required methods are:
- `viewportBounds(for:)`
- `textViewportLayoutController(_:configureRenderingSurfaceFor:)`

## Architecture

### Core Components

**LispTokenizer** (`Sources/TurboLispREPL/Reader/LispTokenizer.swift`)
- Recognizes three token types: strings, comments, and parentheses
- Returns array of TokenSpan objects with location, length, and kind
- Uses character-by-character parsing with special handling for escape sequences in strings

**LispIndenter** (`Sources/TurboLispREPL/Reader/LispIndenter.swift`)
- Computes indentation for Lisp code with special handling for `defun`, `let`, and `if` forms
- Maintains a depth counter and special form stack to determine proper indentation
- Returns LineIndent objects with NSRange and CGFloat indentation values
- Base indentation is 2 spaces per depth level, with additional 2 spaces for special forms

**ViewportOrchestrator** (`Sources/TurboLispREPL/Editor/ViewportOrchestrator.swift`)
- TextKit2 integration for macOS 12.0+
- Placeholder implementation for viewport layout events
- Has cross-platform fallback for non-Apple platforms

### Package Structure
- Swift 6.1 package with a single library target "TurboLispREPL"
- Test target "TurboLispREPLTests" with unit tests for tokenizer and indenter
- Conditional compilation for platform-specific features (AppKit/CoreGraphics on macOS)