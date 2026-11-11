import SwiftUI
import UIKit

/// Lets the view of a ``ContextMenuCustomItem`` close the menu it is shown in.
///
/// ```swift
/// ContextMenuCustomItem { menu in
///     ReactionsBar(reactions: reactions) { reaction in
///         menu.dismiss { react(with: reaction) }
///     }
/// }
/// ```
@MainActor
public struct ContextMenuProxy {
    /// The SwiftUI environment of the place where the `contextMenuInteraction` modifier is applied.
    /// `nil` in a menu of a ``ContextMenuInteraction`` set up in UIKit.
    let environmentValues: EnvironmentValues?
    private let dismissHandler: @MainActor (ContextMenuAction.Handler?) -> Void

    init(
        environmentValues: EnvironmentValues?,
        dismissHandler: @escaping @MainActor (ContextMenuAction.Handler?) -> Void
    ) {
        self.environmentValues = environmentValues
        self.dismissHandler = dismissHandler
    }

    /// Dismisses the menu, the same way a selected action does.
    ///
    /// Ignored once the menu is being dismissed: the first call wins, a later handler doesn't run.
    /// - Parameter handler: Runs on the main actor after the menu has finished its dismissal animation.
    public func dismiss(performing handler: ContextMenuAction.Handler? = nil) {
        dismissHandler(handler)
    }
}
