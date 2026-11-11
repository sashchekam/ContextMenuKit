import UIKit

final class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?

    func scene(
        _ scene: UIScene,
        willConnectTo session: UISceneSession,
        options connectionOptions: UIScene.ConnectionOptions
    ) {
        guard let windowScene = scene as? UIWindowScene else {
            return
        }
        let window = UIWindow(windowScene: windowScene)
        let navigationController = UINavigationController(rootViewController: DemoListViewController())
        DemoLaunchOptions.current.apply(to: navigationController)
        window.rootViewController = navigationController
        window.makeKeyAndVisible()
        self.window = window
    }
}
