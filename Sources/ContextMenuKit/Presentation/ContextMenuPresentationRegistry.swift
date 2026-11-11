import UIKit

/// Keeps track of active menus so that a window never shows two menus at once.
@MainActor
final class ContextMenuPresentationRegistry {
    private struct Entry {
        weak var window: UIWindow?
        weak var owner: AnyObject?
    }

    static let shared = ContextMenuPresentationRegistry()

    private var entries: [Entry] = []

    func hasActivePresentation(in window: UIWindow) -> Bool {
        removeStaleEntries()
        return entries.contains { $0.window === window }
    }

    /// Registers `owner` as the active menu of `window`.
    /// - Returns: `false` if the window already has an active menu.
    @discardableResult
    func register(_ owner: AnyObject, in window: UIWindow) -> Bool {
        guard !hasActivePresentation(in: window) else {
            return false
        }
        entries.append(Entry(window: window, owner: owner))
        return true
    }

    func unregister(_ owner: AnyObject) {
        entries.removeAll { $0.owner === owner }
        removeStaleEntries()
    }

    private func removeStaleEntries() {
        entries.removeAll { $0.owner == nil || $0.window == nil }
    }
}
