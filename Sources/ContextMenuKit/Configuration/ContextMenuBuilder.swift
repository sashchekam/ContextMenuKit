/// Builds the sections of a ``ContextMenu``.
///
/// Takes ``ContextMenuSection`` values, and actions and custom items outside of a section. Consecutive items
/// outside of a section form one section. Supports `if`, `if`-`else`, `switch`, `for`-`in` and `if #available`.
@resultBuilder
public enum ContextMenuBuilder {
    /// Adds a section.
    public static func buildExpression(_ section: ContextMenuSection) -> [ContextMenuSection] {
        [section]
    }

    /// Adds sections built elsewhere, for example taken from another menu.
    public static func buildExpression(_ sections: [ContextMenuSection]) -> [ContextMenuSection] {
        sections
    }

    /// Adds an action outside of a section.
    public static func buildExpression(_ action: ContextMenuAction) -> [ContextMenuSection] {
        implicitSection(with: [.action(action)])
    }

    /// Adds actions outside of a section.
    public static func buildExpression(_ actions: [ContextMenuAction]) -> [ContextMenuSection] {
        implicitSection(with: actions.map(ContextMenuItem.action))
    }

    /// Adds an item with your own view outside of a section.
    public static func buildExpression(_ item: ContextMenuCustomItem) -> [ContextMenuSection] {
        implicitSection(with: [.custom(item)])
    }

    /// Adds an item outside of a section.
    public static func buildExpression(_ item: ContextMenuItem) -> [ContextMenuSection] {
        implicitSection(with: [item])
    }

    /// Joins the statements of a block.
    public static func buildBlock(_ components: [ContextMenuSection]...) -> [ContextMenuSection] {
        components.flatMap { $0 }
    }

    /// Supports `if` without `else`.
    public static func buildOptional(_ component: [ContextMenuSection]?) -> [ContextMenuSection] {
        component ?? []
    }

    /// Supports `if`-`else` and `switch`.
    public static func buildEither(first component: [ContextMenuSection]) -> [ContextMenuSection] {
        component
    }

    /// Supports `if`-`else` and `switch`.
    public static func buildEither(second component: [ContextMenuSection]) -> [ContextMenuSection] {
        component
    }

    /// Supports `for`-`in`.
    public static func buildArray(_ components: [[ContextMenuSection]]) -> [ContextMenuSection] {
        components.flatMap { $0 }
    }

    /// Supports `if #available`.
    public static func buildLimitedAvailability(_ component: [ContextMenuSection]) -> [ContextMenuSection] {
        component
    }

    /// Merges adjacent sections made from actions outside of a section.
    public static func buildFinalResult(_ component: [ContextMenuSection]) -> [ContextMenuSection] {
        var sections: [ContextMenuSection] = []
        for section in component {
            if section.isImplicit, let last = sections.last, last.isImplicit {
                sections[sections.count - 1].items += section.items
            } else {
                sections.append(section)
            }
        }
        // The result may go into another menu, where these sections must stay as they are.
        return sections.map { ContextMenuSection(items: $0.items, isImplicit: false) }
    }

    private static func implicitSection(with items: [ContextMenuItem]) -> [ContextMenuSection] {
        items.isEmpty ? [] : [ContextMenuSection(items: items, isImplicit: true)]
    }
}
