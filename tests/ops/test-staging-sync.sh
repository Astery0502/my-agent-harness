#!/usr/bin/env bash
set -euo pipefail

export LC_ALL=C
export LANG=C

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
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

assert_file_exists() {
  local path="$1"
  [[ -f "$path" ]] || fail "expected file to exist: $path"
}

assert_file_contains() {
  local path="$1"
  local needle="$2"
  grep -Fq "$needle" "$path" || fail "expected file to contain: $path :: $needle"
}

assert_file_not_contains() {
  local path="$1"
  local needle="$2"
  ! grep -Fq "$needle" "$path" || fail "expected file not to contain: $path :: $needle"
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
  tar --exclude='./.git' --exclude='./.worktrees' --exclude='./.local' -cf - .
) | (
  cd "$TEST_REPO"
  tar -xf -
)

cd "$TEST_REPO"

./scripts/sync-claude.sh

assert_file_exists "$TEST_REPO/.local/staging/claude/CLAUDE.md"
assert_file_exists "$TEST_REPO/.local/staging/claude/agents/planner.md"
assert_file_exists "$TEST_REPO/.local/staging/claude/commands/plan.md"
assert_file_exists "$TEST_REPO/.local/staging/claude/skills/planning-protocol/SKILL.md"
assert_file_exists "$TEST_REPO/.local/staging/claude/skills/planning-protocol/references/lifecycle.md"
assert_file_exists "$TEST_REPO/.local/staging/claude/skills/planning-protocol/references/artifacts.md"
assert_file_exists "$TEST_REPO/.local/staging/claude/skills/planning-protocol/assets/plan-e-template.md"
assert_file_exists "$TEST_REPO/.local/staging/claude/skills/planning-protocol/assets/plan-h-template.md"
assert_file_contains "$TEST_REPO/.local/staging/claude/commands/plan.md" "planning-protocol"
assert_file_contains "$TEST_REPO/.local/staging/claude/agents/planner.md" "request_invariant"
assert_file_contains "$TEST_REPO/.local/staging/claude/skills/planning-protocol/assets/plan-h-template.md" "reopen_triggers"
assert_file_missing "$TEST_REPO/.local/staging/claude/AGENTS.md"
assert_file_missing "$TEST_REPO/.local/staging/claude/CLAUDE.base.md"
assert_file_not_contains "$TEST_REPO/.local/staging/claude/commands/plan.md" "runtime/"
assert_file_not_contains "$TEST_REPO/.local/staging/claude/agents/planner.md" "runtime/"
assert_json_expr "$TEST_REPO/.local/install-state/claude.json" '.status == "installed"'
assert_json_expr "$TEST_REPO/.local/install-state/claude.json" '.profile == "claude-only"'
CLAUDE_STAGE_ROOT="$(realpath "$TEST_REPO/.local/staging/claude")"
assert_json_expr "$TEST_REPO/.local/install-state/claude.json" ".targetRoot == \"$CLAUDE_STAGE_ROOT\""

touch "$TEST_REPO/.local/staging/claude/SHOULD_BE_REMOVED"
./scripts/sync-claude.sh
assert_file_missing "$TEST_REPO/.local/staging/claude/SHOULD_BE_REMOVED"

./scripts/sync-codex.sh --profile codex-only

assert_file_exists "$TEST_REPO/.local/staging/codex/AGENTS.md"
assert_file_exists "$TEST_REPO/.local/staging/codex/config.toml"
assert_file_exists "$TEST_REPO/.local/staging/codex/prompts/plan.md"
assert_file_exists "$TEST_REPO/.local/staging/codex/agents/explorer.toml"
assert_file_exists "$TEST_REPO/.local/staging/codex/shared-agents/planner.md"
assert_file_exists "$TEST_REPO/.local/staging/codex/skills/planning-protocol/SKILL.md"
assert_file_exists "$TEST_REPO/.local/staging/codex/rules/common/testing.md"
assert_file_contains "$TEST_REPO/.local/staging/codex/prompts/plan.md" "plan-h"
assert_file_contains "$TEST_REPO/.local/staging/codex/prompts/plan.md" "planning-protocol"
assert_file_contains "$TEST_REPO/.local/staging/codex/skills/planning-protocol/assets/plan-h-template.md" "reopen_triggers"
assert_file_missing "$TEST_REPO/.local/staging/codex/AGENTS.supplement.md"
assert_file_missing "$TEST_REPO/.local/staging/codex/commands"
assert_file_missing "$TEST_REPO/.local/staging/codex/shared"
assert_file_not_contains "$TEST_REPO/.local/staging/codex/prompts/plan.md" "runtime/"
assert_file_not_contains "$TEST_REPO/.local/staging/codex/shared-agents/planner.md" "runtime/"
assert_json_expr "$TEST_REPO/.local/install-state/codex.json" '.status == "installed"'
assert_json_expr "$TEST_REPO/.local/install-state/codex.json" '.profile == "codex-only"'
CODEX_STAGE_ROOT="$(realpath "$TEST_REPO/.local/staging/codex")"
assert_json_expr "$TEST_REPO/.local/install-state/codex.json" ".targetRoot == \"$CODEX_STAGE_ROOT\""

tmp_install_map="$(mktemp)"
jq 'del(.mappings[] | select(.source == "runtime/skills"))' \
  "$TEST_REPO/runtime/platforms/codex/install-map.json" > "$tmp_install_map"
mv "$tmp_install_map" "$TEST_REPO/runtime/platforms/codex/install-map.json"

if ./scripts/sync-codex.sh --profile codex-only >/tmp/staging-sync-codex.out 2>&1; then
  fail "sync-codex should fail when a selected component has no install-map target"
fi

assert_contains "$(cat /tmp/staging-sync-codex.out)" "selected component has no install-map target for platform: shared-skills"

echo "PASS: staging sync integration"
