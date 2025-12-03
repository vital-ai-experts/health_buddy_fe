// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "FeatureChatImpl",
    platforms: [ .iOS(.v17) ],
    products: [ .library(name: "FeatureChatImpl", targets: ["FeatureChatImpl"]) ],
    dependencies: [
        .package(name: "FeatureChatApi", path: "../FeatureChatApi"),
        .package(name: "FeatureAgendaApi", path: "../../Agenda/FeatureAgendaApi"),
        .package(name: "LibraryBase", path: "../../../Library/Base"),
        .package(name: "LibraryServiceLoader", path: "../../../Library/ServiceLoader"),
        .package(name: "LibraryNotification", path: "../../../Library/Notification"),
        .package(name: "ResourceKit", path: "../../../Library/ResourceKit"),
        .package(name: "LibraryChatUI", path: "../../../Library/ChatUI"),
        .package(name: "LibraryNetworking", path: "../../../Library/Networking")
    ],
    targets: [
        .target(
            name: "FeatureChatImpl",
            dependencies: [
                .product(name: "FeatureChatApi", package: "FeatureChatApi"),
                .product(name: "FeatureAgendaApi", package: "FeatureAgendaApi"),
                .product(name: "LibraryBase", package: "LibraryBase"),
                .product(name: "LibraryServiceLoader", package: "LibraryServiceLoader"),
                .product(name: "LibraryNotification", package: "LibraryNotification"),
                .product(name: "ResourceKit", package: "ResourceKit"),
                .product(name: "LibraryChatUI", package: "LibraryChatUI"),
                .product(name: "LibraryNetworking", package: "LibraryNetworking")
            ],
            path: "Sources"
        )
    ]
)
