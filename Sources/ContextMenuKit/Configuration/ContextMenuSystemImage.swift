/// SF Symbols for common context menu actions. The raw value is the symbol name.
///
/// Every symbol is available on iOS 15. For any other symbol use
/// ``ContextMenuImage/custom(_:)`` with `UIImage(systemName:)`.
public enum ContextMenuSystemImage: String, CaseIterable, Sendable {
    case reply = "arrowshape.turn.up.left"
    case forward = "arrowshape.turn.up.right"
    case copy = "doc.on.doc"
    case edit = "pencil"
    case delete = "trash"
    case share = "square.and.arrow.up"
    case save = "square.and.arrow.down"
    case duplicate = "plus.square.on.square"
    case favorite = "star"
    case unfavorite = "star.slash"
    case bookmark = "bookmark"
    case pin = "pin"
    case unpin = "pin.slash"
    case link = "link"
    case info = "info.circle"
    case flag = "flag"
    case show = "eye"
    case hide = "eye.slash"
    case mute = "bell.slash"
    case unmute = "bell"
    case archive = "archivebox"
    case move = "folder"
    case translate = "character.bubble"
    case select = "checkmark.circle"
    case markAsRead = "envelope.open"
    case markAsUnread = "envelope.badge"
    case more = "ellipsis.circle"
}
