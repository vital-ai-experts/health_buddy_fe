// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "LibraryNotification",
    platforms: [ .iOS(.v17) ],
    products: [ .library(name: "LibraryNotification", targets: ["LibraryNotification"]) ],
    dependencies: [
        .package(name: "LibraryBase", path: "../Base")
    ],
    targets: [
        .target(
            name: "LibraryNotification",
            dependencies: [
                .product(name: "LibraryBase", package: "LibraryBase")
            ],
            path: "Sources"
        )
    ]
)
