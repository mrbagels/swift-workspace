# Automation Bridge Guide

Use `WorkspaceAutomationBridge` when an app wants to expose workspace commands
to App Intents, Shortcuts, widgets, controls, or other system automation
surfaces.

The bridge does not generate concrete `AppIntent` types for you. App Intents are
app-target specific: phrases, entities, permissions, handoff behavior, and
inline actions depend on the host app. The package provides a stable command
catalog and handoff payloads so your app target can keep the intent layer thin.

## Install

```swift
.product(name: "WorkspaceAutomationBridge", package: "swift-workspace")
```

## Build A Catalog

```swift
import WorkspaceAutomationBridge
import WorkspaceCore

let catalog = WorkspaceAutomationCatalog.make(
  from: registry,
  routeIdentifier: \.rawValue,
  appNamePlaceholder: "Workspace Demo"
)
```

The catalog contains:

- `WorkspaceAutomationCommandDescriptor`
- `WorkspaceAppShortcutDescriptor`
- `WorkspaceAutomationHandoff`

Use descriptors to drive intent titles, display labels, shortcut phrases, and
scene handoff routing.

## Recommended Intent Shape

Start with a small useful surface:

- one open-app intent for opening a route,
- one inline action intent for a high-value app command,
- one App Shortcuts provider that advertises the best descriptors.

Do not expose every route as a custom intent type. Prefer one generic app-owned
intent that looks up a descriptor by ID, then hands off to the main scene or
calls app-owned inline logic.

## Handoff

```swift
let handoff = catalog.handoff(for: "route.inbox", source: "shortcut")
```

Route the handoff in your app scene:

- `.openRoute` maps to `WorkspaceFeature.Action.routeSelected`.
- `.openScene` maps to `WorkspaceFeature.Action.sceneRequested`.
- inline app, toolbar, primary, and system actions map to app-owned behavior.

Keep business logic outside the intent type. The intent should validate input,
create a handoff or call a service, and return a clear result.
