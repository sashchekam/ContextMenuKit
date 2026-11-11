import ContextMenuKit
import UIKit

/// Chat-like screen: message bubbles in a collection view between the navigation bar and an input panel.
/// Incoming bubbles get a leading-aligned menu, outgoing ones — a trailing-aligned one.
/// A bar of reactions with a tail is shown above the bubble, on the side of the menu.
/// On the way back the preview is clipped to the messages area. Only outgoing messages can be edited.
final class ChatDemoViewController: UIViewController, DemoScreen {
    private enum Constants {
        static let inputPanelHeight: CGFloat = 52
        static let bubbleSpacing: CGFloat = 6
        static let primaryMessageIndex = 3
        static let reactions = ["❤️", "👍", "😂", "😮", "😢", "🔥"]
        /// The tail of the reactions bar almost touches the bubble.
        static let reactionsSpacing: CGFloat = 2
    }

    private let messages = ChatMessage.samples
    private lazy var collectionView = UICollectionView(frame: .zero, collectionViewLayout: makeLayout())
    private let inputPanel = ChatInputPanelView()

    override func viewDidLoad() {
        super.viewDidLoad()
        title = Demo.chat.title
        view.backgroundColor = .systemBackground
        navigationItem.largeTitleDisplayMode = .never

        collectionView.backgroundColor = .systemBackground
        collectionView.dataSource = self
        collectionView.register(MessageCell.self, forCellWithReuseIdentifier: MessageCell.reuseIdentifier)
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        inputPanel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(collectionView)
        view.addSubview(inputPanel)

        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: inputPanel.topAnchor),

            inputPanel.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            inputPanel.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            inputPanel.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            inputPanel.topAnchor.constraint(
                equalTo: view.safeAreaLayoutGuide.bottomAnchor,
                constant: -Constants.inputPanelHeight
            )
        ])
    }

    func presentPrimaryMenu() {
        let indexPath = IndexPath(item: Constants.primaryMessageIndex, section: 0)
        (collectionView.cellForItem(at: indexPath) as? MessageCell)?.interaction.presentMenu()
    }

    private func makeLayout() -> UICollectionViewLayout {
        let size = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .estimated(44))
        let group = NSCollectionLayoutGroup.vertical(layoutSize: size, subitems: [NSCollectionLayoutItem(layoutSize: size)])
        let section = NSCollectionLayoutSection(group: group)
        section.interGroupSpacing = Constants.bubbleSpacing
        section.contentInsets = NSDirectionalEdgeInsets(top: 12, leading: 0, bottom: 12, trailing: 0)
        return UICollectionViewCompositionalLayout(section: section)
    }

    private func menuConfiguration(for message: ChatMessage) -> ContextMenuConfiguration {
        let menu = ContextMenu {
            ContextMenuSection {
                ContextMenuAction.toast("Reply", image: .system(.reply), in: view)
                ContextMenuAction.toast("Copy", image: .system(.copy), in: view)
                ContextMenuAction.toast("Forward", image: .system(.forward), in: view)
            }
            ContextMenuSection {
                if message.isOutgoing {
                    ContextMenuAction.toast("Edit", image: .system(.edit), in: view)
                }
                ContextMenuAction.toast("Delete", image: .system(.delete), in: view, isDestructive: true)
            }
        }
        let reactions = ContextMenuAccessory(
            placement: .above(.preview, spacing: Constants.reactionsSpacing),
            scrollBehavior: .staysVisible
        ) { [weak view] menu in
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
            alignment: message.isOutgoing ? .trailing : .leading,
            clipping: .rect { [weak self] in
                guard let collectionView = self?.collectionView else {
                    return .infinite
                }
                return collectionView.convert(collectionView.bounds, to: nil)
            }
        )
    }
}

// MARK: - UICollectionViewDataSource

extension ChatDemoViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        messages.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: MessageCell.reuseIdentifier, for: indexPath)
        guard let messageCell = cell as? MessageCell else {
            return cell
        }
        let message = messages[indexPath.item]
        messageCell.configure(with: message)
        messageCell.menuConfigurationProvider = { [weak self] in
            self?.menuConfiguration(for: message)
        }
        return messageCell
    }
}

// MARK: - Message

struct ChatMessage {
    static let samples: [ChatMessage] = [
        ChatMessage(text: "Hi! Long-press any bubble.", isOutgoing: false),
        ChatMessage(text: "Like this?", isOutgoing: true),
        ChatMessage(text: "Exactly. The bubble presses down, then lifts above the blurred chat.", isOutgoing: false),
        ChatMessage(
            text: "And the menu grows from the corner that is closest to the bubble. "
                + "Mine are on the right, so the menu is aligned with their right edge.",
            isOutgoing: true
        ),
        ChatMessage(text: "Try the ones near the input panel.", isOutgoing: false),
        ChatMessage(text: "The bubble goes up so that the menu fits below it.", isOutgoing: true),
        ChatMessage(text: "👍", isOutgoing: false),
        ChatMessage(text: "Now scroll so that a bubble is half hidden under the navigation bar.", isOutgoing: false),
        ChatMessage(text: "On the way back it hides behind the bar instead of flying over it.", isOutgoing: true),
        ChatMessage(text: "Tap outside the menu to close it.", isOutgoing: false),
        ChatMessage(text: "Or pick an action — it runs only after the menu is gone.", isOutgoing: true),
        ChatMessage(text: "Short", isOutgoing: false),
        ChatMessage(text: "Shorter", isOutgoing: true),
        ChatMessage(
            text: "A longer message to check how multi-line bubbles look when they are lifted "
                + "and how the menu is placed under them. It has a few lines of text.",
            isOutgoing: false
        ),
        ChatMessage(text: "Looks fine.", isOutgoing: true),
        ChatMessage(text: "Last one near the bottom.", isOutgoing: false)
    ]

    let text: String
    let isOutgoing: Bool
}

// MARK: - Cell

final class MessageCell: UICollectionViewCell {
    static let reuseIdentifier = "MessageCell"

    private(set) lazy var interaction = ContextMenuInteraction(delegate: self)
    var menuConfigurationProvider: (() -> ContextMenuConfiguration?)?

    private let bubbleView = UIView()
    private let textLabel = UILabel()
    private var incomingConstraint: NSLayoutConstraint?
    private var outgoingConstraint: NSLayoutConstraint?

    override init(frame: CGRect) {
        super.init(frame: frame)
        setUpViews()
        bubbleView.addInteraction(interaction)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        nil
    }

    func configure(with message: ChatMessage) {
        textLabel.text = message.text
        textLabel.textColor = message.isOutgoing ? .white : .label
        bubbleView.backgroundColor = message.isOutgoing ? .systemBlue : .secondarySystemBackground
        incomingConstraint?.isActive = !message.isOutgoing
        outgoingConstraint?.isActive = message.isOutgoing
    }

    private func setUpViews() {
        bubbleView.layer.cornerRadius = 18
        bubbleView.layer.cornerCurve = .continuous
        bubbleView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(bubbleView)

        textLabel.numberOfLines = 0
        textLabel.font = .preferredFont(forTextStyle: .body)
        textLabel.translatesAutoresizingMaskIntoConstraints = false
        bubbleView.addSubview(textLabel)

        let bottomConstraint = bubbleView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
        bottomConstraint.priority = .defaultHigh
        incomingConstraint = bubbleView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 12)
        outgoingConstraint = bubbleView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -12)

        NSLayoutConstraint.activate([
            bubbleView.topAnchor.constraint(equalTo: contentView.topAnchor),
            bottomConstraint,
            bubbleView.widthAnchor.constraint(lessThanOrEqualTo: contentView.widthAnchor, multiplier: 0.75),
            textLabel.topAnchor.constraint(equalTo: bubbleView.topAnchor, constant: 8),
            textLabel.bottomAnchor.constraint(equalTo: bubbleView.bottomAnchor, constant: -8),
            textLabel.leadingAnchor.constraint(equalTo: bubbleView.leadingAnchor, constant: 12),
            textLabel.trailingAnchor.constraint(equalTo: bubbleView.trailingAnchor, constant: -12)
        ])
    }
}

extension MessageCell: ContextMenuInteractionDelegate {
    func contextMenuInteraction(
        _ interaction: ContextMenuInteraction,
        configurationAt location: CGPoint
    ) -> ContextMenuConfiguration? {
        menuConfigurationProvider?()
    }
}

// MARK: - Input panel

/// Fake input panel at the bottom: only marks the area the preview must not fly over.
final class ChatInputPanelView: UIView {
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .secondarySystemBackground

        let field = UILabel()
        field.text = "  Message"
        field.textColor = .placeholderText
        field.backgroundColor = .systemBackground
        field.layer.cornerRadius = 18
        field.layer.cornerCurve = .continuous
        field.clipsToBounds = true
        field.translatesAutoresizingMaskIntoConstraints = false
        addSubview(field)

        NSLayoutConstraint.activate([
            field.topAnchor.constraint(equalTo: topAnchor, constant: 8),
            field.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 12),
            field.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -12),
            field.heightAnchor.constraint(equalToConstant: 36)
        ])
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        nil
    }
}
