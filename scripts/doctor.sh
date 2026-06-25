#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
PROJECT_ROOT=$(cd "$SCRIPT_DIR/.." && pwd)

failures=0

ok() {
  printf 'ok: %s\n' "$*"
}

warn() {
  printf 'warning: %s\n' "$*" >&2
}

fail() {
  printf 'error: %s\n' "$*" >&2
  failures=$((failures + 1))
}

require_command() {
  local name="$1"

  if command -v "$name" >/dev/null 2>&1; then
    ok "found $name ($(command -v "$name"))"
  else
    fail "required command not found: $name"
  fi
}

require_path() {
  local path="$1"

  if [[ -e "$PROJECT_ROOT/$path" ]]; then
    ok "found $path"
  else
    fail "missing $path"
  fi
}

require_ignored() {
  local path="$1"

  if git -C "$PROJECT_ROOT" check-ignore -q -- "$path"; then
    ok "$path is ignored"
  else
    fail "$path must be ignored"
  fi
}

print_version() {
  local label="$1"
  shift
  local output

  if output=$("$@" 2>/dev/null); then
    output=${output%%$'\n'*}
    ok "$label: $output"
  else
    warn "could not read $label"
  fi
}

require_command git
require_command python3
require_command swift
require_command xcodebuild
require_command xcodegen
require_command xcrun

print_version "Swift" swift --version
print_version "Xcode" xcodebuild -version
if sdk_version=$(xcrun --sdk macosx --show-sdk-version 2>/dev/null); then
  ok "macOS SDK: $sdk_version"
else
  warn "could not read macOS SDK version"
fi

require_path "Package.swift"
require_path "project.yml"
require_path "Sources/WorkspaceCore"
require_path "Sources/WorkspaceTCA"
require_path "Sources/MacWorkspaceShell"
require_path "Sources/IOSWorkspaceShell"
require_path "Apps/MacWorkspaceDemo"
require_path "Apps/MacWorkspaceDemoUITests/MacWorkspaceDemoUITests.swift"
require_path "Apps/IOSWorkspaceDemo"
require_path "Apps/IOSWorkspaceDemoUITests/IOSWorkspaceDemoUITests.swift"
require_path "Examples/CustomRendererClient/Package.swift"
require_path "Examples/MinimalMacWorkspaceApp/MinimalMacWorkspaceApp.swift"
require_path "Examples/MinimalIOSWorkspaceApp/MinimalIOSWorkspaceApp.swift"
require_path "scripts/check-docs.sh"
require_path "docs/llm/START_HERE.md"
require_path "docs/llm/manifest.json"
require_path "docs/architecture/workspace-engine-split.md"
require_path "docs/product/phased-implementation-plan.md"

require_ignored "SwiftWorkspace.xcodeproj/"
require_ignored ".build/"
require_ignored ".swiftpm/"

if ((failures > 0)); then
  printf '\nDoctor found %d issue(s).\n' "$failures" >&2
  exit 1
fi

printf '\nDoctor passed.\n'
