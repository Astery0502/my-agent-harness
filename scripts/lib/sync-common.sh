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
      {
        find . -mindepth 1 -type d -print | LC_ALL=C sort | sed 's/^/D /'
        find . -mindepth 1 -type f -print0 \
          | xargs -0 shasum -a 256 \
          | awk '{print "F " $2 " " $1}'
      } | LC_ALL=C sort -t' ' -k2
    ) | shasum -a 256 | awk '{print $1}'
    return
  fi
  sync_fail "cannot digest missing path: $path"
}

sync_compute_actual_digests() {
  local target_root="$1"
  local component_targets_json="$2"

  # Single jq call: emit sorted "cid TAB target" lines grouped by component
  local pairs
  pairs="$(jq -r \
    'to_entries | sort_by(.key)[] | .key as $k | (.value | sort[]) | [$k, .] | @tsv' \
    <<<"$component_targets_json")"

  [[ -n "$pairs" ]] || { printf '{}'; return 0; }

  # First pass: collect all FILE targets for a single batched shasum call.
  # Directories are handled by sync_path_digest in the second pass.
  local _batch_files=() _batch_idx=0
  local _cid _tp
  while IFS=$'\t' read -r _cid _tp; do
    [[ -n "$_cid" ]] || continue
    [[ -f "$target_root/$_tp" ]] && _batch_files+=("$target_root/$_tp")
  done <<< "$pairs"

  # Single shasum call for all files; store hashes positionally
  local _file_hashes=()
  if [[ ${#_batch_files[@]} -gt 0 ]]; then
    local _h _rest
    while IFS=' ' read -r _h _rest; do
      _file_hashes+=("$_h")
    done < <(shasum -a 256 "${_batch_files[@]}")
  fi

  # Second pass: build per-component hash inputs using cached file hashes
  local prev_cid="" hash_input="" digest_lines="" comp_digest

  while IFS=$'\t' read -r _cid _tp; do
    [[ -n "$_cid" ]] || continue

    if [[ "$_cid" != "$prev_cid" && -n "$prev_cid" ]]; then
      { read -r comp_digest _; } < <(printf '%s' "$hash_input" | shasum -a 256)
      digest_lines="${digest_lines}${prev_cid}"$'\t'"${comp_digest}"$'\n'
      hash_input=""
    fi
    prev_cid="$_cid"

    local _full="$target_root/$_tp"
    local _td
    if [[ -f "$_full" && "${_batch_files[$_batch_idx]}" == "$_full" ]]; then
      _td="${_file_hashes[$_batch_idx]}"
      _batch_idx=$((_batch_idx + 1))
    else
      _td="$(sync_path_digest "$_full")"
    fi
    hash_input="${hash_input}${_tp} ${_td}"$'\n'
  done <<< "$pairs"

  if [[ -n "$prev_cid" ]]; then
    { read -r comp_digest _; } < <(printf '%s' "$hash_input" | shasum -a 256)
    digest_lines="${digest_lines}${prev_cid}"$'\t'"${comp_digest}"
  fi

  # Single jq call: build compact JSON object from TSV lines
  printf '%s\n' "$digest_lines" \
    | jq -Rcn '[inputs | select(length > 0) | split("\t") | {key: .[0], value: .[1]}] | from_entries'
}

# --- Resolution ---

sync_resolve() {
  local repo_root="$1"
  local platform="$2"
  local profile="$3"
  local manifest_file
  local install_map_file

  manifest_file="$(layout_manifest_file "$repo_root")"
  install_map_file="$(layout_install_map_for "$repo_root" "$platform")"

  [[ -f "$manifest_file" ]] || sync_fail "manifest not found: $manifest_file"
  [[ -f "$install_map_file" ]] || sync_fail "install map not found for platform: $platform"

  # Single jq call: validate profile + emit component and path metadata.
  # Line format:
  #   PC\t<cid>           – profile component (validates it exists in .components)
  #   CP\t<cid>\t<path>   – component source path (all components, for runtime-path detection)
  #   AC\t<cid>           – all manifest component names (for install-map validation)
  local manifest_meta
  manifest_meta="$(jq -re --arg p "$profile" '
    . as $m |
    ($m.profiles[$p] // error("unknown profile: " + $p)) as $cids |
    (
      $cids[] |
      if ($m.components[.] == null) then error("profile references unknown component: " + .) else . end |
      "PC\t" + .
    ),
    (
      $m.components | to_entries[] |
      .key as $k | (.value.paths // [])[] | "CP\t" + $k + "\t" + .
    ),
    (
      $m.components | keys[] | "AC\t" + .
    )
  ' "$manifest_file" 2>&1)" || sync_fail "$manifest_meta"

  # Build lookup sets (space-padded strings) and component list from metadata
  local cid_list=""             # newline-separated profile component IDs
  local in_profile_set=" "     # " cid1 cid2 … " for O(1)-style membership checks
  local all_comps_set=" "      # all manifest component names
  local runtime_path_comps=" " # components that have at least one runtime/* path

  local _type _a _b
  while IFS=$'\t' read -r _type _a _b; do
    case "$_type" in
      PC)
        cid_list="${cid_list}${_a}"$'\n'
        in_profile_set="$in_profile_set$_a "
        ;;
      CP)
        [[ "$_b" == runtime/* ]] && runtime_path_comps="$runtime_path_comps$_a "
        ;;
      AC)
        all_comps_set="$all_comps_set$_a "
        ;;
    esac
  done <<< "$manifest_meta"

  # Single jq call: emit all mapping fields as TSV.
  # Copy line:   copy\t<target>\t<component>\t<source>
  # Concat line: concat\t<target>\t<N>\t<comp1>\t<path1>[\t<comp2>\t<path2>…]
  local mapping_lines
  mapping_lines="$(jq -r '
    .mappings[] |
    if .mode == "concat" then
      (["concat", .target, (.sources | length)] + [.sources[] | .component, .path]) | @tsv
    else
      ["copy", .target, .component, (.source // "")] | @tsv
    end
  ' "$install_map_file")"

  local seen_targets=" "  # space-padded set of deployed target paths
  local actions_inner=""  # comma-separated JSON action objects (no outer brackets)

  local _mode _target_path _rest
  local _src_component _src_path _resolved _action_json
  local _num_sources _sources_str _remain _j _src_json _fsrcs_inner

  while IFS=$'\t' read -r _mode _target_path _rest; do
    [[ -n "$_mode" ]] || continue

    sync_validate_relative_path "$_target_path"

    if [[ "$seen_targets" == *" $_target_path "* ]]; then
      sync_fail "multiple mappings resolve to the same target: $_target_path"
    fi
    seen_targets="$seen_targets$_target_path "

    if [[ "$_mode" == "concat" ]]; then
      _num_sources="${_rest%%$'\t'*}"
      _sources_str="${_rest#*$'\t'}"
      _fsrcs_inner=""
      _remain="$_sources_str"
      _j=0
      while (( _j < _num_sources )); do
        _src_component="${_remain%%$'\t'*}"
        _remain="${_remain#*$'\t'}"
        if [[ "$_remain" == *$'\t'* ]]; then
          _src_path="${_remain%%$'\t'*}"
          _remain="${_remain#*$'\t'}"
        else
          _src_path="$_remain"
          _remain=""
        fi
        _j=$((_j + 1))

        [[ "$all_comps_set" == *" $_src_component "* ]] \
          || sync_fail "install map references unknown component: $_src_component"

        if [[ "$in_profile_set" == *" $_src_component "* ]]; then
          sync_validate_relative_path "$_src_path"
          [[ -e "$repo_root/$_src_path" ]] || sync_fail "source does not exist: $_src_path"
          _resolved="$(realpath "$repo_root/$_src_path")"
          sync_ensure_inside_repo "$repo_root" "$_src_path" "$_resolved"
          _src_json="{\"component\":\"$_src_component\",\"path\":\"$_src_path\"}"
          if [[ -n "$_fsrcs_inner" ]]; then
            _fsrcs_inner="$_fsrcs_inner,$_src_json"
          else
            _fsrcs_inner="$_src_json"
          fi
        fi
      done

      if [[ -n "$_fsrcs_inner" ]]; then
        _action_json="{\"sources\":[$_fsrcs_inner],\"target\":\"$_target_path\",\"mode\":\"concat\"}"
        if [[ -n "$actions_inner" ]]; then
          actions_inner="$actions_inner,$_action_json"
        else
          actions_inner="$_action_json"
        fi
      fi
    else
      _src_component="${_rest%%$'\t'*}"
      _src_path="${_rest#*$'\t'}"

      [[ "$all_comps_set" == *" $_src_component "* ]] \
        || sync_fail "install map references unknown component: $_src_component"

      if [[ "$in_profile_set" == *" $_src_component "* ]]; then
        sync_validate_relative_path "$_src_path"
        [[ -e "$repo_root/$_src_path" ]] || sync_fail "source does not exist: $_src_path"
        _resolved="$(realpath "$repo_root/$_src_path")"
        sync_ensure_inside_repo "$repo_root" "$_src_path" "$_resolved"
        _action_json="{\"component\":\"$_src_component\",\"source\":\"$_src_path\",\"target\":\"$_target_path\"}"
        if [[ -n "$actions_inner" ]]; then
          actions_inner="$actions_inner,$_action_json"
        else
          actions_inner="$_action_json"
        fi
      fi
    fi
  done <<< "$mapping_lines"

  local actions="[$actions_inner]"

  # Validate every runtime component in the profile appears in at least one action
  local _cid
  while IFS= read -r _cid; do
    [[ -n "$_cid" ]] || continue
    [[ "$runtime_path_comps" == *" $_cid "* ]] || continue
    if [[ "$actions_inner" != *"\"component\":\"$_cid\""* ]]; then
      sync_fail "selected component has no install-map target for platform: $_cid"
    fi
  done <<< "$cid_list"

  printf '%s\n' "$actions"
}

# --- Build ---

sync_build() {
  local repo_root="$1"
  local actions="$2"
  local build_root="$3"

  rm -rf "$build_root"
  mkdir -p "$build_root"

  # Single jq call: emit all actions as TSV
  # copy:   copy\t<target>\t<source>
  # concat: concat\t<target>\t<N>\t<path1>[\t<path2>...]
  local build_lines
  build_lines="$(jq -r '.[] |
    if .mode == "concat" then
      ["concat", .target, (.sources | length)] + [.sources[].path] | @tsv
    else
      ["copy", .target, .source] | @tsv
    end
  ' <<<"$actions")"

  local _mode _target_path _rest
  while IFS=$'\t' read -r _mode _target_path _rest; do
    [[ -n "$_mode" ]] || continue
    local dest="$build_root/$_target_path"
    local dest_dir="${dest%/*}"

    if [[ "$_mode" == "concat" ]]; then
      local _num_sources _src_path _src _first=1 _j=0 _remain
      _num_sources="${_rest%%$'\t'*}"
      _remain="${_rest#*$'\t'}"
      mkdir -p "$dest_dir"
      : > "$dest"
      while (( _j < _num_sources )); do
        if [[ "$_remain" == *$'\t'* ]]; then
          _src_path="${_remain%%$'\t'*}"
          _remain="${_remain#*$'\t'}"
        else
          _src_path="$_remain"
          _remain=""
        fi
        _j=$((_j + 1))
        # Sources validated in sync_resolve (relative, within repo, no traversal)
        _src="$repo_root/$_src_path"
        [[ -f "$_src" ]] || sync_fail "concat requires file sources: $_src_path"
        if (( _first == 0 )); then
          printf '\n\n' >> "$dest"
        fi
        cat "$_src" >> "$dest"
        _first=0
      done
    else
      # Source validated in sync_resolve; use directly without realpath
      local _src="$repo_root/$_rest"
      if [[ -f "$_src" ]]; then
        mkdir -p "$dest_dir"
        cp "$_src" "$dest"
      elif [[ -d "$_src" ]]; then
        mkdir -p "$dest"
        if find "$_src" -mindepth 1 -print -quit | grep -q .; then
          cp -R "$_src"/. "$dest"/
          rm -rf "$dest/.git"
        fi
      else
        sync_fail "unsupported source type: $_rest"
      fi
    fi
  done <<< "$build_lines"
}

# --- Digest ---

sync_digest() {
  local build_root="$1"
  local actions="$2"

  # Single jq call: build component→targets map from all actions at once
  local component_targets_map
  component_targets_map="$(jq -c '
    reduce .[] as $a (
      {};
      if $a.mode == "concat" then
        reduce $a.sources[] as $s (.; .[$s.component] += [$a.target])
      else
        .[$a.component] += [$a.target]
      end
    )
  ' <<<"$actions")"

  local component_digests
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
      mkdir -p "${target_root%/*}"
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
          mkdir -p "${backup_root}/${stale_target%/*}"
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

      local deployed_dir_targets=""
      while IFS= read -r target_path; do
        [[ -n "$target_path" ]] || continue
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
          mkdir -p "${backup_root}/${target_path%/*}"
          rm -rf "$backup_root/$target_path"
          cp -R "$dest_path" "$backup_root/$target_path"
          backup_count=$((backup_count + 1))
        fi

        mkdir -p "${dest_path%/*}"

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
      done < <(jq -r '.[].target' <<<"$actions")
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

  printf '%s\n' "dry-run: no changes applied"
  printf '%s\n' "platform: $platform"
  printf '%s\n' "target: $target"
  printf '%s\n' "profile: $profile"
  printf '%s\n' "target root: $target_root"
  printf '%s\n' "targets:"

  # Single jq call: emit target, component(s), mode as TSV
  jq -r '.[] |
    (.mode // "copy") as $m |
    (if $m == "concat" then [.sources[].component] | unique | join(",") else .component end) as $c |
    [.target, $c, $m] | @tsv
  ' <<<"$actions" | while IFS=$'\t' read -r _tp _comp _mode; do
    printf '  %s (%s) [%s]\n' "$_tp" "$_comp" "$_mode"
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
