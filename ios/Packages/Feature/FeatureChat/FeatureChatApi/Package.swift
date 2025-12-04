// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "FeatureChatApi",
    platforms: [ .iOS(.v17) ],
    products: [ .library(name: "FeatureChatApi", targets: ["FeatureChatApi"]) ],
    dependencies: [
        .package(name: "LibraryChatUI", path: "../../Library/ChatUI"),
        .package(name: "LibraryThemeKit", path: "../../Library/ThemeKit")
    ],
    targets: [
        .target(
            name: "FeatureChatApi",
            dependencies: [
                .product(name: "LibraryChatUI", package: "LibraryChatUI"),
                .product(name: "ThemeKit", package: "LibraryThemeKit")
            ],
            path: "Sources"
        )
    ]
)
