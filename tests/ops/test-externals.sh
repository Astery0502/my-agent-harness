#!/usr/bin/env bash
set -euo pipefail

TESTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$TESTS_DIR/lib/test-helpers.sh"
test_setup_repo

# Start with an empty registry so tests are independent of the source file's contents.
printf '[]\n' > "$TEST_REPO/ops/external-skills.json"

# Helper: create a local bare git repo with a minimal SKILL.md as the mock remote.
setup_mock_remote() {
  local remote_dir="$1"
  local skill_content="${2:-# Mock Skill}"

  mkdir -p "$remote_dir"
  git -C "$remote_dir" init --bare --quiet

  # Populate via a temp work tree.
  local work_dir
  work_dir="$(mktemp -d)"
  git -C "$work_dir" init --quiet
  git -C "$work_dir" config user.email "test@test"
  git -C "$work_dir" config user.name "test"
  printf '%s\n' "$skill_content" > "$work_dir/SKILL.md"
  git -C "$work_dir" add SKILL.md
  git -C "$work_dir" commit --quiet -m "init"
  git -C "$work_dir" remote add origin "$remote_dir"
  git -C "$work_dir" push --quiet origin "$(git -C "$work_dir" rev-parse --abbrev-ref HEAD):main"
  rm -rf "$work_dir"
}

# Helper: add a commit to a bare remote via a temp work tree.
add_commit_to_remote() {
  local remote_dir="$1"
  local file="$2"
  local content="$3"

  local work_dir
  work_dir="$(mktemp -d)"
  git -C "$work_dir" init --quiet
  git -C "$work_dir" config user.email "test@test"
  git -C "$work_dir" config user.name "test"
  git -C "$work_dir" remote add origin "$remote_dir"
  git -C "$work_dir" fetch --quiet origin
  git -C "$work_dir" checkout --quiet -b main "origin/main"
  printf '%s\n' "$content" > "$work_dir/$file"
  git -C "$work_dir" add "$file"
  git -C "$work_dir" commit --quiet -m "update"
  git -C "$work_dir" push --quiet origin main
  rm -rf "$work_dir"
}

# --- Set up mock remote ---

MOCK_REMOTE="$TMP_DIR/mock-remote.git"
setup_mock_remote "$MOCK_REMOTE" "# External Mock Skill"

# --- 1. Empty registry — sync completes, no external output ---

out="$(run_sync --platform claude)"
assert_contains "$out" "sync: installed"
assert_not_contains "$out" "external:"

# --- 2. Add external skill to registry, fresh fetch clones it ---

printf '[{"name":"mock-skill","url":"%s","ref":"main"}]\n' "$MOCK_REMOTE" \
  > "$TEST_REPO/ops/external-skills.json"

out="$(run_sync --platform claude)"
assert_contains "$out" "external: fetched:"
assert_contains "$out" "sync: installed"

# External skill deployed to live target
assert_file_exists "$TEST_HOME/.claude/skills/mock-skill/SKILL.md"
assert_file_contains "$TEST_HOME/.claude/skills/mock-skill/SKILL.md" "External Mock Skill"

# Local skills are still present too
assert_dir_exists "$TEST_HOME/.claude/skills"

# Cache was created (keyed by URL slug, not skill name)
assert_dir_exists "$TEST_REPO/.local/external"

# --- 3. Second sync — external is up-to-date, nothing redeploys ---

out="$(run_sync --platform claude)"
assert_contains "$out" "external: up-to-date:"
assert_contains "$out" "sync: up-to-date"

# --- 4. Commit added to mock remote — sync detects update ---

add_commit_to_remote "$MOCK_REMOTE" "extra.md" "new content"

out="$(run_sync --platform claude)"
assert_contains "$out" "external: updated:"
assert_contains "$out" "sync: installed"

# Updated file visible in live target
assert_file_exists "$TEST_HOME/.claude/skills/mock-skill/extra.md"

# --- 5. State file records external skill component digest ---

state_file="$TEST_REPO/.local/install-state/live/claude.json"
assert_json_expr "$state_file" '.componentDigests | has("external/mock-skill")'
assert_json_expr "$state_file" '.componentTargets["external/mock-skill"] | contains(["skills/mock-skill"])'

# --- 6. Doctor reports healthy with external skill installed ---

doctor_out="$(run_doctor)"
assert_contains "$doctor_out" "claude: healthy"

# --- 7. Drift detected if external skill files modified ---

printf '\n# drift\n' >> "$TEST_HOME/.claude/skills/mock-skill/SKILL.md"

if run_doctor >/dev/null 2>&1; then
  fail "doctor should fail after external skill drift"
fi

out="$(run_doctor 2>&1 || true)"
assert_contains "$out" "drifted"

run_repair
doctor_out="$(run_doctor)"
assert_contains "$doctor_out" "claude: healthy"

# --- 8. Content check via staging (clean snapshot) ---

out="$(run_sync --platform claude --target staging)"
assert_contains "$out" "sync: installed"
assert_file_exists "$TEST_REPO/.local/staging/claude/skills/mock-skill/SKILL.md"

# --- 9. Bad URL — warns but sync continues ---

printf '[{"name":"bad-skill","url":"/nonexistent/path.git"},{"name":"mock-skill","url":"%s","ref":"main"}]\n' \
  "$MOCK_REMOTE" > "$TEST_REPO/ops/external-skills.json"

out="$(run_sync --platform claude --target staging 2>&1)"
assert_contains "$out" "external warning:"
assert_contains "$out" "sync: installed"
# mock-skill still present (bad-skill is absent, not fatal)
assert_file_exists "$TEST_REPO/.local/staging/claude/skills/mock-skill/SKILL.md"
assert_file_missing "$TEST_REPO/.local/staging/claude/skills/bad-skill/SKILL.md"

# --- 10. Hung clone times out and sync continues ---

FAKE_BIN="$TMP_DIR/fake-bin"
mkdir -p "$FAKE_BIN"
REAL_GIT="$(command -v git)"
cat > "$FAKE_BIN/git" <<EOF
#!/usr/bin/env bash
if [[ "\$1" == "clone" ]]; then
  sleep 2
  exit 1
fi
exec "$REAL_GIT" "\$@"
EOF
chmod +x "$FAKE_BIN/git"

printf '[{"name":"slow-skill","url":"%s","ref":"main"}]\n' "$MOCK_REMOTE" \
  > "$TEST_REPO/ops/external-skills.json"
rm -rf "$TEST_REPO/.local/external"

out="$(PATH="$FAKE_BIN:$PATH" EXTERNALS_FETCH_TIMEOUT=1 HOME="$TEST_HOME" ./scripts/sync.sh --platform claude 2>&1)"
assert_contains "$out" "external warning: timed out cloning"
assert_contains "$out" "sync: installed"
assert_file_missing "$TEST_HOME/.claude/skills/slow-skill/SKILL.md"

# --- 11. sub_path — only the named subdirectory is deployed ---

MOCK_REMOTE_SUB="$TMP_DIR/mock-remote-sub.git"
mkdir -p "$MOCK_REMOTE_SUB"
git -C "$MOCK_REMOTE_SUB" init --bare --quiet

work_dir="$(mktemp -d)"
git -C "$work_dir" init --quiet
git -C "$work_dir" config user.email "test@test"
git -C "$work_dir" config user.name "test"
mkdir -p "$work_dir/sub/skill-files"
printf '# Sub Skill\n' > "$work_dir/sub/skill-files/SKILL.md"
printf '# Root file (should not deploy)\n' > "$work_dir/root-file.md"
git -C "$work_dir" add .
git -C "$work_dir" commit --quiet -m "init"
git -C "$work_dir" remote add origin "$MOCK_REMOTE_SUB"
git -C "$work_dir" push --quiet origin "$(git -C "$work_dir" rev-parse --abbrev-ref HEAD):main"
rm -rf "$work_dir"

printf '[{"name":"sub-skill","url":"%s","ref":"main","sub_path":"sub/skill-files"}]\n' \
  "$MOCK_REMOTE_SUB" > "$TEST_REPO/ops/external-skills.json"

out="$(run_sync --platform claude)"
assert_contains "$out" "external: fetched:"
assert_contains "$out" "sync: installed"

# Only subdirectory content deployed
assert_file_exists "$TEST_HOME/.claude/skills/sub-skill/SKILL.md"
assert_file_contains "$TEST_HOME/.claude/skills/sub-skill/SKILL.md" "Sub Skill"

# Root-level file from the repo must not appear
assert_file_missing "$TEST_HOME/.claude/skills/sub-skill/root-file.md"

# --- 12. Two skills from the same repo share one clone ---

MOCK_REMOTE_MULTI="$TMP_DIR/mock-remote-multi.git"
mkdir -p "$MOCK_REMOTE_MULTI"
git -C "$MOCK_REMOTE_MULTI" init --bare --quiet

work_dir="$(mktemp -d)"
git -C "$work_dir" init --quiet
git -C "$work_dir" config user.email "test@test"
git -C "$work_dir" config user.name "test"
mkdir -p "$work_dir/skills/alpha" "$work_dir/skills/beta"
printf '# Alpha\n' > "$work_dir/skills/alpha/SKILL.md"
printf '# Beta\n' > "$work_dir/skills/beta/SKILL.md"
git -C "$work_dir" add .
git -C "$work_dir" commit --quiet -m "init"
git -C "$work_dir" remote add origin "$MOCK_REMOTE_MULTI"
git -C "$work_dir" push --quiet origin "$(git -C "$work_dir" rev-parse --abbrev-ref HEAD):main"
rm -rf "$work_dir"

printf '[
  {"name":"alpha","url":"%s","ref":"main","sub_path":"skills/alpha"},
  {"name":"beta","url":"%s","ref":"main","sub_path":"skills/beta"}
]\n' "$MOCK_REMOTE_MULTI" "$MOCK_REMOTE_MULTI" \
  > "$TEST_REPO/ops/external-skills.json"

before_clone_count="$(find "$TEST_REPO/.local/external" -mindepth 1 -maxdepth 1 -type d 2>/dev/null | wc -l | tr -d ' ')"

out="$(run_sync --platform claude)"
assert_contains "$out" "external: fetched:"
assert_contains "$out" "sync: installed"

# Both skills deployed
assert_file_exists "$TEST_HOME/.claude/skills/alpha/SKILL.md"
assert_file_contains "$TEST_HOME/.claude/skills/alpha/SKILL.md" "Alpha"
assert_file_exists "$TEST_HOME/.claude/skills/beta/SKILL.md"
assert_file_contains "$TEST_HOME/.claude/skills/beta/SKILL.md" "Beta"

# Only one new clone directory created for the shared URL (two skills, one repo)
after_clone_count="$(find "$TEST_REPO/.local/external" -mindepth 1 -maxdepth 1 -type d | wc -l | tr -d ' ')"
new_clone_count=$(( after_clone_count - before_clone_count ))
[[ "$new_clone_count" -eq 1 ]] || fail "expected 1 new clone dir for shared URL, got $new_clone_count"

echo "PASS: test-externals"
