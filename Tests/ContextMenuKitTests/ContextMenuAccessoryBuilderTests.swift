@testable import ContextMenuKit
import Testing
import UIKit

@MainActor
@Suite("ContextMenuAccessoryBuilder")
struct ContextMenuAccessoryBuilderTests {
    @Test("Keeps accessories and arrays of them in order")
    func order() {
        let configuration = ContextMenuConfiguration {
            accessory("A")
            [accessory("B"), accessory("C")]
            accessory("D")
        }

        #expect(configuration.accessories.names == ["A", "B", "C", "D"])
    }

    @Test("Supports conditions, loops and availability checks", arguments: [true, false])
    func controlFlow(condition: Bool) {
        let configuration = ContextMenuConfiguration {
            if condition {
                accessory("If")
            } else {
                accessory("Else")
            }
            if condition {
                accessory("Optional")
            }
            for name in ["Loop 1", "Loop 2"] {
                accessory(name)
            }
            if #available(iOS 16, *) {
                accessory("Available")
            }
        }

        let expectedNames = condition
            ? ["If", "Optional", "Loop 1", "Loop 2", "Available"]
            : ["Else", "Loop 1", "Loop 2", "Available"]
        #expect(configuration.accessories.names == expectedNames)
    }

    @Test("An empty closure adds no accessories, so a configuration without menu items stays empty")
    func emptyAccessories() {
        let configuration = ContextMenuConfiguration { }

        #expect(configuration.accessories.isEmpty)
        #expect(configuration.isEmpty)
    }

    @Test("Passes the other parameters through")
    func otherParameters() {
        let configuration = ContextMenuConfiguration(
            menu: ContextMenu {
                ContextMenuAction(title: "Copy") { }
            },
            alignment: .trailing
        ) {
            accessory("A")
        }

        #expect(configuration.menu.sections.count == 1)
        #expect(configuration.alignment == .trailing)
        #expect(configuration.accessories.names == ["A"])
    }
}

private func accessory(_ name: String) -> ContextMenuAccessory {
    ContextMenuAccessory { _ in
        let view = UIView()
        view.accessibilityIdentifier = name
        return view
    }
}

@MainActor
private extension [ContextMenuAccessory] {
    var names: [String] {
        let proxy = DismissRecorder().proxy
        return map { $0.makeView(proxy).accessibilityIdentifier ?? "" }
    }
}
