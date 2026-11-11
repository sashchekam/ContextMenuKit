import UIKit

/// Computes where the preview, the menu and the accessories end up. Pure functions without state.
///
/// Rules:
/// - the preview keeps its X and moves only vertically;
/// - accessories are attached to the preview or to the menu; the preview with its accessories forms
///   the top group, the menu with its accessories — the bottom group, placed `previewMenuSpacing` below the top one;
/// - a preview that is taller than the space left for it, or whose group starts above the safe area,
///   is placed so that its group starts at the top of the safe area;
/// - a preview that is too low is lifted so that the bottom group fits above the bottom of the safe area;
/// - otherwise the preview stays where it is;
/// - the menu is aligned with the left or right edge of the preview, accessories with their anchors;
///   neither comes closer than `screenEdgeInset` to the safe area edges;
/// - if the content doesn't fit into the window, it becomes scrollable and is scrolled to the bottom.
enum ContextMenuLayoutCalculator {
    /// Frames of the preview and the menu with the frames of their accessories.
    private struct Arrangement {
        var previewFrame: CGRect
        var menuFrame: CGRect
        var accessoryFrames: [CGRect]
        /// Union of all the frames and the gap between the groups.
        var bounds: CGRect

        func movedVertically(by distance: CGFloat) -> Arrangement {
            Arrangement(
                previewFrame: previewFrame.offsetBy(dx: 0, dy: distance),
                menuFrame: menuFrame.offsetBy(dx: 0, dy: distance),
                accessoryFrames: accessoryFrames.map { $0.offsetBy(dx: 0, dy: distance) },
                bounds: bounds.offsetBy(dx: 0, dy: distance)
            )
        }
    }

    static func layout(for input: ContextMenuLayoutInput) -> ContextMenuLayout {
        let sourceFrame = input.sourceFrame
        let arrangementAtSource = arrangement(forPreviewAt: sourceFrame, input: input)
        let previewY = previewOriginY(
            for: input,
            spaceAbove: sourceFrame.minY - arrangementAtSource.bounds.minY,
            spaceBelow: arrangementAtSource.bounds.maxY - sourceFrame.maxY
        )
        // The preview moves only vertically, and horizontal positions don't depend on vertical ones.
        let arrangement = arrangementAtSource.movedVertically(by: previewY - sourceFrame.minY)
        let contentHeight = max(input.containerSize.height, arrangement.bounds.maxY + input.safeAreaInsets.bottom)

        return ContextMenuLayout(
            previewFrame: arrangement.previewFrame,
            menuFrame: arrangement.menuFrame,
            accessoryFrames: arrangement.accessoryFrames,
            contentSize: CGSize(width: input.containerSize.width, height: contentHeight),
            contentOffset: CGPoint(x: 0, y: contentHeight - input.containerSize.height)
        )
    }

    /// Frames of the collapsed menu and accessories next to the preview at `sourceFrame`:
    /// where they grow from during the presentation and where they return during the dismissal.
    ///
    /// The menu frame is the frame before scaling, the menu itself is scaled into its corner,
    /// see ``menuAnchorPoint(for:)``. Accessories of the menu are attached to the menu as it looks collapsed.
    static func collapsedFrames(
        sourceFrame: CGRect,
        collapsedMenuScale: CGFloat,
        input: ContextMenuLayoutInput
    ) -> ContextMenuOverlayFrames {
        let arrangement = arrangement(forPreviewAt: sourceFrame, input: input)
        let visibleMenuFrame = scale(
            arrangement.menuFrame,
            by: collapsedMenuScale,
            around: menuAnchorPoint(for: input.menuEdge)
        )
        let accessoryFrames = input.accessories.enumerated().map { index, accessory in
            let frame = switch accessory.placement.target {
            case .preview:
                arrangement.accessoryFrames[index]
            case .menu:
                accessoryFrame(accessory, attachedTo: visibleMenuFrame, input: input)
            }
            return frame.offsetBy(dx: accessory.collapsedOffset.dx, dy: accessory.collapsedOffset.dy)
        }
        return ContextMenuOverlayFrames(preview: sourceFrame, menu: arrangement.menuFrame, accessories: accessoryFrames)
    }

    /// Frame where an accessory is shown when the content is scrolled to `contentOffset`.
    /// An accessory that stays visible is moved into the safe area of the visible part of the content.
    static func displayedFrame(
        of frame: CGRect,
        for accessory: ContextMenuAccessoryLayoutInput,
        contentOffset: CGPoint,
        input: ContextMenuLayoutInput
    ) -> CGRect {
        guard accessory.staysVisible else {
            return frame
        }
        return visibleFrame(of: frame, contentOffset: contentOffset, input: input)
    }

    /// Moves `frame` vertically into the safe area of the part of the content visible at `contentOffset`.
    static func visibleFrame(of frame: CGRect, contentOffset: CGPoint, input: ContextMenuLayoutInput) -> CGRect {
        let minY = contentOffset.y + input.safeAreaInsets.top
        let maxY = contentOffset.y + input.containerSize.height - input.safeAreaInsets.bottom - frame.height
        var visibleFrame = frame
        visibleFrame.origin.y = max(minY, min(frame.minY, maxY))
        return visibleFrame
    }

    /// The corner of the menu it grows from: the top corner on the side of the preview edge it is aligned with.
    static func menuAnchorPoint(for menuEdge: ContextMenuHorizontalEdge) -> CGPoint {
        switch menuEdge {
        case .left:
            CGPoint(x: 0, y: 0)
        case .right:
            CGPoint(x: 1, y: 0)
        }
    }

    static func menuEdge(
        for alignment: ContextMenuAlignment,
        sourceFrame: CGRect,
        containerWidth: CGFloat,
        layoutDirection: UIUserInterfaceLayoutDirection
    ) -> ContextMenuHorizontalEdge {
        let leadingEdge: ContextMenuHorizontalEdge = layoutDirection == .rightToLeft ? .right : .left
        let trailingEdge: ContextMenuHorizontalEdge = layoutDirection == .rightToLeft ? .left : .right

        switch alignment {
        case .leading:
            return leadingEdge
        case .trailing:
            return trailingEdge
        case .automatic:
            let windowCenterX = containerWidth / 2
            if sourceFrame.midX < windowCenterX {
                return .left
            }
            if sourceFrame.midX > windowCenterX {
                return .right
            }
            return leadingEdge
        }
    }

    // MARK: - Private

    /// Lays out both groups for the preview at `previewFrame`: the menu goes below everything attached to the preview.
    private static func arrangement(forPreviewAt previewFrame: CGRect, input: ContextMenuLayoutInput) -> Arrangement {
        var accessoryFrames = [CGRect](repeating: .zero, count: input.accessories.count)

        var previewGroup = previewFrame
        for (index, accessory) in input.accessories.enumerated() where accessory.placement.target == .preview {
            accessoryFrames[index] = accessoryFrame(accessory, attachedTo: previewFrame, input: input)
            previewGroup = previewGroup.union(accessoryFrames[index])
        }

        // The menu group is laid out from y = 0 first, then moved below the preview group.
        var menuFrame = CGRect(origin: CGPoint(x: menuOriginX(for: previewFrame, input: input), y: 0), size: input.menuSize)
        var menuGroup = menuFrame
        var menuAccessoryIndices: [Int] = []
        for (index, accessory) in input.accessories.enumerated() where accessory.placement.target == .menu {
            accessoryFrames[index] = accessoryFrame(accessory, attachedTo: menuFrame, input: input)
            menuGroup = menuGroup.union(accessoryFrames[index])
            menuAccessoryIndices.append(index)
        }
        let menuShift = previewGroup.maxY + input.previewMenuSpacing - menuGroup.minY
        menuFrame.origin.y += menuShift
        menuGroup.origin.y += menuShift
        for index in menuAccessoryIndices {
            accessoryFrames[index].origin.y += menuShift
        }

        return Arrangement(
            previewFrame: previewFrame,
            menuFrame: menuFrame,
            accessoryFrames: accessoryFrames,
            bounds: previewGroup.union(menuGroup)
        )
    }

    private static func menuOriginX(for previewFrame: CGRect, input: ContextMenuLayoutInput) -> CGFloat {
        let preferredX = switch input.menuEdge {
        case .left:
            previewFrame.minX
        case .right:
            previewFrame.maxX - input.menuSize.width
        }
        return clampedX(preferredX, width: input.menuSize.width, input: input)
    }

    private static func accessoryFrame(
        _ accessory: ContextMenuAccessoryLayoutInput,
        attachedTo targetFrame: CGRect,
        input: ContextMenuLayoutInput
    ) -> CGRect {
        let placement = accessory.placement
        let size = accessory.size
        let x = targetFrame.minX + targetFrame.width * placement.targetAnchor.x
            - size.width * placement.accessoryAnchor.x + placement.offset.dx
        let y = targetFrame.minY + targetFrame.height * placement.targetAnchor.y
            - size.height * placement.accessoryAnchor.y + placement.offset.dy
        return CGRect(origin: CGPoint(x: clampedX(x, width: size.width, input: input), y: y), size: size)
    }

    /// Keeps a view of `width` at least `screenEdgeInset` away from the safe area edges.
    /// A view wider than that space starts at the left inset.
    private static func clampedX(_ x: CGFloat, width: CGFloat, input: ContextMenuLayoutInput) -> CGFloat {
        let minX = input.safeAreaInsets.left + input.screenEdgeInset
        let maxX = input.containerSize.width - input.safeAreaInsets.right - input.screenEdgeInset - width
        return max(minX, min(x, maxX))
    }

    /// Y of the preview, given how much its groups stick out above and below it.
    private static func previewOriginY(for input: ContextMenuLayoutInput, spaceAbove: CGFloat, spaceBelow: CGFloat) -> CGFloat {
        let safeFrame = CGRect(origin: .zero, size: input.containerSize).inset(by: input.safeAreaInsets)
        let sourceFrame = input.sourceFrame
        let availableHeight = safeFrame.height - spaceAbove - spaceBelow

        if sourceFrame.height > availableHeight || sourceFrame.minY - spaceAbove < safeFrame.minY {
            return safeFrame.minY + spaceAbove
        }
        if sourceFrame.maxY + spaceBelow > safeFrame.maxY {
            return safeFrame.maxY - spaceBelow - sourceFrame.height
        }
        return sourceFrame.minY
    }

    /// Visible frame of a view of `frame` scaled by `scale` around `anchorPoint`.
    private static func scale(_ frame: CGRect, by scale: CGFloat, around anchorPoint: CGPoint) -> CGRect {
        let anchor = CGPoint(x: frame.minX + frame.width * anchorPoint.x, y: frame.minY + frame.height * anchorPoint.y)
        let size = CGSize(width: frame.width * scale, height: frame.height * scale)
        return CGRect(
            origin: CGPoint(x: anchor.x - size.width * anchorPoint.x, y: anchor.y - size.height * anchorPoint.y),
            size: size
        )
    }
}
