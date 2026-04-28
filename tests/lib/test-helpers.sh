#!/usr/bin/env bash
# Shared test helpers for harness ops tests.
# Source this file from test scripts. Call test_setup_repo before running tests.

export LC_ALL=C
export LANG=C

TEST_HELPERS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEST_ROOT_DIR="$(cd "$TEST_HELPERS_DIR/../.." && pwd)"

TMP_DIR=""
TEST_REPO=""
TEST_HOME=""

fail() {
  echo "FAIL: $*" >&2
  exit 1
}

test_cleanup() {
  [[ -n "$TMP_DIR" && -d "$TMP_DIR" ]] && rm -rf "$TMP_DIR"
}

test_setup_repo() {
  TMP_DIR="$(mktemp -d)"
  TEST_REPO="$TMP_DIR/repo"
  TEST_HOME="$TMP_DIR/home"
  trap test_cleanup EXIT

  mkdir -p "$TEST_REPO" "$TEST_HOME/.claude" "$TEST_HOME/.codex"

  (
    cd "$TEST_ROOT_DIR"
    tar --exclude='./.git' --exclude='./.worktrees' --exclude='./.local' -cf - .
  ) | (
    cd "$TEST_REPO"
    tar -xf -
  )

  cd "$TEST_REPO"
}

# Minimal fixture: same as test_setup_repo but excludes large skill directories
# and docs/tests that are not needed for behavioral (non-content) tests.
# Reduces per-sync digest cost from ~60+ subprocesses to a handful.
test_setup_minimal_repo() {
  TMP_DIR="$(mktemp -d)"
  TEST_REPO="$TMP_DIR/repo"
  TEST_HOME="$TMP_DIR/home"
  trap test_cleanup EXIT

  mkdir -p "$TEST_REPO" "$TEST_HOME/.claude" "$TEST_HOME/.codex"

  (
    cd "$TEST_ROOT_DIR"
    tar --exclude='./.git' --exclude='./.worktrees' --exclude='./.local' \
        --exclude='./runtime/skills/nexus' \
        --exclude='./runtime/skills/agile-par' \
        --exclude='./tests' \
        --exclude='./docs' \
        --exclude='./.plans' \
        -cf - .
  ) | (
    cd "$TEST_REPO"
    tar -xf -
  )

  cd "$TEST_REPO"
}

# Synthetic fixture for behavioral tests (lifecycle, dry-run, errors).
# Builds a minimal fake repo from scratch: only scripts/ is copied from the
# real repo; manifest, install-maps, and source files are written inline.
# Each sync hashes 2-3 small files instead of the full runtime tree.
# Use test_setup_repo / test_setup_minimal_repo only when real content matters.
test_setup_fixture() {
  TMP_DIR="$(mktemp -d)"
  TEST_REPO="$TMP_DIR/repo"
  TEST_HOME="$TMP_DIR/home"
  trap test_cleanup EXIT

  mkdir -p "$TEST_REPO/ops" \
           "$TEST_REPO/runtime/src" \
           "$TEST_REPO/runtime/platforms/claude" \
           "$TEST_REPO/runtime/platforms/codex" \
           "$TEST_HOME/.claude" \
           "$TEST_HOME/.codex"

  cp -R "$TEST_ROOT_DIR/scripts" "$TEST_REPO/scripts"

  # Tiny source files — content is irrelevant to behavioral tests
  printf '# shared\n' > "$TEST_REPO/runtime/src/file.md"
  printf '# claude\n' > "$TEST_REPO/runtime/platforms/claude/platform.md"
  printf '# codex\n'  > "$TEST_REPO/runtime/platforms/codex/platform.md"
  printf '[]\n'        > "$TEST_REPO/ops/external-skills.json"

  cat > "$TEST_REPO/ops/manifest.json" <<'EOF'
{
  "components": {
    "shared-root":     { "paths": ["runtime/src"] },
    "claude-platform": { "paths": ["runtime/platforms/claude"] },
    "codex-platform":  { "paths": ["runtime/platforms/codex"] }
  },
  "profiles": {
    "claude-only": ["shared-root", "claude-platform"],
    "codex-only":  ["shared-root", "codex-platform"]
  }
}
EOF

  cat > "$TEST_REPO/runtime/platforms/claude/install-map.json" <<'EOF'
{
  "platform": "claude",
  "defaultProfile": "claude-only",
  "targetRoot": "~/.claude",
  "mappings": [
    { "component": "shared-root",     "source": "runtime/src/file.md",                  "target": "shared.md" },
    { "component": "claude-platform", "source": "runtime/platforms/claude/platform.md", "target": "platform.md" }
  ]
}
EOF

  cat > "$TEST_REPO/runtime/platforms/codex/install-map.json" <<'EOF'
{
  "platform": "codex",
  "defaultProfile": "codex-only",
  "targetRoot": "~/.codex",
  "mappings": [
    { "component": "shared-root",    "source": "runtime/src/file.md",                 "target": "AGENTS.md" },
    { "component": "codex-platform", "source": "runtime/platforms/codex/platform.md", "target": "platform.md" }
  ]
}
EOF

  # Backup copies so error-injection tests can restore originals without tar
  cp "$TEST_REPO/ops/manifest.json" \
     "$TEST_REPO/ops/manifest.json.bak"
  cp "$TEST_REPO/runtime/platforms/claude/install-map.json" \
     "$TEST_REPO/runtime/platforms/claude/install-map.json.bak"

  cd "$TEST_REPO"
}

# --- Assert helpers ---

assert_contains() {
  local haystack="$1"
  local needle="$2"
  [[ "$haystack" == *"$needle"* ]] || fail "expected output to contain: $needle\ngot: $haystack"
}

assert_not_contains() {
  local haystack="$1"
  local needle="$2"
  [[ "$haystack" != *"$needle"* ]] || fail "expected output to NOT contain: $needle"
}

assert_file_exists() {
  local path="$1"
  [[ -f "$path" ]] || fail "expected file to exist: $path"
}

assert_dir_exists() {
  local path="$1"
  [[ -d "$path" ]] || fail "expected directory to exist: $path"
}

assert_file_missing() {
  local path="$1"
  [[ ! -e "$path" ]] || fail "expected path to be absent: $path"
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
    fail "expected $path to NOT contain: $needle"
  fi
}

assert_json_expr() {
  local file="$1"
  local expr="$2"
  jq -e "$expr" "$file" >/dev/null || fail "json assertion failed: $file :: $expr"
}

run_and_capture_failure() {
  local output_var="$1"
  shift

  local output status
  set +e
  output="$("$@" 2>&1)"
  status=$?
  set -e

  [[ "$status" -ne 0 ]] || fail "expected command to fail: $*"
  printf -v "$output_var" '%s' "$output"
}

assert_report_field() {
  local output="$1"
  local field="$2"
  local expected="$3"
  local line actual

  while IFS= read -r line; do
    if [[ "$line" == "$field: "* ]]; then
      actual="${line#"$field: "}"
      [[ "$actual" == "$expected" ]] || fail "expected report field $field to be: $expected; got: $actual"
      return
    fi
  done <<< "$output"

  fail "expected report field: $field"
}

assert_state_has_target() {
  local file="$1"
  local component="$2"
  local target="$3"
  jq -e --arg component "$component" --arg target "$target" \
    '.componentTargets[$component] | index($target)' "$file" >/dev/null \
    || fail "expected state component target: $component -> $target"
}

assert_frontmatter_field() {
  local file="$1"
  local field="$2"
  local expected="$3"
  local line actual in_frontmatter=false

  [[ -f "$file" ]] || fail "expected file to exist before checking frontmatter: $file"

  while IFS= read -r line; do
    if [[ "$line" == "---" ]]; then
      if [[ "$in_frontmatter" == false ]]; then
        in_frontmatter=true
        continue
      fi
      break
    fi

    if [[ "$in_frontmatter" == true && "$line" == "$field: "* ]]; then
      actual="${line#"$field: "}"
      [[ "$actual" == "$expected" ]] || fail "expected frontmatter field $field in $file to be: $expected; got: $actual"
      return
    fi
  done < "$file"

  fail "expected frontmatter field in $file: $field"
}

# --- Runner helpers ---

run_sync() {
  HOME="$TEST_HOME" ./scripts/sync.sh "$@"
}

run_doctor() {
  HOME="$TEST_HOME" ./scripts/doctor.sh "$@"
}

run_repair() {
  HOME="$TEST_HOME" ./scripts/repair.sh "$@"
}

run_list() {
  HOME="$TEST_HOME" ./scripts/list-installed.sh "$@"
}
