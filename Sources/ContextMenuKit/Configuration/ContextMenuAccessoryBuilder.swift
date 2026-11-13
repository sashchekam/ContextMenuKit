/// Builds the accessories of a ``ContextMenuConfiguration``.
///
/// List accessories the way you list views in SwiftUI. An accessory listed later is drawn above the earlier ones.
/// Supports `if`, `if`-`else`, `switch`, `for`-`in` and `if #available`.
///
/// ```swift
/// ContextMenuConfiguration(menu: menu) {
///     ContextMenuAccessory(placement: .above(.preview)) { menu in
///         ReactionsBar { reaction in menu.dismiss { react(with: reaction) } }
///     }
///     if message.isEdited {
///         ContextMenuAccessory(placement: .beside(.preview, side: .oppositeMenuEdge, alignment: .bottom)) { _ in
///             Text("Edited")
///         }
///     }
/// }
/// ```
@resultBuilder
public enum ContextMenuAccessoryBuilder {
    /// Adds an accessory.
    public static func buildExpression(_ accessory: ContextMenuAccessory) -> [ContextMenuAccessory] {
        [accessory]
    }

    /// Adds accessories built elsewhere, for example shared between several menus.
    public static func buildExpression(_ accessories: [ContextMenuAccessory]) -> [ContextMenuAccessory] {
        accessories
    }

    /// Joins the statements of a block.
    public static func buildBlock(_ components: [ContextMenuAccessory]...) -> [ContextMenuAccessory] {
        components.flatMap { $0 }
    }

    /// Supports `if` without `else`.
    public static func buildOptional(_ component: [ContextMenuAccessory]?) -> [ContextMenuAccessory] {
        component ?? []
    }

    /// Supports `if`-`else` and `switch`.
    public static func buildEither(first component: [ContextMenuAccessory]) -> [ContextMenuAccessory] {
        component
    }

    /// Supports `if`-`else` and `switch`.
    public static func buildEither(second component: [ContextMenuAccessory]) -> [ContextMenuAccessory] {
        component
    }

    /// Supports `for`-`in`.
    public static func buildArray(_ components: [[ContextMenuAccessory]]) -> [ContextMenuAccessory] {
        components.flatMap { $0 }
    }

    /// Supports `if #available`.
    public static func buildLimitedAvailability(_ component: [ContextMenuAccessory]) -> [ContextMenuAccessory] {
        component
    }
}
