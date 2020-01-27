// swift-tools-version:5.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

var dependencies: [Package.Dependency] = [
    // 💧 A server-side Swift web framework.
    .package(url: "https://github.com/vapor/vapor.git", from: "3.3.1"),

    .package(url: "https://github.com/twof/VaporMailgunService.git", from: "1.5.0"),
]

#if os(macOS) // Local development
dependencies.append(contentsOf: [
        .package(path: "../KognitaCore"),
    ]
)
#else
dependencies.append(contentsOf: [
        .package(url: "https://Kognita:dyjdov-bupgev-goffY8@github.com/MatsMoll/KognitaCore", from: "2.0.0"),
    ]
)
#endif

let package = Package(
    name: "KognitaAPI",
    platforms: [
        .macOS(.v10_15),
    ],
    products: [
        // Products define the executables and libraries produced by a package, and make them visible to other packages.
        .library(
            name: "KognitaAPI",
            targets: ["KognitaAPI"]),
    ],
    dependencies: dependencies,
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages which this package depends on.
        .target(
            name: "KognitaAPI",
            dependencies: [
                "KognitaCore",
                "Mailgun",
                "Vapor"
        ]),
        .testTarget(
            name: "KognitaAPITests",
            dependencies: [
                "KognitaAPI",
                "KognitaCoreTestable"
        ]),
    ]
)
