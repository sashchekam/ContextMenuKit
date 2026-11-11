// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "ContextMenuKit",
    platforms: [.iOS(.v15)],
    products: [
        .library(name: "ContextMenuKit", targets: ["ContextMenuKit"])
    ],
    targets: [
        .target(name: "ContextMenuKit"),
        .testTarget(
            name: "ContextMenuKitTests",
            dependencies: ["ContextMenuKit"],
            exclude: ["__Snapshots__"]
        )
    ]
)
