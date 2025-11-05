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
        .package(name: "LibraryServiceLoader", path: "../../../Library/ServiceLoader")
    ],
    targets: [
        .target(
            name: "DomainHealth",
            dependencies: [
                .product(name: "LibraryServiceLoader", package: "LibraryServiceLoader")
            ],
            path: "Sources",
            linkerSettings: [
                .linkedFramework("HealthKit")
            ]
        )
    ]
)
