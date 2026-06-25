# swift-workspace Agent Instructions

This folder is the source of truth for the clean `swift-workspace` product. Treat the
repository root outside this folder as prototype history unless a task
explicitly asks to modify it.

## Start Here

- Read `README.md`.
- Read `docs/llm/START_HERE.md`.
- Read `docs/architecture/workspace-engine-split.md` before changing package
  boundaries, public API names, or platform renderer responsibilities.
- Read `docs/product/phased-implementation-plan.md` before sequencing new work.
- Read `docs/features/server-side-companion.md` before adding server or network
  functionality.
- Read `docs/operations/verification.md` before changing verification scripts,
  project generation, or CI.

## Working Rules

- Keep `WorkspaceCore` free of SwiftUI, TCA, SQLiteData, CloudKit, AppKit, and
  UIKit.
- Keep `WorkspaceTCA` platform-neutral. Platform renderers may consume it, but
  it must not know about windows, titlebars, sidebars, split-view pixels, or
  platform-specific navigation containers.
- Keep iCloud/CloudKit primary for user-owned data. Server features are
  companion capabilities, not the canonical store for documents or workspace
  state.
- Do not make the macOS shell the engine. `MacWorkspaceShell` is one renderer
  over `WorkspaceCore` and `WorkspaceTCA`.
- Prefer typed route IDs, command IDs, scene IDs, and restoration payloads over
  stringly typed integration points.
- Optional adapters must remain optional products. Do not force SQLiteData,
  CloudKit, or server clients onto consumers that only need the core engine.
- Preserve the docs lifecycle: stable docs in durable folders, temporary notes
  in `docs/scratchpad`, and AI entrypoints in `docs/llm`.

## Verification

Use the narrowest relevant command:

```sh
swift test
xcodegen generate --spec project.yml
scripts/verify.sh
```

Generated `.xcodeproj`, `.build`, `.swiftpm`, DerivedData, and workspace-local
state are not source of truth.
