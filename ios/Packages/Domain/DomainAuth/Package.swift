// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "DomainAuth",
    platforms: [ .iOS(.v17) ],
    products: [ .library(name: "DomainAuth", targets: ["DomainAuth"]) ],
    dependencies: [
        .package(name: "LibraryServiceLoader", path: "../../Library/ServiceLoader"),
        .package(name: "LibraryNetworking", path: "../../Library/Networking")
    ],
    targets: [
        .target(
            name: "DomainAuth",
            dependencies: [
                .product(name: "LibraryServiceLoader", package: "LibraryServiceLoader"),
                .product(name: "LibraryNetworking", package: "LibraryNetworking")
            ],
            path: "Sources"
        )
    ]
)
