#!/usr/bin/env bash
# Zip the built fastfiles as a drop-in release: dist/synthex-vip-<version>.zip containing mods/synthex/zone/*.ff
#   tools/package.sh 1.0.0
set -euo pipefail
REPO="$(cd "$(dirname "$0")/.." && pwd)"
VER="${1:?usage: tools/package.sh <version>}"
ZONE="$REPO/mod/synthex/zone"
for f in core_mod zm_mod mp_mod en_core_mod en_zm_mod en_mp_mod; do
	[ -f "$ZONE/$f.ff" ] || { echo "missing $ZONE/$f.ff - run tools/build.sh first" >&2; exit 1; }
done
STAGE="$(mktemp -d)"
mkdir -p "$STAGE/mods/synthex/zone"
cp "$ZONE"/*.ff "$STAGE/mods/synthex/zone/"
cp "$REPO/docs/INSTALL.txt" "$STAGE/INSTALL.txt"
mkdir -p "$REPO/dist"
OUTZIP="$REPO/dist/synthex-vip-$VER.zip"
rm -f "$OUTZIP"
( cd "$STAGE" && zip -qr "$OUTZIP" mods INSTALL.txt )
rm -rf "$STAGE"
echo "$OUTZIP"
