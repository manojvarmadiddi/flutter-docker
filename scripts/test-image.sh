#!/usr/bin/env bash
# Usage: test-image.sh <image:tag> <variant> <expected-version>
set -euo pipefail
img="${1:?image}"; variant="${2:?variant}"; want="${3:?version}"
plat=(); [[ "$variant" == "android" || "$variant" == "full" ]] && plat=(--platform linux/amd64)

run() { docker run --rm "${plat[@]}" "$img" bash -lc "$1"; }

echo ">> version check"
run "flutter --version" | tee /dev/stderr | grep -q "Flutter $want" \
  || { echo "FAIL: expected Flutter $want" >&2; exit 1; }

echo ">> flutter doctor"
run "flutter doctor -v" || true

case "$variant" in
  web)     run "flutter create -t app --no-pub t && cd t && flutter build web" ;;
  android) run "flutter create -t app --no-pub t && cd t && flutter build apk --debug" ;;
  full)    run "flutter create -t app --no-pub t && cd t && flutter build apk --debug && flutter build web" ;;
  base)    run "flutter create -t app --no-pub t && cd t && flutter build linux" ;;
  *) echo "unknown variant $variant" >&2; exit 1 ;;
esac
echo ">> OK: $img ($variant)"
