#!/usr/bin/env bash
# Usage: resolve-tags.sh <version> <variant> [image]
# Prints one fully-qualified tag per line. Moving tags (minor, stable, latest)
# are emitted only when <version> is the newest in that line.
source "$(dirname "$0")/lib.sh"

version="${1:?version}"; variant="${2:?variant (base|web|android)}"; image="${3:-${IMAGE:-flutter}}"
suffix=""; [[ "$variant" != "base" ]] && suffix="-$variant"
minor="${version%.*}"

emit() { echo "${image}:$1${suffix}"; }

emit "$version"
if [[ "$(latest_patch_of_minor "$minor")" == "$version" ]]; then
  emit "$minor"
fi
if [[ "$(latest_stable)" == "$version" ]]; then
  emit "stable"
  if [[ "$variant" == "base" ]]; then echo "${image}:latest"; else echo "${image}:${variant}"; fi
fi
