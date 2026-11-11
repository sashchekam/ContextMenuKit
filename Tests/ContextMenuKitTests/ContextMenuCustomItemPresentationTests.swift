@testable import ContextMenuKit
import Testing
import UIKit

/// The presenter's side of custom items: a view closes the menu through its proxy,
/// and the handler waits for the dismissal animation, as for a selected action.
@MainActor
@Suite("Custom items in a presented menu")
struct ContextMenuCustomItemPresentationTests {
    let animator = ViewAnimatorMock()
    let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 390, height: 844))
    let sourceView = UIView(frame: CGRect(x: 16, y: 200, width: 200, height: 80))
    let delegate: ConfigurationDelegateStub
    let log = ActionLog()
    let interaction: ContextMenuInteraction

    init() {
        let delegate = ConfigurationDelegateStub()
        delegate.configuration = ContextMenuConfiguration(menu: ContextMenu {
            ContextMenuCustomItem { [weak delegate] proxy in
                let view = ProxyProbeView(proxy: proxy)
                delegate?.probeView = view
                return view
            }
        })
        self.delegate = delegate
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

    @Test("A dismissal from a custom item waits for the animation before the handler runs")
    func handlerWaitsForAnimation() {
        presentMenu()

        delegate.probeView?.proxy.dismiss(performing: log.handler("Reaction"))

        #expect(log.performed.isEmpty)
        #expect(interaction.isActive)
    }

    @Test("A dismissal from a custom item runs the handler once the menu is gone")
    func handlerRunsAfterDismissal() {
        presentMenu()
        delegate.probeView?.proxy.dismiss(performing: log.handler("Reaction"))

        animator.finishAll()

        #expect(log.performed == ["Reaction"])
        #expect(!interaction.isActive)
    }

    @Test("A dismissal without a handler closes the menu")
    func dismissalWithoutHandler() {
        presentMenu()
        delegate.probeView?.proxy.dismiss()

        animator.finishAll()

        #expect(!interaction.isActive)
    }

    @Test("A custom item can close the menu while it is still appearing")
    func dismissalDuringPresentation() {
        interaction.presentMenu()
        delegate.probeView?.proxy.dismiss(performing: log.handler("Reaction"))

        animator.finishAll()

        #expect(log.performed == ["Reaction"])
    }

    @Test("Only the first dismissal counts")
    func repeatedDismissal() {
        presentMenu()
        delegate.probeView?.proxy.dismiss(performing: log.handler("First"))
        delegate.probeView?.proxy.dismiss(performing: log.handler("Second"))

        animator.finishAll()

        #expect(log.performed == ["First"])
    }

    @Test("A dismissal after the menu is gone is ignored")
    func dismissalAfterSession() {
        presentMenu()
        delegate.probeView?.proxy.dismiss(performing: log.handler("First"))
        animator.finishAll()

        delegate.probeView?.proxy.dismiss(performing: log.handler("Late"))
        animator.finishAll()

        #expect(log.performed == ["First"])
    }

    // MARK: - Helpers

    private func presentMenu() {
        interaction.presentMenu()
        animator.finishAll()
    }
}

/// Returns a fixed configuration and keeps the view of its custom item.
@MainActor
final class ConfigurationDelegateStub: ContextMenuInteractionDelegate {
    var configuration: ContextMenuConfiguration?
    var probeView: ProxyProbeView?

    func contextMenuInteraction(
        _ interaction: ContextMenuInteraction,
        configurationAt location: CGPoint
    ) -> ContextMenuConfiguration? {
        configuration
    }
}
