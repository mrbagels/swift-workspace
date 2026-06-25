#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
PROJECT_ROOT=$(cd "$SCRIPT_DIR/.." && pwd)

MAC_DESTINATION=${VERIFY_MAC_DESTINATION:-platform=macOS,arch=arm64}
IOS_DESTINATION=${VERIFY_IOS_DESTINATION:-generic/platform=iOS Simulator}
IOS_TEST_DESTINATION=${VERIFY_IOS_TEST_DESTINATION:-}
IOS_TEST_DEVICE_NAME=${VERIFY_IOS_TEST_DEVICE:-iPhone 17 Pro}
DERIVED_DATA=${VERIFY_DERIVED_DATA:-/tmp/swift-workspace-derived-data}
BUILD_IOS=${VERIFY_BUILD_IOS:-0}
RUN_UI_TESTS=${VERIFY_RUN_UI_TESTS:-0}

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

default_ios_test_destination() {
  local requested_name="$1"

  python3 - "$requested_name" <<'PY'
import json
import subprocess
import sys

requested_name = sys.argv[1]
data = json.loads(
    subprocess.check_output(
        ["xcrun", "simctl", "list", "devices", "available", "--json"],
        text=True,
    )
)

matches = []
for runtime_devices in data.get("devices", {}).values():
    for device in runtime_devices:
        name = device.get("name", "")
        udid = device.get("udid")
        if udid and (name == requested_name or name.startswith(f"{requested_name} ")):
            matches.append(device)

booted = [device for device in matches if device.get("state") == "Booted"]
selected = (booted or matches)[0] if matches else None
if selected:
    print(f"platform=iOS Simulator,id={selected['udid']}")
else:
    print(f"platform=iOS Simulator,name={requested_name}")
PY
}

require_command swift
require_command xcodebuild
require_command xcodegen
require_command xcrun
require_command python3

if [[ -z "$IOS_TEST_DESTINATION" ]]; then
  IOS_TEST_DESTINATION=$(default_ios_test_destination "$IOS_TEST_DEVICE_NAME")
fi

run_step "Run swift-workspace doctor" \
  "$PROJECT_ROOT/scripts/doctor.sh"

run_step "Run documentation checks" \
  "$PROJECT_ROOT/scripts/check-docs.sh"

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

run_step "Build MinimalMacWorkspaceApp" \
  xcodebuild \
    -project "$PROJECT_ROOT/SwiftWorkspace.xcodeproj" \
    -scheme MinimalMacWorkspaceApp \
    -configuration Debug \
    -destination "$MAC_DESTINATION" \
    -derivedDataPath "$DERIVED_DATA/minimal-mac" \
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

  run_step "Build MinimalIOSWorkspaceApp" \
    xcodebuild \
      -project "$PROJECT_ROOT/SwiftWorkspace.xcodeproj" \
      -scheme MinimalIOSWorkspaceApp \
      -configuration Debug \
      -destination "$IOS_DESTINATION" \
      -derivedDataPath "$DERIVED_DATA/minimal-ios" \
      -skipMacroValidation \
      -skipPackagePluginValidation \
      CODE_SIGNING_ALLOWED=NO \
      build
fi

if [[ "$RUN_UI_TESTS" == "1" ]]; then
  run_step "Run MacWorkspaceDemo UI smoke tests" \
    xcodebuild \
      -project "$PROJECT_ROOT/SwiftWorkspace.xcodeproj" \
      -scheme MacWorkspaceDemo \
      -configuration Debug \
      -destination "$MAC_DESTINATION" \
      -derivedDataPath "$DERIVED_DATA/mac-ui-tests" \
      -skipMacroValidation \
      -skipPackagePluginValidation \
      CODE_SIGNING_ALLOWED=YES \
      CODE_SIGN_STYLE=Manual \
      CODE_SIGN_IDENTITY=- \
      test

  if [[ "$BUILD_IOS" == "1" ]]; then
    run_step "Run IOSWorkspaceDemo UI smoke tests" \
      xcodebuild \
        -project "$PROJECT_ROOT/SwiftWorkspace.xcodeproj" \
        -scheme IOSWorkspaceDemo \
        -configuration Debug \
        -destination "$IOS_TEST_DESTINATION" \
        -derivedDataPath "$DERIVED_DATA/ios-ui-tests" \
        -skipMacroValidation \
        -skipPackagePluginValidation \
        CODE_SIGNING_ALLOWED=YES \
        CODE_SIGN_STYLE=Manual \
        CODE_SIGN_IDENTITY=- \
        test
  fi
fi

printf '\nVerification passed.\n'
