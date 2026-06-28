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
    .library(name: "WorkspaceAutomationBridge", targets: ["WorkspaceAutomationBridge"]),
    .library(name: "WorkspacePersistence", targets: ["WorkspacePersistence"]),
    .library(name: "WorkspaceSQLiteData", targets: ["WorkspaceSQLiteData"]),
    .library(name: "WorkspaceCloudKit", targets: ["WorkspaceCloudKit"]),
    .library(name: "WorkspaceServerClient", targets: ["WorkspaceServerClient"]),
    .library(name: "WorkspaceServerTesting", targets: ["WorkspaceServerTesting"]),
    .library(name: "WorkspaceShellDesignSystem", targets: ["WorkspaceShellDesignSystem"]),
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
    .package(
      url: "https://github.com/mrbagels/comet",
      from: "0.4.1"
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
      name: "WorkspaceAutomationBridge",
      dependencies: [
        "WorkspaceCore",
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
      name: "WorkspaceShellDesignSystem",
      dependencies: [
        "WorkspaceCore",
      ]
    ),
    .target(
      name: "WorkspaceServerClient",
      dependencies: [
        "WorkspaceCore",
        .product(name: "Comet", package: "comet"),
        .product(name: "CometTCA", package: "comet"),
        .product(
          name: "ComposableArchitecture",
          package: "swift-composable-architecture"
        ),
      ]
    ),
    .target(
      name: "WorkspaceServerTesting",
      dependencies: [
        "WorkspaceServerClient",
        .product(name: "Comet", package: "comet"),
        .product(name: "CometTesting", package: "comet"),
      ]
    ),
    .target(
      name: "MacWorkspaceShell",
      dependencies: [
        "WorkspaceCore",
        "WorkspaceShellDesignSystem",
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
        "WorkspaceShellDesignSystem",
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
      name: "WorkspaceEngineTests",
      dependencies: [
        "WorkspaceEngine",
      ]
    ),
    .testTarget(
      name: "WorkspaceAutomationBridgeTests",
      dependencies: [
        "WorkspaceAutomationBridge",
      ]
    ),
    .testTarget(
      name: "MacWorkspaceShellTests",
      dependencies: [
        "MacWorkspaceShell",
      ],
      resources: [
        .process("__Snapshots__"),
      ]
    ),
    .testTarget(
      name: "IOSWorkspaceShellTests",
      dependencies: [
        "IOSWorkspaceShell",
      ],
      resources: [
        .process("__Snapshots__"),
      ]
    ),
    .testTarget(
      name: "WorkspacePersistenceTests",
      dependencies: [
        "WorkspacePersistence",
      ]
    ),
    .testTarget(
      name: "WorkspaceCloudKitTests",
      dependencies: [
        "WorkspaceCloudKit",
      ]
    ),
    .testTarget(
      name: "WorkspaceServerClientTests",
      dependencies: [
        "WorkspaceServerClient",
        .product(name: "CometTesting", package: "comet"),
      ]
    ),
    .testTarget(
      name: "WorkspaceServerTestingTests",
      dependencies: [
        "WorkspaceServerTesting",
      ]
    ),
  ]
)
