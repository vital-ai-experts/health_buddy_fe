// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "LibraryNotification",
    platforms: [ .iOS(.v17) ],
    products: [ .library(name: "LibraryNotification", targets: ["LibraryNotification"]) ],
    targets: [
        .target(
            name: "LibraryNotification",
            path: "Sources"
        )
    ]
)
