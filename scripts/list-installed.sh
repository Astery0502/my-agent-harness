#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# shellcheck source=./lib/ops-common.sh
source "$SCRIPT_DIR/lib/ops-common.sh"

usage() {
  cat <<'EOF'
Usage: ./scripts/list-installed.sh [--help]

List current local harness install state for Claude and Codex.

Current behavior:
- read state/claude-install-state.json
- read state/codex-install-state.json
- print platform, status, profile, modules, target root, and installed timestamp
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
    echo "list-installed.sh: unsupported argument: $1" >&2
    exit 1
    ;;
esac

for platform in $(ops_platforms); do
  state_file="$(ops_state_file_for "$REPO_ROOT" "$platform")"
  status="$(ops_state_get_raw "$state_file" '.status')"
  profile="$(ops_state_get_raw "$state_file" '.profile')"
  modules="$(ops_state_get_modules_text "$state_file")"
  target_root="$(ops_state_get_raw "$state_file" '.targetRoot')"
  installed_at="$(ops_state_get_raw "$state_file" '.installedAt // "(never)"')"

  printf '%s\n' "platform: $platform"
  printf '%s\n' "status: $status"
  printf '%s\n' "profile: $profile"
  printf '%s\n' "modules: $modules"
  printf '%s\n' "target root: $target_root"
  printf '%s\n' "installed at: $installed_at"
  printf '\n'
done
