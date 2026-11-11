/// Horizontal alignment of the menu relative to the preview.
public enum ContextMenuAlignment: Sendable {
    /// Aligns the menu with the preview edge that is closer to the window edge:
    /// a preview in the left half of the window gets a left-aligned menu, a preview
    /// in the right half — a right-aligned one. A centered preview uses the leading edge.
    case automatic
    /// Aligns the menu with the leading edge of the preview.
    case leading
    /// Aligns the menu with the trailing edge of the preview.
    case trailing
}
