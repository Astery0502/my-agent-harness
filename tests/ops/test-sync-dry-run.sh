#!/usr/bin/env bash
set -euo pipefail

TESTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$TESTS_DIR/lib/test-helpers.sh"
test_setup_fixture

# 1. Dry-run produces the stable report fields and summary.
dry_output="$(run_sync --platform claude --dry-run)"
assert_contains "$dry_output" "dry-run: no changes applied"
assert_report_field "$dry_output" "platform" "claude"
assert_report_field "$dry_output" "profile" "claude-only"
assert_contains "$dry_output" "digests:"

# 2. Dry-run does NOT create files in live target.
assert_file_missing "$TEST_HOME/.claude/shared.md"
assert_file_missing "$TEST_HOME/.claude/platform.md"

# 3. Dry-run does NOT create state file.
assert_file_missing "$TEST_REPO/.local/install-state/live/claude.json"

# 4. Dry-run with staging does not create staging directory.
dry_output="$(run_sync --platform codex --profile codex-only --target staging --dry-run)"
assert_contains "$dry_output" "dry-run: no changes applied"
assert_report_field "$dry_output" "target" "staging"
assert_file_missing "$TEST_REPO/.local/staging/codex"

# 5. Real sync after dry-run records the installed state.
sync_output="$(run_sync --platform claude)"
assert_contains "$sync_output" "sync: installed"
state_file="$TEST_REPO/.local/install-state/live/claude.json"
assert_json_expr "$state_file" '.status == "installed"'
assert_json_expr "$state_file" '.profile == "claude-only"'
assert_json_expr "$state_file" ".targetRoot == \"$(realpath "$TEST_HOME/.claude")\""
assert_state_has_target "$state_file" "shared-root" "shared.md"
assert_state_has_target "$state_file" "claude-platform" "platform.md"

echo "PASS: sync dry-run"
