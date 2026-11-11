/// Builds the items of a ``ContextMenuSection``.
///
/// Supports `if`, `if`-`else`, `switch`, `for`-`in` and `if #available`.
@resultBuilder
public enum ContextMenuSectionBuilder {
    /// Adds an action.
    public static func buildExpression(_ action: ContextMenuAction) -> [ContextMenuItem] {
        [.action(action)]
    }

    /// Adds actions built elsewhere, for example mapped from a view model.
    public static func buildExpression(_ actions: [ContextMenuAction]) -> [ContextMenuItem] {
        actions.map(ContextMenuItem.action)
    }

    /// Adds an item with your own view.
    public static func buildExpression(_ item: ContextMenuCustomItem) -> [ContextMenuItem] {
        [.custom(item)]
    }

    /// Adds an item.
    public static func buildExpression(_ item: ContextMenuItem) -> [ContextMenuItem] {
        [item]
    }

    /// Joins the statements of a block.
    public static func buildBlock(_ components: [ContextMenuItem]...) -> [ContextMenuItem] {
        components.flatMap { $0 }
    }

    /// Supports `if` without `else`.
    public static func buildOptional(_ component: [ContextMenuItem]?) -> [ContextMenuItem] {
        component ?? []
    }

    /// Supports `if`-`else` and `switch`.
    public static func buildEither(first component: [ContextMenuItem]) -> [ContextMenuItem] {
        component
    }

    /// Supports `if`-`else` and `switch`.
    public static func buildEither(second component: [ContextMenuItem]) -> [ContextMenuItem] {
        component
    }

    /// Supports `for`-`in`.
    public static func buildArray(_ components: [[ContextMenuItem]]) -> [ContextMenuItem] {
        components.flatMap { $0 }
    }

    /// Supports `if #available`.
    public static func buildLimitedAvailability(_ component: [ContextMenuItem]) -> [ContextMenuItem] {
        component
    }
}
