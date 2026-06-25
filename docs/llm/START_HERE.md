# swift-workspace LLM Start Here

`swift-workspace` is the clean product root for the reusable workspace engine. The
existing Mac Shell package outside this folder is a prototype reference, not the
source of truth for new architecture.

## Read Order

1. `README.md`
2. `AGENTS.md`
3. `docs/architecture/workspace-engine-split.md`
4. `docs/product/phased-implementation-plan.md`
5. `docs/features/server-side-companion.md`
6. `docs/technical/package-map.md`
7. `docs/operations/verification.md`

## Current Intent

The product should let client apps adopt the shared workspace engine in pieces
or wholesale. The same engine must support:

- a custom macOS workspace shell,
- a native macOS shell treatment,
- an iOS and iPadOS renderer,
- fully custom client renderers,
- optional persistence adapters,
- iCloud-primary storage,
- thin server companion capabilities.

## Rules Of Thumb

- If a type is pure routing, command, availability, restoration, or scene
  orchestration, it belongs in `WorkspaceCore`.
- If a type uses TCA but not SwiftUI/AppKit/UIKit, it belongs in `WorkspaceTCA`.
- If a type renders UI, it belongs in a platform renderer.
- If a type touches SQLiteData, CloudKit, or server APIs, it belongs in an
  optional adapter product.
- If a decision is stable, document it in a durable folder, not scratchpad.
