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

# Returns 0 (true) if the registry file is the empty JSON array [].
# Mirrors the path returned by layout_external_registry_file.
_externals_registry_is_empty() {
  local registry_file="$1"
  local _first_line
  IFS= read -r _first_line < "$registry_file" 2>/dev/null || true
  [[ "$_first_line" == '[]' ]]
}

externals_fetch_timeout_seconds() {
  local configured="${EXTERNALS_FETCH_TIMEOUT:-15}"
  if [[ "$configured" =~ ^[0-9]+$ ]] && (( configured > 0 )); then
    printf '%s\n' "$configured"
    return 0
  fi
  printf '%s\n' "15"
}

_externals_run_with_timeout() {
  local seconds="$1"
  shift

  perl -e 'alarm shift @ARGV; exec @ARGV' "$seconds" "$@"
}

# Derive a stable, filesystem-safe slug from a git URL for use as a cache dir name.
_externals_url_to_slug() {
  local url="$1"
  case "$url" in
    [hH][tT][tT][pP]://*) url="${url#*://}" ;;
    [hH][tT][tT][pP][sS]://*) url="${url#*://}" ;;
  esac
  printf '%s' "$url" \
    | sed 's|\.git$||; s|[^a-zA-Z0-9._-]|-|g; s|^-*||; s|--*|-|g'
}

# Resolve a GitHub repository path (owner/repo) from an HTTPS GitHub URL.
_externals_github_repo_path() {
  local url="$1"
  case "$url" in
    https://github.com/*|http://github.com/*) ;;
    *) return 1 ;;
  esac

  local path
  path="${url#*://github.com/}"
  path="${path%.git}"
  local owner="${path%%/*}"
  local repo_path="${path#*/}"
  [[ "$repo_path" != "$path" ]] || return 1
  local repo="${repo_path%%/*}"

  [[ -n "$owner" && -n "$repo" ]] || return 1
  printf '%s/%s\n' "$owner" "$repo"
}

_externals_resolve_latest_release_ref() {
  local url="$1"
  local repo_path
  repo_path="$(_externals_github_repo_path "$url")" || return 1

  local timeout_seconds tag
  timeout_seconds="$(externals_fetch_timeout_seconds)"

  if command -v gh >/dev/null 2>&1; then
    tag="$(_externals_run_with_timeout "$timeout_seconds" \
      gh api "repos/$repo_path/releases/latest" --jq .tag_name 2>/dev/null || true)"
    if [[ -n "$tag" && "$tag" != "null" ]]; then
      printf '%s\n' "$tag"
      return 0
    fi
  fi

  if command -v curl >/dev/null 2>&1; then
    tag="$(curl -fsSL --max-time "$timeout_seconds" \
      "https://api.github.com/repos/$repo_path/releases/latest" 2>/dev/null \
      | jq -r '.tag_name // empty' 2>/dev/null || true)"
    if [[ -n "$tag" && "$tag" != "null" ]]; then
      printf '%s\n' "$tag"
      return 0
    fi
  fi

  return 1
}

# Clone a GitHub URL via the gh CLI into dest. Returns 1 if gh is unavailable,
# URL is not GitHub, or the clone fails.
_externals_gh_clone() {
  local url="$1"
  local dest="$2"
  command -v gh >/dev/null 2>&1 || return 1
  local timeout_seconds
  timeout_seconds="$(externals_fetch_timeout_seconds)"
  local repo_path
  repo_path="$(_externals_github_repo_path "$url")" || return 1
  _externals_run_with_timeout "$timeout_seconds" \
    gh repo clone "$repo_path" "$dest" -- --quiet 2>/dev/null
}

# Fetch (clone or pull) one repo by slug (URL-derived cache dir name).
# Returns 0 and prints a status line; on error warns and returns 1.
_externals_fetch_one() {
  local repo_root="$1"
  local slug="$2"
  local url="$3"
  local ref="${4:-}"
  local skill_dir
  local tmp_dir=""
  local timeout_seconds
  local status
  skill_dir="$(layout_external_skill_dir "$repo_root" "$slug")"
  timeout_seconds="$(externals_fetch_timeout_seconds)"

  if [[ -d "$skill_dir/.git" ]] && ! git -C "$skill_dir" rev-parse --verify --quiet HEAD >/dev/null; then
    rm -rf "$skill_dir"
  fi

  if [[ ! -d "$skill_dir/.git" ]]; then
    status=0
    _externals_run_with_timeout "$timeout_seconds" \
      git clone --quiet "$url" "$skill_dir" 2>/dev/null || status=$?
    if (( status != 0 )); then
      if (( status == 142 )); then
        externals_warn "timed out cloning $slug from $url"
        return 1
      fi
      if ! _externals_gh_clone "$url" "$skill_dir"; then
        externals_warn "failed to clone $slug from $url"
        return 1
      fi
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

  # Already cloned — fetch updates and move to the requested ref.
  local old_head
  old_head="$(git -C "$skill_dir" rev-parse HEAD 2>/dev/null)" || old_head=""

  status=0
  _externals_run_with_timeout "$timeout_seconds" \
    git -C "$skill_dir" fetch --quiet origin 2>/dev/null || status=$?
  if (( status != 0 )); then
    if (( status == 142 )); then
      externals_warn "timed out fetching updates for $slug"
      return 1
    fi
    # gh fallback: re-clone the cache dir (it's disposable)
    tmp_dir="$(mktemp -d)"
    if _externals_gh_clone "$url" "$tmp_dir"; then
      rm -rf "$skill_dir"
      mv "$tmp_dir" "$skill_dir"
      if [[ -n "$ref" ]]; then
        if ! git -C "$skill_dir" checkout --quiet "$ref" 2>/dev/null; then
          externals_warn "failed to checkout ref '$ref' for $slug"
          return 1
        fi
      fi
      printf '%s\n' "external: updated: $slug"
      return 0
    fi
    rm -rf "$tmp_dir"
    externals_warn "failed to fetch updates for $slug"
    return 1
  fi

  if [[ -n "$ref" ]]; then
    if git -C "$skill_dir" rev-parse --verify --quiet "refs/remotes/origin/$ref" >/dev/null; then
      if ! git -C "$skill_dir" merge --quiet --ff-only "origin/$ref" 2>/dev/null; then
        externals_warn "failed to fast-forward $slug (diverged?)"
        return 1
      fi
    else
      if ! git -C "$skill_dir" rev-parse --verify --quiet "refs/tags/$ref" >/dev/null; then
        if ! _externals_run_with_timeout "$timeout_seconds" \
          git -C "$skill_dir" fetch --quiet origin "refs/tags/$ref:refs/tags/$ref" 2>/dev/null; then
          externals_warn "failed to fetch tag '$ref' for $slug"
          return 1
        fi
      fi
      if ! git -C "$skill_dir" checkout --quiet "$ref" 2>/dev/null; then
        externals_warn "failed to checkout ref '$ref' for $slug"
        return 1
      fi
    fi
  else
    if ! git -C "$skill_dir" merge --quiet --ff-only "origin/HEAD" 2>/dev/null; then
      externals_warn "failed to fast-forward $slug (diverged?)"
      return 1
    fi
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
  local registry_file="$repo_root/ops/external-skills.json"  # mirrors layout_external_registry_file

  [[ -f "$registry_file" ]] || return 0
  _externals_registry_is_empty "$registry_file" && return 0

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

    if [[ "$seen_slugs" == *"|$slug|"* ]]; then
      i=$((i + 1))
      continue
    fi

    seen_slugs="$seen_slugs|$slug|"
    if [[ "$ref" == "latest-release" ]]; then
      if ! ref="$(_externals_resolve_latest_release_ref "$url")"; then
        externals_warn "failed to resolve latest release for $url — skipping"
        i=$((i + 1))
        continue
      fi
    fi

    _externals_fetch_one "$repo_root" "$slug" "$url" "$ref" || true

    i=$((i + 1))
  done
}

# Append copy actions for each fetched external skill.
# Discovers the skills base target from the shared-skills action in resolved actions.
externals_inject_actions() {
  local actions="$1"
  local repo_root="$2"
  local registry_file="$repo_root/ops/external-skills.json"  # mirrors layout_external_registry_file

  [[ -f "$registry_file" ]] || { printf '%s\n' "$actions"; return 0; }
  if _externals_registry_is_empty "$registry_file"; then
    printf '%s\n' "$actions"
    return 0
  fi

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
    if [[ ! -e "$repo_root/$rel_source" ]]; then
      externals_warn "missing fetched path for $name — skipping injection"
      continue
    fi
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
