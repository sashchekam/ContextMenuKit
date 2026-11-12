import Foundation

/// Dependencies of the menu machinery. Tests replace them with mocks.
@MainActor
struct ContextMenuEnvironment {
    static var live: ContextMenuEnvironment {
        ContextMenuEnvironment(
            animator: UIKitViewAnimator(),
            hapticFeedback: UIKitHapticFeedback(),
            registry: .shared,
            notificationCenter: .default,
            mainQueue: MainQueueScheduler()
        )
    }

    var animator: any AnimatesViews
    var hapticFeedback: any GeneratesHapticFeedback
    var registry: ContextMenuPresentationRegistry
    var notificationCenter: NotificationCenter
    /// Defers the reaction of the SwiftUI modifier to its binding.
    var mainQueue: any SchedulesMainQueueWork
}
