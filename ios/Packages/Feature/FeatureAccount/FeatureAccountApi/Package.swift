// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "FeatureAccountApi",
    platforms: [ .iOS(.v17) ],
    products: [ .library(name: "FeatureAccountApi", targets: ["FeatureAccountApi"]) ],
    targets: [
        .target(
            name: "FeatureAccountApi",
            path: "Sources"
        )
    ]
)
