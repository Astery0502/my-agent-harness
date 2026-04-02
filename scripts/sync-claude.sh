#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage: ./scripts/sync-claude.sh [--help]

Stub script for syncing harness content into ~/.claude.

Planned responsibilities:
- read install/profiles.json and install/modules.json
- read platforms/claude/install-map.json
- copy or render declared files into ~/.claude
- update state/claude-install-state.json

Current behavior:
- print this help text
- exit without modifying runtime files
EOF
}

case "${1:-}" in
  --help|-h|"")
    usage
    ;;
  *)
    echo "sync-claude.sh: unsupported argument: $1" >&2
    exit 1
    ;;
esac
