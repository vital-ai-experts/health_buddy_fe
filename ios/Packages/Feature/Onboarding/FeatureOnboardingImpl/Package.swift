// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "FeatureOnboardingImpl",
    platforms: [ .iOS(.v17) ],
    products: [ .library(name: "FeatureOnboardingImpl", targets: ["FeatureOnboardingImpl"]) ],
    dependencies: [
        .package(name: "FeatureOnboardingApi", path: "../FeatureOnboardingApi"),
        .package(name: "LibraryServiceLoader", path: "../../../Library/ServiceLoader"),
        .package(name: "DomainOnboarding", path: "../../../Domain/Onboarding"),
        .package(name: "DomainChat", path: "../../../Domain/DomainChat"),
        .package(name: "LibraryChatUI", path: "../../../Library/ChatUI"),
        .package(name: "DomainHealth", path: "../../../Domain/Health")
    ],
    targets: [
        .target(
            name: "FeatureOnboardingImpl",
            dependencies: [
                .product(name: "FeatureOnboardingApi", package: "FeatureOnboardingApi"),
                .product(name: "LibraryServiceLoader", package: "LibraryServiceLoader"),
                .product(name: "DomainOnboarding", package: "DomainOnboarding"),
                .product(name: "DomainChat", package: "DomainChat"),
                .product(name: "LibraryChatUI", package: "LibraryChatUI"),
                .product(name: "DomainHealth", package: "DomainHealth")
            ],
            path: "Sources"
        )
    ]
)
