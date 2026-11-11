import UIKit

extension UIButton {
    /// A button with an emoji that reports its reaction when tapped.
    static func reaction(
        _ reaction: String,
        fontSize: CGFloat,
        onSelect: @escaping @MainActor (String) -> Void
    ) -> UIButton {
        let button = UIButton(type: .system)
        button.setTitle(reaction, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: fontSize)
        button.accessibilityLabel = reaction
        button.addAction(UIAction { _ in onSelect(reaction) }, for: .primaryActionTriggered)
        return button
    }
}
