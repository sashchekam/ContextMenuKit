import Foundation
import Testing
import UIKit

/// Compares a rendered view with its reference PNG pixel by pixel.
///
/// References live in `__Snapshots__/<test file name>/<test function>.<name>.png` next to the test file.
/// A missing reference is recorded and the test fails, so the second run must pass.
/// On a mismatch the rendered image is attached to the test report.
@MainActor
func expectSnapshot(
    of view: UIView,
    named name: String,
    interfaceStyle: UIUserInterfaceStyle = .light,
    filePath: String = #filePath,
    function: String = #function,
    sourceLocation: SourceLocation = #_sourceLocation
) {
    let image = ViewSnapshot.render(view, interfaceStyle: interfaceStyle)
    let referenceURL = ViewSnapshot.referenceURL(filePath: filePath, function: function, name: name)

    guard let reference = UIImage(contentsOfFile: referenceURL.path) else {
        ViewSnapshot.record(image, at: referenceURL, sourceLocation: sourceLocation)
        return
    }
    guard !ViewSnapshot.hasSamePixels(image, reference) else {
        return
    }
    Issue.record("Snapshot doesn't match the reference \(referenceURL.path)", sourceLocation: sourceLocation)
    if let data = image.pngData() {
        Attachment.record(data, named: "\(referenceURL.deletingPathExtension().lastPathComponent).actual.png")
    }
}

@MainActor
private enum ViewSnapshot {
    static func render(_ view: UIView, interfaceStyle: UIUserInterfaceStyle) -> UIImage {
        // Trait overrides reach a view only inside a window. A scene-less window is enough for rendering.
        let window = UIWindow(frame: view.bounds)
        window.overrideUserInterfaceStyle = interfaceStyle
        window.addSubview(view)
        defer { view.removeFromSuperview() }
        window.layoutIfNeeded()

        let format = UIGraphicsImageRendererFormat.preferred()
        format.preferredRange = .standard
        return UIGraphicsImageRenderer(bounds: view.bounds, format: format).image { context in
            view.traitCollection.performAsCurrent {
                view.layer.render(in: context.cgContext)
            }
        }
    }

    static func referenceURL(filePath: String, function: String, name: String) -> URL {
        let testFileURL = URL(fileURLWithPath: filePath)
        let testName = function
            .replacingOccurrences(of: "\\W+", with: "-", options: .regularExpression)
            .trimmingCharacters(in: CharacterSet(charactersIn: "-"))
        return testFileURL
            .deletingLastPathComponent()
            .appendingPathComponent("__Snapshots__")
            .appendingPathComponent(testFileURL.deletingPathExtension().lastPathComponent)
            .appendingPathComponent("\(testName).\(name).png")
    }

    static func record(_ image: UIImage, at url: URL, sourceLocation: SourceLocation) {
        do {
            try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
            try image.pngData()?.write(to: url)
            Issue.record("Recorded a new reference \(url.path). Check it and run the test again.", sourceLocation: sourceLocation)
        } catch {
            Issue.record(error, "Couldn't record a reference at \(url.path)", sourceLocation: sourceLocation)
        }
    }

    static func hasSamePixels(_ lhs: UIImage, _ rhs: UIImage) -> Bool {
        guard let lhsPixels = lhs.cgImage.flatMap(pixels(of:)), let rhsPixels = rhs.cgImage.flatMap(pixels(of:)) else {
            return false
        }
        return lhsPixels == rhsPixels
    }

    /// Draws the image into an 8-bit sRGB buffer, so PNGs with different encodings compare equal.
    private static func pixels(of image: CGImage) -> Pixels? {
        let bytesPerRow = image.width * 4
        var bytes = [UInt8](repeating: 0, count: bytesPerRow * image.height)
        let isDrawn = bytes.withUnsafeMutableBytes { buffer in
            guard let context = CGContext(
                data: buffer.baseAddress,
                width: image.width,
                height: image.height,
                bitsPerComponent: 8,
                bytesPerRow: bytesPerRow,
                space: CGColorSpace(name: CGColorSpace.sRGB) ?? CGColorSpaceCreateDeviceRGB(),
                bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
            ) else {
                return false
            }
            context.draw(image, in: CGRect(x: 0, y: 0, width: image.width, height: image.height))
            return true
        }
        return isDrawn ? Pixels(width: image.width, height: image.height, bytes: bytes) : nil
    }
}

private struct Pixels: Equatable {
    let width: Int
    let height: Int
    let bytes: [UInt8]
}
