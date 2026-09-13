// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "Sonance",
    platforms: [
        .iOS(.v16)
    ],
    products: [
        .library(
            name: "SonanceCore",
            targets: ["SonanceCore"]
        )
    ],
    targets: [
        .target(
            name: "SonanceCore",
            path: "Sonance"
        )
    ]
)
