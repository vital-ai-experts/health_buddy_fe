// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "LibraryNetworking",
    platforms: [ .iOS(.v17) ],
    products: [ .library(name: "LibraryNetworking", targets: ["LibraryNetworking"]) ],
    targets: [
        .target(
            name: "LibraryNetworking",
            path: "Sources"
        )
    ]
)
