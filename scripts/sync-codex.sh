#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# shellcheck source=./lib/sync-common.sh
source "$SCRIPT_DIR/lib/sync-common.sh"

usage() {
  cat <<'EOF'
Usage: ./scripts/sync-codex.sh [--help] [--profile <id>]

Stage harness content for Codex into a local staging directory.

Current behavior:
- read install/profiles.json and install/modules.json
- read platforms/codex/install-map.json
- stage mapped files into state/staging/codex/
- update state/codex-install-state.json
- never write into ~/.codex in this milestone
EOF
}

PROFILE="minimal"

while (($# > 0)); do
  case "$1" in
    --help|-h)
      usage
      exit 0
      ;;
    --profile)
      shift
      [[ $# -gt 0 ]] || sync_fail "--profile requires a value"
      PROFILE="$1"
      ;;
    *)
      echo "sync-codex.sh: unsupported argument: $1" >&2
      exit 1
      ;;
  esac
  shift
done

if [[ "${SHOW_HELP:-0}" == "1" ]]; then
    usage
    exit 0
fi

sync_run \
  "$REPO_ROOT" \
  "codex" \
  "$PROFILE" \
  "platforms/codex/install-map.json" \
  "state/codex-install-state.json" \
  "state/staging/codex"
