// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "MathLibSwift",
    products: [
        .library(
            name: "MathLibSwift",
            targets: ["MathLibSwift"]
        ),
        .executable(
            name: "MathLibSwiftExample",
            targets: ["MathLibSwiftCli"]
        ),
    ],
    dependencies: [],
    targets: [
        .target(
            name: "MathLibSwift",
            dependencies: ["CMathLib"],
            cSettings: [
                .headerSearchPath("../../C/include"),
                .define("SWIFT_PACKAGE")
            ],
            linkerSettings: [
                .unsafeFlags(["-L../../C/build"], .when(platforms: [.linux, .macOS]))
            ]
        ),
        .target(
            name: "CMathLib",
            dependencies: []
        ),
        .executableTarget(
            name: "MathLibSwiftCli",
            dependencies: ["MathLibSwift"],
            path: "Sources/MathLibSwiftCli"
        ),
    ]
)
