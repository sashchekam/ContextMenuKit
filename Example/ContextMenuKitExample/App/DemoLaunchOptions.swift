import UIKit

/// Launch arguments that let a script open a demo and its menu without touches:
///
/// ```
/// xcrun simctl launch booted dev.contextmenukit.example -demo chat -autoPresentMenu YES
/// ```
///
/// Used to check the presented state with `simctl io screenshot`.
@MainActor
struct DemoLaunchOptions {
    private enum Constants {
        static let presentationDelay: TimeInterval = 1
    }

    static var current: DemoLaunchOptions {
        let defaults = UserDefaults.standard
        return DemoLaunchOptions(
            demo: defaults.string(forKey: "demo").flatMap(Demo.init(rawValue:)).flatMap { $0.isAvailable ? $0 : nil },
            shouldAutoPresentMenu: defaults.bool(forKey: "autoPresentMenu")
        )
    }

    let demo: Demo?
    let shouldAutoPresentMenu: Bool

    func apply(to navigationController: UINavigationController) {
        guard let demo else {
            return
        }
        let screen = demo.makeViewController()
        navigationController.pushViewController(screen, animated: false)

        guard shouldAutoPresentMenu else {
            return
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + Constants.presentationDelay) { [weak screen] in
            screen?.presentPrimaryMenu()
        }
    }
}
