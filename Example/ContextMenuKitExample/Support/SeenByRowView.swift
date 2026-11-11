import UIKit

/// Content of a selectable custom menu item: who has seen a message, with avatars on the trailing side.
/// Taller than an action row: the item takes its height from Auto Layout.
final class SeenByRowView: UIView {
    private enum Constants {
        static let avatarSize: CGFloat = 28
        static let avatarOverlap: CGFloat = 6
        static let avatarColors: [UIColor] = [.systemBlue, .systemGreen, .systemPink, .systemOrange]
        static let horizontalInset: CGFloat = 16
        static let verticalInset: CGFloat = 10
        static let spacing: CGFloat = 8
    }

    init(names: [String]) {
        super.init(frame: .zero)

        let titleLabel = UILabel()
        titleLabel.text = "Seen by \(names.count) people"
        titleLabel.font = .preferredFont(forTextStyle: .body)
        titleLabel.adjustsFontForContentSizeCategory = true

        let subtitleLabel = UILabel()
        subtitleLabel.text = names.formatted(.list(type: .and))
        subtitleLabel.font = .preferredFont(forTextStyle: .footnote)
        subtitleLabel.adjustsFontForContentSizeCategory = true
        subtitleLabel.textColor = .secondaryLabel

        let textStackView = UIStackView(arrangedSubviews: [titleLabel, subtitleLabel])
        textStackView.axis = .vertical
        textStackView.spacing = 2

        let avatarsStackView = UIStackView(arrangedSubviews: names.enumerated().map { index, name in
            makeAvatar(for: name, color: Constants.avatarColors[index % Constants.avatarColors.count])
        })
        avatarsStackView.spacing = -Constants.avatarOverlap
        avatarsStackView.setContentCompressionResistancePriority(.required, for: .horizontal)

        for subview in [textStackView, avatarsStackView] {
            subview.translatesAutoresizingMaskIntoConstraints = false
            addSubview(subview)
        }
        NSLayoutConstraint.activate([
            textStackView.topAnchor.constraint(equalTo: topAnchor, constant: Constants.verticalInset),
            textStackView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -Constants.verticalInset),
            textStackView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: Constants.horizontalInset),
            avatarsStackView.leadingAnchor.constraint(
                greaterThanOrEqualTo: textStackView.trailingAnchor,
                constant: Constants.spacing
            ),
            avatarsStackView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -Constants.horizontalInset),
            avatarsStackView.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        nil
    }

    private func makeAvatar(for name: String, color: UIColor) -> UIView {
        let label = UILabel()
        label.text = name.first.map(String.init)
        label.font = .systemFont(ofSize: 13, weight: .semibold)
        label.textColor = .white
        label.textAlignment = .center
        label.backgroundColor = color
        label.layer.cornerRadius = Constants.avatarSize / 2
        label.clipsToBounds = true
        NSLayoutConstraint.activate([
            label.widthAnchor.constraint(equalToConstant: Constants.avatarSize),
            label.heightAnchor.constraint(equalToConstant: Constants.avatarSize)
        ])
        return label
    }
}
