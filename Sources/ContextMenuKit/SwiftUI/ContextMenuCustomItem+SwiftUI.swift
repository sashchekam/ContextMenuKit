import SwiftUI

public extension ContextMenuCustomItem {
    /// Creates a selectable item with a SwiftUI view: the whole row highlights and closes the menu, like an action.
    ///
    /// ```swift
    /// ContextMenuCustomItem {
    ///     showReadReceipts()
    /// } content: {
    ///     ReadReceiptsRow(readers: message.readers)
    /// }
    /// ```
    ///
    /// With the `contextMenuInteraction` modifier the view gets the environment of the place where the modifier
    /// is applied, environment objects included. In a menu set up in UIKit, pass its dependencies explicitly.
    /// - Parameters:
    ///   - height: Height of the item, `nil` takes the height the view needs at the width of the menu.
    ///   - handler: Runs after the menu has finished its dismissal animation.
    ///   - content: The view of the item. It doesn't receive touches.
    init<Content: View>(
        height: CGFloat? = nil,
        handler: @escaping Handler,
        @ViewBuilder content: @escaping @MainActor () -> Content
    ) {
        self.init(height: height, handler: handler) { proxy in
            ContextMenuHostingItemView(content: content(), environmentValues: proxy.environmentValues)
        }
    }

    /// Creates an interactive item with a SwiftUI view: the view handles touches itself
    /// and closes the menu through the proxy.
    ///
    /// ```swift
    /// ContextMenuCustomItem { menu in
    ///     ReactionsBar { reaction in
    ///         menu.dismiss { react(with: reaction) }
    ///     }
    /// }
    /// ```
    ///
    /// With the `contextMenuInteraction` modifier the view gets the environment of the place where the modifier
    /// is applied, environment objects included. In a menu set up in UIKit, pass its dependencies explicitly.
    /// - Parameters:
    ///   - height: Height of the item, `nil` takes the height the view needs at the width of the menu.
    ///   - content: The view of the item.
    init<Content: View>(
        height: CGFloat? = nil,
        @ViewBuilder content: @escaping @MainActor (ContextMenuProxy) -> Content
    ) {
        self.init(height: height, handler: nil) { proxy in
            ContextMenuHostingItemView(content: content(proxy), environmentValues: proxy.environmentValues)
        }
    }
}
