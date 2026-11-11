import UIKit

/// Properties of the source view that the menu changes while it is shown.
///
/// The source view is hidden with `alpha` rather than `isHidden`, so that a view
/// inside a `UIStackView` keeps its place in the layout.
@MainActor
struct SourceViewState {
    let alpha: CGFloat
    let transform: CGAffineTransform

    init(view: UIView) {
        alpha = view.alpha
        transform = view.transform
    }

    func restore(on view: UIView) {
        view.alpha = alpha
        view.transform = transform
    }
}
