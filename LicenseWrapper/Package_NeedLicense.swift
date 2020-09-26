// swift-tools-version:5.3

import PackageDescription

let package = Package(
    name: "LicenseWrapper",
    platforms: [.macOS(.v10_15)],
    products: [
        .library(
            name: "LicenseWrapper",
            targets: ["LicenseWrapper"]
        ),
    ],
    dependencies: [
        .package(
            name: "License",
            url: "https://github.com/intitni/AbnormalMouseLicense",
            .branch("master")
        ),
    ],
    targets: [
        .target(
            name: "LicenseWrapper",
            dependencies: ["License"]
        ),
    ]
)
