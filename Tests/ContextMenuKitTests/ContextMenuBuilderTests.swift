@testable import ContextMenuKit
import Testing
import UIKit

@Suite("ContextMenuBuilder")
struct ContextMenuBuilderTests {
    @Test("Keeps sections and their actions in order")
    func sections() {
        let menu = ContextMenu {
            ContextMenuSection {
                action("A")
                action("B")
            }
            ContextMenuSection {
                action("C")
            }
        }

        #expect(menu.titles == [["A", "B"], ["C"]])
    }

    @Test("Groups consecutive actions outside of a section into one section")
    func looseActions() {
        let menu = ContextMenu {
            action("A")
            [action("B"), action("C")]
            ContextMenuItem.action(action("D"))
        }

        #expect(menu.titles == [["A", "B", "C", "D"]])
    }

    @Test("A section splits the actions around it")
    func sectionBetweenLooseActions() {
        let menu = ContextMenu {
            action("A")
            ContextMenuSection {
                action("B")
            }
            action("C")
        }

        #expect(menu.titles == [["A"], ["B"], ["C"]])
    }

    @Test("Actions around a skipped section stay in one section")
    func skippedSectionBetweenLooseActions() {
        let isSectionShown = false

        let menu = ContextMenu {
            action("A")
            if isSectionShown {
                ContextMenuSection {
                    action("B")
                }
            }
            action("C")
        }

        #expect(menu.titles == [["A", "C"]])
    }

    @Test("Sections taken from another menu aren't merged with actions next to them")
    func sectionsFromAnotherMenu() {
        let otherMenu = ContextMenu {
            action("A")
        }

        let menu = ContextMenu {
            otherMenu.sections
            action("B")
        }

        #expect(menu.titles == [["A"], ["B"]])
    }

    @Test("An empty array of actions adds no section")
    func emptyLooseActions() {
        let menu = ContextMenu {
            ContextMenuSection {
                action("A")
            }
            [ContextMenuAction]()
            ContextMenuSection {
                action("B")
            }
        }

        #expect(menu.titles == [["A"], ["B"]])
    }

    @Test("Section builder supports conditions, loops and availability checks", arguments: [true, false])
    func sectionControlFlow(condition: Bool) {
        let menu = ContextMenu {
            ContextMenuSection {
                if condition {
                    action("If")
                } else {
                    action("Else")
                }
                if condition {
                    action("Optional")
                }
                for title in ["Loop 1", "Loop 2"] {
                    action(title)
                }
                if #available(iOS 16, *) {
                    action("Available")
                }
                [action("Array")]
                ContextMenuItem.action(action("Item"))
            }
        }

        let expectedTitles = condition
            ? ["If", "Optional", "Loop 1", "Loop 2", "Available", "Array", "Item"]
            : ["Else", "Loop 1", "Loop 2", "Available", "Array", "Item"]
        #expect(menu.titles == [expectedTitles])
    }

    @Test("Menu builder supports conditions, loops and availability checks", arguments: [true, false])
    func menuControlFlow(condition: Bool) {
        let menu = ContextMenu {
            if condition {
                ContextMenuSection { action("If") }
            } else {
                ContextMenuSection { action("Else") }
            }
            if condition {
                ContextMenuSection { action("Optional") }
            }
            for title in ["Loop 1", "Loop 2"] {
                ContextMenuSection { action(title) }
            }
            if #available(iOS 16, *) {
                ContextMenuSection { action("Available") }
            }
        }

        let expectedTitles = condition
            ? [["If"], ["Optional"], ["Loop 1"], ["Loop 2"], ["Available"]]
            : [["Else"], ["Loop 1"], ["Loop 2"], ["Available"]]
        #expect(menu.titles == expectedTitles)
    }

    @Test("Custom items join sections like actions")
    func customItems() {
        let menu = ContextMenu {
            action("A")
            ContextMenuCustomItem { _ in UIView() }
            ContextMenuSection {
                ContextMenuCustomItem { _ in UIView() }
                action("B")
            }
        }

        #expect(menu.titles == [["A", TestData.customItemTitle], [TestData.customItemTitle, "B"]])
    }

    @Test("An empty menu has no sections")
    func emptyMenu() {
        let menu = ContextMenu { }

        #expect(menu.sections.isEmpty)
        #expect(menu.isEmpty)
    }
}

private func action(_ title: String) -> ContextMenuAction {
    ContextMenuAction(title: title) { }
}

private extension ContextMenuBuilderTests {
    enum TestData {
        static let customItemTitle = "Custom item"
    }
}

private extension ContextMenu {
    var titles: [[String]] {
        sections.map { section in
            section.items.map { item in
                switch item {
                case let .action(action):
                    action.title
                case .custom:
                    ContextMenuBuilderTests.TestData.customItemTitle
                }
            }
        }
    }
}
