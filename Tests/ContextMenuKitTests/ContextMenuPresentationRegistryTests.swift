@testable import ContextMenuKit
import Testing
import UIKit

@MainActor
@Suite("ContextMenuPresentationRegistry")
struct ContextMenuPresentationRegistryTests {
    let registry = ContextMenuPresentationRegistry()
    let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 390, height: 844))
    let firstOwner = NSObject()
    let secondOwner = NSObject()

    @Test("The first menu in a window is registered")
    func registersFirstMenu() {
        #expect(registry.register(firstOwner, in: window))
        #expect(registry.hasActivePresentation(in: window))
    }

    @Test("A second menu in the same window is refused")
    func refusesSecondMenuInSameWindow() {
        registry.register(firstOwner, in: window)

        #expect(!registry.register(secondOwner, in: window))
    }

    @Test("Menus in different windows don't block each other")
    func allowsMenusInDifferentWindows() {
        let otherWindow = UIWindow(frame: window.frame)
        registry.register(firstOwner, in: window)

        #expect(registry.register(secondOwner, in: otherWindow))
    }

    @Test("Unregistering frees the window")
    func unregisterFreesWindow() {
        registry.register(firstOwner, in: window)

        registry.unregister(firstOwner)

        #expect(!registry.hasActivePresentation(in: window))
    }
}
