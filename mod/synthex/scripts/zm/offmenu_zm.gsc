// SYNTHEX.VIP - Zombies pages.
// Tabs: Player, Weapons, Zombies, ESP, Teleport, Fun, World, Lobby.

#using scripts\codescripts\struct;
#using scripts\shared\aat_shared;
#using scripts\shared\array_shared;
#using scripts\shared\flag_shared;
#using scripts\shared\laststand_shared;
#using scripts\shared\system_shared;
#using scripts\shared\util_shared;
#using scripts\shared\ai\zombie_utility;
#using scripts\shared\offmenu\offmenu_core;
#using scripts\shared\offmenu\offmenu_common;
#using scripts\shared\offmenu\offmenu_overlay;

#using scripts\zm\_zm;
#using scripts\zm\_zm_bgb;
#using scripts\zm\_zm_laststand;
#using scripts\zm\_zm_perks;
#using scripts\zm\_zm_powerups;
#using scripts\zm\_zm_score;
#using scripts\zm\_zm_utility;
#using scripts\zm\_zm_weapons;
#using scripts\zm\offmenu_esp;
#using scripts\zm\offmenu_zm_fun;
#using scripts\shared\offmenu\offmenu_fun;
#using scripts\shared\offmenu\offmenu_camo;

#insert scripts\shared\shared.gsh;

#namespace offmenu_zm;

REGISTER_SYSTEM_EX( "offmenu_zm", &__init__, &__main__, array( "offmenu" ) )

function __init__()
{
	level.offm_mode_label = "Zombies";
	level.offm_player_extra = &player_extra;
	level.offm_ov_tags = [];
	level.offm_ov_tags[ "god" ] = "GOD";
	level.offm_ov_tags[ "ammo" ] = "AMMO";
	level.offm_ov_tags[ "esp_on" ] = "ESP";
	level.offm_ov_tags[ "noclip" ] = "NOCLIP";
	level.offm_ov_tags[ "invisible" ] = "INVIS";
	level.offm_ov_tags[ "ignoreme" ] = "IGNORED";

	offmenu_overlay::add_stat( "round", "Round", "int", &st_round, true );
	offmenu_overlay::add_stat( "left", "Zombies Left", "int", &st_left, true );
	offmenu_overlay::add_stat( "points", "Points", "int", &st_points, true );
	offmenu_overlay::add_stat( "kills", "Kills", "int", &st_kills, true );
	offmenu_overlay::add_stat( "hs", "Headshots", "int", &st_headshots, false );
	offmenu_overlay::add_stat( "map", "Map", "str", &st_map, false );
	offmenu_overlay::add_stat( "gtime", "Game Time", "timer_up", &st_game_time, true );
	offmenu_overlay::add_stat( "rtime", "Round Time", "timer_up", &st_round_time, false );
	offmenu_overlay::add_stat( "alive", "Players Alive", "int", &st_alive, false );

	offmenu::set_builder( &build );

	level.offm_gungame_ladder = &offmenu_zm_fun::gungame_ladder;
	level.offm_stats_fn = &stats_array;
	level.offm_page_fn = &page_data;
	level.offm_powerup_fn = &spawn_powerup_named;
	level.offm_item_handlers[ "w_" ] = &item_weapon;
	level.offm_default_weapon_options = &default_weapon_options;
	level.offm_item_handlers[ "bgb" ] = &item_bgb;
	level.offm_item_handlers[ "player" ] = &item_player;
	level.offm_item_handlers[ "spot" ] = &item_spot;
}

function __main__()
{
	zm::register_actor_damage_callback( &headshots_only_damage );
	level.offm_game_start = GetTime();
	level.offm_round_start = GetTime();
	level thread watch_rounds();
}

function private watch_rounds()
{
	for ( ;; )
	{
		level waittill( "start_of_round" );
		level.offm_round_start = GetTime();
		foreach ( p in GetPlayers() )
			p thread offmenu_overlay::flash();
	}
}

// ---------------------------------------------------------------------------
// Header + overlay stats
// ---------------------------------------------------------------------------

function private st_round()      { return int( level.round_number ); }
function private st_points()     { return int( self.score ); }
function private st_kills()      { return int( self.kills ); }
function private st_headshots()  { return int( self.headshots ); }
function private st_left()       { return int( zombie_utility::get_current_zombie_count() + level.zombie_total ); }
function private st_game_time()  { return int( ( GetTime() - level.offm_game_start ) / 1000 ); }
function private st_round_time() { return int( ( GetTime() - level.offm_round_start ) / 1000 ); }
function private st_map()        { return map_name(); }

function private st_alive()
{
	n = 0;
	foreach ( p in GetPlayers() )
	{
		if ( IsAlive( p ) && !p laststand::player_is_in_laststand() )
			n++;
	}
	return n;
}

function map_name()
{
	m = GetDvarString( "mapname" );
	switch ( m )
	{
		case "zm_zod":        return "Shadows of Evil";
		case "zm_factory":    return "The Giant";
		case "zm_castle":     return "Der Eisendrache";
		case "zm_island":     return "Zetsubou No Shima";
		case "zm_stalingrad": return "Gorod Krovi";
		case "zm_genesis":    return "Revelations";
		case "zm_prototype":  return "Nacht der Untoten";
		case "zm_asylum":     return "Verruckt";
		case "zm_sumpf":      return "Shi No Numa";
		case "zm_theater":    return "Kino der Toten";
		case "zm_cosmodrome": return "Ascension";
		case "zm_temple":     return "Shangri-La";
		case "zm_moon":       return "Moon";
		case "zm_tomb":       return "Origins";
	}
	return m;
}

// ---------------------------------------------------------------------------
// Tree
// ---------------------------------------------------------------------------

function build()
{
	self build_player_tab();
	self build_weapons_tab();
	self build_zombies_tab();
	self offmenu_esp::build_tab();
	self build_teleport_tab();
	self offmenu_common::build_fun( "fun",
		array( "ray_gun", "raygun_mark3", "tesla_gun", "thundergun", "launcher_standard", "launcher_multi" ),
		array( "Ray Gun", "GKZ-45 Mk3", "Wunderwaffe", "Thundergun", "XM-53", "L4 Siege" ) );
	self add_headshots_only();
	self build_fun_extras();
	self build_world_tab();
	self build_lobby_tab();
}

// Fun > Arsenal / Modes / Zombies, Zombies > Revive, World > Filters (keys must match synthex_spec.lua)
function private build_fun_extras()
{
	self offmenu::side( "fun", "arsenal", "Arsenal" );
	self offmenu::card( 0, "Airstrike" );
	self offmenu::button( "Call Airstrike", &offmenu_fun::call_airstrike );
	self offmenu::choice( "Rockets", "strike_n", array( 3, 6, 10 ), array( "3", "6", "10" ), 1 );
	self offmenu::card( 1, "Force Push" );
	self offmenu::toggle( "Force Push", "forcepush", &offmenu_zm_fun::toggle_force_push );

	self offmenu::side( "fun", "modes", "Modes" );
	self offmenu::card( 0, "Gun Game" );
	self offmenu::toggle( "Gun Game", "gungame", &offmenu_fun::toggle_gungame, false );
	self offmenu::choice( "Kills Per Weapon", "gg_kills", array( 1, 3, 5, 10 ), array( "1", "3", "5", "10" ), 1 );
	self offmenu::card( 1, "Weapons" );
	self offmenu::toggle( "Random Weapon Each Round", "rndweapon", &offmenu_zm_fun::toggle_random_weapon, false );
	self offmenu::toggle( "Auto Pack-a-Punch", "autopap", &offmenu_zm_fun::toggle_auto_pap );

	self offmenu::side( "fun", "zombies", "Zombies" );
	self offmenu::card( 0, "Chaos" );
	self offmenu::toggle( "Exploding Zombies", "explodezm", &offmenu_zm_fun::toggle_exploding_zombies, false );
	self offmenu::button( "Launch All Zombies", &offmenu_zm_fun::launch_all_zombies );
	self offmenu::card( 1, "Aim Assist" );
	self offmenu::toggle( "Aim Assist", "aimassist", &offmenu_zm_fun::toggle_aim_assist );
	self offmenu::choice( "Strength", "aim_str", array( 0.12, 0.25, 0.5 ), array( "Light", "Medium", "Strong" ), 1 );

	self offmenu::side( "zombies", "revive", "Revive" );
	self offmenu::card( 0, "Revive" );
	self offmenu::toggle( "Instant Revive", "instarevive", &offmenu_zm_fun::toggle_instant_revive, false );
	self offmenu::toggle( "Infinite Downs", "infdowns", &offmenu_zm_fun::toggle_infinite_downs, false );
}

// Fun > Bullets > Extras: Headshots Only (zombies only take damage from player headshots)
function private add_headshots_only()
{
	foreach ( t in self.offm.tabs )
	{
		if ( t.id != "fun" )
			continue;
		foreach ( s in t.sides )
		{
			if ( s.id != "bullets" )
				continue;
			foreach ( c in s.cards )
			{
				if ( c.title == "Extras" )
				{
					self.offm.b_side = s;
					self.offm.b_card = c;
					self offmenu::toggle( "Headshots Only", "hsonly", &toggle_headshots_only, false );
					self offmenu::toggle( "Every Shot Hits Head", "autohead", &toggle_auto_head );
				}
			}
		}
	}
}

function private toggle_headshots_only( on, key )
{
	level.offm_headshots_only = on;
}

// Per player (zombies only): every bullet that hits a zombie is re-delivered to its head.
function private toggle_auto_head( on, key )
{
	self.offm_autohead = on;
}

// Registered with zm::register_actor_damage_callback: return -1 to leave damage alone, else the new damage.
function private headshots_only_damage( inflictor, attacker, damage, flags, meansofdeath, weapon, vpoint, vdir, sHitLoc, psOffsetTime, boneIndex, surfaceType )
{
	if ( !isdefined( attacker ) || !IsPlayer( attacker ) )
		return -1;

	// Every Shot Hits Head: swallow the body hit and deal it again to the head next frame, so the game applies
	// its own headshot multiplier, points and head pop.
	if ( IS_TRUE( attacker.offm_autohead ) && is_bullet( meansofdeath ) && !zm_utility::is_headshot( weapon, sHitLoc, meansofdeath ) )
	{
		self thread redirect_to_head( damage, attacker, inflictor, meansofdeath, flags, weapon );
		return 0;
	}

	if ( !IS_TRUE( level.offm_headshots_only ) )
		return -1;
	if ( zm_utility::is_headshot( weapon, sHitLoc, meansofdeath ) )
		return -1;
	return 0;
}

function private is_bullet( mod )
{
	return mod === "MOD_RIFLE_BULLET" || mod === "MOD_PISTOL_BULLET";
}

function private redirect_to_head( damage, attacker, inflictor, mod, flags, weapon )
{
	self endon( "death" );
	waittillframeend;
	if ( !IsAlive( self ) || !isdefined( attacker ) )
		return;
	head = self.origin + ( 0, 0, 64 );
	if ( isdefined( self GetTagOrigin( "j_head" ) ) )
		head = self GetTagOrigin( "j_head" );
	self DoDamage( damage, head, attacker, inflictor, "head", mod, flags, weapon );
}

// ---- Player ----------------------------------------------------------------

function private build_player_tab()
{
	self offmenu::tab( "player", "Player" );

	self offmenu::side( "player", "general", "General" );
	self offmenu::card( 0, "Survival" );
	self offmenu::toggle( "God Mode", "god", &offmenu_common::toggle_god );
	self offmenu::toggle( "Demi-God", "demigod", &offmenu_common::toggle_demigod, undefined, "never dies" );
	self offmenu::toggle( "Zombies Ignore Me", "ignoreme", &toggle_ignoreme );
	self offmenu::toggle( "Invisible", "invisible", &offmenu_common::toggle_invisible );
	self offmenu::toggle( "Auto Revive", "autorevive", &toggle_auto_revive );
	self offmenu::card( 0, "Quick Actions" );
	self offmenu::button( "Max Ammo", &offmenu_common::max_ammo_all );
	self offmenu::button( "Full Health", &offmenu_common::full_health );
	self offmenu::button( "All Perks", &give_all_perks );
	self offmenu::button( "Suicide", &offmenu_common::suicide, undefined, undefined, true );

	self offmenu::card( 1, "Ammo" );
	self offmenu::toggle( "Infinite Ammo", "ammo", &offmenu_common::toggle_ammo );
	self offmenu::toggle( "Infinite Equipment", "equip", &offmenu_common::toggle_equipment );
	self offmenu::toggle( "Infinite Hero Weapon", "hero", &offmenu_common::toggle_gadget_power );
	self offmenu::choice( "Ammo Mode", "ammomode", array( "clip", "stock" ), array( "Clip + Stock", "Stock Only" ), 0 );
	self offmenu::card( 1, "Health" );
	self offmenu::slider( "Max Health", "maxhp", array( 100, 150, 250, 500, 1000 ), array( "100", "150", "250", "500", "1000" ), 0, &offmenu_common::set_max_health );
	self offmenu::choice( "Regen", "regen", array( 0, 5, 1000 ), array( "Normal", "Fast", "Instant" ), 0, &offmenu_common::set_regen );

	self offmenu::card( 2, "Points" );
	self offmenu::stat( "Current", &st_points );
	self offmenu::choice( "Amount", "pts_amt", array( 1000, 10000, 100000, 1000000 ), array( "1,000", "10,000", "100,000", "1,000,000" ), 1 );
	self offmenu::button( "Give", &give_points_selected, 1 );
	self offmenu::button( "Take", &give_points_selected, -1 );
	self offmenu::toggle( "Lock Points", "lockpts", &toggle_lock_points );

	self offmenu::card( 3, "Weapon" );
	self offmenu::stat( "Holding", &st_holding );
	self offmenu::button( "Pack-a-Punch", &pap_current );
	self offmenu::button( "Un-Pack", &unpap_current );
	self offmenu::button( "Drop Weapon", &drop_current );
	self offmenu::button( "Take Weapon", &take_current );

	self offmenu_common::build_movement( "player" );
	self offmenu_common::build_camera( "player" );
	self offmenu_overlay::build_page( "player", "Flash On New Round" );
	self offmenu_common::build_position( "player", "position", "Position" );
}

function private toggle_ignoreme( on, key )
{
	self.ignoreme = on;
}

function private toggle_auto_revive( on, key )
{
	self notify( "offm_autorevive_end" );
	if ( on )
		self thread auto_revive_loop();
}

function private auto_revive_loop()
{
	self endon( "disconnect" );
	self endon( "offm_autorevive_end" );
	for ( ;; )
	{
		self waittill( "player_downed" );
		wait 1;
		if ( self laststand::player_is_in_laststand() )
			self zm_laststand::auto_revive( self );
	}
}

function private give_points_selected( sign )
{
	amount = self offmenu::get_value( "pts_amt" );
	if ( sign > 0 )
		self zm_score::add_to_player_score( amount );
	else
		self zm_score::minus_to_player_score( int( min( amount, self.score ) ) );
}

function private toggle_lock_points( on, key )
{
	self notify( "offm_lockpts_end" );
	if ( on )
		self thread lock_points_loop( self.score );
}

function private lock_points_loop( value )
{
	self endon( "disconnect" );
	self endon( "offm_lockpts_end" );
	for ( ;; )
	{
		if ( self.score < value )
			self zm_score::add_to_player_score( value - self.score, false );
		wait 0.1;
	}
}

// ---- Weapons ---------------------------------------------------------------

function private build_weapons_tab()
{
	self offmenu::tab( "weapons", "Weapons" );
	cats = array( "ar", "smg", "shotgun", "lmg", "sniper", "pistol", "launcher", "wonder" );
	labels = array( "Assault Rifles", "SMGs", "Shotguns", "LMGs", "Snipers", "Pistols", "Launchers", "Wonder Weapons" );
	for ( i = 0; i < cats.size; i++ )
	{
		self offmenu::side( "weapons", cats[ i ], labels[ i ], &fill_weapon_page );
		self.offm.b_side.cat = cats[ i ];
		self.offm.b_side.cat_label = labels[ i ];
	}

	self offmenu::side( "weapons", "upgrades", "Upgrades" );
	self offmenu::card( 0, "Current Weapon" );
	self offmenu::stat( "Holding", &st_holding );
	self offmenu::stat( "Upgraded", &st_upgraded );
	self offmenu::button( "Pack-a-Punch", &pap_current );
	self offmenu::button( "Un-Pack", &unpap_current );
	self offmenu::card( 1, "Alt Ammo" );
	self offmenu::choice( "Type", "aat", aat_names(), aat_labels(), 0 );
	self offmenu::button( "Apply to Current", &apply_aat );
	self offmenu::card( 2, "All Weapons" );
	self offmenu::button( "Upgrade All", &upgrade_all );
	self offmenu::button( "Max Ammo All", &offmenu_common::max_ammo_all );
	self offmenu::button( "Take All Weapons", &take_all, undefined, undefined, true );

	self offmenu_camo::build_side( "weapons" );
}

// Weapons > Camo off: upgraded weapons get their Pack-a-Punch camo back
function private default_weapon_options( w )
{
	return self zm_weapons::get_pack_a_punch_weapon_options( w );
}

function private aat_names()  { return array( "zm_aat_blast_furnace", "zm_aat_dead_wire", "zm_aat_fire_works", "zm_aat_thunder_wall", "zm_aat_turned" ); }
function private aat_labels() { return array( "Blast Furnace", "Dead Wire", "Fireworks", "Thunder Wall", "Turned" ); }

function private weapon_category( w, entry )
{
	if ( isdefined( entry ) && IS_TRUE( entry.is_wonder_weapon ) )
		return "wonder";
	n = w.name;
	foreach ( prefix in array( "ar", "smg", "shotgun", "lmg", "sniper", "pistol", "launcher" ) )
	{
		if ( GetSubStr( n, 0, prefix.size + 1 ) == prefix + "_" )
			return prefix;
	}
	switch ( n )
	{
		case "ray_gun":
		case "raygun_mark2":
		case "raygun_mark3":
		case "tesla_gun":
		case "thundergun":
		case "idgun_0":
		case "idgun_1":
		case "idgun_2":
		case "idgun_3":
		case "octobomb":
			return "wonder";
	}
	return undefined;
}

// Builds a weapon category page from the weapons this map registered.
function private fill_weapon_page()
{
	s = self.offm.b_side;
	group = "w_" + s.cat;

	self offmenu::card( 0, s.cat_label );
	count = 0;
	// Keyed by weapon: iterate the keys like the stock magic box does (foreach over the table itself errors).
	foreach ( w in GetArrayKeys( level.zombie_weapons ) )
	{
		entry = level.zombie_weapons[ w ];
		if ( !isdefined( w ) || w == level.weaponNone || zm_weapons::is_weapon_upgraded( w ) )
			continue;
		if ( weapon_category( w, entry ) !== s.cat )
			continue;
		self offmenu::item( weapon_label( w.name ), &select_weapon, w, group, w.name );
		count++;
	}
	if ( count == 0 )
		self offmenu::note( "None on this map." );

	self offmenu::card( 1, "Give" );
	self offmenu::button( "Give", &give_selected, group, false );
	self offmenu::button( "Give Upgraded", &give_selected, group, true );
	self offmenu::toggle( "Replace Current Weapon", "w_replace", &offmenu_common::noop_toggle, false );
	self offmenu::toggle( "Switch To It", "w_switch", &offmenu_common::noop_toggle, false );

	self offmenu::card( 2, "Pack-a-Punch" );
	self offmenu::choice( "Alt Ammo", "aat_give", array_insert_front( aat_names(), "random" ), array_insert_front( aat_labels(), "Random" ), 0 );
	self offmenu::note( "Used when giving the upgraded one." );

	self offmenu::card( 3, "Current Loadout" );
	self offmenu::stat( "Slot 1", &st_slot_1 );
	self offmenu::stat( "Slot 2", &st_slot_2 );
	self offmenu::stat( "Slot 3", &st_slot_3 );
	self offmenu::button( "Drop Current", &drop_current );
	self offmenu::button( "Take Current", &take_current );

	if ( !isdefined( self.offm_state[ "w_defaults" ] ) )
	{
		self.offm_state[ "w_defaults" ] = true;
		self.offm_state[ "w_replace" ] = true;
		self.offm_state[ "w_switch" ] = true;
	}
}

function private array_insert_front( arr, x )
{
	out = array( x );
	foreach ( a in arr )
		out[ out.size ] = a;
	return out;
}

function private select_weapon( w )
{
	self.offm_sel_weapon = w;
}

function private give_selected( group, upgraded )
{
	w = self.offm_sel_weapon;
	if ( !isdefined( w ) )
		return;
	if ( upgraded )
	{
		up = zm_weapons::get_upgrade_weapon( w, zm_weapons::weapon_supports_attachments( w ) );
		if ( isdefined( up ) && up != level.weaponNone )
			w = up;
	}
	if ( self offmenu::get_state( "w_replace" ) && self GetWeaponsListPrimaries().size >= zm_utility_max_weapons() )
		self TakeWeapon( self GetCurrentWeapon() );
	self zm_weapons::weapon_give( w, upgraded, false, true, self offmenu::get_state( "w_switch" ) );

	if ( upgraded )
	{
		aat = self offmenu::get_value( "aat_give" );
		if ( aat !== "random" )
			self aat::acquire( w, aat );
		else
			self aat::acquire( w );
	}
}

function private zm_utility_max_weapons()
{
	return offmenu::pick( self HasPerk( "specialty_additionalprimaryweapon" ), 3, 2 );
}

function private weapon_label( n )
{
	switch ( n )
	{
		case "ar_standard":       return "KN-44";
		case "ar_accurate":       return "ICR-1";
		case "ar_cqb":            return "HVK-30";
		case "ar_damage":         return "Man-O-War";
		case "ar_marksman":       return "Sheiva";
		case "ar_longburst":      return "M8A7";
		case "ar_fastburst":      return "XR-2";
		case "ar_peacekeeper":    return "Peacekeeper MK2";
		case "ar_famas":          return "FFAR";
		case "ar_garand":         return "MX Garand";
		case "ar_m14":            return "M14";
		case "ar_m16":            return "M16";
		case "ar_galil":          return "Galil";
		case "ar_an94":           return "AN-94";
		case "smg_standard":      return "Kuda";
		case "smg_versatile":     return "VMP";
		case "smg_fastfire":      return "Vesper";
		case "smg_burst":         return "Pharo";
		case "smg_capacity":      return "Razorback";
		case "smg_longrange":     return "Weevil";
		case "smg_mp40":          return "MP40";
		case "smg_ppsh":          return "PPSh-41";
		case "smg_thompson":      return "M1927";
		case "smg_ak74u":         return "AK-74u";
		case "smg_sten":
		case "smg_sten2":         return "Sten";
		case "shotgun_pump":      return "KRM-262";
		case "shotgun_semiauto":  return "205 Brecci";
		case "shotgun_fullauto":  return "Haymaker 12";
		case "shotgun_precision": return "Argus";
		case "shotgun_energy":    return "Banshii";
		case "lmg_light":         return "BRM";
		case "lmg_cqb":           return "Dingo";
		case "lmg_slowfire":      return "Gorgon";
		case "lmg_heavy":         return "48 Dredge";
		case "lmg_rpk":           return "RPK";
		case "sniper_fastbolt":   return "Locus";
		case "sniper_fastsemi":   return "Drakon";
		case "sniper_powerbolt":  return "SVG-100";
		case "pistol_standard":   return "MR6";
		case "pistol_burst":      return "RK5";
		case "pistol_fullauto":   return "L-CAR 9";
		case "pistol_shotgun":    return "Marshal 16";
		case "pistol_revolver38": return "Bloodhound";
		case "pistol_energy":     return "Rift E9";
		case "pistol_m1911":      return "1911";
		case "launcher_standard": return "XM-53";
		case "launcher_multi":    return "L4 Siege";
		case "ray_gun":           return "Ray Gun";
		case "raygun_mark2":      return "Ray Gun Mark II";
		case "raygun_mark3":      return "GKZ-45 Mk3";
		case "tesla_gun":         return "Wunderwaffe DG-2";
		case "thundergun":        return "Thundergun";
		case "octobomb":          return "Li'l Arnie";
	}
	return n;
}

function private st_holding()
{
	w = self GetCurrentWeapon();
	if ( !isdefined( w ) || w == level.weaponNone )
		return "-";
	base = zm_weapons::get_base_weapon( w );
	if ( isdefined( base ) )
		return weapon_label( base.name );
	return weapon_label( w.name );
}

function private st_upgraded()
{
	return offmenu::pick( zm_weapons::is_weapon_upgraded( self GetCurrentWeapon() ), "Yes", "No" );
}

function private slot_label( i )
{
	list = self GetWeaponsListPrimaries();
	if ( i >= list.size )
		return "Empty";
	base = zm_weapons::get_base_weapon( list[ i ] );
	if ( isdefined( base ) )
		return weapon_label( base.name );
	return weapon_label( list[ i ].name );
}
function private st_slot_1() { return self slot_label( 0 ); }
function private st_slot_2() { return self slot_label( 1 ); }
function private st_slot_3() { return self slot_label( 2 ); }

function pap_current()
{
	w = self GetCurrentWeapon();
	if ( zm_weapons::is_weapon_upgraded( w ) )
		return;
	up = zm_weapons::get_upgrade_weapon( w, zm_weapons::weapon_supports_attachments( w ) );
	if ( !isdefined( up ) || up == level.weaponNone )
		return;
	self TakeWeapon( w );
	self zm_weapons::weapon_give( up, true, false, true, true );
	self aat::acquire( up );
}

function private unpap_current()
{
	w = self GetCurrentWeapon();
	base = zm_weapons::get_base_weapon( w );
	if ( !isdefined( base ) || base == w )
		return;
	self TakeWeapon( w );
	self zm_weapons::weapon_give( base, false, false, true, true );
}

function private apply_aat()
{
	w = self GetCurrentWeapon();
	if ( zm_weapons::is_weapon_upgraded( w ) )
		self aat::acquire( w, self offmenu::get_value( "aat" ) );
}

function private upgrade_all()
{
	foreach ( w in self GetWeaponsListPrimaries() )
	{
		if ( zm_weapons::is_weapon_upgraded( w ) )
			continue;
		up = zm_weapons::get_upgrade_weapon( w, zm_weapons::weapon_supports_attachments( w ) );
		if ( !isdefined( up ) || up == level.weaponNone )
			continue;
		self TakeWeapon( w );
		self zm_weapons::weapon_give( up, true, false, true, false );
		self aat::acquire( up );
	}
}

function private take_all()
{
	foreach ( w in self GetWeaponsListPrimaries() )
		self TakeWeapon( w );
}

function private drop_current()
{
	self dropItem( self GetCurrentWeapon() );
}

function private take_current()
{
	self TakeWeapon( self GetCurrentWeapon() );
}

// ---- Zombies ---------------------------------------------------------------

function private build_zombies_tab()
{
	self offmenu::tab( "zombies", "Zombies" );

	self offmenu::side( "zombies", "points", "Points" );
	self offmenu::card( 0, "Points" );
	self offmenu::stat( "Current", &st_points );
	self offmenu::choice( "Amount", "pts_amt", array( 1000, 10000, 100000, 1000000 ), array( "1,000", "10,000", "100,000", "1,000,000" ), 1 );
	self offmenu::button( "Give", &give_points_selected, 1 );
	self offmenu::button( "Take", &give_points_selected, -1 );
	self offmenu::toggle( "Lock Points", "lockpts", &toggle_lock_points );
	self offmenu::card( 1, "Presets" );
	self offmenu::button( "+1,000", &add_points, 1000 );
	self offmenu::button( "+10,000", &add_points, 10000 );
	self offmenu::button( "+100,000", &add_points, 100000 );
	self offmenu::button( "+1,000,000", &add_points, 1000000 );
	self offmenu::button( "Reset to 500", &reset_points );
	self offmenu::card( 2, "Team" );
	self offmenu::button( "Give Amount to Everyone", &give_team_points );
	self offmenu::toggle( "Double Points Always", "perma_dp", &toggle_perma_double_points, false );
	self offmenu::card( 3, "Stats" );
	self offmenu::stat( "Kills", &st_kills );
	self offmenu::stat( "Headshots", &st_headshots );
	self offmenu::stat( "Downs", &st_downs );

	self offmenu::side( "zombies", "perks", "Perks", &fill_perks );

	self offmenu::side( "zombies", "bgb", "Gobblegums" );
	self offmenu::card( 0, "Classic" );
	foreach ( g in bgb_classic() )
		self offmenu::item( bgb_label( g ), &select_bgb, g, "bgb", g );
	self offmenu::card( 1, "Mega" );
	foreach ( g in bgb_mega() )
		self offmenu::item( bgb_label( g ), &select_bgb, g, "bgb", g );
	self offmenu::card( 2, "Give" );
	self offmenu::button( "Give Selected", &give_selected_bgb );
	self offmenu::button( "Give Last Again", &give_last_bgb );
	self offmenu::note( "Selected gum goes in your gum slot." );

	self offmenu::side( "zombies", "powerups", "Power-Ups", &fill_powerups );

	self offmenu::side( "zombies", "rounds", "Rounds" );
	self offmenu::card( 0, "Round" );
	self offmenu::stat( "Current", &st_round );
	self offmenu::choice( "Jump To", "round_to", array( 5, 10, 15, 20, 25, 30, 40, 50, 75, 100 ), array( "5", "10", "15", "20", "25", "30", "40", "50", "75", "100" ), 5 );
	self offmenu::button( "Apply", &jump_to_round );
	self offmenu::button( "Skip 1", &skip_rounds, 1 );
	self offmenu::button( "Skip 5", &skip_rounds, 5 );
	self offmenu::card( 1, "Zombies" );
	self offmenu::button( "Kill All Zombies", &kill_all_zombies );
	self offmenu::toggle( "Stop Spawning", "nospawn", &toggle_spawning, false );
	self offmenu::toggle( "Freeze Zombies", "freezezm", &toggle_freeze_zombies, false );
	self offmenu::toggle( "One-Hit Zombies", "onehit", &toggle_one_hit, false );
	self offmenu::choice( "Zombie Speed", "zm_speed", array( "default", "walk", "run", "sprint", "super_sprint" ), array( "Default", "Walk", "Run", "Sprint", "Super Sprint" ), 0, &set_zombie_speed );
	self offmenu::card( 2, "Live" );
	self offmenu::stat( "Zombies Left", &st_left );
	self offmenu::stat( "Alive Now", &st_alive_zombies );
	self offmenu::stat( "Round Time", &st_round_time );

	self offmenu::side( "zombies", "map", "Map" );
	self offmenu::card( 0, "Power" );
	self offmenu::button( "Turn On Power", &power_on );
	self offmenu::stat( "State", &st_power );
	self offmenu::card( 1, "Doors" );
	self offmenu::button( "Open All Doors & Debris", &open_all_doors );
	self offmenu::toggle( "Free Doors", "freedoors", &toggle_free_doors, false );
	self offmenu::card( 2, "Mystery Box" );
	self offmenu::toggle( "Free Mystery Box", "freebox", &toggle_free_box, false );
	self offmenu::button( "Start Fire Sale", &spawn_powerup_named, "fire_sale" );
	self offmenu::card( 3, "Pack-a-Punch" );
	self offmenu::toggle( "Free Pack-a-Punch", "freepap", &toggle_free_pap, false );
	self offmenu::button( "Teleport to Pack-a-Punch", &tele_pap );
}

function private add_points( n )   { self zm_score::add_to_player_score( n ); }
function private st_downs()        { return int( self.downs ); }

function private reset_points()
{
	self zm_score::minus_to_player_score( self.score );
	self zm_score::add_to_player_score( 500 );
}

function private give_team_points()
{
	amount = self offmenu::get_value( "pts_amt" );
	foreach ( p in GetPlayers() )
		p zm_score::add_to_player_score( amount );
}

function private toggle_perma_double_points( on, key )
{
	level notify( "offm_dp_end" );
	if ( on )
		level thread perma_zombie_var( "zombie_point_scalar", 2, "offm_dp_end" );
	else
		level.zombie_vars[ "allies" ][ "zombie_point_scalar" ] = 1;
}

function private perma_zombie_var( name, value, end_note )
{
	level endon( end_note );
	for ( ;; )
	{
		level.zombie_vars[ "allies" ][ name ] = value;
		wait 0.5;
	}
}

// Perks: state comes from HasPerk every time the page opens.
function private fill_perks()
{
	perks = [];
	if ( isdefined( level._custom_perks ) )
		perks = GetArrayKeys( level._custom_perks );

	half = int( ( perks.size + 1 ) / 2 );
	for ( i = 0; i < perks.size; i++ )
	{
		if ( i == 0 )
			self offmenu::card( 0, "Perks" );
		else if ( i == half )
			self offmenu::card( 1, "More Perks" );
		key = "perk_" + perks[ i ];
		self.offm_state[ key ] = self HasPerk( perks[ i ] );
		r = self offmenu::toggle( perk_label( perks[ i ] ), key, &toggle_perk, false );
		r.perk = perks[ i ];
	}
	if ( perks.size == 0 )
	{
		self offmenu::card( 0, "Perks" );
		self offmenu::note( "This map has no perks." );
	}

	self offmenu::card( 2, "Actions" );
	self offmenu::button( "Give All", &give_all_perks );
	self offmenu::button( "Remove All", &remove_all_perks );
	self offmenu::toggle( "No Perk Limit", "noperklimit", &toggle_no_perk_limit, false );
	self offmenu::toggle( "Keep Perks When Downed", "keepperks", &toggle_keep_perks );
}

function private toggle_perk( on, key )
{
	perk = GetSubStr( key, 5 );
	if ( on && !self HasPerk( perk ) )
		self zm_perks::give_perk( perk, false );
	else if ( !on && self HasPerk( perk ) )
		self notify( perk + "_stop" );
}

function perk_label( perk )
{
	switch ( perk )
	{
		case "specialty_armorvest":               return "Juggernog";
		case "specialty_quickrevive":             return "Quick Revive";
		case "specialty_fastreload":              return "Speed Cola";
		case "specialty_doubletap2":              return "Double Tap";
		case "specialty_staminup":                return "Stamin-Up";
		case "specialty_deadshot":                return "Deadshot Daiquiri";
		case "specialty_additionalprimaryweapon": return "Mule Kick";
		case "specialty_widowswine":              return "Widow's Wine";
		case "specialty_electriccherry":          return "Electric Cherry";
		case "specialty_phdflopper":              return "PhD Flopper";
		case "specialty_tombstone":               return "Tombstone";
		case "specialty_whoswho":                 return "Who's Who";
		case "specialty_vultureaid":              return "Vulture Aid";
	}
	return perk;
}

function give_all_perks()
{
	if ( !isdefined( level._custom_perks ) )
		return;
	level.perk_purchase_limit = 99;
	foreach ( perk in GetArrayKeys( level._custom_perks ) )
	{
		if ( !self HasPerk( perk ) )
		{
			self zm_perks::give_perk( perk, false );
			WAIT_SERVER_FRAME;
		}
	}
}

function private remove_all_perks()
{
	if ( !isdefined( level._custom_perks ) )
		return;
	foreach ( perk in GetArrayKeys( level._custom_perks ) )
	{
		if ( self HasPerk( perk ) )
			self notify( perk + "_stop" );
	}
}

function private toggle_no_perk_limit( on, key )
{
	if ( on )
	{
		level.offm_old_perk_limit = level.perk_purchase_limit;
		level.perk_purchase_limit = 99;
	}
	else if ( isdefined( level.offm_old_perk_limit ) )
	{
		level.perk_purchase_limit = level.offm_old_perk_limit;
	}
}

function private toggle_keep_perks( on, key )
{
	self notify( "offm_keepperks_end" );
	if ( on )
		self thread keep_perks_loop();
}

function private keep_perks_loop()
{
	self endon( "disconnect" );
	self endon( "offm_keepperks_end" );
	for ( ;; )
	{
		owned = [];
		foreach ( perk in GetArrayKeys( level._custom_perks ) )
		{
			if ( self HasPerk( perk ) )
				owned[ owned.size ] = perk;
		}
		self waittill( "player_downed" );
		self waittill( "player_revived" );
		wait 0.5;
		foreach ( perk in owned )
		{
			if ( !self HasPerk( perk ) )
			{
				self zm_perks::give_perk( perk, false );
				WAIT_SERVER_FRAME;
			}
		}
	}
}

// Gobblegums (names from the game; the gum system itself is closed so these are tested in game)
function private bgb_classic()
{
	return array( "zm_bgb_always_done_swiftly", "zm_bgb_arms_grace", "zm_bgb_coagulant", "zm_bgb_in_plain_sight",
		"zm_bgb_stock_option", "zm_bgb_sword_flay", "zm_bgb_tone_death", "zm_bgb_alchemical_antithesis",
		"zm_bgb_anywhere_but_here", "zm_bgb_armamental_accomplishment", "zm_bgb_firing_on_all_cylinders" );
}

function private bgb_mega()
{
	return array( "zm_bgb_perkaholic", "zm_bgb_shopping_free", "zm_bgb_near_death_experience", "zm_bgb_reign_drops",
		"zm_bgb_round_robbin", "zm_bgb_unbearable", "zm_bgb_wall_power", "zm_bgb_crate_power",
		"zm_bgb_power_vacuum", "zm_bgb_secret_shopper", "zm_bgb_soda_fountain" );
}

function private bgb_label( name )
{
	return offmenu_zm_util_pretty( GetSubStr( name, 7 ) );
}

function private select_bgb( g )
{
	self.offm_sel_bgb = g;
}

function private give_selected_bgb()
{
	if ( isdefined( self.offm_sel_bgb ) )
	{
		self.offm_last_bgb = self.offm_sel_bgb;
		self bgb::give( self.offm_sel_bgb );
	}
}

function private give_last_bgb()
{
	if ( isdefined( self.offm_last_bgb ) )
		self bgb::give( self.offm_last_bgb );
}

// "always_done_swiftly" -> "Always Done Swiftly"
function offmenu_zm_util_pretty( name )
{
	out = "";
	foreach ( part in StrTok( name, "_" ) )
	{
		if ( out != "" )
			out += " ";
		out += ToUpper( GetSubStr( part, 0, 1 ) ) + GetSubStr( part, 1 );
	}
	return out;
}

// Power-ups
function private fill_powerups()
{
	self offmenu::card( 0, "Spawn" );
	names = [];
	if ( isdefined( level.zombie_powerups ) )
		names = GetArrayKeys( level.zombie_powerups );
	half = int( ( names.size + 1 ) / 2 );
	for ( i = 0; i < names.size; i++ )
	{
		if ( i == half )
			self offmenu::card( 1, "More" );
		self offmenu::button( powerup_label( names[ i ] ), &spawn_powerup_named, names[ i ] );
	}
	self offmenu::card( 2, "Settings" );
	self offmenu::choice( "Spawn At", "pu_at", array( "crosshair", "me" ), array( "Crosshair", "On Me" ), 0 );
	self offmenu::card( 3, "Permanent" );
	self offmenu::toggle( "Insta-Kill", "perma_ik", &toggle_perma_insta_kill, false );
	self offmenu::toggle( "Double Points", "perma_dp", &toggle_perma_double_points, false );
	self offmenu::toggle( "Fire Sale", "perma_fs", &toggle_perma_fire_sale, false );
}

function private powerup_label( n )
{
	switch ( n )
	{
		case "full_ammo":       return "Max Ammo";
		case "insta_kill":      return "Insta-Kill";
		case "double_points":   return "Double Points";
		case "nuke":            return "Nuke";
		case "carpenter":       return "Carpenter";
		case "fire_sale":       return "Fire Sale";
		case "minigun":         return "Death Machine";
		case "free_perk":       return "Free Perk";
		case "bonus_points_player":
		case "bonus_points_team": return "Bonus Points";
	}
	return offmenu_zm_util_pretty( n );
}

function private spawn_powerup_named( name )
{
	if ( self offmenu::get_value( "pu_at" ) === "me" )
	{
		pos = self.origin;
	}
	else
	{
		pos = self offmenu::crosshair_trace( 400 )[ "position" ];
		if ( Distance( pos, self.origin ) > 350 )
			pos = self.origin + AnglesToForward( self GetPlayerAngles() ) * 80;
	}
	zm_powerups::specific_powerup_drop( name, pos + ( 0, 0, 30 ) );
}

function private toggle_perma_insta_kill( on, key )
{
	level notify( "offm_ik_end" );
	if ( on )
		level thread perma_zombie_var( "zombie_insta_kill", 1, "offm_ik_end" );
	else
		level.zombie_vars[ "allies" ][ "zombie_insta_kill" ] = 0;
}

function private toggle_perma_fire_sale( on, key )
{
	level notify( "offm_fs_end" );
	if ( on )
	{
		level thread spawn_fire_sale_loop();
	}
}

function private spawn_fire_sale_loop()
{
	level endon( "offm_fs_end" );
	for ( ;; )
	{
		if ( !IS_TRUE( level.zombie_vars[ "zombie_powerup_fire_sale_on" ] ) )
			level.zombie_vars[ "zombie_powerup_fire_sale_on" ] = 1;
		wait 1;
	}
}

// Rounds
function private get_zombies()
{
	return GetAITeamArray( level.zombie_team );
}

function private st_alive_zombies()
{
	return int( get_zombies().size );
}

function kill_all_zombies()
{
	foreach ( z in get_zombies() )
	{
		if ( IsAlive( z ) )
			z DoDamage( z.health + 666, z.origin, self );
	}
}

function private skip_rounds( n )
{
	// The round loop adds 1 when the current round ends, so pre-add n - 1 then end this round.
	zm::set_round_number( level.round_number + n - 1 );
	level.zombie_total = 0;
	self kill_all_zombies();
}

function private jump_to_round()
{
	target = self offmenu::get_value( "round_to" );
	zm::set_round_number( target - 1 );
	level.zombie_total = 0;
	self kill_all_zombies();
}

function private toggle_spawning( on, key )
{
	if ( on )
		level flag::clear( "spawn_zombies" );
	else
		level flag::set( "spawn_zombies" );
}

function private toggle_freeze_zombies( on, key )
{
	level notify( "offm_freeze_end" );
	if ( on )
	{
		level thread freeze_loop();
	}
	else
	{
		foreach ( z in get_zombies() )
			z SetEntityPaused( false );
	}
}

function private freeze_loop()
{
	level endon( "offm_freeze_end" );
	for ( ;; )
	{
		foreach ( z in get_zombies() )
			z SetEntityPaused( true );
		wait 0.5;
	}
}

function private toggle_one_hit( on, key )
{
	level notify( "offm_onehit_end" );
	if ( on )
		level thread one_hit_loop();
}

function private one_hit_loop()
{
	level endon( "offm_onehit_end" );
	for ( ;; )
	{
		foreach ( z in get_zombies() )
		{
			if ( IsAlive( z ) && z.health > 1 )
				z.health = 1;
		}
		wait 0.25;
	}
}

function private set_zombie_speed( speed, key )
{
	level notify( "offm_speed_end" );
	if ( speed == "default" )
	{
		foreach ( z in get_zombies() )
		{
			if ( IsAlive( z ) && isdefined( z.zombie_move_speed_override ) )
				z zombie_utility::set_zombie_run_cycle_restore_from_override();
		}
		return;
	}
	level thread zombie_speed_loop( speed );
}

function private zombie_speed_loop( speed )
{
	level endon( "offm_speed_end" );
	for ( ;; )
	{
		foreach ( z in get_zombies() )
		{
			if ( IsAlive( z ) && z.archetype === "zombie" && z.zombie_move_speed_override !== speed )
				z zombie_utility::set_zombie_run_cycle_override_value( speed );
		}
		wait 1;
	}
}

// Map
function private power_on()
{
	level flag::set( "power_on" );
	level notify( "power_on" );
	foreach ( trig in GetEntArray( "use_elec_switch", "targetname" ) )
		trig notify( "trigger", self );
}

function private st_power()
{
	return offmenu::pick( level flag::get( "power_on" ), "On", "Off" );
}

function private open_all_doors()
{
	SetDvar( "zombie_unlock_all", 1 );
	level flag::set( "power_on" );
	foreach ( type in array( "zombie_door", "zombie_airlock_buy", "zombie_debris" ) )
	{
		foreach ( t in GetEntArray( type, "targetname" ) )
		{
			t notify( "trigger", self, true );
			WAIT_SERVER_FRAME;
		}
	}
	if ( !self offmenu::get_state( "freedoors" ) )
		SetDvar( "zombie_unlock_all", 0 );
}

function private toggle_free_doors( on, key )
{
	SetDvar( "zombie_unlock_all", offmenu::pick( on, 1, 0 ) );
}

function private toggle_free_box( on, key )
{
	level notify( "offm_freebox_end" );
	if ( on )
		level thread free_box_loop();
	else if ( isdefined( level.chests ) )
	{
		foreach ( c in level.chests )
		{
			if ( isdefined( c.offm_cost ) )
				c.zombie_cost = c.offm_cost;
		}
	}
}

function private free_box_loop()
{
	level endon( "offm_freebox_end" );
	for ( ;; )
	{
		if ( isdefined( level.chests ) )
		{
			foreach ( c in level.chests )
			{
				if ( !isdefined( c.offm_cost ) && isdefined( c.zombie_cost ) && c.zombie_cost > 0 )
					c.offm_cost = c.zombie_cost;
				c.zombie_cost = 0;
			}
		}
		wait 0.5;
	}
}

function private toggle_free_pap( on, key )
{
	level notify( "offm_freepap_end" );
	if ( on )
		level thread free_pap_loop();
}

function private free_pap_loop()
{
	level endon( "offm_freepap_end" );
	for ( ;; )
	{
		foreach ( t in GetEntArray( "zm_pack_a_punch", "targetname" ) )
		{
			t.cost = 0;
			t.aat_cost = 0;
		}
		wait 0.25;
	}
}

function private tele_pap()
{
	pap = GetEntArray( "zm_pack_a_punch", "targetname" );
	if ( pap.size > 0 )
		self SetOrigin( pap[ 0 ].origin + AnglesToForward( pap[ 0 ].angles ) * 60 + ( 0, 0, 5 ) );
}

// ---- Teleport --------------------------------------------------------------

function private build_teleport_tab()
{
	self offmenu::tab( "teleport", "Teleport" );
	self offmenu_common::build_position( "teleport", "positions", "Positions" );
	self offmenu::side( "teleport", "spots", "Map Spots", &fill_spots );
	self offmenu_common::build_teleport_tools( "teleport", "All Zombies to Crosshair", &zombies_to_crosshair );
}

function private fill_spots()
{
	self offmenu::card( 0, "Machines" );
	pap = GetEntArray( "zm_pack_a_punch", "targetname" );
	if ( pap.size > 0 )
		self offmenu::item( "Pack-a-Punch", &tele_ent, pap[ 0 ], "spot", "pap" );
	if ( isdefined( level.chests ) && isdefined( level.chest_index ) && isdefined( level.chests[ level.chest_index ] ) )
		self offmenu::item( "Mystery Box", &tele_ent, level.chests[ level.chest_index ], "spot", "box" );
	foreach ( m in GetEntArray( "zombie_vending", "targetname" ) )
	{
		if ( isdefined( m.script_noteworthy ) )
			self offmenu::item( perk_label( m.script_noteworthy ), &tele_ent, m, "spot", m.script_noteworthy );
	}
	self offmenu::card( 1, "Map" );
	self offmenu::button( "Player Spawn", &offmenu_common::tele_spawn );
	sw = GetEntArray( "use_elec_switch", "targetname" );
	if ( sw.size > 0 )
		self offmenu::button( "Power Switch", &tele_ent, sw[ 0 ] );
	self offmenu::card( 2, "Note" );
	self offmenu::note( "Spots come from the map, so" );
	self offmenu::note( "custom maps work too." );
}

function private tele_ent( ent )
{
	if ( !isdefined( ent ) )
		return;
	fwd = ( 1, 0, 0 );
	if ( isdefined( ent.angles ) )
		fwd = AnglesToForward( ent.angles );
	self SetOrigin( ent.origin + fwd * 60 + ( 0, 0, 5 ) );
}

function private zombies_to_crosshair()
{
	pos = self offmenu::crosshair_trace()[ "position" ];
	foreach ( z in get_zombies() )
	{
		if ( IsAlive( z ) )
			z ForceTeleport( pos + ( RandomIntRange( -60, 60 ), RandomIntRange( -60, 60 ), 5 ) );
	}
}

// ---- World -----------------------------------------------------------------

function private build_world_tab()
{
	self offmenu_common::build_world( "world" );
	// Time page, second card
	self.offm.b_side = self.offm.tabs[ self.offm.tabs.size - 1 ].sides[ 0 ];
	self offmenu::card( 1, "Rounds" );
	self offmenu::toggle( "Pause Between Rounds", "pauserounds", &toggle_pause_rounds, false );
	self offmenu::slider( "Round Delay", "rounddelay", array( 0, 5, 10, 20, 30 ), array( "0s", "5s", "10s", "20s", "30s" ), 2, &set_round_delay );
	offmenu_fun_filters_side( self );
}

function private toggle_pause_rounds( on, key )
{
	// Holds the next round by keeping zombie spawning off and the count at zero until turned off.
	self toggle_spawning( on, key );
	self.offm_state[ "nospawn" ] = on;
}

function private set_round_delay( value, key )
{
	level.zombie_vars[ "zombie_between_round_time" ] = value;
}

// ---- Lobby -----------------------------------------------------------------

function private build_lobby_tab()
{
	self offmenu::tab( "lobby", "Lobby" );
	self offmenu_common::build_players( "lobby" );

	self offmenu::side( "lobby", "session", "Session" );
	self offmenu::card( 0, "Game" );
	self offmenu::button( "Restart Map", &restart_map );
	self offmenu::button( "End Game", &end_game, undefined, undefined, true );
	self offmenu::card( 1, "Menu" );
	self offmenu::toggle( "Hide Welcome Hint", "nohint", &offmenu_common::noop_toggle, false );
	self offmenu::button( "Run Self-Test", &offmenu::selftest );
	self offmenu::card( 2, "Info" );
	self offmenu::stat( "Mode", &st_mode );
	self offmenu::stat( "Map", &st_map );
	self offmenu::stat( "Session", &st_session );
}

function private st_mode()    { return offmenu::pick( GetPlayers().size > 1, "Zombies - Co-op", "Zombies - Solo" ); }
function private st_session() { return offmenu::pick( SessionModeIsOnlineGame(), "Private", "Offline" ); }

function private restart_map()
{
	self offmenu::close_menu();
	map_restart( false );
}

function private end_game()
{
	self offmenu::close_menu();
	level notify( "end_game" );
}

function private player_extra()
{
	self offmenu::button( "Revive", &p_revive );
	self offmenu::button( "Give 10,000 Points", &p_points, 10000 );
	self offmenu::button( "Give All Perks", &p_perks );
}

function private p_revive()
{
	t = self offmenu_common::get_target();
	if ( t laststand::player_is_in_laststand() )
		t zm_laststand::auto_revive( self );
}

function private p_points( n )
{
	self offmenu_common::get_target() zm_score::add_to_player_score( n );
}

function private p_perks()
{
	self offmenu_common::get_target() thread give_all_perks();
}

// ---------------------------------------------------------------------------
// Lua menu bridge (orders must match ui/synthex/synthex_spec.lua)
// ---------------------------------------------------------------------------

function private weapon_names()
{
	return array( "ar_standard", "ar_accurate", "ar_cqb", "ar_damage", "ar_marksman", "ar_longburst", "ar_fastburst", "ar_peacekeeper",
		"ar_famas", "ar_garand", "ar_m14", "ar_m16", "ar_galil", "ar_an94",
		"smg_standard", "smg_versatile", "smg_fastfire", "smg_burst", "smg_capacity", "smg_longrange", "smg_mp40", "smg_ppsh",
		"smg_thompson", "smg_ak74u", "smg_sten",
		"shotgun_pump", "shotgun_semiauto", "shotgun_fullauto", "shotgun_precision", "shotgun_energy",
		"lmg_light", "lmg_cqb", "lmg_slowfire", "lmg_heavy", "lmg_rpk",
		"sniper_fastbolt", "sniper_fastsemi", "sniper_powerbolt",
		"pistol_standard", "pistol_burst", "pistol_fullauto", "pistol_shotgun", "pistol_revolver38", "pistol_energy", "pistol_m1911",
		"launcher_standard", "launcher_multi",
		"ray_gun", "raygun_mark2", "raygun_mark3", "tesla_gun", "thundergun", "octobomb", "idgun_0" );
}

function private perk_names()
{
	return array( "specialty_armorvest", "specialty_quickrevive", "specialty_fastreload", "specialty_doubletap2", "specialty_staminup",
		"specialty_deadshot", "specialty_additionalprimaryweapon", "specialty_widowswine", "specialty_electriccherry",
		"specialty_phdflopper", "specialty_tombstone", "specialty_whoswho", "specialty_vultureaid" );
}

function private powerup_names()
{
	return array( "full_ammo", "insta_kill", "double_points", "nuke", "carpenter", "fire_sale", "minigun", "free_perk",
		"bonus_points_player", "bonus_points_team", "shield_charge", "ww_grenade" );
}

function private base_name( w )
{
	if ( !isdefined( w ) || w == level.weaponNone )
		return undefined;
	base = zm_weapons::get_base_weapon( w );
	if ( isdefined( base ) )
		return base.name;
	return w.name;
}

function private esp_nearest_code()
{
	if ( !isdefined( self.offm_esp_live ) || !isdefined( self.offm_esp_live.nearest ) )
		return 0;
	switch ( self.offm_esp_live.nearest.cls )
	{
		case "reg":   return 1;
		case "crawl": return 2;
		case "spec":  return 3;
		case "boss":  return 4;
	}
	return 0;
}

// sx_stats layout - see StatText() in synthex_menu.lua
function private stats_array()
{
	names = weapon_names();
	v = [];
	v[ 0 ] = int( level.round_number );
	v[ 1 ] = int( self.score );
	v[ 2 ] = int( self.kills );
	v[ 3 ] = int( self.headshots );
	v[ 4 ] = int( self.downs );
	v[ 5 ] = int( zombie_utility::get_current_zombie_count() + level.zombie_total );
	v[ 6 ] = int( GetAITeamArray( level.zombie_team ).size );
	v[ 7 ] = int( ( GetTime() - level.offm_round_start ) / 1000 );
	v[ 8 ] = offmenu::pick( level flag::get( "power_on" ), 1, 0 );
	v[ 9 ] = offmenu::index_of( names, base_name( self GetCurrentWeapon() ) );
	v[ 10 ] = offmenu::pick( zm_weapons::is_weapon_upgraded( self GetCurrentWeapon() ), 1, 0 );
	prim = self GetWeaponsListPrimaries();
	for ( i = 0; i < 3; i++ )
	{
		if ( i < prim.size )
			v[ 11 + i ] = offmenu::index_of( names, base_name( prim[ i ] ) );
		else
			v[ 11 + i ] = -1;
	}
	if ( isdefined( self.offm_esp_live ) )
	{
		v[ 14 ] = int( self.offm_esp_live.tracked );
		v[ 15 ] = int( self.offm_esp_live.specials );
		v[ 16 ] = int( self.offm_esp_live.out );
	}
	else
	{
		v[ 14 ] = 0;
		v[ 15 ] = 0;
		v[ 16 ] = 0;
	}
	v[ 17 ] = self esp_nearest_code();
	v = self offmenu::shared_stats( v );
	v[ 27 ] = int( ( GetTime() - level.offm_game_start ) / 1000 );
	v[ 28 ] = st_alive();
	return v;
}

// Lists for dynamic pages (sx_list codes - see ListCodes in synthex_menu.lua)
function private page_data( tab_id, side_id )
{
	if ( tab_id == "weapons" )
	{
		names = weapon_names();
		avail = [];
		have = [];
		foreach ( w in GetArrayKeys( level.zombie_weapons ) )
		{
			if ( isdefined( w ) && w != level.weaponNone )
				have[ w.name ] = true;
		}
		for ( i = 0; i < names.size; i++ )
		{
			if ( isdefined( have[ names[ i ] ] ) )
				avail[ avail.size ] = i;
		}
		self offmenu::send_list( 1, avail );
	}
	else if ( tab_id == "zombies" && side_id == "perks" )
	{
		names = perk_names();
		avail = [];
		owned = [];
		for ( i = 0; i < names.size; i++ )
		{
			if ( isdefined( level._custom_perks ) && isdefined( level._custom_perks[ names[ i ] ] ) )
				avail[ avail.size ] = i;
			if ( self HasPerk( names[ i ] ) )
				owned[ owned.size ] = i;
		}
		self offmenu::send_list( 2, avail );
		self offmenu::send_list( 3, owned );
	}
	else if ( tab_id == "zombies" && side_id == "powerups" )
	{
		names = powerup_names();
		avail = [];
		for ( i = 0; i < names.size; i++ )
		{
			if ( isdefined( level.zombie_powerups ) && isdefined( level.zombie_powerups[ names[ i ] ] ) )
				avail[ avail.size ] = i;
		}
		self offmenu::send_list( 4, avail );
	}
	else if ( tab_id == "lobby" && side_id == "players" )
	{
		self offmenu::send_players();
	}
	else if ( tab_id == "teleport" && side_id == "spots" )
	{
		names = perk_names();
		machines = [];
		foreach ( m in GetEntArray( "zombie_vending", "targetname" ) )
		{
			i = offmenu::index_of( names, m.script_noteworthy );
			if ( i >= 0 )
				machines[ machines.size ] = i;
		}
		self offmenu::send_list( 8, machines );
		flags = [];
		if ( GetEntArray( "zm_pack_a_punch", "targetname" ).size > 0 )
			flags[ flags.size ] = 0;
		if ( isdefined( level.chests ) && isdefined( level.chest_index ) && isdefined( level.chests[ level.chest_index ] ) )
			flags[ flags.size ] = 1;
		if ( GetEntArray( "use_elec_switch", "targetname" ).size > 0 )
			flags[ flags.size ] = 2;
		self offmenu::send_list( 9, flags );
	}
}

function private item_weapon( id, group )
{
	w = GetWeapon( id );
	if ( w != level.weaponNone )
		self.offm_sel_weapon = w;
}

function private item_bgb( id, group )
{
	self.offm_sel_bgb = id;
}

function private item_player( id, group )
{
	p = offmenu::player_by_num( int( id ) );
	if ( isdefined( p ) )
		self.offm_target = p;
}

function private item_spot( id, group )
{
	switch ( id )
	{
		case "pap":
			self tele_pap();
			return;
		case "box":
			if ( isdefined( level.chests ) && isdefined( level.chests[ level.chest_index ] ) )
				self tele_ent( level.chests[ level.chest_index ] );
			return;
	}
	foreach ( m in GetEntArray( "zombie_vending", "targetname" ) )
	{
		if ( m.script_noteworthy === id )
		{
			self tele_ent( m );
			return;
		}
	}
}

function private offmenu_fun_filters_side( player )
{
	player offmenu::side( "world", "filters", "Filters" );
	player offmenu::card( 0, "Screen Filter" );
	player offmenu::choice( "Filter", "filter", array( 0, 1, 2, 3, 4, 5, 6, 7, 8, 9 ),
		array( "None", "Frost", "Glitch", "Overdrive", "Underwater", "Rain", "Radial Blur", "Speed Burst", "Static", "EMP" ), 0, &offmenu_fun::set_filter );
}
