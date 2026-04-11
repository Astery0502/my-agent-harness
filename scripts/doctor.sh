#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# shellcheck source=./lib/ops-common.sh
source "$SCRIPT_DIR/lib/ops-common.sh"

usage() {
  cat <<'EOF'
Usage: ./scripts/doctor.sh [--help] [--target <live|staging>]

Diagnose harness installs for the selected target.

Reads stored state (componentDigests + componentTargets) and re-hashes
the deployed paths to detect drift. No manifest or install-map resolution needed.
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
      echo "doctor.sh: unsupported argument: $1" >&2
      exit 1
      ;;
  esac
  shift
done

exit_code=0
err_file="$(mktemp)"
trap 'rm -f "$err_file"' EXIT

while IFS= read -r platform; do
  state_file="$(ops_state_file_for "$REPO_ROOT" "$platform" "$TARGET")"
  IFS=$'\t' read -r status target_root < <(jq -r '[.status, .targetRoot] | @tsv' "$state_file")

  case "$status" in
    not-installed)
      printf '%s\n' "$platform: not-installed"
      ;;
    installed)
      if ! ops_validate_installed_target_root "$REPO_ROOT" "$target_root" "$platform" "$TARGET" >/dev/null 2>"$err_file"; then
        printf '%s\n' "$platform: malformed - $(cat "$err_file")"
        exit_code=1
        continue
      fi

      stored_digests="$(jq -c '.componentDigests' "$state_file")"
      component_targets="$(jq -c '.componentTargets' "$state_file")"
      actual_digests="$(sync_compute_actual_digests "$target_root" "$component_targets")"

      if [[ "$actual_digests" == "$stored_digests" ]]; then
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
done < <(layout_discover_platforms "$REPO_ROOT")

exit "$exit_code"
