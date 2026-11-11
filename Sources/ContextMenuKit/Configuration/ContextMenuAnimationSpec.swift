import CoreGraphics
import Foundation

/// Timings and scales of the menu transitions. Defaults reproduce the reference animation.
public struct ContextMenuAnimationSpec: Sendable {
    /// Parameters of a spring animation.
    public struct Spring: Sendable, Equatable {
        public var duration: TimeInterval
        public var dampingRatio: CGFloat
        public var initialVelocity: CGFloat

        public init(duration: TimeInterval, dampingRatio: CGFloat, initialVelocity: CGFloat) {
            self.duration = duration
            self.dampingRatio = dampingRatio
            self.initialVelocity = initialVelocity
        }
    }

    public static var `default`: ContextMenuAnimationSpec {
        ContextMenuAnimationSpec()
    }

    /// Scale of the source view while it is pressed, before the preview lifts.
    public var pressDownScale: CGFloat = 0.97
    /// Duration of the press-down animation.
    public var pressDownDuration: TimeInterval = 0.2
    /// Spring that lifts the preview, expands the menu and the accessories and shows the backdrop.
    public var presentation = Spring(duration: 0.45, dampingRatio: 0.7, initialVelocity: 2)
    /// Scale of the menu collapsed into its corner next to the source view.
    public var collapsedMenuScale: CGFloat = 0.1
    /// Scale of a collapsed accessory with the ``ContextMenuAccessory/Transition/scale`` transition.
    public var collapsedAccessoryScale: CGFloat = 0.1
    /// Duration of the animation that returns the preview to the source view.
    public var dismissalDuration: TimeInterval = 0.2
    /// Duration of the final cross-fade from the preview to the source view.
    /// `0` removes the preview right after it has landed.
    public var previewFadeOutDuration: TimeInterval = 0.15

    public init() { }
}
