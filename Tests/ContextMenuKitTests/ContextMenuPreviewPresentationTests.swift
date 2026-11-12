@testable import ContextMenuKit
import SwiftUI
import Testing
import UIKit

/// The preview: a snapshot that a tap goes through, or a live view of the configuration that gets touches,
/// sits right over the source view and gives up the first responder when the dismissal starts.
@MainActor
@Suite("Preview of a presented menu")
struct ContextMenuPreviewPresentationTests {
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

    // MARK: - Snapshot

    @Test("A snapshot preview doesn't get touches: a tap on it dismisses the menu")
    func tapOnSnapshot() throws {
        configure(preview: .snapshot)
        presentMenu()
        let overlay = try #require(overlay)

        let touchedView = try #require(overlay.hitTest(previewCenter(in: overlay), with: nil))

        #expect(!overlay.isMenuContent(touchedView))
    }

    // MARK: - View

    @Test("A preview view is used instead of a snapshot and is as large as the source view")
    func previewView() throws {
        let previewView = UIView()
        configure(preview: .view { _ in previewView })
        presentMenu()
        let overlay = try #require(overlay)

        #expect(overlay.previewView.contentView === previewView)
        #expect(previewView.bounds.size == sourceView.bounds.size)
        #expect(overlay.previewView.frame.size == sourceView.bounds.size)
    }

    @Test("A preview view gets touches: a tap on it doesn't dismiss the menu")
    func tapOnPreviewView() throws {
        let previewView = UIView()
        configure(preview: .view { _ in previewView })
        presentMenu()
        let overlay = try #require(overlay)

        let touchedView = try #require(overlay.hitTest(previewCenter(in: overlay), with: nil))

        #expect(touchedView === previewView)
        #expect(overlay.isMenuContent(touchedView))
    }

    @Test("A preview view without user interaction lets the tap through to the backdrop")
    func decorativePreviewView() throws {
        let previewView = UIView()
        previewView.isUserInteractionEnabled = false
        configure(preview: .view { _ in previewView })
        presentMenu()
        let overlay = try #require(overlay)

        let touchedView = try #require(overlay.hitTest(previewCenter(in: overlay), with: nil))

        #expect(!overlay.isMenuContent(touchedView))
    }

    @Test("A preview view keeps its own transform and alpha while the menu moves the preview")
    func previewViewKeepsTransform() throws {
        let previewView = UIView()
        previewView.transform = TestData.ownTransform
        previewView.alpha = TestData.ownAlpha
        configure(preview: .view { _ in previewView })
        presentMenu()

        interaction.dismissMenu()
        animator.finishAll()

        #expect(previewView.transform == TestData.ownTransform)
        #expect(previewView.alpha == TestData.ownAlpha)
    }

    @Test("A preview view closes the menu through its proxy, the handler runs after the dismissal animation")
    func previewViewDismissesMenu() {
        var probeView: ProxyProbeView?
        configure(preview: .view { proxy in
            let view = ProxyProbeView(proxy: proxy)
            probeView = view
            return view
        })
        presentMenu()

        probeView?.proxy.dismiss(performing: log.handler("Open"))
        #expect(log.performed.isEmpty)
        animator.finishAll()

        #expect(log.performed == ["Open"])
        #expect(!interaction.isActive)
    }

    @Test("A preview view gives up the first responder when the dismissal starts")
    func previewViewResignsFirstResponder() throws {
        let previewView = FirstResponderProbeView()
        configure(preview: .view { _ in previewView })
        presentMenu()
        try #require(previewView.becomeFirstResponder())

        interaction.dismissMenu()

        #expect(animator.hasPendingAnimations)
        #expect(!previewView.isFirstResponder)
    }

    @Test("A SwiftUI preview is as large as the source view")
    func swiftUIPreview() throws {
        configure(preview: .view { _ in Color.red })
        presentMenu()
        let overlay = try #require(overlay)

        #expect(overlay.previewView.contentView.bounds.size == sourceView.bounds.size)
    }

    // MARK: - Helpers

    private var overlay: ContextMenuOverlayView? {
        window.subviews.lazy.compactMap { $0 as? ContextMenuOverlayView }.first
    }

    private func configure(preview: ContextMenuPreview) {
        delegate.configuration = ContextMenuConfiguration(
            menu: ContextMenu {
                ContextMenuAction(title: "Copy") { }
            },
            preview: preview
        )
    }

    private func presentMenu() {
        interaction.presentMenu()
        animator.finishAll()
    }

    private func previewCenter(in overlay: ContextMenuOverlayView) -> CGPoint {
        let previewBounds = overlay.previewView.bounds
        return overlay.previewView.convert(CGPoint(x: previewBounds.midX, y: previewBounds.midY), to: overlay)
    }
}

private extension ContextMenuPreviewPresentationTests {
    enum TestData {
        static let ownTransform = CGAffineTransform(rotationAngle: 0.1)
        static let ownAlpha: CGFloat = 0.5
    }
}

/// A preview view that can become the first responder, like a text view with a selection.
@MainActor
private final class FirstResponderProbeView: UIView {
    override var canBecomeFirstResponder: Bool {
        true
    }
}
