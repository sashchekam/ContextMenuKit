import UIKit

/// Lets the view of a ``ContextMenuAccessory`` follow the menu: point a tail at the preview,
/// run its own animations along with the presentation.
///
/// ```swift
/// final class ReactionsPanel: UIView, ContextMenuAccessoryView {
///     func contextMenuAccessoryWillPresent(_ context: ContextMenuAccessoryContext) {
///         tailCenterX = context.previewFrame.minX + 24
///         animateButtonsIn()
///     }
/// }
/// ```
///
/// Every method has an empty default implementation. SwiftUI views of accessories don't get these calls.
@MainActor
public protocol ContextMenuAccessoryView: UIView {
    /// Called once the layout is ready, right before the preview starts to lift.
    func contextMenuAccessoryWillPresent(_ context: ContextMenuAccessoryContext)

    /// Called when the presentation animation has finished.
    func contextMenuAccessoryDidPresent()

    /// Called when the dismissal starts.
    func contextMenuAccessoryWillDismiss()
}

public extension ContextMenuAccessoryView {
    /// Does nothing by default.
    func contextMenuAccessoryWillPresent(_ context: ContextMenuAccessoryContext) { }

    /// Does nothing by default.
    func contextMenuAccessoryDidPresent() { }

    /// Does nothing by default.
    func contextMenuAccessoryWillDismiss() { }
}

/// What the view of an accessory learns right before the presentation.
public struct ContextMenuAccessoryContext: Equatable, Sendable {
    /// Frame of the preview in the coordinate space of the accessory, once the menu is presented.
    public var previewFrame: CGRect
    /// Frame of the menu in the coordinate space of the accessory, once the menu is presented.
    /// Its height is zero for a menu without items.
    public var menuFrame: CGRect
    /// The spring that lifts the preview, to keep your own animations in step with it.
    public var presentationAnimation: ContextMenuAnimationSpec.Spring

    public init(previewFrame: CGRect, menuFrame: CGRect, presentationAnimation: ContextMenuAnimationSpec.Spring) {
        self.previewFrame = previewFrame
        self.menuFrame = menuFrame
        self.presentationAnimation = presentationAnimation
    }
}
