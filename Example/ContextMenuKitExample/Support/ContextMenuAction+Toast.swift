import ContextMenuKit
import UIKit

extension ContextMenuAction {
    /// An action of the example app: shows its title in a toast over `view` when selected.
    @MainActor
    static func toast(
        _ title: String,
        image: ContextMenuImage?,
        in view: UIView,
        isDestructive: Bool = false,
        isEnabled: Bool = true
    ) -> ContextMenuAction {
        ContextMenuAction(
            title: title,
            image: image,
            isDestructive: isDestructive,
            isEnabled: isEnabled
        ) { [weak view] in
            guard let view else {
                return
            }
            Toast.show(title, in: view)
        }
    }
}
