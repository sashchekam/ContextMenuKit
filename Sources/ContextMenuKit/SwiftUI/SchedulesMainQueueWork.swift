import Foundation

/// Runs work on the main queue after the current pass of the run loop, so that tests can run it manually.
///
/// The SwiftUI modifier learns about changes of its binding inside a SwiftUI update, where it can neither
/// snapshot the content nor write the binding back. It defers that work with this scheduler.
@MainActor
protocol SchedulesMainQueueWork {
    func schedule(_ work: @escaping @MainActor () -> Void)
}

struct MainQueueScheduler: SchedulesMainQueueWork {
    func schedule(_ work: @escaping @MainActor () -> Void) {
        DispatchQueue.main.async {
            work()
        }
    }
}
