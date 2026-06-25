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

## Generated Output

The following are generated or local-only:

- `SwiftWorkspace.xcodeproj`
- `.build`
- `.swiftpm`
- DerivedData

Do not treat generated project files as source of truth.
