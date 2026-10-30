#!/usr/bin/env bash
# Usage: test-image.sh <image:tag> <expected-version> [platform]
set -euo pipefail
img="${1:?image}"; want="${2:?version}"; plat=(); [[ -n "${3:-}" ]] && plat=(--platform "$3")

run() { docker run --rm "${plat[@]}" "$img" bash -c "$1"; }

echo ">> version check"
run "flutter --version" | tee /dev/stderr | grep -q "Flutter $want" \
  || { echo "FAIL: expected Flutter $want" >&2; exit 1; }

echo ">> flutter doctor"
run "flutter doctor -v" || true

echo ">> build apk + web"
run "flutter create -t app --no-pub t && cd t && flutter build apk --debug && flutter build web"
echo ">> OK: $img"
