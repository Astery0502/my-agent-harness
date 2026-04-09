#!/usr/bin/env bash

layout_fail() {
  echo "layout error: $*" >&2
  exit 1
}

layout_runtime_dir() {
  local repo_root="$1"
  printf '%s/runtime\n' "$repo_root"
}

layout_ops_dir() {
  local repo_root="$1"
  printf '%s/ops\n' "$repo_root"
}

layout_install_dir() {
  local repo_root="$1"
  printf '%s/ops/install\n' "$repo_root"
}

layout_schema_dir() {
  local repo_root="$1"
  printf '%s/ops/schema\n' "$repo_root"
}

layout_local_dir() {
  local repo_root="$1"
  printf '%s/.local\n' "$repo_root"
}

layout_install_state_dir() {
  local repo_root="$1"
  printf '%s/.local/install-state\n' "$repo_root"
}

layout_staging_dir() {
  local repo_root="$1"
  printf '%s/.local/staging\n' "$repo_root"
}

layout_install_state_file_for() {
  local repo_root="$1"
  local platform="$2"

  case "$platform" in
    claude|codex)
      printf '%s/%s.json\n' "$(layout_install_state_dir "$repo_root")" "$platform"
      ;;
    *)
      layout_fail "unknown platform for install-state path: $platform"
      ;;
  esac
}

layout_staging_root_for() {
  local repo_root="$1"
  local platform="$2"

  case "$platform" in
    claude|codex)
      printf '%s/%s\n' "$(layout_staging_dir "$repo_root")" "$platform"
      ;;
    *)
      layout_fail "unknown platform for staging path: $platform"
      ;;
  esac
}

layout_install_map_for() {
  local repo_root="$1"
  local platform="$2"

  case "$platform" in
    claude|codex)
      printf '%s/runtime/platforms/%s/install-map.json\n' "$repo_root" "$platform"
      ;;
    *)
      layout_fail "unknown platform for install-map path: $platform"
      ;;
  esac
}

layout_bootstrap_local_dirs() {
  local repo_root="$1"
  mkdir -p "$(layout_install_state_dir "$repo_root")" "$(layout_staging_dir "$repo_root")"
}
