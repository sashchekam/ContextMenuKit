import UIKit

/// Adds a custom context menu to any view.
///
/// ```swift
/// let interaction = ContextMenuInteraction(delegate: self)
/// bubbleView.addInteraction(interaction)
/// ```
///
/// A long press asks the delegate for a ``ContextMenuConfiguration``, presses the view down,
/// lifts its preview above a blurred backdrop and shows the menu and the accessories next to it.
/// A configuration without menu items and accessories isn't shown.
/// Only one menu can be shown in a window at a time.
@MainActor
public final class ContextMenuInteraction: NSObject, UIInteraction {
    private enum Constants {
        static let minimumPressDuration: TimeInterval = 0.15
    }

    public weak var delegate: ContextMenuInteractionDelegate?
    public private(set) weak var view: UIView?
    /// The recognizer that opens the menu. Use it to set up relationships with other recognizers.
    public let longPressGestureRecognizer: UILongPressGestureRecognizer

    /// `true` from the start of the press until the menu is fully dismissed.
    public var isActive: Bool {
        presenter != nil
    }

    private let environment: ContextMenuEnvironment
    private var presenter: ContextMenuPresenter?

    public convenience init(delegate: ContextMenuInteractionDelegate?) {
        self.init(delegate: delegate, environment: .live)
    }

    init(delegate: ContextMenuInteractionDelegate?, environment: ContextMenuEnvironment) {
        self.delegate = delegate
        self.environment = environment
        longPressGestureRecognizer = UILongPressGestureRecognizer()
        super.init()
        longPressGestureRecognizer.minimumPressDuration = Constants.minimumPressDuration
        longPressGestureRecognizer.addTarget(self, action: #selector(handleLongPress(_:)))
    }

    // MARK: - UIInteraction

    public func willMove(to view: UIView?) {
        presenter?.dismiss(animated: false)
        self.view?.removeGestureRecognizer(longPressGestureRecognizer)
    }

    public func didMove(to view: UIView?) {
        self.view = view
        view?.addGestureRecognizer(longPressGestureRecognizer)
    }

    // MARK: - Presentation

    /// Presents the menu without a press, for example from a "More" button.
    public func presentMenu() {
        guard let view else {
            return
        }
        beginSession(at: CGPoint(x: view.bounds.midX, y: view.bounds.midY), pressesDown: false)
    }

    /// Dismisses the menu if it is shown. No action is performed.
    public func dismissMenu(animated: Bool = true) {
        presenter?.dismiss(animated: animated)
    }

    // MARK: - Private

    @objc
    private func handleLongPress(_ recognizer: UILongPressGestureRecognizer) {
        guard recognizer.state == .began, let view else {
            return
        }
        beginSession(at: recognizer.location(in: view), pressesDown: true)
    }

    private func beginSession(at location: CGPoint, pressesDown: Bool) {
        guard
            presenter == nil,
            let view,
            let window = view.window,
            !environment.registry.hasActivePresentation(in: window),
            let configuration = delegate?.contextMenuInteraction(self, configurationAt: location),
            !configuration.isEmpty
        else {
            return
        }

        let presenter = ContextMenuPresenter(
            sourceView: view,
            window: window,
            configuration: configuration,
            environment: environment
        )
        presenter.delegate = self
        self.presenter = presenter
        presenter.start(pressesDown: pressesDown)
    }
}

// MARK: - ContextMenuPresenterDelegate

extension ContextMenuInteraction: ContextMenuPresenterDelegate {
    func presenterWillPresent(_ presenter: ContextMenuPresenter) {
        delegate?.contextMenuInteractionWillPresent(self)
    }

    func presenterDidPresent(_ presenter: ContextMenuPresenter) {
        delegate?.contextMenuInteractionDidPresent(self)
    }

    func presenterWillDismiss(_ presenter: ContextMenuPresenter) {
        delegate?.contextMenuInteractionWillDismiss(self)
    }

    func presenterDidDismiss(_ presenter: ContextMenuPresenter) {
        delegate?.contextMenuInteractionDidDismiss(self)
    }

    func presenterDidFinish(_ presenter: ContextMenuPresenter) {
        guard self.presenter === presenter else {
            return
        }
        self.presenter = nil
    }
}
