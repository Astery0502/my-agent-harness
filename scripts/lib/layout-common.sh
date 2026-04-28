#!/usr/bin/env bash

layout_fail() {
  echo "layout error: $*" >&2
  exit 1
}

layout_manifest_file() {
  local repo_root="$1"
  printf '%s/ops/manifest.json\n' "$repo_root"
}

layout_install_map_for() {
  local repo_root="$1"
  local platform="$2"
  printf '%s/runtime/platforms/%s/install-map.json\n' "$repo_root" "$platform"
}

layout_discover_platforms() {
  local repo_root="$1"
  local map_path
  for map_path in "$repo_root"/runtime/platforms/*/install-map.json; do
    [[ -f "$map_path" ]] || continue
    basename "$(dirname "$map_path")"
  done | LC_ALL=C sort
}

layout_local_dir() {
  local repo_root="$1"
  printf '%s/.local\n' "$repo_root"
}

layout_install_state_dir() {
  local repo_root="$1"
  printf '%s/.local/install-state\n' "$repo_root"
}

layout_install_state_target_dir() {
  local repo_root="$1"
  local target="$2"
  case "$target" in
    live|staging)
      printf '%s/%s\n' "$(layout_install_state_dir "$repo_root")" "$target"
      ;;
    *)
      layout_fail "unknown target for install-state path: $target"
      ;;
  esac
}

layout_install_state_file_for() {
  local repo_root="$1"
  local platform="$2"
  local target="$3"
  printf '%s/%s.json\n' "$(layout_install_state_target_dir "$repo_root" "$target")" "$platform"
}

layout_staging_dir() {
  local repo_root="$1"
  printf '%s/.local/staging\n' "$repo_root"
}

layout_staging_root_for() {
  local repo_root="$1"
  local platform="$2"
  printf '%s/%s\n' "$(layout_staging_dir "$repo_root")" "$platform"
}

layout_backups_dir() {
  local repo_root="$1"
  printf '%s/.local/backups\n' "$repo_root"
}

layout_backup_root_for() {
  local repo_root="$1"
  local platform="$2"
  local timestamp="$3"
  printf '%s/%s/%s\n' "$(layout_backups_dir "$repo_root")" "$platform" "$timestamp"
}

layout_external_registry_file() {
  local repo_root="$1"
  printf '%s/ops/external-skills.json\n' "$repo_root"
}

layout_external_dir() {
  local repo_root="$1"
  printf '%s/.local/external\n' "$repo_root"
}

layout_external_skill_dir() {
  local repo_root="$1"
  local name="$2"
  printf '%s/%s\n' "$(layout_external_dir "$repo_root")" "$name"
}

layout_bootstrap_local_dirs() {
  local repo_root="$1"
  # Inline paths to avoid 5 subshell forks; must stay in sync with layout functions above.
  mkdir -p \
    "$repo_root/.local/install-state/live" \
    "$repo_root/.local/install-state/staging" \
    "$repo_root/.local/staging" \
    "$repo_root/.local/backups" \
    "$repo_root/.local/external"
}
