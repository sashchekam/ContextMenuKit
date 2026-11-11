import UIKit

/// Parameters of a single `UIView` animation.
struct ViewAnimation: Equatable {
    struct Spring: Equatable {
        var dampingRatio: CGFloat
        var initialVelocity: CGFloat
    }

    var duration: TimeInterval
    var delay: TimeInterval = 0
    var options: UIView.AnimationOptions = []
    /// `nil` animates with the curve from `options`.
    var spring: Spring?
}

/// Abstraction over `UIView.animate`, so that tests can run animation blocks manually.
@MainActor
protocol AnimatesViews {
    func animate(
        _ animation: ViewAnimation,
        animations: @escaping @MainActor () -> Void,
        completion: (@MainActor (Bool) -> Void)?
    )
}

struct UIKitViewAnimator: AnimatesViews {
    func animate(
        _ animation: ViewAnimation,
        animations: @escaping @MainActor () -> Void,
        completion: (@MainActor (Bool) -> Void)?
    ) {
        guard let spring = animation.spring else {
            UIView.animate(
                withDuration: animation.duration,
                delay: animation.delay,
                options: animation.options,
                animations: { animations() },
                completion: { completion?($0) }
            )
            return
        }
        UIView.animate(
            withDuration: animation.duration,
            delay: animation.delay,
            usingSpringWithDamping: spring.dampingRatio,
            initialSpringVelocity: spring.initialVelocity,
            options: animation.options,
            animations: { animations() },
            completion: { completion?($0) }
        )
    }
}
