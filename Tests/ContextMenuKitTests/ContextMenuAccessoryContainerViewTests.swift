@testable import ContextMenuKit
import SwiftUI
import Testing
import UIKit

/// Measuring an accessory and passing touches through its container.
@MainActor
@Suite("ContextMenuAccessoryContainerView")
struct ContextMenuAccessoryContainerViewTests {
    // MARK: - Size

    @Test("A fitting accessory takes the Auto Layout size of its view")
    func autoLayoutSize() {
        let container = makeContainer(size: .fitting) { _ in FixedSizeView(size: TestData.fixedSize) }

        #expect(measure(container) == TestData.fixedSize)
    }

    @Test("A fitting accessory is at most as wide as the limit, its height is measured for that width")
    func fittingWidthIsLimited() {
        let label = UILabel()
        label.numberOfLines = 0
        label.text = String(repeating: "A long hint below the menu. ", count: 10)
        let singleLineHeight = label.intrinsicContentSize.height
        let container = makeContainer(size: .fitting) { _ in label }

        let size = measure(container)

        #expect(size.width == TestData.maxWidth)
        #expect(size.height > singleLineHeight)
    }

    @Test("A fitting accessory without constraints takes its size from sizeThatFits, the height for the resulting width")
    func frameLayoutSize() {
        let container = makeContainer(size: .fitting) { _ in FrameLayoutView() }

        // Half of the limit wide, and a quarter of that width tall.
        #expect(measure(container) == CGSize(width: TestData.maxWidth / 2, height: TestData.maxWidth / 8))
    }

    @Test("A SwiftUI accessory takes the size its content needs")
    func swiftUISize() {
        let container = makeContainer(size: .fitting) { proxy in
            ContextMenuHostingItemView(
                content: Color.red.frame(width: TestData.fixedSize.width, height: TestData.fixedSize.height),
                environmentValues: proxy.environmentValues
            )
        }

        #expect(measure(container) == TestData.fixedSize)
    }

    @Test(
        "Dimensions can be fixed or match the target",
        arguments: [
            (ContextMenuAccessory.Placement.above(.preview), TestData.previewSize.height),
            (ContextMenuAccessory.Placement.below(.menu), TestData.menuSize.height)
        ]
    )
    func fixedAndMatchingDimensions(placement: ContextMenuAccessory.Placement, expectedHeight: CGFloat) {
        let container = makeContainer(
            placement: placement,
            size: ContextMenuAccessory.Size(width: .fixed(50), height: .matchingTarget)
        ) { _ in UIView() }

        #expect(measure(container) == CGSize(width: 50, height: expectedHeight))
    }

    @Test("The layout input carries the resolved placement, the scroll behavior and the collapsed offset")
    func layoutInput() {
        let accessory = ContextMenuAccessory(
            placement: .above(.preview),
            size: .fixed(TestData.fixedSize),
            transition: ContextMenuAccessory.Transition(collapsedOffset: CGVector(dx: 5, dy: 10)),
            scrollBehavior: .staysVisible
        ) { _ in UIView() }
        let container = ContextMenuAccessoryContainerView(accessory: accessory, proxy: TestData.proxy, resolver: TestData.resolver)

        let input = container.layoutInput(previewSize: TestData.previewSize, menuSize: TestData.menuSize, maxWidth: TestData.maxWidth)

        #expect(input == ContextMenuAccessoryLayoutInput(
            size: TestData.fixedSize,
            placement: TestData.resolver.placement(.above(.preview)),
            staysVisible: true,
            collapsedOffset: CGVector(dx: 5, dy: 10)
        ))
    }

    // MARK: - Touches

    @Test("Touches on an interactive view reach the view")
    func interactiveViewGetsTouches() {
        let view = UIView()
        let container = makeLaidOutContainer(with: view)

        #expect(container.hitTest(TestData.point, with: nil) === view)
    }

    @Test("Touches on a view that doesn't take them pass through the container")
    func decorativeViewPassesTouches() {
        let view = UIView()
        view.isUserInteractionEnabled = false
        let container = makeLaidOutContainer(with: view)

        #expect(container.hitTest(TestData.point, with: nil) == nil)
    }

    @Test("The container places the view with bounds and center, keeping its transform")
    func viewKeepsTransform() {
        let view = UIView()
        view.transform = CGAffineTransform(scaleX: 0.5, y: 0.5)
        _ = makeLaidOutContainer(with: view)

        #expect(view.bounds.size == TestData.fixedSize)
        #expect(view.center == CGPoint(x: TestData.fixedSize.width / 2, y: TestData.fixedSize.height / 2))
        #expect(view.transform == CGAffineTransform(scaleX: 0.5, y: 0.5))
    }

    // MARK: - Helpers

    private func makeContainer(
        placement: ContextMenuAccessory.Placement = .above(.preview),
        size: ContextMenuAccessory.Size,
        view: @escaping @MainActor (ContextMenuProxy) -> UIView
    ) -> ContextMenuAccessoryContainerView {
        ContextMenuAccessoryContainerView(
            accessory: ContextMenuAccessory(placement: placement, size: size, view: view),
            proxy: TestData.proxy,
            resolver: TestData.resolver
        )
    }

    private func makeLaidOutContainer(with view: UIView) -> ContextMenuAccessoryContainerView {
        let container = makeContainer(size: .fixed(TestData.fixedSize)) { _ in view }
        container.frame = CGRect(origin: .zero, size: TestData.fixedSize)
        container.layoutIfNeeded()
        return container
    }

    private func measure(_ container: ContextMenuAccessoryContainerView) -> CGSize {
        container.layoutInput(previewSize: TestData.previewSize, menuSize: TestData.menuSize, maxWidth: TestData.maxWidth).size
    }
}

private extension ContextMenuAccessoryContainerViewTests {
    enum TestData {
        static let maxWidth: CGFloat = 300
        static let fixedSize = CGSize(width: 120, height: 30)
        static let previewSize = CGSize(width: 200, height: 80)
        static let menuSize = CGSize(width: 248, height: 144)
        static let point = CGPoint(x: 10, y: 10)
        static let resolver = ContextMenuAccessoryResolver(
            menuEdge: .left,
            layoutDirection: .leftToRight,
            defaultSpacing: 8,
            defaultCollapsedScale: 0.1
        )

        @MainActor
        static var proxy: ContextMenuProxy {
            ContextMenuProxy(environmentValues: nil) { _ in }
        }
    }
}

/// An Auto Layout view of a fixed size.
private final class FixedSizeView: UIView {
    init(size: CGSize) {
        super.init(frame: .zero)
        NSLayoutConstraint.activate([
            widthAnchor.constraint(equalToConstant: size.width),
            heightAnchor.constraint(equalToConstant: size.height)
        ])
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        nil
    }
}

/// A frame layout view that takes half of the proposed width and a quarter of the proposed width in height.
private final class FrameLayoutView: UIView {
    override func sizeThatFits(_ size: CGSize) -> CGSize {
        CGSize(width: size.width / 2, height: size.width / 4)
    }
}
