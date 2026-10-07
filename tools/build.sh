#!/usr/bin/env bash
# Build the SYNTHEX.VIP mod with the BO3 Mod Tools linker under Wine (Linux), then deploy it to the game's
# mods folder. See docs/BUILDING.md for the one-time setup (Mod Tools, Wine Mono, MS VC++ 2012 DLLs, L3akMod).
#
#   tools/build.sh            build core_mod zm_mod mp_mod and deploy
#   tools/build.sh zm_mod     build only the listed zones
#   DEPLOY=0 tools/build.sh   build without copying into the game
#
# Linker log: tools/last_build.log
set -euo pipefail

REPO="$(cd "$(dirname "$0")/.." && pwd)"
# Steam library: native Steam first, then Flatpak Steam. Override any of these with environment variables:
#   STEAM=<steamapps/common>  GAME=<Black Ops III folder>  TOOLS=<Mod Tools folder, e.g. a staged .toolsroot>
if [ -z "${STEAM:-}" ]; then
	for c in "$HOME/.steam/steam/steamapps/common" "$HOME/.local/share/Steam/steamapps/common" \
		"$HOME/.var/app/com.valvesoftware.Steam/.local/share/Steam/steamapps/common"; do
		[ -d "$c/Call of Duty Black Ops III" ] && { STEAM="$c"; break; }
	done
fi
STEAM="${STEAM:-$HOME/.steam/steam/steamapps/common}"
GAME="${GAME:-$STEAM/Call of Duty Black Ops III}"
TOOLS="${TOOLS:-$STEAM/Call of Duty Black Ops III 455130}"
MOD=synthex
ZONES=("${@:-core_mod zm_mod mp_mod}")
ZONES=(${ZONES[@]})

export WINEPREFIX="$REPO/.wineprefix"
export WINEDEBUG=-all
# Wine's builtin msvcr110 stubs Concurrency::_TaskCollection (used by the localized link); use the MS DLLs placed in bin/.
export WINEDLLOVERRIDES="msvcr110,msvcp110=n,b"

[ -f "$TOOLS/bin/linker_modtools.exe" ] || { echo "Mod Tools not installed at: $TOOLS" >&2; exit 1; }

# The linker doesn't notice a missing local function (&fn); the game then refuses to load the mod.
python3 "$REPO/tools/check_refs.py" || { echo "Fix the missing functions above before building." >&2; exit 1; }
# Menu layout vs script buttons/options (needs a Python with lupa: set LAYOUT_PY, or pip install lupa)
LAYOUT_PY="${LAYOUT_PY:-python3}"
if "$LAYOUT_PY" -c "import lupa" 2>/dev/null; then
	"$LAYOUT_PY" "$REPO/tools/check_layout.py" || { echo "Fix the menu layout problems above before building." >&2; exit 1; }
else
	echo "(layout check skipped: no lupa - pip install lupa, or set LAYOUT_PY)"
fi

# The linker reads mods/<MOD>/ under the tools root; point it at the repo copy.
mkdir -p "$TOOLS/mods"
if [ ! -L "$TOOLS/mods/$MOD" ]; then
	rm -rf "$TOOLS/mods/$MOD"
	ln -s "$REPO/mod/$MOD" "$TOOLS/mods/$MOD"
fi

# Windows-style paths for the Mod Tools environment (the launcher normally sets these).
WIN_TOOLS="Z:$(echo "$TOOLS" | sed 's|/|\\|g')\\"
export TA_TOOLS_PATH="$WIN_TOOLS"
export TA_GAME_PATH="$WIN_TOOLS"
export TA_LOCAL_ASSET_CACHE="${WIN_TOOLS}share\\assetconvert"

# Asset database (GDTs -> gdtdb/gdt.db). The linker looks for "gdtDB" - case matters on Linux.
[ -e "$TOOLS/gdtDB" ] || ln -s gdtdb "$TOOLS/gdtDB"
( cd "$TOOLS/gdtdb" && wine gdtdb.exe /update 2>&1 | grep -E 'gdtDB:' || true )

cd "$TOOLS/bin"
: > "$REPO/tools/last_build.log"
for z in "${ZONES[@]}"; do
	echo "Linking $z ..."
	echo "===== $z" >> "$REPO/tools/last_build.log"
	set +e
	wine linker_modtools.exe -language english -fs_game "$MOD" -modsource "$z" >> "$REPO/tools/last_build.log" 2>&1
	rc=$?
	set -e
	if [ $rc -ne 0 ] || sed -n "/===== $z/,\$p" "$REPO/tools/last_build.log" | grep -qE '^ERROR|^Error|error:'; then
		sed -n "/===== $z/,\$p" "$REPO/tools/last_build.log" | grep -vE 'wine32|multiarch|dpkg|apt-get' | tail -n 30
		echo "BUILD FAILED on $z (exit $rc) - see tools/last_build.log" >&2
		exit 1
	fi
done

# Deploy: copy the built fastfiles into the game's own mods folder.
OUT="$REPO/mod/$MOD/zone"
[ "${DEPLOY:-1}" = "1" ] || { echo "Built to $OUT"; exit 0; }
mkdir -p "$GAME/mods/$MOD/zone"
cp -v "$OUT"/* "$GAME/mods/$MOD/zone/"
echo "Deployed to $GAME/mods/$MOD/zone"
