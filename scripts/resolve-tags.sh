#!/usr/bin/env bash
# Usage: resolve-tags.sh <version> [image]
# Prints one fully-qualified tag per line. Moving tags (minor, stable, latest)
# are emitted only when <version> is the newest in that line.
source "$(dirname "$0")/lib.sh"

version="${1:?version}"; image="${2:-${IMAGE:-flutter}}"
minor="${version%.*}"

echo "${image}:${version}"
if [[ "$(latest_patch_of_minor "$minor")" == "$version" ]]; then
  echo "${image}:${minor}"
fi
if [[ "$(latest_stable)" == "$version" ]]; then
  echo "${image}:stable"
  echo "${image}:latest"
fi
