// swift-tools-version:5.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription
import Foundation

var dependencies: [Package.Dependency] = [
    // 💧 A server-side Swift web framework.
    .package(name: "vapor", url: "https://github.com/vapor/vapor.git", from: "4.14.0"),

    .package(url: "https://github.com/twof/VaporMailgunService.git", from: "4.0.0-rc")
]

switch ProcessInfo.processInfo.environment["BUILD_TYPE"] {
case "LOCAL":
    dependencies.append(contentsOf: [
            .package(path: "../KognitaCore"),
            .package(path: "../KognitaModels"),
            .package(path: "../../QTIKit")
        ]
    )
case "DEV":
    dependencies.append(contentsOf: [
            .package(name: "KognitaCore", url: "https://Kognita:dyjdov-bupgev-goffY8@github.com/MatsMoll/KognitaCore", .branch("develop")),
            .package(name: "KognitaModels", url: "https://Kognita:dyjdov-bupgev-goffY8@github.com/MatsMoll/KognitaModels", .branch("develop")),
            .package(name: "QTIKit", url: "https://github.com/MatsMoll/qtikit", from: "0.0.1"),
        ]
    )
default:
    dependencies.append(contentsOf: [
            .package(name: "KognitaCore", url: "https://Kognita:dyjdov-bupgev-goffY8@github.com/MatsMoll/KognitaCore", from: "2.0.0"),
            .package(name: "KognitaModels", url: "https://Kognita:dyjdov-bupgev-goffY8@github.com/MatsMoll/KognitaModels", from: "1.0.0"),
            .package(name: "QTIKit", url: "https://github.com/MatsMoll/qtikit", from: "0.0.1"),
        ]
    )
}

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
                .product(name: "KognitaCore", package: "KognitaCore"),
                .product(name: "KognitaModels", package: "KognitaModels"),
                .product(name: "Vapor", package: "vapor"),
                .product(name: "Mailgun", package: "VaporMailgunService"),
                .product(name: "QTIKit", package: "QTIKit"),
        ]),
        .testTarget(
            name: "KognitaAPITests",
            dependencies: [
                .target(name: "KognitaAPI"),
                .product(name: "KognitaCoreTestable", package: "KognitaCore"),
                .product(name: "XCTVapor", package: "vapor")
        ]),
    ]
)
