#!/usr/bin/env bash

export LC_ALL=C
export LANG=C

SYNC_LIB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck source=./layout-common.sh
source "$SYNC_LIB_DIR/layout-common.sh"

sync_fail() {
  echo "sync error: $*" >&2
  exit 1
}

sync_require_command() {
  command -v "$1" >/dev/null 2>&1 || sync_fail "required command not found: $1"
}

sync_validate_relative_path() {
  local path="$1"

  [[ -n "$path" ]] || sync_fail "empty path is not allowed"
  [[ "$path" != /* ]] || sync_fail "absolute paths are not allowed: $path"
  [[ "$path" != *".."* ]] || sync_fail "parent directory traversal is not allowed: $path"
}

sync_ensure_inside_repo() {
  local repo_root="$1"
  local source_path="$2"
  local resolved_path="$3"

  case "$resolved_path" in
    "$repo_root" | "$repo_root"/*) ;;
    *)
      sync_fail "source path escapes repository root: $source_path"
      ;;
  esac
}

sync_source_is_allowed() {
  local source_path="$1"
  local allowed_paths_file="$2"
  local allowed_path

  while IFS= read -r allowed_path; do
    [[ -n "$allowed_path" ]] || continue
    if [[ "$source_path" == "$allowed_path" || "$source_path" == "$allowed_path/"* ]]; then
      return 0
    fi
  done < "$allowed_paths_file"

  return 1
}

sync_component_for_source() {
  local source_path="$1"
  local component_paths_file="$2"
  local best_component=""
  local best_length=0
  local component
  local component_path
  local path_length

  while IFS=$'\t' read -r component component_path; do
    [[ -n "$component" && -n "$component_path" ]] || continue
    if [[ "$source_path" == "$component_path" || "$source_path" == "$component_path/"* ]]; then
      path_length=${#component_path}
      if (( path_length > best_length )); then
        best_component="$component"
        best_length=$path_length
      fi
    fi
  done < "$component_paths_file"

  [[ -n "$best_component" ]] || sync_fail "no resolved component matched source path: $source_path"
  printf '%s\n' "$best_component"
}

sync_path_digest() {
  local path="$1"

  if [[ -f "$path" ]]; then
    shasum -a 256 "$path" | awk '{print $1}'
    return
  fi

  if [[ -d "$path" ]]; then
    (
      cd "$path"
      find . -mindepth 1 -print | LC_ALL=C sort | while IFS= read -r entry; do
        if [[ -d "$entry" ]]; then
          printf 'D %s\n' "$entry"
        elif [[ -f "$entry" ]]; then
          printf 'F %s %s\n' "$entry" "$(shasum -a 256 "$entry" | awk '{print $1}')"
        fi
      done
    ) | shasum -a 256 | awk '{print $1}'
    return
  fi

  sync_fail "cannot digest missing path: $path"
}

sync_prepare_repo_context() {
  local repo_root_input="$1"
  local repo_root

  sync_require_command jq
  sync_require_command shasum
  sync_require_command realpath

  repo_root="$(realpath "$repo_root_input")"
  printf '%s\n' "$repo_root"
}

sync_resolve_profile_modules() {
  local profiles_json="$1"
  local modules_json="$2"
  local profile="$3"
  local modules_file="$4"
  local current_module

  jq -r --arg profile "$profile" '
    .profiles[]
    | select(.id == $profile)
    | .modules[]
  ' "$profiles_json" > "$modules_file"

  [[ -s "$modules_file" ]] || sync_fail "unknown or empty profile: $profile"

  while IFS= read -r current_module; do
    jq -e --arg module "$current_module" '
      .modules[]
      | select(.id == $module)
    ' "$modules_json" >/dev/null || sync_fail "profile references unknown module: $current_module"
  done < "$modules_file"
}

sync_resolve_module_components() {
  local modules_json="$1"
  local modules_file="$2"
  local components_file="$3"
  local current_module

  : > "$components_file"
  while IFS= read -r current_module; do
    jq -r --arg module "$current_module" '
      .modules[]
      | select(.id == $module)
      | .components[]
    ' "$modules_json" >> "$components_file"
  done < "$modules_file"

  LC_ALL=C sort -u "$components_file" -o "$components_file"
  [[ -s "$components_file" ]] || sync_fail "resolved zero components"
}

sync_resolve_component_paths() {
  local components_json="$1"
  local components_file="$2"
  local allowed_paths_file="$3"
  local component_paths_file="$4"
  local current_component
  local source_path

  : > "$allowed_paths_file"
  : > "$component_paths_file"

  while IFS= read -r current_component; do
    jq -e --arg component "$current_component" '
      .components[]
      | select(.id == $component)
    ' "$components_json" >/dev/null || sync_fail "module references unknown component: $current_component"

    jq -r --arg component "$current_component" '
      .components[]
      | select(.id == $component)
      | .paths[]
    ' "$components_json" | while IFS= read -r source_path; do
      sync_validate_relative_path "$source_path"
      printf '%s\n' "$source_path" >> "$allowed_paths_file"
      printf '%s\t%s\n' "$current_component" "$source_path" >> "$component_paths_file"
    done
  done < "$components_file"

  LC_ALL=C sort -u "$allowed_paths_file" -o "$allowed_paths_file"
}

sync_collect_mapping_actions() {
  local repo_root="$1"
  local install_map_json="$2"
  local allowed_paths_file="$3"
  local component_paths_file="$4"
  local action_file="$5"
  local component_targets_file="$6"
  local seen_targets_file="$7"
  local mapping
  local source_path
  local target_path
  local mode
  local resolved_source
  local component_id
  local source_count

  : > "$action_file"
  : > "$component_targets_file"
  : > "$seen_targets_file"

  while IFS= read -r mapping; do
    target_path="$(printf '%s' "$mapping" | jq -r '.target')"
    mode="$(printf '%s' "$mapping" | jq -r '.mode // "copy"')"

    sync_validate_relative_path "$target_path"

    if grep -Fxq "$target_path" "$seen_targets_file"; then
      sync_fail "multiple mappings resolve to the same target: $target_path"
    fi
    printf '%s\n' "$target_path" >> "$seen_targets_file"

    case "$mode" in
      concat)
        source_count=0
        while IFS= read -r source_path; do
          sync_validate_relative_path "$source_path"
          if ! sync_source_is_allowed "$source_path" "$allowed_paths_file"; then
            continue
          fi

          [[ -e "$repo_root/$source_path" ]] || sync_fail "install map source does not exist: $source_path"
          resolved_source="$(realpath "$repo_root/$source_path")"
          sync_ensure_inside_repo "$repo_root" "$source_path" "$resolved_source"

          component_id="$(sync_component_for_source "$source_path" "$component_paths_file")"
          printf '%s\t%s\n' "$component_id" "$target_path" >> "$component_targets_file"
          source_count=$((source_count + 1))
        done < <(printf '%s' "$mapping" | jq -r '.sources[]')

        (( source_count > 0 )) || sync_fail "concat mapping resolved zero allowed sources for target: $target_path"
        printf '%s\n' "$mapping" >> "$action_file"
        ;;
      *)
        source_path="$(printf '%s' "$mapping" | jq -r '.source')"
        sync_validate_relative_path "$source_path"

        if ! sync_source_is_allowed "$source_path" "$allowed_paths_file"; then
          continue
        fi

        [[ -e "$repo_root/$source_path" ]] || sync_fail "install map source does not exist: $source_path"
        resolved_source="$(realpath "$repo_root/$source_path")"
        sync_ensure_inside_repo "$repo_root" "$source_path" "$resolved_source"

        component_id="$(sync_component_for_source "$source_path" "$component_paths_file")"
        printf '%s\t%s\n' "$component_id" "$target_path" >> "$component_targets_file"
        printf '%s\n' "$mapping" >> "$action_file"
        ;;
    esac
  done < <(jq -c '.mappings[]' "$install_map_json")

  LC_ALL=C sort -u "$component_targets_file" -o "$component_targets_file"
}

sync_validate_component_targets() {
  local components_file="$1"
  local component_paths_file="$2"
  local component_targets_file="$3"
  local current_component
  local requires_runtime_target

  while IFS= read -r current_component; do
    [[ -n "$current_component" ]] || continue
    requires_runtime_target=0
    while IFS=$'\t' read -r component_id component_path; do
      [[ "$component_id" == "$current_component" ]] || continue
      if [[ "$component_path" == runtime/* ]]; then
        requires_runtime_target=1
        break
      fi
    done < "$component_paths_file"

    (( requires_runtime_target == 1 )) || continue

    if ! cut -f1 "$component_targets_file" | grep -Fxq "$current_component"; then
      sync_fail "selected component has no install-map target for platform: $current_component"
    fi
  done < "$components_file"
}

sync_compute_component_digests_from_targets() {
  local staging_root="$1"
  local component_targets_file="$2"
  local component_digests_json='{}'
  local current_component
  local component_digest
  local target_digest
  local component_id
  local target_path

  if [[ -s "$component_targets_file" ]]; then
    while IFS= read -r current_component; do
      component_digest="$(
        while IFS=$'\t' read -r component_id target_path; do
          [[ "$component_id" == "$current_component" ]] || continue
          target_digest="$(sync_path_digest "$staging_root/$target_path")"
          printf '%s %s\n' "$target_path" "$target_digest"
        done < "$component_targets_file" | LC_ALL=C sort | shasum -a 256 | awk '{print $1}'
      )"
      component_digests_json="$(
        jq -c --arg key "$current_component" --arg value "$component_digest" '. + {($key): $value}' <<<"$component_digests_json"
      )"
    done < <(cut -f1 "$component_targets_file" | LC_ALL=C sort -u)
  fi

  printf '%s\n' "$component_digests_json"
}

sync_run() {
  local repo_root_input="$1"
  local platform="$2"
  local profile="$3"
  local repo_root
  local install_dir
  local profiles_json
  local modules_json
  local components_json
  local install_map_json
  local state_file
  local staging_root
  local work_dir
  local modules_file
  local components_file
  local allowed_paths_file
  local component_paths_file
  local action_file
  local seen_targets_file
  local component_targets_file
  local component_digests_json
  local installed_at
  local modules_json_value
  local mapping
  local mode
  local source_path
  local target_path
  local destination_dir
  local resolved_source
  local destination_path
  local first_source

  repo_root="$(sync_prepare_repo_context "$repo_root_input")"
  install_dir="$(layout_install_dir "$repo_root")"
  profiles_json="$install_dir/profiles.json"
  modules_json="$install_dir/modules.json"
  components_json="$install_dir/components.json"
  install_map_json="$(layout_install_map_for "$repo_root" "$platform")"
  state_file="$(layout_install_state_file_for "$repo_root" "$platform")"
  staging_root="$(layout_staging_root_for "$repo_root" "$platform")"

  sync_require_command jq
  sync_require_command shasum
  sync_require_command realpath

  layout_bootstrap_local_dirs "$repo_root"

  work_dir="$(mktemp -d)"
  trap 'rm -rf "$work_dir"' RETURN

  modules_file="$work_dir/modules.txt"
  components_file="$work_dir/components.txt"
  allowed_paths_file="$work_dir/allowed-paths.txt"
  component_paths_file="$work_dir/component-paths.tsv"
  action_file="$work_dir/actions.jsonl"
  seen_targets_file="$work_dir/seen-targets.txt"
  component_targets_file="$work_dir/component-targets.tsv"

  sync_resolve_profile_modules "$profiles_json" "$modules_json" "$profile" "$modules_file"
  sync_resolve_module_components "$modules_json" "$modules_file" "$components_file"
  sync_resolve_component_paths "$components_json" "$components_file" "$allowed_paths_file" "$component_paths_file"
  sync_collect_mapping_actions "$repo_root" "$install_map_json" "$allowed_paths_file" "$component_paths_file" "$action_file" "$component_targets_file" "$seen_targets_file"
  sync_validate_component_targets "$components_file" "$component_paths_file" "$component_targets_file"

  rm -rf "$staging_root"
  mkdir -p "$staging_root"

  while IFS= read -r mapping; do
    mode="$(printf '%s' "$mapping" | jq -r '.mode // "copy"')"
    target_path="$(printf '%s' "$mapping" | jq -r '.target')"
    destination_path="$staging_root/$target_path"
    destination_dir="$(dirname "$destination_path")"

    case "$mode" in
      concat)
        mkdir -p "$destination_dir"
        : > "$destination_path"
        first_source=1
        while IFS= read -r source_path; do
          if ! sync_source_is_allowed "$source_path" "$allowed_paths_file"; then
            continue
          fi

          resolved_source="$(realpath "$repo_root/$source_path")"
          [[ -f "$resolved_source" ]] || sync_fail "concat mappings require file sources: $source_path"

          if (( first_source == 0 )); then
            printf '\n\n' >> "$destination_path"
          fi
          cat "$resolved_source" >> "$destination_path"
          first_source=0
        done < <(printf '%s' "$mapping" | jq -r '.sources[]')

        (( first_source == 0 )) || sync_fail "concat mapping produced no output for target: $target_path"
        ;;
      *)
        source_path="$(printf '%s' "$mapping" | jq -r '.source')"
        resolved_source="$(realpath "$repo_root/$source_path")"

        if [[ -f "$resolved_source" ]]; then
          mkdir -p "$destination_dir"
          cp "$resolved_source" "$destination_path"
        elif [[ -d "$resolved_source" ]]; then
          mkdir -p "$destination_path"
          if find "$resolved_source" -mindepth 1 -print -quit | grep -q .; then
            cp -R "$resolved_source"/. "$destination_path"/
          fi
        else
          sync_fail "unsupported install map source type: $source_path"
        fi
        ;;
    esac
  done < "$action_file"

  component_digests_json="$(sync_compute_component_digests_from_targets "$staging_root" "$component_targets_file")"

  installed_at="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
  modules_json_value="$(jq -R -s 'split("\n") | map(select(length > 0))' "$modules_file")"

  mkdir -p "$(dirname "$state_file")"

  jq -n \
    --arg platform "$platform" \
    --arg installedAt "$installed_at" \
    --arg profile "$profile" \
    --arg targetRoot "$staging_root" \
    --arg status "installed" \
    --argjson modules "$modules_json_value" \
    --argjson componentDigests "$component_digests_json" \
    '{
      platform: $platform,
      installedAt: $installedAt,
      profile: $profile,
      modules: $modules,
      componentDigests: $componentDigests,
      targetRoot: $targetRoot,
      status: $status
    }' > "$state_file"
}
