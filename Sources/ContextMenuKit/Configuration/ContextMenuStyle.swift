import UIKit

/// Visual parameters of the menu and the overlay. Defaults follow a neutral, system-like look.
public struct ContextMenuStyle {
    /// Container of the menu rows.
    public struct Menu {
        /// Width of the menu and of the views of custom items.
        public var width: CGFloat = 248
        /// Corner radius of the menu.
        public var cornerRadius: CGFloat = 13
        /// Fill of the menu behind the rows.
        public var backgroundColor: UIColor = .secondarySystemGroupedBackground
        /// Color of the thin separator between rows of one section.
        public var separatorColor: UIColor = .separator
        /// Height of the thin separator between rows of one section.
        public var separatorThickness: CGFloat = 0.5
        /// Color of the thick separator between sections.
        public var sectionSeparatorColor = UIColor { traits in
            UIColor(white: 0, alpha: traits.userInterfaceStyle == .dark ? 0.3 : 0.06)
        }
        /// Height of the thick separator between sections.
        public var sectionSeparatorHeight: CGFloat = 8

        public init() { }
    }

    /// A single action row.
    public struct Row {
        /// Height of an action row. Custom items have their own height, see ``ContextMenuCustomItem/height``.
        public var height: CGFloat = 48
        /// Distance from the menu edges to the title and the icon.
        public var horizontalInset: CGFloat = 16
        /// Size of the icon at the trailing edge of the row.
        public var iconSize = CGSize(width: 24, height: 24)
        /// Minimal gap between the title and the icon.
        public var iconTitleSpacing: CGFloat = 8
        /// Font of the title.
        public var titleFont: UIFont = .systemFont(ofSize: 17)
        /// Color of the title of an enabled, non-destructive action.
        public var titleColor: UIColor = .label
        /// Tint of the icon of an enabled, non-destructive action.
        public var iconColor: UIColor = .label
        /// Color of the title and the icon of a destructive action.
        public var destructiveColor: UIColor = .systemRed
        /// Color of the title and the icon of a disabled action.
        public var disabledColor: UIColor = .tertiaryLabel
        /// Background of a highlighted action or selectable custom item while it is touched.
        public var highlightedBackgroundColor: UIColor = .systemFill

        public init() { }
    }

    /// Backdrop behind the preview and the menu.
    public struct Background {
        /// Color that covers the window under the blur.
        public var dimmingColor: UIColor = .gray.withAlphaComponent(0.3)
        /// Material of the blur over the window.
        public var blurStyle: UIBlurEffect.Style = .systemUltraThinMaterial

        public init() { }
    }

    /// Spacing used by the layout.
    public struct Layout {
        /// Vertical gap between the preview and the menu.
        public var previewMenuSpacing: CGFloat = 8
        /// Minimal distance between the menu or an accessory and the safe area edges of the window.
        public var screenEdgeInset: CGFloat = 16
        /// Gap between an accessory and the element it is attached to,
        /// unless ``ContextMenuAccessory/Placement/spacing`` sets another one.
        public var accessorySpacing: CGFloat = 8

        public init() { }
    }

    /// The neutral, system-like style.
    public static var `default`: ContextMenuStyle {
        ContextMenuStyle()
    }

    /// Container of the menu rows.
    public var menu = Menu()
    /// Action rows.
    public var row = Row()
    /// Backdrop behind the preview and the menu.
    public var background = Background()
    /// Spacing used by the layout.
    public var layout = Layout()

    public init() { }
}
