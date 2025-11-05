// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "LibraryServiceLoader",
    platforms: [
        .iOS(.v17)
    ],
    products: [
        .library(
            name: "LibraryServiceLoader",
            targets: ["LibraryServiceLoader"]
        )
    ],
    targets: [
        .target(
            name: "LibraryServiceLoader",
            path: "Sources"
        )
    ]
)
