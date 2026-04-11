#!/usr/bin/env bash
set -euo pipefail

TESTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$TESTS_DIR/lib/test-helpers.sh"
test_setup_repo

# Sync both platforms to staging for content validation
run_sync --platform claude --target staging >/dev/null
run_sync --platform codex --profile codex-only --target staging >/dev/null

# === Claude staging content ===

# 1. Core files exist
assert_file_exists "$TEST_REPO/.local/staging/claude/CLAUDE.md"
assert_dir_exists "$TEST_REPO/.local/staging/claude/agents"
assert_dir_exists "$TEST_REPO/.local/staging/claude/skills"
assert_dir_exists "$TEST_REPO/.local/staging/claude/commands"
assert_dir_exists "$TEST_REPO/.local/staging/claude/rules"

# 2. CLAUDE.md is a concat of HARNESS.md + CLAUDE.base.md
assert_file_contains "$TEST_REPO/.local/staging/claude/CLAUDE.md" "HARNESS.md"
assert_file_contains "$TEST_REPO/.local/staging/claude/CLAUDE.md" "Behavioral guidelines"

# 3. Agent files
assert_file_exists "$TEST_REPO/.local/staging/claude/agents/planner.md"
assert_file_contains "$TEST_REPO/.local/staging/claude/agents/planner.md" "switch roles explicitly"
assert_file_contains "$TEST_REPO/.local/staging/claude/skills/planning-protocol/references/lifecycle.md" "request_invariant"

# 4. Command files
assert_file_exists "$TEST_REPO/.local/staging/claude/commands/plan.md"
assert_file_contains "$TEST_REPO/.local/staging/claude/commands/plan.md" "planning-protocol"

# 5. Skill files
assert_file_exists "$TEST_REPO/.local/staging/claude/skills/planning-protocol/SKILL.md"
assert_file_exists "$TEST_REPO/.local/staging/claude/skills/planning-protocol/references/lifecycle.md"
assert_file_exists "$TEST_REPO/.local/staging/claude/skills/planning-protocol/references/artifacts.md"
assert_file_exists "$TEST_REPO/.local/staging/claude/skills/planning-protocol/assets/plan-e-template.md"
assert_file_exists "$TEST_REPO/.local/staging/claude/skills/planning-protocol/assets/plan-h-template.md"
assert_file_contains "$TEST_REPO/.local/staging/claude/skills/planning-protocol/assets/plan-h-template.md" "reopen_triggers"
assert_file_exists "$TEST_REPO/.local/staging/claude/skills/planning-protocol/assets/constraint-packet.md"
assert_file_contains "$TEST_REPO/.local/staging/claude/skills/planning-protocol/assets/constraint-packet.md" "reopen_target"

# 6. No leaked source files
assert_file_missing "$TEST_REPO/.local/staging/claude/CLAUDE.base.md"
assert_file_missing "$TEST_REPO/.local/staging/claude/AGENTS.md"

# 7. No runtime/ paths in deployed command content
assert_file_not_contains "$TEST_REPO/.local/staging/claude/commands/plan.md" "runtime/"
assert_file_not_contains "$TEST_REPO/.local/staging/claude/agents/planner.md" "runtime/"

# === Codex staging content ===

# 8. Core files exist
assert_file_exists "$TEST_REPO/.local/staging/codex/AGENTS.md"
assert_file_exists "$TEST_REPO/.local/staging/codex/config.toml"
assert_dir_exists "$TEST_REPO/.local/staging/codex/shared-agents"
assert_dir_exists "$TEST_REPO/.local/staging/codex/skills"
assert_dir_exists "$TEST_REPO/.local/staging/codex/prompts"
assert_dir_exists "$TEST_REPO/.local/staging/codex/rules"

# 9. AGENTS.md is concat of HARNESS.md + AGENTS.supplement.md
assert_file_contains "$TEST_REPO/.local/staging/codex/AGENTS.md" "HARNESS.md"
assert_file_contains "$TEST_REPO/.local/staging/codex/AGENTS.md" "Behavioral guidelines"

# 10. Codex-specific agents (placeholder agents removed; mapping removed)

# 11. Shared agents in shared-agents/
assert_file_exists "$TEST_REPO/.local/staging/codex/shared-agents/planner.md"
assert_file_exists "$TEST_REPO/.local/staging/codex/shared-agents/debugger.md"

# 12. Commands mapped to prompts/ (not commands/)
assert_file_exists "$TEST_REPO/.local/staging/codex/prompts/plan.md"
assert_file_contains "$TEST_REPO/.local/staging/codex/prompts/plan.md" "planning-protocol"
assert_file_missing "$TEST_REPO/.local/staging/codex/commands"

# 13. Skills
assert_file_contains "$TEST_REPO/.local/staging/codex/skills/tdd-workflow/SKILL.md" "name: tdd-workflow"
assert_file_contains "$TEST_REPO/.local/staging/codex/skills/planning-protocol/assets/plan-h-template.md" "reopen_triggers"

# 14. Rules (placeholder rules removed; directory still synced)

# 15. No leaked source files
assert_file_missing "$TEST_REPO/.local/staging/codex/AGENTS.supplement.md"
assert_file_missing "$TEST_REPO/.local/staging/codex/config.base.toml"

# 16. No runtime/ paths in deployed content
assert_file_not_contains "$TEST_REPO/.local/staging/codex/prompts/plan.md" "runtime/"
assert_file_not_contains "$TEST_REPO/.local/staging/codex/shared-agents/planner.md" "runtime/"

# === Evolution-front experiment content ===

# 17. Claude evolution-front files
assert_file_exists "$TEST_REPO/.local/staging/claude/commands/evolution-plan.md"
assert_file_exists "$TEST_REPO/.local/staging/claude/agents/evolution-planner.md"
assert_file_exists "$TEST_REPO/.local/staging/claude/skills/evolution-front-experiment/SKILL.md"
assert_file_exists "$TEST_REPO/.local/staging/claude/skills/evolution-front-experiment/templates/evidence-chain.md"
assert_file_exists "$TEST_REPO/.local/staging/claude/skills/evolution-front-experiment/templates/constraint-packet.md"

# 18. Codex evolution-front files
assert_file_exists "$TEST_REPO/.local/staging/codex/prompts/evolution-plan.md"
assert_file_exists "$TEST_REPO/.local/staging/codex/shared-agents/evolution-planner.md"
assert_file_exists "$TEST_REPO/.local/staging/codex/skills/evolution-front-experiment/SKILL.md"
assert_file_exists "$TEST_REPO/.local/staging/codex/skills/evolution-front-experiment/templates/evidence-chain.md"
assert_file_exists "$TEST_REPO/.local/staging/codex/skills/evolution-front-experiment/templates/constraint-packet.md"

# 19. Evolution plan command content
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

# 20. Evolution planner agent content
for path in \
  "$TEST_REPO/.local/staging/claude/agents/evolution-planner.md" \
  "$TEST_REPO/.local/staging/codex/shared-agents/evolution-planner.md"
do
  assert_file_contains "$path" "opt-in evolution-front experiment"
  assert_file_contains "$path" "constraint packet"
done

# 21. Evolution-front skill content
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

# 22. Evidence chain template fields
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

# 23. Constraint packet template fields
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

echo "PASS: sync content validation"
