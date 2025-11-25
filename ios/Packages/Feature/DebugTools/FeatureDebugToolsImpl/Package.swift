// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "FeatureDebugToolsImpl",
    platforms: [ .iOS(.v17) ],
    products: [ .library(name: "FeatureDebugToolsImpl", targets: ["FeatureDebugToolsImpl"]) ],
    dependencies: [
        .package(name: "FeatureDebugToolsApi", path: "../FeatureDebugToolsApi"),
        .package(name: "LibraryBase", path: "../../../Library/Base"),
        .package(name: "LibraryServiceLoader", path: "../../../Library/ServiceLoader"),
        .package(name: "LibraryNotification", path: "../../../Library/Notification"),
        .package(name: "FeatureOnboardingApi", path: "../../Onboarding/FeatureOnboardingApi"),
        .package(name: "FeatureChatImpl", path: "../../FeatureChat/FeatureChatImpl"),
        .package(name: "DomainAuth", path: "../../../Domain/DomainAuth")
    ],
    targets: [
        .target(
            name: "FeatureDebugToolsImpl",
            dependencies: [
                .product(name: "FeatureDebugToolsApi", package: "FeatureDebugToolsApi"),
                .product(name: "LibraryBase", package: "LibraryBase"),
                .product(name: "LibraryServiceLoader", package: "LibraryServiceLoader"),
                .product(name: "LibraryNotification", package: "LibraryNotification"),
                .product(name: "FeatureOnboardingApi", package: "FeatureOnboardingApi"),
                .product(name: "FeatureChatImpl", package: "FeatureChatImpl"),
                .product(name: "DomainAuth", package: "DomainAuth")
            ],
            path: "Sources"
        )
    ]
)
