# ``IOSWorkspaceShell``

iOS and iPadOS renderer for the shared workspace engine.

## Overview

`IOSWorkspaceShell` renders `WorkspaceFeature` with platform-appropriate
navigation. It resolves automatic navigation to stack navigation on compact
widths and split navigation on regular widths, provides a command-search sheet,
shows route badges when configured, and supports scene-aware iPad actions.

It does not own workspace logic, persistence writes, server calls, documents, or
app domain behavior.

Use this module when an iOS or iPadOS app wants a packaged shell over the shared
engine. Custom iOS clients can import `WorkspaceCore` and `WorkspaceTCA`
directly.

## Topics

### Shell View

- ``IOSWorkspaceShellView``
- ``IOSWorkspaceShellConfiguration``
- ``IOSWorkspaceNavigationStyle``

### Restoration

- ``IOSWorkspaceRestoration``
- ``IOSWorkspaceColumnPreference``
