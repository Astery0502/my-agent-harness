#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# shellcheck source=./lib/ops-common.sh
source "$SCRIPT_DIR/lib/ops-common.sh"

usage() {
  cat <<'EOF'
Usage: ./scripts/list-installed.sh [--help] [--target <live|staging>]

List current harness install state for all discovered platforms.
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
      echo "list-installed.sh: unsupported argument: $1" >&2
      exit 1
      ;;
  esac
  shift
done

while IFS= read -r platform; do
  state_file="$(ops_state_file_for "$REPO_ROOT" "$platform" "$TARGET")"
  status="$(ops_state_get_raw "$state_file" '.status')"
  profile="$(ops_state_get_raw "$state_file" 'if .profile == "" then "(none)" else .profile end')"
  components="$(ops_state_get_components_text "$state_file")"
  target_root="$(ops_state_get_raw "$state_file" 'if .targetRoot == "" then "(none)" else .targetRoot end')"
  installed_at="$(ops_state_get_raw "$state_file" '(.installedAt // "(never)") | if . == "" then "(never)" else . end')"

  printf '%s\n' "platform: $platform"
  printf '%s\n' "target: $TARGET"
  printf '%s\n' "status: $status"
  printf '%s\n' "profile: $profile"
  printf '%s\n' "components: $components"
  printf '%s\n' "target root: $target_root"
  printf '%s\n' "installed at: $installed_at"
  printf '\n'
done < <(layout_discover_platforms "$REPO_ROOT")
