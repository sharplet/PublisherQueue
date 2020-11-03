// swift-tools-version:5.3

import PackageDescription

let package = Package(
  name: "PublisherQueue",
  platforms: [
    .iOS(.v13),
    .macOS(.v10_15),
  ],
  products: [
    .library(name: "PublisherQueue", targets: ["PublisherQueue"]),
  ],
  targets: [
    .target(name: "PublisherQueue"),
  ]
)
