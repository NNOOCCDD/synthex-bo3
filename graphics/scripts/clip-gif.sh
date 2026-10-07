#!/usr/bin/env bash
# README banner: render the BannerClip composition to MP4, then make a palette-optimised GIF (much smaller than
# Remotion's own GIF output for footage) plus the still PNG used as the GitHub social preview.
#   graphics/scripts/clip-gif.sh        (Node 22: . ~/.nvm/nvm.sh first)
set -euo pipefail
cd "$(dirname "$0")/.."
TMP="$(mktemp -d)"
npx remotion render src/index.ts BannerClip "$TMP/clip.mp4" --codec=h264 --crf=16
npx remotion still src/index.ts BannerClip ../docs/banner.png --frame=75
ffmpeg -v error -y -i "$TMP/clip.mp4" -vf "fps=15,scale=880:-1:flags=lanczos,palettegen=max_colors=256:stats_mode=full" "$TMP/pal.png"
ffmpeg -v error -y -i "$TMP/clip.mp4" -i "$TMP/pal.png" \
	-lavfi "fps=15,scale=880:-1:flags=lanczos [x]; [x][1:v] paletteuse=dither=bayer:bayer_scale=3:diff_mode=rectangle" -loop 0 ../docs/banner.gif
rm -rf "$TMP"
ls -la ../docs/banner.gif ../docs/banner.png
