// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "FeatureAccountImpl",
    platforms: [ .iOS(.v17) ],
    products: [ .library(name: "FeatureAccountImpl", targets: ["FeatureAccountImpl"]) ],
    dependencies: [
        .package(name: "FeatureAccountApi", path: "../FeatureAccountApi"),
        .package(name: "LibraryBase", path: "../../../Library/Base"),
        .package(name: "LibraryServiceLoader", path: "../../../Library/ServiceLoader"),
        .package(name: "DomainAuth", path: "../../../Domain/DomainAuth"),
        .package(name: "DomainHealth", path: "../../../Domain/Health"),
        .package(name: "FeatureOnboardingApi", path: "../../Onboarding/FeatureOnboardingApi"),
        .package(name: "FeatureDebugToolsApi", path: "../../DebugTools/FeatureDebugToolsApi"),
        .package(name: "FeatureAgendaApi", path: "../../Agenda/FeatureAgendaApi"),
        .package(name: "ThemeKit", path: "../../../Library/ThemeKit")
    ],
    targets: [
        .target(
            name: "FeatureAccountImpl",
            dependencies: [
                .product(name: "FeatureAccountApi", package: "FeatureAccountApi"),
                .product(name: "LibraryBase", package: "LibraryBase"),
                .product(name: "LibraryServiceLoader", package: "LibraryServiceLoader"),
                .product(name: "DomainAuth", package: "DomainAuth"),
                .product(name: "DomainHealth", package: "DomainHealth"),
                .product(name: "FeatureOnboardingApi", package: "FeatureOnboardingApi"),
                .product(name: "FeatureDebugToolsApi", package: "FeatureDebugToolsApi"),
                .product(name: "FeatureAgendaApi", package: "FeatureAgendaApi"),
                .product(name: "ThemeKit", package: "ThemeKit")
            ],
            path: "Sources"
        )
    ]
)
