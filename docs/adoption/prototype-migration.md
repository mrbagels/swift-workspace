# Prototype Migration Guide

This guide maps the old Mac Shell prototype shape to the clean `swift-workspace`
product. The prototype is a reference implementation, not the destination
architecture.

## Migration Principle

Do not move files wholesale. Preserve behavior intentionally by moving concepts
into the correct product boundary:

- shared engine mechanics into `WorkspaceCore`,
- shared reducer behavior into `WorkspaceTCA`,
- macOS presentation into `MacWorkspaceShell`,
- iOS presentation into `IOSWorkspaceShell`,
- storage helpers into optional adapter products,
- app-specific domain behavior into the consuming app.

## Name Mapping

| Prototype Concept | New Product Concept |
| --- | --- |
| `ShellRoute` or route model | `WorkspaceRouteDescriptor` |
| route section | `WorkspaceRouteSection` |
| route registry | `WorkspaceNavigationRegistry` |
| shell command | `WorkspaceCommand` |
| command palette search | `WorkspaceCommandSearch` |
| command menu grouping | `WorkspaceCommandSections` |
| route window handoff | `WorkspaceSceneRequest` and `WorkspaceSceneValue` |
| shared shell restoration | `WorkspaceRestoration` |
| Mac chrome restoration | `MacWorkspaceRestoration` |
| Mac shell renderer | `MacWorkspaceShellView` custom renderer |

## What To Port First

1. Route IDs and command IDs.
2. Registry sections and route descriptors.
3. Command search keywords and keyboard shortcuts.
4. Scene presentation declarations.
5. Shared restoration payloads.
6. Mac renderer configuration and restoration.
7. Persistence adapters that are still app-agnostic.

## What Not To Port

Do not copy prototype assumptions that make the Mac shell the engine:

- route selection logic inside Mac-only views,
- persistence writes inside renderer code,
- app domain models inside package products,
- Chime-specific copy, branding, or workflow state,
- database or CloudKit lifecycle ownership inside `WorkspaceCore`,
- server calls inside the shared reducer.

## Mac Parity Checklist

Use this checklist when comparing prototype behavior against the new Mac shell:

- the custom shell renders from `WorkspaceFeature`,
- command palette opens from toolbar and native commands,
- route commands, scene commands, app commands, toolbar commands, and primary
  commands share one command registry,
- selected route fallback is reducer-owned,
- disabled and hidden routes reconcile in the reducer,
- scene handoff uses typed `WorkspaceSceneValue`,
- Mac restoration composes around shared restoration,
- sidebar presentation, inspector, split widths, and density remain Mac-specific,
- stable accessibility identifiers exist for automation,
- visual-state fixtures cover the custom Mac renderer state.

## iOS Parity Checklist

The iOS renderer should prove the engine is not Mac-only:

- compact widths use stack navigation,
- regular widths use split navigation,
- command search uses the same command filtering and selection state,
- route context actions request scenes for iPadOS,
- route badges and shortcut labels are renderer choices over shared metadata,
- iOS restoration composes around shared restoration,
- visual-state fixtures cover compact and split states.

## Adapter Migration

Move storage one layer at a time:

- Use `WorkspacePersistence` for small JSON restoration payloads.
- Use `WorkspaceSQLiteData` only in apps that already own a SQLiteData database.
- Use `WorkspaceCloudKit` contracts for iCloud-owned sync decisions.
- Keep user documents and app workflow state in app-owned storage.

## Verification

Run the new workspace verification, not the old prototype scripts:

```sh
scripts/doctor.sh
scripts/verify.sh
VERIFY_BUILD_IOS=1 scripts/verify.sh
```

Prototype snapshots can still be useful as behavioral references, but they are
not source of truth for the new package graph.
