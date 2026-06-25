# Verification

Last updated: 2026-06-25

## Fast Checks

```sh
scripts/doctor.sh
swift test
```

## Full Local Check

```sh
scripts/verify.sh
```

The full script:

1. runs the doctor,
2. runs package tests,
3. generates the Xcode project,
4. builds the macOS demo.

Set `VERIFY_BUILD_IOS=1` to also build the iOS demo:

```sh
VERIFY_BUILD_IOS=1 scripts/verify.sh
```

Use the iOS build option after changes to `IOSWorkspaceShell`, the iOS demo, or
shared APIs consumed by iOS-only SwiftUI code. Plain `swift test` runs on macOS
and does not compile the `#if os(iOS)` renderer body.

## Example Checks

```sh
swift test --package-path Examples/CustomRendererClient
```

The full verification script runs this example check.

## Documentation Checks

DocC catalogs are checked into each public product target. This local SwiftPM
toolchain does not currently expose `swift package generate-documentation`, so
DocC generation is not part of `scripts/verify.sh` yet. Add it once the package
uses a toolchain or plugin that supports documentation generation in CI.

## Generated Output

The following are generated or local-only:

- `SwiftWorkspace.xcodeproj`
- `.build`
- `.swiftpm`
- DerivedData

Do not treat generated project files as source of truth.
