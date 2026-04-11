#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# shellcheck source=./lib/ops-common.sh
source "$SCRIPT_DIR/lib/ops-common.sh"

usage() {
  cat <<'EOF'
Usage: ./scripts/repair.sh [--help] [--target <live|staging>]

Repair harness installs by rerunning sync with recorded profiles.
EOF
}

TARGET="live"

while (($# > 0)); do
  case "$1" in
    --help|-h)
      usage
      exit 0
      ;;
    --target)
      shift
      [[ $# -gt 0 ]] || ops_fail "--target requires a value"
      TARGET="$1"
      sync_validate_target "$TARGET" || ops_fail "unsupported target: $TARGET"
      ;;
    *)
      echo "repair.sh: unsupported argument: $1" >&2
      exit 1
      ;;
  esac
  shift
done

while IFS= read -r platform; do
  state_file="$(ops_state_file_for "$REPO_ROOT" "$platform" "$TARGET")"
  status="$(ops_state_get_raw "$state_file" '.status')"
  profile="$(ops_state_get_raw "$state_file" '.profile')"
  target_root="$(ops_state_get_raw "$state_file" '.targetRoot')"

  case "$status" in
    not-installed)
      printf '%s\n' "$platform: nothing to repair"
      ;;
    installed)
      ops_validate_installed_target_root "$REPO_ROOT" "$target_root" "$platform" "$TARGET" >/dev/null
      "$SCRIPT_DIR/sync.sh" --platform "$platform" --profile "$profile" --target "$TARGET" >/dev/null
      printf '%s\n' "$platform: repaired"
      ;;
    *)
      ops_fail "cannot repair malformed state for $platform"
      ;;
  esac
done < <(layout_discover_platforms "$REPO_ROOT")
