# SYNTHEX.VIP

An in-game mod menu for **Call of Duty: Black Ops III** — Zombies and Multiplayer custom games, offline or in
your own private matches. Mouse-driven, wide layout, dark charcoal + dusty pink.

![The menu in Zombies (Der Eisendrache)](docs/menu.jpg)

> **Offline / private only.** The menu turns itself off in public matchmaking and only the host gets it.
> BO3 mods can't be loaded in public matches anyway. Please don't use it to ruin other people's games.

## Install (players)
1. Download `synthex-vip-<version>.zip` from [Releases](../../releases).
2. Unzip it into your Black Ops III folder so you end up with
   `Call of Duty Black Ops III/mods/synthex/zone/*.ff` (six `.ff` files).
   (Steam → right-click Black Ops III → Manage → Browse local files.)
3. Steam → right-click Black Ops III → Properties → Launch Options, add:
   ```
   +set fs_game synthex
   ```
   (If you already have launch options, put it after them, separated by a space.)
4. Start the game and play **Zombies** (solo/offline or a private game) or **Multiplayer custom games**.
   Campaign isn't supported.

To play without the mod again, remove `+set fs_game synthex` from the launch options.

## Using it
| | |
|---|---|
| **Open** | hold **Aim** and press **Melee** |
| **Close** | **V** or **Backspace** (controller: B) — not Esc, Esc opens the game's pause menu |
| **Mouse** | click tabs, side tabs, toggles, buttons and the `‹ ›` arrows on sliders |
| **Keys** | Q / E tabs · A / D side tabs · W / S move · F select · Z / X or mouse wheel change a value |

Settings save to disk under **Player → Config** (`players/mods/synthex/synthex_config.txt`), with
**Auto-Load On Start** so your setup comes back every game. Zombies and Multiplayer are saved separately.

## Features
**Player** — God Mode, Demi-God, infinite ammo / equipment / hero weapon, max health and regen, points or score,
weapon tools (Pack-a-Punch, alt ammo, drop/take). **Movement**: speed, Super Jump, Infinite Jump, double jump
anywhere, No Clip fly. **Camera**: third person, FOV, hide HUD, photo mode. **Overlay**: a small stats box in any corner — pick the
stats, size and opacity. **Position**: save/load positions, quick teleports. **Config**: save/load settings.

**Weapons** — every weapon on the map by category, Pack-a-Punched versions, attachments (MP), current loadout.

**Zombies** (Zombies mode) — points, all perks, classic and mega Gobblegums, power-ups, rounds (skip, jump to,
freeze), map tools (open all doors, power on, Mystery Box / Pack-a-Punch), zombie spawning and speed, revive tools
(instant revive, infinite downs).

**ESP** (Zombies mode, AI zombies and map items only) — markers above zombie heads with distance and a health
bar; styles, sizes, colours per enemy type, through walls, edge arrows, max distance; Mystery Box, Pack-a-Punch,
perks, wall weapons, buildable parts and power-ups.

**Fun** — explosive bullets, magic bullets, **Rapid Fire** (5–40 shots/s, any gun, snipers too), No Recoil,
fast reload, Headshots Only and Every Shot Hits Head (Zombies), Forge mode, airstrike at the crosshair,
Force Push, Gun Game (MP: for you and the bots), random weapon each round, auto Pack-a-Punch, exploding zombies,
zombie launcher, aim assist on zombies, clones (MP).

**World** — slow motion and game speed, gravity, jump height, movement speed for everyone, screen filters
(frost, glitch, underwater, rain, EMP, …).

**Teleport** — map spots (Pack-a-Punch, box, perk machines, power), teleport gun, saved positions.

**Lobby** — players, match control, restart / end game (MP: add bots, freeze, bring or kick them), and a
built-in self-test that runs every option once.

<img src="docs/overlay.jpg" width="300" alt="Stats overlay">

## Building from source
The mod is made with Treyarch's official **Black Ops III Mod Tools**. The menu UI is Lua, which the stock
linker refuses to compile, so you also need **L3akMod** (D3V Team, tested with v1.0.4) installed into the Mod Tools.
Full steps for Windows and Linux (Wine) are in [docs/BUILDING.md](docs/BUILDING.md).

Notes for other modders (how the LUI menu talks to GSC, engine limits we hit, workarounds) are in
[docs/TECHNICAL.md](docs/TECHNICAL.md).

## Troubleshooting
- **"menu disabled in this session"** — you're in an online public lobby, or you aren't the host.
- **Game closes on start (Linux/Proton)** — T7Patch (`WINEDLLOVERRIDES="dsound=n,b"`) crashed the September
  2026 BO3 build for us; try launching without it.
- **Nothing opens** — check the launch option is exactly `+set fs_game synthex` and the six `.ff` files are in
  `mods/synthex/zone/`.

## Credits
- Built with the Call of Duty: Black Ops III Mod Tools (Treyarch / Activision). Two stock scripts
  (`_clientids.gsc`, `music_shared.csc`) are included with one added line each to load the menu.
- Lua compiling via L3akMod (D3V Team) — not included, download it yourself.
- Made by imzleepink, written with the help of Claude (Anthropic's AI) as a coding assistant.

Not affiliated with or endorsed by Activision or Treyarch. No game files are included.

## License
MIT — see [LICENSE](LICENSE). Applies to the SYNTHEX.VIP code and art in this repository, not to the stock
Treyarch scripts it modifies.
