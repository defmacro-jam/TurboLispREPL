// swift-tools-version:5.7
import PackageDescription

let package = Package(
    name: "TurboLispREPL",
    products: [
        .library(name: "TurboLispREPL", targets: ["TurboLispREPL"]),
    ],
    targets: [
        .target(name: "TurboLispREPL", dependencies: []),
        .testTarget(name: "TurboLispREPLTests", dependencies: ["TurboLispREPL"]),
    ]
)

