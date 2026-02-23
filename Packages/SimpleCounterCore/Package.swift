// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "SimpleCounterCore",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [
        .library(name: "SimpleCounterCore", targets: ["SimpleCounterCore"]),
    ],
    dependencies: [
        .package(url: "https://github.com/groue/GRDB.swift.git", from: "6.0.0"),
    ],
    targets: [
        .target(
            name: "SimpleCounterCore",
            dependencies: [
                .product(name: "GRDB", package: "GRDB.swift"),
            ]
        ),
        .testTarget(
            name: "SimpleCounterCoreTests",
            dependencies: [
                "SimpleCounterCore",
                .product(name: "GRDB", package: "GRDB.swift"),
            ]
        ),
    ]
)
