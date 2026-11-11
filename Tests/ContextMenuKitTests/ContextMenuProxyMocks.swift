@testable import ContextMenuKit
import UIKit

/// Keeps the handlers the menu was asked to dismiss with, instead of dismissing it.
@MainActor
final class DismissRecorder {
    private(set) var handlers: [ContextMenuAction.Handler?] = []

    var proxy: ContextMenuProxy {
        ContextMenuProxy(environmentValues: nil) { [weak self] handler in
            self?.handlers.append(handler)
        }
    }

    /// Runs the recorded handlers, as the menu does after its dismissal animation.
    func performHandlers() {
        for handler in handlers {
            handler?()
        }
    }
}

/// Titles of the actions and items in the order their handlers ran.
@MainActor
final class ActionLog {
    private(set) var performed: [String] = []

    func handler(_ title: String) -> ContextMenuAction.Handler {
        { [weak self] in
            self?.performed.append(title)
        }
    }
}

/// The view of a custom item that keeps the proxy it got, so that a test can close the menu like the view would.
@MainActor
final class ProxyProbeView: UIView {
    let proxy: ContextMenuProxy

    init(proxy: ContextMenuProxy) {
        self.proxy = proxy
        super.init(frame: .zero)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        nil
    }
}
