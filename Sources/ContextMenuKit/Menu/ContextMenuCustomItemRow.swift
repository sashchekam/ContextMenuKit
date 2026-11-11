import UIKit

/// Hosts the view of a ``ContextMenuCustomItem``.
///
/// A selectable item works like an action row: its view doesn't get touches, the whole row highlights and selects.
/// An interactive item leaves touches to its view.
@MainActor
final class ContextMenuCustomItemRow: UIControl {
    override var isHighlighted: Bool {
        didSet {
            backgroundColor = isHighlighted && isSelectable ? style.highlightedBackgroundColor : .clear
        }
    }

    let contentView: UIView

    private let style: ContextMenuStyle.Row
    private let height: CGFloat?
    private let isSelectable: Bool

    /// - Parameter proxy: Passed to the view of the item; a selectable row closes the menu through it.
    init(item: ContextMenuCustomItem, proxy: ContextMenuProxy, style: ContextMenuStyle.Row) {
        contentView = item.makeView(proxy)
        self.style = style
        height = item.height
        isSelectable = item.handler != nil
        super.init(frame: .zero)

        // The row places the view with its frame, like a cell places its content view.
        contentView.translatesAutoresizingMaskIntoConstraints = true
        addSubview(contentView)

        if let handler = item.handler {
            contentView.isUserInteractionEnabled = false
            addAction(UIAction { _ in proxy.dismiss(performing: handler) }, for: .touchUpInside)
        }
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        nil
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        contentView.frame = bounds
    }
}

// MARK: - ContextMenuRow

extension ContextMenuCustomItemRow: ContextMenuRow {
    func preferredHeight(forWidth width: CGFloat) -> CGFloat {
        height ?? contentView.fittingHeight(forWidth: width)
    }
}
