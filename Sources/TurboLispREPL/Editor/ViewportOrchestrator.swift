import Foundation

#if canImport(AppKit)
import AppKit

/// Orchestrates TextKit2 viewport events and token analysis.
@available(macOS 12.0, *)
public final class ViewportOrchestrator: NSObject, NSTextViewportLayoutControllerDelegate {
    private weak var textView: NSTextView?
    private let layoutManager: NSTextLayoutManager
    private let viewportController: NSTextViewportLayoutController
    private let reader: TurboLispReaderAPI

    public init(textView: NSTextView,
                reader: TurboLispReaderAPI = TurboLispReader()) {
        self.textView = textView
        self.layoutManager = textView.textLayoutManager
        self.viewportController = textView.textLayoutManager.textViewportLayoutController
        self.reader = reader
        super.init()
        self.viewportController.delegate = self
    }

    public func viewportBounds(for textViewportLayoutController: NSTextViewportLayoutController) -> CGRect {
        guard let textView else { return .zero }
        return textView.enclosingScrollView?.contentView.bounds ?? textView.visibleRect
    }

    public func textViewportLayoutController(_ textViewportLayoutController: NSTextViewportLayoutController,
                                             configureRenderingSurfaceFor textLayoutFragment: NSTextLayoutFragment) {
        // Rely on system-provided fragment views. No additional configuration.
    }

    public func textViewportLayoutControllerDidLayout(_ controller: NSTextViewportLayoutController) {
        guard let textView else { return }
        let bounds = viewportBounds(for: controller)
        textView.setNeedsDisplay(bounds)

        let startPoint = bounds.origin
        let endPoint = CGPoint(x: bounds.maxX, y: bounds.maxY)
        let startIndex = textView.characterIndexForInsertion(at: startPoint)
        let endIndex = textView.characterIndexForInsertion(at: endPoint)
        let visibleRange = NSRange(location: startIndex, length: max(0, endIndex - startIndex))

        let text = textView.string
        DispatchQueue.global(qos: .userInitiated).async { [reader] in
            _ = reader.tokenizeViewport(text: text, requestedRange: visibleRange)
        }
    }
}
#else
/// Platform placeholder for non-Apple platforms.
public final class ViewportOrchestrator {
    public init() {}
}
#endif
