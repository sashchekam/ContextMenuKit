import ContextMenuKit
import UIKit

/// Cards of different sizes in the corners and in the center: checks the layout rules
/// and the automatic alignment of the menu.
final class FreeViewsDemoViewController: UIViewController, DemoScreen {
    private enum Position {
        case topLeading
        case topTrailing
        case center
        case bottomLeading
        case bottomTrailing
    }

    private struct Card {
        let title: String
        let color: UIColor
        let size: CGSize
        let position: Position
    }

    private enum Constants {
        static let inset: CGFloat = 16
        /// A custom icon with its own color: the row doesn't tint images with `.alwaysOriginal` rendering.
        static let likeImage = UIImage(systemName: "heart.fill")?.withTintColor(.systemPink, renderingMode: .alwaysOriginal)
        static let cards = [
            Card(title: "Top leading", color: .systemBlue, size: CGSize(width: 130, height: 80), position: .topLeading),
            Card(title: "Top trailing", color: .systemIndigo, size: CGSize(width: 200, height: 120), position: .topTrailing),
            Card(title: "Center", color: .systemTeal, size: CGSize(width: 260, height: 150), position: .center),
            Card(title: "Bottom leading", color: .systemOrange, size: CGSize(width: 110, height: 110), position: .bottomLeading),
            Card(title: "Bottom trailing", color: .systemPink, size: CGSize(width: 180, height: 90), position: .bottomTrailing)
        ]
    }

    private var primaryInteraction: ContextMenuInteraction?

    func presentPrimaryMenu() {
        primaryInteraction?.presentMenu()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = Demo.freeViews.title
        view.backgroundColor = .systemBackground

        for card in Constants.cards {
            let cardView = DemoCardView(title: card.title, color: card.color)
            cardView.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview(cardView)
            NSLayoutConstraint.activate(constraints(for: cardView, card: card))

            let interaction = ContextMenuInteraction(delegate: self)
            cardView.addInteraction(interaction)
            if card.position == .center {
                primaryInteraction = interaction
            }
        }
    }

    private func constraints(for cardView: UIView, card: Card) -> [NSLayoutConstraint] {
        let guide = view.safeAreaLayoutGuide
        let size = [
            cardView.widthAnchor.constraint(equalToConstant: card.size.width),
            cardView.heightAnchor.constraint(equalToConstant: card.size.height)
        ]
        let position = switch card.position {
        case .topLeading:
            [
                cardView.topAnchor.constraint(equalTo: guide.topAnchor, constant: Constants.inset),
                cardView.leadingAnchor.constraint(equalTo: guide.leadingAnchor, constant: Constants.inset)
            ]
        case .topTrailing:
            [
                cardView.topAnchor.constraint(equalTo: guide.topAnchor, constant: Constants.inset),
                cardView.trailingAnchor.constraint(equalTo: guide.trailingAnchor, constant: -Constants.inset)
            ]
        case .center:
            [
                cardView.centerXAnchor.constraint(equalTo: guide.centerXAnchor),
                cardView.centerYAnchor.constraint(equalTo: guide.centerYAnchor)
            ]
        case .bottomLeading:
            [
                cardView.bottomAnchor.constraint(equalTo: guide.bottomAnchor, constant: -Constants.inset),
                cardView.leadingAnchor.constraint(equalTo: guide.leadingAnchor, constant: Constants.inset)
            ]
        case .bottomTrailing:
            [
                cardView.bottomAnchor.constraint(equalTo: guide.bottomAnchor, constant: -Constants.inset),
                cardView.trailingAnchor.constraint(equalTo: guide.trailingAnchor, constant: -Constants.inset)
            ]
        }
        return size + position
    }
}

// MARK: - ContextMenuInteractionDelegate

extension FreeViewsDemoViewController: ContextMenuInteractionDelegate {
    func contextMenuInteraction(
        _ interaction: ContextMenuInteraction,
        configurationAt location: CGPoint
    ) -> ContextMenuConfiguration? {
        let menu = ContextMenu {
            ContextMenuSection {
                ContextMenuAction.toast("Copy", image: .system(.copy), in: view)
                ContextMenuAction.toast("Share", image: .system(.share), in: view)
                ContextMenuAction.toast("Like", image: Constants.likeImage.map(ContextMenuImage.custom), in: view)
            }
            ContextMenuSection {
                ContextMenuAction.toast("Rename", image: .system(.edit), in: view, isEnabled: false)
                ContextMenuAction.toast("Delete", image: .system(.delete), in: view, isDestructive: true)
            }
        }
        return ContextMenuConfiguration(menu: menu)
    }
}
