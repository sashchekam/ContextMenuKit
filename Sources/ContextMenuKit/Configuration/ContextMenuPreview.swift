import UIKit

/// What the menu lifts above the backdrop: a snapshot of the source view or your own view.
///
/// By default the preview is a ``snapshot``: a picture of the source view that a tap goes through
/// to the backdrop. Pass ``view(_:)`` for a live view that the user can interact with, for example
/// a message bubble whose text can be selected and copied:
///
/// ```swift
/// ContextMenuConfiguration(
///     menu: menu,
///     preview: .view { _ in
///         MessageBubbleView(message: message, isTextSelectable: true)
///     }
/// )
/// ```
///
/// The view is placed right over the source view and is exactly as large, so make it look the same:
/// the source view is hidden while the menu is shown, and the preview fades into it once it has landed.
public struct ContextMenuPreview {
    enum Kind {
        case snapshot
        case view(@MainActor (ContextMenuProxy) -> UIView)
    }

    let kind: Kind

    /// A snapshot of the source view, taken right before the preview lifts.
    ///
    /// The snapshot doesn't get touches: a tap on it dismisses the menu, like a tap on the backdrop.
    public static var snapshot: ContextMenuPreview {
        ContextMenuPreview(kind: .snapshot)
    }

    /// Your own view instead of a snapshot: it stays live and gets touches.
    ///
    /// The view is created right before the preview lifts and is as large as the source view. A tap on it
    /// doesn't dismiss the menu; a view with `isUserInteractionEnabled` set to `false` lets the tap through
    /// to the backdrop. When the dismissal starts, the preview resigns the first responder, so a text selection
    /// and its edit menu go away before the preview flies back.
    /// - Parameter makeView: Creates the view of the preview. The proxy closes the menu.
    public static func view(_ makeView: @escaping @MainActor (ContextMenuProxy) -> UIView) -> ContextMenuPreview {
        ContextMenuPreview(kind: .view(makeView))
    }
}
