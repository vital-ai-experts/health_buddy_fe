// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "LibraryNotification",
    platforms: [ .iOS(.v17) ],
    products: [ .library(name: "LibraryNotification", targets: ["LibraryNotification"]) ],
    dependencies: [
        .package(name: "LibraryBase", path: "../Base"),
        .package(name: "LibraryTrack", path: "../Track"),
        .package(name: "LibraryNetworking", path: "../Networking")
    ],
    targets: [
        .target(
            name: "LibraryNotification",
            dependencies: [
                .product(name: "LibraryBase", package: "LibraryBase"),
                .product(name: "LibraryTrack", package: "LibraryTrack"),
                .product(name: "LibraryNetworking", package: "LibraryNetworking")
            ],
            path: "Sources"
        )
    ]
)
