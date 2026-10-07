-- SYNTHEX.VIP - page definitions (mirrors the GSC option registry: same keys, labels, value lists, defaults).
-- Row kinds: toggle, slider, choice, button, item, stat, note. Dynamic pages build rows from data sent by script.

CoD.SynthexSpec = {}
local Spec = CoD.SynthexSpec

local function T( label, key, hint ) return { k = "toggle", label = label, key = key, hint = hint } end
local function S( label, key, labels, def ) return { k = "slider", label = label, key = key, labels = labels, def = def } end
local function CH( label, key, labels, def ) return { k = "choice", label = label, key = key, labels = labels, def = def } end
local function B( label, danger ) return { k = "button", label = label, danger = danger } end
local function I( label, group, id ) return { k = "item", label = label, group = group, id = id } end
local function ST( label, stat ) return { k = "stat", label = label, stat = stat } end
local function N( text ) return { k = "note", label = text } end
local function LT( label, key, hint ) return { k = "toggle", label = label, key = key, hint = hint, lua = true } end
local function LB( label, danger ) return { k = "button", label = label, danger = danger, lua = true } end
local function C( col, title, rows ) return { col = col, title = title, rows = rows } end
Spec.T, Spec.S, Spec.CH, Spec.B, Spec.I, Spec.ST, Spec.N, Spec.C = T, S, CH, B, I, ST, N, C

-- Toggles that start ON (must match the GSC defaults).
Spec.DefaultOn = {
	cfg_auto = true, ov_logo = true, ov_tags = true, ov_flash = true, ov_hidemenu = true,
	esp_walls = true, esp_reg = true, esp_crawl = true, esp_spec = true, esp_boss = true, esp_redclose = true,
	esp_l_dist = true, esp_edge = true, esp_pulse = true, esp_i_box = true, esp_i_pap = true, esp_i_parts = true, esp_i_pow = true,
	w_replace = true, w_switch = true,
	ov_s_round = true, ov_s_left = true, ov_s_points = true, ov_s_kills = true, ov_s_gtime = true,
	ov_s_score = true, ov_s_time = true, ov_s_deaths = true, ov_s_spec = true
}

-- Ordered lists shared with GSC (index = position, 0-based on the wire).
Spec.ZMWeapons = {
	{ "ar_standard", "KN-44", "ar" }, { "ar_accurate", "ICR-1", "ar" }, { "ar_cqb", "HVK-30", "ar" }, { "ar_damage", "Man-O-War", "ar" },
	{ "ar_marksman", "Sheiva", "ar" }, { "ar_longburst", "M8A7", "ar" }, { "ar_fastburst", "XR-2", "ar" }, { "ar_peacekeeper", "Peacekeeper MK2", "ar" },
	{ "ar_famas", "FFAR", "ar" }, { "ar_garand", "MX Garand", "ar" }, { "ar_m14", "M14", "ar" }, { "ar_m16", "M16", "ar" }, { "ar_galil", "Galil", "ar" }, { "ar_an94", "AN-94", "ar" },
	{ "smg_standard", "Kuda", "smg" }, { "smg_versatile", "VMP", "smg" }, { "smg_fastfire", "Vesper", "smg" }, { "smg_burst", "Pharo", "smg" },
	{ "smg_capacity", "Razorback", "smg" }, { "smg_longrange", "Weevil", "smg" }, { "smg_mp40", "MP40", "smg" }, { "smg_ppsh", "PPSh-41", "smg" },
	{ "smg_thompson", "M1927", "smg" }, { "smg_ak74u", "AK-74u", "smg" }, { "smg_sten", "Sten", "smg" },
	{ "shotgun_pump", "KRM-262", "shotgun" }, { "shotgun_semiauto", "205 Brecci", "shotgun" }, { "shotgun_fullauto", "Haymaker 12", "shotgun" },
	{ "shotgun_precision", "Argus", "shotgun" }, { "shotgun_energy", "Banshii", "shotgun" },
	{ "lmg_light", "BRM", "lmg" }, { "lmg_cqb", "Dingo", "lmg" }, { "lmg_slowfire", "Gorgon", "lmg" }, { "lmg_heavy", "48 Dredge", "lmg" }, { "lmg_rpk", "RPK", "lmg" },
	{ "sniper_fastbolt", "Locus", "sniper" }, { "sniper_fastsemi", "Drakon", "sniper" }, { "sniper_powerbolt", "SVG-100", "sniper" },
	{ "pistol_standard", "MR6", "pistol" }, { "pistol_burst", "RK5", "pistol" }, { "pistol_fullauto", "L-CAR 9", "pistol" },
	{ "pistol_shotgun", "Marshal 16", "pistol" }, { "pistol_revolver38", "Bloodhound", "pistol" }, { "pistol_energy", "Rift E9", "pistol" }, { "pistol_m1911", "1911", "pistol" },
	{ "launcher_standard", "XM-53", "launcher" }, { "launcher_multi", "L4 Siege", "launcher" },
	{ "ray_gun", "Ray Gun", "wonder" }, { "raygun_mark2", "Ray Gun Mark II", "wonder" }, { "raygun_mark3", "GKZ-45 Mk3", "wonder" },
	{ "tesla_gun", "Wunderwaffe DG-2", "wonder" }, { "thundergun", "Thundergun", "wonder" }, { "octobomb", "Li'l Arnie", "wonder" },
	{ "idgun_0", "Apothicon Servant", "wonder" }
}

Spec.MPWeapons = {
	{ "ar_standard", "KN-44", "ar" }, { "ar_accurate", "ICR-1", "ar" }, { "ar_cqb", "HVK-30", "ar" }, { "ar_damage", "Man-O-War", "ar" },
	{ "ar_marksman", "Sheiva", "ar" }, { "ar_longburst", "M8A7", "ar" }, { "ar_fastburst", "XR-2", "ar" }, { "ar_peacekeeper", "Peacekeeper MK2", "ar" },
	{ "ar_famas", "FFAR", "ar" }, { "ar_garand", "MX Garand", "ar" }, { "ar_an94", "AN-94", "ar" }, { "ar_galil", "Galil", "ar" }, { "ar_m14", "M14", "ar" }, { "ar_m16", "M16", "ar" },
	{ "smg_standard", "Kuda", "smg" }, { "smg_versatile", "VMP", "smg" }, { "smg_fastfire", "Vesper", "smg" }, { "smg_burst", "Pharo", "smg" },
	{ "smg_capacity", "Razorback", "smg" }, { "smg_longrange", "Weevil", "smg" }, { "smg_mp40", "HG 40", "smg" }, { "smg_ppsh", "PPSh-41", "smg" },
	{ "smg_ak74u", "AK-74u", "smg" }, { "smg_msmc", "HLX 4", "smg" }, { "smg_sten2", "Sten", "smg" },
	{ "shotgun_pump", "KRM-262", "shotgun" }, { "shotgun_semiauto", "205 Brecci", "shotgun" }, { "shotgun_fullauto", "Haymaker 12", "shotgun" },
	{ "shotgun_precision", "Argus", "shotgun" }, { "shotgun_energy", "Banshii", "shotgun" }, { "shotgun_olympia", "Olympia", "shotgun" },
	{ "lmg_light", "BRM", "lmg" }, { "lmg_cqb", "Dingo", "lmg" }, { "lmg_slowfire", "Gorgon", "lmg" }, { "lmg_heavy", "48 Dredge", "lmg" }, { "lmg_rpk", "RPK", "lmg" }, { "lmg_infinite", "R70 Ajax", "lmg" },
	{ "sniper_fastbolt", "Locus", "sniper" }, { "sniper_fastsemi", "Drakon", "sniper" }, { "sniper_powerbolt", "SVG-100", "sniper" }, { "sniper_chargeshot", "P-06", "sniper" },
	{ "sniper_double", "Dbl Barrel", "sniper" }, { "sniper_quickscope", "DBSR-50", "sniper" }, { "sniper_mosin", "Mosin", "sniper" }, { "sniper_xpr50", "XPR-50", "sniper" },
	{ "pistol_standard", "MR6", "pistol" }, { "pistol_burst", "RK5", "pistol" }, { "pistol_fullauto", "L-CAR 9", "pistol" }, { "pistol_shotgun", "Marshal 16", "pistol" },
	{ "pistol_energy", "Rift E9", "pistol" }, { "pistol_m1911", "1911", "pistol" },
	{ "launcher_standard", "XM-53", "launcher" }, { "launcher_lockonly", "BlackCell", "launcher" }, { "launcher_multi", "L4 Siege", "launcher" }, { "launcher_ex41", "Ex-41", "launcher" },
	{ "hero_annihilator", "Annihilator", "hero" }, { "hero_gravityspikes", "Gravity Spikes", "hero" }, { "hero_chemicalgelgun", "H.I.V.E.", "hero" },
	{ "hero_flamethrower", "Purifier", "hero" }, { "hero_minigun", "Scythe", "hero" }, { "hero_bowlauncher", "Sparrow", "hero" },
	{ "hero_lightninggun", "Tempest", "hero" }, { "hero_armblade", "Ripper", "hero" }, { "hero_pineapplegun", "War Machine", "hero" }
}

Spec.Perks = {
	{ "specialty_armorvest", "Juggernog" }, { "specialty_quickrevive", "Quick Revive" }, { "specialty_fastreload", "Speed Cola" },
	{ "specialty_doubletap2", "Double Tap" }, { "specialty_staminup", "Stamin-Up" }, { "specialty_deadshot", "Deadshot Daiquiri" },
	{ "specialty_additionalprimaryweapon", "Mule Kick" }, { "specialty_widowswine", "Widow's Wine" }, { "specialty_electriccherry", "Electric Cherry" },
	{ "specialty_phdflopper", "PhD Flopper" }, { "specialty_tombstone", "Tombstone" }, { "specialty_whoswho", "Who's Who" }, { "specialty_vultureaid", "Vulture Aid" }
}

Spec.PowerUps = {
	{ "full_ammo", "Max Ammo" }, { "insta_kill", "Insta-Kill" }, { "double_points", "Double Points" }, { "nuke", "Nuke" },
	{ "carpenter", "Carpenter" }, { "fire_sale", "Fire Sale" }, { "minigun", "Death Machine" }, { "free_perk", "Free Perk" },
	{ "bonus_points_player", "Bonus Points" }, { "bonus_points_team", "Team Bonus" }, { "shield_charge", "Shield Charge" }, { "ww_grenade", "Widow's Grenade" }
}

Spec.Streaks = {
	{ "uav", "UAV" }, { "rcbomb", "RC-XD" }, { "counteruav", "Counter-UAV" }, { "dart", "Dart" }, { "supply_drop", "Care Package" },
	{ "remote_missile", "Hellstorm" }, { "planemortar", "Lightning Strike" }, { "satellite", "H.A.T.R." }, { "autoturret", "Sentry Gun" },
	{ "raps", "R.A.P.S." }, { "ai_tank_drop", "Talon" }, { "combat_robot", "G.I. Unit" }, { "sentinel", "Wraith" }, { "helicopter_comlink", "Power Core" },
	{ "microwave_turret", "Guardian" }, { "drone_strike", "Drone Strike" }, { "helicopter_gunner", "Mothership" }, { "emp", "EMP" }
}

Spec.ClassicGums = {
	"zm_bgb_always_done_swiftly", "zm_bgb_arms_grace", "zm_bgb_coagulant", "zm_bgb_in_plain_sight", "zm_bgb_stock_option",
	"zm_bgb_sword_flay", "zm_bgb_tone_death", "zm_bgb_alchemical_antithesis", "zm_bgb_anywhere_but_here",
	"zm_bgb_armamental_accomplishment", "zm_bgb_firing_on_all_cylinders"
}
Spec.MegaGums = {
	"zm_bgb_perkaholic", "zm_bgb_shopping_free", "zm_bgb_near_death_experience", "zm_bgb_reign_drops", "zm_bgb_round_robbin",
	"zm_bgb_unbearable", "zm_bgb_wall_power", "zm_bgb_crate_power", "zm_bgb_power_vacuum", "zm_bgb_secret_shopper", "zm_bgb_soda_fountain"
}

Spec.MapNames = {
	zm_zod = "Shadows of Evil", zm_factory = "The Giant", zm_castle = "Der Eisendrache", zm_island = "Zetsubou No Shima",
	zm_stalingrad = "Gorod Krovi", zm_genesis = "Revelations", zm_prototype = "Nacht der Untoten", zm_asylum = "Verruckt",
	zm_sumpf = "Shi No Numa", zm_theater = "Kino der Toten", zm_cosmodrome = "Ascension", zm_temple = "Shangri-La",
	zm_moon = "Moon", zm_tomb = "Origins"
}

function Spec.Pretty( name, prefix )
	if prefix and string.sub( name, 1, #prefix ) == prefix then
		name = string.sub( name, #prefix + 1 )
	end
	local out = ""
	for part in string.gmatch( name, "[^_]+" ) do
		if out ~= "" then out = out .. " " end
		out = out .. string.upper( string.sub( part, 1, 1 ) ) .. string.sub( part, 2 )
	end
	return out
end

-- Shared value lists
local Speed = { "1x", "1.25x", "1.5x", "2x", "3x" }
local Colors = { "Pink", "Gold", "Red", "White", "Green", "Cyan" }

-- ---------------------------------------------------------------------------
-- Shared pages
-- ---------------------------------------------------------------------------

local function MovementSide()
	return { id = "movement", label = "Movement", cards = {
		C( 0, "Speed", { S( "Movement Speed", "speed", Speed, 0 ), T( "Super Sprint", "supersprint" ), T( "Infinite Sprint", "infsprint" ) } ),
		C( 1, "Jumping", { T( "Super Jump", "superjump" ), T( "Infinite Jump", "infjump" ), S( "Jump Boost", "jumpboost", { "400", "550", "750", "1000", "1400" }, 2 ), T( "Double Jump Anywhere", "doublejump" ) } ),
		C( 2, "No Clip", { T( "No Clip", "noclip" ), S( "Fly Speed", "flyspeed", { "Slow", "Normal", "Fast", "Faster" }, 1 ), S( "Sprint Boost", "flyboost", { "1.5x", "2.5x", "4x" }, 1 ), N( "Move to fly, Jump up, Crouch down." ) } ),
		C( 3, "Safety", { T( "No Fall Damage", "nofall" ), T( "Return If Out Of Map", "oob" ) } )
	} }
end

local function CameraSide()
	return { id = "camera", label = "Camera", cards = {
		C( 0, "View", { T( "Third Person", "thirdperson" ), S( "Field of View", "fov", { "65", "75", "80", "90", "100", "110", "120" }, 2 ), T( "Hide HUD", "hidehud" ) } ),
		C( 1, "Photo Mode", { T( "Freeze Time", "freezetime" ), T( "Hide Weapon", "hideweapon" ), N( "Use with No Clip for screenshots." ) } )
	} }
end

local function OverlaySide( zm )
	local show
	if zm then
		show = { T( "Round", "ov_s_round" ), T( "Zombies Left", "ov_s_left" ), T( "Points", "ov_s_points" ), T( "Kills", "ov_s_kills" ),
			T( "Headshots", "ov_s_hs" ), T( "Map", "ov_s_map" ), T( "Game Time", "ov_s_gtime" ), T( "Round Time", "ov_s_rtime" ), T( "Players Alive", "ov_s_alive" ) }
	else
		show = { T( "Mode", "ov_s_mode" ), T( "Team Score", "ov_s_score" ), T( "Time Left", "ov_s_time" ), T( "Kills", "ov_s_kills" ),
			T( "Deaths", "ov_s_deaths" ), T( "Your Score", "ov_s_pscore" ), T( "Specialist %", "ov_s_spec" ), T( "Bots", "ov_s_bots" ), T( "Map", "ov_s_map" ) }
	end
	return { id = "overlay", label = "Overlay", cards = {
		C( 0, "Stats Overlay", { T( "Enabled", "ov_on" ), CH( "Position", "ov_pos", { "Top Right", "Top Left", "Bottom Right", "Bottom Left" }, 0 ),
			S( "Opacity", "ov_alpha", { "30%", "50%", "65%", "80%", "95%" }, 3 ), CH( "Size", "ov_size", { "Small", "Medium", "Large" }, 1 ), T( "Show Logo", "ov_logo" ) } ),
		C( 1, "Show", show ),
		C( 2, "Extras", { T( "Active Features", "ov_tags" ), T( "Controls Hint", "ov_hint" ),
			T( zm and "Flash On New Round" or "Flash On Streak", "ov_flash" ), T( "Hide While Menu Open", "ov_hidemenu" ) } )
	} }
end

local function PositionSide( id, label )
	return { id = id, label = label, cards = {
		C( 0, "Position Slots (this game)", { CH( "Slot", "posslot", { "Slot 1", "Slot 2", "Slot 3" }, 0 ), B( "Save" ), B( "Load" ),
			ST( "Slot 1", "slot1" ), ST( "Slot 2", "slot2" ), ST( "Slot 3", "slot3" ) } ),
		C( 1, "Quick", { B( "To Crosshair" ), B( "To Sky (+2000)" ), B( "Back to Spawn" ) } ),
		C( 2, "Current", { ST( "X", "px" ), ST( "Y", "py" ), ST( "Z", "pz" ), ST( "Facing", "yaw" ) } )
	} }
end

local function ConfigSide()
	return { id = "config", label = "Config", cards = {
		C( 0, "Config", { LB( "Save Config" ), LB( "Load Config" ), LT( "Auto-Load On Start", "cfg_auto", "every game" ), LB( "Reset To Defaults", true ) } ),
		C( 1, "Status", { ST( "Storage", "cfg_store" ), ST( "Last Action", "cfg_last" ) } ),
		C( 2, "About", { N( "Saves every toggle and slider (Zombies and Multiplayer separately)." ), N( "Not saved: positions, No Clip, Forge, round / time freezes." ) } )
	} }
end

-- Weapons > Camo (same order as offmenu_camo.gsc)
Spec.Camos = {
	"Gold", "Diamond", "Dark Matter", "Jungle Tech", "Ash", "Flectarn",
	"Heat Stroke", "Snow Job", "Dante", "Integer", "6 Speed", "Policia",
	"Ardent", "Burnt", "Bliss", "Battle", "Chameleon", "Arctic",
	"Jungle", "Huntsman", "Woodlums", "Contagious", "Fear", "WMD",
	"Red Hex", "Lucid", "PaP Shadows of Evil", "PaP Der Eisendrache 1", "PaP Der Eisendrache 2", "PaP Der Eisendrache 3",
	"PaP Der Eisendrache 4", "PaP Der Eisendrache 5", "PaP Der Eisendrache 6", "PaP Zetsubou No Shima", "PaP Gorod Krovi", "PaP Gorod Krovi 2",
	"PaP Gorod Krovi 3", "PaP Revelations", "PaP Revelations 2", "Transgression", "Storm", "Wartorn",
	"Prestige", "Etching", "Ice", "Jungle Earth", "Jungle Glow", "Scorch Contrast",
	"Scorch Green", "Scorch Glow", "Flectarn Purple", "Flectarn Stealth", "Flectarn Glow", "Flectarn Shiny",
	"Snow Job Green", "Dante Crazy", "Dante Hallucination", "Dante Glow", "Integer Purple", "Integer Glow",
	"Ardent Glow", "Burnt Shiny", "Art of War Gold Ink", "Art of War Gem", "Art of War Animated", "Chameleon Shiny",
	"Chameleon Glow", "Heat Stroke Glow", "Section 9", "Black Ops III", "115", "Cyborg",
	"Loyalty", "Take Out", "Nuketown", "Jungle Cat", "Heat Stroke Red", "Nightmare",
	"CoD XP", "Contract Crystals", "St Patricks", "Cherry Fizz", "VIP Bubbles", "Soviet Winter Blue",
	"Honeycomb Amber", "Summertime", "CWL Excellence", "CWL Mindfreak", "CWL NV", "CWL Orbit",
	"CWL Tainted Minds", "CWL Epsilon", "CWL Infused", "CWL LDLC", "CWL Millenium", "CWL Splyce",
	"CWL Supremacy", "CWL Cloud9", "CWL Elevate", "CWL EnVyUs", "CWL FaZe", "CWL OpTic",
	"CWL Rise Nation"
}

local function CamoSide()
	return { id = "camo", label = "Camo", cards = {
		C( 0, "Guns", { T( "Universal Camo", "camo_on" ), CH( "Camo", "camo_gun", Spec.Camos, 2 ), N( "Every gun you hold, picked up ones too." ) } ),
		C( 1, "Knife", { T( "Knife Camo", "kcamo_on" ), CH( "Camo", "camo_knife", Spec.Camos, 2 ), N( "Only knives that take camos (MP combat knife)." ) } )
	} }
end

local function ToolsSide( bring )
	return { id = "tools", label = "Tools", cards = {
		C( 0, "Teleport Gun", { T( "Teleport Gun", "telegun" ), N( "Shoot to teleport where it lands." ) } ),
		C( 1, "Bring", { B( "All Players to Me" ), B( bring ) } )
	} }
end

local function FunTab( magicLabels, zm )
	return { id = "fun", label = "Fun", sides = {
		{ id = "bullets", label = "Bullets", cards = {
			C( 0, "Explosive Bullets", { T( "Explosive Bullets", "explo" ), S( "Radius", "explo_r", { "100", "160", "220", "300", "400" }, 2 ), S( "Damage", "explo_d", { "150", "300", "600", "1500", "5000" }, 2 ) } ),
			C( 1, "Magic Bullets", { T( "Magic Bullets", "magic" ), CH( "Fires", "magic_w", magicLabels, 0 ) } ),
			C( 3, "Rapid Fire", { T( "Rapid Fire", "rapid" ), S( "Fire Rate", "rapid_r", { "5/s", "10/s", "20/s", "40/s" }, 1 ), N( "Hold fire: your gun shoots at the crosshair this fast, snipers too." ) } ),
			C( 2, "Extras", zm and { T( "Fast Reload", "fastreload" ), T( "Fast Weapon Swap", "fastswap" ), T( "No Recoil", "norecoil" ), T( "Headshots Only", "hsonly" ), T( "Every Shot Hits Head", "autohead" ) }
				or { T( "Fast Reload", "fastreload" ), T( "Fast Weapon Swap", "fastswap" ), T( "No Recoil", "norecoil" ) } )
		} },
		{ id = "forge", label = "Forge", cards = {
			C( 0, "Forge Mode", { T( "Forge Mode", "forge" ), S( "Hold Distance", "forge_d", { "80", "150", "250", "400" }, 1 ), N( "Aim at an object, hold Use to carry." ) } ),
			C( 1, "Options", { T( "Rotate With View", "forge_rot" ) } )
		} },
		{ id = "arsenal", label = "Arsenal", cards = zm and {
			C( 0, "Airstrike", { B( "Call Airstrike" ), CH( "Rockets", "strike_n", { "3", "6", "10" }, 1 ) } ),
			C( 1, "Force Push", { T( "Force Push", "forcepush" ), N( "Shots knock zombies flying." ) } )
		} or {
			C( 0, "Airstrike", { B( "Call Airstrike" ), CH( "Rockets", "strike_n", { "3", "6", "10" }, 1 ) } )
		} },
		{ id = "modes", label = "Modes", cards = zm and {
			C( 0, "Gun Game", { T( "Gun Game", "gungame" ), CH( "Kills Per Weapon", "gg_kills", { "1", "3", "5", "10" }, 1 ) } ),
			C( 1, "Weapons", { T( "Random Weapon Each Round", "rndweapon" ), T( "Auto Pack-a-Punch", "autopap" ) } )
		} or {
			C( 0, "Gun Game", { T( "Gun Game", "gungame" ), CH( "Kills Per Weapon", "gg_kills", { "1", "3", "5", "10" }, 1 ) } ),
			C( 1, "Everyone", { T( "Gun Game For Everyone", "gg_all" ), N( "Bots climb the same ladder." ) } )
		} },
		zm and { id = "zombies", label = "Zombies", cards = {
			C( 0, "Chaos", { T( "Exploding Zombies", "explodezm" ), B( "Launch All Zombies" ) } ),
			C( 1, "Aim Assist", { T( "Aim Assist", "aimassist" ), CH( "Strength", "aim_str", { "Light", "Medium", "Strong" }, 1 ), N( "Zombies only, while aiming." ) } )
		} } or { id = "clone", label = "Clone", cards = {
			C( 0, "Clone", { B( "Spawn Clone" ), B( "Remove Clones" ) } )
		} }
	} }
end

local function WorldTab( zm )
	local second
	if zm then
		second = C( 1, "Rounds", { T( "Pause Between Rounds", "pauserounds" ), S( "Round Delay", "rounddelay", { "0s", "5s", "10s", "20s", "30s" }, 2 ) } )
	else
		second = C( 1, "Timer", { T( "Pause Timer", "pausetimer" ), T( "Unlimited Time", "unlimtime" ) } )
	end
	return { id = "world", label = "World", sides = {
		{ id = "time", label = "Time", cards = {
			C( 0, "Speed", { T( "Slow Motion", "slowmo" ), S( "Game Speed", "timescale", { "0.25x", "0.5x", "0.75x", "1.0x", "1.5x", "2.0x" }, 3 ) } ),
			second
		} },
		{ id = "physics", label = "Physics", cards = {
			C( 0, "Gravity", { T( "Low Gravity", "lowgrav" ), S( "Gravity", "gravity", { "100", "200", "400", "600", "800", "1200" }, 4 ) } ),
			C( 1, "Jumping (everyone)", { S( "Jump Height", "jump_h", { "39", "60", "100", "200", "400" }, 0 ) } ),
			C( 2, "Movement (everyone)", { S( "Player Speed", "all_speed", { "1.0x", "1.25x", "1.5x", "2.0x" }, 0 ) } )
		} },
		{ id = "filters", label = "Filters", cards = {
			C( 0, "Screen Filter", { CH( "Filter", "filter", { "None", "Frost", "Glitch", "Overdrive", "Underwater", "Rain", "Radial Blur", "Speed Burst", "Static", "EMP" }, 0 ) } )
		} }
	} }
end

-- Players page (dynamic: list comes from script)
local function PlayersSide( zm )
	return { id = "players", label = "Players", dynamic = "players", build = function( data )
		local list = {}
		for _, p in ipairs( data.players or {} ) do
			table.insert( list, I( p.name, "player", p.num ) )
		end
		if #list == 0 then table.insert( list, N( "No players found." ) ) end
		local actions = { B( "Bring to Me" ), B( "Go to Player" ), B( "Give God" ), B( "Remove God" ), B( "Freeze" ), B( "Unfreeze" ) }
		if zm then
			table.insert( actions, B( "Revive" ) ); table.insert( actions, B( "Give 10,000 Points" ) ); table.insert( actions, B( "Give All Perks" ) )
		else
			table.insert( actions, B( "Kick", true ) )
		end
		table.insert( actions, B( "Kill", true ) )
		return {
			C( 0, "Players", list ),
			C( 1, "Actions", actions ),
			C( 2, "Selected", { ST( "Name", "selname" ), ST( "Health", "selhp" ), ST( "God Mode", "selgod" ) } )
		}
	end }
end

-- ---------------------------------------------------------------------------
-- Zombies
-- ---------------------------------------------------------------------------

local function ZMWeaponSide( cat, label )
	return { id = cat, label = label, dynamic = "zm_weapons", gun = cat, build = function( data )
		local list = {}
		for i, w in ipairs( Spec.ZMWeapons ) do
			if w[3] == cat and data.available and data.available[ i - 1 ] then
				table.insert( list, I( w[2], "w_" .. cat, w[1] ) )
			end
		end
		if #list == 0 then table.insert( list, N( "None on this map." ) ) end
		return {
			C( 0, label, list ),
			C( 1, "Give", { B( "Give" ), B( "Give Upgraded" ), T( "Replace Current Weapon", "w_replace" ), T( "Switch To It", "w_switch" ) } ),
			C( 2, "Pack-a-Punch", { CH( "Alt Ammo", "aat_give", { "Random", "Blast Furnace", "Dead Wire", "Fireworks", "Thunder Wall", "Turned" }, 0 ), N( "Used when giving the upgraded one." ) } ),
			C( 3, "Current Loadout", { ST( "Slot 1", "slot_w1" ), ST( "Slot 2", "slot_w2" ), ST( "Slot 3", "slot_w3" ), B( "Drop Current" ), B( "Take Current" ) } )
		}
	end }
end

local function ZMTabs()
	local tabs = {}
	table.insert( tabs, { id = "player", label = "Player", sides = {
		{ id = "general", label = "General", cards = {
			C( 0, "Survival", { T( "God Mode", "god" ), T( "Demi-God", "demigod", "never dies" ), T( "Zombies Ignore Me", "ignoreme" ), T( "Invisible", "invisible" ), T( "Auto Revive", "autorevive" ) } ),
			C( 0, "Quick Actions", { B( "Max Ammo" ), B( "Full Health" ), B( "All Perks" ), B( "Suicide", true ) } ),
			C( 1, "Ammo", { T( "Infinite Ammo", "ammo" ), T( "Infinite Equipment", "equip" ), T( "Infinite Hero Weapon", "hero" ), CH( "Ammo Mode", "ammomode", { "Clip + Stock", "Stock Only" }, 0 ) } ),
			C( 1, "Health", { S( "Max Health", "maxhp", { "100", "150", "250", "500", "1000" }, 0 ), CH( "Regen", "regen", { "Normal", "Fast", "Instant" }, 0 ) } ),
			C( 2, "Points", { ST( "Current", "points" ), CH( "Amount", "pts_amt", { "1,000", "10,000", "100,000", "1,000,000" }, 1 ), B( "Give" ), B( "Take" ), T( "Lock Points", "lockpts" ) } ),
			C( 3, "Weapon", { ST( "Holding", "holding" ), B( "Pack-a-Punch" ), B( "Un-Pack" ), B( "Drop" ), B( "Take" ) } )
		} },
		MovementSide(), CameraSide(), OverlaySide( true ), PositionSide( "position", "Position" ), ConfigSide()
	} } )

	table.insert( tabs, { id = "weapons", label = "Weapons", sides = {
		ZMWeaponSide( "ar", "Assault Rifles" ), ZMWeaponSide( "smg", "SMGs" ), ZMWeaponSide( "shotgun", "Shotguns" ), ZMWeaponSide( "lmg", "LMGs" ),
		ZMWeaponSide( "sniper", "Snipers" ), ZMWeaponSide( "pistol", "Pistols" ), ZMWeaponSide( "launcher", "Launchers" ), ZMWeaponSide( "wonder", "Wonder Weapons" ),
		{ id = "upgrades", label = "Upgrades", gun = "pap", cards = {
			C( 0, "Current Weapon", { ST( "Holding", "holding" ), ST( "Upgraded", "upgraded" ), B( "Pack-a-Punch" ), B( "Un-Pack" ) } ),
			C( 1, "Alt Ammo", { CH( "Type", "aat", { "Blast Furnace", "Dead Wire", "Fireworks", "Thunder Wall", "Turned" }, 0 ), B( "Apply to Current" ) } ),
			C( 2, "All Weapons", { B( "Upgrade All" ), B( "Max Ammo All" ), B( "Take All Weapons", true ) } )
		} },
		CamoSide()
	} } )

	local classic, mega = {}, {}
	for _, g in ipairs( Spec.ClassicGums ) do table.insert( classic, I( Spec.Pretty( g, "zm_bgb_" ), "bgb", g ) ) end
	for _, g in ipairs( Spec.MegaGums ) do table.insert( mega, I( Spec.Pretty( g, "zm_bgb_" ), "bgb", g ) ) end

	table.insert( tabs, { id = "zombies", label = "Zombies", sides = {
		{ id = "points", label = "Points", cards = {
			C( 0, "Points", { ST( "Current", "points" ), CH( "Amount", "pts_amt", { "1,000", "10,000", "100,000", "1,000,000" }, 1 ), B( "Give" ), B( "Take" ), T( "Lock Points", "lockpts" ) } ),
			C( 1, "Presets", { B( "+1,000" ), B( "+10,000" ), B( "+100,000" ), B( "+1,000,000" ), B( "Reset to 500" ) } ),
			C( 2, "Team", { B( "Give Amount to Everyone" ), T( "Double Points Always", "perma_dp" ) } ),
			C( 3, "Stats", { ST( "Kills", "kills" ), ST( "Headshots", "headshots" ), ST( "Downs", "downs" ) } )
		} },
		{ id = "perks", label = "Perks", dynamic = "perks", build = function( data )
			local a, b = {}, {}
			local avail = {}
			for i, p in ipairs( Spec.Perks ) do
				if data.available and data.available[ i - 1 ] then table.insert( avail, p ) end
			end
			local half = math.ceil( #avail / 2 )
			for i, p in ipairs( avail ) do
				local row = T( p[2], "perk_" .. p[1] )
				if i <= half then table.insert( a, row ) else table.insert( b, row ) end
			end
			if #avail == 0 then table.insert( a, N( "This map has no perks." ) ) end
			return {
				C( 0, "Perks", a ), C( 1, "More Perks", b ),
				C( 2, "Actions", { B( "Give All" ), B( "Remove All" ), T( "No Perk Limit", "noperklimit" ), T( "Keep Perks When Downed", "keepperks" ) } )
			}
		end },
		{ id = "bgb", label = "Gobblegums", cards = {
			C( 0, "Classic", classic ), C( 1, "Mega", mega ),
			C( 2, "Give", { B( "Give Selected" ), B( "Give Last Again" ), N( "Selected gum goes in your gum slot." ) } )
		} },
		{ id = "powerups", label = "Power-Ups", dynamic = "powerups", build = function( data )
			local a, b, avail = {}, {}, {}
			for i, p in ipairs( Spec.PowerUps ) do
				if data.available and data.available[ i - 1 ] then table.insert( avail, p ) end
			end
			local half = math.ceil( #avail / 2 )
			for i, p in ipairs( avail ) do
				local row = B( p[2] ); row.id = p[1]
				if i <= half then table.insert( a, row ) else table.insert( b, row ) end
			end
			return {
				C( 0, "Spawn", a ), C( 1, "More", b ),
				C( 2, "Settings", { CH( "Spawn At", "pu_at", { "Crosshair", "On Me" }, 0 ) } ),
				C( 3, "Permanent", { T( "Insta-Kill", "perma_ik" ), T( "Double Points", "perma_dp" ), T( "Fire Sale", "perma_fs" ) } )
			}
		end },
		{ id = "rounds", label = "Rounds", cards = {
			C( 0, "Round", { ST( "Current", "round" ), CH( "Jump To", "round_to", { "5", "10", "15", "20", "25", "30", "40", "50", "75", "100" }, 5 ), B( "Apply" ), B( "Skip 1" ), B( "Skip 5" ) } ),
			C( 1, "Zombies", { B( "Kill All Zombies" ), T( "Stop Spawning", "nospawn" ), T( "Freeze Zombies", "freezezm" ), T( "One-Hit Zombies", "onehit" ),
				CH( "Zombie Speed", "zm_speed", { "Default", "Walk", "Run", "Sprint", "Super Sprint" }, 0 ) } ),
			C( 2, "Live", { ST( "Zombies Left", "zleft" ), ST( "Alive Now", "zalive" ), ST( "Round Time", "rtime" ) } )
		} },
		{ id = "map", label = "Map", cards = {
			C( 0, "Power", { B( "Turn On Power" ), ST( "State", "power" ) } ),
			C( 1, "Doors", { B( "Open All Doors & Debris" ), T( "Free Doors", "freedoors" ) } ),
			C( 2, "Mystery Box", { T( "Free Mystery Box", "freebox" ), B( "Start Fire Sale" ) } ),
			C( 3, "Pack-a-Punch", { T( "Free Pack-a-Punch", "freepap" ), B( "Teleport to Pack-a-Punch" ) } )
		} },
		{ id = "revive", label = "Revive", cards = {
			C( 0, "Revive", { T( "Instant Revive", "instarevive" ), T( "Infinite Downs", "infdowns" ), N( "Solo keeps Quick Revive." ) } )
		} }
	} } )

	table.insert( tabs, { id = "esp", label = "ESP", sides = {
		{ id = "enemies", label = "Enemies", cards = {
			C( 0, "Zombie ESP", { T( "Enabled", "esp_on" ), T( "Through Walls", "esp_walls" ), S( "Max Distance", "esp_dist", { "750", "1,500", "3,000", "6,000", "Any" }, 2 ), S( "Max Markers", "esp_max", { "8", "16", "24", "32" }, 2 ) } ),
			C( 1, "Show", { T( "Regular Zombies", "esp_reg" ), T( "Crawlers", "esp_crawl" ), T( "Special Enemies", "esp_spec", "dogs, spiders" ), T( "Bosses", "esp_boss", "Margwa, Panzer" ) } ),
			C( 2, "Live", { ST( "Tracked", "esp_tracked" ), ST( "Nearest", "esp_nearest" ), ST( "Specials", "esp_specials" ), ST( "Out of Range", "esp_out" ) } )
		} },
		{ id = "style", label = "Style", cards = {
			C( 0, "Marker", { CH( "Style", "esp_style", { "Diamond", "Dot", "Box", "Skull" }, 0 ), S( "Size", "esp_size", { "XS", "S", "M", "L", "XL", "XXL" }, 2 ), S( "Opacity", "esp_alpha", { "40%", "60%", "85%", "100%" }, 2 ) } ),
			C( 1, "Colours", { CH( "Regular", "esp_c_reg", Colors, 0 ), CH( "Special", "esp_c_spec", Colors, 1 ), CH( "Boss", "esp_c_boss", Colors, 2 ),
				T( "Red When Close", "esp_redclose" ), S( "Close Range", "esp_close", { "150", "300", "500", "800" }, 1 ) } )
		} },
		{ id = "labels", label = "Labels", cards = {
			C( 0, "Labels", { T( "Distance", "esp_l_dist" ), T( "Health Bar", "esp_l_hp" ) } ),
			C( 1, "Behaviour", { T( "Edge Arrows", "esp_edge", "off-screen" ), T( "Nearest Zombie Only", "esp_nearest" ), T( "Pulse When Close", "esp_pulse" ) } )
		} },
		{ id = "items", label = "Map Items", cards = {
			C( 0, "Items", { T( "Mystery Box", "esp_i_box" ), T( "Pack-a-Punch", "esp_i_pap" ), T( "Perk Machines", "esp_i_perks" ), T( "Wall Weapons", "esp_i_wall" ),
				T( "Buildable Parts", "esp_i_parts" ), T( "Power-Ups On Ground", "esp_i_pow" ) } ),
			C( 1, "Style", { CH( "Colour", "esp_c_item", Colors, 3 ), S( "Size", "esp_i_size", { "XS", "S", "M", "L", "XL", "XXL" }, 2 ) } )
		} },
		{ id = "chams", label = "Chams", cards = {
			C( 0, "Zombie Chams", { T( "Enabled", "zc_on" ), CH( "Style", "zc_style", { "Solid", "Through Walls", "Solid + Walls", "Thermal", "Rim Glow", "Glitch", "Hex Shimmer", "Flow", "Hacked" }, 2 ),
				CH( "Colour", "zc_col", { "Pink", "Red", "Green", "Cyan", "Gold", "White", "Purple", "Rainbow" }, 0 ),
				S( "Rainbow Speed", "zc_speed", { "Slow", "Normal", "Fast", "Very Fast" }, 1 ) } ),
			C( 1, "About", { N( "Solid: zombies drawn in one flat colour." ), N( "Through Walls: coloured silhouette you can see through walls." ), N( "Thermal: heat-vision look." ), N( "Rim Glow, Glitch, Hex Shimmer, Flow, Hacked: animated game shaders." ) } )
		} }
	} } )

	table.insert( tabs, { id = "teleport", label = "Teleport", sides = {
		PositionSide( "positions", "Positions" ),
		{ id = "spots", label = "Map Spots", dynamic = "spots", build = function( data )
			local machines = {}
			if data.pap then table.insert( machines, I( "Pack-a-Punch", "spot", "pap" ) ) end
			if data.box then table.insert( machines, I( "Mystery Box", "spot", "box" ) ) end
			for i, p in ipairs( Spec.Perks ) do
				if data.machines and data.machines[ i - 1 ] then table.insert( machines, I( p[2], "spot", p[1] ) ) end
			end
			local map = { B( "Player Spawn" ) }
			if data.power then table.insert( map, B( "Power Switch" ) ) end
			return { C( 0, "Machines", machines ), C( 1, "Map", map ), C( 2, "Note", { N( "Spots come from the map, so" ), N( "custom maps work too." ) } ) }
		end },
		ToolsSide( "All Zombies to Crosshair" )
	} } )

	table.insert( tabs, FunTab( { "Ray Gun", "GKZ-45 Mk3", "Wunderwaffe", "Thundergun", "XM-53", "L4 Siege" }, true ) )
	table.insert( tabs, WorldTab( true ) )
	table.insert( tabs, { id = "lobby", label = "Lobby", sides = {
		PlayersSide( true ),
		{ id = "session", label = "Session", cards = {
			C( 0, "Game", { B( "Restart Map" ), B( "End Game", true ) } ),
			C( 1, "Menu", { T( "Hide Welcome Hint", "nohint" ), B( "Run Self-Test" ) } ),
			C( 2, "Info", { ST( "Mode", "mode" ), ST( "Map", "map" ), ST( "Session", "session" ) } )
		} }
	} } )
	return tabs
end

-- ---------------------------------------------------------------------------
-- Multiplayer
-- ---------------------------------------------------------------------------

local function MPWeaponSide( cat, label )
	return { id = cat, label = label, dynamic = "mp_weapons", gun = cat, build = function( data )
		local list = {}
		for i, w in ipairs( Spec.MPWeapons ) do
			if w[3] == cat and data.available and data.available[ i - 1 ] then
				table.insert( list, I( w[2], "w_" .. cat, w[1] ) )
			end
		end
		if #list == 0 then table.insert( list, N( "Not available." ) ) end
		return {
			C( 0, label, list ),
			C( 1, "Give", { B( "Give" ), B( "Give With Attachments" ), T( "Replace Current Weapon", "w_replace" ), T( "Switch To It", "w_switch" ) } ),
			C( 3, "Current Loadout", { ST( "Primary", "prim" ), ST( "Secondary", "sec" ), B( "Drop Current" ) } )
		}
	end }
end

local function MPTabs()
	local tabs = {}
	table.insert( tabs, { id = "player", label = "Player", sides = {
		{ id = "general", label = "General", cards = {
			C( 0, "Survival", { T( "God Mode", "god" ), T( "Demi-God", "demigod", "never dies" ), T( "Always UAV", "uav" ), T( "Invisible", "invisible" ), T( "Instant Respawn", "instaspawn" ) } ),
			C( 0, "Quick Actions", { B( "Max Ammo" ), B( "Full Health" ), B( "Full Specialist" ), B( "Suicide", true ) } ),
			C( 1, "Ammo", { T( "Infinite Ammo", "ammo" ), T( "Infinite Equipment", "equip" ), T( "Infinite Specialist", "hero" ), CH( "Ammo Mode", "ammomode", { "Clip + Stock", "Stock Only" }, 0 ) } ),
			C( 1, "Health", { S( "Max Health", "maxhp", { "100", "150", "250", "500", "1000" }, 0 ), CH( "Regen", "regen", { "Normal", "Fast", "Instant" }, 0 ) } ),
			C( 2, "Score", { ST( "Your Score", "score" ), ST( "Kills", "kills" ), ST( "Deaths", "deaths" ), CH( "Add Score", "score_amt", { "100", "500", "1,000", "5,000" }, 2 ), B( "Give" ) } ),
			C( 3, "Weapon", { ST( "Holding", "holding" ), B( "Refill" ), B( "Drop" ) } )
		} },
		MovementSide(), CameraSide(), OverlaySide( false ), PositionSide( "position", "Position" ), ConfigSide()
	} } )

	local att = {}
	for _, a in ipairs( { { "extclip", "Extended Mags" }, { "fastreload", "Fast Mags" }, { "grip", "Grip" }, { "quickdraw", "Quickdraw" }, { "suppressed", "Suppressor" },
		{ "rf", "Rapid Fire" }, { "fmj", "FMJ" }, { "extbarrel", "Long Barrel" }, { "stalker", "Stock" }, { "steadyaim", "Laser Sight" } } ) do
		table.insert( att, T( a[2], "att_" .. a[1] ) )
	end
	table.insert( tabs, { id = "weapons", label = "Weapons", sides = {
		MPWeaponSide( "ar", "Assault Rifles" ), MPWeaponSide( "smg", "SMGs" ), MPWeaponSide( "shotgun", "Shotguns" ), MPWeaponSide( "lmg", "LMGs" ),
		MPWeaponSide( "sniper", "Snipers" ), MPWeaponSide( "pistol", "Pistols" ), MPWeaponSide( "launcher", "Launchers" ), MPWeaponSide( "hero", "Specialist" ),
		{ id = "attach", label = "Attachments", gun = "pap", cards = {
			C( 0, "Optic", { CH( "Optic", "att_optic", { "None", "Reflex", "ELO", "Holo", "Recon", "Thermal", "Varix" }, 0 ) } ),
			C( 1, "Attachments", att ),
			C( 2, "Apply", { B( "Apply to Current" ), N( "Unsupported ones are skipped." ) } )
		} },
		CamoSide()
	} } )

	local heroes = {}
	for _, w in ipairs( Spec.MPWeapons ) do
		if w[3] == "hero" then table.insert( heroes, I( w[2], "hero", w[1] ) ) end
	end
	table.insert( tabs, { id = "streaks", label = "Streaks", sides = {
		{ id = "score", label = "Scorestreaks", dynamic = "streaks", build = function( data )
			local a, b, avail = {}, {}, {}
			for i, s in ipairs( Spec.Streaks ) do
				if data.available and data.available[ i - 1 ] then table.insert( avail, s ) end
			end
			local half = math.ceil( #avail / 2 )
			for i, s in ipairs( avail ) do
				local row = I( s[2], "streak", s[1] )
				if i <= half then table.insert( a, row ) else table.insert( b, row ) end
			end
			return { C( 0, "Scorestreaks", a ), C( 1, "More", b ), C( 2, "Give", { B( "Give Selected" ), B( "Give All" ) } ) }
		end },
		{ id = "spec", label = "Specialist", cards = {
			C( 0, "Specialist", { ST( "Charge %", "specpct" ), B( "Full Charge" ), T( "Infinite Specialist", "hero" ) } ),
			C( 1, "Weapon", heroes )
		} }
	} } )

	table.insert( tabs, { id = "teleport", label = "Teleport", sides = {
		PositionSide( "positions", "Positions" ),
		{ id = "spots", label = "Map Spots", cards = {
			C( 0, "Spawns", { B( "Allies Spawn" ), B( "Axis Spawn" ), B( "Random Spawn" ), B( "Map Centre" ) } )
		} },
		ToolsSide( "All Bots to Crosshair" )
	} } )

	table.insert( tabs, FunTab( { "XM-53", "L4 Siege", "BlackCell", "Annihilator", "War Machine", "Tempest" } ) )
	table.insert( tabs, WorldTab( false ) )
	table.insert( tabs, { id = "lobby", label = "Lobby", sides = {
		PlayersSide( false ),
		{ id = "bots", label = "Bots", cards = {
			C( 0, "Add Bots", { CH( "Team", "bot_team", { "Enemy", "Friendly" }, 0 ), CH( "Count", "bot_count", { "1", "3", "5", "9" }, 2 ),
				CH( "Difficulty", "bot_diff", { "Recruit", "Regular", "Hardened", "Veteran" }, 1 ), B( "Add" ) } ),
			C( 1, "Control", { B( "Kill All Bots" ), B( "Bring Bots to Crosshair" ), T( "Freeze Bots", "freezebots" ), B( "Kick All Bots", true ) } ),
			C( 2, "Behaviour", { T( "Bots Ignore Me", "botsignore" ) } )
		} },
		{ id = "match", label = "Match", cards = {
			C( 0, "Timer", { T( "Pause Timer", "pausetimer" ), T( "Unlimited Time", "unlimtime" ), T( "Unlimited Score", "unlimscore" ) } ),
			C( 1, "Game", { B( "Fast Restart" ), B( "End Game", true ) } ),
			C( 2, "Menu", { T( "Hide Welcome Hint", "nohint" ), B( "Run Self-Test" ) } ),
			C( 3, "Info", { ST( "Mode", "mode" ), ST( "Map", "map" ), ST( "Session", "session" ) } )
		} }
	} } )
	return tabs
end

function Spec.Build( zm )
	if zm then return ZMTabs() end
	return MPTabs()
end
