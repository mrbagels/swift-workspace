# ``WorkspaceAutomationBridge``

Automation descriptors and handoff payloads for App Intents and Shortcuts.

## Overview

`WorkspaceAutomationBridge` converts a workspace navigation registry into a
serializable automation catalog. Host app targets can bind that catalog to
concrete `AppIntent`, `AppShortcutsProvider`, widget, or control types.

The bridge is descriptor-only. It does not define app-specific App Intent types,
phrases, entities, permissions, or business logic.

Use this module for:

- command descriptors,
- route and scene automation metadata,
- shortcut descriptor templates,
- app-scene handoff payloads.

## Topics

### Catalogs

- ``WorkspaceAutomationCatalog``
- ``WorkspaceAutomationCommandDescriptor``
- ``WorkspaceAppShortcutDescriptor``

### Handoff

- ``WorkspaceAutomationHandoff``
- ``WorkspaceAutomationKind``
- ``WorkspaceAutomationLaunchPolicy``
