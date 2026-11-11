import UIKit

/// A file of the Files demo.
struct DemoFile {
    enum Kind {
        case document
        case image
        case audio
        case archive

        var symbolName: String {
            switch self {
            case .document:
                "doc.text.fill"
            case .image:
                "photo.fill"
            case .audio:
                "waveform"
            case .archive:
                "doc.zipper"
            }
        }

        var color: UIColor {
            switch self {
            case .document:
                .systemBlue
            case .image:
                .systemOrange
            case .audio:
                .systemPink
            case .archive:
                .systemGray
            }
        }

        var typeName: String {
            switch self {
            case .document:
                "PDF"
            case .image:
                "JPEG"
            case .audio:
                "M4A"
            case .archive:
                "ZIP"
            }
        }
    }

    static let samples = [
        DemoFile(name: "Quarterly report", kind: .document, size: "2.4 MB", isPinned: true),
        DemoFile(name: "Beach", kind: .image, size: "3.1 MB", isFavorite: true),
        DemoFile(name: "Voice memo", kind: .audio, size: "860 KB"),
        DemoFile(name: "Design assets", kind: .archive, size: "48 MB"),
        DemoFile(name: "Mountains", kind: .image, size: "4.7 MB"),
        DemoFile(name: "Meeting notes", kind: .document, size: "120 KB"),
        DemoFile(name: "Podcast intro", kind: .audio, size: "5.2 MB", isFavorite: true),
        DemoFile(name: "Recipes", kind: .document, size: "96 KB"),
        DemoFile(name: "Photo backup", kind: .archive, size: "1.2 GB"),
        DemoFile(name: "City at night", kind: .image, size: "2.9 MB"),
        DemoFile(name: "Trip plan", kind: .document, size: "310 KB"),
        DemoFile(name: "Birdsong", kind: .audio, size: "1.8 MB")
    ]

    let id = UUID()
    var name: String
    var kind: Kind
    var size: String
    var isFavorite = false
    var isPinned = false

    var details: String {
        "\(kind.typeName) · \(size)"
    }

    /// A new file with the same content and a new identifier.
    func copy() -> DemoFile {
        DemoFile(name: "\(name) copy", kind: kind, size: size)
    }
}
