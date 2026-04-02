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

assert_contains() {
  local haystack="$1"
  local needle="$2"
  [[ "$haystack" == *"$needle"* ]] || fail "expected output to contain: $needle"
}

assert_json_expr() {
  local file="$1"
  local expr="$2"
  jq -e "$expr" "$file" >/dev/null || fail "json assertion failed: $file :: $expr"
}

trap cleanup EXIT

mkdir -p "$TEST_REPO"

(
  cd "$ROOT_DIR"
  tar --exclude='./.git' --exclude='./.worktrees' -cf - .
) | (
  cd "$TEST_REPO"
  tar -xf -
)

cd "$TEST_REPO"

list_output="$(./scripts/list-installed.sh)"
assert_contains "$list_output" "claude"
assert_contains "$list_output" "codex"
assert_contains "$list_output" "not-installed"

./scripts/sync-claude.sh >/dev/null
./scripts/sync-codex.sh --profile codex-only >/dev/null

doctor_output="$(./scripts/doctor.sh)"
assert_contains "$doctor_output" "claude"
assert_contains "$doctor_output" "codex"
assert_contains "$doctor_output" "healthy"

printf '\n# drift\n' >> "$TEST_REPO/state/staging/claude/AGENTS.md"

if ./scripts/doctor.sh >/tmp/local-ops-doctor.out 2>&1; then
  fail "doctor should fail after staged drift"
fi

assert_contains "$(cat /tmp/local-ops-doctor.out)" "drifted"

repair_output="$(./scripts/repair.sh)"
assert_contains "$repair_output" "claude"
assert_contains "$repair_output" "codex"
assert_contains "$repair_output" "repaired"

doctor_output="$(./scripts/doctor.sh)"
assert_contains "$doctor_output" "healthy"

assert_json_expr "$TEST_REPO/state/claude-install-state.json" '.status == "installed"'
assert_json_expr "$TEST_REPO/state/codex-install-state.json" '.status == "installed"'

echo "PASS: local ops integration"
