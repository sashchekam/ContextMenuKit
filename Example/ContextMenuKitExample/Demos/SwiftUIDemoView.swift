import ContextMenuKit
import SwiftUI

/// SwiftUI views with the `contextMenuInteraction` modifier:
/// - a card whose "More" button presents the menu through the `isPresented` binding and whose text expands
///   on its own, so the hosted view follows the size of its content. Its menu starts with a SwiftUI custom item
///   that picks the color of the card;
/// - chat bubbles with leading and trailing menus that hide behind the bars on the way back,
///   with a SwiftUI bar of reactions above the bubble. Outgoing bubbles start their menu with a selectable
///   SwiftUI row: it highlights and closes the menu like an action.
///
/// The modifier needs iOS 16, so on iOS 15 the demo list hides this screen, see ``Demo/available``.
@available(iOS 16.0, *)
struct SwiftUIDemoView: View {
    private enum Constants {
        static let bubbleSpacing: CGFloat = 6
        static let bubbleInset: CGFloat = 12
        /// Keeps bubbles narrower than the screen, like in the UIKit chat.
        static let bubbleOppositeInset: CGFloat = 64
        static let readers = ["Anna", "Max", "Lena"]
    }

    @ObservedObject var model: SwiftUIDemoModel
    /// The visible part of the scroll view in window coordinates: previews are clipped to it on the way back.
    @State private var messagesFrame: CGRect?

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: Constants.bubbleSpacing) {
                    SwiftUIDemoCard()
                        .contextMenuInteraction(isPresented: $model.isCardMenuPresented, alignment: .trailing) {
                            ContextMenuSection {
                                ContextMenuCustomItem { menu in
                                    SwiftUIDemoColorPicker(menu: menu)
                                }
                            }
                            action("Edit", image: .edit)
                            action("Share", image: .share)
                            action("Duplicate", image: .duplicate)
                            ContextMenuSection {
                                action("Delete", image: .delete, isDestructive: true)
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.bottom, 12)

                    ForEach(ChatMessage.samples.indices, id: \.self) { index in
                        messageRow(for: ChatMessage.samples[index])
                    }
                }
                .padding(.vertical, 12)
            }
            .background {
                GeometryReader { proxy in
                    Color.clear
                        .onAppear { messagesFrame = proxy.frame(in: .global) }
                        .onChange(of: proxy.frame(in: .global)) { messagesFrame = $0 }
                }
            }

            SwiftUIDemoInputPanel()
        }
        .environmentObject(model)
    }

    private func messageRow(for message: ChatMessage) -> some View {
        HStack(spacing: 0) {
            if message.isOutgoing {
                Spacer(minLength: Constants.bubbleOppositeInset)
            }
            SwiftUIDemoBubble(message: message)
                .contextMenuInteraction(
                    alignment: message.isOutgoing ? .trailing : .leading,
                    clipping: .rect { messagesFrame ?? .infinite },
                    accessories: [
                        ContextMenuAccessory(placement: .above(.preview), scrollBehavior: .staysVisible) { menu in
                            SwiftUIDemoReactions(menu: menu)
                        }
                    ]
                ) {
                    if message.isOutgoing {
                        ContextMenuSection {
                            // Selectable: the whole row highlights and works like an action.
                            ContextMenuCustomItem { [model] in
                                model.showToast("Seen by \(Constants.readers.formatted(.list(type: .and)))")
                            } content: {
                                SwiftUIDemoSeenByRow(names: Constants.readers)
                            }
                        }
                    }
                    ContextMenuSection {
                        action("Reply", image: .reply)
                        action("Copy", image: .copy)
                        action("Forward", image: .forward)
                    }
                    ContextMenuSection {
                        if message.isOutgoing {
                            action("Edit", image: .edit)
                        }
                        action("Delete", image: .delete, isDestructive: true)
                    }
                }
            if !message.isOutgoing {
                Spacer(minLength: Constants.bubbleOppositeInset)
            }
        }
        .padding(.horizontal, Constants.bubbleInset)
    }

    private func action(_ title: String, image: ContextMenuSystemImage, isDestructive: Bool = false) -> ContextMenuAction {
        ContextMenuAction(title: title, image: .system(image), isDestructive: isDestructive) { [model] in
            model.showToast(title)
        }
    }
}

/// A card with a "More" button and text that expands. Reads the model from the environment,
/// which reaches it through the hosting controller of the modifier.
private struct SwiftUIDemoCard: View {
    private enum Constants {
        static let summary = "A SwiftUI view. Its ⋯ button sets the isPresented binding of the modifier."
        static let details = " The view lives in its own hosting controller: environment objects reach it, "
            + "and when this text expands, the view around it grows too. Long-press the card while it is expanded "
            + "to see the new size in the preview."
    }

    @EnvironmentObject private var model: SwiftUIDemoModel
    @State private var isExpanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top) {
                Text("Tap ⋯ or long-press the card")
                    .font(.headline)
                Spacer(minLength: 8)
                Button {
                    model.isCardMenuPresented = true
                } label: {
                    Image(systemName: "ellipsis.circle.fill")
                        .font(.title2)
                }
                .accessibilityLabel("More")
            }
            Text(isExpanded ? Constants.summary + Constants.details : Constants.summary)
                .font(.subheadline)
                .fixedSize(horizontal: false, vertical: true)
            Button(isExpanded ? "Show less" : "Show more") {
                isExpanded.toggle()
            }
            .font(.subheadline.weight(.semibold))
        }
        .foregroundStyle(.white)
        .tint(.white)
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(model.cardColor, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

/// An interactive custom item of the card menu: color swatches. Reads the model from the environment,
/// which reaches the item through the modifier, and closes the menu through the proxy.
/// The card changes its color once the menu is gone.
private struct SwiftUIDemoColorPicker: View {
    private struct Swatch {
        let name: String
        let color: Color
    }

    private enum Constants {
        static let swatches = [
            Swatch(name: "Purple", color: .purple),
            Swatch(name: "Blue", color: .blue),
            Swatch(name: "Green", color: .green),
            Swatch(name: "Orange", color: .orange),
            Swatch(name: "Pink", color: .pink)
        ]
        static let swatchSize: CGFloat = 32
    }

    let menu: ContextMenuProxy
    @EnvironmentObject private var model: SwiftUIDemoModel

    var body: some View {
        HStack(spacing: 0) {
            ForEach(Constants.swatches, id: \.name) { swatch in
                Button {
                    menu.dismiss { [model] in
                        model.cardColor = swatch.color
                    }
                } label: {
                    Circle()
                        .fill(swatch.color)
                        .frame(width: Constants.swatchSize, height: Constants.swatchSize)
                        .overlay {
                            if swatch.color == model.cardColor {
                                Image(systemName: "checkmark")
                                    .font(.footnote.weight(.bold))
                                    .foregroundStyle(.white)
                            }
                        }
                }
                .frame(maxWidth: .infinity)
                .accessibilityLabel(swatch.name)
                .accessibilityAddTraits(swatch.color == model.cardColor ? .isSelected : [])
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 12)
    }
}

/// Reactions above a bubble: an accessory with a SwiftUI view. Reads the model from the environment,
/// which reaches the accessory through the modifier, and closes the menu through the proxy.
private struct SwiftUIDemoReactions: View {
    private enum Constants {
        static let reactions = ["❤️", "👍", "😂", "😮", "😢", "🔥"]
        static let buttonSize: CGFloat = 40
        static let emojiSize: CGFloat = 26
        static let inset: CGFloat = 4
    }

    let menu: ContextMenuProxy
    @EnvironmentObject private var model: SwiftUIDemoModel

    var body: some View {
        HStack(spacing: 0) {
            ForEach(Constants.reactions, id: \.self) { reaction in
                Button {
                    menu.dismiss { [model] in
                        model.showToast("Reacted with \(reaction)")
                    }
                } label: {
                    Text(reaction)
                        .font(.system(size: Constants.emojiSize))
                        .frame(width: Constants.buttonSize, height: Constants.buttonSize)
                }
                .accessibilityLabel(reaction)
            }
        }
        .padding(Constants.inset)
        .background(Color(uiColor: .secondarySystemGroupedBackground), in: Capsule())
    }
}

/// Content of a selectable custom item: who has seen a message, with avatars on the trailing side.
/// The SwiftUI counterpart of the UIKit ``SeenByRowView``.
private struct SwiftUIDemoSeenByRow: View {
    private enum Constants {
        static let avatarSize: CGFloat = 28
        static let avatarOverlap: CGFloat = 6
        static let avatarColors: [Color] = [.blue, .green, .pink, .orange]
    }

    let names: [String]

    var body: some View {
        HStack(spacing: 8) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Seen by \(names.count) people")
                    .font(.body)
                Text(names.formatted(.list(type: .and)))
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            // Takes the rest of the row. A `Spacer` here would add the spacing of the stack twice.
            .frame(maxWidth: .infinity, alignment: .leading)
            HStack(spacing: -Constants.avatarOverlap) {
                ForEach(names.indices, id: \.self) { index in
                    Text(names[index].prefix(1))
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(width: Constants.avatarSize, height: Constants.avatarSize)
                        .background(Constants.avatarColors[index % Constants.avatarColors.count], in: Circle())
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }
}

private struct SwiftUIDemoBubble: View {
    let message: ChatMessage

    var body: some View {
        Text(message.text)
            .font(.body)
            .foregroundStyle(message.isOutgoing ? Color.white : Color.primary)
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .background(
                message.isOutgoing ? Color.blue : Color(uiColor: .secondarySystemBackground),
                in: RoundedRectangle(cornerRadius: 18, style: .continuous)
            )
    }
}

/// Fake input panel at the bottom: only marks the area the preview must not fly over.
private struct SwiftUIDemoInputPanel: View {
    var body: some View {
        Text("Message")
            .foregroundStyle(Color(uiColor: .placeholderText))
            .padding(.horizontal, 12)
            .frame(maxWidth: .infinity, minHeight: 36, alignment: .leading)
            .background(Color(uiColor: .systemBackground), in: Capsule())
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color(uiColor: .secondarySystemBackground), ignoresSafeAreaEdges: .bottom)
    }
}
