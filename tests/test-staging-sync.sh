#!/usr/bin/env bash
set -euo pipefail

export LC_ALL=C
export LANG=C

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP_DIR="$(mktemp -d)"
TEST_REPO="$TMP_DIR/repo"

cleanup() {
  rm -rf "$TMP_DIR"
}

fail() {
  echo "FAIL: $*" >&2
  exit 1
}

assert_file_exists() {
  local path="$1"
  [[ -f "$path" ]] || fail "expected file to exist: $path"
}

assert_file_missing() {
  local path="$1"
  [[ ! -e "$path" ]] || fail "expected path to be absent: $path"
}

assert_json_expr() {
  local file="$1"
  local expr="$2"
  jq -e "$expr" "$file" >/dev/null || fail "json assertion failed: $file :: $expr"
}

mkdir -p "$TEST_REPO"

(
  cd "$ROOT_DIR"
  tar --exclude='./.git' -cf - .
) | (
  cd "$TEST_REPO"
  tar -xf -
)

cd "$TEST_REPO"

./scripts/sync-claude.sh

assert_file_exists "$TEST_REPO/state/staging/claude/AGENTS.md"
assert_file_exists "$TEST_REPO/state/staging/claude/agents/planner.md"
assert_json_expr "$TEST_REPO/state/claude-install-state.json" '.status == "installed"'
assert_json_expr "$TEST_REPO/state/claude-install-state.json" '.profile == "minimal"'
CLAUDE_STAGE_ROOT="$(realpath "$TEST_REPO/state/staging/claude")"
assert_json_expr "$TEST_REPO/state/claude-install-state.json" ".targetRoot == \"$CLAUDE_STAGE_ROOT\""

touch "$TEST_REPO/state/staging/claude/SHOULD_BE_REMOVED"
./scripts/sync-claude.sh
assert_file_missing "$TEST_REPO/state/staging/claude/SHOULD_BE_REMOVED"

./scripts/sync-codex.sh --profile codex-only

assert_file_exists "$TEST_REPO/state/staging/codex/AGENTS.md"
assert_file_exists "$TEST_REPO/state/staging/codex/config.toml"
assert_file_exists "$TEST_REPO/state/staging/codex/shared/agents/planner.md"
assert_json_expr "$TEST_REPO/state/codex-install-state.json" '.status == "installed"'
assert_json_expr "$TEST_REPO/state/codex-install-state.json" '.profile == "codex-only"'
CODEX_STAGE_ROOT="$(realpath "$TEST_REPO/state/staging/codex")"
assert_json_expr "$TEST_REPO/state/codex-install-state.json" ".targetRoot == \"$CODEX_STAGE_ROOT\""

echo "PASS: staging sync integration"
