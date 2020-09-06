// swift-tools-version:5.2

import PackageDescription

let package = Package(
    name: "LicenseWrapper",
    products: [
        .library(
            name: "LicenseWrapper",
            targets: ["LicenseWrapper"]
        ),
    ],
    dependencies: [
        .package(
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
