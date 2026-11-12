import SwiftUI
import UIKit

/// Hosts the SwiftUI view of a ``ContextMenuCustomItem`` in the menu, of a ``ContextMenuAccessory``
/// or of a ``ContextMenuPreview`` in the overlay.
///
/// Measures the content for the proposed width: the width of the menu for an item, see ``ContextMenuCustomItemRow``,
/// or the width limit for a fitting accessory, see ``ContextMenuAccessoryContainerView``.
/// A preview is as large as the source view and isn't measured.
@MainActor
final class ContextMenuHostingItemView<Content: View>: UIView {
    private let hostingController: UIHostingController<ContextMenuHostedContent<Content>>

    init(content: Content, environmentValues: EnvironmentValues?) {
        hostingController = UIHostingController(
            rootView: ContextMenuHostedContent(content: content, environmentValues: environmentValues)
        )
        super.init(frame: .zero)
        if #available(iOS 16.4, *) {
            hostingController.safeAreaRegions = []
        }
        let hostedView: UIView = hostingController.view
        // The menu background and the highlight of a selectable item are drawn behind the content.
        hostedView.backgroundColor = .clear
        addSubview(hostedView)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        nil
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        hostingController.view.frame = bounds
    }

    override func sizeThatFits(_ size: CGSize) -> CGSize {
        // An infinite height asks for the height the content needs at this width.
        hostingController.sizeThatFits(in: CGSize(width: size.width, height: .infinity))
    }

    override func systemLayoutSizeFitting(
        _ targetSize: CGSize,
        withHorizontalFittingPriority horizontalFittingPriority: UILayoutPriority,
        verticalFittingPriority: UILayoutPriority
    ) -> CGSize {
        sizeThatFits(targetSize)
    }
}
