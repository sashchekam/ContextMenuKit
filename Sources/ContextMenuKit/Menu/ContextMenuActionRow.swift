import UIKit

/// A single action of the menu: the title on the leading side, the icon on the trailing side.
@MainActor
final class ContextMenuActionRow: UIControl {
    override var isHighlighted: Bool {
        didSet {
            backgroundColor = isHighlighted ? style.highlightedBackgroundColor : .clear
        }
    }

    private let style: ContextMenuStyle.Row
    private let titleLabel = UILabel()
    private let iconView = UIImageView()

    init(action: ContextMenuAction, style: ContextMenuStyle.Row, onSelect: @escaping @MainActor () -> Void) {
        self.style = style
        super.init(frame: .zero)
        isEnabled = action.isEnabled
        setUpContent(for: action)
        setUpAccessibility(for: action)
        addAction(UIAction { _ in onSelect() }, for: .touchUpInside)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        nil
    }

    private func setUpContent(for action: ContextMenuAction) {
        let contentColor = contentColor(for: action)

        titleLabel.text = action.title
        titleLabel.font = style.titleFont
        titleLabel.textColor = contentColor
        titleLabel.lineBreakMode = .byTruncatingTail
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(titleLabel)

        var constraints = [
            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: style.horizontalInset),
            titleLabel.centerYAnchor.constraint(equalTo: centerYAnchor)
        ]

        if let image = action.image?.image {
            iconView.image = image
            iconView.tintColor = action.isEnabled && !action.isDestructive ? style.iconColor : contentColor
            iconView.contentMode = .scaleAspectFit
            iconView.translatesAutoresizingMaskIntoConstraints = false
            addSubview(iconView)
            constraints += [
                iconView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -style.horizontalInset),
                iconView.centerYAnchor.constraint(equalTo: centerYAnchor),
                iconView.widthAnchor.constraint(equalToConstant: style.iconSize.width),
                iconView.heightAnchor.constraint(equalToConstant: style.iconSize.height),
                titleLabel.trailingAnchor.constraint(
                    lessThanOrEqualTo: iconView.leadingAnchor,
                    constant: -style.iconTitleSpacing
                )
            ]
        } else {
            constraints.append(
                titleLabel.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor, constant: -style.horizontalInset)
            )
        }

        NSLayoutConstraint.activate(constraints)
    }

    private func setUpAccessibility(for action: ContextMenuAction) {
        isAccessibilityElement = true
        accessibilityLabel = action.title
        accessibilityTraits = action.isEnabled ? .button : [.button, .notEnabled]
    }

    private func contentColor(for action: ContextMenuAction) -> UIColor {
        guard action.isEnabled else {
            return style.disabledColor
        }
        return action.isDestructive ? style.destructiveColor : style.titleColor
    }
}

// MARK: - ContextMenuRow

extension ContextMenuActionRow: ContextMenuRow {
    func preferredHeight(forWidth width: CGFloat) -> CGFloat {
        style.height
    }
}
