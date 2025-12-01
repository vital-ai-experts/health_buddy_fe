// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "FeatureAgendaImpl",
    platforms: [ .iOS(.v17) ],
    products: [ .library(name: "FeatureAgendaImpl", targets: ["FeatureAgendaImpl"]) ],
    dependencies: [
        .package(name: "FeatureAgendaApi", path: "../FeatureAgendaApi"),
        .package(name: "LibraryBase", path: "../../../Library/Base"),
        .package(name: "LibraryServiceLoader", path: "../../../Library/ServiceLoader"),
        .package(name: "LibraryNotification", path: "../../../Library/Notification"),
        .package(name: "ThemeKit", path: "../../../Library/ThemeKit")
    ],
    targets: [
        .target(
            name: "FeatureAgendaImpl",
            dependencies: [
                .product(name: "FeatureAgendaApi", package: "FeatureAgendaApi"),
                .product(name: "LibraryBase", package: "LibraryBase"),
                .product(name: "LibraryServiceLoader", package: "LibraryServiceLoader"),
                .product(name: "LibraryNotification", package: "LibraryNotification"),
                .product(name: "ThemeKit", package: "ThemeKit")
            ],
            path: "Sources"
        )
    ]
)
