import UIKit

/// A haptic the menu plays when the preview starts to lift, see ``ContextMenuAnimationSpec/hapticFeedback``.
///
/// ```swift
/// var animationSpec = ContextMenuAnimationSpec()
/// animationSpec.hapticFeedback = .impact(.soft, intensity: 0.7)
/// // No haptic at all:
/// animationSpec.hapticFeedback = nil
/// ```
public struct ContextMenuHapticFeedback: Equatable, Sendable {
    enum Kind: Equatable, Sendable {
        case impact(UIImpactFeedbackGenerator.FeedbackStyle, intensity: CGFloat)
        case selection
    }

    let kind: Kind

    /// A physical impact, see `UIImpactFeedbackGenerator`.
    /// - Parameters:
    ///   - style: The mass of the colliding objects, from `.light` to `.heavy`; `.soft` and `.rigid` set
    ///     their flexibility.
    ///   - intensity: Strength of the impact, from `0` to `1`.
    public static func impact(
        _ style: UIImpactFeedbackGenerator.FeedbackStyle,
        intensity: CGFloat = 1
    ) -> ContextMenuHapticFeedback {
        ContextMenuHapticFeedback(kind: .impact(style, intensity: min(max(intensity, 0), 1)))
    }

    /// A light tick, the one of a changed selection, see `UISelectionFeedbackGenerator`.
    public static var selection: ContextMenuHapticFeedback {
        ContextMenuHapticFeedback(kind: .selection)
    }
}
