// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "DomainHealth",
    platforms: [
        .iOS(.v17)
    ],
    products: [
        .library(
            name: "DomainHealth",
            targets: ["DomainHealth"]
        )
    ],
    dependencies: [
        .package(name: "LibraryBase", path: "../../../Library/Base"),
        .package(name: "LibraryServiceLoader", path: "../../../Library/ServiceLoader"),
        .package(name: "LibraryNetworking", path: "../../../Library/Networking"),
    ],
    targets: [
        .target(
            name: "DomainHealth",
            dependencies: [
                .product(name: "LibraryBase", package: "LibraryBase"),
                .product(name: "LibraryServiceLoader", package: "LibraryServiceLoader"),
                .product(name: "LibraryNetworking", package: "LibraryNetworking"),
            ],
            path: "Sources",
            linkerSettings: [
                .linkedFramework("HealthKit")
            ]
        )
    ]
)
