// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "FeatureAccountImpl",
    platforms: [ .iOS(.v17) ],
    products: [ .library(name: "FeatureAccountImpl", targets: ["FeatureAccountImpl"]) ],
    dependencies: [
        .package(name: "FeatureAccountApi", path: "../FeatureAccountApi"),
        .package(name: "LibraryServiceLoader", path: "../../../Library/ServiceLoader"),
        .package(name: "DomainAuth", path: "../../../Domain/DomainAuth"),
        .package(name: "DomainOnboarding", path: "../../../Domain/Onboarding")
    ],
    targets: [
        .target(
            name: "FeatureAccountImpl",
            dependencies: [
                .product(name: "FeatureAccountApi", package: "FeatureAccountApi"),
                .product(name: "LibraryServiceLoader", package: "LibraryServiceLoader"),
                .product(name: "DomainAuth", package: "DomainAuth"),
                .product(name: "DomainOnboarding", package: "DomainOnboarding")
            ],
            path: "Sources"
        )
    ]
)
