// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "TrackpadProbe",
    platforms: [.macOS(.v26)],
    products: [.executable(name: "TrackpadProbe", targets: ["TrackpadProbe"])],
    dependencies: [
        .package(url: "https://github.com/mrkai77/Subsurface", revision: "88eb16b0a6f7a44a898cecff9e283298aa413936"),
        // Matches Subsurface's requirement; Package.resolved pins the reviewed
        // revision. Direct access is used only to silence upstream diagnostic logs.
        .package(url: "https://github.com/SenpaiHunters/Scribe", branch: "main"),
    ],
    targets: [
        .executableTarget(name: "TrackpadProbe", dependencies: [
            .product(name: "Subsurface", package: "Subsurface"),
            .product(name: "Scribe", package: "Scribe"),
        ]),
        .testTarget(name: "TrackpadProbeTests", dependencies: ["TrackpadProbe"]),
    ],
    swiftLanguageModes: [.v6]
)
