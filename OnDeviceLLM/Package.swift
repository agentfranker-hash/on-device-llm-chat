// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "OnDeviceLLM",
    platforms: [.iOS(.v17)],
    products: [
        .library(name: "OnDeviceLLM", targets: ["OnDeviceLLM"])
    ],
    dependencies: [],
    targets: [
        .target(name: "OnDeviceLLM", path: "OnDeviceLLM")
    ]
)
