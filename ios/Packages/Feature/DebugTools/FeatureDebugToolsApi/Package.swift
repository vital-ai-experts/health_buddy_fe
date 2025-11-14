// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "FeatureDebugToolsApi",
    platforms: [ .iOS(.v17) ],
    products: [ .library(name: "FeatureDebugToolsApi", targets: ["FeatureDebugToolsApi"]) ],
    targets: [
        .target(
            name: "FeatureDebugToolsApi",
            path: "Sources"
        )
    ]
)
