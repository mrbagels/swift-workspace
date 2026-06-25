# ``WorkspaceEngine``

Convenience umbrella for the reusable workspace engine.

## Overview

`WorkspaceEngine` re-exports `WorkspaceCore`, `WorkspaceTCA`,
`WorkspacePersistence`, and Composable Architecture. Import it when an app wants
the default engine surface wholesale.

Apps that need smaller dependency footprints can import individual products
instead:

- `WorkspaceCore` for pure route, command, scene, and restoration models.
- `WorkspaceTCA` for the shared reducer.
- `WorkspacePersistence` for small restoration storage helpers.

Optional adapters and platform shells remain separate products.

## Re-Exported Products

- `WorkspaceCore`
- `WorkspaceTCA`
- `WorkspacePersistence`
- `ComposableArchitecture`
