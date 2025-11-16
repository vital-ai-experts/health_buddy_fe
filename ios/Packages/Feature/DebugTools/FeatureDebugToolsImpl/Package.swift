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
        .package(name: "FeatureChatImpl", path: "../../FeatureChat/FeatureChatImpl")
    ],
    targets: [
        .target(
            name: "FeatureDebugToolsImpl",
            dependencies: [
                .product(name: "FeatureDebugToolsApi", package: "FeatureDebugToolsApi"),
                .product(name: "LibraryBase", package: "LibraryBase"),
                .product(name: "LibraryServiceLoader", package: "LibraryServiceLoader"),
                .product(name: "LibraryNotification", package: "LibraryNotification"),
                .product(name: "FeatureChatImpl", package: "FeatureChatImpl")
            ],
            path: "Sources"
        )
    ]
)
