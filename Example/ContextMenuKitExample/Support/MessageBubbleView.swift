import UIKit

/// A chat bubble with the text of a message.
///
/// The chat shows one in each cell, and the menu lifts another one as a live preview, where the text
/// can be selected and copied. Both draw the text with the same `UITextView` setup, so the preview looks
/// exactly like the bubble it covers.
final class MessageBubbleView: UIView {
    private enum Constants {
        static let cornerRadius: CGFloat = 18
        static let textInsets = UIEdgeInsets(top: 8, left: 12, bottom: 8, right: 12)
    }

    private let textView = UITextView()

    /// - Parameter isTextSelectable: `true` lets the user select a part of the text and copy it.
    ///   `false` leaves touches to the views around, for example to the menu interaction of the bubble.
    init(isTextSelectable: Bool = false) {
        super.init(frame: .zero)
        layer.cornerRadius = Constants.cornerRadius
        layer.cornerCurve = .continuous
        setUpTextView(isSelectable: isTextSelectable)
    }

    convenience init(message: ChatMessage, isTextSelectable: Bool) {
        self.init(isTextSelectable: isTextSelectable)
        configure(with: message)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        nil
    }

    func configure(with message: ChatMessage) {
        textView.text = message.text
        textView.textColor = message.isOutgoing ? .white : .label
        // The selection and its handles take the tint color: white stays visible on a blue bubble.
        textView.tintColor = message.isOutgoing ? .white : .systemBlue
        backgroundColor = message.isOutgoing ? .systemBlue : .secondarySystemBackground
    }

    private func setUpTextView(isSelectable: Bool) {
        textView.isEditable = false
        textView.isSelectable = isSelectable
        textView.isUserInteractionEnabled = isSelectable
        // Lays the text out like a multi-line label: as tall as the text, without extra insets.
        textView.isScrollEnabled = false
        textView.textContainerInset = .zero
        textView.textContainer.lineFragmentPadding = 0
        textView.backgroundColor = .clear
        textView.font = .preferredFont(forTextStyle: .body)
        textView.adjustsFontForContentSizeCategory = true
        textView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(textView)

        NSLayoutConstraint.activate([
            textView.topAnchor.constraint(equalTo: topAnchor, constant: Constants.textInsets.top),
            textView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -Constants.textInsets.bottom),
            textView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: Constants.textInsets.left),
            textView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -Constants.textInsets.right)
        ])
    }
}
