import UIKit

/// An icon of a context menu action.
///
/// ```swift
/// ContextMenuAction(title: "Delete", image: .system(.delete), isDestructive: true) { delete() }
/// ContextMenuAction(title: "Like", image: .custom(heartImage)) { like() }
/// ```
public enum ContextMenuImage {
    /// An SF Symbol for a common action, no symbol name needed.
    case system(ContextMenuSystemImage)
    /// Any image. Template images are tinted with the row colors, original images keep their own colors.
    case custom(UIImage)

    var image: UIImage? {
        switch self {
        case let .system(systemImage):
            UIImage(systemName: systemImage.rawValue)
        case let .custom(image):
            image
        }
    }
}
