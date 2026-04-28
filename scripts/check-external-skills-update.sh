#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# shellcheck source=./lib/layout-common.sh
source "$ROOT_DIR/scripts/lib/layout-common.sh"
# shellcheck source=./lib/external-common.sh
source "$ROOT_DIR/scripts/lib/external-common.sh"

fail() {
  echo "external-skills update check error: $*" >&2
  exit 1
}

require_command() {
  command -v "$1" >/dev/null 2>&1 || fail "missing required command: $1"
}

_remote_head_for_branch() {
  local url="$1" branch="$2"
  local timeout_seconds ref_pattern head
  timeout_seconds="$(externals_fetch_timeout_seconds)"
  ref_pattern="refs/heads/$branch"
  head="$(_externals_run_with_timeout "$timeout_seconds" \
    git ls-remote "$url" "$ref_pattern" 2>/dev/null | awk '{print $1}')" || return 1
  printf '%s\n' "$head"
}

_check_branch_ref() {
  local name="$1" url="$2" ref="$3"
  local slug cache_dir local_head remote_head
  slug="$(_externals_url_to_slug "$url")"
  cache_dir="$(layout_external_skill_dir "$ROOT_DIR" "$slug")"

  if [[ ! -d "$cache_dir/.git" ]]; then
    printf '%s\n' "$name: not fetched — run sync first"
    return
  fi

  local_head="$(git -C "$cache_dir" rev-parse HEAD 2>/dev/null)" || {
    printf '%s\n' "$name: could not read local HEAD"
    return
  }

  remote_head="$(_remote_head_for_branch "$url" "$ref")" || {
    printf '%s\n' "$name: could not reach remote"
    return
  }

  if [[ -z "$remote_head" ]]; then
    printf '%s\n' "$name: remote ref 'refs/heads/$ref' not found"
    return
  fi

  if [[ "$local_head" == "$remote_head" ]]; then
    printf '%s\n' "$name: up-to-date"
  else
    printf '%s\n' "$name: update available"
  fi
}

_check_latest_release() {
  local name="$1" url="$2"
  local slug cache_dir local_tag latest_tag
  slug="$(_externals_url_to_slug "$url")"
  cache_dir="$(layout_external_skill_dir "$ROOT_DIR" "$slug")"

  if [[ ! -d "$cache_dir/.git" ]]; then
    printf '%s\n' "$name: not fetched — run sync first"
    return
  fi

  local_tag="$(git -C "$cache_dir" describe --tags --exact-match HEAD 2>/dev/null || true)"
  if [[ -z "$local_tag" ]]; then
    local_tag="<untagged:$(git -C "$cache_dir" rev-parse --short HEAD 2>/dev/null)>"
  fi

  latest_tag="$(_externals_resolve_latest_release_ref "$url" 2>/dev/null)" || {
    printf '%s\n' "$name: could not resolve latest release"
    return
  }

  printf '%s\n' "$name local: $local_tag"
  printf '%s\n' "$name latest: $latest_tag"

  if [[ "$local_tag" == "$latest_tag" ]]; then
    printf '%s\n' "$name: up-to-date"
  else
    printf '%s\n' "$name: update available ($local_tag → $latest_tag)"
  fi
}

_check_pinned_tag() {
  local name="$1" url="$2" ref="$3"
  local slug cache_dir latest_tag
  slug="$(_externals_url_to_slug "$url")"
  cache_dir="$(layout_external_skill_dir "$ROOT_DIR" "$slug")"

  if [[ ! -d "$cache_dir/.git" ]]; then
    printf '%s\n' "$name: not fetched — run sync first"
    return
  fi

  printf '%s\n' "$name local: $ref (pinned)"

  # Only check for newer releases on GitHub URLs.
  latest_tag="$(_externals_resolve_latest_release_ref "$url" 2>/dev/null)" || {
    printf '%s\n' "$name: pinned to $ref"
    return
  }

  if [[ "$ref" == "$latest_tag" ]]; then
    printf '%s\n' "$name: up-to-date"
  else
    printf '%s\n' "$name latest: $latest_tag"
    printf '%s\n' "$name: update available ($ref → $latest_tag)"
  fi
}

_is_branch_ref() {
  local ref="$1"
  # Treat as a branch if no '/' and not a version-like string (v1.2.3 or 1.2.3).
  [[ "$ref" != "latest-release" ]] && \
  [[ ! "$ref" =~ ^v?[0-9]+\.[0-9]+ ]] && \
  [[ "$ref" != *"/"* ]]
}

check_one() {
  local name="$1" url="$2" ref="$3"

  if [[ -z "$ref" ]]; then
    _check_branch_ref "$name" "$url" "main"
    return
  fi

  case "$ref" in
    latest-release)
      _check_latest_release "$name" "$url"
      ;;
    *)
      if _is_branch_ref "$ref"; then
        _check_branch_ref "$name" "$url" "$ref"
      else
        _check_pinned_tag "$name" "$url" "$ref"
      fi
      ;;
  esac
}

main() {
  require_command jq
  require_command git

  local registry
  registry="$(layout_external_registry_file "$ROOT_DIR")"
  [[ -f "$registry" ]] || fail "registry not found: $registry"

  local count
  count="$(jq 'length' "$registry")"
  if (( count == 0 )); then
    printf '%s\n' "no external skills registered"
    return
  fi

  local i=0
  while (( i < count )); do
    local name url ref
    name="$(jq -r ".[$i].name" "$registry")"
    url="$(jq -r ".[$i].url" "$registry")"
    ref="$(jq -r ".[$i].ref // empty" "$registry")"
    i=$((i + 1))

    [[ -n "$name" && "$name" != "null" ]] || continue
    [[ -n "$url" && "$url" != "null" ]] || continue

    check_one "$name" "$url" "$ref"
  done
}

main "$@"
