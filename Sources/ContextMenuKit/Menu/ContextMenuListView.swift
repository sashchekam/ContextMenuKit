import UIKit

/// The menu itself: sections of action rows and custom items with thin separators between rows
/// and thick separators between sections. Uses frame layout, its width is ``ContextMenuStyle/Menu/width``.
///
/// Rows close the menu through the proxy: a selected action or a selectable custom item passes its handler,
/// interactive custom items call the proxy themselves.
@MainActor
final class ContextMenuListView: UIView {
    /// Size of the menu. Measures custom items on the first call, so ask for it once the menu is in the window:
    /// then the items are measured with the window traits, such as the text size.
    var preferredSize: CGSize {
        let rowHeights = rowHeights.flatMap { $0 }
        let rowSeparatorCount = rows.reduce(0) { $0 + $1.count - 1 }
        let sectionSeparatorCount = max(rows.count - 1, 0)
        let height = rowHeights.reduce(0, +)
            + CGFloat(rowSeparatorCount) * style.menu.separatorThickness
            + CGFloat(sectionSeparatorCount) * style.menu.sectionSeparatorHeight
        return CGSize(width: style.menu.width, height: height)
    }

    private let style: ContextMenuStyle
    private let proxy: ContextMenuProxy
    /// Rows of non-empty sections.
    private var rows: [[any ContextMenuRow]] = []
    private var rowSeparators: [UIView] = []
    private var sectionSeparators: [UIView] = []
    /// Measured once: the frames of the preview and the menu are computed from these heights.
    private lazy var rowHeights: [[CGFloat]] = rows.map { sectionRows in
        sectionRows.map { $0.preferredHeight(forWidth: style.menu.width) }
    }

    init(menu: ContextMenu, style: ContextMenuStyle, proxy: ContextMenuProxy) {
        self.style = style
        self.proxy = proxy
        super.init(frame: .zero)
        backgroundColor = style.menu.backgroundColor
        layer.cornerRadius = style.menu.cornerRadius
        layer.cornerCurve = .continuous
        clipsToBounds = true
        setUpRows(for: menu)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        nil
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        var originY: CGFloat = 0
        var rowSeparatorIndex = 0

        for (sectionIndex, sectionRows) in rows.enumerated() {
            if sectionIndex > 0 {
                sectionSeparators[sectionIndex - 1].frame = horizontalStrip(at: originY, height: style.menu.sectionSeparatorHeight)
                originY += style.menu.sectionSeparatorHeight
            }
            for (rowIndex, row) in sectionRows.enumerated() {
                if rowIndex > 0 {
                    rowSeparators[rowSeparatorIndex].frame = horizontalStrip(at: originY, height: style.menu.separatorThickness)
                    rowSeparatorIndex += 1
                    originY += style.menu.separatorThickness
                }
                let rowHeight = rowHeights[sectionIndex][rowIndex]
                row.frame = horizontalStrip(at: originY, height: rowHeight)
                originY += rowHeight
            }
        }
    }

    private func setUpRows(for menu: ContextMenu) {
        let sections = menu.sections.map(\.items).filter { !$0.isEmpty }

        for (sectionIndex, items) in sections.enumerated() {
            if sectionIndex > 0 {
                sectionSeparators.append(makeSeparator(color: style.menu.sectionSeparatorColor))
            }
            var sectionRows: [any ContextMenuRow] = []
            for (itemIndex, item) in items.enumerated() {
                if itemIndex > 0 {
                    rowSeparators.append(makeSeparator(color: style.menu.separatorColor))
                }
                let row = makeRow(for: item)
                addSubview(row)
                sectionRows.append(row)
            }
            rows.append(sectionRows)
        }
    }

    private func makeRow(for item: ContextMenuItem) -> any ContextMenuRow {
        switch item {
        case let .action(action):
            ContextMenuActionRow(action: action, style: style.row) { [proxy] in
                guard action.isEnabled else {
                    return
                }
                proxy.dismiss(performing: action.handler)
            }
        case let .custom(customItem):
            ContextMenuCustomItemRow(item: customItem, proxy: proxy, style: style.row)
        }
    }

    private func makeSeparator(color: UIColor) -> UIView {
        let separator = UIView()
        separator.backgroundColor = color
        separator.isUserInteractionEnabled = false
        addSubview(separator)
        return separator
    }

    private func horizontalStrip(at originY: CGFloat, height: CGFloat) -> CGRect {
        CGRect(x: 0, y: originY, width: bounds.width, height: height)
    }
}
