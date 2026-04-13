// swift-tools-version: 6.1
import PackageDescription

let package = Package(
    name: "BugPet",
    platforms: [
        .macOS(.v13),
    ],
    products: [
        .executable(name: "BugPet", targets: ["BugPetNative"]),
    ],
    targets: [
        .executableTarget(
            name: "BugPetNative",
            path: "Sources/BugPetNative",
            resources: [
                .process("Resources"),
            ]
        ),
    ]
)
