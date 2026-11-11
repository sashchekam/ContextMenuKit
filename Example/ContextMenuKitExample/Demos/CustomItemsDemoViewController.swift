import ContextMenuKit
import UIKit

/// Custom items in a UIKit menu:
/// - an interactive bar of reactions: its buttons close the menu through the proxy;
/// - an interactive volume slider that doesn't close the menu: the value changes while the menu is open,
///   and the card shows it once the menu is gone;
/// - a selectable "Seen by" row: the whole row highlights and closes the menu like an action.
final class CustomItemsDemoViewController: UIViewController, DemoScreen {
    private enum Constants {
        static let reactions = ["❤️", "👍", "😂", "😮", "😢", "🔥"]
        static let readers = ["Anna", "Max", "Lena"]
        static let title = "Long-press the card"
    }

    private let card = DemoCardView(title: Constants.title, color: .systemTeal)
    private var primaryInteraction: ContextMenuInteraction?
    private var volume: Float = 0.5 {
        didSet {
            updateVolumeSubtitle()
        }
    }

    func presentPrimaryMenu() {
        primaryInteraction?.presentMenu()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = Demo.customItems.title
        view.backgroundColor = .systemGroupedBackground

        updateVolumeSubtitle()
        card.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(card)

        NSLayoutConstraint.activate([
            card.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 24),
            card.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 16),
            card.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -16),
            card.heightAnchor.constraint(equalToConstant: 140)
        ])

        let interaction = ContextMenuInteraction(delegate: self)
        card.addInteraction(interaction)
        primaryInteraction = interaction
    }

    private func showToast(_ text: String) {
        Toast.show(text, in: view)
    }

    private func updateVolumeSubtitle() {
        card.subtitle = "Volume \(volume.formatted(.percent.precision(.fractionLength(0))))"
    }
}

// MARK: - ContextMenuInteractionDelegate

extension CustomItemsDemoViewController: ContextMenuInteractionDelegate {
    func contextMenuInteraction(
        _ interaction: ContextMenuInteraction,
        configurationAt location: CGPoint
    ) -> ContextMenuConfiguration? {
        let menu = ContextMenu {
            ContextMenuSection {
                // Interactive: the buttons get touches and close the menu themselves.
                ContextMenuCustomItem { [weak self] menu in
                    ReactionsBarView(reactions: Constants.reactions) { reaction in
                        menu.dismiss { self?.showToast("Reacted with \(reaction)") }
                    }
                }
            }
            ContextMenuSection {
                // Interactive and stays open: the slider changes the volume without closing the menu.
                ContextMenuCustomItem { [weak self] _ in
                    VolumeSliderView(value: self?.volume ?? 0) { value in
                        self?.volume = value
                    }
                }
            }
            ContextMenuSection {
                // Selectable: the row works like an action, the view only draws it.
                ContextMenuCustomItem { [weak self] in
                    self?.showToast("Seen by \(Constants.readers.formatted(.list(type: .and)))")
                } view: {
                    SeenByRowView(names: Constants.readers)
                }
                ContextMenuAction.toast("Reply", image: .system(.reply), in: view)
                ContextMenuAction.toast("Copy", image: .system(.copy), in: view)
            }
            ContextMenuSection {
                ContextMenuAction.toast("Delete", image: .system(.delete), in: view, isDestructive: true)
            }
        }
        return ContextMenuConfiguration(menu: menu)
    }
}
