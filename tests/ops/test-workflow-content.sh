#!/usr/bin/env bash
set -euo pipefail

TESTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$TESTS_DIR/lib/test-helpers.sh"
test_setup_repo

# Sync Claude platform to staging for workflow contract validation
run_sync --platform claude --target staging >/dev/null

SKILLS="$TEST_REPO/.local/staging/claude/skills/planning-protocol"
AGENTS="$TEST_REPO/.local/staging/claude/agents"
COMMANDS="$TEST_REPO/.local/staging/claude/commands"

# === Constraint packet as context bus ===

# lifecycle.md declares per-step constraint packet updates
assert_file_contains "$SKILLS/references/lifecycle.md" "Constraint packet update"

# artifacts.md has the ECL bus preamble
assert_file_contains "$SKILLS/references/artifacts.md" "context bus"

# unified constraint-packet template exists
assert_file_exists "$SKILLS/assets/constraint-packet.md"
assert_file_contains "$SKILLS/assets/constraint-packet.md" "reopen_target"

# === Step D objective distance discipline (critic agent) ===

# lifecycle.md encodes the critic agent isolation rule at step D
assert_file_contains "$SKILLS/references/lifecycle.md" "Role discipline"

# critic agent exists and has the isolation rule
assert_file_exists "$AGENTS/critic.md"
assert_file_contains "$AGENTS/critic.md" "Isolation Rule"

# planner.md references the critic agent for step D
assert_file_contains "$AGENTS/planner.md" "critic"

# === Intra-chain reopen paths ===

# lifecycle.md defines upstream reopen conditions for mid-chain steps
assert_file_contains "$SKILLS/references/lifecycle.md" "Upstream reopen condition"

# artifacts.md defines the reopen_target field
assert_file_contains "$SKILLS/references/artifacts.md" "reopen_target"

# === Step F validation code ===

assert_file_contains "$SKILLS/references/lifecycle.md" "concrete feasibility artifact"

# === `/plan` front-half routing ===

# plan.md requires planning-protocol rather than bypassing step A
assert_file_contains "$COMMANDS/plan.md" "Do not bypass step A"
assert_file_contains "$COMMANDS/plan.md" "planning-protocol"

# planner.md keeps step A premise-checking mandatory for `/plan`
assert_file_contains "$AGENTS/planner.md" "Do not skip step A premise-checking"

# === Closed-loop feedback ===

# artifacts.md documents implementation failures as valid reopen triggers
assert_file_contains "$SKILLS/references/artifacts.md" "Implementation failures"

# === ARI model ===

# lifecycle.md uses actionable_requirements as the C output
assert_file_contains "$SKILLS/references/lifecycle.md" "actionable_requirements"

# lifecycle.md has Red-Blue adversarial step G
assert_file_contains "$SKILLS/references/lifecycle.md" "Red-Blue"

# === Iteration delta ===

# constraint-packet.md has iteration/delta plus ECL operational fields
assert_file_contains "$SKILLS/assets/constraint-packet.md" "iteration"
assert_file_contains "$SKILLS/assets/constraint-packet.md" "delta_from_prior"
assert_file_contains "$SKILLS/assets/constraint-packet.md" "code_assembly_schema"
assert_file_contains "$SKILLS/assets/constraint-packet.md" "next_iteration_prompt"

echo "PASS: workflow contract validation"
