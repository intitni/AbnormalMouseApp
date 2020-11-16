// swift-tools-version:5.3

import PackageDescription

let package = Package(
    name: "AppDependencies",
    platforms: [.macOS(.v10_15)],
    products: [
        .library(
            name: "AppDependencies",
            targets: ["AppDependencies"]
        ),
    ],
    dependencies: [
        .package(
            name: "License",
            url: "https://github.com/intitni/AbnormalMouseLicense",
            .branch("master")
        ),
        .package(
            name: "CGEventOverride",
            url: "https://github.com/intitni/CGEventOverride.git",
            .branch("master")
        ),
        .package(
            url: "https://github.com/pointfreeco/swift-composable-architecture",
            .upToNextMajor(from: "0.3.0")
        ),
        .package(
            url: "https://github.com/kishikawakatsumi/KeychainAccess",
            .upToNextMajor(from: "4.2.0")
        ),
        .package(
            url: "https://github.com/CombineCommunity/CombineExt",
            .upToNextMajor(from: "1.2.0")
        ),
        .package(
            url: "https://github.com/sparkle-project/Sparkle",
            .branch("master")
        ),
    ],
    targets: [
        .target(
            name: "AppDependencies",
            dependencies: [
                "License",
                "CGEventOverride",
                "CombineExt",
                "KeychainAccess",
                "Sparkle",
                .product(name: "ComposableArchitecture", package: "swift-composable-architecture"),
            ]
        ),
    ]
)
