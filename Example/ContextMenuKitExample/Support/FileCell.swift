import ContextMenuKit
import UIKit

/// A tile of the Files demo: the icon of the kind, badges for a pinned and a favorite file, the name and the details.
/// The menu comes from ``menuConfigurationProvider``, set by the screen.
final class FileCell: UICollectionViewCell {
    static let reuseIdentifier = "FileCell"

    private enum Constants {
        static let inset: CGFloat = 14
        static let iconPointSize: CGFloat = 30
        static let badgePointSize: CGFloat = 13
        static let cornerRadius: CGFloat = 16
    }

    private(set) lazy var interaction = ContextMenuInteraction(delegate: self)
    var menuConfigurationProvider: (() -> ContextMenuConfiguration?)?

    private let tileView = UIView()
    private let iconView = UIImageView()
    private let favoriteBadge = UIImageView()
    private let pinBadge = UIImageView()
    private let nameLabel = UILabel()
    private let detailsLabel = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setUpViews()
        tileView.addInteraction(interaction)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        nil
    }

    func configure(with file: DemoFile) {
        iconView.image = UIImage(systemName: file.kind.symbolName)
        iconView.tintColor = file.kind.color
        nameLabel.text = file.name
        detailsLabel.text = file.details
        favoriteBadge.isHidden = !file.isFavorite
        pinBadge.isHidden = !file.isPinned
    }

    private func setUpViews() {
        tileView.backgroundColor = .secondarySystemGroupedBackground
        tileView.layer.cornerRadius = Constants.cornerRadius
        tileView.layer.cornerCurve = .continuous

        iconView.preferredSymbolConfiguration = UIImage.SymbolConfiguration(pointSize: Constants.iconPointSize)
        iconView.contentMode = .scaleAspectFit

        let badgeConfiguration = UIImage.SymbolConfiguration(pointSize: Constants.badgePointSize, weight: .semibold)
        favoriteBadge.image = UIImage(systemName: "star.fill", withConfiguration: badgeConfiguration)
        favoriteBadge.tintColor = .systemYellow
        pinBadge.image = UIImage(systemName: "pin.fill", withConfiguration: badgeConfiguration)
        pinBadge.tintColor = .systemOrange
        let badgesStackView = UIStackView(arrangedSubviews: [pinBadge, favoriteBadge])
        badgesStackView.spacing = 4

        nameLabel.font = .preferredFont(forTextStyle: .headline)
        nameLabel.numberOfLines = 2
        detailsLabel.font = .preferredFont(forTextStyle: .footnote)
        detailsLabel.textColor = .secondaryLabel
        let textStackView = UIStackView(arrangedSubviews: [nameLabel, detailsLabel])
        textStackView.axis = .vertical
        textStackView.spacing = 2

        for subview in [tileView, iconView, badgesStackView, textStackView] {
            subview.translatesAutoresizingMaskIntoConstraints = false
        }
        contentView.addSubview(tileView)
        tileView.addSubview(iconView)
        tileView.addSubview(badgesStackView)
        tileView.addSubview(textStackView)

        NSLayoutConstraint.activate([
            tileView.topAnchor.constraint(equalTo: contentView.topAnchor),
            tileView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            tileView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            tileView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),

            iconView.topAnchor.constraint(equalTo: tileView.topAnchor, constant: Constants.inset),
            iconView.leadingAnchor.constraint(equalTo: tileView.leadingAnchor, constant: Constants.inset),
            badgesStackView.topAnchor.constraint(equalTo: tileView.topAnchor, constant: Constants.inset),
            badgesStackView.trailingAnchor.constraint(equalTo: tileView.trailingAnchor, constant: -Constants.inset),

            textStackView.leadingAnchor.constraint(equalTo: tileView.leadingAnchor, constant: Constants.inset),
            textStackView.trailingAnchor.constraint(equalTo: tileView.trailingAnchor, constant: -Constants.inset),
            textStackView.bottomAnchor.constraint(equalTo: tileView.bottomAnchor, constant: -Constants.inset)
        ])
    }
}

extension FileCell: ContextMenuInteractionDelegate {
    func contextMenuInteraction(
        _ interaction: ContextMenuInteraction,
        configurationAt location: CGPoint
    ) -> ContextMenuConfiguration? {
        menuConfigurationProvider?()
    }
}
