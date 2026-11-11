import SwiftUI
import UIKit

/// Hosts the content of the SwiftUI `contextMenuInteraction` modifier in its own view, so that the menu
/// can press that view down, snapshot it and hide it like any other `UIView`.
///
/// SwiftUI lays out this controller's view; the hosted view inside it belongs to the menu, which changes
/// its `transform` and `alpha`. Keeps the `isPresented` binding of the modifier in sync with the menu.
///
/// Needs iOS 16: SwiftUI asks for the size through `sizeThatFits(_:)` with a `ProposedViewSize`, and the content
/// reports its own size changes through `sizingOptions`.
@available(iOS 16.0, *)
@MainActor
final class ContextMenuHostingController<Content: View>: UIViewController {
    let interaction: ContextMenuInteraction

    private let hostingController: UIHostingController<ContextMenuHostedContent<Content>>
    private let environment: ContextMenuEnvironment
    /// The environment around the modifier. SwiftUI views of custom items in the menu get it too.
    private var environmentValues: EnvironmentValues
    private var makeConfiguration: (@MainActor () -> ContextMenuConfiguration)?
    private var isPresented: Binding<Bool>?
    /// `true` from the moment the menu starts to appear until it is dismissed. The binding follows this value.
    private var isMenuPresented = false
    private var isPresentationUpdateScheduled = false

    init(content: Content, environmentValues: EnvironmentValues, environment: ContextMenuEnvironment) {
        hostingController = UIHostingController(
            rootView: ContextMenuHostedContent(content: content, environmentValues: environmentValues)
        )
        interaction = ContextMenuInteraction(delegate: nil, environment: environment)
        self.environment = environment
        self.environmentValues = environmentValues
        super.init(nibName: nil, bundle: nil)
        interaction.delegate = self
        // Lets the controller notice when the content changes its size on its own, see below.
        hostingController.sizingOptions = [.preferredContentSize]
        if #available(iOS 16.4, *) {
            hostingController.safeAreaRegions = []
        }
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        nil
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        let hostedView: UIView = hostingController.view
        hostedView.backgroundColor = .clear
        hostedView.addInteraction(interaction)
        addChild(hostingController)
        view.addSubview(hostedView)
        hostingController.didMove(toParent: self)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        // The menu presses the hosted view down with a transform, so it is placed with bounds and center.
        let hostedView: UIView = hostingController.view
        hostedView.bounds = CGRect(origin: .zero, size: view.bounds.size)
        hostedView.center = CGPoint(x: view.bounds.midX, y: view.bounds.midY)
    }

    override func preferredContentSizeDidChange(forChildContentContainer container: any UIContentContainer) {
        super.preferredContentSizeDidChange(forChildContentContainer: container)
        // The content has changed its size by itself, for example after a change of its own state.
        // SwiftUI asks for the size again only after this invalidation.
        view.invalidateIntrinsicContentSize()
    }

    // MARK: - SwiftUI

    func update(
        content: Content,
        environmentValues: EnvironmentValues,
        isPresented: Binding<Bool>?,
        makeConfiguration: @escaping @MainActor () -> ContextMenuConfiguration
    ) {
        hostingController.rootView = ContextMenuHostedContent(content: content, environmentValues: environmentValues)
        self.environmentValues = environmentValues
        self.isPresented = isPresented
        self.makeConfiguration = makeConfiguration
        schedulePresentationUpdateIfNeeded()
    }

    func sizeThatFits(_ proposal: ProposedViewSize) -> CGSize {
        // An infinite dimension asks the hosting controller for the ideal size, as `nil` does in SwiftUI.
        hostingController.sizeThatFits(in: proposal.replacingUnspecifiedDimensions(by: CGSize(
            width: CGFloat.infinity,
            height: CGFloat.infinity
        )))
    }

    /// SwiftUI has removed the view: the menu of a view that is gone closes at once.
    func dismantle() {
        let isPresented = isPresented
        self.isPresented = nil
        interaction.dismissMenu(animated: false)

        guard let isPresented, isPresented.wrappedValue else {
            return
        }
        // The binding may outlive the view, for example if it comes from a model. SwiftUI is in the middle
        // of an update, so it is reset afterwards; otherwise the next view with this binding shows the menu.
        environment.mainQueue.schedule {
            isPresented.wrappedValue = false
        }
    }

    // MARK: - Private

    private func schedulePresentationUpdateIfNeeded() {
        guard
            let isPresented,
            isPresented.wrappedValue != isMenuPresented,
            !isPresentationUpdateScheduled
        else {
            return
        }
        isPresentationUpdateScheduled = true
        // Presenting snapshots the content and writes the binding back: neither may happen during an update.
        environment.mainQueue.schedule { [weak self] in
            self?.updatePresentation()
        }
    }

    private func updatePresentation() {
        isPresentationUpdateScheduled = false
        guard let isPresented, isPresented.wrappedValue != isMenuPresented else {
            return
        }
        guard isPresented.wrappedValue else {
            interaction.dismissMenu(animated: true)
            return
        }
        interaction.presentMenu()
        if !interaction.isActive {
            // The menu is empty, the view is not in a window or the window already shows a menu.
            setPresentedBinding(false)
        }
    }

    private func setPresentedBinding(_ value: Bool) {
        guard let isPresented, isPresented.wrappedValue != value else {
            return
        }
        isPresented.wrappedValue = value
    }
}

// MARK: - ContextMenuInteractionDelegate

@available(iOS 16.0, *)
extension ContextMenuHostingController: ContextMenuInteractionDelegate {
    func contextMenuInteraction(
        _ interaction: ContextMenuInteraction,
        configurationAt location: CGPoint
    ) -> ContextMenuConfiguration? {
        guard var configuration = makeConfiguration?() else {
            return nil
        }
        configuration.environmentValues = environmentValues
        return configuration
    }

    func contextMenuInteractionWillPresent(_ interaction: ContextMenuInteraction) {
        isMenuPresented = true
        setPresentedBinding(true)
    }

    func contextMenuInteractionDidDismiss(_ interaction: ContextMenuInteraction) {
        isMenuPresented = false
        setPresentedBinding(false)
    }
}

// MARK: - Hosted content

/// Root view of a hosting controller: the content with the environment of the place where the modifier is applied.
/// Hosts the content of the modifier and the SwiftUI views of custom items and accessories.
struct ContextMenuHostedContent<Content: View>: View {
    let content: Content
    /// A hosting controller doesn't inherit the environment of the SwiftUI hierarchy around it,
    /// so environment objects, fonts and other values are passed explicitly.
    /// `nil` for a custom item in a menu set up in UIKit: there is no SwiftUI hierarchy around it.
    let environmentValues: EnvironmentValues?

    var body: some View {
        // The branch never changes for a hosting controller, so the content keeps its identity and state.
        if let environmentValues {
            content
                .environment(\.self, environmentValues)
                // The hosted view is exactly as large as the content: the window's safe area doesn't apply to it.
                .ignoresSafeArea()
        } else {
            content
                .ignoresSafeArea()
        }
    }
}
