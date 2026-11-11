import SwiftUI

@MainActor
public extension View {
    /// Adds a context menu to the view.
    ///
    /// A long press presses the view down, lifts its preview above a blurred backdrop and shows the menu
    /// next to it, the same way ``ContextMenuInteraction`` does for a `UIView`.
    ///
    /// ```swift
    /// MessageBubble(message)
    ///     .contextMenuInteraction(alignment: message.isOutgoing ? .trailing : .leading) {
    ///         ContextMenuAction(title: "Reply", image: .system(.reply)) { reply(to: message) }
    ///         ContextMenuSection {
    ///             ContextMenuAction(title: "Delete", image: .system(.delete), isDestructive: true) {
    ///                 delete(message)
    ///             }
    ///         }
    ///     }
    /// ```
    ///
    /// The menu is built right before it is shown, so it reflects the current state. A menu without items
    /// and accessories isn't shown.
    ///
    /// Accessories put your views next to the preview and the menu, for example reactions above a message:
    ///
    /// ```swift
    /// MessageBubble(message)
    ///     .contextMenuInteraction(accessories: [
    ///         ContextMenuAccessory(placement: .above(.preview)) { menu in
    ///             ReactionsBar { reaction in menu.dismiss { react(with: reaction) } }
    ///         }
    ///     ]) {
    ///         ContextMenuAction(title: "Reply", image: .system(.reply)) { reply(to: message) }
    ///     }
    /// ```
    ///
    /// The view is hosted in its own `UIHostingController`: it gets the environment of the place where
    /// the modifier is applied, and its size follows its content. A few things don't cross that boundary:
    /// - Preferences set inside the view, such as `navigationTitle(_:)` or `toolbar(content:)`, don't reach
    ///   the views around it. Apply them outside of this modifier.
    /// - A `withAnimation` transaction from outside doesn't animate the view's content.
    ///   Use `animation(_:value:)` inside the view.
    ///
    /// In a file that imports SwiftUI, the type name `ContextMenu` is ambiguous with the deprecated
    /// `SwiftUI.ContextMenu`: write `ContextMenuKit.ContextMenu` where you need the type itself.
    ///
    /// The modifier needs iOS 16 to size the view by its content. On iOS 15, SwiftUI views still work
    /// as custom items and accessories of a menu presented by ``ContextMenuInteraction``.
    ///
    /// - Parameters:
    ///   - isPresented: Presents the menu without a press when set to `true`, for example from a "More" button,
    ///     and dismisses it when set to `false`. The modifier sets it to `true` when the menu starts to appear
    ///     and to `false` once the menu is dismissed or if it can't be shown.
    ///   - alignment: Horizontal alignment of the menu relative to the preview.
    ///   - clipping: Where the view is visible, so that on its way back the preview doesn't fly over bars.
    ///   - style: Colors, fonts and sizes of the menu.
    ///   - animationSpec: Timings and curves of the press, the presentation and the dismissal.
    ///   - accessories: Views shown next to the preview and the menu, see ``ContextMenuAccessory``.
    ///   - menu: Sections, actions and custom items of the menu, see ``ContextMenuBuilder``.
    @available(iOS 16.0, *)
    func contextMenuInteraction(
        isPresented: Binding<Bool>? = nil,
        alignment: ContextMenuAlignment = .automatic,
        clipping: ContextMenuClipping = .none,
        style: ContextMenuStyle = .default,
        animationSpec: ContextMenuAnimationSpec = .default,
        accessories: [ContextMenuAccessory] = [],
        @ContextMenuBuilder menu: @escaping @MainActor () -> [ContextMenuSection]
    ) -> some View {
        ContextMenuInteractionRepresentable(content: self, isPresented: isPresented) {
            ContextMenuConfiguration(
                menu: ContextMenu(content: menu),
                accessories: accessories,
                alignment: alignment,
                clipping: clipping,
                style: style,
                animationSpec: animationSpec
            )
        }
    }
}
