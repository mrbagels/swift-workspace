// swift-tools-version: 6.2

import PackageDescription

let package = Package(
  name: "swift-workspace",
  platforms: [
    .iOS(.v26),
    .macOS(.v26),
  ],
  products: [
    .library(name: "WorkspaceCore", targets: ["WorkspaceCore"]),
    .library(name: "WorkspaceTCA", targets: ["WorkspaceTCA"]),
    .library(name: "WorkspaceEngine", targets: ["WorkspaceEngine"]),
    .library(name: "WorkspacePersistence", targets: ["WorkspacePersistence"]),
    .library(name: "WorkspaceSQLiteData", targets: ["WorkspaceSQLiteData"]),
    .library(name: "WorkspaceCloudKit", targets: ["WorkspaceCloudKit"]),
    .library(name: "MacWorkspaceShell", targets: ["MacWorkspaceShell"]),
    .library(name: "IOSWorkspaceShell", targets: ["IOSWorkspaceShell"]),
  ],
  dependencies: [
    .package(
      url: "https://github.com/pointfreeco/swift-composable-architecture",
      from: "1.25.5"
    ),
    .package(
      url: "https://github.com/pointfreeco/sqlite-data",
      from: "1.0.0"
    ),
  ],
  targets: [
    .target(name: "WorkspaceCore"),
    .target(
      name: "WorkspaceTCA",
      dependencies: [
        "WorkspaceCore",
        .product(
          name: "ComposableArchitecture",
          package: "swift-composable-architecture"
        ),
      ]
    ),
    .target(
      name: "WorkspaceEngine",
      dependencies: [
        .product(
          name: "ComposableArchitecture",
          package: "swift-composable-architecture"
        ),
        "WorkspaceCore",
        "WorkspacePersistence",
        "WorkspaceTCA",
      ]
    ),
    .target(
      name: "WorkspacePersistence",
      dependencies: [
        "WorkspaceCore",
      ]
    ),
    .target(
      name: "WorkspaceSQLiteData",
      dependencies: [
        "WorkspaceCore",
        .product(name: "SQLiteData", package: "sqlite-data"),
      ]
    ),
    .target(
      name: "WorkspaceCloudKit",
      dependencies: [
        "WorkspaceCore",
      ]
    ),
    .target(
      name: "MacWorkspaceShell",
      dependencies: [
        "WorkspaceCore",
        "WorkspaceTCA",
        .product(
          name: "ComposableArchitecture",
          package: "swift-composable-architecture"
        ),
      ]
    ),
    .target(
      name: "IOSWorkspaceShell",
      dependencies: [
        "WorkspaceCore",
        "WorkspaceTCA",
        .product(
          name: "ComposableArchitecture",
          package: "swift-composable-architecture"
        ),
      ]
    ),
    .testTarget(
      name: "WorkspaceCoreTests",
      dependencies: [
        "WorkspaceCore",
      ]
    ),
    .testTarget(
      name: "WorkspaceTCATests",
      dependencies: [
        "WorkspaceTCA",
      ]
    ),
    .testTarget(
      name: "WorkspacePersistenceTests",
      dependencies: [
        "WorkspacePersistence",
      ]
    ),
  ]
)
