// swift-tools-version: 6.2

import PackageDescription

let package = Package(
  name: "CustomRendererClient",
  platforms: [
    .iOS(.v26),
    .macOS(.v26),
  ],
  products: [
    .library(
      name: "CustomRendererClient",
      targets: ["CustomRendererClient"]
    ),
  ],
  dependencies: [
    .package(path: "../.."),
  ],
  targets: [
    .target(
      name: "CustomRendererClient",
      dependencies: [
        .product(name: "WorkspaceCore", package: "swift-workspace"),
        .product(name: "WorkspacePersistence", package: "swift-workspace"),
        .product(name: "WorkspaceTCA", package: "swift-workspace"),
      ]
    ),
    .testTarget(
      name: "CustomRendererClientTests",
      dependencies: [
        "CustomRendererClient",
        .product(name: "WorkspaceCore", package: "swift-workspace"),
      ]
    ),
  ]
)
