// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "DomainAuth",
    platforms: [ .iOS(.v17) ],
    products: [ .library(name: "DomainAuth", targets: ["DomainAuth"]) ],
    dependencies: [
        .package(name: "LibraryBase", path: "../../Library/Base"),
        .package(name: "LibraryServiceLoader", path: "../../Library/ServiceLoader"),
        .package(name: "LibraryNetworking", path: "../../Library/Networking"),
        .package(name: "LibraryTrack", path: "../../Library/Track")
    ],
    targets: [
        .target(
            name: "DomainAuth",
            dependencies: [
                .product(name: "LibraryBase", package: "LibraryBase"),
                .product(name: "LibraryServiceLoader", package: "LibraryServiceLoader"),
                .product(name: "LibraryNetworking", package: "LibraryNetworking"),
                .product(name: "LibraryTrack", package: "LibraryTrack")
            ],
            path: "Sources"
        )
    ]
)
