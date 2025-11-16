// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "LibraryTrack",
    platforms: [ .iOS(.v17) ],
    products: [ .library(name: "LibraryTrack", targets: ["LibraryTrack"]) ],
    dependencies: [
        .package(path: "../Networking"),
        .package(path: "../Base")
    ],
    targets: [
        .target(
            name: "LibraryTrack",
            dependencies: [
                .product(name: "LibraryNetworking", package: "Networking"),
                .product(name: "LibraryBase", package: "Base")
            ],
            path: "Sources"
        )
    ]
)
