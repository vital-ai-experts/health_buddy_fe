// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "DomainOnboarding",
    platforms: [ .iOS(.v17) ],
    products: [ .library(name: "DomainOnboarding", targets: ["DomainOnboarding"]) ],
    dependencies: [
        .package(name: "LibraryBase", path: "../../Library/Base"),
        .package(name: "LibraryServiceLoader", path: "../../Library/ServiceLoader"),
        .package(name: "LibraryNetworking", path: "../../Library/Networking"),
        .package(name: "DomainChat", path: "../DomainChat")
    ],
    targets: [
        .target(
            name: "DomainOnboarding",
            dependencies: [
                .product(name: "LibraryBase", package: "LibraryBase"),
                .product(name: "LibraryServiceLoader", package: "LibraryServiceLoader"),
                .product(name: "LibraryNetworking", package: "LibraryNetworking"),
                .product(name: "DomainChat", package: "DomainChat")
            ],
            path: "Sources"
        )
    ]
)
