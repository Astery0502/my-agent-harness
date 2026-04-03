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

assert_file_contains() {
  local path="$1"
  local needle="$2"
  [[ -f "$path" ]] || fail "expected file to exist before checking contents: $path"
  grep -Fq "$needle" "$path" || fail "expected $path to contain: $needle"
}

assert_file_contains_all() {
  local needle="$1"
  shift

  local path
  for path in "$@"; do
    assert_file_contains "$path" "$needle"
  done
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
  git archive --format=tar HEAD
) | (
  cd "$TEST_REPO"
  tar -xf -
)

cd "$TEST_REPO"

./scripts/sync-claude.sh >/dev/null
./scripts/sync-codex.sh --profile codex-only >/dev/null

# Baseline /plan assets should reflect the shared constraint-packet handoff.
baseline_plan_assets=(
  "$TEST_REPO/state/staging/claude/commands/plan.md"
  "$TEST_REPO/state/staging/claude/agents/planner.md"
  "$TEST_REPO/state/staging/claude/skills/tdd-workflow/SKILL.md"
  "$TEST_REPO/state/staging/codex/commands/plan.md"
  "$TEST_REPO/state/staging/codex/shared/agents/planner.md"
  "$TEST_REPO/state/staging/codex/skills/tdd-workflow/SKILL.md"
)
assert_file_contains_all "shared constraint packet handoff" "${baseline_plan_assets[@]}"

# Claude should stage the new opt-in experiment command and skill assets.
assert_file_exists "$TEST_REPO/state/staging/claude/commands/evolution-plan.md"
assert_file_exists "$TEST_REPO/state/staging/claude/skills/evolution-front-experiment/SKILL.md"
assert_file_exists "$TEST_REPO/state/staging/claude/skills/evolution-front-experiment/templates/evidence-chain.md"
assert_file_exists "$TEST_REPO/state/staging/claude/skills/evolution-front-experiment/templates/constraint-packet.md"
claude_experiment_checks=(
  "$TEST_REPO/state/staging/claude/commands/evolution-plan.md|/evolution-plan"
  "$TEST_REPO/state/staging/claude/commands/evolution-plan.md|three operational phases"
  "$TEST_REPO/state/staging/claude/commands/evolution-plan.md|primary artifact"
  "$TEST_REPO/state/staging/claude/commands/evolution-plan.md|evidence chain record"
  "$TEST_REPO/state/staging/claude/commands/evolution-plan.md|probe_evidence"
  "$TEST_REPO/state/staging/claude/commands/evolution-plan.md|reopen_event"
  "$TEST_REPO/state/staging/claude/commands/evolution-plan.md|freeze rule"
  "$TEST_REPO/state/staging/claude/skills/evolution-front-experiment/SKILL.md|opt-in"
  "$TEST_REPO/state/staging/claude/skills/evolution-front-experiment/SKILL.md|three operational phases"
  "$TEST_REPO/state/staging/claude/skills/evolution-front-experiment/SKILL.md|primary artifact"
  "$TEST_REPO/state/staging/claude/skills/evolution-front-experiment/SKILL.md|evidence chain record"
  "$TEST_REPO/state/staging/claude/skills/evolution-front-experiment/SKILL.md|minimum required schema"
  "$TEST_REPO/state/staging/claude/skills/evolution-front-experiment/SKILL.md|probe_evidence"
  "$TEST_REPO/state/staging/claude/skills/evolution-front-experiment/SKILL.md|reopen_event"
  "$TEST_REPO/state/staging/claude/skills/evolution-front-experiment/SKILL.md|freeze rule"
)
for check in "${claude_experiment_checks[@]}"; do
  IFS='|' read -r path needle <<<"$check"
  assert_file_contains "$path" "$needle"
done
assert_file_not_contains "$TEST_REPO/state/staging/claude/commands/evolution-plan.md" "agents/evolution-planner.md"
assert_file_not_contains "$TEST_REPO/state/staging/claude/skills/evolution-front-experiment/SKILL.md" "docs/evidence-chain-model.md"

# Codex should stage the new opt-in experiment command, skill assets, and shared agent.
assert_file_exists "$TEST_REPO/state/staging/codex/commands/evolution-plan.md"
assert_file_exists "$TEST_REPO/state/staging/codex/shared/agents/evolution-planner.md"
assert_file_exists "$TEST_REPO/state/staging/codex/skills/evolution-front-experiment/SKILL.md"
assert_file_exists "$TEST_REPO/state/staging/codex/skills/evolution-front-experiment/templates/evidence-chain.md"
assert_file_exists "$TEST_REPO/state/staging/codex/skills/evolution-front-experiment/templates/constraint-packet.md"
codex_experiment_checks=(
  "$TEST_REPO/state/staging/codex/commands/evolution-plan.md|/evolution-plan"
  "$TEST_REPO/state/staging/codex/commands/evolution-plan.md|three operational phases"
  "$TEST_REPO/state/staging/codex/commands/evolution-plan.md|primary artifact"
  "$TEST_REPO/state/staging/codex/commands/evolution-plan.md|evidence chain record"
  "$TEST_REPO/state/staging/codex/commands/evolution-plan.md|probe_evidence"
  "$TEST_REPO/state/staging/codex/commands/evolution-plan.md|reopen_event"
  "$TEST_REPO/state/staging/codex/commands/evolution-plan.md|freeze rule"
  "$TEST_REPO/state/staging/codex/skills/evolution-front-experiment/SKILL.md|opt-in"
  "$TEST_REPO/state/staging/codex/skills/evolution-front-experiment/SKILL.md|three operational phases"
  "$TEST_REPO/state/staging/codex/skills/evolution-front-experiment/SKILL.md|primary artifact"
  "$TEST_REPO/state/staging/codex/skills/evolution-front-experiment/SKILL.md|evidence chain record"
  "$TEST_REPO/state/staging/codex/skills/evolution-front-experiment/SKILL.md|minimum required schema"
  "$TEST_REPO/state/staging/codex/skills/evolution-front-experiment/SKILL.md|probe_evidence"
  "$TEST_REPO/state/staging/codex/skills/evolution-front-experiment/SKILL.md|reopen_event"
  "$TEST_REPO/state/staging/codex/skills/evolution-front-experiment/SKILL.md|freeze rule"
)
for check in "${codex_experiment_checks[@]}"; do
  IFS='|' read -r path needle <<<"$check"
  assert_file_contains "$path" "$needle"
done
assert_file_not_contains "$TEST_REPO/state/staging/codex/commands/plan.md" "agents/planner.md"
assert_file_not_contains "$TEST_REPO/state/staging/codex/commands/evolution-plan.md" "agents/evolution-planner.md"
assert_file_not_contains "$TEST_REPO/state/staging/codex/skills/evolution-front-experiment/SKILL.md" "docs/evidence-chain-model.md"

# The challenger evidence-chain template should match the minimum required schema.
evidence_chain_schema_fields=(
  clarified_request
  suspect_claims
  candidate_strategies
  accepted_constraints
  rejected_constraints
  probe_evidence
  frozen_decision
  verification_target
  reopen_trigger
)
for field in "${evidence_chain_schema_fields[@]}"; do
  assert_file_contains "$TEST_REPO/state/staging/claude/skills/evolution-front-experiment/templates/evidence-chain.md" "$field"
  assert_file_contains "$TEST_REPO/state/staging/codex/skills/evolution-front-experiment/templates/evidence-chain.md" "$field"
done

assert_file_contains_all "reopen_event" \
  "$TEST_REPO/state/staging/claude/skills/evolution-front-experiment/templates/evidence-chain.md" \
  "$TEST_REPO/state/staging/codex/skills/evolution-front-experiment/templates/evidence-chain.md"
assert_file_contains_all "freeze rule" \
  "$TEST_REPO/state/staging/claude/skills/evolution-front-experiment/templates/evidence-chain.md" \
  "$TEST_REPO/state/staging/codex/skills/evolution-front-experiment/templates/evidence-chain.md"
assert_file_not_contains "$TEST_REPO/state/staging/claude/skills/evolution-front-experiment/templates/evidence-chain.md" "docs/evidence-chain-model.md"
assert_file_not_contains "$TEST_REPO/state/staging/codex/skills/evolution-front-experiment/templates/evidence-chain.md" "docs/evidence-chain-model.md"

# The frozen constraint packet handoff should preserve its explicit downstream contract.
constraint_packet_fields=(
  task_statement
  clarified_assumptions
  rejected_interpretations
  chosen_direction
  open_risks
  probe_evidence
  draft_acceptance_criteria
  verification_target
)
for field in "${constraint_packet_fields[@]}"; do
  assert_file_contains "$TEST_REPO/state/staging/claude/skills/evolution-front-experiment/templates/constraint-packet.md" "$field"
  assert_file_contains "$TEST_REPO/state/staging/codex/skills/evolution-front-experiment/templates/constraint-packet.md" "$field"
done
assert_file_contains_all "frozen handoff" \
  "$TEST_REPO/state/staging/claude/skills/evolution-front-experiment/templates/constraint-packet.md" \
  "$TEST_REPO/state/staging/codex/skills/evolution-front-experiment/templates/constraint-packet.md"

echo "PASS: evolution-front experiment integration"
