// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "FeatureAgendaApi",
    platforms: [ .iOS(.v17) ],
    products: [ .library(name: "FeatureAgendaApi", targets: ["FeatureAgendaApi"]) ],
    targets: [
        .target(
            name: "FeatureAgendaApi",
            path: "Sources"
        )
    ]
)
