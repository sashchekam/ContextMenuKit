@testable import ContextMenuKit
import Testing
import UIKit

/// The haptic of the animation spec: prepared when the session starts, played once when the preview lifts,
/// and nothing at all when it is turned off.
@MainActor
@Suite("Haptic feedback")
struct ContextMenuHapticFeedbackTests {
    let animator = ViewAnimatorMock()
    let hapticFeedback = HapticFeedbackMock()
    let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 390, height: 844))
    let sourceView = UIView(frame: CGRect(x: 16, y: 200, width: 200, height: 80))
    let delegate = ConfigurationDelegateStub()
    let interaction: ContextMenuInteraction

    init() {
        interaction = ContextMenuInteraction(
            delegate: delegate,
            environment: .mock(
                animator: animator,
                mainQueue: MainQueueSchedulerMock(),
                registry: ContextMenuPresentationRegistry(),
                hapticFeedback: hapticFeedback
            )
        )
        window.isHidden = false
        window.addSubview(sourceView)
        sourceView.addInteraction(interaction)
    }

    @Test("By default the menu prepares a rigid impact and plays it once, when the preview lifts")
    func defaultHaptic() {
        configure(hapticFeedback: ContextMenuAnimationSpec.default.hapticFeedback)

        interaction.presentMenu()

        #expect(animator.hasPendingAnimations)
        #expect(hapticFeedback.events == [.prepare(.impact(.rigid)), .play(.impact(.rigid))])
    }

    @Test("The dismissal doesn't play a haptic")
    func noHapticOnDismissal() {
        configure(hapticFeedback: .impact(.rigid))
        interaction.presentMenu()
        animator.finishAll()

        interaction.dismissMenu()
        animator.finishAll()

        #expect(hapticFeedback.events == [.prepare(.impact(.rigid)), .play(.impact(.rigid))])
    }

    @Test(
        "The menu plays the haptic of its animation spec",
        arguments: [
            ContextMenuHapticFeedback.impact(.soft, intensity: 0.5),
            .impact(.heavy),
            .selection
        ]
    )
    func customHaptic(feedback: ContextMenuHapticFeedback) {
        configure(hapticFeedback: feedback)

        interaction.presentMenu()

        #expect(hapticFeedback.events == [.prepare(feedback), .play(feedback)])
    }

    @Test("Without a haptic in the animation spec the menu neither prepares nor plays one")
    func hapticTurnedOff() {
        configure(hapticFeedback: nil)

        interaction.presentMenu()
        animator.finishAll()

        #expect(interaction.isActive)
        #expect(hapticFeedback.events.isEmpty)
    }

    @Test("The intensity of an impact stays within 0...1")
    func intensityIsClamped() {
        #expect(ContextMenuHapticFeedback.impact(.light, intensity: 2) == .impact(.light, intensity: 1))
        #expect(ContextMenuHapticFeedback.impact(.light, intensity: -1) == .impact(.light, intensity: 0))
    }

    // MARK: - Helpers

    private func configure(hapticFeedback: ContextMenuHapticFeedback?) {
        var animationSpec = ContextMenuAnimationSpec()
        animationSpec.hapticFeedback = hapticFeedback
        delegate.configuration = ContextMenuConfiguration(
            menu: ContextMenu {
                ContextMenuAction(title: "Copy") { }
            },
            animationSpec: animationSpec
        )
    }
}
