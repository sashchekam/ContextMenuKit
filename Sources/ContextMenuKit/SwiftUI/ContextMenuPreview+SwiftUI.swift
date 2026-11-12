import SwiftUI

public extension ContextMenuPreview {
    /// A SwiftUI view instead of a snapshot: it stays live and gets touches.
    ///
    /// ```swift
    /// MessageBubble(message)
    ///     .contextMenuInteraction(preview: .view { _ in
    ///         MessageBubble(message, isPlaying: true)
    ///     }) {
    ///         ContextMenuAction(title: "Reply", image: .system(.reply)) { reply(to: message) }
    ///     }
    /// ```
    ///
    /// The view is proposed the size of the source view and is placed right over it, see ``view(_:)``.
    /// With the `contextMenuInteraction` modifier the view gets the environment of the place where the modifier
    /// is applied, environment objects included. In a configuration set up in UIKit, pass its dependencies explicitly.
    /// - Parameter content: The view of the preview. The proxy closes the menu.
    static func view<Content: View>(
        @ViewBuilder content: @escaping @MainActor (ContextMenuProxy) -> Content
    ) -> ContextMenuPreview {
        ContextMenuPreview(kind: .view { proxy in
            ContextMenuHostingItemView(content: content(proxy), environmentValues: proxy.environmentValues)
        })
    }
}
