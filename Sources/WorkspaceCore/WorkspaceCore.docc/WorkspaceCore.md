# ``WorkspaceCore``

Shared workspace vocabulary for routes, commands, scenes, search, policy, and
restoration.

## Overview

`WorkspaceCore` is pure Swift and imports Foundation only. It is the lowest
level product a client can adopt when it wants the engine vocabulary without
TCA, SwiftUI, persistence, CloudKit, or platform shells.

Use this module for:

- typed route descriptors and route sections,
- command identifiers, roles, targets, search, and grouping,
- scene requests and scene values,
- route-open requests and URL parsing,
- route metadata patches,
- shared restoration payloads.

Platform renderers, optional adapters, and app features should build on these
types rather than inventing parallel route or command models.

## Topics

### Routes

- ``WorkspaceRouteDescriptor``
- ``WorkspaceRouteSection``
- ``WorkspaceNavigationRegistry``
- ``WorkspaceRoutePresentation``
- ``WorkspaceAvailability``
- ``WorkspaceRouteMetadataPatch``
- ``WorkspaceValuePatch``

### Commands

- ``WorkspaceCommand``
- ``WorkspaceCommandID``
- ``WorkspaceCommandIdentifier``
- ``WorkspaceCommandTarget``
- ``WorkspaceCommandSource``
- ``WorkspaceCommandRole``
- ``WorkspaceCommandSearch``
- ``WorkspaceCommandSections``
- ``WorkspaceCommandGrouping``
- ``WorkspaceCommandReferenceConfiguration``
- ``WorkspaceCommandExecutionPolicy``

### Scenes And Route Opening

- ``WorkspaceScenePresentation``
- ``WorkspaceSceneRequest``
- ``WorkspaceSceneValue``
- ``WorkspaceSceneCollection``
- ``WorkspaceRouteOpenRequest``
- ``WorkspaceRouteOpenRejection``
- ``WorkspaceRouteOpenURLParser``

### Restoration And Shortcuts

- ``WorkspaceRestoration``
- ``WorkspaceKeyboardShortcut``
- ``WorkspaceKeyboardModifiers``
