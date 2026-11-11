@testable import ContextMenuKit
import Testing
import UIKit

@MainActor
@Suite("ContextMenuListView snapshots")
struct ContextMenuListViewSnapshotTests {
    @Test("Two sections with destructive and disabled actions", arguments: [UIUserInterfaceStyle.light, .dark])
    func twoSections(interfaceStyle: UIUserInterfaceStyle) {
        let view = ContextMenuListView(menu: .sample, style: .default, proxy: DismissRecorder().proxy)
        view.frame = CGRect(origin: .zero, size: view.preferredSize)

        expectSnapshot(of: view, named: interfaceStyle == .dark ? "dark" : "light", interfaceStyle: interfaceStyle)
    }

    @Test("Custom items next to actions", arguments: [UIUserInterfaceStyle.light, .dark])
    func customItems(interfaceStyle: UIUserInterfaceStyle) {
        let view = ContextMenuListView(menu: .customItems, style: .default, proxy: DismissRecorder().proxy)
        view.frame = CGRect(origin: .zero, size: view.preferredSize)

        expectSnapshot(of: view, named: interfaceStyle == .dark ? "dark" : "light", interfaceStyle: interfaceStyle)
    }
}

private extension ContextMenu {
    static var customItems: ContextMenu {
        ContextMenu {
            ContextMenuSection {
                ContextMenuCustomItem { _ in SymbolBarView() }
            }
            ContextMenuSection {
                ContextMenuCustomItem { } view: {
                    ReceiptsRowView()
                }
                ContextMenuAction(title: "Reply", image: .system(.reply)) { }
                ContextMenuAction(title: "Copy", image: .system(.copy)) { }
            }
        }
    }

    static var sample: ContextMenu {
        ContextMenu {
            ContextMenuSection {
                ContextMenuAction(title: "Reply", image: .system(.reply)) { }
                ContextMenuAction(title: "Copy", image: .system(.copy)) { }
                ContextMenuAction(
                    title: "A very long title that doesn't fit into the row",
                    image: UIImage(systemName: "text.alignleft").map(ContextMenuImage.custom)
                ) { }
            }
            ContextMenuSection {
                ContextMenuAction(title: "Edit", image: .system(.edit), isEnabled: false) { }
                ContextMenuAction(title: "Delete", image: .system(.delete), isDestructive: true) { }
            }
        }
    }
}

/// An interactive item: a row of symbols, like a bar of reactions. Its height comes from Auto Layout.
private final class SymbolBarView: UIView {
    override init(frame: CGRect) {
        super.init(frame: frame)
        let symbolNames = ["heart.fill", "hand.thumbsup.fill", "flame.fill", "star.fill", "face.smiling"]
        let stackView = UIStackView(arrangedSubviews: symbolNames.map { name in
            let imageView = UIImageView(image: UIImage(systemName: name))
            imageView.contentMode = .scaleAspectFit
            imageView.tintColor = .systemOrange
            return imageView
        })
        stackView.distribution = .fillEqually
        stackView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stackView)
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: topAnchor, constant: 12),
            stackView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -12),
            stackView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 8),
            stackView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -8),
            stackView.heightAnchor.constraint(equalToConstant: 28)
        ])
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        nil
    }
}

/// A selectable item: two lines of text and avatars, taller than an action row.
private final class ReceiptsRowView: UIView {
    override init(frame: CGRect) {
        super.init(frame: frame)
        let titleLabel = UILabel()
        titleLabel.text = "Seen by 3 people"
        titleLabel.font = .systemFont(ofSize: 17)
        let subtitleLabel = UILabel()
        subtitleLabel.text = "Today at 12:41"
        subtitleLabel.font = .systemFont(ofSize: 13)
        subtitleLabel.textColor = .secondaryLabel
        let textStackView = UIStackView(arrangedSubviews: [titleLabel, subtitleLabel])
        textStackView.axis = .vertical
        textStackView.spacing = 2

        let avatarsStackView = UIStackView(arrangedSubviews: [UIColor.systemBlue, .systemGreen, .systemPink].map { color in
            let avatarView = UIView()
            avatarView.backgroundColor = color
            avatarView.layer.cornerRadius = 12
            avatarView.widthAnchor.constraint(equalToConstant: 24).isActive = true
            avatarView.heightAnchor.constraint(equalToConstant: 24).isActive = true
            return avatarView
        })
        avatarsStackView.spacing = -6

        for subview in [textStackView, avatarsStackView] {
            subview.translatesAutoresizingMaskIntoConstraints = false
            addSubview(subview)
        }
        NSLayoutConstraint.activate([
            textStackView.topAnchor.constraint(equalTo: topAnchor, constant: 10),
            textStackView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -10),
            textStackView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            avatarsStackView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            avatarsStackView.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        nil
    }
}
