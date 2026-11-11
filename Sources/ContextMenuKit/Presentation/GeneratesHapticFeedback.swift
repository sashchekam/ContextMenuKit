import UIKit

/// Abstraction over a feedback generator, so that tests can check the haptic contract.
@MainActor
protocol GeneratesHapticFeedback {
    func prepare()
    func impactOccurred()
}

@MainActor
final class ImpactHapticFeedback: GeneratesHapticFeedback {
    private let generator = UIImpactFeedbackGenerator(style: .rigid)

    func prepare() {
        generator.prepare()
    }

    func impactOccurred() {
        generator.impactOccurred()
    }
}
