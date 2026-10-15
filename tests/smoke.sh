#!/usr/bin/env bash
# Usage: tests/smoke.sh <image> <goose version, e.g. v3.29.0>
set -euo pipefail

img=$1
want=$2
run() { docker run --rm --entrypoint "$1" "${@:2}"; }

got=$(run goose "$img" --version)
[[ "$got" == *"$want"* ]] || { echo "goose version: got '$got', want '$want'"; exit 1; }
echo "ok goose $want"

run bash "$img" -c 'true'
echo "ok bash present"

cwd=$(run pwd "$img")
[[ "$cwd" == /migrations ]] || { echo "workdir: got '$cwd'"; exit 1; }
echo "ok workdir /migrations"

run goose --user 1000:1000 "$img" --version >/dev/null
echo "ok runs as uid 1000"

# the default ENTRYPOINT must run a mounted entrypoint from /migrations even
# when the repo committed it without the exec bit
tmp=$(mktemp -d)
printf '#!/bin/bash\nset -eu\necho "cwd=$PWD"\n' > "$tmp/entrypoint.sh"
chmod 644 "$tmp/entrypoint.sh"
out=$(docker run --rm -v "$tmp:/migrations:ro" "$img")
rm -rf "$tmp"
[[ "$out" == "cwd=/migrations" ]] || { echo "entrypoint: got '$out'"; exit 1; }
echo "ok entrypoint wiring"
