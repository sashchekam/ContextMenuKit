import UIKit

/// Hosts the view of a ``ContextMenuAccessory`` in the overlay.
///
/// The menu moves and scales the container, so the view inside keeps its own `transform` and `alpha`.
/// Touches that don't land on the view pass through the container to the backdrop.
@MainActor
final class ContextMenuAccessoryContainerView: UIView {
    let contentView: UIView
    let transition: ContextMenuResolvedTransition

    private let size: ContextMenuAccessory.Size
    private let placement: ContextMenuResolvedPlacement
    private let staysVisible: Bool

    /// - Parameters:
    ///   - proxy: Passed to the view of the accessory to close the menu.
    ///   - resolver: Turns the placement and the transition into physical values for this session.
    init(accessory: ContextMenuAccessory, proxy: ContextMenuProxy, resolver: ContextMenuAccessoryResolver) {
        contentView = accessory.makeView(proxy)
        size = accessory.size
        placement = resolver.placement(accessory.placement)
        transition = resolver.transition(accessory.transition, placement: accessory.placement)
        staysVisible = accessory.scrollBehavior == .staysVisible
        super.init(frame: .zero)

        // The container places the view with bounds and center, so the view's own transform stays untouched.
        contentView.translatesAutoresizingMaskIntoConstraints = true
        addSubview(contentView)
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

    /// Measures the accessory. Ask once the overlay is in the window: then the view is measured
    /// with the window traits, such as the text size.
    /// - Parameters:
    ///   - previewSize: Size of the preview, for an accessory that matches its target.
    ///   - menuSize: Size of the menu, for an accessory that matches its target.
    ///   - maxWidth: Limit of a fitting width.
    func layoutInput(previewSize: CGSize, menuSize: CGSize, maxWidth: CGFloat) -> ContextMenuAccessoryLayoutInput {
        let targetSize = switch placement.target {
        case .preview:
            previewSize
        case .menu:
            menuSize
        }
        let width = switch size.width {
        case let .fixed(width):
            width
        case .matchingTarget:
            targetSize.width
        case .fitting:
            contentView.fittingWidth(limit: maxWidth)
        }
        let height = switch size.height {
        case let .fixed(height):
            height
        case .matchingTarget:
            targetSize.height
        case .fitting:
            contentView.fittingHeight(forWidth: width)
        }

        return ContextMenuAccessoryLayoutInput(
            size: CGSize(width: width, height: height),
            placement: placement,
            staysVisible: staysVisible,
            collapsedOffset: transition.collapsedOffset
        )
    }

    // MARK: - Lifecycle

    /// Tells the view where it ends up relative to the preview and the menu, see ``ContextMenuAccessoryView``.
    /// - Parameters:
    ///   - frame: Frame of the accessory once the menu is presented.
    ///   - previewFrame: Frame of the preview in the same coordinate space.
    ///   - menuFrame: Frame of the menu in the same coordinate space.
    ///   - animation: The spring that lifts the preview.
    func willPresent(
        at frame: CGRect,
        previewFrame: CGRect,
        menuFrame: CGRect,
        animation: ContextMenuAnimationSpec.Spring
    ) {
        let context = ContextMenuAccessoryContext(
            previewFrame: previewFrame.offsetBy(dx: -frame.minX, dy: -frame.minY),
            menuFrame: menuFrame.offsetBy(dx: -frame.minX, dy: -frame.minY),
            presentationAnimation: animation
        )
        accessoryView?.contextMenuAccessoryWillPresent(context)
    }

    func didPresent() {
        accessoryView?.contextMenuAccessoryDidPresent()
    }

    func willDismiss() {
        accessoryView?.contextMenuAccessoryWillDismiss()
    }

    private var accessoryView: (any ContextMenuAccessoryView)? {
        contentView as? any ContextMenuAccessoryView
    }
}
