import Foundation

#if canImport(AppKit)
import AppKit

/// Orchestrates TextKit2 viewport events and token analysis.
@available(macOS 12.0, *)
public final class ViewportOrchestrator: NSObject, NSTextViewportLayoutControllerDelegate {
    private let layoutManager: NSTextLayoutManager
    private let viewportController: NSTextViewportLayoutController
    private let reader: TurboLispReaderAPI

    public init(layoutManager: NSTextLayoutManager,
                viewportController: NSTextViewportLayoutController,
                reader: TurboLispReaderAPI = TurboLispReader()) {
        self.layoutManager = layoutManager
        self.viewportController = viewportController
        self.reader = reader
        super.init()
        self.viewportController.delegate = self
    }

    public func viewportBounds(for textViewportLayoutController: NSTextViewportLayoutController) -> CGRect {
        // Return the visible rectangle of the backing text view.  If the layout
        // manager is not currently attached to a view we fall back to `.zero`.
        if let textView = layoutManager.textView {
            // Prefer the scroll view's content bounds if available to ensure we
            // account for any scrolling that has occurred.
            return textView.enclosingScrollView?.contentView.bounds ?? textView.visibleRect
        }
        return .zero
    }

    public func textViewportLayoutController(_ textViewportLayoutController: NSTextViewportLayoutController,
                                             configureRenderingSurfaceFor textLayoutFragment: NSTextLayoutFragment) {
        // Determine if the fragment lies inside the visible bounds and create a
        // rendering surface (a view backed by a layer) for it.  If the fragment
        // moves out of view, tear down any previously created surface.
        let visibleBounds = viewportBounds(for: textViewportLayoutController)

        if visibleBounds.intersects(textLayoutFragment.layoutFragmentFrame) {
            // The fragment is visible; ensure it has a view to render into.
            if textLayoutFragment.view == nil {
                let fragmentView = NSTextLayoutFragmentView(textLayoutFragment: textLayoutFragment)
                fragmentView.wantsLayer = true
                fragmentView.layer?.contentsScale = NSScreen.main?.backingScaleFactor ?? 2.0
                textLayoutFragment.view = fragmentView
            }
        } else {
            // Fragment left the viewport; release any rendering resources.
            if let view = textLayoutFragment.view {
                view.removeFromSuperview()
                textLayoutFragment.view = nil
            }
        }
    }

    public func textViewportLayoutControllerDidLayout(_ controller: NSTextViewportLayoutController) {
        // New fragments may have entered the viewport. Trigger a redraw of the
        // visible region and kick off any asynchronous analysis work.
        let bounds = viewportBounds(for: controller)
        layoutManager.textView?.setNeedsDisplay(bounds)

        // Determine the visible character range within the text view.
        guard let textView = layoutManager.textView else { return }
        let startPoint = bounds.origin
        let endPoint = CGPoint(x: bounds.maxX, y: bounds.maxY)
        let startIndex = textView.characterIndexForInsertion(at: startPoint)
        let endIndex = textView.characterIndexForInsertion(at: endPoint)
        let visibleRange = NSRange(location: startIndex, length: max(0, endIndex - startIndex))

        // Tokenize the visible range using the reader.  Results can later be
        // used for syntax highlighting or other decorations.
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

