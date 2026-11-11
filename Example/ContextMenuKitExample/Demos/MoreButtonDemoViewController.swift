import ContextMenuKit
import UIKit

/// The menu presented from a "More" button with `presentMenu()`; a long press on the card works too.
final class MoreButtonDemoViewController: UIViewController, DemoScreen {
    private var primaryInteraction: ContextMenuInteraction?

    func presentPrimaryMenu() {
        primaryInteraction?.presentMenu()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = Demo.moreButton.title
        view.backgroundColor = .systemGroupedBackground

        let card = DemoCardView(title: "Tap ⋯ or long-press the card", color: .systemPurple)
        let moreButton = UIButton(type: .system)
        moreButton.setImage(UIImage(systemName: "ellipsis.circle.fill"), for: .normal)
        moreButton.tintColor = .white
        moreButton.accessibilityLabel = "More"

        card.translatesAutoresizingMaskIntoConstraints = false
        moreButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(card)
        card.addSubview(moreButton)

        NSLayoutConstraint.activate([
            card.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 24),
            card.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 16),
            card.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -16),
            card.heightAnchor.constraint(equalToConstant: 140),
            moreButton.topAnchor.constraint(equalTo: card.topAnchor, constant: 8),
            moreButton.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -8),
            moreButton.widthAnchor.constraint(equalToConstant: 44),
            moreButton.heightAnchor.constraint(equalToConstant: 44)
        ])

        let interaction = ContextMenuInteraction(delegate: self)
        card.addInteraction(interaction)
        primaryInteraction = interaction
        moreButton.addAction(UIAction { _ in interaction.presentMenu() }, for: .primaryActionTriggered)
    }
}

// MARK: - ContextMenuInteractionDelegate

extension MoreButtonDemoViewController: ContextMenuInteractionDelegate {
    func contextMenuInteraction(
        _ interaction: ContextMenuInteraction,
        configurationAt location: CGPoint
    ) -> ContextMenuConfiguration? {
        // Actions outside of a section form one section, Delete gets its own.
        let menu = ContextMenu {
            ContextMenuAction.toast("Edit", image: .system(.edit), in: view)
            ContextMenuAction.toast("Share", image: .system(.share), in: view)
            ContextMenuAction.toast("Duplicate", image: .system(.duplicate), in: view)
            ContextMenuSection {
                ContextMenuAction.toast("Delete", image: .system(.delete), in: view, isDestructive: true)
            }
        }
        return ContextMenuConfiguration(menu: menu, alignment: .trailing)
    }
}
