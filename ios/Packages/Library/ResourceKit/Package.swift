// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "ResourceKit",
    platforms: [ .iOS(.v17) ],
    products: [ .library(name: "ResourceKit", targets: ["ResourceKit"]) ],
    targets: [
        .target(
            name: "ResourceKit",
            path: "Sources",
            resources: [
                .process("ResourceKit/Resources")
            ]
        )
    ]
)
