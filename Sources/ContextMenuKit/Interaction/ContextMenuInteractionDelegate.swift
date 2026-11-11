import CoreGraphics

/// Provides the menu configuration and observes the menu lifecycle.
///
/// Only ``contextMenuInteraction(_:configurationAt:)`` is required, lifecycle methods are optional.
@MainActor
public protocol ContextMenuInteractionDelegate: AnyObject {
    /// Returns the configuration of the menu, or `nil` to not show any menu.
    /// - Parameters:
    ///   - interaction: The interaction asking for a menu.
    ///   - location: Touch location in the coordinate space of the interaction's view.
    func contextMenuInteraction(
        _ interaction: ContextMenuInteraction,
        configurationAt location: CGPoint
    ) -> ContextMenuConfiguration?

    /// Called right before the preview starts to lift.
    func contextMenuInteractionWillPresent(_ interaction: ContextMenuInteraction)

    /// Called when the presentation animation has finished.
    func contextMenuInteractionDidPresent(_ interaction: ContextMenuInteraction)

    /// Called when the dismissal starts.
    func contextMenuInteractionWillDismiss(_ interaction: ContextMenuInteraction)

    /// Called after the overlay is removed and right before the selected action's handler runs.
    func contextMenuInteractionDidDismiss(_ interaction: ContextMenuInteraction)
}

public extension ContextMenuInteractionDelegate {
    /// Does nothing by default.
    func contextMenuInteractionWillPresent(_ interaction: ContextMenuInteraction) { }

    /// Does nothing by default.
    func contextMenuInteractionDidPresent(_ interaction: ContextMenuInteraction) { }

    /// Does nothing by default.
    func contextMenuInteractionWillDismiss(_ interaction: ContextMenuInteraction) { }

    /// Does nothing by default.
    func contextMenuInteractionDidDismiss(_ interaction: ContextMenuInteraction) { }
}
