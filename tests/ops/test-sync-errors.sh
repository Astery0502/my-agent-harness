#!/usr/bin/env bash
set -euo pipefail

TESTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$TESTS_DIR/lib/test-helpers.sh"
test_setup_fixture

# 1. Unknown platform (no install-map.json)
run_and_capture_failure out run_sync --platform bogus
assert_contains "$out" "install map not found"

# 2. Unknown profile
run_and_capture_failure out run_sync --platform claude --profile nonexistent
assert_contains "$out" "unknown profile"

# 3. Profile references unknown component -- inject a bad profile into manifest
tmp_manifest="$(mktemp)"
jq '.profiles.bad = ["no-such-component"]' "$TEST_REPO/ops/manifest.json" > "$tmp_manifest"
mv "$tmp_manifest" "$TEST_REPO/ops/manifest.json"

run_and_capture_failure out run_sync --platform claude --profile bad
assert_contains "$out" "profile references unknown component"

# restore manifest
cp "$TEST_REPO/ops/manifest.json.bak" "$TEST_REPO/ops/manifest.json"

# 4. Source path with .. traversal -- inject bad mapping
tmp_map="$(mktemp)"
jq '.mappings += [{"component": "shared-root", "source": "runtime/../../../etc/passwd", "target": "evil"}]' \
  "$TEST_REPO/runtime/platforms/claude/install-map.json" > "$tmp_map"
mv "$tmp_map" "$TEST_REPO/runtime/platforms/claude/install-map.json"

run_and_capture_failure out run_sync --platform claude
assert_contains "$out" "parent directory traversal"

# restore install-map
cp "$TEST_REPO/runtime/platforms/claude/install-map.json.bak" \
   "$TEST_REPO/runtime/platforms/claude/install-map.json"

# 5. Absolute target path
tmp_map="$(mktemp)"
jq '.mappings += [{"component": "shared-root", "source": "runtime/src/file.md", "target": "/tmp/evil"}]' \
  "$TEST_REPO/runtime/platforms/claude/install-map.json" > "$tmp_map"
mv "$tmp_map" "$TEST_REPO/runtime/platforms/claude/install-map.json"

run_and_capture_failure out run_sync --platform claude
assert_contains "$out" "absolute paths are not allowed"

# restore
cp "$TEST_REPO/runtime/platforms/claude/install-map.json.bak" \
   "$TEST_REPO/runtime/platforms/claude/install-map.json"

# 6. Duplicate target paths
tmp_map="$(mktemp)"
jq '.mappings += [{"component": "shared-root", "source": "runtime/src/file.md", "target": "shared.md"}]' \
  "$TEST_REPO/runtime/platforms/claude/install-map.json" > "$tmp_map"
mv "$tmp_map" "$TEST_REPO/runtime/platforms/claude/install-map.json"

run_and_capture_failure out run_sync --platform claude
assert_contains "$out" "multiple mappings resolve to the same target"

# restore
cp "$TEST_REPO/runtime/platforms/claude/install-map.json.bak" \
   "$TEST_REPO/runtime/platforms/claude/install-map.json"

# 7. Component with no install-map target -- remove claude-platform mapping
tmp_map="$(mktemp)"
jq 'del(.mappings[] | select(.target == "platform.md"))' \
  "$TEST_REPO/runtime/platforms/claude/install-map.json" > "$tmp_map"
mv "$tmp_map" "$TEST_REPO/runtime/platforms/claude/install-map.json"

run_and_capture_failure out run_sync --platform claude
assert_contains "$out" "selected component has no install-map target for platform: claude-platform"

# 8. Sync should not print success report on failure
assert_not_contains "$out" "sync: installed"

echo "PASS: sync error handling"
