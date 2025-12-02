// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "LibraryChatUI",
    platforms: [ .iOS(.v17) ],
    products: [ .library(name: "LibraryChatUI", targets: ["LibraryChatUI"]) ],
    dependencies: [
        .package(name: "LibraryBase", path: "../Base"),
        .package(name: "ThemeKit", path: "../ThemeKit")
    ],
    targets: [
        .target(
            name: "LibraryChatUI",
            dependencies: [
                .product(name: "LibraryBase", package: "LibraryBase"),
                .product(name: "ThemeKit", package: "ThemeKit")
            ],
            path: "Sources"
        )
    ]
)
