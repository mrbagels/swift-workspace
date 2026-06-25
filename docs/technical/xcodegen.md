# XcodeGen Setup

Last updated: 2026-06-25

`project.yml` generates `SwiftWorkspace.xcodeproj`.

The generated project is not source of truth. Edit `project.yml`, then run:

```sh
xcodegen generate --spec project.yml
```

## Local Package

The project references the local Swift package by path:

```yaml
packages:
  SwiftWorkspace:
    path: .
```

App targets depend on package products rather than source folders directly.
This keeps the generated project aligned with SwiftPM distribution.

## Schemes

- `MacWorkspaceDemo`
- `IOSWorkspaceDemo`
- `MinimalMacWorkspaceApp`
- `MinimalIOSWorkspaceApp`

`MacWorkspaceDemo` and `IOSWorkspaceDemo` also wire UI smoke test targets for
launch, route, and command-search coverage.

Package tests should be run with SwiftPM:

```sh
swift test
```
