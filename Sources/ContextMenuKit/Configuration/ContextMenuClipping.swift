import CoreGraphics

/// Describes where the source view is visible, so that on its way back the preview
/// doesn't fly over navigation bars, input panels and other chrome.
public enum ContextMenuClipping {
    /// The preview is never clipped.
    case none
    /// While flying back, the preview is clipped to the rect returned by the closure.
    /// The rect is in window coordinates and is requested when the dismissal starts.
    case rect(@MainActor () -> CGRect)
}
