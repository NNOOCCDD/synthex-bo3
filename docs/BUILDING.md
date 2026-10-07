# Building SYNTHEX.VIP

You need:
- **Call of Duty: Black Ops III** and **Call of Duty: Black Ops III - Mod Tools** (free, Steam → Library → Tools).
- **L3akMod** (D3V Team; tested with v1.0.4). The stock linker prints "Lua not supported" and skips the menu's
  `.lua` files; L3akMod's `libtiff64r.dll` adds Lua compiling. Get it from its authors; it isn't included here.
  Keep a copy of the original `libtiff64r.dll` so you can put it back.

Layout of this repo:
```
mod/synthex/
  scripts/            GSC (server) + CSC (client) scripts; *_clientids.gsc and music_shared.csc are stock
                      files with one #using added, which pulls the menu into the game
  ui/synthex/         the LUI menu (Lua): spec (pages), menu renderer, stats overlay, saved config
  gdts/ images/       ESP marker textures
  zone_source/        core_mod / zm_mod / mp_mod zone files (what goes into each fastfile)
tools/build.sh        Linux build (Wine), tools/package.sh makes the release zip
```

## Windows
1. Install L3akMod into the Mod Tools `bin` folder (replacing `libtiff64r.dll`).
2. Copy `mod/synthex` to `Call of Duty Black Ops III/mods/synthex`.
3. Open the Mod Tools Launcher, select the `synthex` mod and link `core_mod`, `zm_mod` and `mp_mod`
   (or from a Mod Tools command prompt: `linker_modtools.exe -language english -fs_game synthex -modsource zm_mod`,
   once per zone).
4. The fastfiles land in `mods/synthex/zone/`. Launch the game with `+set fs_game synthex`.

## Linux (Wine)
`tools/build.sh` runs the Windows linker under Wine (tested with Wine 10) and copies the result into the game.

One-time setup:
1. **Tools root.** Point `TOOLS` at your Mod Tools folder (default: `<steamapps/common>/Call of Duty Black Ops III 455130`).
   We use a separate copy (`.toolsroot/`) so L3akMod and the extra DLLs never touch the Steam install:
   copy the Mod Tools there and symlink the game's `zone/` folder into it (`.toolsroot/zone -> <BO3>/zone`).
   The script symlinks `mods/synthex` in the tools root to this repo by itself.
2. **Wine prefix.** The script uses `.wineprefix/` in the repo. `gdtdb.exe` is .NET: install Wine Mono
   (9.4.0 tested, the `.msi` from dl.winehq.org) with `WINEPREFIX=$PWD/.wineprefix wine msiexec /i wine-mono-9.4.0-x86.msi`.
3. **VC++ 2012 runtime.** Wine's own `msvcr110` stubs `Concurrency::_TaskCollection`, which the linker uses for the
   localized fastfiles. Put Microsoft's x64 `msvcr110.dll` and `msvcp110.dll` (from the VC++ 2012 x64 redistributable)
   into `<TOOLS>/bin`. The script already sets `WINEDLLOVERRIDES=msvcr110,msvcp110=n,b`.
4. **L3akMod** into `<TOOLS>/bin` as above.

Then:
```bash
TOOLS="$PWD/.toolsroot" tools/build.sh             # build core_mod, zm_mod, mp_mod and copy into the game
TOOLS="$PWD/.toolsroot" tools/build.sh zm_mod      # just one zone
DEPLOY=0 TOOLS="$PWD/.toolsroot" tools/build.sh    # build only
tools/package.sh 1.0.0                              # dist/synthex-vip-1.0.0.zip
```
`STEAM` / `GAME` can be set too if your library isn't in a standard place (native and Flatpak Steam are detected).
The linker log is `tools/last_build.log`.

## Linker gotchas
- One zone per linker call (`-modsource` takes a single zone).
- The linker opens `gdtDB\gdt.db`; on a case-sensitive filesystem symlink `gdtDB -> gdtdb` (the script does).
- 2D materials: `materialType` must be `2d_blend` (not `2d`), `surfaceType` must be set, and source images
  must be RGBA TIFFs (greyscale TIFFs fail with "format not supported").
- L3akMod's Lua compiler only accepts globals it knows. `io`, `os`, `package`, `_G`, `rawget`, `getfenv`
  fail with the unhelpful `attempt to index global 'ERR' (a nil value)`; bisect the file to find the line.
