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

    public func textViewportLayoutControllerDidLayout(_ controller: NSTextViewportLayoutController) {
        // In the real application this would trigger async analysis of visible lines.
    }
}

#else
/// Platform placeholder for non-Apple platforms.
public final class ViewportOrchestrator {
    public init() {}
}
#endif

