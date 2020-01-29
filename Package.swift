// swift-tools-version:5.1
import PackageDescription
import Foundation

// MARK: - Conveniences

let localDev = ProcessInfo.processInfo.environment["LIBS_DEVELOPMENT"] == "1"
let devDir = "../"

struct Dep {
    let package: PackageDescription.Package.Dependency
    let targets: [Target.Dependency]
}

extension Array where Element == Dep {
    mutating func appendLocal(_ path: String, targets: Target.Dependency...) {
        append(.init(package: .package(path: "\(devDir)\(path)"), targets: targets))
    }

    mutating func append(_ url: String, from: Version, targets: Target.Dependency...) {
        append(.init(package: .package(url: url, from: from), targets: targets))
    }

    mutating func append(_ url: String, _ requirement: PackageDescription.Package.Dependency.Requirement, targets: Target.Dependency...) {
        append(.init(package: .package(url: url, requirement), targets: targets))
    }
}

// MARK: - Dependencies

var deps: [Dep] = []

// Sugary extensions for the SwiftNIO library
deps.append("https://github.com/vapor/async-kit.git", from: "1.0.0-beta.2", targets: "AsyncKit")

// Event-driven network application framework for high performance protocol servers & clients, non-blocking.
deps.append("https://github.com/apple/swift-nio.git", from: "2.2.0", targets: "NIO")

// Bindings to OpenSSL-compatible libraries for TLS support in SwiftNIO
deps.append("https://github.com/apple/swift-nio-ssl.git", from: "2.0.0", targets: "NIOSSL")

// Swift logging API
deps.append("https://github.com/apple/swift-log.git", from: "1.0.0", targets: "Logging")

if localDev {
    deps.appendLocal("SwifQL", targets: "SwifQL")
} else {
    deps.append("https://github.com/SwifQL/SwifQL.git", from: "2.0.0-beta.1", targets: "SwifQL")
}

// MARK: - Package

let package = Package(
    name: "Bridges",
    platforms: [
       .macOS(.v10_14)
    ],
    products: [
        .library(name: "Bridges", targets: ["Bridges"]),
    ],
    dependencies: deps.map { $0.package },
    targets: [
        .target(name: "Bridges", dependencies: deps.flatMap { $0.targets }),
        .testTarget(name: "BridgesTests", dependencies: ["Bridges"]),
    ]
)
