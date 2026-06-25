# API Review Checklist

Use this checklist before tagging a `swift-workspace` release or declaring a
product surface stable.

## Package Boundaries

- `WorkspaceCore` imports Foundation only.
- `WorkspaceTCA` depends on `WorkspaceCore` and TCA only.
- `WorkspaceEngine` is a convenience product, not a new behavior owner.
- Optional adapters stay optional.
- Platform shells depend on the shared reducer rather than duplicating engine
  behavior.
- Demo apps may import convenience products, but package targets should keep
  dependency direction clean.

## Naming

- Shared concepts use the `Workspace...` prefix.
- Mac-only types use the `MacWorkspace...` prefix.
- iOS-only types use the `IOSWorkspace...` prefix.
- Route IDs, command IDs, scene IDs, and restoration payloads are typed.
- Public names describe product concepts, not prototype internals.

## Sendable And Codable

- Public value types that cross reducer, persistence, scene, or adapter
  boundaries are `Sendable`.
- Storage-safe payloads are `Codable` when their generic route ID is `Codable`.
- Codable conformance is conditional when the route ID controls encodability.
- Public enums with persistence meaning use stable raw values.

## Renderer Rules

- Renderers do not write persistence directly.
- Renderers do not call the server directly.
- Renderers do not own document or workflow state.
- Renderer configuration is explicit and codable where restoration needs it.
- Accessibility identifiers are stable and not localized.

## Reducer Rules

- Route selection, command execution, command palette state, route-open
  rejection, command policy, scene delegates, recents, and metadata reconciliation
  are covered by tests.
- New app-owned behavior exits through delegate actions.
- Effects are introduced only when there is a real shared effect.

## Adapter Rules

- Persistence helpers encode small workspace payloads, not app documents.
- SQLiteData helpers do not own the app database lifecycle.
- CloudKit helpers do not own the app container lifecycle.
- Server clients remain optional and app-owned.

## Documentation

- README package list matches `Package.swift`.
- `docs/technical/package-map.md` matches products and dependencies.
- Adoption docs cover Mac, iOS, custom renderer, engine-only, persistence, and
  CloudKit paths.
- The phased plan says what is complete, what is in progress, and what is
  decision-gated.
- Breaking changes have migration notes.

## Verification

Run:

```sh
scripts/doctor.sh
swift test
VERIFY_BUILD_IOS=1 scripts/verify.sh
```

For release candidates, also build example packages and inspect both demo apps
manually.
