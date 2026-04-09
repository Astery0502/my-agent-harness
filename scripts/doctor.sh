#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# shellcheck source=./lib/ops-common.sh
source "$SCRIPT_DIR/lib/ops-common.sh"

usage() {
  cat <<'EOF'
Usage: ./scripts/doctor.sh [--help]

Diagnose local staged harness installs and recorded state.

Current behavior:
- validate install metadata consistency
- compare .local staged files against recorded component digests
- report healthy, not-installed, drifted, or malformed state
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
    echo "doctor.sh: unsupported argument: $1" >&2
    exit 1
    ;;
esac

exit_code=0

for platform in $(ops_platforms); do
  state_file="$(ops_state_file_for "$REPO_ROOT" "$platform")"
  status="$(ops_state_get_raw "$state_file" '.status')"
  profile="$(ops_state_get_raw "$state_file" '.profile')"
  target_root="$(ops_state_get_raw "$state_file" '.targetRoot')"
  recorded_digests="$(jq -c '.componentDigests' "$state_file")"

  case "$status" in
    not-installed)
      printf '%s\n' "$platform: not-installed"
      ;;
    installed)
      if ! resolved_target_root="$(ops_validate_installed_target_root "$REPO_ROOT" "$target_root" 2>/tmp/ops-doctor.err)"; then
        printf '%s\n' "$platform: malformed - $(cat /tmp/ops-doctor.err)"
        exit_code=1
        continue
      fi

      actual_digests="$(ops_compute_component_digests "$REPO_ROOT" "$platform" "$profile" "$resolved_target_root")"
      if [[ "$actual_digests" == "$recorded_digests" ]]; then
        printf '%s\n' "$platform: healthy"
      else
        printf '%s\n' "$platform: drifted"
        exit_code=1
      fi
      ;;
    *)
      printf '%s\n' "$platform: malformed - unknown status $status"
      exit_code=1
      ;;
  esac
done

exit "$exit_code"
