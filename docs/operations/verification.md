# Verification

Last updated: 2026-06-27

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
2. runs documentation checks,
3. runs package tests,
4. cleans the custom renderer example SwiftPM build cache,
5. runs custom renderer example tests,
6. cleans the Xcode derived data buckets owned by the verifier,
7. generates the Xcode project,
8. builds the macOS demo,
9. builds the minimal macOS starter app.

Set `VERIFY_BUILD_IOS=1` to also build the iOS demo and minimal iOS starter app:

```sh
VERIFY_BUILD_IOS=1 scripts/verify.sh
```

Use the iOS build option after changes to `IOSWorkspaceShell`, the iOS demo, the
iOS starter app, or shared APIs consumed by iOS-only SwiftUI code. Plain
`swift test` runs on macOS and does not compile the `#if os(iOS)` renderer body.
The iOS app targets use explicit Info.plist files with `UILaunchScreen` and
universal iPhone/iPad device-family settings so current iPhones do not launch in
compatibility scaling.

Set `VERIFY_RUN_UI_TESTS=1` to run the UI smoke tests after the app builds:

```sh
VERIFY_RUN_UI_TESTS=1 scripts/verify.sh
VERIFY_BUILD_IOS=1 VERIFY_RUN_UI_TESTS=1 scripts/verify.sh
```

The iOS UI smoke test uses `VERIFY_IOS_TEST_DESTINATION`, defaulting to
the first available simulator whose name matches or starts with
`VERIFY_IOS_TEST_DEVICE`, which defaults to `iPhone 17 Pro`. The script passes
the resolved simulator UUID to `xcodebuild` so runtimes named like
`iPhone 17 Pro (26.5)` still work.

The verifier clears its own Xcode derived data buckets before generated-project
builds. This avoids stale SwiftSyntax macro prebuilts after Xcode or toolchain
changes. Override `VERIFY_DERIVED_DATA` only when you want those disposable
build products somewhere other than `/tmp/swift-workspace-derived-data`.

## Example Checks

```sh
swift test --package-path Examples/CustomRendererClient
```

The full verification script runs this example check.

## Documentation Checks

DocC catalogs are checked into each public product target. This local SwiftPM
toolchain does not currently expose `swift package generate-documentation`, so
DocC generation is not part of `scripts/verify.sh` yet. `scripts/check-docs.sh`
validates the LLM manifest, durable entrypoint files, DocC landing pages, and
public documentation copy rules. Add full DocC generation once the package uses a
toolchain or plugin that supports documentation generation in CI.

## Continuous Integration

The repository workflow lives at `.github/workflows/swift-workspace.yml`. It runs
on GitHub's `macos-26` runner, installs XcodeGen when needed, and executes
`scripts/verify.sh` from the `swift-workspace` folder. The iOS demo and starter
builds are available through the manual `workflow_dispatch` input named
`build_ios`. UI smoke tests are available through the manual `run_ui_tests`
input.

## Generated Output

The following are generated or local-only:

- `SwiftWorkspace.xcodeproj`
- `.build`
- `.swiftpm`
- DerivedData

Do not treat generated project files as source of truth.
