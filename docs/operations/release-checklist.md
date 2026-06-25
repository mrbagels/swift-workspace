# Release Checklist

Use this checklist for semantic-versioned package releases from the
`swift-workspace` root.

## Versioning

- Use semantic versioning.
- Patch releases fix bugs without changing public API contracts.
- Minor releases add compatible API, docs, examples, or optional products.
- Major releases allow source-breaking public API changes.
- Keep `MARKETING_VERSION` in `project.yml` aligned with the release tag when
  demo apps need a visible version bump.

## Preflight

1. Review `docs/operations/api-review-checklist.md`.
2. Confirm generated outputs are ignored and unstaged.
3. Confirm no secrets, `.env` files, CloudKit container credentials, or private
   data are staged.
4. Confirm `Package.swift`, `project.yml`, README, package map, and adoption docs
   agree.
5. Confirm release notes describe new products, changed APIs, migration steps,
   and known limitations.

## Verification

Run the full local pass:

```sh
scripts/doctor.sh
swift test
VERIFY_BUILD_IOS=1 scripts/verify.sh
swift test --package-path Examples/CustomRendererClient
```

If a release touches only docs, still run `scripts/doctor.sh` and at least
`swift test` before tagging.

## Manual Review

Before a public tag, manually inspect:

- Mac demo custom style,
- command palette search and keyboard focus,
- native command menus,
- route scene handoff,
- iOS compact navigation,
- iPad split navigation,
- iPad route scene handoff,
- custom renderer example behavior.

Manual review currently remains required because the package does not yet have
pixel snapshots or UI automation for every renderer.

## Tagging

```sh
git tag -a 0.1.0 -m "swift-workspace 0.1.0"
git push origin 0.1.0
```

Publish from the `swift-workspace` package root. Do not publish the prototype
root as the clean product.

## Post-Release

- Create a follow-up milestone for any known manual-review gaps.
- Keep the phased implementation plan current.
- Update adoption docs when consumers report friction.
