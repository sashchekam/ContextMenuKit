import SwiftUI
import UIKit

/// Hosts ``SwiftUIDemoView``: the SwiftUI counterpart of the Chat and More button demos.
@available(iOS 16.0, *)
final class SwiftUIDemoViewController: UIHostingController<SwiftUIDemoView>, DemoScreen {
    private let model: SwiftUIDemoModel

    init() {
        let model = SwiftUIDemoModel()
        self.model = model
        super.init(rootView: SwiftUIDemoView(model: model))
        model.showToast = { [weak self] text in
            guard let view = self?.view else {
                return
            }
            Toast.show(text, in: view)
        }
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        nil
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = Demo.swiftUI.title
        navigationItem.largeTitleDisplayMode = .never
    }

    func presentPrimaryMenu() {
        model.isCardMenuPresented = true
    }
}

/// State shared by the SwiftUI demo views.
@MainActor
final class SwiftUIDemoModel: ObservableObject {
    /// Drives the menu of the card: its "More" button sets it to `true`.
    @Published var isCardMenuPresented = false
    /// Set by the color picker in the menu of the card.
    @Published var cardColor = Color.purple
    /// Shows which action was performed. Set by the hosting screen.
    var showToast: (String) -> Void = { _ in }
}
