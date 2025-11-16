// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "LibraryBase",
    platforms: [ .iOS(.v17) ],
    products: [ .library(name: "LibraryBase", targets: ["LibraryBase"]) ],
    targets: [
        .target(
            name: "LibraryBase",
            path: "Sources"
        )
    ]
)
