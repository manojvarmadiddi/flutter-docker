#!/usr/bin/env bash
# Build the Flutter image (Android + web) for one version.
#   ./scripts/build.sh --version stable|3.24.5 [--image ghcr.io/owner/flutter]
#                      [--push] [--platform P] [--extra-tag T] [--dry-run]
source "$(dirname "$0")/lib.sh"

version="stable"; push=false; dry=false; platform=""; extra_tags=()
IMAGE="${IMAGE:-flutter}"
usage() { sed -n '2,5p' "$0"; exit "${1:-0}"; }

while [[ $# -gt 0 ]]; do
  case "$1" in
    --version)   version="$2"; shift 2 ;;
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

version="$(resolve_version "$version")"
read -r plat tools < <(android_for_version "$version")
echo ">> Flutter $version  image=$IMAGE  push=$push"

args=(--target full --build-arg "FLUTTER_VERSION=$version"
      --build-arg "ANDROID_PLATFORM=$plat" --build-arg "ANDROID_BUILD_TOOLS=$tools")
while read -r tag; do args+=(-t "$tag"); done < <("$ROOT_DIR/scripts/resolve-tags.sh" "$version" "$IMAGE")
for t in "${extra_tags[@]:-}"; do [[ -n "$t" ]] && args+=(-t "$t"); done

p="${platform:-$(jq -r .platform "$ROOT_DIR/config/policy.json")}"
args+=(--platform "$p")
if $push; then args+=(--push); else args+=(--load); fi

cmd=(docker buildx build "${args[@]}" "$ROOT_DIR")
echo ">> ${cmd[*]}"
$dry || "${cmd[@]}"
