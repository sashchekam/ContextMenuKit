@testable import ContextMenuKit
import Testing
import UIKit

/// The presenter's side of accessories: they are shown with the menu, close it through their proxy,
/// learn where the preview ends up and stay visible while the content scrolls.
@MainActor
@Suite("Accessories in a presented menu")
struct ContextMenuAccessoryPresentationTests {
    let animator = ViewAnimatorMock()
    let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 390, height: 844))
    let sourceView = UIView(frame: CGRect(x: 16, y: 200, width: 200, height: 80))
    let delegate = ConfigurationDelegateStub()
    let log = ActionLog()
    let interaction: ContextMenuInteraction

    init() {
        interaction = ContextMenuInteraction(
            delegate: delegate,
            environment: .mock(
                animator: animator,
                mainQueue: MainQueueSchedulerMock(),
                registry: ContextMenuPresentationRegistry()
            )
        )
        window.isHidden = false
        window.addSubview(sourceView)
        sourceView.addInteraction(interaction)
    }

    // MARK: - Proxy

    @Test("An accessory closes the menu through its proxy, the handler runs after the dismissal animation")
    func accessoryDismissesMenu() {
        var probeView: ProxyProbeView?
        configure(accessories: [
            ContextMenuAccessory { proxy in
                let view = ProxyProbeView(proxy: proxy)
                probeView = view
                return view
            }
        ])
        presentMenu()

        probeView?.proxy.dismiss(performing: log.handler("Reaction"))
        #expect(log.performed.isEmpty)
        animator.finishAll()

        #expect(log.performed == ["Reaction"])
        #expect(!interaction.isActive)
    }

    // MARK: - Empty menu

    @Test("Accessories are shown without menu items")
    func accessoriesWithoutMenuItems() {
        delegate.configuration = ContextMenuConfiguration(
            accessories: [ContextMenuAccessory(size: .fixed(TestData.accessorySize)) { _ in UIView() }]
        )

        presentMenu()

        #expect(interaction.isActive)
        #expect(overlay?.menuView.isHidden == true)
        #expect(overlay?.accessoryViews.count == 1)
    }

    @Test("A configuration without menu items and accessories isn't shown")
    func emptyConfiguration() {
        delegate.configuration = ContextMenuConfiguration(menu: ContextMenu { })

        presentMenu()

        #expect(!interaction.isActive)
        #expect(overlay == nil)
    }

    // MARK: - Lifecycle

    @Test("An accessory view learns where the preview and the menu end up, relative to itself")
    func accessoryViewContext() {
        let accessoryView = LifecycleProbeView()
        configure(accessories: [
            ContextMenuAccessory(placement: .above(.preview), size: .fixed(TestData.accessorySize)) { _ in accessoryView }
        ])

        interaction.presentMenu()

        // The accessory is 8 points above the preview, the menu is 8 points below it.
        #expect(accessoryView.context == ContextMenuAccessoryContext(
            previewFrame: CGRect(x: 0, y: 48, width: 200, height: 80),
            menuFrame: CGRect(x: 0, y: 136, width: 248, height: 48),
            presentationAnimation: ContextMenuAnimationSpec.default.presentation
        ))
    }

    @Test("An accessory view hears about the presentation before it starts")
    func willPresentBeforeAnimation() {
        let accessoryView = LifecycleProbeView()
        configure(accessories: [ContextMenuAccessory { _ in accessoryView }])

        interaction.presentMenu()

        #expect(accessoryView.events == ["willPresent"])
    }

    @Test("An accessory view hears about the end of the presentation and the start of the dismissal")
    func lifecycleEvents() {
        let accessoryView = LifecycleProbeView()
        configure(accessories: [ContextMenuAccessory { _ in accessoryView }])
        presentMenu()

        interaction.dismissMenu()

        #expect(accessoryView.events == ["willPresent", "didPresent", "willDismiss"])
    }

    // MARK: - Touches

    @Test("A tap on an accessory doesn't dismiss the menu, a tap on the preview does")
    func tapOnAccessory() throws {
        let accessoryView = UIView()
        configure(accessories: [ContextMenuAccessory { _ in accessoryView }])
        presentMenu()

        let overlay = try #require(overlay)

        #expect(overlay.isMenuContent(accessoryView))
        #expect(!overlay.isMenuContent(overlay.previewView))
    }

    // MARK: - Scrolling

    @Test("An accessory that stays visible starts at the top of the visible safe area above a tall preview")
    func staysVisibleInitially() throws {
        presentTallPreview(scrollBehavior: .staysVisible)
        let overlay = try #require(overlay)

        let accessoryFrame = try #require(overlay.accessoryViews.first?.frame)

        #expect(overlay.scrollView.contentOffset.y > 0)
        #expect(accessoryFrame.minY == overlay.scrollView.contentOffset.y + window.safeAreaInsets.top)
    }

    @Test("An accessory that stays visible follows the scroll position")
    func staysVisibleWhileScrolling() throws {
        presentTallPreview(scrollBehavior: .staysVisible)
        let overlay = try #require(overlay)

        overlay.scrollView.contentOffset = CGPoint(x: 0, y: TestData.scrollOffset)

        #expect(overlay.accessoryViews.first?.frame.minY == TestData.scrollOffset + window.safeAreaInsets.top)
    }

    @Test("An accessory that scrolls with the content stays at its place above the preview")
    func scrollsWithContent() throws {
        presentTallPreview(scrollBehavior: .scrollsWithContent)
        let overlay = try #require(overlay)

        overlay.scrollView.contentOffset = CGPoint(x: 0, y: TestData.scrollOffset)

        #expect(overlay.accessoryViews.first?.frame.maxY == overlay.previewView.frame.minY - TestData.spacing)
    }

    // MARK: - Helpers

    private var overlay: ContextMenuOverlayView? {
        window.subviews.lazy.compactMap { $0 as? ContextMenuOverlayView }.first
    }

    private func configure(accessories: [ContextMenuAccessory]) {
        delegate.configuration = ContextMenuConfiguration(
            menu: ContextMenu {
                ContextMenuAction(title: "Copy") { }
            },
            accessories: accessories
        )
    }

    private func presentMenu() {
        interaction.presentMenu()
        animator.finishAll()
    }

    private func presentTallPreview(scrollBehavior: ContextMenuAccessory.ScrollBehavior) {
        sourceView.frame = CGRect(x: 16, y: 100, width: 200, height: 1000)
        configure(accessories: [
            ContextMenuAccessory(size: .fixed(TestData.accessorySize), scrollBehavior: scrollBehavior) { _ in UIView() }
        ])
        presentMenu()
    }
}

private extension ContextMenuAccessoryPresentationTests {
    enum TestData {
        static let accessorySize = CGSize(width: 100, height: 40)
        static let spacing: CGFloat = 8
        static let scrollOffset: CGFloat = 100
    }
}

/// An accessory view that records the lifecycle calls it gets.
@MainActor
private final class LifecycleProbeView: UIView, ContextMenuAccessoryView {
    private(set) var events: [String] = []
    private(set) var context: ContextMenuAccessoryContext?

    func contextMenuAccessoryWillPresent(_ context: ContextMenuAccessoryContext) {
        self.context = context
        events.append("willPresent")
    }

    func contextMenuAccessoryDidPresent() {
        events.append("didPresent")
    }

    func contextMenuAccessoryWillDismiss() {
        events.append("willDismiss")
    }
}
