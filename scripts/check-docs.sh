#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
PROJECT_ROOT=$(cd "$SCRIPT_DIR/.." && pwd)

failures=0

fail() {
  printf 'error: %s\n' "$*" >&2
  failures=$((failures + 1))
}

ok() {
  printf 'ok: %s\n' "$*"
}

require_command() {
  local name="$1"

  if command -v "$name" >/dev/null 2>&1; then
    ok "found $name ($(command -v "$name"))"
  else
    fail "required command not found: $name"
  fi
}

require_file() {
  local path="$1"

  if [[ -f "$PROJECT_ROOT/$path" ]]; then
    ok "found $path"
  else
    fail "missing $path"
  fi
}

require_nonempty_file() {
  local path="$1"

  require_file "$path"
  if [[ -s "$PROJECT_ROOT/$path" ]]; then
    ok "$path is nonempty"
  else
    fail "$path must not be empty"
  fi
}

require_command python3

python3 -m json.tool "$PROJECT_ROOT/docs/llm/manifest.json" >/dev/null
ok "docs/llm/manifest.json is valid JSON"

while IFS= read -r path; do
  require_file "$path"
done < <(
  python3 - "$PROJECT_ROOT/docs/llm/manifest.json" <<'PY'
import json
import sys

with open(sys.argv[1], encoding="utf-8") as file:
    manifest = json.load(file)

for entry in manifest["entrypoints"]:
    print(entry["path"])
PY
)

docc_catalogs=(
  "Sources/WorkspaceCore/WorkspaceCore.docc/WorkspaceCore.md"
  "Sources/WorkspaceTCA/WorkspaceTCA.docc/WorkspaceTCA.md"
  "Sources/WorkspaceEngine/WorkspaceEngine.docc/WorkspaceEngine.md"
  "Sources/WorkspacePersistence/WorkspacePersistence.docc/WorkspacePersistence.md"
  "Sources/WorkspaceSQLiteData/WorkspaceSQLiteData.docc/WorkspaceSQLiteData.md"
  "Sources/WorkspaceCloudKit/WorkspaceCloudKit.docc/WorkspaceCloudKit.md"
  "Sources/MacWorkspaceShell/MacWorkspaceShell.docc/MacWorkspaceShell.md"
  "Sources/IOSWorkspaceShell/IOSWorkspaceShell.docc/IOSWorkspaceShell.md"
)

for catalog in "${docc_catalogs[@]}"; do
  require_nonempty_file "$catalog"
  if grep -q '^# ' "$PROJECT_ROOT/$catalog"; then
    ok "$catalog has a top-level title"
  else
    fail "$catalog must include a top-level title"
  fi
done

if grep -R "—" "$PROJECT_ROOT/README.md" "$PROJECT_ROOT/docs" >/dev/null 2>&1; then
  fail "public docs must avoid em dash characters"
else
  ok "public docs avoid em dash characters"
fi

if ((failures > 0)); then
  printf '\nDocumentation check found %d issue(s).\n' "$failures" >&2
  exit 1
fi

printf '\nDocumentation check passed.\n'
