import ContextMenuKit
import UIKit

/// A screen of the example app. The raw value is the name for the `-demo` launch argument.
enum Demo: String, CaseIterable {
    case freeViews = "free-views"
    case chat
    case files
    case tallPreview = "tall-preview"
    case longMenu = "long-menu"
    case moreButton = "more-button"
    case customItems = "custom-items"
    case accessories
    case styles
    case lifecycle
    case swiftUI = "swiftui"

    /// Demos that run on this device. The SwiftUI modifier needs iOS 16, so on iOS 15 the SwiftUI demo is hidden.
    static var available: [Demo] {
        allCases.filter(\.isAvailable)
    }

    var isAvailable: Bool {
        guard self == .swiftUI else {
            return true
        }
        guard #available(iOS 16.0, *) else {
            return false
        }
        return true
    }

    var title: String {
        switch self {
        case .freeViews:
            "Free views"
        case .chat:
            "Chat"
        case .files:
            "Files"
        case .tallPreview:
            "Tall preview"
        case .longMenu:
            "Long menu"
        case .moreButton:
            "More button"
        case .customItems:
            "Custom items"
        case .accessories:
            "Accessories"
        case .styles:
            "Styles"
        case .lifecycle:
            "Lifecycle"
        case .swiftUI:
            "SwiftUI"
        }
    }

    var subtitle: String {
        switch self {
        case .freeViews:
            "Views of different sizes all over the screen"
        case .chat:
            "Bubbles in a collection view, clipped by the bars on the way back"
        case .files:
            "Menus built from the state of each file, actions that change the grid"
        case .tallPreview:
            "A view taller than the screen, the overlay scrolls"
        case .longMenu:
            "Every built-in icon in a menu taller than the screen"
        case .moreButton:
            "Presenting the menu from a button, without a press"
        case .customItems:
            "Your own views in the menu: reactions, a volume slider, a selectable row"
        case .accessories:
            "Your own views around the preview and the menu: reactions, badges, hints"
        case .styles:
            "Colors, fonts, sizes, backdrop and timings of the menu"
        case .lifecycle:
            "Delegate calls in a log, a view without a menu, dismissal from code"
        case .swiftUI:
            "The same menus on SwiftUI views: a binding, self-sizing content, custom items and reactions"
        }
    }

    @MainActor
    func makeViewController() -> UIViewController & DemoScreen {
        makeScreen()
    }

    /// The initializer of the screen. A reference to the initializer of each class rather than `init()` on a metatype:
    /// on `(UIViewController & DemoScreen).Type`, `init()` is the inherited `UIViewController.init()`,
    /// which skips the own initializer of `SwiftUIDemoViewController` and crashes in `UIHostingController`.
    @MainActor
    private var makeScreen: @MainActor () -> UIViewController & DemoScreen {
        switch self {
        case .freeViews:
            FreeViewsDemoViewController.init
        case .chat:
            ChatDemoViewController.init
        case .files:
            FilesDemoViewController.init
        case .tallPreview:
            TallPreviewDemoViewController.init
        case .longMenu:
            LongMenuDemoViewController.init
        case .moreButton:
            MoreButtonDemoViewController.init
        case .customItems:
            CustomItemsDemoViewController.init
        case .accessories:
            AccessoriesDemoViewController.init
        case .styles:
            StylesDemoViewController.init
        case .lifecycle:
            LifecycleDemoViewController.init
        case .swiftUI:
            if #available(iOS 16.0, *) {
                SwiftUIDemoViewController.init
            } else {
                preconditionFailure("The SwiftUI demo needs iOS 16, see isAvailable")
            }
        }
    }
}

/// A demo screen that can open its menu on its own, see ``DemoLaunchOptions``.
@MainActor
protocol DemoScreen: AnyObject {
    /// Presents the main menu of the screen when the app is launched with `-autoPresentMenu YES`.
    func presentPrimaryMenu()
}
