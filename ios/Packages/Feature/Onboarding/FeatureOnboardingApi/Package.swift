// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "FeatureOnboardingApi",
    platforms: [ .iOS(.v17) ],
    products: [ .library(name: "FeatureOnboardingApi", targets: ["FeatureOnboardingApi"]) ],
    targets: [
        .target(
            name: "FeatureOnboardingApi",
            path: "Sources"
        )
    ]
)
