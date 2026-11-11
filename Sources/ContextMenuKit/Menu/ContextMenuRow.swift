import UIKit

/// A row of ``ContextMenuListView``: an action or a custom item.
@MainActor
protocol ContextMenuRow: UIView {
    /// Height of the row in a menu of the given width.
    func preferredHeight(forWidth width: CGFloat) -> CGFloat
}
