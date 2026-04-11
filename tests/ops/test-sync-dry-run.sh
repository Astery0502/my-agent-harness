#!/usr/bin/env bash
set -euo pipefail

TESTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$TESTS_DIR/lib/test-helpers.sh"
test_setup_repo

# 1. Dry-run produces expected output
dry_output="$(run_sync --platform claude --dry-run)"
assert_contains "$dry_output" "dry-run: no changes applied"
assert_contains "$dry_output" "platform: claude"
assert_contains "$dry_output" "profile: claude-only"
assert_contains "$dry_output" "CLAUDE.md"
assert_contains "$dry_output" "agents"
assert_contains "$dry_output" "skills"
assert_contains "$dry_output" "commands"
assert_contains "$dry_output" "rules"
assert_contains "$dry_output" "digests:"

# 2. Dry-run does NOT create files in live target
assert_file_missing "$TEST_HOME/.claude/CLAUDE.md"
assert_file_missing "$TEST_HOME/.claude/agents"

# 3. Dry-run does NOT create state file
assert_file_missing "$TEST_REPO/.local/install-state/live/claude.json"

# 4. Dry-run with staging does not create staging directory
dry_output="$(run_sync --platform codex --profile codex-only --target staging --dry-run)"
assert_contains "$dry_output" "dry-run: no changes applied"
assert_contains "$dry_output" "target: staging"
assert_file_missing "$TEST_REPO/.local/staging/codex"

# 5. Real sync after dry-run works correctly
sync_output="$(run_sync --platform claude)"
assert_contains "$sync_output" "sync: installed"
assert_file_exists "$TEST_HOME/.claude/CLAUDE.md"

echo "PASS: sync dry-run"
