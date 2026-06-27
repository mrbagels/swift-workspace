# ``WorkspaceShellDesignSystem``

Shared SwiftUI primitives for workspace shells and custom renderers.

## Overview

`WorkspaceShellDesignSystem` contains small reusable presentation components
that are useful across bundled shells and app-owned renderers. It does not own
route selection, command execution, persistence, server calls, or app domain
behavior.

Use this module for:

- route status states,
- badges,
- keycaps,
- section labels,
- simple shell palette and metrics values.

## Topics

### Tokens

- ``WorkspaceShellMetrics``
- ``WorkspaceShellPalette``

### Components

- ``WorkspaceShellBadge``
- ``WorkspaceShellKeycap``
- ``WorkspaceShellSectionLabel``
- ``WorkspaceShellRouteStatusView``
