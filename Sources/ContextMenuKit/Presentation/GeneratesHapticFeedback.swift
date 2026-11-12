import UIKit

/// Abstraction over feedback generators, so that tests can check the haptic contract.
@MainActor
protocol GeneratesHapticFeedback {
    /// Wakes the haptic engine up ahead of ``play(_:)``, so that the haptic isn't late.
    func prepare(_ feedback: ContextMenuHapticFeedback)
    func play(_ feedback: ContextMenuHapticFeedback)
}

extension GeneratesHapticFeedback {
    /// Prepares the haptic of the animation spec. `nil` is the haptic turned off: nothing happens.
    func prepareIfNeeded(_ feedback: ContextMenuHapticFeedback?) {
        guard let feedback else {
            return
        }
        prepare(feedback)
    }

    /// Plays the haptic of the animation spec. `nil` is the haptic turned off: nothing happens.
    func playIfNeeded(_ feedback: ContextMenuHapticFeedback?) {
        guard let feedback else {
            return
        }
        play(feedback)
    }
}

/// Plays haptics with UIKit feedback generators. Keeps the generator of the last haptic,
/// so that the generator that was prepared is the one that plays.
@MainActor
final class UIKitHapticFeedback: GeneratesHapticFeedback {
    private struct Player {
        let feedback: ContextMenuHapticFeedback
        let generator: UIFeedbackGenerator
        let play: @MainActor () -> Void
    }

    private var player: Player?

    func prepare(_ feedback: ContextMenuHapticFeedback) {
        player(for: feedback).generator.prepare()
    }

    func play(_ feedback: ContextMenuHapticFeedback) {
        player(for: feedback).play()
    }

    private func player(for feedback: ContextMenuHapticFeedback) -> Player {
        if let player, player.feedback == feedback {
            return player
        }
        let player = switch feedback.kind {
        case let .impact(style, intensity):
            Self.impactPlayer(for: feedback, style: style, intensity: intensity)
        case .selection:
            Self.selectionPlayer(for: feedback)
        }
        self.player = player
        return player
    }

    private static func impactPlayer(
        for feedback: ContextMenuHapticFeedback,
        style: UIImpactFeedbackGenerator.FeedbackStyle,
        intensity: CGFloat
    ) -> Player {
        let generator = UIImpactFeedbackGenerator(style: style)
        return Player(feedback: feedback, generator: generator) {
            generator.impactOccurred(intensity: intensity)
        }
    }

    private static func selectionPlayer(for feedback: ContextMenuHapticFeedback) -> Player {
        let generator = UISelectionFeedbackGenerator()
        return Player(feedback: feedback, generator: generator) {
            generator.selectionChanged()
        }
    }
}
