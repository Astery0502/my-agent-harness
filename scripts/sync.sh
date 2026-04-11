#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# shellcheck source=./lib/sync-common.sh
source "$SCRIPT_DIR/lib/sync-common.sh"

usage() {
  cat <<'EOF'
Usage: ./scripts/sync.sh --platform <name> [--profile <id>] [--target <live|staging>] [--dry-run]

Install harness content for the specified platform.

Options:
  --platform  Platform name (required). Discovered from runtime/platforms/<name>/install-map.json.
  --profile   Profile ID from ops/manifest.json. Defaults to install-map's defaultProfile.
  --target    Install target: live (default) or staging.
  --dry-run   Show what would be installed without making changes.
EOF
}

PLATFORM=""
PROFILE=""
TARGET="live"
DRY_RUN=0

while (($# > 0)); do
  case "$1" in
    --help|-h)
      usage
      exit 0
      ;;
    --platform)
      shift
      [[ $# -gt 0 ]] || sync_fail "--platform requires a value"
      PLATFORM="$1"
      ;;
    --profile)
      shift
      [[ $# -gt 0 ]] || sync_fail "--profile requires a value"
      PROFILE="$1"
      ;;
    --target)
      shift
      [[ $# -gt 0 ]] || sync_fail "--target requires a value"
      TARGET="$1"
      sync_validate_target "$TARGET" || sync_fail "unsupported target: $TARGET"
      ;;
    --dry-run)
      DRY_RUN=1
      ;;
    *)
      echo "sync.sh: unsupported argument: $1" >&2
      exit 1
      ;;
  esac
  shift
done

[[ -n "$PLATFORM" ]] || sync_fail "--platform is required"

# default profile from install-map if not specified
if [[ -z "$PROFILE" ]]; then
  install_map="$(layout_install_map_for "$REPO_ROOT" "$PLATFORM")"
  [[ -f "$install_map" ]] || sync_fail "install map not found for platform: $PLATFORM"
  PROFILE="$(jq -r '.defaultProfile // empty' "$install_map")"
  [[ -n "$PROFILE" ]] || sync_fail "no --profile specified and install-map has no defaultProfile"
fi

sync_run \
  "$REPO_ROOT" \
  "$PLATFORM" \
  "$PROFILE" \
  "$TARGET" \
  "$DRY_RUN"
