import UIKit

/// A menu item that shows your own view: a row of reactions, a row of avatars, a slider.
///
/// A custom item works in one of two ways.
///
/// **Selectable.** With a `handler`, the item behaves like a ``ContextMenuAction``: the whole row highlights
/// on touch, a tap closes the menu, and the handler runs after the dismissal animation. The view only draws
/// the content and doesn't receive touches.
///
/// ```swift
/// ContextMenuCustomItem {
///     showReadReceipts()
/// } view: {
///     ReadReceiptsRow(readers: message.readers)
/// }
/// ```
///
/// **Interactive.** Without a `handler`, the view handles touches itself: buttons, sliders, switches.
/// It closes the menu through the ``ContextMenuProxy`` it gets.
///
/// ```swift
/// ContextMenuCustomItem { menu in
///     ReactionsBar(reactions: reactions) { reaction in
///         menu.dismiss { react(with: reaction) }
///     }
/// }
/// ```
///
/// The view is created right before the menu is shown and is as wide as the menu, see ``ContextMenuStyle/Menu/width``.
/// Keep its background clear: the menu background and the highlight of a selectable item are drawn behind it.
/// Items are separated from their neighbours like action rows, put an item into its own ``ContextMenuSection``
/// to set it apart.
///
/// SwiftUI views work too, see `init(height:content:)`.
public struct ContextMenuCustomItem {
    /// Runs on the main actor after the menu has finished its dismissal animation.
    public typealias Handler = ContextMenuAction.Handler

    /// Height of the item. `nil` takes the height from the view: its Auto Layout height at the width of the menu,
    /// or `sizeThatFits(_:)` for a view without constraints. The height is measured once, when the menu is shown.
    public var height: CGFloat?
    /// Makes the item selectable: runs on the main actor after the menu has finished its dismissal animation.
    /// `nil` makes the item interactive.
    public var handler: Handler?

    let makeView: @MainActor (ContextMenuProxy) -> UIView

    /// Creates a selectable item: the whole row highlights and closes the menu, like an action.
    /// - Parameters:
    ///   - height: Height of the item, `nil` takes it from the view.
    ///   - handler: Runs after the menu has finished its dismissal animation.
    ///   - view: Creates the view of the item. The view doesn't receive touches.
    public init(
        height: CGFloat? = nil,
        handler: @escaping Handler,
        view: @escaping @MainActor () -> UIView
    ) {
        self.init(height: height, handler: handler) { _ in
            view()
        }
    }

    /// Creates an interactive item: the view handles touches itself and closes the menu through the proxy.
    /// - Parameters:
    ///   - height: Height of the item, `nil` takes it from the view.
    ///   - view: Creates the view of the item.
    public init(
        height: CGFloat? = nil,
        view: @escaping @MainActor (ContextMenuProxy) -> UIView
    ) {
        self.init(height: height, handler: nil, makeView: view)
    }

    init(height: CGFloat?, handler: Handler?, makeView: @escaping @MainActor (ContextMenuProxy) -> UIView) {
        self.height = height
        self.handler = handler
        self.makeView = makeView
    }
}
