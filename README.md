# TurboLisp REPL

This Swift package provides scaffolding for a TurboLisp REPL. It includes:

- `Editor/ViewportOrchestrator.swift` – placeholder orchestrator for TextKit2 viewport events.
- `Reader/LispTokenizer.swift` – minimal tokenizer for strings, comments, and parentheses.
- `Reader/LispIndenter.swift` – simple indentation engine with rules for `defun`, `let`, and `if`.

Unit tests for the tokenizer and indenter can be run with:

```bash
swift test
```
