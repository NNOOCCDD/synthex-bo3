# How it works (notes for modders)

## Load chain
Mod scripts only run if something in the stock load chain `#using`s them. `scripts/{zm,mp}/gametypes/_clientids.gsc`
(server) and `scripts/shared/music_shared.csc` (client) are stock copies with one extra `#using` line each.
The server side is `offmenu_zm.gsc` / `offmenu_mp.gsc` on top of the shared `scripts/shared/offmenu/*`;
the client side `synthex_ui.csc` calls `LuiLoad` for the Lua menu and overlay and draws screen filters.

## Why a Lua (LUI) menu
The first version was drawn with script HUD elements. A client only draws about 22 regular + 26 archived script
HUD elements (measured in game), and font scales below 1.0 render huge, so a full menu doesn't fit. The menu is
now a LUI menu (`OpenLUIMenu( "SynthexMenu" )`), which also gives mouse support (`setHandleMouse`,
`leftmouseup`, `mouseenter`). LUI gives a click to the first element hit, so click zones must never overlap.

## Menu <-> script protocol
Lua → GSC with `Engine.SendMenuResponse( controller, "SynthexMenu", msg )`, received by `waittill( "menuresponse" )`:

| message | meaning |
|---|---|
| `t\|key\|0/1` | toggle |
| `v\|key\|index` | slider / choice |
| `b\|tab\|side\|label` | button |
| `i\|group\|id` | list item (weapon, perk, player, …) |
| `p\|tab\|side` | page opened (script sends that page's data) |
| `cfgdone\|n` | saved config applied |
| `close` | menu closed |

A response is cut at the first space (it travels like a console command), so spaces are sent as `_`.

GSC → Lua with `LUINotifyEvent( &"sx_stats" | &"sx_list" | &"sx_cfg" | &"sx_flash", n, ... )`, read in Lua from
the `PerController.scriptNotify` model with `CoD.GetScriptNotifyData`. `LUINotifyEvent` takes at most 5 values,
so stats go out as an offset plus 4 values per event. Event strings must be `#precache( "eventstring", ... )`'d.

Page definitions exist twice — `ui/synthex/synthex_spec.lua` (what's drawn) and the GSC builders (what each key
does) — and must use the same keys.

## Saved config
L3akMod's compiler rejects `io` by name, but at runtime the library is still reachable through
`debug.getregistry()._LOADED.io`. `synthex_config.lua` writes `players/mods/synthex/synthex_config.txt`
(one line per mode, only values that differ from the defaults). On spawn the script sends `sx_cfg`; a Lua
listener on the UI root answers with paced `t|`/`v|` messages while the menu is closed, then `cfgdone`.

## Things that bit us
- GSC: no `?:` operator; functions error on extra arguments; `PrintLn` is dev-only (link error in a ship build);
  `IsTestClient` is a method; `foreach` over `level.zombie_weapons` fails ("not an array key") — use `GetArrayKeys`.
- Cheat-protected dvars (`cg_thirdPersonAngle`, …) can't be set; FOV is set client-side from Lua (`cg_fov_default`).
- `SetDvar( "jump_height" )` does nothing — use the builtin `SetJumpHeight()`.
- Jumps: the server sees buttons every 50 ms, by which time a jump has already left the ground; detect the
  press edge and use the previous frame's ground state. Launch with `SetOrigin( +1 z )` then `SetVelocity` for a few frames.
- Waypoints: `SetWaypoint( true )` (constant size) ignores the `SetShader` size. With `SetWaypoint( false )`
  the size is in world units, so ESP rescales by distance. `SetShader` after `SetWaypoint` turns the element back
  into a plain screen icon — redo `SetWaypoint` + `SetTargetEnt` after every resize.
- Zombies damage hooks: `zm::register_actor_damage_callback` (return -1 to leave damage alone) for Headshots Only;
  redirect body hits with `DoDamage( dmg, pos, attacker, inflictor, "head", mod, flags, weapon )`.
- There's no fire-rate or recoil scale for players in script: Rapid Fire uses `MagicBullet` with the held
  weapon, No Recoil undoes upward view kick each frame while firing.
- `GiveAchievement` is ignored while a mod is loaded.
