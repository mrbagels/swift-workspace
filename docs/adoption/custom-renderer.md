# Custom Renderer Quickstart

Use this path when an app wants the shared workspace engine but not the bundled
Mac or iOS shells.

## Package Products

Import only what the custom client needs:

```swift
import WorkspaceCore
import WorkspaceTCA
```

Add `WorkspacePersistence` when the client wants the provided UserDefaults or
file-backed restoration helpers.

## Shape

A custom renderer should treat `WorkspaceFeature.State` as the source for:

- visible route sections,
- selected route,
- command search and command sections,
- scene request metadata,
- shared restoration state.

The renderer owns all visual decisions. It can be SwiftUI, AppKit, UIKit, a menu
bar surface, an extension, or a bridge into another runtime.

## Compiled Example

The checked-in example lives at:

```text
Examples/CustomRendererClient
```

It is a standalone Swift package that depends on the local `swift-workspace`
package by path. It builds route snapshots, command sections, metadata patches,
and file restoration without importing `MacWorkspaceShell` or `IOSWorkspaceShell`.

Run it directly:

```sh
swift test --package-path Examples/CustomRendererClient
```

The root verification script runs the same command.
