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
    dependencies: [],
    targets: [
        .target(
            name: "LicenseWrapper",
            dependencies: []
        ),
    ]
)
