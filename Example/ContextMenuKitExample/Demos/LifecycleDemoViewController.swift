import ContextMenuKit
import UIKit

/// The delegate's side of an interaction:
/// - every delegate call goes to a log with the time since the menu was asked for: the configuration comes first,
///   and the handler of the selected action runs only after `contextMenuInteractionDidDismiss`;
/// - the delegate returns `nil` for the locked card: no press-down and no menu;
/// - with the switch on, the menu is dismissed from code two seconds after it appears,
///   with `dismissMenu(animated:)` guarded by `isActive`;
/// - "Present" calls `presentMenu()`: the menu is asked for at the center of the view.
final class LifecycleDemoViewController: UIViewController, DemoScreen {
    private enum Constants {
        static let inset: CGFloat = 16
        static let spacing: CGFloat = 12
        static let cardHeight: CGFloat = 110
        static let autoDismissDelay: UInt64 = 2_000_000_000
        static let logCornerRadius: CGFloat = 12
        static let logInset: CGFloat = 12
    }

    private let menuCard = DemoCardView(title: "Long-press me", subtitle: "Every call is logged", color: .systemIndigo)
    private let lockedCard = DemoCardView(title: "Locked", subtitle: "The delegate returns nil", color: .systemGray)
    private let autoDismissSwitch = UISwitch()
    private let logView = UITextView()
    private lazy var menuInteraction = ContextMenuInteraction(delegate: self)
    private lazy var lockedInteraction = ContextMenuInteraction(delegate: self)

    private var logLines: [String] = []
    /// When the delegate was last asked for a menu: times in the log are counted from it.
    private var sessionStartTime: CFTimeInterval?
    private var autoDismissTask: Task<Void, Never>?

    func presentPrimaryMenu() {
        menuInteraction.presentMenu()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = Demo.lifecycle.title
        view.backgroundColor = .systemGroupedBackground
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            primaryAction: UIAction(title: "Present") { [weak self] _ in
                self?.menuInteraction.presentMenu()
            }
        )

        menuCard.addInteraction(menuInteraction)
        lockedCard.addInteraction(lockedInteraction)
        setUpViews()
        log("Long-press a card or tap Present.")
    }

    private func setUpViews() {
        let cardsStackView = UIStackView(arrangedSubviews: [menuCard, lockedCard])
        cardsStackView.distribution = .fillEqually
        cardsStackView.spacing = Constants.spacing

        let switchLabel = UILabel()
        switchLabel.text = "Dismiss from code after 2 s"
        switchLabel.font = .preferredFont(forTextStyle: .body)
        let switchStackView = UIStackView(arrangedSubviews: [switchLabel, autoDismissSwitch])
        switchStackView.spacing = Constants.spacing

        let logTitleLabel = UILabel()
        logTitleLabel.text = "Delegate calls, in seconds since the menu was asked for"
        logTitleLabel.font = .preferredFont(forTextStyle: .footnote)
        logTitleLabel.textColor = .secondaryLabel
        logTitleLabel.numberOfLines = 0
        let clearButton = UIButton(type: .system, primaryAction: UIAction(title: "Clear") { [weak self] _ in
            self?.clearLog()
        })
        clearButton.setContentHuggingPriority(.required, for: .horizontal)
        clearButton.setContentCompressionResistancePriority(.required, for: .horizontal)
        let logHeaderStackView = UIStackView(arrangedSubviews: [logTitleLabel, clearButton])
        logHeaderStackView.spacing = Constants.spacing

        logView.isEditable = false
        logView.font = .monospacedSystemFont(ofSize: 13, weight: .regular)
        logView.backgroundColor = .secondarySystemGroupedBackground
        logView.layer.cornerRadius = Constants.logCornerRadius
        logView.layer.cornerCurve = .continuous
        logView.textContainerInset = UIEdgeInsets(
            top: Constants.logInset,
            left: Constants.logInset,
            bottom: Constants.logInset,
            right: Constants.logInset
        )

        let stackView = UIStackView(arrangedSubviews: [cardsStackView, switchStackView, logHeaderStackView, logView])
        stackView.axis = .vertical
        stackView.spacing = Constants.spacing
        stackView.setCustomSpacing(Constants.spacing * 2, after: switchStackView)
        stackView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stackView)

        let guide = view.safeAreaLayoutGuide
        NSLayoutConstraint.activate([
            cardsStackView.heightAnchor.constraint(equalToConstant: Constants.cardHeight),
            stackView.topAnchor.constraint(equalTo: guide.topAnchor, constant: Constants.inset),
            stackView.leadingAnchor.constraint(equalTo: guide.leadingAnchor, constant: Constants.inset),
            stackView.trailingAnchor.constraint(equalTo: guide.trailingAnchor, constant: -Constants.inset),
            stackView.bottomAnchor.constraint(equalTo: guide.bottomAnchor, constant: -Constants.inset)
        ])
    }

    // MARK: - Log

    private func startSession() {
        sessionStartTime = CACurrentMediaTime()
        if !logLines.isEmpty {
            logLines.append("")
        }
    }

    private func log(_ message: String) {
        let line = sessionStartTime.map { start in
            String(format: "%6.3f  %@", CACurrentMediaTime() - start, message)
        } ?? message
        logLines.append(line)
        logView.text = logLines.joined(separator: "\n")
        logView.layoutIfNeeded()
        let bottomOffset = logView.contentSize.height - logView.bounds.height + logView.adjustedContentInset.bottom
        logView.setContentOffset(CGPoint(x: 0, y: max(-logView.adjustedContentInset.top, bottomOffset)), animated: false)
    }

    private func clearLog() {
        logLines = []
        sessionStartTime = nil
        logView.text = nil
    }

    private func loggedAction(_ title: String, image: ContextMenuSystemImage, isDestructive: Bool = false) -> ContextMenuAction {
        ContextMenuAction(title: title, image: .system(image), isDestructive: isDestructive) { [weak self] in
            self?.log("handler of \(title)")
        }
    }

    // MARK: - Dismissal from code

    private func scheduleAutoDismiss(of interaction: ContextMenuInteraction) {
        autoDismissTask = Task { [weak self, weak interaction] in
            try? await Task.sleep(nanoseconds: Constants.autoDismissDelay)
            // `isActive` is `true` until the menu is fully dismissed: a menu that is already closing is left alone.
            guard !Task.isCancelled, let self, let interaction, interaction.isActive else {
                return
            }
            log("dismissMenu(animated: true)")
            interaction.dismissMenu(animated: true)
        }
    }
}

// MARK: - ContextMenuInteractionDelegate

extension LifecycleDemoViewController: ContextMenuInteractionDelegate {
    func contextMenuInteraction(
        _ interaction: ContextMenuInteraction,
        configurationAt location: CGPoint
    ) -> ContextMenuConfiguration? {
        startSession()
        let point = "(\(Int(location.x)), \(Int(location.y)))"
        guard interaction === menuInteraction else {
            log("configurationAt \(point) → nil, no menu")
            return nil
        }
        log("configurationAt \(point)")
        let menu = ContextMenu {
            loggedAction("Copy", image: .copy)
            loggedAction("Share", image: .share)
            ContextMenuSection {
                loggedAction("Delete", image: .delete, isDestructive: true)
            }
        }
        return ContextMenuConfiguration(menu: menu)
    }

    func contextMenuInteractionWillPresent(_ interaction: ContextMenuInteraction) {
        log("willPresent")
    }

    func contextMenuInteractionDidPresent(_ interaction: ContextMenuInteraction) {
        log("didPresent")
        if autoDismissSwitch.isOn {
            scheduleAutoDismiss(of: interaction)
        }
    }

    func contextMenuInteractionWillDismiss(_ interaction: ContextMenuInteraction) {
        autoDismissTask?.cancel()
        autoDismissTask = nil
        log("willDismiss")
    }

    func contextMenuInteractionDidDismiss(_ interaction: ContextMenuInteraction) {
        log("didDismiss")
    }
}
