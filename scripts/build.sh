#!/usr/bin/env bash
# Build Flutter images.
#   ./scripts/build.sh --version stable|3.24.5 [--variant base,web,android]
#                      [--image ghcr.io/owner/flutter] [--push] [--platform P] [--dry-run]
source "$(dirname "$0")/lib.sh"

version="stable"; variants=""; push=false; dry=false; platform=""; extra_tags=()
IMAGE="${IMAGE:-flutter}"
usage() { sed -n '2,5p' "$0"; exit "${1:-0}"; }

while [[ $# -gt 0 ]]; do
  case "$1" in
    --version)   version="$2"; shift 2 ;;
    --variant)   variants="$2"; shift 2 ;;
    --image)     IMAGE="$2"; shift 2 ;;
    --platform)  platform="$2"; shift 2 ;;
    --extra-tag) extra_tags+=("$2"); shift 2 ;;
    --push)      push=true; shift ;;
    --dry-run)   dry=true; shift ;;
    -h|--help)   usage ;;
    *) echo "unknown option: $1" >&2; usage 1 ;;
  esac
done
export IMAGE

[[ -n "$variants" ]] || variants="$(jq -r '.variants | join(",")' "$ROOT_DIR/config/policy.json")"
version="$(resolve_version "$version")"
echo ">> Flutter $version  variants=$variants  image=$IMAGE  push=$push"

for variant in ${variants//,/ }; do
  args=(--target "$variant" --build-arg "FLUTTER_VERSION=$version")
  if [[ "$variant" == "android" || "$variant" == "full" ]]; then
    read -r plat tools < <(android_for_version "$version")
    args+=(--build-arg "ANDROID_PLATFORM=$plat" --build-arg "ANDROID_BUILD_TOOLS=$tools")
  fi

  while read -r tag; do args+=(-t "$tag"); done < <("$ROOT_DIR/scripts/resolve-tags.sh" "$version" "$variant" "$IMAGE")
  for t in "${extra_tags[@]:-}"; do [[ -n "$t" ]] && args+=(-t "$t"); done

  if $push; then
    p="${platform:-$(jq -r --arg v "$variant" '.platforms[$v]' "$ROOT_DIR/config/policy.json")}"
    args+=(--platform "$p" --push)
  else
    # --load cannot hold multi-arch; android is amd64-only
    [[ -n "$platform" ]] && args+=(--platform "$platform")
    [[ ( "$variant" == "android" || "$variant" == "full" ) && -z "$platform" ]] && args+=(--platform linux/amd64)
    args+=(--load)
  fi

  cmd=(docker buildx build "${args[@]}" "$ROOT_DIR")
  echo ">> [$variant] ${cmd[*]}"
  $dry || "${cmd[@]}"
done
