#!/usr/bin/env bash
set -euo pipefail

TESTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$TESTS_DIR/lib/test-helpers.sh"
test_setup_repo

# 1. Unknown platform (no install-map.json)
if run_sync --platform bogus 2>/tmp/sync-err.out; then
  fail "sync should fail for unknown platform"
fi
assert_contains "$(cat /tmp/sync-err.out)" "install map not found"

# 2. Unknown profile
if run_sync --platform claude --profile nonexistent 2>/tmp/sync-err.out; then
  fail "sync should fail for unknown profile"
fi
assert_contains "$(cat /tmp/sync-err.out)" "unknown profile"

# 3. Profile references unknown component -- inject a bad profile into manifest
tmp_manifest="$(mktemp)"
jq '.profiles.bad = ["no-such-component"]' "$TEST_REPO/ops/manifest.json" > "$tmp_manifest"
mv "$tmp_manifest" "$TEST_REPO/ops/manifest.json"

if run_sync --platform claude --profile bad 2>/tmp/sync-err.out; then
  fail "sync should fail when profile references unknown component"
fi
assert_contains "$(cat /tmp/sync-err.out)" "profile references unknown component"

# restore manifest
(
  cd "$TEST_ROOT_DIR"
  tar --exclude='./.git' --exclude='./.worktrees' --exclude='./.local' -cf - ops/manifest.json
) | (
  cd "$TEST_REPO"
  tar -xf -
)

# 4. Source path with .. traversal -- inject bad mapping
tmp_map="$(mktemp)"
jq '.mappings += [{"component": "shared-root", "source": "runtime/../../../etc/passwd", "target": "evil"}]' \
  "$TEST_REPO/runtime/platforms/claude/install-map.json" > "$tmp_map"
mv "$tmp_map" "$TEST_REPO/runtime/platforms/claude/install-map.json"

if run_sync --platform claude 2>/tmp/sync-err.out; then
  fail "sync should fail on .. traversal"
fi
assert_contains "$(cat /tmp/sync-err.out)" "parent directory traversal"

# restore install-map
(
  cd "$TEST_ROOT_DIR"
  tar --exclude='./.git' --exclude='./.worktrees' --exclude='./.local' -cf - runtime/platforms/claude/install-map.json
) | (
  cd "$TEST_REPO"
  tar -xf -
)

# 5. Absolute target path
tmp_map="$(mktemp)"
jq '.mappings += [{"component": "shared-root", "source": "runtime/HARNESS.md", "target": "/tmp/evil"}]' \
  "$TEST_REPO/runtime/platforms/claude/install-map.json" > "$tmp_map"
mv "$tmp_map" "$TEST_REPO/runtime/platforms/claude/install-map.json"

if run_sync --platform claude 2>/tmp/sync-err.out; then
  fail "sync should fail on absolute target path"
fi
assert_contains "$(cat /tmp/sync-err.out)" "absolute paths are not allowed"

# restore
(
  cd "$TEST_ROOT_DIR"
  tar --exclude='./.git' --exclude='./.worktrees' --exclude='./.local' -cf - runtime/platforms/claude/install-map.json
) | (
  cd "$TEST_REPO"
  tar -xf -
)

# 6. Duplicate target paths
tmp_map="$(mktemp)"
jq '.mappings += [{"component": "shared-root", "source": "runtime/HARNESS.md", "target": "agents"}]' \
  "$TEST_REPO/runtime/platforms/claude/install-map.json" > "$tmp_map"
mv "$tmp_map" "$TEST_REPO/runtime/platforms/claude/install-map.json"

if run_sync --platform claude 2>/tmp/sync-err.out; then
  fail "sync should fail on duplicate target paths"
fi
assert_contains "$(cat /tmp/sync-err.out)" "multiple mappings resolve to the same target"

# restore
(
  cd "$TEST_ROOT_DIR"
  tar --exclude='./.git' --exclude='./.worktrees' --exclude='./.local' -cf - runtime/platforms/claude/install-map.json
) | (
  cd "$TEST_REPO"
  tar -xf -
)

# 7. Component with no install-map target -- remove skills mapping
tmp_map="$(mktemp)"
jq 'del(.mappings[] | select(.target == "skills"))' \
  "$TEST_REPO/runtime/platforms/claude/install-map.json" > "$tmp_map"
mv "$tmp_map" "$TEST_REPO/runtime/platforms/claude/install-map.json"

if run_sync --platform claude 2>/tmp/sync-err.out; then
  fail "sync should fail when component has no install-map target"
fi
assert_contains "$(cat /tmp/sync-err.out)" "selected component has no install-map target for platform: shared-skills"

# 8. Sync should not print success report on failure
if [[ "$(cat /tmp/sync-err.out)" == *"sync: installed"* ]]; then
  fail "sync should not print success report on failure"
fi

echo "PASS: sync error handling"
