@testable import ContextMenuKit
import CoreGraphics
import Testing
import UIKit

// Window 390 × 844, safe area from 47 to 810, menu 248 × 200, gaps of 8, screen edge inset 16.
// Reactions above the preview: 280 × 66, so they take 74 points above it.
@Suite("Accessories in ContextMenuLayoutCalculator")
struct ContextMenuAccessoryLayoutTests {
    // MARK: - Vertical layout

    @Test("An accessory above a preview that fits leaves the preview in place")
    func accessoryAbovePreviewThatFits() {
        let layout = layout(sourceFrame: CGRect(x: 20, y: 200, width: 150, height: 80), accessories: [.reactions()])

        #expect(layout.previewFrame.minY == 200)
        #expect(layout.accessoryFrames == [CGRect(x: 20, y: 126, width: 280, height: 66)])
        #expect(layout.menuFrame.minY == 288)
    }

    @Test("A preview without room for its accessory above moves down so that the accessory starts at the safe area")
    func accessoryAbovePreviewPushesItDown() {
        let layout = layout(sourceFrame: CGRect(x: 20, y: 60, width: 150, height: 80), accessories: [.reactions()])

        #expect(layout.previewFrame.minY == 121)
        #expect(layout.accessoryFrames.first?.minY == 47)
        #expect(layout.menuFrame.minY == 209)
    }

    @Test("An accessory below the menu lifts the preview so that it fits above the bottom of the safe area")
    func accessoryBelowMenuLiftsPreview() {
        let hint = TestData.accessory(.below(.menu), size: CGSize(width: 248, height: 40))
        let layout = layout(sourceFrame: CGRect(x: 20, y: 500, width: 150, height: 80), accessories: [hint])

        #expect(layout.previewFrame.minY == 474)
        #expect(layout.menuFrame.minY == 562)
        #expect(layout.accessoryFrames == [CGRect(x: 20, y: 770, width: 248, height: 40)])
    }

    @Test("An accessory below the preview goes between the preview and the menu")
    func accessoryBelowPreviewPushesMenuDown() {
        let label = TestData.accessory(.below(.preview), size: CGSize(width: 200, height: 30))
        let layout = layout(sourceFrame: CGRect(x: 20, y: 100, width: 150, height: 80), accessories: [label])

        #expect(layout.accessoryFrames == [CGRect(x: 20, y: 188, width: 200, height: 30)])
        #expect(layout.menuFrame.minY == 226)
    }

    @Test("An accessory above the menu goes between the preview and the menu")
    func accessoryAboveMenuPushesMenuDown() {
        let label = TestData.accessory(.above(.menu), size: CGSize(width: 200, height: 30))
        let layout = layout(sourceFrame: CGRect(x: 20, y: 100, width: 150, height: 80), accessories: [label])

        #expect(layout.accessoryFrames == [CGRect(x: 20, y: 188, width: 200, height: 30)])
        #expect(layout.menuFrame.minY == 226)
    }

    @Test("An accessory over the preview takes no extra room")
    func overlayTakesNoRoom() {
        let badge = TestData.accessory(
            .overlay(.preview, horizontalAlignment: .trailing, verticalAlignment: .top),
            size: TestData.badgeSize
        )
        let layout = layout(sourceFrame: CGRect(x: 20, y: 100, width: 150, height: 80), accessories: [badge])

        #expect(layout.previewFrame.minY == 100)
        #expect(layout.accessoryFrames == [CGRect(x: 146, y: 100, width: 24, height: 24)])
        #expect(layout.menuFrame.minY == 188)
    }

    @Test("The part of an overlay that sticks out above the preview stays below the top of the safe area")
    func overlaySticksOutAbovePreview() {
        let badge = TestData.accessory(
            .overlay(.preview, horizontalAlignment: .trailing, verticalAlignment: .top, offset: CGVector(dx: 8, dy: -12)),
            size: TestData.badgeSize
        )
        let layout = layout(sourceFrame: CGRect(x: 20, y: 50, width: 150, height: 80), accessories: [badge])

        #expect(layout.previewFrame.minY == 59)
        #expect(layout.accessoryFrames == [CGRect(x: 154, y: 47, width: 24, height: 24)])
    }

    @Test("An accessory beside the preview lines up with its bottom on the side away from the menu edge")
    func accessoryBesidePreview() {
        let label = TestData.accessory(
            .beside(.preview, side: .oppositeMenuEdge, alignment: .bottom),
            size: CGSize(width: 60, height: 20)
        )
        let layout = layout(sourceFrame: CGRect(x: 20, y: 200, width: 150, height: 80), accessories: [label])

        #expect(layout.accessoryFrames == [CGRect(x: 178, y: 260, width: 60, height: 20)])
    }

    @Test("Several accessories keep the order of the input")
    func severalAccessories() {
        let hint = TestData.accessory(.below(.menu), size: CGSize(width: 248, height: 40))
        let layout = layout(sourceFrame: CGRect(x: 20, y: 200, width: 150, height: 80), accessories: [hint, .reactions()])

        #expect(layout.accessoryFrames == [
            CGRect(x: 20, y: 496, width: 248, height: 40),
            CGRect(x: 20, y: 126, width: 280, height: 66)
        ])
    }

    @Test("A tall preview with an accessory makes the content scroll to the bottom of the menu group")
    func tallPreviewWithAccessories() {
        let layout = layout(sourceFrame: CGRect(x: 20, y: 100, width: 150, height: 700), accessories: [.reactions()])

        #expect(layout.previewFrame.minY == 121)
        #expect(layout.accessoryFrames.first?.minY == 47)
        #expect(layout.menuFrame.minY == 829)
        #expect(layout.contentSize.height == 1063)
        #expect(layout.contentOffset == CGPoint(x: 0, y: 219))
    }

    // MARK: - Horizontal layout

    @Test("An accessory aligned with the menu edge follows a right-aligned menu")
    func accessoryFollowsRightMenuEdge() {
        let layout = layout(
            sourceFrame: CGRect(x: 300, y: 200, width: 70, height: 80),
            menuEdge: .right,
            accessories: [.reactions(menuEdge: .right)]
        )

        #expect(layout.accessoryFrames.first?.minX == 90)
    }

    @Test(
        "An accessory keeps the inset from the screen edges",
        arguments: [
            (CGRect(x: 5, y: 200, width: 30, height: 30), CGFloat(280), CGFloat(16)),
            (CGRect(x: 200, y: 200, width: 30, height: 30), CGFloat(280), CGFloat(94)),
            (CGRect(x: 200, y: 200, width: 30, height: 30), CGFloat(400), CGFloat(16))
        ]
    )
    func accessoryIsClampedToScreenEdges(sourceFrame: CGRect, width: CGFloat, expectedMinX: CGFloat) {
        let accessory = TestData.accessory(.above(.preview), size: CGSize(width: width, height: 40))
        let layout = layout(sourceFrame: sourceFrame, accessories: [accessory])

        #expect(layout.accessoryFrames.first?.minX == expectedMinX)
    }

    // MARK: - Scrolling

    @Test("An accessory that stays visible is shown at the top of the safe area of the scrolled content")
    func accessoryStaysVisible() {
        let reactions = ContextMenuAccessoryLayoutInput.reactions(staysVisible: true)
        let input = ContextMenuLayoutInput.make(
            sourceFrame: CGRect(x: 20, y: 100, width: 150, height: 700),
            accessories: [reactions]
        )
        let layout = ContextMenuLayoutCalculator.layout(for: input)

        let frame = ContextMenuLayoutCalculator.displayedFrame(
            of: layout.accessoryFrames[0],
            for: reactions,
            contentOffset: layout.contentOffset,
            input: input
        )

        #expect(frame == CGRect(x: 20, y: 266, width: 280, height: 66))
    }

    @Test("An accessory that scrolls with the content is shown at its place")
    func accessoryScrollsWithContent() {
        let reactions = ContextMenuAccessoryLayoutInput.reactions()
        let input = ContextMenuLayoutInput.make(
            sourceFrame: CGRect(x: 20, y: 100, width: 150, height: 700),
            accessories: [reactions]
        )
        let layout = ContextMenuLayoutCalculator.layout(for: input)

        let frame = ContextMenuLayoutCalculator.displayedFrame(
            of: layout.accessoryFrames[0],
            for: reactions,
            contentOffset: layout.contentOffset,
            input: input
        )

        #expect(frame == layout.accessoryFrames[0])
    }

    @Test(
        "A visible frame is kept within the safe area of the visible content",
        arguments: [
            (CGFloat(1000), CGFloat(0), CGFloat(770)),
            (CGFloat(10), CGFloat(100), CGFloat(147)),
            (CGFloat(300), CGFloat(100), CGFloat(300))
        ]
    )
    func visibleFrame(originY: CGFloat, contentOffsetY: CGFloat, expectedY: CGFloat) {
        let frame = ContextMenuLayoutCalculator.visibleFrame(
            of: CGRect(x: 20, y: originY, width: 100, height: 40),
            contentOffset: CGPoint(x: 0, y: contentOffsetY),
            input: .make(sourceFrame: .zero)
        )

        #expect(frame.minY == expectedY)
    }

    // MARK: - Collapsed state

    @Test("Collapsed accessories of the preview sit next to the source view, those of the menu next to the collapsed menu")
    func collapsedFrames() {
        let hint = TestData.accessory(
            .below(.menu),
            size: CGSize(width: 248, height: 40),
            collapsedOffset: CGVector(dx: 0, dy: 10)
        )
        let frames = ContextMenuLayoutCalculator.collapsedFrames(
            sourceFrame: CGRect(x: 20, y: 200, width: 150, height: 80),
            collapsedMenuScale: 0.1,
            input: .make(sourceFrame: .zero, accessories: [.reactions(), hint])
        )

        #expect(frames.preview == CGRect(x: 20, y: 200, width: 150, height: 80))
        #expect(frames.menu == CGRect(x: 20, y: 288, width: 248, height: 200))
        #expect(frames.accessories == [
            CGRect(x: 20, y: 126, width: 280, height: 66),
            CGRect(x: 20, y: 326, width: 248, height: 40)
        ])
    }

    // MARK: - Helpers

    private func layout(
        sourceFrame: CGRect,
        menuEdge: ContextMenuHorizontalEdge = .left,
        accessories: [ContextMenuAccessoryLayoutInput]
    ) -> ContextMenuLayout {
        ContextMenuLayoutCalculator.layout(for: .make(sourceFrame: sourceFrame, menuEdge: menuEdge, accessories: accessories))
    }
}

// MARK: - Resolver

@Suite("ContextMenuAccessoryResolver")
struct ContextMenuAccessoryResolverTests {
    @Test("Above the preview at the menu edge: bottom corner to top corner, spacing up")
    func abovePreviewAtLeftMenuEdge() {
        let placement = TestData.resolver().placement(.above(.preview))

        #expect(placement == ContextMenuResolvedPlacement(
            target: .preview,
            targetAnchor: CGPoint(x: 0, y: 0),
            accessoryAnchor: CGPoint(x: 0, y: 1),
            offset: CGVector(dx: 0, dy: -8)
        ))
    }

    @Test("A placement at the menu edge mirrors for a right-aligned menu")
    func menuEdgeMirrors() {
        let placement = TestData.resolver(menuEdge: .right).placement(.above(.preview, spacing: 4))

        #expect(placement.targetAnchor == CGPoint(x: 1, y: 0))
        #expect(placement.accessoryAnchor == CGPoint(x: 1, y: 1))
        #expect(placement.offset == CGVector(dx: 0, dy: -4))
    }

    @Test(
        "Beside the target the spacing goes sideways",
        arguments: [
            (ContextMenuHorizontalEdge.left, CGFloat(1), CGFloat(4)),
            (ContextMenuHorizontalEdge.right, CGFloat(0), CGFloat(-4))
        ]
    )
    func besideSpacing(menuEdge: ContextMenuHorizontalEdge, expectedTargetX: CGFloat, expectedDX: CGFloat) {
        let placement = TestData.resolver(menuEdge: menuEdge).placement(.beside(.preview, side: .oppositeMenuEdge, spacing: 4))

        #expect(placement.targetAnchor == CGPoint(x: expectedTargetX, y: 0.5))
        #expect(placement.accessoryAnchor == CGPoint(x: 1 - expectedTargetX, y: 0.5))
        #expect(placement.offset == CGVector(dx: expectedDX, dy: 0))
    }

    @Test(
        "A placement in layout direction mirrors in right-to-left languages, an overlay gets no spacing",
        arguments: [
            (UIUserInterfaceLayoutDirection.leftToRight, CGFloat(1), CGFloat(8)),
            (UIUserInterfaceLayoutDirection.rightToLeft, CGFloat(0), CGFloat(-8))
        ]
    )
    func layoutDirectionMirrors(direction: UIUserInterfaceLayoutDirection, expectedX: CGFloat, expectedDX: CGFloat) {
        let placement = TestData.resolver(layoutDirection: direction).placement(
            .overlay(.preview, horizontalAlignment: .trailing, verticalAlignment: .top, offset: CGVector(dx: 8, dy: -8))
        )

        #expect(placement.targetAnchor == CGPoint(x: expectedX, y: 0))
        #expect(placement.accessoryAnchor == CGPoint(x: expectedX, y: 0))
        #expect(placement.offset == CGVector(dx: expectedDX, dy: -8))
    }

    @Test("By default an accessory grows out of the point it is attached to, with the scale of the spec")
    func defaultTransition() {
        let transition = TestData.resolver(menuEdge: .right).transition(.scale, placement: .above(.preview))

        #expect(transition == ContextMenuResolvedTransition(
            collapsedScale: 0.1,
            collapsedAlpha: 0,
            anchorPoint: CGPoint(x: 1, y: 1),
            collapsedOffset: .zero
        ))
    }

    @Test("A custom transition mirrors its anchor point and offset with the placement")
    func customTransitionMirrors() {
        let transition = TestData.resolver(menuEdge: .right).transition(
            ContextMenuAccessory.Transition(
                collapsedScale: 0.5,
                collapsedAlpha: 0.2,
                anchorPoint: CGPoint(x: 0.25, y: 0),
                collapsedOffset: CGVector(dx: 10, dy: 20)
            ),
            placement: .below(.menu)
        )

        #expect(transition == ContextMenuResolvedTransition(
            collapsedScale: 0.5,
            collapsedAlpha: 0.2,
            anchorPoint: CGPoint(x: 0.75, y: 0),
            collapsedOffset: CGVector(dx: -10, dy: 20)
        ))
    }
}

// MARK: - Test data

private enum TestData {
    static let reactionsSize = CGSize(width: 280, height: 66)
    static let badgeSize = CGSize(width: 24, height: 24)

    static func resolver(
        menuEdge: ContextMenuHorizontalEdge = .left,
        layoutDirection: UIUserInterfaceLayoutDirection = .leftToRight
    ) -> ContextMenuAccessoryResolver {
        ContextMenuAccessoryResolver(
            menuEdge: menuEdge,
            layoutDirection: layoutDirection,
            defaultSpacing: 8,
            defaultCollapsedScale: 0.1
        )
    }

    static func accessory(
        _ placement: ContextMenuAccessory.Placement,
        size: CGSize,
        menuEdge: ContextMenuHorizontalEdge = .left,
        collapsedOffset: CGVector = .zero
    ) -> ContextMenuAccessoryLayoutInput {
        ContextMenuAccessoryLayoutInput(
            size: size,
            placement: resolver(menuEdge: menuEdge).placement(placement),
            collapsedOffset: collapsedOffset
        )
    }
}

private extension ContextMenuAccessoryLayoutInput {
    static func reactions(menuEdge: ContextMenuHorizontalEdge = .left, staysVisible: Bool = false) -> Self {
        ContextMenuAccessoryLayoutInput(
            size: TestData.reactionsSize,
            placement: TestData.resolver(menuEdge: menuEdge).placement(.above(.preview)),
            staysVisible: staysVisible
        )
    }
}

private extension ContextMenuLayoutInput {
    static func make(
        sourceFrame: CGRect,
        menuEdge: ContextMenuHorizontalEdge = .left,
        accessories: [ContextMenuAccessoryLayoutInput] = []
    ) -> ContextMenuLayoutInput {
        ContextMenuLayoutInput(
            sourceFrame: sourceFrame,
            containerSize: CGSize(width: 390, height: 844),
            safeAreaInsets: UIEdgeInsets(top: 47, left: 0, bottom: 34, right: 0),
            menuSize: CGSize(width: 248, height: 200),
            menuEdge: menuEdge,
            previewMenuSpacing: 8,
            screenEdgeInset: 16,
            accessories: accessories
        )
    }
}
