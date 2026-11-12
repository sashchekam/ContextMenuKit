import ContextMenuKit
import UIKit

/// A bar of reactions for an accessory above a message: a capsule with a tail of two circles
/// that points at the message. When the menu appears, the buttons pop in one by one, starting from the tail.
///
/// Adopts ``ContextMenuAccessoryView`` to learn where the message ends up.
final class ReactionsPanelView: UIView, ContextMenuAccessoryView {
    private struct Tail {
        /// Center of the large circle in the coordinates of the panel.
        var centerX: CGFloat
        /// The message is on the left: the small circle goes left and the buttons spin clockwise.
        var isOnLeft: Bool
    }

    private enum Constants {
        static let capsuleHeight: CGFloat = 48
        static let tailHeight: CGFloat = 18
        static let buttonSize: CGFloat = 40
        static let emojiFontSize: CGFloat = 26
        static let horizontalInset: CGFloat = 4
        static let largeTailRadius: CGFloat = 8
        static let smallTailRadius: CGFloat = 4
        static let largeTailCenterY = capsuleHeight + 2
        static let smallTailCenterY = capsuleHeight + 14
        static let smallTailShift: CGFloat = 6
        /// Distance from the edge of the message to the tail.
        static let tailInset: CGFloat = 24
        static let shadowOpacity: Float = 0.12
        static let shadowRadius: CGFloat = 8
        // Pop-in of the buttons.
        static let popDuration: TimeInterval = 0.35
        static let popDampingRatio: CGFloat = 0.6
        static let popVelocity: CGFloat = 0.5
        static let popDelay: TimeInterval = 0.03
        static let popDelayStep: TimeInterval = 0.017
        static let collapsedButtonScale: CGFloat = 0.1
    }

    private let capsuleView = UIView()
    private let largeTailView = UIView()
    private let smallTailView = UIView()
    private let buttons: [UIButton]
    private var tail = Tail(centerX: Constants.tailInset, isOnLeft: true)

    init(reactions: [String], onSelect: @escaping @MainActor (String) -> Void) {
        buttons = reactions.map { reaction in
            UIButton.reaction(reaction, fontSize: Constants.emojiFontSize, onSelect: onSelect)
        }
        super.init(frame: .zero)
        setUpViews()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        nil
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        let smallTailCenterX = tail.centerX + (tail.isOnLeft ? -Constants.smallTailShift : Constants.smallTailShift)
        largeTailView.frame = Self.circle(
            center: CGPoint(x: tail.centerX, y: Constants.largeTailCenterY),
            radius: Constants.largeTailRadius
        )
        smallTailView.frame = Self.circle(
            center: CGPoint(x: smallTailCenterX, y: Constants.smallTailCenterY),
            radius: Constants.smallTailRadius
        )
    }

    // MARK: - ContextMenuAccessoryView

    func contextMenuAccessoryWillPresent(_ context: ContextMenuAccessoryContext) {
        layoutIfNeeded()
        tail = Self.tail(pointingAt: context.previewFrame, panelWidth: bounds.width)
        setNeedsLayout()
        popInButtons()
    }

    // MARK: - Private

    private func setUpViews() {
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = Constants.shadowOpacity
        layer.shadowRadius = Constants.shadowRadius
        layer.shadowOffset = .zero

        for tailView in [largeTailView, smallTailView] {
            tailView.backgroundColor = .secondarySystemGroupedBackground
            addSubview(tailView)
        }
        largeTailView.layer.cornerRadius = Constants.largeTailRadius
        smallTailView.layer.cornerRadius = Constants.smallTailRadius
        capsuleView.backgroundColor = .secondarySystemGroupedBackground
        capsuleView.layer.cornerRadius = Constants.capsuleHeight / 2
        capsuleView.layer.cornerCurve = .continuous
        capsuleView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(capsuleView)

        let stackView = UIStackView(arrangedSubviews: buttons)
        stackView.translatesAutoresizingMaskIntoConstraints = false
        capsuleView.addSubview(stackView)

        NSLayoutConstraint.activate([
            capsuleView.topAnchor.constraint(equalTo: topAnchor),
            capsuleView.leadingAnchor.constraint(equalTo: leadingAnchor),
            capsuleView.trailingAnchor.constraint(equalTo: trailingAnchor),
            capsuleView.heightAnchor.constraint(equalToConstant: Constants.capsuleHeight),
            bottomAnchor.constraint(equalTo: capsuleView.bottomAnchor, constant: Constants.tailHeight),

            stackView.leadingAnchor.constraint(equalTo: capsuleView.leadingAnchor, constant: Constants.horizontalInset),
            stackView.trailingAnchor.constraint(equalTo: capsuleView.trailingAnchor, constant: -Constants.horizontalInset),
            stackView.centerYAnchor.constraint(equalTo: capsuleView.centerYAnchor)
        ] + buttons.flatMap { button in
            [
                button.widthAnchor.constraint(equalToConstant: Constants.buttonSize),
                button.heightAnchor.constraint(equalToConstant: Constants.buttonSize)
            ]
        })
    }

    /// The buttons pop in with a spin, the closest to the tail first.
    private func popInButtons() {
        let rotation: CGFloat = tail.isOnLeft ? .pi / 2 : -.pi / 2
        let collapsedTransform = CGAffineTransform(scaleX: Constants.collapsedButtonScale, y: Constants.collapsedButtonScale)
            .rotated(by: rotation)
        let orderedButtons = buttons.sorted { first, second in
            distanceToTail(from: first) < distanceToTail(from: second)
        }

        for (index, button) in orderedButtons.enumerated() {
            button.alpha = 0
            button.transform = collapsedTransform
            UIView.animate(
                withDuration: Constants.popDuration,
                delay: Constants.popDelay + Constants.popDelayStep * Double(index),
                usingSpringWithDamping: Constants.popDampingRatio,
                initialSpringVelocity: Constants.popVelocity,
                options: .allowUserInteraction
            ) {
                button.alpha = 1
                button.transform = .identity
            }
        }
    }

    private func distanceToTail(from button: UIButton) -> CGFloat {
        abs(button.convert(CGPoint(x: button.bounds.midX, y: 0), to: self).x - tail.centerX)
    }

    /// The tail goes near the edge of the message on the side the panel is aligned with,
    /// within the message and the straight part of the capsule.
    private static func tail(pointingAt previewFrame: CGRect, panelWidth: CGFloat) -> Tail {
        let isOnLeft = abs(previewFrame.minX) <= abs(panelWidth - previewFrame.maxX)
        let preferredX = isOnLeft ? previewFrame.minX + Constants.tailInset : previewFrame.maxX - Constants.tailInset
        let withinPreview = min(
            max(preferredX, previewFrame.minX + Constants.largeTailRadius),
            previewFrame.maxX - Constants.largeTailRadius
        )
        let capsuleRadius = Constants.capsuleHeight / 2
        let centerX = min(max(withinPreview, capsuleRadius), panelWidth - capsuleRadius)
        return Tail(centerX: centerX, isOnLeft: isOnLeft)
    }

    private static func circle(center: CGPoint, radius: CGFloat) -> CGRect {
        CGRect(x: center.x - radius, y: center.y - radius, width: radius * 2, height: radius * 2)
    }
}
