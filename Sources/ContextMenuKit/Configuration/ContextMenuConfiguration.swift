import SwiftUI

/// Everything the interaction needs to present a menu for a particular touch.
public struct ContextMenuConfiguration {
    /// Sections and items of the menu. Without items, only the preview and the accessories are shown.
    public var menu: ContextMenu
    /// Views shown next to the preview and the menu, outside of the menu list, see ``ContextMenuAccessory``.
    /// Listed later, an accessory is drawn above the earlier ones.
    public var accessories: [ContextMenuAccessory]
    /// Horizontal alignment of the menu relative to the preview.
    public var alignment: ContextMenuAlignment
    /// Where the source view is visible, so that on its way back the preview doesn't fly over bars.
    public var clipping: ContextMenuClipping
    /// Colors, fonts and sizes.
    public var style: ContextMenuStyle
    /// Timings and curves of the transitions.
    public var animationSpec: ContextMenuAnimationSpec
    /// The environment of the place where the SwiftUI modifier is applied, for SwiftUI views of custom items.
    /// `nil` for a menu set up in UIKit.
    var environmentValues: EnvironmentValues?

    /// `true` when there is nothing to show: the menu has no items and there are no accessories.
    var isEmpty: Bool {
        menu.isEmpty && accessories.isEmpty
    }

    /// Creates a configuration.
    /// - Parameters:
    ///   - menu: Sections and items of the menu. Without items, only the preview and the accessories are shown.
    ///   - accessories: Views shown next to the preview and the menu.
    ///   - alignment: Horizontal alignment of the menu relative to the preview.
    ///   - clipping: Where the source view is visible, so that on its way back the preview doesn't fly over bars.
    ///   - style: Colors, fonts and sizes.
    ///   - animationSpec: Timings and curves of the transitions.
    public init(
        menu: ContextMenu = ContextMenu { },
        accessories: [ContextMenuAccessory] = [],
        alignment: ContextMenuAlignment = .automatic,
        clipping: ContextMenuClipping = .none,
        style: ContextMenuStyle = .default,
        animationSpec: ContextMenuAnimationSpec = .default
    ) {
        self.menu = menu
        self.accessories = accessories
        self.alignment = alignment
        self.clipping = clipping
        self.style = style
        self.animationSpec = animationSpec
    }
}
