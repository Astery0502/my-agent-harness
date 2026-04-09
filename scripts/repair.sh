#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# shellcheck source=./lib/ops-common.sh
source "$SCRIPT_DIR/lib/ops-common.sh"

usage() {
  cat <<'EOF'
Usage: ./scripts/repair.sh [--help]

Repair local staged harness installs by rerunning sync with recorded profiles.

Current behavior:
- for installed platforms, rerun the matching local staging sync
- for not-installed platforms, report that nothing needs repair
- write only inside .local/ and never outside the repository
EOF
}

case "${1:-}" in
  --help|-h)
    usage
    exit 0
    ;;
  "")
    ;;
  *)
    echo "repair.sh: unsupported argument: $1" >&2
    exit 1
    ;;
esac

for platform in $(ops_platforms); do
  state_file="$(ops_state_file_for "$REPO_ROOT" "$platform")"
  status="$(ops_state_get_raw "$state_file" '.status')"
  profile="$(ops_state_get_raw "$state_file" '.profile')"
  target_root="$(ops_state_get_raw "$state_file" '.targetRoot')"

  case "$status" in
    not-installed)
      printf '%s\n' "$platform: nothing to repair"
      ;;
    installed)
      ops_validate_installed_target_root "$REPO_ROOT" "$target_root" >/dev/null
      sync_script="$(ops_sync_script_for "$REPO_ROOT" "$platform")"
      "$sync_script" --profile "$profile" >/dev/null
      printf '%s\n' "$platform: repaired"
      ;;
    *)
      ops_fail "cannot repair malformed state for $platform"
      ;;
  esac
done
