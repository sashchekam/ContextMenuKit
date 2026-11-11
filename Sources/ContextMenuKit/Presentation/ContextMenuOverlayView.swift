import UIKit

/// Full-window overlay: dimming and blur backdrop, and a vertical scroll view
/// that holds the preview, the menu and the accessories. A tap outside the menu and the accessories
/// requests dismissal.
@MainActor
final class ContextMenuOverlayView: UIView {
    let dimmingView = UIView()
    let blurView = UIVisualEffectView(effect: nil)
    let scrollView = ContextMenuScrollView()
    /// Container of the preview, the menu and the accessories, its coordinates are the scroll view content coordinates.
    let contentView = UIView()
    let previewView: UIView
    let menuView: ContextMenuListView
    /// Drawn above the preview and the menu, in the order of the configuration.
    let accessoryViews: [ContextMenuAccessoryContainerView]

    var onDismissRequest: (() -> Void)?
    /// Called when the window size changes: the layout is no longer valid.
    var onSizeChange: (() -> Void)?
    /// Called when the content scrolls.
    var onScroll: (() -> Void)?

    private var lastLayoutSize: CGSize?

    init(
        frame: CGRect,
        previewView: UIView,
        menuView: ContextMenuListView,
        accessoryViews: [ContextMenuAccessoryContainerView],
        style: ContextMenuStyle.Background
    ) {
        self.previewView = previewView
        self.menuView = menuView
        self.accessoryViews = accessoryViews
        super.init(frame: frame)

        autoresizingMask = [.flexibleWidth, .flexibleHeight]
        accessibilityViewIsModal = true
        dimmingView.backgroundColor = style.dimmingColor

        addSubview(dimmingView)
        addSubview(blurView)
        addSubview(scrollView)
        scrollView.addSubview(contentView)
        contentView.addSubview(previewView)
        contentView.addSubview(menuView)
        for accessoryView in accessoryViews {
            contentView.addSubview(accessoryView)
        }
        scrollView.delegate = self

        let tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        tapRecognizer.delegate = self
        scrollView.addGestureRecognizer(tapRecognizer)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        nil
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        dimmingView.frame = bounds
        blurView.frame = bounds
        scrollView.frame = bounds

        if let lastLayoutSize, lastLayoutSize != bounds.size {
            // Leave the layout pass before the overlay removes itself.
            DispatchQueue.main.async { [weak self] in
                self?.onSizeChange?()
            }
        }
        lastLayoutSize = bounds.size
    }

    override func accessibilityPerformEscape() -> Bool {
        onDismissRequest?()
        return true
    }

    /// `true` for a view of the menu or of an accessory: a tap on it doesn't dismiss the menu.
    func isMenuContent(_ view: UIView) -> Bool {
        view.isDescendant(of: menuView) || accessoryViews.contains { view.isDescendant(of: $0) }
    }

    func setContent(size: CGSize, offset: CGPoint) {
        contentView.frame = CGRect(origin: .zero, size: size)
        scrollView.contentSize = size
        scrollView.contentOffset = offset
    }

    @objc
    private func handleTap() {
        onDismissRequest?()
    }
}

// MARK: - UIGestureRecognizerDelegate

extension ContextMenuOverlayView: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        guard let touchedView = touch.view else {
            return true
        }
        return !isMenuContent(touchedView)
    }
}

// MARK: - UIScrollViewDelegate

extension ContextMenuOverlayView: UIScrollViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        onScroll?()
    }
}

/// Scroll view of the overlay. Rows highlight without delay, and a drag that starts on a row still scrolls.
/// Controls inside custom items, such as sliders, keep the UIKit behavior: a drag doesn't cancel their touches.
@MainActor
final class ContextMenuScrollView: UIScrollView {
    override init(frame: CGRect) {
        super.init(frame: frame)
        contentInsetAdjustmentBehavior = .never
        delaysContentTouches = false
        showsHorizontalScrollIndicator = false
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        nil
    }

    override func touchesShouldCancel(in view: UIView) -> Bool {
        view is any ContextMenuRow || super.touchesShouldCancel(in: view)
    }

    func stopScrolling() {
        setContentOffset(contentOffset, animated: false)
    }
}
