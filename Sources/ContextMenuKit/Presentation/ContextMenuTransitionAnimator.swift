import UIKit

/// Choreography of the menu transitions. Knows nothing about states: it only moves views.
///
/// Positions are applied through `bounds`, `center` and `transform` separately, because
/// animating `frame` of a view with a non-identity transform is undefined in UIKit.
@MainActor
struct ContextMenuTransitionAnimator {
    let animator: any AnimatesViews
    let spec: ContextMenuAnimationSpec

    /// The first beat: the source view shrinks a little under the finger.
    func animatePressDown(
        of view: UIView,
        from baseTransform: CGAffineTransform,
        completion: @escaping @MainActor (Bool) -> Void
    ) {
        let pressedTransform = baseTransform.scaledBy(x: spec.pressDownScale, y: spec.pressDownScale)
        animator.animate(pressAnimation) {
            view.transform = pressedTransform
        } completion: { finished in
            completion(finished)
        }
    }

    /// Returns the source view to its transform when the press is cancelled before the presentation.
    func animatePressRelease(
        of view: UIView,
        to transform: CGAffineTransform,
        completion: @escaping @MainActor (Bool) -> Void
    ) {
        animator.animate(pressAnimation) {
            view.transform = transform
        } completion: { finished in
            completion(finished)
        }
    }

    /// Puts the preview over the source view and collapses the menu and the accessories, without animation.
    /// - Parameters:
    ///   - frames: Frames of the collapsed state in the content coordinates of the overlay.
    ///   - previewScale: Scale of the source view at the moment of presentation.
    ///   - menuAnchorPoint: Corner of the menu that stays in place while it grows.
    func prepareForPresentation(
        of overlay: ContextMenuOverlayView,
        frames: ContextMenuOverlayFrames,
        previewScale: CGFloat,
        menuAnchorPoint: CGPoint
    ) {
        let previewView = overlay.previewView
        previewView.bounds = CGRect(origin: .zero, size: frames.preview.size)
        previewView.center = Self.center(of: frames.preview, anchorPoint: previewView.layer.anchorPoint)
        previewView.transform = CGAffineTransform(scaleX: previewScale, y: previewScale)

        let menuView = overlay.menuView
        menuView.layer.anchorPoint = menuAnchorPoint
        menuView.bounds = CGRect(origin: .zero, size: frames.menu.size)
        menuView.center = Self.center(of: frames.menu, anchorPoint: menuAnchorPoint)
        menuView.transform = collapsedMenuTransform
        menuView.alpha = 0

        for (accessoryView, frame) in zip(overlay.accessoryViews, frames.accessories) {
            accessoryView.layer.anchorPoint = accessoryView.transition.anchorPoint
            accessoryView.bounds = CGRect(origin: .zero, size: frame.size)
            accessoryView.center = Self.center(of: frame, anchorPoint: accessoryView.transition.anchorPoint)
            accessoryView.transform = accessoryView.transition.collapsedTransform
            accessoryView.alpha = accessoryView.transition.collapsedAlpha
        }

        overlay.dimmingView.alpha = 0
        overlay.blurView.effect = nil
        overlay.layoutIfNeeded()
    }

    /// The second beat: the preview lifts to its place, the menu and the accessories expand, the backdrop blurs.
    /// - Parameter frames: Frames of the presented state in the content coordinates of the overlay.
    func animatePresentation(
        of overlay: ContextMenuOverlayView,
        frames: ContextMenuOverlayFrames,
        blurStyle: UIBlurEffect.Style,
        completion: @escaping @MainActor (Bool) -> Void
    ) {
        let previewView = overlay.previewView
        let menuView = overlay.menuView
        let accessoryViews = overlay.accessoryViews
        let dimmingView = overlay.dimmingView
        let blurView = overlay.blurView
        let previewCenter = Self.center(of: frames.preview, anchorPoint: previewView.layer.anchorPoint)
        let menuCenter = Self.center(of: frames.menu, anchorPoint: menuView.layer.anchorPoint)
        let accessoryCenters = Self.centers(of: accessoryViews, in: frames.accessories)
        let animation = ViewAnimation(
            duration: spec.presentation.duration,
            options: [.curveEaseInOut, .allowUserInteraction],
            spring: ViewAnimation.Spring(
                dampingRatio: spec.presentation.dampingRatio,
                initialVelocity: spec.presentation.initialVelocity
            )
        )

        animator.animate(animation) {
            previewView.center = previewCenter
            previewView.transform = .identity
            menuView.center = menuCenter
            menuView.transform = .identity
            menuView.alpha = 1
            for (accessoryView, center) in zip(accessoryViews, accessoryCenters) {
                accessoryView.center = center
                accessoryView.transform = .identity
                accessoryView.alpha = 1
            }
            dimmingView.alpha = 1
            blurView.effect = UIBlurEffect(style: blurStyle)
        } completion: { finished in
            completion(finished)
        }
    }

    /// Moves the presented accessories without animation, for example to keep them visible while the content scrolls.
    func moveAccessories(of overlay: ContextMenuOverlayView, to frames: [CGRect]) {
        for (accessoryView, center) in zip(overlay.accessoryViews, Self.centers(of: overlay.accessoryViews, in: frames)) {
            accessoryView.center = center
        }
    }

    /// Flies the preview back over the source view and collapses the menu and the accessories.
    /// - Parameters:
    ///   - frames: Frames of the collapsed state in the content coordinates of the overlay.
    ///   - visiblePreviewRect: Part of the preview, in its own coordinates, that stays visible
    ///     when it lands. `nil` means the preview is not clipped.
    func animateDismissal(
        of overlay: ContextMenuOverlayView,
        frames: ContextMenuOverlayFrames,
        visiblePreviewRect: CGRect?,
        completion: @escaping @MainActor (Bool) -> Void
    ) {
        let previewView = overlay.previewView
        let menuView = overlay.menuView
        let accessoryViews = overlay.accessoryViews
        let dimmingView = overlay.dimmingView
        let blurView = overlay.blurView
        let previewCenter = Self.center(of: frames.preview, anchorPoint: previewView.layer.anchorPoint)
        let menuCenter = Self.center(of: frames.menu, anchorPoint: menuView.layer.anchorPoint)
        let accessoryCenters = Self.centers(of: accessoryViews, in: frames.accessories)
        let collapsedMenuTransform = self.collapsedMenuTransform

        if let visiblePreviewRect {
            applyClippingMask(to: previewView, visibleRect: visiblePreviewRect)
        }

        let animation = ViewAnimation(duration: spec.dismissalDuration, options: [.curveEaseInOut, .beginFromCurrentState])
        animator.animate(animation) {
            previewView.center = previewCenter
            previewView.transform = .identity
            menuView.center = menuCenter
            menuView.transform = collapsedMenuTransform
            menuView.alpha = 0
            for (accessoryView, center) in zip(accessoryViews, accessoryCenters) {
                accessoryView.center = center
                accessoryView.transform = accessoryView.transition.collapsedTransform
                accessoryView.alpha = accessoryView.transition.collapsedAlpha
            }
            dimmingView.alpha = 0
            blurView.effect = nil
        } completion: { finished in
            completion(finished)
        }
    }

    /// The last beat: the preview fades out over the source view that is already visible,
    /// together with the accessories that stay visible when collapsed.
    func animatePreviewFadeOut(of overlay: ContextMenuOverlayView, completion: @escaping @MainActor (Bool) -> Void) {
        guard spec.previewFadeOutDuration > 0 else {
            completion(true)
            return
        }
        let previewView = overlay.previewView
        let accessoryViews = overlay.accessoryViews
        animator.animate(ViewAnimation(duration: spec.previewFadeOutDuration, options: .curveEaseInOut)) {
            previewView.alpha = 0
            for accessoryView in accessoryViews {
                accessoryView.alpha = 0
            }
        } completion: { finished in
            completion(finished)
        }
    }

    // MARK: - Private

    private var collapsedMenuTransform: CGAffineTransform {
        CGAffineTransform(scaleX: spec.collapsedMenuScale, y: spec.collapsedMenuScale)
    }

    private var pressAnimation: ViewAnimation {
        ViewAnimation(
            duration: spec.pressDownDuration,
            options: [.curveEaseInOut, .allowUserInteraction, .beginFromCurrentState]
        )
    }

    /// Position of `anchorPoint` of a view that occupies `frame` with the identity transform.
    static func center(of frame: CGRect, anchorPoint: CGPoint) -> CGPoint {
        CGPoint(x: frame.minX + frame.width * anchorPoint.x, y: frame.minY + frame.height * anchorPoint.y)
    }

    private static func centers(of accessoryViews: [ContextMenuAccessoryContainerView], in frames: [CGRect]) -> [CGPoint] {
        zip(accessoryViews, frames).map { accessoryView, frame in
            center(of: frame, anchorPoint: accessoryView.layer.anchorPoint)
        }
    }

    /// Animates a mask from the whole preview down to its visible part, so that on its way back
    /// the preview gradually hides behind bars instead of flying over them.
    private func applyClippingMask(to view: UIView, visibleRect: CGRect) {
        let fullPath = CGPath(rect: view.bounds, transform: nil)
        let visiblePath = CGPath(rect: visibleRect, transform: nil)

        let mask = CAShapeLayer()
        mask.frame = view.bounds
        mask.path = visiblePath
        view.layer.mask = mask

        let animation = CABasicAnimation(keyPath: "path")
        animation.fromValue = fullPath
        animation.toValue = visiblePath
        animation.duration = spec.dismissalDuration
        animation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        mask.add(animation, forKey: "path")
    }
}
