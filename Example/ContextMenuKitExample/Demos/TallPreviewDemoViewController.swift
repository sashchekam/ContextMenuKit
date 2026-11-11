import ContextMenuKit
import UIKit

/// A card taller than the screen: the preview is pinned to the top of the safe area
/// and the overlay scrolls down to the menu, like long messages in iMessage.
/// The reactions above the card stay at the top of the screen while the overlay scrolls.
final class TallPreviewDemoViewController: UIViewController, DemoScreen {
    private enum Constants {
        static let inset: CGFloat = 16
        static let reactions = ["❤️", "👍", "😂", "😮", "😢", "🔥"]
        static let heading = "A message taller than the screen"
        static let paragraphs = [
            "Long messages happen: a pasted article, a long list, a log. This card is one of them, "
                + "and it is taller than the screen. Long-press it anywhere.",
            "The card presses down and lifts, like any other view. It doesn't fit on the screen together with the menu, "
                + "so the preview is pinned to the top of the safe area and keeps its width and position on the x axis.",
            "The overlay becomes scrollable. It starts scrolled to the bottom, so the menu is in sight right away — "
                + "the same way iMessage shows long messages. Scroll the overlay up to read the beginning of the card.",
            "The bar of reactions is attached to the top of the card. With the default scroll behavior "
                + "it would scroll away with the card, but this one uses staysVisible: "
                + "it sticks to the top of the safe area, like a section header, and stays at hand while you scroll.",
            "Tap outside of the card or pick an action to close the menu. On its way back the preview is clipped "
                + "to the scroll view of this screen, so it slides under the navigation bar instead of flying over it.",
            "The action runs only after the preview is back in place, so whatever the action changes "
                + "doesn't disturb the animation.",
            "Scroll this screen down a little and long-press the card again: the preview flies up from its place "
                + "and, on the way back, hides under the navigation bar again.",
            "That's the whole story of a long message. The rest of the card is here only to make it long enough "
                + "for the larger phones and the larger text sizes: the overlay only scrolls when the content "
                + "doesn't fit into the window.",
            "The end."
        ]
    }

    private var primaryInteraction: ContextMenuInteraction?

    private let scrollView = UIScrollView()

    func presentPrimaryMenu() {
        primaryInteraction?.presentMenu()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = Demo.tallPreview.title
        view.backgroundColor = .systemBackground
        navigationItem.largeTitleDisplayMode = .never

        let card = UIView()
        card.backgroundColor = .secondarySystemBackground
        card.layer.cornerRadius = 18
        card.layer.cornerCurve = .continuous

        let label = UILabel()
        label.numberOfLines = 0
        label.attributedText = Self.makeText()

        scrollView.translatesAutoresizingMaskIntoConstraints = false
        card.translatesAutoresizingMaskIntoConstraints = false
        label.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)
        scrollView.addSubview(card)
        card.addSubview(label)

        let content = scrollView.contentLayoutGuide
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),

            card.topAnchor.constraint(equalTo: content.topAnchor, constant: Constants.inset),
            card.bottomAnchor.constraint(equalTo: content.bottomAnchor, constant: -Constants.inset),
            card.leadingAnchor.constraint(equalTo: content.leadingAnchor, constant: Constants.inset),
            card.trailingAnchor.constraint(equalTo: content.trailingAnchor, constant: -Constants.inset),
            card.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor, constant: -2 * Constants.inset),

            label.topAnchor.constraint(equalTo: card.topAnchor, constant: 12),
            label.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -12),
            label.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 14),
            label.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -14)
        ])

        let interaction = ContextMenuInteraction(delegate: self)
        card.addInteraction(interaction)
        primaryInteraction = interaction
    }
}

// MARK: - Text

private extension TallPreviewDemoViewController {
    static func makeText() -> NSAttributedString {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.paragraphSpacing = 12
        let text = NSMutableAttributedString(
            string: Constants.heading + "\n",
            attributes: [.font: UIFont.preferredFont(forTextStyle: .title2), .paragraphStyle: paragraphStyle]
        )
        text.append(NSAttributedString(
            string: Constants.paragraphs.joined(separator: "\n"),
            attributes: [.font: UIFont.preferredFont(forTextStyle: .body), .paragraphStyle: paragraphStyle]
        ))
        return text
    }
}

// MARK: - ContextMenuInteractionDelegate

extension TallPreviewDemoViewController: ContextMenuInteractionDelegate {
    func contextMenuInteraction(
        _ interaction: ContextMenuInteraction,
        configurationAt location: CGPoint
    ) -> ContextMenuConfiguration? {
        let menu = ContextMenu {
            ContextMenuAction.toast("Copy", image: .system(.copy), in: view)
            ContextMenuAction.toast("Share", image: .system(.share), in: view)
            ContextMenuAction.toast("Bookmark", image: .system(.bookmark), in: view)
        }
        let reactions = ContextMenuAccessory(scrollBehavior: .staysVisible) { [weak view] menu in
            ReactionsPanelView(reactions: Constants.reactions) { reaction in
                menu.dismiss {
                    guard let view else {
                        return
                    }
                    Toast.show("Reacted with \(reaction)", in: view)
                }
            }
        }
        return ContextMenuConfiguration(
            menu: menu,
            accessories: [reactions],
            clipping: .rect { [weak self] in
                guard let scrollView = self?.scrollView else {
                    return .infinite
                }
                return scrollView.convert(scrollView.bounds, to: nil)
            }
        )
    }
}
