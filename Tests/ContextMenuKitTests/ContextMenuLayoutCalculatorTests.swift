@testable import ContextMenuKit
import CoreGraphics
import Testing
import UIKit

// Window 390 × 844, safe area from 47 to 810, menu 248 × 200.
// Space for the preview above the menu: 810 - 47 - 200 - 8 = 555, so its maxY is limited by 602.
@Suite("ContextMenuLayoutCalculator")
struct ContextMenuLayoutCalculatorTests {
    @Test("A preview that fits keeps its frame, the menu goes right below it")
    func previewThatFitsStaysInPlace() {
        let layout = ContextMenuLayoutCalculator.layout(for: .make(sourceFrame: CGRect(x: 20, y: 100, width: 150, height: 80)))

        #expect(layout.previewFrame == CGRect(x: 20, y: 100, width: 150, height: 80))
        #expect(layout.menuFrame == CGRect(x: 20, y: 188, width: 248, height: 200))
        #expect(layout.contentSize == CGSize(width: 390, height: 844))
        #expect(layout.contentOffset == .zero)
    }

    @Test("A preview too low for the menu is lifted so that the menu fits")
    func previewTooLowIsLifted() {
        let layout = ContextMenuLayoutCalculator.layout(for: .make(sourceFrame: CGRect(x: 20, y: 600, width: 150, height: 80)))

        #expect(layout.previewFrame == CGRect(x: 20, y: 522, width: 150, height: 80))
        #expect(layout.menuFrame.minY == 610)
        #expect(layout.contentOffset == .zero)
    }

    @Test("A preview above the safe area is pinned to its top")
    func previewAboveSafeAreaIsPinnedToTop() {
        let layout = ContextMenuLayoutCalculator.layout(for: .make(sourceFrame: CGRect(x: 20, y: 20, width: 150, height: 80)))

        #expect(layout.previewFrame.minY == 47)
        #expect(layout.menuFrame.minY == 135)
    }

    @Test("A preview taller than the available space is pinned to the top and the content scrolls to the menu")
    func tallPreviewMakesContentScrollable() {
        let layout = ContextMenuLayoutCalculator.layout(for: .make(sourceFrame: CGRect(x: 20, y: 100, width: 150, height: 700)))

        #expect(layout.previewFrame == CGRect(x: 20, y: 47, width: 150, height: 700))
        #expect(layout.menuFrame.minY == 755)
        #expect(layout.contentSize == CGSize(width: 390, height: 989))
        #expect(layout.contentOffset == CGPoint(x: 0, y: 145))
    }

    @Test("A right-aligned menu shares the right edge with the preview")
    func rightAlignedMenu() {
        let input = ContextMenuLayoutInput.make(sourceFrame: CGRect(x: 200, y: 100, width: 170, height: 80), menuEdge: .right)

        #expect(ContextMenuLayoutCalculator.layout(for: input).menuFrame.minX == 122)
    }

    @Test(
        "The menu keeps the inset from the screen edges",
        arguments: [
            (CGRect(x: 5, y: 100, width: 30, height: 30), ContextMenuHorizontalEdge.right, CGFloat(16)),
            (CGRect(x: 350, y: 100, width: 30, height: 30), ContextMenuHorizontalEdge.left, CGFloat(126))
        ]
    )
    func menuIsClampedToScreenEdges(sourceFrame: CGRect, menuEdge: ContextMenuHorizontalEdge, expectedMinX: CGFloat) {
        let input = ContextMenuLayoutInput.make(sourceFrame: sourceFrame, menuEdge: menuEdge)

        #expect(ContextMenuLayoutCalculator.layout(for: input).menuFrame.minX == expectedMinX)
    }

    @Test(
        "Alignment resolves to a physical edge",
        arguments: [
            MenuEdgeCase(.automatic, sourceMidX: 100, direction: .leftToRight, expected: .left),
            MenuEdgeCase(.automatic, sourceMidX: 300, direction: .leftToRight, expected: .right),
            MenuEdgeCase(.automatic, sourceMidX: 195, direction: .leftToRight, expected: .left),
            MenuEdgeCase(.automatic, sourceMidX: 195, direction: .rightToLeft, expected: .right),
            MenuEdgeCase(.leading, sourceMidX: 300, direction: .leftToRight, expected: .left),
            MenuEdgeCase(.leading, sourceMidX: 100, direction: .rightToLeft, expected: .right),
            MenuEdgeCase(.trailing, sourceMidX: 100, direction: .leftToRight, expected: .right),
            MenuEdgeCase(.trailing, sourceMidX: 300, direction: .rightToLeft, expected: .left)
        ]
    )
    func menuEdge(_ testCase: MenuEdgeCase) {
        let edge = ContextMenuLayoutCalculator.menuEdge(
            for: testCase.alignment,
            sourceFrame: CGRect(x: testCase.sourceMidX - 10, y: 100, width: 20, height: 20),
            containerWidth: 390,
            layoutDirection: testCase.direction
        )

        #expect(edge == testCase.expected)
    }
}

struct MenuEdgeCase: Sendable, CustomTestStringConvertible {
    let alignment: ContextMenuAlignment
    let sourceMidX: CGFloat
    let direction: UIUserInterfaceLayoutDirection
    let expected: ContextMenuHorizontalEdge

    var testDescription: String {
        "\(alignment), midX \(sourceMidX), \(direction == .rightToLeft ? "RTL" : "LTR") → \(expected)"
    }

    init(
        _ alignment: ContextMenuAlignment,
        sourceMidX: CGFloat,
        direction: UIUserInterfaceLayoutDirection,
        expected: ContextMenuHorizontalEdge
    ) {
        self.alignment = alignment
        self.sourceMidX = sourceMidX
        self.direction = direction
        self.expected = expected
    }
}

private extension ContextMenuLayoutInput {
    static func make(sourceFrame: CGRect, menuEdge: ContextMenuHorizontalEdge = .left) -> ContextMenuLayoutInput {
        ContextMenuLayoutInput(
            sourceFrame: sourceFrame,
            containerSize: CGSize(width: 390, height: 844),
            safeAreaInsets: UIEdgeInsets(top: 47, left: 0, bottom: 34, right: 0),
            menuSize: CGSize(width: 248, height: 200),
            menuEdge: menuEdge,
            previewMenuSpacing: 8,
            screenEdgeInset: 16
        )
    }
}
