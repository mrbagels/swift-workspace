# ``MacWorkspaceShell``

macOS renderer for the shared workspace engine.

## Overview

`MacWorkspaceShell` renders `WorkspaceFeature` with Mac-native chrome. It owns
presentation details such as native split views, custom shell style, command
menus, toolbar affordances, command palette UI, inspector presentation, density,
and Mac-specific restoration.

It does not own workspace logic, persistence writes, server calls, documents, or
app domain behavior.

Use this module when a macOS app wants a packaged shell over the shared engine.
Custom Mac clients can import `WorkspaceCore` and `WorkspaceTCA` directly.

## Topics

### Shell View

- ``MacWorkspaceShellView``
- ``MacWorkspaceShellConfiguration``
- ``MacWorkspaceShellStyle``
- ``MacWorkspaceShellLayout``
- ``MacWorkspaceShellBehavior``
- ``MacWorkspaceBrand``
- ``MacWorkspaceTint``

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
