#!/usr/bin/env bash
# Shared helpers. Source this file; do not execute it.
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
RELEASES_URL="${RELEASES_URL:-https://storage.googleapis.com/flutter_infra_release/releases/releases_linux.json}"
_RELEASES_CACHE=""

# Prints the releases JSON (cached per process; RELEASES_FILE overrides for tests).
releases() {
  if [[ -z "$_RELEASES_CACHE" ]]; then
    if [[ -n "${RELEASES_FILE:-}" ]]; then
      _RELEASES_CACHE="$(cat "$RELEASES_FILE")"
    else
      _RELEASES_CACHE="$(curl -fsSL --retry 3 "$RELEASES_URL")"
    fi
  fi
  printf '%s' "$_RELEASES_CACHE"
}

# Newest stable version, e.g. 3.24.5
latest_stable() {
  releases | jq -r '. as $r | [$r.releases[] | select(.channel=="stable" and .hash==$r.current_release.stable)][0].version | ltrimstr("v")'
}

# All stable versions, sorted ascending (one per line).
stable_versions() {
  releases | jq -r '.releases[] | select(.channel=="stable") | .version | ltrimstr("v")' | sort -uV
}

# Resolve "stable" or an explicit version to a concrete, validated version.
resolve_version() {
  local v="${1#v}"
  if [[ "$v" == "stable" ]]; then
    latest_stable
    return
  fi
  if ! stable_versions | grep -qx "$v"; then
    echo "error: '$v' is not a known stable Flutter release" >&2
    return 1
  fi
  echo "$v"
}

# Newest patch release for a minor line (arg: 3.24 -> 3.24.5)
latest_patch_of_minor() {
  stable_versions | grep -E "^${1//./\\.}\.[0-9]+$" | tail -1
}

# Android platform/build-tools for a Flutter version -> "<platform> <build_tools>"
android_for_version() {
  local version="$1" best="" min platform tools
  while read -r min platform tools; do
    if [[ "$(printf '%s\n%s\n' "$min" "$version" | sort -V | head -1)" == "$min" ]]; then
      best="$platform $tools"
    fi
  done < <(jq -r '.[] | "\(.min_flutter) \(.platform) \(.build_tools)"' "$ROOT_DIR/config/android.json")
  [[ -n "$best" ]] || { echo "error: no android mapping for $version" >&2; return 1; }
  echo "$best"
}
