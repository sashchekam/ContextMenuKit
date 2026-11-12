import ContextMenuKit
import UIKit

/// The same menu in different looks. Every card sets its own ``ContextMenuStyle`` (colors, fonts, sizes, backdrop)
/// or ``ContextMenuAnimationSpec`` (press, lift and dismissal timings) in the configuration.
final class StylesDemoViewController: UIViewController, DemoScreen {
    private struct StyledCard {
        let title: String
        let subtitle: String
        let color: UIColor
        var style = ContextMenuStyle.default
        var animationSpec = ContextMenuAnimationSpec.default
    }

    private enum Constants {
        static let inset: CGFloat = 16
        static let spacing: CGFloat = 12
        static let cardHeight: CGFloat = 110
        static let columns = 2
        /// The Rounded card: the most visible custom style.
        static let primaryCardIndex = 1
        /// Computed: ``ContextMenuStyle`` isn't `Sendable`, so it can't be stored in a static constant.
        static var cards: [StyledCard] {
            [
                StyledCard(title: "Default", subtitle: "The built-in look", color: .systemGray),
                StyledCard(title: "Rounded", subtitle: "Colors, font, corners, backdrop", color: .systemIndigo, style: .rounded),
                StyledCard(title: "Compact", subtitle: "Smaller rows, narrower menu", color: .systemTeal, style: .compact),
                StyledCard(title: "Dark", subtitle: "Dark in any appearance", color: UIColor(white: 0.2, alpha: 1), style: .dark),
                StyledCard(title: "Bouncy", subtitle: "Deeper press, springier lift", color: .systemOrange, animationSpec: .bouncy),
                StyledCard(title: "Snappy", subtitle: "Light press, quick transitions", color: .systemGreen, animationSpec: .snappy)
            ]
        }
    }

    private var cardsByInteraction: [ObjectIdentifier: StyledCard] = [:]
    private var primaryInteraction: ContextMenuInteraction?

    func presentPrimaryMenu() {
        primaryInteraction?.presentMenu()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = Demo.styles.title
        view.backgroundColor = .systemGroupedBackground

        let cards = Constants.cards
        let rows = stride(from: 0, to: cards.count, by: Constants.columns).map { start in
            let rowCards = cards[start..<min(start + Constants.columns, cards.count)]
            let rowStackView = UIStackView(arrangedSubviews: rowCards.enumerated().map { offset, card in
                makeCardView(for: card, isPrimary: start + offset == Constants.primaryCardIndex)
            })
            rowStackView.distribution = .fillEqually
            rowStackView.spacing = Constants.spacing
            return rowStackView
        }
        let gridStackView = UIStackView(arrangedSubviews: rows)
        gridStackView.axis = .vertical
        gridStackView.spacing = Constants.spacing
        gridStackView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(gridStackView)

        let guide = view.safeAreaLayoutGuide
        NSLayoutConstraint.activate([
            gridStackView.topAnchor.constraint(equalTo: guide.topAnchor, constant: Constants.inset),
            gridStackView.leadingAnchor.constraint(equalTo: guide.leadingAnchor, constant: Constants.inset),
            gridStackView.trailingAnchor.constraint(equalTo: guide.trailingAnchor, constant: -Constants.inset)
        ])
    }

    private func makeCardView(for card: StyledCard, isPrimary: Bool) -> UIView {
        let cardView = DemoCardView(title: card.title, subtitle: card.subtitle, color: card.color)
        cardView.heightAnchor.constraint(equalToConstant: Constants.cardHeight).isActive = true

        let interaction = ContextMenuInteraction(delegate: self)
        cardView.addInteraction(interaction)
        cardsByInteraction[ObjectIdentifier(interaction)] = card
        if isPrimary {
            primaryInteraction = interaction
        }
        return cardView
    }
}

// MARK: - ContextMenuInteractionDelegate

extension StylesDemoViewController: ContextMenuInteractionDelegate {
    func contextMenuInteraction(
        _ interaction: ContextMenuInteraction,
        configurationAt location: CGPoint
    ) -> ContextMenuConfiguration? {
        guard let card = cardsByInteraction[ObjectIdentifier(interaction)] else {
            return nil
        }
        // Every kind of row, so that each style shows all its colors.
        let menu = ContextMenu {
            ContextMenuSection {
                ContextMenuAction.toast("Copy", image: .system(.copy), in: view)
                ContextMenuAction.toast("Share", image: .system(.share), in: view)
                ContextMenuAction.toast("Favorite", image: .system(.favorite), in: view)
            }
            ContextMenuSection {
                ContextMenuAction.toast("Rename", image: .system(.edit), in: view, isEnabled: false)
                ContextMenuAction.toast("Delete", image: .system(.delete), in: view, isDestructive: true)
            }
        }
        return ContextMenuConfiguration(menu: menu, style: card.style, animationSpec: card.animationSpec)
    }
}

// MARK: - Styles

private extension ContextMenuStyle {
    /// A tinted menu with a rounded font, large corners and a tinted backdrop.
    static var rounded: ContextMenuStyle {
        let accent = UIColor.systemIndigo
        var style = ContextMenuStyle()
        style.menu.width = 232
        style.menu.cornerRadius = 24
        style.menu.backgroundColor = UIColor { traits in
            traits.userInterfaceStyle == .dark
                ? UIColor(red: 0.17, green: 0.16, blue: 0.29, alpha: 1)
                : UIColor(red: 0.95, green: 0.94, blue: 1, alpha: 1)
        }
        style.menu.separatorColor = accent.withAlphaComponent(0.2)
        style.menu.sectionSeparatorColor = accent.withAlphaComponent(0.12)
        style.menu.sectionSeparatorHeight = 6
        style.row.titleFont = .roundedSystemFont(ofSize: 17, weight: .medium)
        style.row.iconColor = accent
        style.row.highlightedBackgroundColor = accent.withAlphaComponent(0.15)
        style.row.destructiveColor = .systemPink
        style.background.dimmingColor = accent.withAlphaComponent(0.25)
        style.background.blurStyle = .systemThinMaterial
        return style
    }

    /// Lower rows, smaller font and icons, a narrower menu closer to the preview.
    static var compact: ContextMenuStyle {
        var style = ContextMenuStyle()
        style.menu.width = 196
        style.menu.cornerRadius = 10
        style.menu.sectionSeparatorHeight = 4
        style.row.height = 38
        style.row.horizontalInset = 12
        style.row.iconSize = CGSize(width: 18, height: 18)
        style.row.titleFont = .systemFont(ofSize: 15)
        style.layout.previewMenuSpacing = 6
        return style
    }

    /// Fixed dark colors: suits a media player or a camera that is dark in both appearances.
    static var dark: ContextMenuStyle {
        var style = ContextMenuStyle()
        style.menu.backgroundColor = UIColor(white: 0.13, alpha: 1)
        style.menu.separatorColor = UIColor(white: 1, alpha: 0.12)
        style.menu.sectionSeparatorColor = UIColor(white: 0, alpha: 0.4)
        style.row.titleColor = .white
        style.row.iconColor = .white
        style.row.disabledColor = UIColor(white: 1, alpha: 0.3)
        style.row.highlightedBackgroundColor = UIColor(white: 1, alpha: 0.14)
        style.row.destructiveColor = UIColor(red: 1, green: 0.42, blue: 0.4, alpha: 1)
        style.background.dimmingColor = UIColor(white: 0, alpha: 0.5)
        style.background.blurStyle = .systemUltraThinMaterialDark
        return style
    }
}

private extension UIFont {
    static func roundedSystemFont(ofSize size: CGFloat, weight: UIFont.Weight) -> UIFont {
        let font = UIFont.systemFont(ofSize: size, weight: weight)
        guard let descriptor = font.fontDescriptor.withDesign(.rounded) else {
            return font
        }
        return UIFont(descriptor: descriptor, size: size)
    }
}

// MARK: - Animation specs

private extension ContextMenuAnimationSpec {
    /// A deeper and longer press, a lift that overshoots, a menu that grows from a larger size.
    static var bouncy: ContextMenuAnimationSpec {
        var spec = ContextMenuAnimationSpec()
        spec.pressDownScale = 0.9
        spec.pressDownDuration = 0.3
        spec.presentation = Spring(duration: 0.7, dampingRatio: 0.5, initialVelocity: 1)
        spec.collapsedMenuScale = 0.3
        spec.dismissalDuration = 0.3
        return spec
    }

    /// A barely visible press and short transitions without an overshoot.
    static var snappy: ContextMenuAnimationSpec {
        var spec = ContextMenuAnimationSpec()
        spec.pressDownScale = 0.98
        spec.pressDownDuration = 0.08
        spec.presentation = Spring(duration: 0.3, dampingRatio: 1, initialVelocity: 0)
        spec.dismissalDuration = 0.15
        spec.previewFadeOutDuration = 0.1
        return spec
    }
}
