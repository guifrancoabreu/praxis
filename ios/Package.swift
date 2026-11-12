// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "ReaderCore",
    platforms: [.iOS(.v17), .macOS(.v13)],
    products: [.library(name: "ReaderCore", targets: ["ReaderCore"])],
    targets: [
        .target(name: "ReaderCore", path: "Praxis", exclude: ["PraxisApp.swift"], sources: ["PageStore.swift", "Catalog.swift", "DesignSystem.swift", "PortraitCache.swift", "RefTokens.swift", "SystemTokens.swift", "Components.swift"]),
        .testTarget(name: "ReaderCoreTests", dependencies: ["ReaderCore"], path: "Tests")
    ]
)
