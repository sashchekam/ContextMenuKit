import UIKit

/// A selectable row of a context menu.
public struct ContextMenuAction {
    /// Runs on the main actor after the menu has finished its dismissal animation.
    public typealias Handler = @MainActor () -> Void

    /// Text of the row.
    public var title: String
    /// A system symbol or your own image shown at the trailing edge of the row.
    public var image: ContextMenuImage?
    /// Destructive actions use ``ContextMenuStyle/Row/destructiveColor`` for the title and the icon.
    public var isDestructive: Bool
    /// Disabled actions are dimmed and can't be selected.
    public var isEnabled: Bool
    /// Runs after the menu has finished its dismissal animation, when the user selects the action.
    public var handler: Handler

    /// Creates an action.
    /// - Parameters:
    ///   - title: Text of the row.
    ///   - image: A system symbol or your own image shown at the trailing edge of the row.
    ///   - isDestructive: Shows the title and the icon in ``ContextMenuStyle/Row/destructiveColor``.
    ///   - isEnabled: `false` dims the action and makes it impossible to select.
    ///   - handler: Runs after the menu has finished its dismissal animation.
    public init(
        title: String,
        image: ContextMenuImage? = nil,
        isDestructive: Bool = false,
        isEnabled: Bool = true,
        handler: @escaping Handler
    ) {
        self.title = title
        self.image = image
        self.isDestructive = isDestructive
        self.isEnabled = isEnabled
        self.handler = handler
    }
}
