import CoreGraphics

public extension ContextMenuAccessory {
    /// Where an accessory is attached: a point of the accessory is pinned to a point of its target.
    ///
    /// The factories cover the common cases:
    ///
    /// ```swift
    /// .above(.preview)                                   // reactions above a message
    /// .below(.menu, alignment: .center)                  // a hint below the menu
    /// .beside(.preview, side: .oppositeMenuEdge)         // a time label next to a message
    /// .overlay(.preview, horizontalAlignment: .trailing,
    ///          verticalAlignment: .top)                  // a badge in the corner of the preview
    /// ```
    ///
    /// Any other relation is set with anchors in unit coordinates, the way `CALayer.anchorPoint` is:
    /// `(0, 0)` is the top corner at x = 0, `(1, 1)` is the bottom corner at x = 1. Which edge is x = 0 depends
    /// on ``horizontalReference``. This accessory hangs from the bottom of the menu by its center:
    ///
    /// ```swift
    /// ContextMenuAccessory.Placement(
    ///     target: .menu,
    ///     targetAnchor: CGPoint(x: 0.5, y: 1),
    ///     accessoryAnchor: CGPoint(x: 0.5, y: 0.5)
    /// )
    /// ```
    struct Placement: Equatable, Sendable {
        /// The element the accessory is attached to.
        public var target: Target
        /// The point of the target the accessory is attached to, in unit coordinates of the target.
        public var targetAnchor: CGPoint
        /// The point of the accessory that is placed at ``targetAnchor``, in unit coordinates of the accessory.
        public var accessoryAnchor: CGPoint
        /// Which edge is x = 0 for both anchors.
        public var horizontalReference: HorizontalReference
        /// Gap between the accessory and the target along the axes where the accessory lies outside of the target,
        /// that is, where one anchor is at 0 and the other at 1. A negative value makes them overlap.
        /// `nil` takes ``ContextMenuStyle/Layout/accessorySpacing``.
        public var spacing: CGFloat?
        /// Extra shift: `dx` towards x = 1 of ``horizontalReference``, `dy` down.
        public var offset: CGVector

        /// Creates a placement from anchors.
        /// - Parameters:
        ///   - target: The element the accessory is attached to.
        ///   - targetAnchor: The point of the target, in its unit coordinates.
        ///   - accessoryAnchor: The point of the accessory placed at `targetAnchor`, in its unit coordinates.
        ///   - horizontalReference: Which edge is x = 0 for both anchors.
        ///   - spacing: Gap along the axes where the accessory lies outside of the target, `nil` takes the style's.
        ///   - offset: Extra shift.
        public init(
            target: Target,
            targetAnchor: CGPoint,
            accessoryAnchor: CGPoint,
            horizontalReference: HorizontalReference = .menuEdge,
            spacing: CGFloat? = nil,
            offset: CGVector = .zero
        ) {
            self.target = target
            self.targetAnchor = targetAnchor
            self.accessoryAnchor = accessoryAnchor
            self.horizontalReference = horizontalReference
            self.spacing = spacing
            self.offset = offset
        }
    }
}

public extension ContextMenuAccessory.Placement {
    /// The element an accessory is attached to.
    enum Target: Equatable, Sendable {
        /// The preview of the source view.
        case preview
        /// The menu.
        case menu
    }

    /// Which edge is x = 0 for the anchors and where `dx` of the offsets points.
    enum HorizontalReference: Equatable, Sendable {
        /// x = 0 is the leading edge, x = 1 is the trailing one: the placement mirrors
        /// in right-to-left languages.
        case layoutDirection
        /// x = 0 is the edge of the preview the menu is aligned with, x = 1 is the opposite one:
        /// the placement follows the menu, including ``ContextMenuAlignment/automatic``.
        /// In a chat, an accessory of an outgoing message goes to the right, of an incoming one — to the left.
        case menuEdge
    }
}

// MARK: - Factories

public extension ContextMenuAccessory.Placement {
    /// Horizontal alignment of an accessory above, below or over its target.
    enum HorizontalAlignment: Equatable, Sendable {
        case leading
        case center
        case trailing
        /// The edge of the preview the menu is aligned with.
        case menuEdge
    }

    /// Vertical alignment of an accessory beside or over its target.
    enum VerticalAlignment: Equatable, Sendable {
        case top
        case center
        case bottom
    }

    /// The side of the target an accessory is placed at.
    enum Side: Equatable, Sendable {
        case leading
        case trailing
        /// The side of the preview the menu is aligned with.
        case menuEdge
        /// The side opposite to the one the menu is aligned with: towards the middle of the screen in a chat.
        case oppositeMenuEdge
    }

    /// Above the target: reactions above a message.
    /// - Parameters:
    ///   - target: The element the accessory is attached to.
    ///   - alignment: Which edges of the accessory and the target line up.
    ///   - spacing: Gap between the accessory and the target, `nil` takes the style's.
    static func above(
        _ target: Target,
        alignment: HorizontalAlignment = .menuEdge,
        spacing: CGFloat? = nil
    ) -> Self {
        let horizontal = alignment.anchor
        return Self(
            target: target,
            targetAnchor: CGPoint(x: horizontal.x, y: 0),
            accessoryAnchor: CGPoint(x: horizontal.x, y: 1),
            horizontalReference: horizontal.reference,
            spacing: spacing
        )
    }

    /// Below the target: a hint below the menu.
    /// - Parameters:
    ///   - target: The element the accessory is attached to.
    ///   - alignment: Which edges of the accessory and the target line up.
    ///   - spacing: Gap between the accessory and the target, `nil` takes the style's.
    static func below(
        _ target: Target,
        alignment: HorizontalAlignment = .menuEdge,
        spacing: CGFloat? = nil
    ) -> Self {
        let horizontal = alignment.anchor
        return Self(
            target: target,
            targetAnchor: CGPoint(x: horizontal.x, y: 1),
            accessoryAnchor: CGPoint(x: horizontal.x, y: 0),
            horizontalReference: horizontal.reference,
            spacing: spacing
        )
    }

    /// Next to the target: a time label next to a message.
    ///
    /// The layout doesn't move the preview sideways: if there is no room on that side,
    /// the accessory is pushed back inside the screen and covers the target.
    /// - Parameters:
    ///   - target: The element the accessory is attached to.
    ///   - side: The side of the target.
    ///   - alignment: Which edges of the accessory and the target line up.
    ///   - spacing: Gap between the accessory and the target, `nil` takes the style's.
    static func beside(
        _ target: Target,
        side: Side,
        alignment: VerticalAlignment = .center,
        spacing: CGFloat? = nil
    ) -> Self {
        let horizontal = side.anchor
        let y = alignment.anchor
        return Self(
            target: target,
            targetAnchor: CGPoint(x: horizontal.x, y: y),
            accessoryAnchor: CGPoint(x: 1 - horizontal.x, y: y),
            horizontalReference: horizontal.reference,
            spacing: spacing
        )
    }

    /// Over the target, inside its bounds: a badge in the corner of the preview.
    /// - Parameters:
    ///   - target: The element the accessory is attached to.
    ///   - horizontalAlignment: Which vertical edges of the accessory and the target line up.
    ///   - verticalAlignment: Which horizontal edges of the accessory and the target line up.
    ///   - offset: Shift from the aligned position: `dx` towards the trailing edge for `.leading`, `.center`
    ///     and `.trailing`, away from the menu edge for `.menuEdge`; `dy` down.
    static func overlay(
        _ target: Target,
        horizontalAlignment: HorizontalAlignment = .center,
        verticalAlignment: VerticalAlignment = .center,
        offset: CGVector = .zero
    ) -> Self {
        let horizontal = horizontalAlignment.anchor
        let anchor = CGPoint(x: horizontal.x, y: verticalAlignment.anchor)
        return Self(
            target: target,
            targetAnchor: anchor,
            accessoryAnchor: anchor,
            horizontalReference: horizontal.reference,
            offset: offset
        )
    }
}

private extension ContextMenuAccessory.Placement.HorizontalAlignment {
    var anchor: (reference: ContextMenuAccessory.Placement.HorizontalReference, x: CGFloat) {
        switch self {
        case .leading:
            (.layoutDirection, 0)
        case .center:
            (.layoutDirection, 0.5)
        case .trailing:
            (.layoutDirection, 1)
        case .menuEdge:
            (.menuEdge, 0)
        }
    }
}

private extension ContextMenuAccessory.Placement.Side {
    var anchor: (reference: ContextMenuAccessory.Placement.HorizontalReference, x: CGFloat) {
        switch self {
        case .leading:
            (.layoutDirection, 0)
        case .trailing:
            (.layoutDirection, 1)
        case .menuEdge:
            (.menuEdge, 0)
        case .oppositeMenuEdge:
            (.menuEdge, 1)
        }
    }
}

private extension ContextMenuAccessory.Placement.VerticalAlignment {
    var anchor: CGFloat {
        switch self {
        case .top:
            0
        case .center:
            0.5
        case .bottom:
            1
        }
    }
}
