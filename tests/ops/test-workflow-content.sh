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

# === Step D objective distance discipline ===

# lifecycle.md encodes the role-switch discipline at step D
assert_file_contains "$SKILLS/references/lifecycle.md" "Role discipline"

# planner.md carries the D discipline as a behavioral rule
assert_file_contains "$AGENTS/planner.md" "switch roles explicitly"

# === Intra-chain reopen paths ===

# lifecycle.md defines upstream reopen conditions for mid-chain steps
assert_file_contains "$SKILLS/references/lifecycle.md" "Upstream reopen condition"

# artifacts.md defines the reopen_target field
assert_file_contains "$SKILLS/references/artifacts.md" "reopen_target"

# === Step F validation code ===

assert_file_contains "$SKILLS/references/lifecycle.md" "validation code"

# === Clarity-based routing ===

# plan.md routes by request clarity to tdd-workflow or planning-protocol
assert_file_contains "$COMMANDS/plan.md" "tdd-workflow"
assert_file_contains "$COMMANDS/plan.md" "planning-protocol"

# planner.md references tdd-workflow as the fast path
assert_file_contains "$AGENTS/planner.md" "tdd-workflow"

# === Closed-loop feedback ===

# artifacts.md documents implementation failures as valid reopen triggers
assert_file_contains "$SKILLS/references/artifacts.md" "Implementation failures"

echo "PASS: workflow contract validation"
