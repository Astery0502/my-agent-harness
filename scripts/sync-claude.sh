#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# shellcheck source=./lib/sync-common.sh
source "$SCRIPT_DIR/lib/sync-common.sh"

usage() {
  cat <<'EOF'
Usage: ./scripts/sync-claude.sh [--help] [--profile <id>]

Stage harness content for Claude into a local staging directory.

Current behavior:
- read ops/install/profiles.json and ops/install/modules.json
- read runtime/platforms/claude/install-map.json
- stage mapped files into .local/staging/claude/
- update .local/install-state/claude.json
- never write into ~/.claude in this milestone
EOF
}

PROFILE="claude-only"

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
      echo "sync-claude.sh: unsupported argument: $1" >&2
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
  "claude" \
  "$PROFILE"
