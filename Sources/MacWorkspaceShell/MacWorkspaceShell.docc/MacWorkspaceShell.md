# ``MacWorkspaceShell``

macOS renderer for the shared workspace engine.

## Overview

`MacWorkspaceShell` renders `WorkspaceFeature` with custom Mac chrome. It owns
presentation details such as command menus, toolbar affordances, command palette
UI, inspector presentation, density, sidebar presentation, and Mac-specific
restoration.

It does not own workspace logic, persistence writes, server calls, documents, or
app domain behavior.

Use this module when a macOS app wants a packaged shell over the shared engine.
Custom Mac clients can import `WorkspaceCore` and `WorkspaceTCA` directly.

## Topics

### Shell View

- ``MacWorkspaceShellView``
- ``MacWorkspaceShellConfiguration``
- ``MacWorkspaceShellLayout``
- ``MacWorkspaceShellBehavior``
- ``MacWorkspaceBrand``
- ``MacWorkspaceTint``
- ``MacWorkspaceSidebarPresentation``

### Commands

- ``MacWorkspaceCommands``
- ``MacWorkspaceCommandMenuConfiguration``

### Restoration And Layout

- ``MacWorkspaceRestoration``
- ``MacWorkspaceColumnWidths``
- ``MacWorkspaceColumn``
- ``MacWorkspaceColumnWidthRange``
- ``MacWorkspaceDensity``
- ``MacWorkspaceDensityMetrics``
