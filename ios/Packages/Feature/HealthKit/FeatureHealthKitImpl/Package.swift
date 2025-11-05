// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "FeatureHealthKitImpl",
    platforms: [ .iOS(.v17) ],
    products: [ .library(name: "FeatureHealthKitImpl", targets: ["FeatureHealthKitImpl"]) ],
    dependencies: [
        .package(name: "FeatureHealthKitApi", path: "../FeatureHealthKitApi"),
        .package(name: "LibraryServiceLoader", path: "../../../Library/ServiceLoader"),
        .package(name: "DomainHealth", path: "../../../Domain/Health"),
        .package(url: "https://github.com/carekit-apple/CareKit.git", exact: "2.0.2")
    ],
    targets: [
        .target(
            name: "FeatureHealthKitImpl",
            dependencies: [
                .product(name: "FeatureHealthKitApi", package: "FeatureHealthKitApi"),
                .product(name: "LibraryServiceLoader", package: "LibraryServiceLoader"),
                .product(name: "DomainHealth", package: "DomainHealth"),
                .product(name: "CareKitUI", package: "CareKit")
            ],
            path: "Sources"
        )
    ]
)
