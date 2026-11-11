import UIKit

/// Physical edge of the preview the menu is aligned with.
enum ContextMenuHorizontalEdge: Equatable {
    case left
    case right
}

/// Input of ``ContextMenuLayoutCalculator``. All frames are in window coordinates.
struct ContextMenuLayoutInput: Equatable {
    var sourceFrame: CGRect
    var containerSize: CGSize
    var safeAreaInsets: UIEdgeInsets
    var menuSize: CGSize
    var menuEdge: ContextMenuHorizontalEdge
    var previewMenuSpacing: CGFloat
    var screenEdgeInset: CGFloat
    var accessories: [ContextMenuAccessoryLayoutInput] = []
}

/// An accessory as the layout sees it: its measured size and where it is attached, in physical coordinates.
struct ContextMenuAccessoryLayoutInput: Equatable {
    var size: CGSize
    var placement: ContextMenuResolvedPlacement
    /// Sticks to the safe area when the overlay scrolls, see ``ContextMenuAccessory/ScrollBehavior/staysVisible``.
    var staysVisible = false
    /// Shift of the collapsed accessory from its collapsed place.
    var collapsedOffset: CGVector = .zero
}

/// ``ContextMenuAccessory/Placement`` with the horizontal reference applied:
/// x of the anchors is measured from the left edge, `dx` points right, and the spacing is part of the offset.
struct ContextMenuResolvedPlacement: Equatable {
    var target: ContextMenuAccessory.Placement.Target
    var targetAnchor: CGPoint
    var accessoryAnchor: CGPoint
    var offset: CGVector
}

/// Result of ``ContextMenuLayoutCalculator``.
///
/// Frames are in the content coordinates of the overlay's scroll view, which match
/// window coordinates while the content isn't scrolled.
struct ContextMenuLayout: Equatable {
    var previewFrame: CGRect
    var menuFrame: CGRect
    /// Frames of the accessories in the order of the input, at their place next to the preview and the menu.
    /// An accessory that stays visible may be shown elsewhere, see ``ContextMenuLayoutCalculator/visibleFrame(of:contentOffset:input:)``.
    var accessoryFrames: [CGRect]
    var contentSize: CGSize
    /// Initial scroll position: a preview taller than the screen is scrolled so that the menu is visible.
    var contentOffset: CGPoint
}

/// Frames of the views of the overlay in one state of a transition.
struct ContextMenuOverlayFrames: Equatable {
    var preview: CGRect
    /// The menu frame without its scale.
    var menu: CGRect
    var accessories: [CGRect]

    /// Applies `transform` to every frame, for example to convert them to another coordinate space.
    func map(_ transform: (CGRect) -> CGRect) -> ContextMenuOverlayFrames {
        ContextMenuOverlayFrames(
            preview: transform(preview),
            menu: transform(menu),
            accessories: accessories.map(transform)
        )
    }
}
