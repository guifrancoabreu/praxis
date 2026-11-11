// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "ReaderCore",
    platforms: [.iOS(.v17), .macOS(.v13)],
    products: [.library(name: "ReaderCore", targets: ["ReaderCore"])],
    targets: [
        .target(name: "ReaderCore", path: "MarxistReader", exclude: ["MarxistReaderApp.swift"], sources: ["Catalog.swift", "DesignSystem.swift"]),
        .testTarget(name: "ReaderCoreTests", dependencies: ["ReaderCore"], path: "Tests")
    ]
)
