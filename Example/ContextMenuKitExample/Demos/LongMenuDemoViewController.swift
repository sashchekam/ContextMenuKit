import ContextMenuKit
import UIKit

/// Every built-in icon of ``ContextMenuSystemImage`` in one menu, made with `for` in the builder.
/// The menu is taller than the screen, so the overlay becomes scrollable.
/// The title of each action is the name of the case, a tap shows the name of the symbol.
final class LongMenuDemoViewController: UIViewController, DemoScreen {
    private enum Constants {
        static let inset: CGFloat = 16
        static let cardHeight: CGFloat = 110
    }

    private var primaryInteraction: ContextMenuInteraction?

    func presentPrimaryMenu() {
        primaryInteraction?.presentMenu()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = Demo.longMenu.title
        view.backgroundColor = .systemGroupedBackground

        let card = DemoCardView(
            title: "Long-press the card",
            subtitle: "\(ContextMenuSystemImage.allCases.count) built-in icons in one menu",
            color: .systemBlue
        )
        card.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(card)

        NSLayoutConstraint.activate([
            card.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 24),
            card.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: Constants.inset),
            card.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -Constants.inset),
            card.heightAnchor.constraint(equalToConstant: Constants.cardHeight)
        ])

        let interaction = ContextMenuInteraction(delegate: self)
        card.addInteraction(interaction)
        primaryInteraction = interaction
    }
}

// MARK: - ContextMenuInteractionDelegate

extension LongMenuDemoViewController: ContextMenuInteractionDelegate {
    func contextMenuInteraction(
        _ interaction: ContextMenuInteraction,
        configurationAt location: CGPoint
    ) -> ContextMenuConfiguration? {
        let menu = ContextMenu {
            for systemImage in ContextMenuSystemImage.allCases {
                ContextMenuAction(title: ".\(systemImage)", image: .system(systemImage)) { [weak self] in
                    guard let view = self?.view else {
                        return
                    }
                    Toast.show("SF Symbol \"\(systemImage.rawValue)\"", in: view)
                }
            }
        }
        return ContextMenuConfiguration(menu: menu)
    }
}
