// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "FeatureOnboardingImpl",
    platforms: [ .iOS(.v17) ],
    products: [ .library(name: "FeatureOnboardingImpl", targets: ["FeatureOnboardingImpl"]) ],
    dependencies: [
        .package(name: "FeatureOnboardingApi", path: "../FeatureOnboardingApi"),
        .package(name: "FeatureAgendaApi", path: "../../Agenda/FeatureAgendaApi"),
        .package(name: "FeatureChatApi", path: "../../FeatureChat/FeatureChatApi"),
        .package(name: "DomainHealth", path: "../../Domain/Health"),
        .package(name: "LibraryBase", path: "../../../Library/Base"),
        .package(name: "LibraryChatUI", path: "../../../Library/ChatUI"),
        .package(name: "LibraryServiceLoader", path: "../../../Library/ServiceLoader"),
        .package(name: "LibraryThemeKit", path: "../../../Library/ThemeKit")
    ],
    targets: [
        .target(
            name: "FeatureOnboardingImpl",
            dependencies: [
                .product(name: "FeatureOnboardingApi", package: "FeatureOnboardingApi"),
                .product(name: "FeatureAgendaApi", package: "FeatureAgendaApi"),
                .product(name: "FeatureChatApi", package: "FeatureChatApi"),
                .product(name: "DomainHealth", package: "DomainHealth"),
                .product(name: "LibraryBase", package: "LibraryBase"),
                .product(name: "LibraryChatUI", package: "LibraryChatUI"),
                .product(name: "LibraryServiceLoader", package: "LibraryServiceLoader"),
                .product(name: "ThemeKit", package: "LibraryThemeKit")
            ],
            path: "Sources"
        )
    ]
)
