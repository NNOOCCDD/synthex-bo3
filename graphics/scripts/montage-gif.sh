#!/usr/bin/env bash
# Gun features montage GIF (docs/montage.gif) from the Montage composition (public/m1..m5.mp4).
# Gameplay footage makes big GIFs: 640 px, 10 fps, 256 colours, then gifsicle --lossy (set GIFSICLE if not on PATH).
set -euo pipefail
cd "$(dirname "$0")/.."
GIFSICLE="${GIFSICLE:-gifsicle}"
TMP="$(mktemp -d)"
npx remotion render src/index.ts Montage "$TMP/m.mp4" --codec=h264 --crf=16
ffmpeg -v error -y -i "$TMP/m.mp4" -vf "fps=10,scale=640:-1:flags=lanczos,palettegen=max_colors=256:stats_mode=full" "$TMP/pal.png"
ffmpeg -v error -y -i "$TMP/m.mp4" -i "$TMP/pal.png" \
	-lavfi "fps=10,scale=640:-1:flags=lanczos [x]; [x][1:v] paletteuse=dither=bayer:bayer_scale=5:diff_mode=rectangle" -loop 0 "$TMP/m.gif"
"$GIFSICLE" -O3 --lossy=80 "$TMP/m.gif" -o ../docs/montage.gif
rm -rf "$TMP"
ls -la ../docs/montage.gif
