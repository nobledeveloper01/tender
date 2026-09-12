// swift-tools-version: 6.0
//
// The domain, as a package, so that it can be tested with `swift test` on
// macOS in seconds and cannot import anything the app has. ADR-0002.
import PackageDescription

let package = Package(
    name: "TenderDomain",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [
        .library(name: "TenderDomain", targets: ["TenderDomain"]),
    ],
    targets: [
        .target(name: "TenderDomain"),
        .testTarget(name: "TenderDomainTests", dependencies: ["TenderDomain"]),
    ]
)
