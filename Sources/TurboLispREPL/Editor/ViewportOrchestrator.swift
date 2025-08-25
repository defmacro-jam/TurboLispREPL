import Foundation

#if canImport(AppKit)
import AppKit

/// Orchestrates TextKit2 viewport events and token analysis.
@available(macOS 12.0, *)
public final class ViewportOrchestrator: NSObject, NSTextViewportLayoutControllerDelegate {
    private let layoutManager: NSTextLayoutManager
    private let viewportController: NSTextViewportLayoutController

    public init(layoutManager: NSTextLayoutManager, viewportController: NSTextViewportLayoutController) {
        self.layoutManager = layoutManager
        self.viewportController = viewportController
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

        // Placeholder for asynchronous token analysis of visible fragments.
        DispatchQueue.global(qos: .userInitiated).async { [layoutManager] in
            // A real implementation would analyze the fragments that intersect
            // `bounds` and update syntax highlighting or other decorations.
            _ = layoutManager // silence unused variable in the placeholder
        }
    }
}

#else
/// Platform placeholder for non-Apple platforms.
public final class ViewportOrchestrator {
    public init() {}
}
#endif

