@testable import ContextMenuKit
import SwiftUI
import Testing
import UIKit

/// `ContextMenuHostingController` needs iOS 16, while the package supports iOS 15. Swift Testing doesn't allow
/// `@available` on a suite type, so every test is marked on its own and gets its controller from a ``Fixture``.
@MainActor
@Suite("ContextMenuHostingController")
struct ContextMenuHostingControllerTests {
    // MARK: - Binding

    @available(iOS 16.0, *)
    @Test("Setting the binding to true presents the menu once the SwiftUI update is over")
    func bindingPresentsMenuLater() {
        let fixture = Fixture()
        fixture.flag.value = true

        fixture.update(isPresented: fixture.flag.binding)

        #expect(!fixture.controller.interaction.isActive)
        #expect(fixture.mainQueue.pendingWorkCount == 1)
    }

    @available(iOS 16.0, *)
    @Test("The deferred presentation shows the menu")
    func deferredPresentationShowsMenu() {
        let fixture = Fixture()
        fixture.flag.value = true
        fixture.update(isPresented: fixture.flag.binding)

        fixture.mainQueue.runAll()

        #expect(fixture.controller.interaction.isActive)
    }

    @available(iOS 16.0, *)
    @Test("Updates while a presentation is pending don't schedule another one")
    func repeatedUpdatesScheduleOnePresentation() {
        let fixture = Fixture()
        fixture.flag.value = true

        fixture.update(isPresented: fixture.flag.binding)
        fixture.update(isPresented: fixture.flag.binding)

        #expect(fixture.mainQueue.pendingWorkCount == 1)
    }

    @available(iOS 16.0, *)
    @Test("A menu that starts to appear sets the binding to true")
    func presentationSetsBinding() {
        let fixture = Fixture()
        fixture.update(isPresented: fixture.flag.binding)

        fixture.controller.interaction.presentMenu()

        #expect(fixture.flag.value)
    }

    @available(iOS 16.0, *)
    @Test("The binding stays true until the dismissal animation is over")
    func bindingStaysTrueDuringDismissal() {
        let fixture = Fixture()
        fixture.update(isPresented: fixture.flag.binding)
        fixture.controller.interaction.presentMenu()
        fixture.animator.finishAll()

        fixture.controller.interaction.dismissMenu(animated: true)

        #expect(fixture.flag.value)
    }

    @available(iOS 16.0, *)
    @Test("A dismissed menu sets the binding to false")
    func dismissalResetsBinding() {
        let fixture = Fixture()
        fixture.update(isPresented: fixture.flag.binding)
        fixture.controller.interaction.presentMenu()
        fixture.animator.finishAll()
        fixture.controller.interaction.dismissMenu(animated: true)

        fixture.animator.finishAll()

        #expect(!fixture.flag.value)
    }

    @available(iOS 16.0, *)
    @Test("Setting the binding to false dismisses the menu")
    func bindingDismissesMenu() {
        let fixture = Fixture()
        fixture.update(isPresented: fixture.flag.binding)
        fixture.controller.interaction.presentMenu()
        fixture.animator.finishAll()
        fixture.flag.value = false
        fixture.update(isPresented: fixture.flag.binding)

        fixture.mainQueue.runAll()
        fixture.animator.finishAll()

        #expect(!fixture.controller.interaction.isActive)
    }

    @available(iOS 16.0, *)
    @Test("An empty menu resets the binding")
    func emptyMenuResetsBinding() {
        let fixture = Fixture()
        fixture.flag.value = true
        fixture.update(isPresented: fixture.flag.binding, menu: ContextMenuKit.ContextMenu { })

        fixture.mainQueue.runAll()

        #expect(!fixture.flag.value)
    }

    @available(iOS 16.0, *)
    @Test("A window that already shows a menu resets the binding")
    func busyWindowResetsBinding() {
        let fixture = Fixture()
        let otherMenu = NSObject()
        fixture.registry.register(otherMenu, in: fixture.window)
        fixture.flag.value = true
        fixture.update(isPresented: fixture.flag.binding)

        fixture.mainQueue.runAll()

        #expect(!fixture.flag.value)
    }

    @available(iOS 16.0, *)
    @Test("Without a binding, updates leave the shown menu alone")
    func updatesWithoutBindingKeepMenu() {
        let fixture = Fixture()
        fixture.update(isPresented: nil)
        fixture.controller.interaction.presentMenu()

        fixture.update(isPresented: nil)

        #expect(fixture.mainQueue.pendingWorkCount == 0)
    }

    // MARK: - Dismantling

    @available(iOS 16.0, *)
    @Test("Removing the view closes its menu at once")
    func dismantleClosesMenu() {
        let fixture = Fixture()
        fixture.update(isPresented: fixture.flag.binding)
        fixture.controller.interaction.presentMenu()

        fixture.controller.dismantle()

        #expect(!fixture.controller.interaction.isActive)
    }

    @available(iOS 16.0, *)
    @Test("Removing the view doesn't write the binding during the SwiftUI update")
    func dismantleKeepsBindingDuringUpdate() {
        let fixture = Fixture()
        fixture.update(isPresented: fixture.flag.binding)
        fixture.controller.interaction.presentMenu()

        fixture.controller.dismantle()

        #expect(fixture.flag.value)
    }

    @available(iOS 16.0, *)
    @Test("Removing the view resets the binding once the SwiftUI update is over")
    func dismantleResetsBindingLater() {
        let fixture = Fixture()
        fixture.update(isPresented: fixture.flag.binding)
        fixture.controller.interaction.presentMenu()
        fixture.controller.dismantle()

        fixture.mainQueue.runAll()

        #expect(!fixture.flag.value)
    }

    // MARK: - Configuration

    @available(iOS 16.0, *)
    @Test("The menu comes from the latest update")
    func configurationFromLatestUpdate() {
        let fixture = Fixture()
        fixture.update(isPresented: nil, alignment: .leading, menu: TestData.menu(titled: "Old"))
        fixture.update(isPresented: nil, alignment: .trailing, menu: TestData.menu(titled: "New"))

        let configuration = fixture.controller.contextMenuInteraction(
            fixture.controller.interaction,
            configurationAt: .zero
        )

        #expect(configuration?.alignment == .trailing)
        #expect(configuration.map(TestData.titles(of:)) == ["New"])
    }

    @available(iOS 16.0, *)
    @Test("The configuration carries the environment of the modifier for SwiftUI views of custom items")
    func configurationEnvironment() {
        let fixture = Fixture()
        var environmentValues = EnvironmentValues()
        environmentValues.layoutDirection = .rightToLeft
        fixture.update(isPresented: nil, environmentValues: environmentValues)

        let configuration = fixture.controller.contextMenuInteraction(
            fixture.controller.interaction,
            configurationAt: .zero
        )

        #expect(configuration?.environmentValues?.layoutDirection == .rightToLeft)
    }

    // MARK: - Size

    @available(iOS 16.0, *)
    @Test("An unspecified proposal gets the ideal size of the content")
    func unspecifiedProposal() {
        let fixture = Fixture()

        #expect(fixture.controller.sizeThatFits(.unspecified) == CGSize(width: 10, height: 10))
    }

    @available(iOS 16.0, *)
    @Test("A specified proposal is passed to the content")
    func specifiedProposal() {
        let fixture = Fixture()

        #expect(
            fixture.controller.sizeThatFits(ProposedViewSize(width: 200, height: 300))
                == CGSize(width: 200, height: 300)
        )
    }
}

/// A value behind a `Binding` outside of SwiftUI.
@MainActor
final class PresentationFlag {
    var value = false

    var binding: Binding<Bool> {
        Binding(get: { self.value }, set: { self.value = $0 })
    }
}

private extension ContextMenuHostingControllerTests {
    /// A controller in a window with mocked animations and main queue.
    @available(iOS 16.0, *)
    @MainActor
    final class Fixture {
        let animator = ViewAnimatorMock()
        let mainQueue = MainQueueSchedulerMock()
        let registry = ContextMenuPresentationRegistry()
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 390, height: 844))
        let flag = PresentationFlag()
        let controller: ContextMenuHostingController<Color>

        init() {
            controller = ContextMenuHostingController(
                content: Color.red,
                environmentValues: EnvironmentValues(),
                environment: .mock(animator: animator, mainQueue: mainQueue, registry: registry)
            )
            window.isHidden = false
            window.addSubview(controller.view)
            controller.view.frame = CGRect(x: 16, y: 200, width: 200, height: 80)
            controller.view.layoutIfNeeded()
        }

        /// Repeats what SwiftUI does when the modifier is updated.
        func update(
            isPresented: Binding<Bool>?,
            alignment: ContextMenuAlignment = .automatic,
            environmentValues: EnvironmentValues = EnvironmentValues(),
            menu: ContextMenuKit.ContextMenu = TestData.menu(titled: "Copy")
        ) {
            controller.update(content: Color.red, environmentValues: environmentValues, isPresented: isPresented) {
                ContextMenuConfiguration(menu: menu, alignment: alignment)
            }
        }
    }

    enum TestData {
        static func menu(titled title: String) -> ContextMenuKit.ContextMenu {
            ContextMenuKit.ContextMenu {
                ContextMenuAction(title: title) { }
            }
        }

        static func titles(of configuration: ContextMenuConfiguration) -> [String] {
            configuration.menu.sections.flatMap(\.items).map { item in
                switch item {
                case let .action(action):
                    action.title
                case .custom:
                    "Custom item"
                }
            }
        }
    }
}
