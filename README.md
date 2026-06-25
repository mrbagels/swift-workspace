# swift-workspace

`swift-workspace` is the fresh product root for the reusable workspace engine that
grew out of the Mac Shell prototype.

The old prototype remains the proving ground. This folder is the clean-room
implementation where the durable API, package structure, docs, demos, and
distribution model are built intentionally.

## Package Products

- `WorkspaceCore`: platform-neutral route, command, scene, search,
  restoration, and policy models.
- `WorkspaceTCA`: a TCA reducer that owns shared workspace behavior without
  owning platform chrome.
- `WorkspaceEngine`: convenience umbrella for clients that want the core
  engine wholesale.
- `WorkspacePersistence`: storage-agnostic Codable and UserDefaults helpers.
- `WorkspaceSQLiteData`: optional SQLiteData records, migrations, and codecs.
- `WorkspaceCloudKit`: optional CloudKit/iCloud adapter contracts.
- `MacWorkspaceShell`: macOS renderer for the engine.
- `IOSWorkspaceShell`: iOS and iPadOS renderer for the engine.

## Project Layout

- `Sources/`: package products.
- `Tests/`: package tests.
- `Apps/MacWorkspaceDemo`: macOS demo app.
- `Apps/IOSWorkspaceDemo`: iOS demo app.
- `Examples/MinimalMacWorkspaceApp`: smallest macOS starter app target.
- `Examples/MinimalIOSWorkspaceApp`: smallest iOS starter app target.
- `docs/llm`: AI entrypoints, routing manifest, and conventions.
- `docs/architecture`: durable architecture decisions.
- `docs/product`: phased product and implementation plans.
- `docs/features`: feature briefs.
- `docs/technical`: implementation notes.
- `docs/operations`: verification and release workflows.
- `docs/scratchpad`: temporary investigations and working notes.

## Adoption Guides

- [Mac shell quickstart](docs/adoption/mac-shell.md)
- [iOS shell quickstart](docs/adoption/ios-shell.md)
- [Engine-only quickstart](docs/adoption/engine-only.md)
- [Custom renderer quickstart](docs/adoption/custom-renderer.md)
- [Persistence adapter guide](docs/adoption/persistence.md)
- [CloudKit adoption guide](docs/adoption/cloudkit.md)
- [Prototype migration guide](docs/adoption/prototype-migration.md)

## Starter Apps

The generated Xcode project includes minimal starter app schemes:

```sh
xcodegen generate --spec project.yml
xcodebuild \
  -project SwiftWorkspace.xcodeproj \
  -scheme MinimalMacWorkspaceApp \
  -configuration Debug \
  -destination 'platform=macOS,arch=arm64' \
  CODE_SIGNING_ALLOWED=NO \
  build
```

Use `VERIFY_BUILD_IOS=1 scripts/verify.sh` to build both iOS app targets.

## Verify

```sh
scripts/doctor.sh
scripts/check-docs.sh
scripts/verify.sh
```

For a fast package-only pass:

```sh
swift test
```

Generate the Xcode project:

```sh
xcodegen generate --spec project.yml
```

Build both demo apps:

```sh
VERIFY_BUILD_IOS=1 scripts/verify.sh
```

Run UI smoke tests:

```sh
VERIFY_RUN_UI_TESTS=1 scripts/verify.sh
VERIFY_BUILD_IOS=1 VERIFY_RUN_UI_TESTS=1 scripts/verify.sh
```

GitHub Actions runs the macOS verification path from
`.github/workflows/swift-workspace.yml`. Use the manual workflow input
`build_ios` when the iOS demo and starter targets should be built in CI, and
`run_ui_tests` when UI smoke tests should run.
