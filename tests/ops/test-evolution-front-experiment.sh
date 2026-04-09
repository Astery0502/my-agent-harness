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

assert_file_exists() {
  local path="$1"
  [[ -f "$path" ]] || fail "expected file to exist: $path"
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
    fail "expected $path to not contain: $needle"
  fi
}

trap cleanup EXIT

mkdir -p "$TEST_REPO"

(
  cd "$ROOT_DIR"
  tar --exclude='./.git' --exclude='./.worktrees' --exclude='./.local' -cf - .
) | (
  cd "$TEST_REPO"
  tar -xf -
)

cd "$TEST_REPO"

./scripts/sync-claude.sh >/dev/null
./scripts/sync-codex.sh --profile codex-only >/dev/null

assert_file_exists "$TEST_REPO/.local/staging/claude/commands/evolution-plan.md"
assert_file_exists "$TEST_REPO/.local/staging/claude/agents/evolution-planner.md"
assert_file_exists "$TEST_REPO/.local/staging/claude/skills/evolution-front-experiment/SKILL.md"
assert_file_exists "$TEST_REPO/.local/staging/claude/skills/evolution-front-experiment/templates/evidence-chain.md"
assert_file_exists "$TEST_REPO/.local/staging/claude/skills/evolution-front-experiment/templates/constraint-packet.md"

assert_file_exists "$TEST_REPO/.local/staging/codex/prompts/evolution-plan.md"
assert_file_exists "$TEST_REPO/.local/staging/codex/shared-agents/evolution-planner.md"
assert_file_exists "$TEST_REPO/.local/staging/codex/skills/evolution-front-experiment/SKILL.md"
assert_file_exists "$TEST_REPO/.local/staging/codex/skills/evolution-front-experiment/templates/evidence-chain.md"
assert_file_exists "$TEST_REPO/.local/staging/codex/skills/evolution-front-experiment/templates/constraint-packet.md"

for path in \
  "$TEST_REPO/.local/staging/claude/commands/evolution-plan.md" \
  "$TEST_REPO/.local/staging/codex/prompts/evolution-plan.md"
do
  assert_file_contains "$path" "/evolution-plan"
  assert_file_contains "$path" "evolution planner agent"
  assert_file_contains "$path" "evolution-front-experiment"
  assert_file_contains "$path" "evidence chain record"
  assert_file_contains "$path" "probe_evidence"
  assert_file_contains "$path" "reopen_event"
  assert_file_not_contains "$path" "agents/evolution-planner.md"
done

for path in \
  "$TEST_REPO/.local/staging/claude/agents/evolution-planner.md" \
  "$TEST_REPO/.local/staging/codex/shared-agents/evolution-planner.md"
do
  assert_file_contains "$path" "opt-in evolution-front experiment"
  assert_file_contains "$path" "constraint packet"
done

for path in \
  "$TEST_REPO/.local/staging/claude/skills/evolution-front-experiment/SKILL.md" \
  "$TEST_REPO/.local/staging/codex/skills/evolution-front-experiment/SKILL.md"
do
  assert_file_contains "$path" "opt-in"
  assert_file_contains "$path" "three operational phases"
  assert_file_contains "$path" "evidence chain record"
  assert_file_contains "$path" "minimum required schema"
  assert_file_contains "$path" "reopen_event"
done

for field in \
  clarified_request \
  suspect_claims \
  candidate_strategies \
  accepted_constraints \
  rejected_constraints \
  probe_evidence \
  frozen_decision \
  verification_target \
  reopen_trigger
do
  assert_file_contains "$TEST_REPO/.local/staging/claude/skills/evolution-front-experiment/templates/evidence-chain.md" "$field"
  assert_file_contains "$TEST_REPO/.local/staging/codex/skills/evolution-front-experiment/templates/evidence-chain.md" "$field"
done

for field in \
  task_statement \
  clarified_assumptions \
  rejected_interpretations \
  chosen_direction \
  open_risks \
  probe_evidence \
  draft_acceptance_criteria \
  verification_target
do
  assert_file_contains "$TEST_REPO/.local/staging/claude/skills/evolution-front-experiment/templates/constraint-packet.md" "$field"
  assert_file_contains "$TEST_REPO/.local/staging/codex/skills/evolution-front-experiment/templates/constraint-packet.md" "$field"
done

echo "PASS: evolution-front experiment integration"
