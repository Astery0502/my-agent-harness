#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage: ./scripts/doctor.sh [--help]

Stub script for install and drift diagnostics.

Planned responsibilities:
- validate install metadata consistency
- compare installed files against recorded component digests
- report drift, missing targets, and mapping problems

Current behavior:
- print this help text
- exit without performing diagnostics
EOF
}

case "${1:-}" in
  --help|-h|"")
    usage
    ;;
  *)
    echo "doctor.sh: unsupported argument: $1" >&2
    exit 1
    ;;
esac
