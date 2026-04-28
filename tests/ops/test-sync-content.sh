#!/usr/bin/env bash
set -euo pipefail

TESTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$TESTS_DIR/lib/test-helpers.sh"
test_setup_repo
printf '[]\n' > "$TEST_REPO/ops/external-skills.json"

# Sync both platforms to staging for content validation
run_sync --platform claude --target staging >/dev/null
run_sync --platform codex --profile codex-only --target staging >/dev/null

claude_state="$TEST_REPO/.local/install-state/staging/claude.json"
codex_state="$TEST_REPO/.local/install-state/staging/codex.json"

# === Claude staging content ===

# 1. Install state records the staged Claude surface.
assert_json_expr "$claude_state" '.status == "installed"'
assert_json_expr "$claude_state" '.profile == "claude-only"'
assert_state_has_target "$claude_state" "shared-root" "CLAUDE.md"
assert_state_has_target "$claude_state" "claude-platform" "CLAUDE.md"
assert_state_has_target "$claude_state" "shared-agents" "agents"
assert_state_has_target "$claude_state" "shared-skills" "skills"
assert_state_has_target "$claude_state" "shared-commands" "commands"
assert_state_has_target "$claude_state" "shared-rules" "rules"

# 3. Stable skill metadata is preserved.
assert_frontmatter_field "$TEST_REPO/.local/staging/claude/skills/nexus/SKILL.md" "name" "nexus"

# 4. Source-only files do not leak into deployed roots.
assert_file_missing "$TEST_REPO/.local/staging/claude/CLAUDE.base.md"
assert_file_missing "$TEST_REPO/.local/staging/claude/AGENTS.md"

# 5. Deployed command content does not leak source-tree paths.
for path in "$TEST_REPO/.local/staging/claude/commands"/*.md; do
  assert_file_not_contains "$path" "runtime/"
done

# === Codex staging content ===

# 6. Install state records the staged Codex surface.
assert_json_expr "$codex_state" '.status == "installed"'
assert_json_expr "$codex_state" '.profile == "codex-only"'
assert_state_has_target "$codex_state" "shared-root" "AGENTS.md"
assert_state_has_target "$codex_state" "codex-platform" "AGENTS.md"
assert_state_has_target "$codex_state" "codex-platform" "config.toml"
assert_state_has_target "$codex_state" "shared-agents" "shared-agents"
assert_state_has_target "$codex_state" "shared-skills" "skills"
assert_state_has_target "$codex_state" "shared-commands" "commands"
assert_state_has_target "$codex_state" "shared-commands" "prompts"
assert_state_has_target "$codex_state" "shared-rules" "rules"

# 8. Stable skill metadata is preserved.
assert_frontmatter_field "$TEST_REPO/.local/staging/codex/skills/nexus/SKILL.md" "name" "nexus"

# 9. Source-only files do not leak into deployed roots.
assert_file_missing "$TEST_REPO/.local/staging/codex/AGENTS.supplement.md"
assert_file_missing "$TEST_REPO/.local/staging/codex/config.base.toml"

# 10. Deployed command and prompt content does not leak source-tree paths.
for path in \
  "$TEST_REPO/.local/staging/codex/commands"/*.md \
  "$TEST_REPO/.local/staging/codex/prompts"/*.md
do
  assert_file_not_contains "$path" "runtime/"
done

# === Evolution-front experiment content ===

# Validate the experiment only when its runtime files are present in the source
# repo. This keeps the sync-content test aligned with the current runtime
# surface rather than requiring optional experiment files unconditionally.
if [[ -e "$TEST_REPO/runtime/commands/evolution-plan.md" ]]; then
  assert_state_has_target "$claude_state" "shared-commands" "commands"
  assert_state_has_target "$claude_state" "shared-agents" "agents"
  assert_state_has_target "$claude_state" "shared-skills" "skills"
  assert_state_has_target "$codex_state" "shared-commands" "commands"
  assert_state_has_target "$codex_state" "shared-commands" "prompts"
  assert_state_has_target "$codex_state" "shared-agents" "shared-agents"
  assert_state_has_target "$codex_state" "shared-skills" "skills"

  for path in \
    "$TEST_REPO/.local/staging/claude/commands/evolution-plan.md" \
    "$TEST_REPO/.local/staging/codex/commands/evolution-plan.md" \
    "$TEST_REPO/.local/staging/codex/prompts/evolution-plan.md"
  do
    assert_frontmatter_field "$path" "name" "evolution-plan"
    assert_file_not_contains "$path" "agents/evolution-planner.md"
  done

  assert_file_exists "$TEST_REPO/.local/staging/claude/skills/evolution-front-experiment/templates/evidence-chain.md"
  assert_file_exists "$TEST_REPO/.local/staging/claude/skills/evolution-front-experiment/templates/constraint-packet.md"
  assert_file_exists "$TEST_REPO/.local/staging/codex/skills/evolution-front-experiment/templates/evidence-chain.md"
  assert_file_exists "$TEST_REPO/.local/staging/codex/skills/evolution-front-experiment/templates/constraint-packet.md"
else
  assert_file_missing "$TEST_REPO/.local/staging/claude/commands/evolution-plan.md"
  assert_file_missing "$TEST_REPO/.local/staging/claude/agents/evolution-planner.md"
  assert_file_missing "$TEST_REPO/.local/staging/claude/skills/evolution-front-experiment"
  assert_file_missing "$TEST_REPO/.local/staging/codex/commands/evolution-plan.md"
  assert_file_missing "$TEST_REPO/.local/staging/codex/prompts/evolution-plan.md"
  assert_file_missing "$TEST_REPO/.local/staging/codex/shared-agents/evolution-planner.md"
  assert_file_missing "$TEST_REPO/.local/staging/codex/skills/evolution-front-experiment"
fi

echo "PASS: sync content validation"
