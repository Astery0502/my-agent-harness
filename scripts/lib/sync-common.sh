#!/usr/bin/env bash

export LC_ALL=C
export LANG=C

SYNC_LIB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck source=./layout-common.sh
source "$SYNC_LIB_DIR/layout-common.sh"
# shellcheck source=./external-common.sh
source "$SYNC_LIB_DIR/external-common.sh"

sync_fail() {
  echo "sync error: $*" >&2
  exit 1
}

sync_require_command() {
  command -v "$1" >/dev/null 2>&1 || sync_fail "required command not found: $1"
}

sync_validate_target() {
  local target="$1"
  case "$target" in
    live|staging) return 0 ;;
    *) return 1 ;;
  esac
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

sync_expand_home_path() {
  local path="$1"
  case "$path" in
    "~")      printf '%s\n' "$HOME" ;;
    "~/"*)    printf '%s/%s\n' "$HOME" "${path#"~/"}" ;;
    /*)       printf '%s\n' "$path" ;;
    *)        sync_fail "target root must be absolute or home-relative: $path" ;;
  esac
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

sync_compute_actual_digests() {
  local target_root="$1"
  local component_targets_json="$2"
  local actual_digests='{}'

  while IFS= read -r cid; do
    local comp_digest
    comp_digest="$(
      jq -r --arg c "$cid" '.[$c][]' <<<"$component_targets_json" | LC_ALL=C sort | while IFS= read -r tp; do
        local td
        td="$(sync_path_digest "$target_root/$tp")"
        printf '%s %s\n' "$tp" "$td"
      done | shasum -a 256 | awk '{print $1}'
    )"
    actual_digests="$(jq -c --arg k "$cid" --arg v "$comp_digest" '. + {($k): $v}' <<<"$actual_digests")"
  done < <(jq -r 'keys[]' <<<"$component_targets_json" | LC_ALL=C sort)

  printf '%s\n' "$actual_digests"
}

# --- Resolution ---

sync_resolve() {
  local repo_root="$1"
  local platform="$2"
  local profile="$3"
  local manifest_file
  local install_map_file
  local profile_components
  local component_ids
  local actions='[]'
  local seen_targets='[]'

  manifest_file="$(layout_manifest_file "$repo_root")"
  install_map_file="$(layout_install_map_for "$repo_root" "$platform")"

  [[ -f "$manifest_file" ]] || sync_fail "manifest not found: $manifest_file"
  [[ -f "$install_map_file" ]] || sync_fail "install map not found for platform: $platform"

  profile_components="$(jq -e --arg p "$profile" '.profiles[$p]' "$manifest_file" 2>/dev/null)" \
    || sync_fail "unknown profile: $profile"
  [[ "$profile_components" != "null" ]] || sync_fail "unknown profile: $profile"

  while IFS= read -r cid; do
    jq -e --arg c "$cid" '.components[$c]' "$manifest_file" >/dev/null 2>&1 \
      || sync_fail "profile references unknown component: $cid"
  done < <(jq -r '.[]' <<<"$profile_components")

  component_ids="$profile_components"

  local mapping_count
  mapping_count="$(jq '.mappings | length' "$install_map_file")"

  local i=0
  while (( i < mapping_count )); do
    local mapping
    mapping="$(jq -c ".mappings[$i]" "$install_map_file")"
    local mode
    mode="$(jq -r '.mode // "copy"' <<<"$mapping")"
    local target_path
    target_path="$(jq -r '.target' <<<"$mapping")"

    sync_validate_relative_path "$target_path"

    if jq -e --arg t "$target_path" 'index($t)' <<<"$seen_targets" >/dev/null 2>&1; then
      sync_fail "multiple mappings resolve to the same target: $target_path"
    fi
    seen_targets="$(jq -c --arg t "$target_path" '. + [$t]' <<<"$seen_targets")"

    if [[ "$mode" == "concat" ]]; then
      local filtered_sources='[]'
      local source_count
      source_count="$(jq '.sources | length' <<<"$mapping")"
      local j=0
      while (( j < source_count )); do
        local src_component
        src_component="$(jq -r ".sources[$j].component" <<<"$mapping")"
        local src_path
        src_path="$(jq -r ".sources[$j].path" <<<"$mapping")"

        jq -e --arg c "$src_component" '.components[$c]' "$manifest_file" >/dev/null 2>&1 \
          || sync_fail "install map references unknown component: $src_component"

        if jq -e --arg c "$src_component" 'index($c)' <<<"$component_ids" >/dev/null 2>&1; then
          sync_validate_relative_path "$src_path"
          [[ -e "$repo_root/$src_path" ]] || sync_fail "source does not exist: $src_path"
          local resolved
          resolved="$(realpath "$repo_root/$src_path")"
          sync_ensure_inside_repo "$repo_root" "$src_path" "$resolved"
          filtered_sources="$(jq -c --arg c "$src_component" --arg p "$src_path" '. + [{"component": $c, "path": $p}]' <<<"$filtered_sources")"
        fi
        j=$((j + 1))
      done

      local filtered_count
      filtered_count="$(jq 'length' <<<"$filtered_sources")"
      if (( filtered_count > 0 )); then
        local action
        action="$(jq -c --argjson srcs "$filtered_sources" --arg t "$target_path" \
          '{sources: $srcs, target: $t, mode: "concat"}' <<<'{}')"
        actions="$(jq -c --argjson a "$action" '. + [$a]' <<<"$actions")"
      fi
    else
      local src_component
      src_component="$(jq -r '.component' <<<"$mapping")"
      local src_path
      src_path="$(jq -r '.source' <<<"$mapping")"

      # validate component exists in manifest
      jq -e --arg c "$src_component" '.components[$c]' "$manifest_file" >/dev/null 2>&1 \
        || sync_fail "install map references unknown component: $src_component"

      if jq -e --arg c "$src_component" 'index($c)' <<<"$component_ids" >/dev/null 2>&1; then
        sync_validate_relative_path "$src_path"
        [[ -e "$repo_root/$src_path" ]] || sync_fail "source does not exist: $src_path"
        local resolved
        resolved="$(realpath "$repo_root/$src_path")"
        sync_ensure_inside_repo "$repo_root" "$src_path" "$resolved"

        local action
        action="$(jq -c --arg c "$src_component" --arg s "$src_path" --arg t "$target_path" \
          '{component: $c, source: $s, target: $t}' <<<'{}')"
        actions="$(jq -c --argjson a "$action" '. + [$a]' <<<"$actions")"
      fi
    fi

    i=$((i + 1))
  done

  # validate every runtime component in the profile has at least one action
  while IFS= read -r cid; do
    local has_runtime_path=0
    while IFS= read -r cpath; do
      if [[ "$cpath" == runtime/* ]]; then
        has_runtime_path=1
        break
      fi
    done < <(jq -r --arg c "$cid" '.components[$c].paths[]' "$manifest_file")

    (( has_runtime_path == 0 )) && continue

    local found=0
    if jq -e --arg c "$cid" '[.[] | select(.component == $c)] | length > 0' <<<"$actions" >/dev/null 2>&1; then
      found=1
    fi
    if (( found == 0 )); then
      if jq -e --arg c "$cid" '[.[] | select(.mode == "concat") | .sources[] | select(.component == $c)] | length > 0' <<<"$actions" >/dev/null 2>&1; then
        found=1
      fi
    fi

    (( found == 1 )) || sync_fail "selected component has no install-map target for platform: $cid"
  done < <(jq -r '.[]' <<<"$component_ids")

  printf '%s\n' "$actions"
}

# --- Build ---

sync_build() {
  local repo_root="$1"
  local actions="$2"
  local build_root="$3"
  local action_count
  local i=0

  rm -rf "$build_root"
  mkdir -p "$build_root"

  action_count="$(jq 'length' <<<"$actions")"

  while (( i < action_count )); do
    local action
    action="$(jq -c ".[$i]" <<<"$actions")"
    local mode
    mode="$(jq -r '.mode // "copy"' <<<"$action")"
    local target_path
    target_path="$(jq -r '.target' <<<"$action")"
    local dest="$build_root/$target_path"
    local dest_dir
    dest_dir="$(dirname "$dest")"

    case "$mode" in
      concat)
        mkdir -p "$dest_dir"
        : > "$dest"
        local first=1
        local j=0
        local src_count
        src_count="$(jq '.sources | length' <<<"$action")"
        while (( j < src_count )); do
          local src_path
          src_path="$(jq -r ".sources[$j].path" <<<"$action")"
          local resolved_src
          resolved_src="$(realpath "$repo_root/$src_path")"
          [[ -f "$resolved_src" ]] || sync_fail "concat requires file sources: $src_path"
          if (( first == 0 )); then
            printf '\n\n' >> "$dest"
          fi
          cat "$resolved_src" >> "$dest"
          first=0
          j=$((j + 1))
        done
        ;;
      *)
        local src_path
        src_path="$(jq -r '.source' <<<"$action")"
        local resolved_src
        resolved_src="$(realpath "$repo_root/$src_path")"
        if [[ -f "$resolved_src" ]]; then
          mkdir -p "$dest_dir"
          cp "$resolved_src" "$dest"
        elif [[ -d "$resolved_src" ]]; then
          mkdir -p "$dest"
          if find "$resolved_src" -mindepth 1 -print -quit | grep -q .; then
            cp -R "$resolved_src"/. "$dest"/
            rm -rf "$dest/.git"
          fi
        else
          sync_fail "unsupported source type: $src_path"
        fi
        ;;
    esac

    i=$((i + 1))
  done
}

# --- Digest ---

sync_digest() {
  local build_root="$1"
  local actions="$2"
  local component_digests='{}'
  local component_targets_map='{}'
  local action_count
  local i=0

  action_count="$(jq 'length' <<<"$actions")"

  while (( i < action_count )); do
    local action
    action="$(jq -c ".[$i]" <<<"$actions")"
    local mode
    mode="$(jq -r '.mode // "copy"' <<<"$action")"
    local target_path
    target_path="$(jq -r '.target' <<<"$action")"

    if [[ "$mode" == "concat" ]]; then
      local j=0
      local src_count
      src_count="$(jq '.sources | length' <<<"$action")"
      while (( j < src_count )); do
        local cid
        cid="$(jq -r ".sources[$j].component" <<<"$action")"
        component_targets_map="$(jq -c --arg c "$cid" --arg t "$target_path" \
          'if .[$c] then .[$c] += [$t] else . + {($c): [$t]} end' <<<"$component_targets_map")"
        j=$((j + 1))
      done
    else
      local cid
      cid="$(jq -r '.component' <<<"$action")"
      component_targets_map="$(jq -c --arg c "$cid" --arg t "$target_path" \
        'if .[$c] then .[$c] += [$t] else . + {($c): [$t]} end' <<<"$component_targets_map")"
    fi

    i=$((i + 1))
  done

  component_digests="$(sync_compute_actual_digests "$build_root" "$component_targets_map")"

  jq -c --argjson digests "$component_digests" --argjson targets "$component_targets_map" \
    '{digests: $digests, targets: $targets}' <<<'{}'
}

sync_prune_backups() {
  local repo_root="$1"
  local platform="$2"
  local keep="${3:-3}"
  local backups_dir
  backups_dir="$(layout_backups_dir "$repo_root")/$platform"

  [[ -d "$backups_dir" ]] || return 0

  local count=0
  while IFS= read -r entry; do
    [[ -n "$entry" ]] || continue
    count=$((count + 1))
    if (( count > keep )); then
      rm -rf "$backups_dir/$entry"
    fi
  done < <(ls -1 "$backups_dir" | LC_ALL=C sort -r)
}

sync_previous_targets_flat() {
  local state_file="$1"

  if [[ ! -f "$state_file" ]]; then
    printf '[]\n'
    return 0
  fi

  jq -c '[.componentTargets // {} | to_entries[] | .value[]] | unique' "$state_file"
}

# --- Deploy ---

sync_deploy() {
  local build_root="$1"
  local target_root="$2"
  local target="$3"
  local actions="$4"
  local repo_root="$5"
  local platform="$6"
  local work_dir="$7"
  local previous_targets_json="${8:-[]}"
  local applied_count=0
  local backup_count=0
  local backup_root=""

  case "$target" in
    staging)
      applied_count="$(jq 'length' <<<"$actions")"
      rm -rf "$target_root"
      mkdir -p "$(dirname "$target_root")"
      mv "$build_root" "$target_root"
      ;;
    live)
      mkdir -p "$target_root"
      local current_targets_json
      current_targets_json="$(jq -c '[.[].target] | unique' <<<"$actions")"

      while IFS= read -r stale_target; do
        [[ -n "$stale_target" ]] || continue
        if [[ -e "$target_root/$stale_target" ]]; then
          if [[ -z "$backup_root" ]]; then
            local ts
            ts="$(date -u +"%Y%m%dT%H%M%SZ")"
            backup_root="$(layout_backup_root_for "$repo_root" "$platform" "$ts")"
            mkdir -p "$backup_root"
          fi
          mkdir -p "$(dirname "$backup_root/$stale_target")"
          rm -rf "$backup_root/$stale_target"
          cp -R "$target_root/$stale_target" "$backup_root/$stale_target"
          rm -rf "$target_root/$stale_target"
          backup_count=$((backup_count + 1))
        fi
      done < <(
        jq -r \
          -n \
          --argjson previous "$previous_targets_json" \
          --argjson current "$current_targets_json" \
          '$previous[] as $target | if ($current | index($target)) then empty else $target end'
      )

      local action_count
      action_count="$(jq 'length' <<<"$actions")"
      local i=0
      local deployed_dir_targets=""
      while (( i < action_count )); do
        local target_path
        target_path="$(jq -r ".[$i].target" <<<"$actions")"
        local source_path="$build_root/$target_path"
        local dest_path="$target_root/$target_path"

        # Skip backup if this target is a sub-path of a directory already deployed
        # by an earlier action in this sync (the parent dir copy already laid it down).
        local covered=0
        if [[ -n "$deployed_dir_targets" ]]; then
          while IFS= read -r dir_target; do
            [[ -z "$dir_target" ]] && continue
            if [[ "$target_path" == "$dir_target"/* ]]; then
              covered=1
              break
            fi
          done <<< "$deployed_dir_targets"
        fi

        if [[ -e "$dest_path" && $covered -eq 0 ]]; then
          if [[ -z "$backup_root" ]]; then
            local ts
            ts="$(date -u +"%Y%m%dT%H%M%SZ")"
            backup_root="$(layout_backup_root_for "$repo_root" "$platform" "$ts")"
            mkdir -p "$backup_root"
          fi
          mkdir -p "$(dirname "$backup_root/$target_path")"
          rm -rf "$backup_root/$target_path"
          cp -R "$dest_path" "$backup_root/$target_path"
          backup_count=$((backup_count + 1))
        fi

        local dest_dir
        dest_dir="$(dirname "$dest_path")"
        mkdir -p "$dest_dir"

        if [[ -f "$source_path" ]]; then
          local tmp
          tmp="$(mktemp "$work_dir/file.XXXXXX")"
          cp "$source_path" "$tmp"
          rm -rf "$dest_path"
          mv "$tmp" "$dest_path"
        elif [[ -d "$source_path" ]]; then
          local tmp
          tmp="$(mktemp -d "$work_dir/dir.XXXXXX")"
          if find "$source_path" -mindepth 1 -print -quit | grep -q .; then
            cp -R "$source_path"/. "$tmp"/
          fi
          rm -rf "$dest_path"
          mv "$tmp" "$dest_path"
          deployed_dir_targets="${deployed_dir_targets:+$deployed_dir_targets
}$target_path"
        else
          sync_fail "built target path missing: $target_path"
        fi

        applied_count=$((applied_count + 1))
        i=$((i + 1))
      done
      ;;
    *)
      sync_fail "unknown target: $target"
      ;;
  esac

  if [[ -n "$backup_root" ]]; then
    sync_prune_backups "$repo_root" "$platform" 3
  fi

  jq -c -n \
    --arg applied "$applied_count" \
    --arg backups "$backup_count" \
    --arg backupRoot "$backup_root" \
    '{appliedCount: ($applied | tonumber), backupCount: ($backups | tonumber), backupRoot: $backupRoot}'
}

# --- Record ---

sync_record() {
  local state_file="$1"
  local platform="$2"
  local profile="$3"
  local digest_info="$4"
  local target_root="$5"
  local components_json="$6"
  local installed_at

  installed_at="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
  mkdir -p "$(dirname "$state_file")"

  jq -n \
    --arg platform "$platform" \
    --arg installedAt "$installed_at" \
    --arg profile "$profile" \
    --arg targetRoot "$target_root" \
    --arg status "installed" \
    --argjson components "$components_json" \
    --argjson digestInfo "$digest_info" \
    '{
      platform: $platform,
      installedAt: $installedAt,
      profile: $profile,
      components: $components,
      componentDigests: $digestInfo.digests,
      componentTargets: $digestInfo.targets,
      targetRoot: $targetRoot,
      status: $status
    }' > "$state_file"
}

# --- Print ---

sync_print_success_report() {
  local platform="$1"
  local target="$2"
  local profile="$3"
  local target_root="$4"
  local components_text="$5"
  local deploy_report="$6"
  local applied_count
  local backup_count
  local backup_root

  IFS=$'\t' read -r applied_count backup_count backup_root \
    < <(jq -r '[.appliedCount, .backupCount, .backupRoot] | @tsv' <<<"$deploy_report")

  printf '%s\n' "sync: installed"
  printf '%s\n' "platform: $platform"
  printf '%s\n' "target: $target"
  printf '%s\n' "profile: $profile"
  printf '%s\n' "target root: $target_root"
  printf '%s\n' "components: $components_text"
  printf '%s\n' "applied targets: $applied_count"
  if (( backup_count > 0 )); then
    printf '%s\n' "backups: created"
    printf '%s\n' "backup root: $backup_root"
  else
    printf '%s\n' "backups: none"
  fi
  printf '%s\n' "status: installed"
  case "$target" in
    live)
      printf '%s\n' "note: unmanaged files under the runtime root were preserved"
      ;;
    staging)
      printf '%s\n' "note: staging was updated without touching the live runtime root"
      ;;
  esac
}

sync_print_dry_run_report() {
  local platform="$1"
  local target="$2"
  local profile="$3"
  local target_root="$4"
  local actions="$5"
  local digest_info="$6"
  local action_count
  action_count="$(jq 'length' <<<"$actions")"

  printf '%s\n' "dry-run: no changes applied"
  printf '%s\n' "platform: $platform"
  printf '%s\n' "target: $target"
  printf '%s\n' "profile: $profile"
  printf '%s\n' "target root: $target_root"
  printf '%s\n' "targets:"

  local i=0
  while (( i < action_count )); do
    local target_path
    target_path="$(jq -r ".[$i].target" <<<"$actions")"
    local mode
    mode="$(jq -r ".[$i].mode // \"copy\"" <<<"$actions")"
    local component
    if [[ "$mode" == "concat" ]]; then
      component="$(jq -r ".[$i].sources | [.[].component] | unique | join(\",\")" <<<"$actions")"
    else
      component="$(jq -r ".[$i].component" <<<"$actions")"
    fi
    printf '  %s (%s) [%s]\n' "$target_path" "$component" "$mode"
    i=$((i + 1))
  done

  printf '%s\n' "digests:"
  jq -r '.digests | to_entries[] | "  \(.key): \(.value)"' <<<"$digest_info"
}

# --- Orchestrator ---

sync_target_root_for() {
  local repo_root="$1"
  local platform="$2"
  local target="$3"

  case "$target" in
    staging)
      layout_staging_root_for "$repo_root" "$platform"
      ;;
    live)
      local install_map_file
      install_map_file="$(layout_install_map_for "$repo_root" "$platform")"
      local configured_root
      configured_root="$(jq -r '.targetRoot' "$install_map_file")"
      [[ -n "$configured_root" && "$configured_root" != "null" ]] || sync_fail "install map missing targetRoot"
      local expanded
      expanded="$(sync_expand_home_path "$configured_root")"
      mkdir -p "$expanded"
      realpath "$expanded"
      ;;
    *)
      sync_fail "unknown sync target: $target"
      ;;
  esac
}

sync_run() {
  local repo_root_input="$1"
  local platform="$2"
  local profile="$3"
  local target="$4"
  local dry_run="${5:-0}"
  local repo_root

  sync_require_command jq
  sync_require_command shasum
  sync_require_command realpath

  repo_root="$(realpath "$repo_root_input")"
  layout_bootstrap_local_dirs "$repo_root"

  externals_fetch_all "$repo_root"

  local actions
  actions="$(sync_resolve "$repo_root" "$platform" "$profile")"
  actions="$(externals_inject_actions "$actions" "$repo_root")"

  local work_dir
  work_dir="$(mktemp -d)"
  trap 'rm -rf "$work_dir"' RETURN

  local build_root="$work_dir/build"
  sync_build "$repo_root" "$actions" "$build_root"

  local digest_info
  digest_info="$(sync_digest "$build_root" "$actions")"

  local target_root
  target_root="$(sync_target_root_for "$repo_root" "$platform" "$target")"

  local manifest_file
  manifest_file="$(layout_manifest_file "$repo_root")"
  local components_json
  components_json="$(jq --arg p "$profile" '.profiles[$p]' "$manifest_file")"
  local components_text
  components_text="$(jq -r 'join(", ")' <<<"$components_json")"

  if [[ "$dry_run" == "1" ]]; then
    sync_print_dry_run_report "$platform" "$target" "$profile" "$target_root" "$actions" "$digest_info"
    return 0
  fi

  local state_file
  state_file="$(layout_install_state_file_for "$repo_root" "$platform" "$target")"
  local previous_targets_json='[]'
  if [[ -f "$state_file" ]]; then
    previous_targets_json="$(sync_previous_targets_flat "$state_file")"
  fi

  # skip deploy if nothing changed (live only — staging always does atomic replace)
  if [[ "$target" == "live" && -f "$state_file" ]]; then
    local stored_status stored_profile stored_target_root stored_digests new_digests
    IFS=$'\t' read -r stored_status stored_profile stored_target_root \
      < <(jq -r '[.status, .profile, .targetRoot] | @tsv' "$state_file")
    stored_digests="$(jq -c '.componentDigests' "$state_file")"
    new_digests="$(jq -c '.digests' <<<"$digest_info")"

    if [[ "$stored_status" == "installed" \
       && "$stored_profile" == "$profile" \
       && "$stored_target_root" == "$target_root" \
       && "$stored_digests" == "$new_digests" ]]; then
      local component_targets actual_digests
      component_targets="$(jq -c '.componentTargets' "$state_file")"
      actual_digests="$(sync_compute_actual_digests "$target_root" "$component_targets")"
      if [[ "$actual_digests" == "$stored_digests" ]]; then
        printf '%s\n' "sync: up-to-date"
        printf '%s\n' "platform: $platform"
        printf '%s\n' "target: $target"
        printf '%s\n' "profile: $profile"
        printf '%s\n' "target root: $target_root"
        printf '%s\n' "components: $components_text"
        printf '%s\n' "note: all component digests match — nothing to deploy"
        return 0
      fi
    fi
  fi

  local deploy_report
  deploy_report="$(sync_deploy "$build_root" "$target_root" "$target" "$actions" "$repo_root" "$platform" "$work_dir" "$previous_targets_json")"

  sync_record "$state_file" "$platform" "$profile" "$digest_info" "$target_root" "$components_json"

  sync_print_success_report "$platform" "$target" "$profile" "$target_root" "$components_text" "$deploy_report"
}
