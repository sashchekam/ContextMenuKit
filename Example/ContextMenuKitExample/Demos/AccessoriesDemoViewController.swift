import ContextMenuKit
import UIKit

/// Accessories: your views next to the preview and the menu.
/// - The first card shows the kinds of placement at once: reactions above the card, a pin on its corner
///   placed with anchors, a views counter over the card, a label beside it and a hint below the menu that slides in.
/// - The second card has no menu items, only reactions.
final class AccessoriesDemoViewController: UIViewController, DemoScreen {
    private enum Constants {
        static let reactions = ["❤️", "👍", "😂", "😮", "😢", "🔥"]
        static let cardSize = CGSize(width: 180, height: 110)
        static let inset: CGFloat = 16
        static let showcaseTopInset: CGFloat = 120
        static let reactionsOnlyTopInset: CGFloat = 440
        static let hintSlideDistance: CGFloat = -16
        static let editedText = "Edited 12:30"
        static let viewCount = 128
        static let counterInset: CGFloat = 8
        static let hintText = "Reactions are visible to everyone in the chat."
    }

    private var showcaseInteraction: ContextMenuInteraction?

    func presentPrimaryMenu() {
        showcaseInteraction?.presentMenu()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = Demo.accessories.title
        view.backgroundColor = .systemGroupedBackground

        let showcaseCard = DemoCardView(title: "Every placement", color: .systemIndigo)
        let reactionsOnlyCard = DemoCardView(title: "Only reactions", color: .systemPink)
        let guide = view.safeAreaLayoutGuide
        for card in [showcaseCard, reactionsOnlyCard] {
            card.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview(card)
            NSLayoutConstraint.activate([
                card.widthAnchor.constraint(equalToConstant: Constants.cardSize.width),
                card.heightAnchor.constraint(equalToConstant: Constants.cardSize.height)
            ])
        }
        NSLayoutConstraint.activate([
            showcaseCard.topAnchor.constraint(equalTo: guide.topAnchor, constant: Constants.showcaseTopInset),
            showcaseCard.leadingAnchor.constraint(equalTo: guide.leadingAnchor, constant: Constants.inset),
            reactionsOnlyCard.topAnchor.constraint(equalTo: guide.topAnchor, constant: Constants.reactionsOnlyTopInset),
            reactionsOnlyCard.trailingAnchor.constraint(equalTo: guide.trailingAnchor, constant: -Constants.inset)
        ])

        let showcaseInteraction = ContextMenuInteraction(delegate: self)
        showcaseCard.addInteraction(showcaseInteraction)
        self.showcaseInteraction = showcaseInteraction
        reactionsOnlyCard.addInteraction(ContextMenuInteraction(delegate: self))
    }

    private func showToast(_ text: String) {
        Toast.show(text, in: view)
    }

    // MARK: - Accessories

    private var reactions: ContextMenuAccessory {
        ContextMenuAccessory(placement: .above(.preview, spacing: 2), scrollBehavior: .staysVisible) { [weak self] menu in
            ReactionsPanelView(reactions: Constants.reactions) { reaction in
                menu.dismiss { self?.showToast("Reacted with \(reaction)") }
            }
        }
    }

    /// A pin centered on the top corner of the card away from the menu: a placement made of anchors.
    /// It grows out of its center, the point it is attached by.
    private var pin: ContextMenuAccessory {
        let placement = ContextMenuAccessory.Placement(
            target: .preview,
            targetAnchor: CGPoint(x: 1, y: 0),
            accessoryAnchor: CGPoint(x: 0.5, y: 0.5)
        )
        return ContextMenuAccessory(placement: placement) { [weak self] menu in
            PinBadgeView {
                menu.dismiss { self?.showToast("Pinned") }
            }
        }
    }

    /// A views counter over the bottom leading corner of the card, inside its bounds. It fades in over the preview
    /// and lets taps through, like the label.
    private var viewsCounter: ContextMenuAccessory {
        ContextMenuAccessory(
            placement: .overlay(
                .preview,
                horizontalAlignment: .leading,
                verticalAlignment: .bottom,
                offset: CGVector(dx: Constants.counterInset, dy: -Constants.counterInset)
            ),
            transition: .opacity
        ) { _ in
            ViewsCounterView(count: Constants.viewCount)
        }
    }

    /// A label next to the bottom of the card, on the side away from the menu. It only fades in and out,
    /// and lets taps through: a tap on it dismisses the menu, like a tap on the backdrop.
    private var editedLabel: ContextMenuAccessory {
        ContextMenuAccessory(
            placement: .beside(.preview, side: .oppositeMenuEdge, alignment: .bottom),
            transition: .opacity
        ) { _ in
            let label = UILabel()
            label.text = Constants.editedText
            label.font = .preferredFont(forTextStyle: .caption1)
            label.textColor = .secondaryLabel
            return label
        }
    }

    /// A hint as wide as the menu, centered below it. It slides down from under the menu as it fades in.
    private var hint: ContextMenuAccessory {
        ContextMenuAccessory(
            placement: .below(.menu, alignment: .center),
            size: ContextMenuAccessory.Size(width: .matchingTarget),
            transition: ContextMenuAccessory.Transition(
                collapsedScale: 1,
                collapsedOffset: CGVector(dx: 0, dy: Constants.hintSlideDistance)
            )
        ) { _ in
            let label = UILabel()
            label.text = Constants.hintText
            label.font = .preferredFont(forTextStyle: .footnote)
            label.textColor = .secondaryLabel
            label.textAlignment = .center
            label.numberOfLines = 0
            return label
        }
    }
}

// MARK: - ContextMenuInteractionDelegate

extension AccessoriesDemoViewController: ContextMenuInteractionDelegate {
    func contextMenuInteraction(
        _ interaction: ContextMenuInteraction,
        configurationAt location: CGPoint
    ) -> ContextMenuConfiguration? {
        guard interaction === showcaseInteraction else {
            return ContextMenuConfiguration(accessories: [reactions])
        }
        let menu = ContextMenu {
            ContextMenuAction.toast("Reply", image: .system(.reply), in: view)
            ContextMenuAction.toast("Copy", image: .system(.copy), in: view)
            ContextMenuSection {
                ContextMenuAction.toast("Delete", image: .system(.delete), in: view, isDestructive: true)
            }
        }
        return ContextMenuConfiguration(menu: menu) {
            reactions
            pin
            viewsCounter
            editedLabel
            hint
        }
    }
}

// MARK: - Views counter

/// An eye and a number on a dark capsule. Decorative: lets taps through to the backdrop.
private final class ViewsCounterView: UIView {
    private enum Constants {
        static let insets = NSDirectionalEdgeInsets(top: 3, leading: 8, bottom: 3, trailing: 8)
        static let backgroundAlpha: CGFloat = 0.35
    }

    init(count: Int) {
        super.init(frame: .zero)
        isUserInteractionEnabled = false
        backgroundColor = .black.withAlphaComponent(Constants.backgroundAlpha)
        layer.cornerCurve = .continuous

        let font = UIFont.preferredFont(forTextStyle: .caption1)
        let iconView = UIImageView(image: UIImage(
            systemName: "eye.fill",
            withConfiguration: UIImage.SymbolConfiguration(font: font)
        ))
        iconView.tintColor = .white
        let label = UILabel()
        label.text = count.formatted()
        label.font = font
        label.textColor = .white
        label.accessibilityLabel = "\(count) views"

        let stackView = UIStackView(arrangedSubviews: [iconView, label])
        stackView.spacing = 4
        stackView.alignment = .center
        stackView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stackView)

        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: topAnchor, constant: Constants.insets.top),
            stackView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -Constants.insets.bottom),
            stackView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: Constants.insets.leading),
            stackView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -Constants.insets.trailing)
        ])
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        nil
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        layer.cornerRadius = bounds.height / 2
    }
}

// MARK: - Pin badge

/// A round button with a pin.
private final class PinBadgeView: UIView {
    private enum Constants {
        static let size: CGFloat = 32
        static let symbolPointSize: CGFloat = 14
    }

    init(onTap: @escaping @MainActor () -> Void) {
        super.init(frame: .zero)

        var configuration = UIButton.Configuration.filled()
        configuration.image = UIImage(systemName: "pin.fill")
        configuration.preferredSymbolConfigurationForImage = UIImage.SymbolConfiguration(
            pointSize: Constants.symbolPointSize,
            weight: .semibold
        )
        configuration.cornerStyle = .capsule
        configuration.baseBackgroundColor = .systemOrange
        let button = UIButton(configuration: configuration, primaryAction: UIAction { _ in onTap() })
        button.accessibilityLabel = "Pin"
        button.translatesAutoresizingMaskIntoConstraints = false
        addSubview(button)

        NSLayoutConstraint.activate([
            button.topAnchor.constraint(equalTo: topAnchor),
            button.bottomAnchor.constraint(equalTo: bottomAnchor),
            button.leadingAnchor.constraint(equalTo: leadingAnchor),
            button.trailingAnchor.constraint(equalTo: trailingAnchor),
            button.widthAnchor.constraint(equalToConstant: Constants.size),
            button.heightAnchor.constraint(equalToConstant: Constants.size)
        ])
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        nil
    }
}
