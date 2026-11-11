import UIKit

@MainActor
protocol ContextMenuPresenterDelegate: AnyObject {
    func presenterWillPresent(_ presenter: ContextMenuPresenter)
    func presenterDidPresent(_ presenter: ContextMenuPresenter)
    func presenterWillDismiss(_ presenter: ContextMenuPresenter)
    func presenterDidDismiss(_ presenter: ContextMenuPresenter)
    /// The session is over: the presenter can be released.
    func presenterDidFinish(_ presenter: ContextMenuPresenter)
}

/// Drives one menu session: press, presentation, dismissal and the selected action.
///
/// The preview is a snapshot of the source view; the source view stays in place, invisible,
/// until the preview lands back on it. Accessories move with the preview and the menu. Every command goes through the state machine,
/// so repeated taps and stale animation completions are ignored.
@MainActor
final class ContextMenuPresenter: NSObject {
    weak var delegate: ContextMenuPresenterDelegate?

    var state: ContextMenuState {
        stateMachine.state
    }

    private let sourceView: UIView
    private let window: UIWindow
    private let configuration: ContextMenuConfiguration
    private let environment: ContextMenuEnvironment
    private let transitionAnimator: ContextMenuTransitionAnimator
    private let sourceViewState: SourceViewState
    /// Frame of the source view in window coordinates before it was pressed down.
    private let initialSourceFrame: CGRect
    private let menuEdge: ContextMenuHorizontalEdge
    private let accessoryResolver: ContextMenuAccessoryResolver
    private var stateMachine = ContextMenuStateMachine()
    private var overlay: ContextMenuOverlayView?
    private var menuSize: CGSize = .zero
    private var accessoryInputs: [ContextMenuAccessoryLayoutInput] = []
    private var layout: ContextMenuLayout?
    /// The handler of the selected action or custom item: runs once the dismissal animation is over.
    private var pendingHandler: ContextMenuAction.Handler?
    private var isFinished = false

    init(
        sourceView: UIView,
        window: UIWindow,
        configuration: ContextMenuConfiguration,
        environment: ContextMenuEnvironment
    ) {
        self.sourceView = sourceView
        self.window = window
        self.configuration = configuration
        self.environment = environment
        transitionAnimator = ContextMenuTransitionAnimator(
            animator: environment.animator,
            spec: configuration.animationSpec
        )
        sourceViewState = SourceViewState(view: sourceView)
        initialSourceFrame = sourceView.convert(sourceView.bounds, to: window)
        let layoutDirection = sourceView.effectiveUserInterfaceLayoutDirection
        menuEdge = ContextMenuLayoutCalculator.menuEdge(
            for: configuration.alignment,
            sourceFrame: initialSourceFrame,
            containerWidth: window.bounds.width,
            layoutDirection: layoutDirection
        )
        accessoryResolver = ContextMenuAccessoryResolver(
            menuEdge: menuEdge,
            layoutDirection: layoutDirection,
            defaultSpacing: configuration.style.layout.accessorySpacing,
            defaultCollapsedScale: configuration.animationSpec.collapsedAccessoryScale
        )
        super.init()
    }

    // MARK: - Commands

    /// Starts the session.
    /// - Parameter pressesDown: `true` for a long press: the source view is pressed down first.
    ///   `false` for a programmatic presentation.
    func start(pressesDown: Bool) {
        guard environment.registry.register(self, in: window) else {
            finish()
            return
        }
        environment.notificationCenter.addObserver(
            self,
            selector: #selector(sceneDidEnterBackground),
            name: UIScene.didEnterBackgroundNotification,
            object: window.windowScene
        )
        environment.hapticFeedback.prepare()

        guard pressesDown else {
            present(previewScale: 1)
            return
        }
        stateMachine.handle(.pressBegan)
        transitionAnimator.animatePressDown(of: sourceView, from: sourceViewState.transform) { [weak self] _ in
            self?.pressDownDidFinish()
        }
    }

    /// Dismisses the menu or cancels the press. Ignored while the menu is already being dismissed.
    func dismiss(animated: Bool) {
        switch stateMachine.state {
        case .idle, .dismissing:
            break
        case .pressing:
            cancelPress(animated: animated)
        case .presenting, .presented:
            beginDismissal(animated: animated)
        }
    }

    // MARK: - Press

    private func pressDownDidFinish() {
        guard stateMachine.state == .pressing else {
            return
        }
        present(previewScale: configuration.animationSpec.pressDownScale)
    }

    private func cancelPress(animated: Bool) {
        let wasPressing = stateMachine.handle(.pressCancelled)
        guard wasPressing, animated else {
            sourceViewState.restore(on: sourceView)
            finish()
            return
        }
        transitionAnimator.animatePressRelease(of: sourceView, to: sourceViewState.transform) { [weak self] _ in
            guard let self else {
                return
            }
            sourceViewState.restore(on: sourceView)
            finish()
        }
    }

    // MARK: - Presentation

    private func present(previewScale: CGFloat) {
        guard let previewView = sourceView.snapshotView(afterScreenUpdates: true) else {
            cancelPress(animated: true)
            return
        }
        stateMachine.handle(.presentationBegan)
        delegate?.presenterWillPresent(self)

        let overlay = makeOverlay(previewView: previewView)
        window.addSubview(overlay)
        overlay.layoutIfNeeded()
        self.overlay = overlay
        measureContent(of: overlay)

        sourceView.alpha = 0
        sourceView.transform = sourceViewState.transform

        let layout = ContextMenuLayoutCalculator.layout(for: layoutInput(sourceFrame: initialSourceFrame))
        self.layout = layout
        overlay.setContent(size: layout.contentSize, offset: layout.contentOffset)
        let presentedFrames = presentedFrames(in: overlay, layout: layout)
        transitionAnimator.prepareForPresentation(
            of: overlay,
            frames: collapsedFrames(for: initialSourceFrame, in: overlay),
            previewScale: previewScale,
            menuAnchorPoint: ContextMenuLayoutCalculator.menuAnchorPoint(for: menuEdge)
        )
        for (accessoryView, frame) in zip(overlay.accessoryViews, presentedFrames.accessories) {
            accessoryView.willPresent(
                at: frame,
                previewFrame: presentedFrames.preview,
                menuFrame: presentedFrames.menu,
                animation: configuration.animationSpec.presentation
            )
        }

        environment.hapticFeedback.impactOccurred()
        transitionAnimator.animatePresentation(
            of: overlay,
            frames: presentedFrames,
            blurStyle: configuration.style.background.blurStyle
        ) { [weak self] _ in
            self?.presentationDidFinish()
        }
    }

    private func presentationDidFinish() {
        guard stateMachine.handle(.presentationFinished) else {
            return
        }
        // The content may have scrolled during the presentation.
        keepAccessoriesVisible()
        overlay?.accessoryViews.forEach { $0.didPresent() }
        delegate?.presenterDidPresent(self)
    }

    private func makeOverlay(previewView: UIView) -> ContextMenuOverlayView {
        let proxy = ContextMenuProxy(environmentValues: configuration.environmentValues) { [weak self] handler in
            self?.dismiss(performing: handler)
        }
        let menuView = ContextMenuListView(menu: configuration.menu, style: configuration.style, proxy: proxy)
        // A menu without items still anchors the accessories attached to it.
        menuView.isHidden = configuration.menu.isEmpty
        let accessoryViews = configuration.accessories.map { accessory in
            ContextMenuAccessoryContainerView(accessory: accessory, proxy: proxy, resolver: accessoryResolver)
        }

        let overlay = ContextMenuOverlayView(
            frame: window.bounds,
            previewView: previewView,
            menuView: menuView,
            accessoryViews: accessoryViews,
            style: configuration.style.background
        )
        overlay.onDismissRequest = { [weak self] in
            self?.dismiss(animated: true)
        }
        overlay.onSizeChange = { [weak self] in
            self?.dismiss(animated: false)
        }
        overlay.onScroll = { [weak self] in
            self?.keepAccessoriesVisible()
        }
        return overlay
    }

    // MARK: - Dismissal

    /// A selected action or custom item closes the menu; its handler runs after the dismissal animation.
    /// Ignored once the dismissal has begun, so only the first selection counts.
    private func dismiss(performing handler: ContextMenuAction.Handler?) {
        guard stateMachine.state == .presenting || stateMachine.state == .presented else {
            return
        }
        pendingHandler = handler
        beginDismissal(animated: true)
    }

    private func beginDismissal(animated: Bool) {
        guard let overlay, stateMachine.handle(.dismissalBegan) else {
            return
        }
        delegate?.presenterWillDismiss(self)
        overlay.isUserInteractionEnabled = false
        overlay.accessoryViews.forEach { $0.willDismiss() }

        guard animated else {
            completeDismissal(fadesPreview: false)
            return
        }

        overlay.scrollView.stopScrolling()
        let sourceFrame = currentSourceFrame()
        transitionAnimator.animateDismissal(
            of: overlay,
            frames: collapsedFrames(for: sourceFrame, in: overlay),
            visiblePreviewRect: visiblePreviewRect(for: sourceFrame)
        ) { [weak self] _ in
            self?.completeDismissal(fadesPreview: true)
        }
    }

    /// The preview has landed: the source view becomes visible under it.
    private func completeDismissal(fadesPreview: Bool) {
        guard stateMachine.state == .dismissing, let overlay else {
            return
        }
        sourceViewState.restore(on: sourceView)

        guard fadesPreview else {
            finishDismissal()
            return
        }
        transitionAnimator.animatePreviewFadeOut(of: overlay) { [weak self] _ in
            self?.finishDismissal()
        }
    }

    private func finishDismissal() {
        guard stateMachine.handle(.dismissalFinished) else {
            return
        }
        overlay?.removeFromSuperview()
        overlay = nil
        delegate?.presenterDidDismiss(self)

        let handler = pendingHandler
        finish()
        handler?()
    }

    private func finish() {
        guard !isFinished else {
            return
        }
        isFinished = true
        environment.notificationCenter.removeObserver(self)
        environment.registry.unregister(self)
        delegate?.presenterDidFinish(self)
    }

    @objc
    private func sceneDidEnterBackground() {
        dismiss(animated: false)
    }
}

// MARK: - Layout

private extension ContextMenuPresenter {
    /// Measures the menu and the accessories. They are measured in the window, with its traits, such as the text size.
    func measureContent(of overlay: ContextMenuOverlayView) {
        menuSize = overlay.menuView.preferredSize
        let maxAccessoryWidth = window.bounds.inset(by: window.safeAreaInsets).width
            - 2 * configuration.style.layout.screenEdgeInset
        accessoryInputs = overlay.accessoryViews.map { accessoryView in
            accessoryView.layoutInput(previewSize: initialSourceFrame.size, menuSize: menuSize, maxWidth: maxAccessoryWidth)
        }
    }

    /// Moves the accessories that stay visible to the visible part of the scrolled content.
    func keepAccessoriesVisible() {
        guard stateMachine.state == .presented, let overlay, let layout else {
            return
        }
        transitionAnimator.moveAccessories(of: overlay, to: presentedFrames(in: overlay, layout: layout).accessories)
    }

    func layoutInput(sourceFrame: CGRect) -> ContextMenuLayoutInput {
        ContextMenuLayoutInput(
            sourceFrame: sourceFrame,
            containerSize: window.bounds.size,
            safeAreaInsets: window.safeAreaInsets,
            menuSize: menuSize,
            menuEdge: menuEdge,
            // No gap under the preview for a menu without items.
            previewMenuSpacing: configuration.menu.isEmpty ? 0 : configuration.style.layout.previewMenuSpacing,
            screenEdgeInset: configuration.style.layout.screenEdgeInset,
            accessories: accessoryInputs
        )
    }

    /// Frames of the presented state in the content coordinates of the overlay.
    /// Accessories that stay visible follow the current scroll position.
    func presentedFrames(in overlay: ContextMenuOverlayView, layout: ContextMenuLayout) -> ContextMenuOverlayFrames {
        let input = layoutInput(sourceFrame: initialSourceFrame)
        let accessoryFrames = zip(layout.accessoryFrames, accessoryInputs).map { frame, accessory in
            ContextMenuLayoutCalculator.displayedFrame(
                of: frame,
                for: accessory,
                contentOffset: overlay.scrollView.contentOffset,
                input: input
            )
        }
        return ContextMenuOverlayFrames(preview: layout.previewFrame, menu: layout.menuFrame, accessories: accessoryFrames)
    }

    /// Frames of the collapsed state next to the source view at `sourceFrame` (in window coordinates),
    /// converted to the content coordinates of the overlay.
    func collapsedFrames(for sourceFrame: CGRect, in overlay: ContextMenuOverlayView) -> ContextMenuOverlayFrames {
        ContextMenuLayoutCalculator.collapsedFrames(
            sourceFrame: sourceFrame,
            collapsedMenuScale: configuration.animationSpec.collapsedMenuScale,
            input: layoutInput(sourceFrame: sourceFrame)
        ).map { frame in
            window.convert(frame, to: overlay.contentView)
        }
    }

    /// Current frame of the source view in window coordinates; the source view may have moved
    /// while the menu was shown. Falls back to the initial frame if the view has left the window.
    func currentSourceFrame() -> CGRect {
        guard sourceView.window === window else {
            return initialSourceFrame
        }
        return sourceView.convert(sourceView.bounds, to: window)
    }

    func visiblePreviewRect(for sourceFrame: CGRect) -> CGRect? {
        guard case let .rect(visibleRectProvider) = configuration.clipping else {
            return nil
        }
        let visibleRect = visibleRectProvider().intersection(sourceFrame)
        guard !visibleRect.isNull else {
            return .zero
        }
        guard visibleRect != sourceFrame else {
            return nil
        }
        return visibleRect.offsetBy(dx: -sourceFrame.minX, dy: -sourceFrame.minY)
    }
}
