#!/usr/bin/env bash
# Shared test helpers for harness ops tests.
# Source this file from test scripts. Call test_setup_repo before running tests.

export LC_ALL=C
export LANG=C

TEST_HELPERS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEST_ROOT_DIR="$(cd "$TEST_HELPERS_DIR/../.." && pwd)"

TMP_DIR=""
TEST_REPO=""
TEST_HOME=""

fail() {
  echo "FAIL: $*" >&2
  exit 1
}

test_cleanup() {
  [[ -n "$TMP_DIR" && -d "$TMP_DIR" ]] && rm -rf "$TMP_DIR"
}

test_setup_repo() {
  TMP_DIR="$(mktemp -d)"
  TEST_REPO="$TMP_DIR/repo"
  TEST_HOME="$TMP_DIR/home"
  trap test_cleanup EXIT

  mkdir -p "$TEST_REPO" "$TEST_HOME/.claude" "$TEST_HOME/.codex"

  (
    cd "$TEST_ROOT_DIR"
    tar --exclude='./.git' --exclude='./.worktrees' --exclude='./.local' -cf - .
  ) | (
    cd "$TEST_REPO"
    tar -xf -
  )

  cd "$TEST_REPO"
}

# --- Assert helpers ---

assert_contains() {
  local haystack="$1"
  local needle="$2"
  [[ "$haystack" == *"$needle"* ]] || fail "expected output to contain: $needle\ngot: $haystack"
}

assert_not_contains() {
  local haystack="$1"
  local needle="$2"
  [[ "$haystack" != *"$needle"* ]] || fail "expected output to NOT contain: $needle"
}

assert_file_exists() {
  local path="$1"
  [[ -f "$path" ]] || fail "expected file to exist: $path"
}

assert_dir_exists() {
  local path="$1"
  [[ -d "$path" ]] || fail "expected directory to exist: $path"
}

assert_file_missing() {
  local path="$1"
  [[ ! -e "$path" ]] || fail "expected path to be absent: $path"
}

assert_file_contains() {
  local path="$1"
  local needle="$2"
  [[ -f "$path" ]] || fail "expected file to exist before checking contents: $path"
  grep -Fq "$needle" "$path" || fail "expected $path to contain: $needle"
}

assert_file_not_contains() {
  local path="$1"
  local needle="$2"
  [[ -f "$path" ]] || fail "expected file to exist before checking contents: $path"
  if grep -Fq "$needle" "$path"; then
    fail "expected $path to NOT contain: $needle"
  fi
}

assert_json_expr() {
  local file="$1"
  local expr="$2"
  jq -e "$expr" "$file" >/dev/null || fail "json assertion failed: $file :: $expr"
}

assert_exit_success() {
  if ! "$@" >/dev/null 2>&1; then
    fail "expected command to succeed: $*"
  fi
}

assert_exit_failure() {
  if "$@" >/dev/null 2>&1; then
    fail "expected command to fail: $*"
  fi
}

# --- Runner helpers ---

run_sync() {
  HOME="$TEST_HOME" ./scripts/sync.sh "$@"
}

run_doctor() {
  HOME="$TEST_HOME" ./scripts/doctor.sh "$@"
}

run_repair() {
  HOME="$TEST_HOME" ./scripts/repair.sh "$@"
}

run_list() {
  HOME="$TEST_HOME" ./scripts/list-installed.sh "$@"
}
