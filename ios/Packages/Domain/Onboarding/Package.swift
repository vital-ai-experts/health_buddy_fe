// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "DomainOnboarding",
    platforms: [ .iOS(.v17) ],
    products: [ .library(name: "DomainOnboarding", targets: ["DomainOnboarding"]) ],
    dependencies: [
        .package(name: "LibraryServiceLoader", path: "../../Library/ServiceLoader"),
        .package(name: "LibraryNetworking", path: "../../Library/Networking")
    ],
    targets: [
        .target(
            name: "DomainOnboarding",
            dependencies: [
                .product(name: "LibraryServiceLoader", package: "LibraryServiceLoader"),
                .product(name: "LibraryNetworking", package: "LibraryNetworking")
            ],
            path: "Sources"
        )
    ]
)
