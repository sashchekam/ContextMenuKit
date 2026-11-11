import UIKit

extension UIView {
    /// Width the view needs, at most `limit`: its Auto Layout width, or `sizeThatFits(_:)` for a view without constraints.
    func fittingWidth(limit: CGFloat) -> CGFloat {
        let fittingWidth = systemLayoutSizeFitting(
            CGSize(width: limit, height: UIView.layoutFittingCompressedSize.height),
            withHorizontalFittingPriority: .fittingSizeLevel,
            verticalFittingPriority: .fittingSizeLevel
        ).width
        guard fittingWidth > 0 else {
            // A view without constraints: frame layout.
            return min(sizeThatFits(CGSize(width: limit, height: .greatestFiniteMagnitude)).width, limit)
        }
        return min(fittingWidth, limit)
    }

    /// Height the view needs at `width`: its Auto Layout height, or `sizeThatFits(_:)` for a view without constraints.
    func fittingHeight(forWidth width: CGFloat) -> CGFloat {
        let fittingHeight = systemLayoutSizeFitting(
            CGSize(width: width, height: UIView.layoutFittingCompressedSize.height),
            withHorizontalFittingPriority: .required,
            verticalFittingPriority: .fittingSizeLevel
        ).height
        guard fittingHeight > 0 else {
            // A view without constraints: frame layout.
            return sizeThatFits(CGSize(width: width, height: .greatestFiniteMagnitude)).height
        }
        return fittingHeight
    }
}
