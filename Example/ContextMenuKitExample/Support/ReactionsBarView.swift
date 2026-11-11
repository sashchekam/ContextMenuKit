import UIKit

/// A row of emoji buttons for an interactive custom menu item: each button reports its reaction.
final class ReactionsBarView: UIView {
    private enum Constants {
        static let buttonSize: CGFloat = 44
        static let emojiFontSize: CGFloat = 28
        static let insets = NSDirectionalEdgeInsets(top: 6, leading: 8, bottom: 6, trailing: 8)
    }

    init(reactions: [String], onSelect: @escaping @MainActor (String) -> Void) {
        super.init(frame: .zero)

        let buttons = reactions.map { reaction in
            UIButton.reaction(reaction, fontSize: Constants.emojiFontSize, onSelect: onSelect)
        }
        let stackView = UIStackView(arrangedSubviews: buttons)
        stackView.distribution = .fillEqually
        stackView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stackView)

        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: topAnchor, constant: Constants.insets.top),
            stackView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -Constants.insets.bottom),
            stackView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: Constants.insets.leading),
            stackView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -Constants.insets.trailing),
            stackView.heightAnchor.constraint(equalToConstant: Constants.buttonSize)
        ])
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        nil
    }
}
