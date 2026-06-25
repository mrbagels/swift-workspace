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
- `docs/llm`: AI entrypoints, routing manifest, and conventions.
- `docs/architecture`: durable architecture decisions.
- `docs/product`: phased product and implementation plans.
- `docs/features`: feature briefs.
- `docs/technical`: implementation notes.
- `docs/operations`: verification and release workflows.
- `docs/scratchpad`: temporary investigations and working notes.

## Verify

```sh
scripts/doctor.sh
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
