// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "FeatureOnboardingImpl",
    platforms: [ .iOS(.v17) ],
    products: [ .library(name: "FeatureOnboardingImpl", targets: ["FeatureOnboardingImpl"]) ],
    dependencies: [
        .package(name: "FeatureOnboardingApi", path: "../FeatureOnboardingApi"),
        .package(name: "LibraryBase", path: "../../../Library/Base"),
        .package(name: "LibraryServiceLoader", path: "../../../Library/ServiceLoader"),
        .package(name: "LibraryThemeKit", path: "../../../Library/ThemeKit")
    ],
    targets: [
        .target(
            name: "FeatureOnboardingImpl",
            dependencies: [
                .product(name: "FeatureOnboardingApi", package: "FeatureOnboardingApi"),
                .product(name: "LibraryBase", package: "LibraryBase"),
                .product(name: "LibraryServiceLoader", package: "LibraryServiceLoader"),
                .product(name: "ThemeKit", package: "LibraryThemeKit")
            ],
            path: "Sources"
        )
    ]
)
