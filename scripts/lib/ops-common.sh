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

ops_platforms() {
  printf 'claude\ncodex\n'
}

ops_state_file_for() {
  local repo_root="$1"
  local platform="$2"

  case "$platform" in
    claude) printf '%s/state/claude-install-state.json\n' "$repo_root" ;;
    codex) printf '%s/state/codex-install-state.json\n' "$repo_root" ;;
    *) ops_fail "unknown platform: $platform" ;;
  esac
}

ops_install_map_for() {
  local repo_root="$1"
  local platform="$2"

  case "$platform" in
    claude) printf '%s/platforms/claude/install-map.json\n' "$repo_root" ;;
    codex) printf '%s/platforms/codex/install-map.json\n' "$repo_root" ;;
    *) ops_fail "unknown platform: $platform" ;;
  esac
}

ops_sync_script_for() {
  local repo_root="$1"
  local platform="$2"

  case "$platform" in
    claude) printf '%s/scripts/sync-claude.sh\n' "$repo_root" ;;
    codex) printf '%s/scripts/sync-codex.sh\n' "$repo_root" ;;
    *) ops_fail "unknown platform: $platform" ;;
  esac
}

ops_state_get_raw() {
  local state_file="$1"
  local expr="$2"
  jq -r "$expr" "$state_file"
}

ops_state_get_modules_text() {
  local state_file="$1"
  jq -r '.modules | if length == 0 then "(none)" else join(", ") end' "$state_file"
}

ops_validate_installed_target_root() {
  local repo_root_input="$1"
  local target_root="$2"
  local repo_root
  local resolved_root

  repo_root="$(realpath "$repo_root_input")"

  [[ -n "$target_root" ]] || ops_fail "empty target root"
  [[ "$target_root" != "~/"* ]] || ops_fail "unsafe target root points outside repository: $target_root"
  [[ -e "$target_root" ]] || ops_fail "installed target root does not exist: $target_root"

  resolved_root="$(realpath "$target_root")"
  sync_ensure_inside_repo "$repo_root" "$target_root" "$resolved_root"
  printf '%s\n' "$resolved_root"
}

ops_compute_component_digests() {
  local repo_root_input="$1"
  local platform="$2"
  local profile="$3"
  local target_root="$4"
  local repo_root
  local profiles_json="$repo_root/install/profiles.json"
  local modules_json="$repo_root/install/modules.json"
  local components_json="$repo_root/install/components.json"
  local install_map_json
  local work_dir
  local modules_file
  local components_file
  local allowed_paths_file
  local component_paths_file
  local seen_targets_file
  local component_targets_file
  local resolved_target_root

  repo_root="$(realpath "$repo_root_input")"
  profiles_json="$repo_root/install/profiles.json"
  modules_json="$repo_root/install/modules.json"
  components_json="$repo_root/install/components.json"
  install_map_json="$(ops_install_map_for "$repo_root" "$platform")"
  resolved_target_root="$(ops_validate_installed_target_root "$repo_root" "$target_root")"

  work_dir="$(mktemp -d)"
  trap 'rm -rf "$work_dir"' RETURN

  modules_file="$work_dir/modules.txt"
  components_file="$work_dir/components.txt"
  allowed_paths_file="$work_dir/allowed-paths.txt"
  component_paths_file="$work_dir/component-paths.tsv"
  seen_targets_file="$work_dir/seen-targets.txt"
  component_targets_file="$work_dir/component-targets.tsv"

  sync_resolve_profile_modules "$profiles_json" "$modules_json" "$profile" "$modules_file"
  sync_resolve_module_components "$modules_json" "$modules_file" "$components_file"
  sync_resolve_component_paths "$components_json" "$components_file" "$allowed_paths_file" "$component_paths_file"
  sync_collect_component_targets "$repo_root" "$install_map_json" "$allowed_paths_file" "$component_paths_file" "$component_targets_file" "$seen_targets_file"
  sync_compute_component_digests_from_targets "$resolved_target_root" "$component_targets_file"
}
