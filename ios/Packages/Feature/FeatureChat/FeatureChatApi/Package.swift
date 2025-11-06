// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "FeatureChatApi",
    platforms: [ .iOS(.v17) ],
    products: [ .library(name: "FeatureChatApi", targets: ["FeatureChatApi"]) ],
    targets: [
        .target(
            name: "FeatureChatApi",
            path: "Sources"
        )
    ]
)
