import UIKit

/// ``ContextMenuAccessory/Transition`` with the defaults and the horizontal reference applied.
struct ContextMenuResolvedTransition: Equatable {
    var collapsedScale: CGFloat
    var collapsedAlpha: CGFloat
    /// Physical anchor point: x is measured from the left edge.
    var anchorPoint: CGPoint
    /// Physical shift of the collapsed accessory: `dx` points right.
    var collapsedOffset: CGVector

    var collapsedTransform: CGAffineTransform {
        CGAffineTransform(scaleX: collapsedScale, y: collapsedScale)
    }
}

/// Turns the placement and the transition of an accessory into physical values for one menu session:
/// applies the horizontal reference, the default spacing and the default scale.
struct ContextMenuAccessoryResolver: Equatable {
    var menuEdge: ContextMenuHorizontalEdge
    var layoutDirection: UIUserInterfaceLayoutDirection
    var defaultSpacing: CGFloat
    var defaultCollapsedScale: CGFloat

    func placement(_ placement: ContextMenuAccessory.Placement) -> ContextMenuResolvedPlacement {
        let isMirrored = isMirrored(placement.horizontalReference)
        let targetAnchor = mirrored(placement.targetAnchor, if: isMirrored)
        let accessoryAnchor = mirrored(placement.accessoryAnchor, if: isMirrored)
        let spacing = placement.spacing ?? defaultSpacing
        let offset = mirrored(placement.offset, if: isMirrored)

        return ContextMenuResolvedPlacement(
            target: placement.target,
            targetAnchor: targetAnchor,
            accessoryAnchor: accessoryAnchor,
            offset: CGVector(
                dx: offset.dx + Self.gap(targetAnchor: targetAnchor.x, accessoryAnchor: accessoryAnchor.x, spacing: spacing),
                dy: offset.dy + Self.gap(targetAnchor: targetAnchor.y, accessoryAnchor: accessoryAnchor.y, spacing: spacing)
            )
        )
    }

    func transition(
        _ transition: ContextMenuAccessory.Transition,
        placement: ContextMenuAccessory.Placement
    ) -> ContextMenuResolvedTransition {
        let isMirrored = isMirrored(placement.horizontalReference)
        return ContextMenuResolvedTransition(
            collapsedScale: transition.collapsedScale ?? defaultCollapsedScale,
            collapsedAlpha: transition.collapsedAlpha,
            anchorPoint: mirrored(transition.anchorPoint ?? placement.accessoryAnchor, if: isMirrored),
            collapsedOffset: mirrored(transition.collapsedOffset, if: isMirrored)
        )
    }

    // MARK: - Private

    /// The spacing applies along an axis only where the accessory lies outside of the target:
    /// one anchor is at the near edge and the other at the far one.
    private static func gap(targetAnchor: CGFloat, accessoryAnchor: CGFloat, spacing: CGFloat) -> CGFloat {
        if targetAnchor == 0, accessoryAnchor == 1 {
            return -spacing
        }
        if targetAnchor == 1, accessoryAnchor == 0 {
            return spacing
        }
        return 0
    }

    /// `true` when x = 0 of the reference is the right edge.
    private func isMirrored(_ reference: ContextMenuAccessory.Placement.HorizontalReference) -> Bool {
        switch reference {
        case .layoutDirection:
            layoutDirection == .rightToLeft
        case .menuEdge:
            menuEdge == .right
        }
    }

    private func mirrored(_ point: CGPoint, if isMirrored: Bool) -> CGPoint {
        isMirrored ? CGPoint(x: 1 - point.x, y: point.y) : point
    }

    private func mirrored(_ vector: CGVector, if isMirrored: Bool) -> CGVector {
        isMirrored ? CGVector(dx: -vector.dx, dy: vector.dy) : vector
    }
}
