// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "FeatureChatImpl",
    platforms: [ .iOS(.v17) ],
    products: [ .library(name: "FeatureChatImpl", targets: ["FeatureChatImpl"]) ],
    dependencies: [
        .package(name: "FeatureChatApi", path: "../FeatureChatApi"),
        .package(name: "LibraryServiceLoader", path: "../../../Library/ServiceLoader"),
        .package(name: "DomainChat", path: "../../../Domain/DomainChat"),
        .package(name: "LibraryChatUI", path: "../../../Library/ChatUI")
    ],
    targets: [
        .target(
            name: "FeatureChatImpl",
            dependencies: [
                .product(name: "FeatureChatApi", package: "FeatureChatApi"),
                .product(name: "LibraryServiceLoader", package: "LibraryServiceLoader"),
                .product(name: "DomainChat", package: "DomainChat"),
                .product(name: "LibraryChatUI", package: "LibraryChatUI")
            ],
            path: "Sources"
        )
    ]
)
