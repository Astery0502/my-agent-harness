#!/usr/bin/env bash

# External skills: fetch from git and inject into the sync pipeline.
#
# Registry: ops/external-skills.json — array of {name, url, ref?, sub_path?} objects.
# Cache:    .local/external/<url-slug>/  — one clone per unique URL, gitignored.
#
# Multiple skills from the same repo share one clone; sub_path selects the
# relevant subdirectory at inject time.
#
# externals_fetch_all   — clone or pull each unique URL; warns on failure.
# externals_inject_actions — append copy actions for each fetched skill.

EXTERNAL_LIB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck source=./layout-common.sh
source "$EXTERNAL_LIB_DIR/layout-common.sh"

externals_warn() {
  echo "external warning: $*" >&2
}

# Derive a stable, filesystem-safe slug from a git URL for use as a cache dir name.
_externals_url_to_slug() {
  local url="$1"
  printf '%s' "$url" \
    | sed 's|https\?://||; s|\.git$||; s|[^a-zA-Z0-9._-]|-|g; s|^-*||; s|--*|-|g'
}

# Fetch (clone or pull) one repo by slug (URL-derived cache dir name).
# Returns 0 and prints a status line; on error warns and returns 1.
_externals_fetch_one() {
  local repo_root="$1"
  local slug="$2"
  local url="$3"
  local ref="${4:-}"
  local skill_dir
  skill_dir="$(layout_external_skill_dir "$repo_root" "$slug")"

  if [[ ! -d "$skill_dir/.git" ]]; then
    if ! git clone --quiet "$url" "$skill_dir" 2>/dev/null; then
      externals_warn "failed to clone $slug from $url"
      return 1
    fi
    if [[ -n "$ref" ]]; then
      if ! git -C "$skill_dir" checkout --quiet "$ref" 2>/dev/null; then
        externals_warn "failed to checkout ref '$ref' for $slug"
        return 1
      fi
    fi
    printf '%s\n' "external: fetched: $slug"
    return 0
  fi

  # Already cloned — pull for updates.
  local old_head
  old_head="$(git -C "$skill_dir" rev-parse HEAD 2>/dev/null)" || old_head=""

  if ! git -C "$skill_dir" fetch --quiet origin 2>/dev/null; then
    externals_warn "failed to fetch updates for $slug"
    return 1
  fi

  local remote_ref
  if [[ -n "$ref" ]]; then
    remote_ref="origin/$ref"
  else
    remote_ref="origin/HEAD"
  fi

  if ! git -C "$skill_dir" merge --quiet --ff-only "$remote_ref" 2>/dev/null; then
    externals_warn "failed to fast-forward $slug (diverged?)"
    return 1
  fi

  local new_head
  new_head="$(git -C "$skill_dir" rev-parse HEAD 2>/dev/null)" || new_head=""

  if [[ "$old_head" != "$new_head" ]]; then
    printf '%s\n' "external: updated: $slug"
  else
    printf '%s\n' "external: up-to-date: $slug"
  fi
}

# Clone or pull each unique URL in the registry. Warns on individual failures.
# Multiple entries sharing the same URL produce one clone (keyed by URL slug).
externals_fetch_all() {
  local repo_root="$1"
  local registry_file
  registry_file="$(layout_external_registry_file "$repo_root")"

  [[ -f "$registry_file" ]] || return 0

  local count
  count="$(jq 'length' "$registry_file" 2>/dev/null)" || return 0
  (( count > 0 )) || return 0

  local seen_slugs=''
  local i=0
  while (( i < count )); do
    local url ref slug
    url="$(jq -r ".[$i].url" "$registry_file")"
    ref="$(jq -r ".[$i].ref // empty" "$registry_file")"

    if [[ -z "$url" || "$url" == "null" ]]; then
      externals_warn "registry entry $i missing url — skipping"
      i=$((i + 1))
      continue
    fi

    slug="$(_externals_url_to_slug "$url")"

    if [[ "$seen_slugs" != *"|$slug|"* ]]; then
      seen_slugs="$seen_slugs|$slug|"
      _externals_fetch_one "$repo_root" "$slug" "$url" "$ref" || true
    fi

    i=$((i + 1))
  done
}

# Append copy actions for each fetched external skill.
# Discovers the skills base target from the shared-skills action in resolved actions.
externals_inject_actions() {
  local actions="$1"
  local repo_root="$2"
  local registry_file
  registry_file="$(layout_external_registry_file "$repo_root")"

  [[ -f "$registry_file" ]] || { printf '%s\n' "$actions"; return 0; }

  local count
  count="$(jq 'length' "$registry_file" 2>/dev/null)" || { printf '%s\n' "$actions"; return 0; }
  (( count > 0 )) || { printf '%s\n' "$actions"; return 0; }

  # Find the base target for skills (target of the shared-skills copy action).
  local skills_base
  skills_base="$(jq -r '.[] | select(.component == "shared-skills") | .target' <<<"$actions" | head -1)"
  if [[ -z "$skills_base" ]]; then
    externals_warn "shared-skills not in resolved actions — skipping external skill injection"
    printf '%s\n' "$actions"
    return 0
  fi

  local i=0
  while (( i < count )); do
    local name url sub_path slug
    name="$(jq -r ".[$i].name" "$registry_file")"
    url="$(jq -r ".[$i].url" "$registry_file")"
    sub_path="$(jq -r ".[$i].sub_path // empty" "$registry_file")"
    i=$((i + 1))

    [[ -n "$name" && "$name" != "null" ]] || continue
    [[ -n "$url" && "$url" != "null" ]] || continue

    slug="$(_externals_url_to_slug "$url")"
    local skill_dir
    skill_dir="$(layout_external_skill_dir "$repo_root" "$slug")"
    [[ -d "$skill_dir" ]] || continue

    # Relative source path from repo root (for the build stage).
    local rel_source=".local/external/$slug"
    [[ -n "$sub_path" ]] && rel_source="$rel_source/$sub_path"
    local target_path="$skills_base/$name"
    local component_id="external/$name"

    actions="$(jq -c \
      --arg cid "$component_id" \
      --arg src "$rel_source" \
      --arg tgt "$target_path" \
      '. + [{"component": $cid, "source": $src, "target": $tgt}]' \
      <<<"$actions")"
  done

  printf '%s\n' "$actions"
}
