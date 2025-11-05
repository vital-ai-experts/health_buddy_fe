// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "FeatureHealthKitApi",
    platforms: [ .iOS(.v17) ],
    products: [ .library(name: "FeatureHealthKitApi", targets: ["FeatureHealthKitApi"]) ],
    targets: [
        .target(
            name: "FeatureHealthKitApi",
            path: "Sources"
        )
    ]
)
