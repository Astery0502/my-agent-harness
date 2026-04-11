#!/usr/bin/env bash

export LC_ALL=C
export LANG=C

OPS_LIB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck source=./sync-common.sh
source "$OPS_LIB_DIR/sync-common.sh"

ops_fail() {
  echo "ops error: $*" >&2
  exit 1
}

ops_default_state_json() {
  local platform="$1"
  jq -n \
    --arg platform "$platform" \
    '{
      platform: $platform,
      installedAt: null,
      profile: "",
      components: [],
      componentDigests: {},
      componentTargets: {},
      targetRoot: "",
      status: "not-installed"
    }'
}

ops_state_file_for() {
  local repo_root="$1"
  local platform="$2"
  local target="$3"
  local state_file

  layout_bootstrap_local_dirs "$repo_root"
  state_file="$(layout_install_state_file_for "$repo_root" "$platform" "$target")"
  mkdir -p "$(dirname "$state_file")"

  if [[ ! -f "$state_file" ]]; then
    ops_default_state_json "$platform" > "$state_file"
  fi

  printf '%s\n' "$state_file"
}

ops_state_get_raw() {
  local state_file="$1"
  local expr="$2"
  jq -r "$expr" "$state_file"
}

ops_state_get_components_text() {
  local state_file="$1"
  jq -r '.components | if length == 0 then "(none)" else join(", ") end' "$state_file"
}

ops_validate_installed_target_root() {
  local repo_root_input="$1"
  local target_root="$2"
  local platform="$3"
  local target="$4"
  local repo_root
  local resolved_root
  local expected_root

  repo_root="$(realpath "$repo_root_input")"

  [[ -n "$target_root" ]] || ops_fail "empty target root"
  [[ -e "$target_root" ]] || ops_fail "installed target root does not exist: $target_root"

  resolved_root="$(realpath "$target_root")"

  case "$target" in
    staging)
      sync_ensure_inside_repo "$repo_root" "$target_root" "$resolved_root"
      ;;
    live)
      expected_root="$(sync_target_root_for "$repo_root" "$platform" "$target")"
      [[ "$resolved_root" == "$expected_root" ]] || ops_fail "installed target root does not match live root: $target_root"
      ;;
    *)
      ops_fail "unknown target: $target"
      ;;
  esac

  printf '%s\n' "$resolved_root"
}

