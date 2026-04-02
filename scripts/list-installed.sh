#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage: ./scripts/list-installed.sh [--help]

Stub script for listing installed harness state.

Planned responsibilities:
- read state/claude-install-state.json
- read state/codex-install-state.json
- summarize installed profiles, modules, and drift status

Current behavior:
- print this help text
- exit without inspecting runtime files
EOF
}

case "${1:-}" in
  --help|-h|"")
    usage
    ;;
  *)
    echo "list-installed.sh: unsupported argument: $1" >&2
    exit 1
    ;;
esac
