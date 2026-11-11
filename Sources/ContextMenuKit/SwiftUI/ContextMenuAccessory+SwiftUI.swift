import SwiftUI

public extension ContextMenuAccessory {
    /// Creates an accessory with a SwiftUI view.
    ///
    /// ```swift
    /// ContextMenuAccessory(placement: .above(.preview)) { menu in
    ///     ReactionsBar { reaction in
    ///         menu.dismiss { react(with: reaction) }
    ///     }
    /// }
    /// ```
    ///
    /// With the `contextMenuInteraction` modifier the view gets the environment of the place where the modifier
    /// is applied, environment objects included. In a configuration set up in UIKit, pass its dependencies explicitly.
    /// A fitting size is the size the view needs, proposed the width of the safe area.
    /// SwiftUI views don't get ``ContextMenuAccessoryView`` calls.
    /// - Parameters:
    ///   - placement: Where the accessory is attached. Above the preview by default.
    ///   - size: Width and height of the accessory. Taken from the view by default.
    ///   - transition: How the accessory appears and disappears.
    ///   - scrollBehavior: What the accessory does when the overlay scrolls.
    ///   - content: The view of the accessory. The proxy closes the menu.
    init<Content: View>(
        placement: Placement = .above(.preview),
        size: Size = .fitting,
        transition: Transition = .scale,
        scrollBehavior: ScrollBehavior = .scrollsWithContent,
        @ViewBuilder content: @escaping @MainActor (ContextMenuProxy) -> Content
    ) {
        self.init(placement: placement, size: size, transition: transition, scrollBehavior: scrollBehavior) { proxy in
            ContextMenuHostingItemView(content: content(proxy), environmentValues: proxy.environmentValues)
        }
    }
}
