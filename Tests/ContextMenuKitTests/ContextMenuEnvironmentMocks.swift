@testable import ContextMenuKit
import UIKit

/// Keeps animations instead of running them: tests run the blocks manually.
@MainActor
final class ViewAnimatorMock: AnimatesViews {
    private struct PendingAnimation {
        let animations: @MainActor () -> Void
        let completion: (@MainActor (Bool) -> Void)?
    }

    private var pendingAnimations: [PendingAnimation] = []

    var hasPendingAnimations: Bool {
        !pendingAnimations.isEmpty
    }

    func animate(
        _ animation: ViewAnimation,
        animations: @escaping @MainActor () -> Void,
        completion: (@MainActor (Bool) -> Void)?
    ) {
        pendingAnimations.append(PendingAnimation(animations: animations, completion: completion))
    }

    /// Finishes the pending animations, including the ones started by their completions.
    func finishAll() {
        while !pendingAnimations.isEmpty {
            let animation = pendingAnimations.removeFirst()
            animation.animations()
            animation.completion?(true)
        }
    }
}

/// Records the haptics instead of playing them.
@MainActor
final class HapticFeedbackMock: GeneratesHapticFeedback {
    enum Event: Equatable {
        case prepare(ContextMenuHapticFeedback)
        case play(ContextMenuHapticFeedback)
    }

    private(set) var events: [Event] = []

    func prepare(_ feedback: ContextMenuHapticFeedback) {
        events.append(.prepare(feedback))
    }

    func play(_ feedback: ContextMenuHapticFeedback) {
        events.append(.play(feedback))
    }
}

/// Keeps deferred work instead of running it: tests run it manually.
@MainActor
final class MainQueueSchedulerMock: SchedulesMainQueueWork {
    private var pendingWork: [@MainActor () -> Void] = []

    var pendingWorkCount: Int {
        pendingWork.count
    }

    func schedule(_ work: @escaping @MainActor () -> Void) {
        pendingWork.append(work)
    }

    func runAll() {
        while !pendingWork.isEmpty {
            pendingWork.removeFirst()()
        }
    }
}

extension ContextMenuEnvironment {
    static func mock(
        animator: ViewAnimatorMock,
        mainQueue: MainQueueSchedulerMock,
        registry: ContextMenuPresentationRegistry,
        hapticFeedback: HapticFeedbackMock = HapticFeedbackMock()
    ) -> ContextMenuEnvironment {
        ContextMenuEnvironment(
            animator: animator,
            hapticFeedback: hapticFeedback,
            registry: registry,
            notificationCenter: NotificationCenter(),
            mainQueue: mainQueue
        )
    }
}
