import UIKit

/// A rounded colored card with a centered title and an optional subtitle under it.
final class DemoCardView: UIView {
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()

    /// A secondary line under the title, hidden when `nil`.
    var subtitle: String? {
        get {
            subtitleLabel.text
        }
        set {
            subtitleLabel.text = newValue
            subtitleLabel.isHidden = newValue == nil
        }
    }

    init(title: String, subtitle: String? = nil, color: UIColor, cornerRadius: CGFloat = 16) {
        super.init(frame: .zero)
        backgroundColor = color
        layer.cornerRadius = cornerRadius
        layer.cornerCurve = .continuous

        titleLabel.text = title
        titleLabel.font = .preferredFont(forTextStyle: .headline)
        titleLabel.textColor = .white
        subtitleLabel.font = .preferredFont(forTextStyle: .footnote)
        subtitleLabel.textColor = .white.withAlphaComponent(0.85)
        for label in [titleLabel, subtitleLabel] {
            label.textAlignment = .center
            label.numberOfLines = 0
        }
        self.subtitle = subtitle

        let stackView = UIStackView(arrangedSubviews: [titleLabel, subtitleLabel])
        stackView.axis = .vertical
        stackView.alignment = .center
        stackView.spacing = 4
        stackView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stackView)

        NSLayoutConstraint.activate([
            stackView.centerXAnchor.constraint(equalTo: centerXAnchor),
            stackView.centerYAnchor.constraint(equalTo: centerYAnchor),
            stackView.leadingAnchor.constraint(greaterThanOrEqualTo: leadingAnchor, constant: 8),
            stackView.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor, constant: -8)
        ])
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        nil
    }
}
