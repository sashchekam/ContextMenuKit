@testable import ContextMenuKit
import SwiftUI
import Testing
import UIKit

@MainActor
@Suite("ContextMenuListView")
struct ContextMenuListViewTests {
    let recorder = DismissRecorder()
    let log = ActionLog()
    let style = ContextMenuStyle.default

    // MARK: - Selection

    @Test("A selected action closes the menu with its handler")
    func actionSelection() {
        let listView = makeListView {
            ContextMenuAction(title: "Copy", handler: log.handler("Copy"))
        }

        listView.firstRow(of: ContextMenuActionRow.self)?.sendActions(for: .touchUpInside)
        recorder.performHandlers()

        #expect(log.performed == ["Copy"])
    }

    @Test("A disabled action doesn't close the menu")
    func disabledActionSelection() {
        let listView = makeListView {
            ContextMenuAction(title: "Edit", isEnabled: false, handler: log.handler("Edit"))
        }

        listView.firstRow(of: ContextMenuActionRow.self)?.sendActions(for: .touchUpInside)

        #expect(recorder.handlers.isEmpty)
    }

    @Test("A selectable custom item closes the menu with its handler")
    func selectableItemSelection() {
        let listView = makeListView {
            ContextMenuCustomItem(handler: log.handler("Receipts")) { UIView() }
        }

        listView.firstRow(of: ContextMenuCustomItemRow.self)?.sendActions(for: .touchUpInside)
        recorder.performHandlers()

        #expect(log.performed == ["Receipts"])
    }

    @Test("The view of a selectable custom item doesn't get touches: the row does")
    func selectableItemTouches() {
        let listView = makeListView {
            ContextMenuCustomItem(handler: log.handler("Receipts")) { UIView() }
        }

        #expect(listView.firstRow(of: ContextMenuCustomItemRow.self)?.contentView.isUserInteractionEnabled == false)
    }

    @Test("A tap on an interactive custom item outside of its controls doesn't close the menu")
    func interactiveItemRowTap() {
        let listView = makeListView {
            ContextMenuCustomItem { _ in UIView() }
        }

        listView.firstRow(of: ContextMenuCustomItemRow.self)?.sendActions(for: .touchUpInside)

        #expect(recorder.handlers.isEmpty)
    }

    @Test("The view of an interactive custom item gets touches")
    func interactiveItemTouches() {
        let listView = makeListView {
            ContextMenuCustomItem { _ in UIView() }
        }

        #expect(listView.firstRow(of: ContextMenuCustomItemRow.self)?.contentView.isUserInteractionEnabled == true)
    }

    @Test("The view of an interactive custom item closes the menu through its proxy")
    func interactiveItemDismissal() {
        let listView = makeListView {
            ContextMenuCustomItem { proxy in ProxyProbeView(proxy: proxy) }
        }
        let probeView = listView.firstRow(of: ContextMenuCustomItemRow.self)?.contentView as? ProxyProbeView

        probeView?.proxy.dismiss(performing: log.handler("Reaction"))
        recorder.performHandlers()

        #expect(log.performed == ["Reaction"])
    }

    // MARK: - Highlight

    @Test("A selectable custom item highlights like an action row")
    func selectableItemHighlight() {
        let listView = makeListView {
            ContextMenuCustomItem(handler: log.handler("Receipts")) { UIView() }
        }
        let row = listView.firstRow(of: ContextMenuCustomItemRow.self)

        row?.isHighlighted = true

        #expect(row?.backgroundColor == style.row.highlightedBackgroundColor)
    }

    @Test("An interactive custom item doesn't highlight")
    func interactiveItemHighlight() {
        let listView = makeListView {
            ContextMenuCustomItem { _ in UIView() }
        }
        let row = listView.firstRow(of: ContextMenuCustomItemRow.self)

        row?.isHighlighted = true

        #expect(row?.backgroundColor == .clear)
    }

    // MARK: - Height

    @Test("A custom item with a height keeps it")
    func explicitHeight() {
        let listView = makeListView {
            ContextMenuCustomItem(height: TestData.explicitHeight) { _ in AspectRatioView() }
        }

        #expect(listView.preferredSize.height == TestData.explicitHeight)
    }

    @Test("A custom item without a height takes the Auto Layout height of its view at the menu width")
    func autoLayoutHeight() {
        let listView = makeListView {
            ContextMenuCustomItem { _ in AspectRatioView() }
        }

        #expect(listView.preferredSize.height == style.menu.width / TestData.aspectRatio)
    }

    @Test("A custom item without constraints takes the height from sizeThatFits")
    func frameLayoutHeight() {
        let listView = makeListView {
            ContextMenuCustomItem { _ in FrameLayoutView() }
        }

        #expect(listView.preferredSize.height == style.menu.width / TestData.aspectRatio)
    }

    @Test("A SwiftUI custom item takes the height its content needs at the menu width")
    func swiftUIHeight() {
        let listView = makeListView {
            ContextMenuCustomItem { _ in
                Color.red.aspectRatio(TestData.aspectRatio, contentMode: .fit)
            }
        }

        #expect(listView.preferredSize.height == style.menu.width / TestData.aspectRatio)
    }

    @Test("A SwiftUI custom item gets the environment of the modifier", arguments: [nil, TestData.environmentHeight])
    func swiftUIEnvironment(environmentHeight: CGFloat?) {
        var environmentValues: EnvironmentValues?
        if let environmentHeight {
            environmentValues = EnvironmentValues()
            environmentValues?.probeHeight = environmentHeight
        }
        let listView = ContextMenuListView(
            menu: ContextMenu {
                ContextMenuCustomItem { _ in EnvironmentHeightProbe() }
            },
            style: style,
            proxy: ContextMenuProxy(environmentValues: environmentValues) { _ in }
        )

        #expect(listView.preferredSize.height == environmentHeight ?? ProbeHeightKey.defaultValue)
    }

    @Test("Custom items and actions are separated like rows")
    func heightWithSeparators() {
        let listView = makeListView {
            ContextMenuSection {
                ContextMenuCustomItem(height: TestData.explicitHeight) { _ in UIView() }
                ContextMenuAction(title: "Reply") { }
            }
            ContextMenuSection {
                ContextMenuAction(title: "Delete") { }
            }
        }

        let expectedHeight = TestData.explicitHeight + style.menu.separatorThickness + style.row.height
            + style.menu.sectionSeparatorHeight + style.row.height
        #expect(listView.preferredSize.height == expectedHeight)
    }

    @Test("Rows are laid out one after another with their own heights")
    func rowFrames() {
        let listView = makeListView {
            ContextMenuCustomItem(height: TestData.explicitHeight) { _ in UIView() }
            ContextMenuAction(title: "Reply") { }
        }
        listView.frame = CGRect(origin: .zero, size: listView.preferredSize)

        listView.layoutIfNeeded()

        let actionRowY = TestData.explicitHeight + style.menu.separatorThickness
        #expect(listView.firstRow(of: ContextMenuCustomItemRow.self)?.frame == CGRect(
            x: 0, y: 0, width: style.menu.width, height: TestData.explicitHeight
        ))
        #expect(listView.firstRow(of: ContextMenuActionRow.self)?.frame == CGRect(
            x: 0, y: actionRowY, width: style.menu.width, height: style.row.height
        ))
    }

    // MARK: - Helpers

    private func makeListView(@ContextMenuBuilder content: () -> [ContextMenuSection]) -> ContextMenuListView {
        ContextMenuListView(menu: ContextMenu(content: content), style: style, proxy: recorder.proxy)
    }
}

private extension ContextMenuListViewTests {
    enum TestData {
        static let explicitHeight: CGFloat = 60
        /// Width to height ratio of the views that depend on the menu width.
        static let aspectRatio: CGFloat = 4
        static let environmentHeight: CGFloat = 70
    }
}

private extension ContextMenuListView {
    func firstRow<Row: UIView>(of type: Row.Type) -> Row? {
        subviews.lazy.compactMap { $0 as? Row }.first
    }
}

/// An Auto Layout view whose height depends on its width.
private final class AspectRatioView: UIView {
    override init(frame: CGRect) {
        super.init(frame: frame)
        let contentView = UIView()
        contentView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(contentView)
        NSLayoutConstraint.activate([
            contentView.topAnchor.constraint(equalTo: topAnchor),
            contentView.bottomAnchor.constraint(equalTo: bottomAnchor),
            contentView.leadingAnchor.constraint(equalTo: leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: trailingAnchor),
            contentView.heightAnchor.constraint(
                equalTo: contentView.widthAnchor,
                multiplier: 1 / ContextMenuListViewTests.TestData.aspectRatio
            )
        ])
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        nil
    }
}

/// A frame layout view whose height depends on its width.
private final class FrameLayoutView: UIView {
    override func sizeThatFits(_ size: CGSize) -> CGSize {
        CGSize(width: size.width, height: size.width / ContextMenuListViewTests.TestData.aspectRatio)
    }
}

private struct ProbeHeightKey: EnvironmentKey {
    static let defaultValue: CGFloat = 10
}

private extension EnvironmentValues {
    var probeHeight: CGFloat {
        get { self[ProbeHeightKey.self] }
        set { self[ProbeHeightKey.self] = newValue }
    }
}

/// A SwiftUI view as tall as the environment says.
private struct EnvironmentHeightProbe: View {
    @Environment(\.probeHeight) private var height

    var body: some View {
        Color.clear.frame(height: height)
    }
}
