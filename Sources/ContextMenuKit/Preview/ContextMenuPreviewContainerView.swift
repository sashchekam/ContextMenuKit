import UIKit

/// Holds the preview in the overlay: a snapshot of the source view or the view of ``ContextMenuPreview/view(_:)``.
///
/// The menu moves, scales, masks and fades the container, so the view inside keeps its own `transform` and `alpha`.
/// Touches that don't land on the view pass through the container to the backdrop.
@MainActor
final class ContextMenuPreviewContainerView: UIView {
    let contentView: UIView

    init(contentView: UIView) {
        self.contentView = contentView
        super.init(frame: .zero)

        // The container places the view with bounds and center, so the view's own transform stays untouched.
        contentView.translatesAutoresizingMaskIntoConstraints = true
        addSubview(contentView)
    }

    /// Creates the preview of `sourceView`: its snapshot or the view of `preview`.
    /// `nil` if the source view can't be snapshotted.
    /// - Parameter proxy: Passed to the view of the preview to close the menu.
    convenience init?(_ preview: ContextMenuPreview, of sourceView: UIView, proxy: ContextMenuProxy) {
        switch preview.kind {
        case .snapshot:
            guard let snapshotView = sourceView.snapshotView(afterScreenUpdates: true) else {
                return nil
            }
            // A snapshot is only a picture: a tap on it goes to the backdrop and dismisses the menu.
            snapshotView.isUserInteractionEnabled = false
            self.init(contentView: snapshotView)
        case let .view(makeView):
            self.init(contentView: makeView(proxy))
        }
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        nil
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        contentView.bounds = CGRect(origin: contentView.bounds.origin, size: bounds.size)
        contentView.center = CGPoint(x: bounds.midX, y: bounds.midY)
    }

    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        let hitView = super.hitTest(point, with: event)
        return hitView === self ? nil : hitView
    }
}
