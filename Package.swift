// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "HackathonLukasClient",
    platforms: [.macOS(.v14)],
    targets: [
        .executableTarget(
            name: "HackathonLukasClient",
            path: "Sources",
            resources: [.process("Resources")]
        ),
    ]
)
