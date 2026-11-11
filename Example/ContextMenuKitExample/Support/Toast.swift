import UIKit

/// A short message at the bottom of the screen: shows which action was performed.
@MainActor
enum Toast {
    private enum Constants {
        static let padding = UIEdgeInsets(top: 10, left: 16, bottom: 10, right: 16)
        static let bottomInset: CGFloat = 24
        static let fadeDuration: TimeInterval = 0.2
        static let displayDuration: TimeInterval = 1.2
    }

    static func show(_ text: String, in view: UIView) {
        let label = UILabel()
        label.text = text
        label.font = .preferredFont(forTextStyle: .subheadline)
        label.textColor = .systemBackground
        label.textAlignment = .center

        let container = UIView()
        container.backgroundColor = .label.withAlphaComponent(0.85)
        container.layer.cornerRadius = 12
        container.layer.cornerCurve = .continuous
        container.alpha = 0
        container.isUserInteractionEnabled = false
        container.addSubview(label)
        view.addSubview(container)

        let labelSize = label.sizeThatFits(CGSize(width: view.bounds.width - 64, height: .greatestFiniteMagnitude))
        let size = CGSize(
            width: labelSize.width + Constants.padding.left + Constants.padding.right,
            height: labelSize.height + Constants.padding.top + Constants.padding.bottom
        )
        container.frame = CGRect(
            x: (view.bounds.width - size.width) / 2,
            y: view.bounds.height - view.safeAreaInsets.bottom - Constants.bottomInset - size.height,
            width: size.width,
            height: size.height
        )
        label.frame = container.bounds.inset(by: Constants.padding)

        UIView.animate(withDuration: Constants.fadeDuration) {
            container.alpha = 1
        }
        UIView.animate(
            withDuration: Constants.fadeDuration,
            delay: Constants.displayDuration,
            animations: { container.alpha = 0 },
            completion: { _ in container.removeFromSuperview() }
        )
    }
}
