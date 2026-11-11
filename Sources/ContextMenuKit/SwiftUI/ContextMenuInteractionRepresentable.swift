import SwiftUI

/// Puts the content of the `contextMenuInteraction` modifier into a ``ContextMenuHostingController``.
@available(iOS 16.0, *)
struct ContextMenuInteractionRepresentable<Content: View>: UIViewControllerRepresentable {
    let content: Content
    let isPresented: Binding<Bool>?
    let makeConfiguration: @MainActor () -> ContextMenuConfiguration

    func makeUIViewController(context: Context) -> ContextMenuHostingController<Content> {
        ContextMenuHostingController(content: content, environmentValues: context.environment, environment: .live)
    }

    func updateUIViewController(_ controller: ContextMenuHostingController<Content>, context: Context) {
        controller.update(
            content: content,
            environmentValues: context.environment,
            isPresented: isPresented,
            makeConfiguration: makeConfiguration
        )
    }

    func sizeThatFits(
        _ proposal: ProposedViewSize,
        uiViewController controller: ContextMenuHostingController<Content>,
        context: Context
    ) -> CGSize? {
        controller.sizeThatFits(proposal)
    }

    static func dismantleUIViewController(_ controller: ContextMenuHostingController<Content>, coordinator: Void) {
        controller.dismantle()
    }
}
