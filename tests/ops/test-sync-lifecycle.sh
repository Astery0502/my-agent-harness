#!/usr/bin/env bash
set -euo pipefail

TESTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$TESTS_DIR/lib/test-helpers.sh"
test_setup_repo

# --- Fresh state ---

# 1. list-installed reports not-installed
list_output="$(run_list)"
assert_contains "$list_output" "claude"
assert_contains "$list_output" "codex"
assert_contains "$list_output" "target: live"
assert_contains "$list_output" "not-installed"

# --- Live sync ---

# 2. Sync claude (live, default profile)
claude_output="$(run_sync --platform claude)"
assert_contains "$claude_output" "sync: installed"
assert_contains "$claude_output" "platform: claude"
assert_contains "$claude_output" "target: live"
assert_contains "$claude_output" "profile: claude-only"
assert_contains "$claude_output" "backups: none"
assert_contains "$claude_output" "note: unmanaged files under the runtime root were preserved"

# 3. Sync codex (live, explicit profile) with pre-existing file for backup
printf 'old agents\n' > "$TEST_HOME/.codex/AGENTS.md"
printf 'keep me\n' > "$TEST_HOME/.codex/unmanaged.txt"

codex_output="$(run_sync --platform codex --profile codex-only)"
assert_contains "$codex_output" "sync: installed"
assert_contains "$codex_output" "target: live"
assert_contains "$codex_output" "backups: created"
assert_contains "$codex_output" "backup root:"

# verify backup was created
backup_root="$(printf '%s\n' "$codex_output" | awk -F': ' '/^backup root:/ {print $2}')"
[[ -n "$backup_root" ]] || fail "expected backup root in codex sync report"
assert_file_exists "$backup_root/AGENTS.md"
assert_file_contains "$backup_root/AGENTS.md" "old agents"

# verify unmanaged files preserved
assert_file_contains "$TEST_HOME/.codex/unmanaged.txt" "keep me"

# --- Doctor ---

# 4. Doctor reports healthy
doctor_output="$(run_doctor)"
assert_contains "$doctor_output" "claude: healthy"
assert_contains "$doctor_output" "codex: healthy"

# --- Drift detection ---

# 5. Modify deployed file, doctor detects drift
printf '\n# drift\n' >> "$TEST_HOME/.claude/CLAUDE.md"

if run_doctor >/tmp/doctor-drift.out 2>&1; then
  fail "doctor should fail after drift"
fi
assert_contains "$(cat /tmp/doctor-drift.out)" "drifted"

# --- Repair ---

# 6. Repair restores health
repair_output="$(run_repair)"
assert_contains "$repair_output" "claude: repaired"
assert_contains "$repair_output" "codex: repaired"

doctor_output="$(run_doctor)"
assert_contains "$doctor_output" "claude: healthy"
assert_contains "$doctor_output" "codex: healthy"

# --- State files ---

# 7. Verify state file structure
assert_json_expr "$TEST_REPO/.local/install-state/live/claude.json" '.status == "installed"'
assert_json_expr "$TEST_REPO/.local/install-state/live/claude.json" '.profile == "claude-only"'
assert_json_expr "$TEST_REPO/.local/install-state/live/claude.json" '.components | length > 0'
assert_json_expr "$TEST_REPO/.local/install-state/live/claude.json" '.componentDigests | keys | length > 0'
assert_json_expr "$TEST_REPO/.local/install-state/live/claude.json" '.componentTargets | keys | length > 0'
assert_json_expr "$TEST_REPO/.local/install-state/live/claude.json" ".targetRoot == \"$(realpath "$TEST_HOME/.claude")\""

assert_json_expr "$TEST_REPO/.local/install-state/live/codex.json" '.status == "installed"'
assert_json_expr "$TEST_REPO/.local/install-state/live/codex.json" '.profile == "codex-only"'
assert_json_expr "$TEST_REPO/.local/install-state/live/codex.json" ".targetRoot == \"$(realpath "$TEST_HOME/.codex")\""

# --- Staging lifecycle ---

# 8. Staging sync
run_sync --platform claude --target staging >/dev/null
run_sync --platform codex --profile codex-only --target staging >/dev/null

doctor_output="$(run_doctor --target staging)"
assert_contains "$doctor_output" "claude: healthy"
assert_contains "$doctor_output" "codex: healthy"

# 9. Staging drift and repair
printf '\n# staging drift\n' >> "$TEST_REPO/.local/staging/claude/CLAUDE.md"

if run_doctor --target staging >/tmp/staging-doctor.out 2>&1; then
  fail "doctor should fail after staging drift"
fi
assert_contains "$(cat /tmp/staging-doctor.out)" "drifted"

repair_output="$(run_repair --target staging)"
assert_contains "$repair_output" "claude: repaired"
assert_contains "$repair_output" "codex: repaired"

doctor_output="$(run_doctor --target staging)"
assert_contains "$doctor_output" "healthy"

# 10. Staging re-sync removes stale files (atomic replace)
touch "$TEST_REPO/.local/staging/claude/SHOULD_BE_REMOVED"
run_sync --platform claude --target staging >/dev/null
assert_file_missing "$TEST_REPO/.local/staging/claude/SHOULD_BE_REMOVED"

# 11. Live preserves unmanaged files
touch "$TEST_HOME/.claude/my-custom-file.txt"
run_sync --platform claude >/dev/null
assert_file_exists "$TEST_HOME/.claude/my-custom-file.txt"

# 12. Live re-sync prunes stale previously-managed targets after mapping changes
mkdir -p "$TEST_HOME/.codex/legacy-prompts"
printf 'stale command\n' > "$TEST_HOME/.codex/legacy-prompts/evolution-plan.md"
jq '.componentTargets["shared-commands"] = ["legacy-prompts"]' \
  "$TEST_REPO/.local/install-state/live/codex.json" > "$TEST_REPO/.local/install-state/live/codex.json.tmp"
mv "$TEST_REPO/.local/install-state/live/codex.json.tmp" "$TEST_REPO/.local/install-state/live/codex.json"
run_sync --platform codex --profile codex-only >/dev/null
assert_file_missing "$TEST_HOME/.codex/legacy-prompts/evolution-plan.md"
assert_file_missing "$TEST_HOME/.codex/legacy-prompts"
assert_file_exists "$TEST_HOME/.codex/prompts/plan.md"
assert_file_exists "$TEST_HOME/.codex/commands/plan.md"

# 13. Default profile (no --profile flag)
default_output="$(run_sync --platform claude --target staging)"
assert_contains "$default_output" "profile: claude-only"

# 14. Double sync skips deploy when nothing changed
second_output="$(run_sync --platform claude)"
assert_contains "$second_output" "sync: up-to-date"
assert_contains "$second_output" "nothing to deploy"
assert_not_contains "$second_output" "backups:"

# 15. After source change, sync deploys again
printf '\n# new content\n' >> "$TEST_REPO/runtime/HARNESS.md"
changed_output="$(run_sync --platform claude)"
assert_contains "$changed_output" "sync: installed"

# 16. Backup pruning keeps only 3 most recent
# We already have backups from steps 3 (codex) and current claude syncs.
# Force 5 claude backups by making changes and syncing.
for i in 1 2 3 4 5; do
  printf '\n# change %s\n' "$i" >> "$TEST_REPO/runtime/HARNESS.md"
  run_sync --platform claude >/dev/null
done

claude_backup_count="$(ls -1 "$TEST_REPO/.local/backups/claude" | wc -l | tr -d '[:space:]')"
[[ "$claude_backup_count" -le 3 ]] || fail "expected at most 3 claude backups, got $claude_backup_count"
[[ "$claude_backup_count" -eq 3 ]] || fail "expected exactly 3 claude backups, got $claude_backup_count"

echo "PASS: sync lifecycle"
