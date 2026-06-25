#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
PROJECT_ROOT=$(cd "$SCRIPT_DIR/.." && pwd)

MAC_DESTINATION=${VERIFY_MAC_DESTINATION:-platform=macOS,arch=arm64}
IOS_DESTINATION=${VERIFY_IOS_DESTINATION:-generic/platform=iOS Simulator}
DERIVED_DATA=${VERIFY_DERIVED_DATA:-/tmp/swift-workspace-derived-data}
BUILD_IOS=${VERIFY_BUILD_IOS:-0}

require_command() {
  local name="$1"

  if ! command -v "$name" >/dev/null 2>&1; then
    echo "error: required command not found: $name" >&2
    exit 127
  fi
}

run_step() {
  local title="$1"
  shift

  printf '\n==> %s\n' "$title"
  "$@"
}

require_command swift
require_command xcodebuild
require_command xcodegen

run_step "Run swift-workspace doctor" \
  "$PROJECT_ROOT/scripts/doctor.sh"

run_step "Run package tests" \
  swift test --package-path "$PROJECT_ROOT"

run_step "Run custom renderer example tests" \
  swift test --package-path "$PROJECT_ROOT/Examples/CustomRendererClient"

run_step "Generate Xcode project" \
  xcodegen generate --spec "$PROJECT_ROOT/project.yml"

run_step "Build MacWorkspaceDemo" \
  xcodebuild \
    -project "$PROJECT_ROOT/SwiftWorkspace.xcodeproj" \
    -scheme MacWorkspaceDemo \
    -configuration Debug \
    -destination "$MAC_DESTINATION" \
    -derivedDataPath "$DERIVED_DATA/mac" \
    -skipMacroValidation \
    -skipPackagePluginValidation \
    CODE_SIGNING_ALLOWED=NO \
    build

if [[ "$BUILD_IOS" == "1" ]]; then
  run_step "Build IOSWorkspaceDemo" \
    xcodebuild \
      -project "$PROJECT_ROOT/SwiftWorkspace.xcodeproj" \
      -scheme IOSWorkspaceDemo \
      -configuration Debug \
      -destination "$IOS_DESTINATION" \
      -derivedDataPath "$DERIVED_DATA/ios" \
      -skipMacroValidation \
      -skipPackagePluginValidation \
      CODE_SIGNING_ALLOWED=NO \
      build
fi

printf '\nVerification passed.\n'
