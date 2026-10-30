#!/usr/bin/env bash
# Usage: detect-versions.sh [--missing <image>]
# Prints a JSON array of stable versions in policy (major >= min_major and
# released within months_back). With --missing, drops versions whose
# <image>:<version> tag (base variant) already exists in the registry.
source "$(dirname "$0")/lib.sh"

policy="$ROOT_DIR/config/policy.json"
min_major="$(jq -r .min_major "$policy")"
months="$(jq -r .months_back "$policy")"
cutoff="$(date -u -d "-${months} months" +%F 2>/dev/null || date -u -v-"${months}"m +%F)"

versions="$(releases | jq -c --arg cutoff "$cutoff" --argjson major "$min_major" '
  [ .releases[]
    | select(.channel=="stable" and (.release_date[0:10] >= $cutoff))
    | .version |= ltrimstr("v")
    | select((.version | split(".")[0] | tonumber) >= $major)
    | .version ] | unique')"
# Keep semantic ordering
versions="$(jq -r '.[]' <<<"$versions" | sort -V | jq -R . | jq -sc .)"

if [[ "${1:-}" == "--missing" ]]; then
  image="${2:?image}"
  out=()
  for v in $(jq -r '.[]' <<<"$versions"); do
    docker buildx imagetools inspect "${image}:${v}" >/dev/null 2>&1 || out+=("$v")
  done
  printf '%s\n' "${out[@]:-}" | grep -v '^$' | jq -R . | jq -sc .
else
  echo "$versions"
fi
