/// Content of a context menu: one or more sections of items.
///
/// List sections and actions the way you list views in SwiftUI:
///
/// ```swift
/// ContextMenu {
///     ContextMenuSection {
///         ContextMenuAction(title: "Reply", image: .system(.reply)) { reply() }
///         if canForward {
///             ContextMenuAction(title: "Forward", image: .system(.forward)) { forward() }
///         }
///     }
///     ContextMenuSection {
///         ContextMenuAction(title: "Delete", image: .system(.delete), isDestructive: true) { delete() }
///     }
/// }
/// ```
///
/// Consecutive actions outside of a section form one section, so a single-section menu needs no
/// ``ContextMenuSection``:
///
/// ```swift
/// ContextMenu {
///     ContextMenuAction(title: "Copy") { copy() }
///     ContextMenuAction(title: "Delete", isDestructive: true) { delete() }
/// }
/// ```
public struct ContextMenu {
    /// Sections of the menu, top to bottom.
    public var sections: [ContextMenuSection]

    var isEmpty: Bool {
        sections.allSatisfy { $0.items.isEmpty }
    }

    /// Creates a menu from the sections and actions listed in `content`.
    public init(@ContextMenuBuilder content: () -> [ContextMenuSection]) {
        sections = content()
    }
}

/// A group of items separated from the neighbouring groups by a thick separator.
public struct ContextMenuSection {
    /// Items of the section, top to bottom.
    public var items: [ContextMenuItem]
    /// Marks a section that ``ContextMenuBuilder`` made from actions outside of a section,
    /// so that it can merge it with the adjacent ones.
    var isImplicit: Bool

    /// Creates a section from the actions and custom items listed in `content`.
    public init(@ContextMenuSectionBuilder content: () -> [ContextMenuItem]) {
        self.init(items: content(), isImplicit: false)
    }

    init(items: [ContextMenuItem], isImplicit: Bool) {
        self.items = items
        self.isImplicit = isImplicit
    }
}

/// An element of a context menu section.
public enum ContextMenuItem {
    /// A row with a title and an icon, see ``ContextMenuAction``.
    case action(ContextMenuAction)
    /// An item with your own view, see ``ContextMenuCustomItem``.
    case custom(ContextMenuCustomItem)
}
