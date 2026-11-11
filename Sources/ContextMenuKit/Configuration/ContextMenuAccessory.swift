import UIKit

/// A view the menu shows outside of its list: a bar of reactions above a message, a hint below the menu,
/// a badge over the preview, a label next to it.
///
/// ```swift
/// ContextMenuConfiguration(
///     menu: menu,
///     accessories: [
///         ContextMenuAccessory(placement: .above(.preview)) { menu in
///             ReactionsBar(reactions: reactions) { reaction in
///                 menu.dismiss { react(with: reaction) }
///             }
///         }
///     ]
/// )
/// ```
///
/// - **Placement.** An accessory is attached to the preview or to the menu: above, below, beside or over it,
///   see ``Placement``. The layout makes room for it: the preview moves down so that whatever sticks out above it
///   stays below the top of the safe area, and the menu goes below everything attached to the preview.
///   Horizontally an accessory keeps ``ContextMenuStyle/Layout/screenEdgeInset`` from the safe area edges.
/// - **Size.** Taken from the view (Auto Layout, or `sizeThatFits(_:)` for frame layout), fixed, or matching
///   the target, separately for the width and the height, see ``Size``.
/// - **Transition.** An accessory grows out of the point it is attached to as the preview lifts,
///   and collapses back as it returns, see ``Transition``.
/// - **Touches.** The view gets touches, and a tap on it doesn't dismiss the menu. A view with
///   `isUserInteractionEnabled` set to `false` lets the tap through, so a decorative accessory dismisses the menu
///   like the backdrop. Close the menu from the view through the ``ContextMenuProxy`` it gets.
/// - **Lifecycle.** Adopt ``ContextMenuAccessoryView`` to learn where the preview ends up, for example to point
///   a tail at it, and to run your own animations along with the menu.
///
/// The view is created right before the menu is shown. SwiftUI views work too, see `init(placement:size:transition:scrollBehavior:content:)`.
public struct ContextMenuAccessory {
    /// Where the accessory is attached.
    public var placement: Placement
    /// Width and height of the accessory.
    public var size: Size
    /// How the accessory appears and disappears.
    public var transition: Transition
    /// What the accessory does when the overlay scrolls, for a preview taller than the screen.
    public var scrollBehavior: ScrollBehavior

    let makeView: @MainActor (ContextMenuProxy) -> UIView

    /// Creates an accessory with a `UIView`.
    /// - Parameters:
    ///   - placement: Where the accessory is attached. Above the preview by default.
    ///   - size: Width and height of the accessory. Taken from the view by default.
    ///   - transition: How the accessory appears and disappears.
    ///   - scrollBehavior: What the accessory does when the overlay scrolls.
    ///   - view: Creates the view of the accessory. The proxy closes the menu.
    public init(
        placement: Placement = .above(.preview),
        size: Size = .fitting,
        transition: Transition = .scale,
        scrollBehavior: ScrollBehavior = .scrollsWithContent,
        view: @escaping @MainActor (ContextMenuProxy) -> UIView
    ) {
        self.placement = placement
        self.size = size
        self.transition = transition
        self.scrollBehavior = scrollBehavior
        makeView = view
    }
}

// MARK: - Size

public extension ContextMenuAccessory {
    /// Width and height of an accessory.
    struct Size: Equatable, Sendable {
        /// The view decides both dimensions.
        public static var fitting: Size {
            Size()
        }

        public var width: Dimension
        public var height: Dimension

        public init(width: Dimension = .fitting, height: Dimension = .fitting) {
            self.width = width
            self.height = height
        }

        /// A fixed size.
        public static func fixed(_ size: CGSize) -> Size {
            Size(width: .fixed(size.width), height: .fixed(size.height))
        }
    }
}

public extension ContextMenuAccessory.Size {
    /// One dimension of an accessory.
    enum Dimension: Equatable, Sendable {
        /// Taken from the view: its Auto Layout size, or `sizeThatFits(_:)` for a view without constraints.
        /// A fitting width is at most the width of the safe area without
        /// ``ContextMenuStyle/Layout/screenEdgeInset`` on both sides. A fitting height is measured
        /// for the resolved width.
        case fitting
        /// A fixed value in points.
        case fixed(CGFloat)
        /// The same as the target's: the width of the menu, the height of the preview.
        case matchingTarget
    }
}

// MARK: - Transition

public extension ContextMenuAccessory {
    /// How an accessory appears and disappears.
    ///
    /// The collapsed accessory sits next to the source view, attached to the collapsed preview or menu.
    /// It goes to its place in the spring that lifts the preview, and back in the dismissal animation.
    struct Transition: Equatable, Sendable {
        /// Grows out of the point it is attached to and fades in, like the menu grows out of its corner.
        public static var scale: Transition {
            Transition()
        }

        /// Only fades in and out, without scaling.
        public static var opacity: Transition {
            Transition(collapsedScale: 1)
        }

        /// Stays visible and flies with its target: suits a badge on the preview.
        public static var identity: Transition {
            Transition(collapsedScale: 1, collapsedAlpha: 1)
        }

        /// Scale of the collapsed accessory. `nil` takes ``ContextMenuAnimationSpec/collapsedAccessoryScale``.
        public var collapsedScale: CGFloat?
        /// Alpha of the collapsed accessory.
        public var collapsedAlpha: CGFloat
        /// The point of the accessory that stays in place while it scales, in unit coordinates of the accessory.
        /// The x coordinate is read the same way as the anchors of the placement,
        /// see ``Placement/horizontalReference``. `nil` takes ``Placement/accessoryAnchor``:
        /// the accessory grows out of the point it is attached to.
        public var anchorPoint: CGPoint?
        /// Shift of the collapsed accessory from its collapsed place: `dx` towards x = 1 of
        /// ``Placement/horizontalReference``, `dy` down. Makes the accessory slide in.
        public var collapsedOffset: CGVector

        public init(
            collapsedScale: CGFloat? = nil,
            collapsedAlpha: CGFloat = 0,
            anchorPoint: CGPoint? = nil,
            collapsedOffset: CGVector = .zero
        ) {
            self.collapsedScale = collapsedScale
            self.collapsedAlpha = collapsedAlpha
            self.anchorPoint = anchorPoint
            self.collapsedOffset = collapsedOffset
        }
    }
}

// MARK: - Scroll behavior

public extension ContextMenuAccessory {
    /// What an accessory does when the overlay scrolls. The overlay scrolls when the preview with the menu
    /// and the accessories is taller than the safe area.
    enum ScrollBehavior: Equatable, Sendable {
        /// Scrolls with the preview and the menu. The overlay starts scrolled to the menu, so an accessory
        /// above a tall preview is out of sight until the content is scrolled up.
        case scrollsWithContent
        /// Stays within the safe area: when its place scrolls away, the accessory sticks to the top or the bottom
        /// of the safe area, like a section header. Suits reactions above a tall message.
        case staysVisible
    }
}
