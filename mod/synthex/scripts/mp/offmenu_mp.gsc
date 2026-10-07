// SYNTHEX.VIP - Multiplayer pages (offline / private custom games only).
// Tabs: Player, Weapons, Streaks, Teleport, Fun, World, Lobby. No ESP in multiplayer.

#using scripts\codescripts\struct;
#using scripts\shared\array_shared;
#using scripts\shared\system_shared;
#using scripts\shared\util_shared;
#using scripts\shared\bots\_bot;
#using scripts\shared\offmenu\offmenu_core;
#using scripts\shared\offmenu\offmenu_common;
#using scripts\shared\offmenu\offmenu_overlay;
#using scripts\shared\offmenu\offmenu_fun;
#using scripts\shared\offmenu\offmenu_camo;

#using scripts\mp\_util;
#using scripts\mp\gametypes\_globallogic;
#using scripts\mp\gametypes\_globallogic_utils;
#using scripts\mp\gametypes\_spawnlogic;
#using scripts\mp\killstreaks\_killstreaks;

#insert scripts\shared\shared.gsh;

#namespace offmenu_mp;

REGISTER_SYSTEM_EX( "offmenu_mp", &__init__, &__main__, array( "offmenu" ) )

function __init__()
{
	level.offm_mode_label = "Multiplayer";
	level.offm_player_extra = &player_extra;
	level.offm_ov_tags = [];
	level.offm_ov_tags[ "god" ] = "GOD";
	level.offm_ov_tags[ "ammo" ] = "AMMO";
	level.offm_ov_tags[ "uav" ] = "UAV";
	level.offm_ov_tags[ "noclip" ] = "NOCLIP";
	level.offm_ov_tags[ "invisible" ] = "INVIS";

	offmenu_overlay::add_stat( "mode", "Mode", "str", &st_mode, false );
	offmenu_overlay::add_stat( "score", "Team Score", "int", &st_team_score, true );
	offmenu_overlay::add_stat( "time", "Time Left", "timer_down", &st_time_left, true );
	offmenu_overlay::add_stat( "kills", "Kills", "int", &st_kills, true );
	offmenu_overlay::add_stat( "deaths", "Deaths", "int", &st_deaths, true );
	offmenu_overlay::add_stat( "pscore", "Your Score", "int", &st_score, false );
	offmenu_overlay::add_stat( "spec", "Specialist %", "int", &st_specialist, true );
	offmenu_overlay::add_stat( "bots", "Bots", "int", &st_bots, false );
	offmenu_overlay::add_stat( "map", "Map", "str", &st_map, false );

	offmenu::set_builder( &build );

	level.offm_gungame_ladder = &gungame_ladder;
	level.offm_stats_fn = &stats_array;
	level.offm_page_fn = &page_data;
	level.offm_item_handlers[ "w_" ] = &item_weapon;
	level.offm_item_handlers[ "hero" ] = &item_hero;
	level.offm_item_handlers[ "streak" ] = &item_streak;
	level.offm_item_handlers[ "player" ] = &item_player;
}

function __main__()
{
}

// ---------------------------------------------------------------------------
// Header + stats
// ---------------------------------------------------------------------------

function private st_mode()        { return mode_name( level.gametype ); }
function private st_map()         { return GetDvarString( "mapname" ); }
function private st_kills()       { return int( self.kills ); }
function private st_deaths()      { return int( self.deaths ); }
function private st_score()       { return int( self.score ); }
function private st_specialist()  { return int( self GadgetPowerGet( 0 ) ); }
function private st_bots()        { return get_bots().size; }

function private st_team_score()
{
	if ( level.teambased )
		return int( GetTeamScore( self.team ) );
	return int( self.score );
}

function private st_time_left()
{
	if ( !isdefined( level.timeLimit ) || level.timeLimit <= 0 )
		return 0;
	return int( globallogic_utils::getTimeRemaining() / 1000 );
}

function private mode_name( gt )
{
	switch ( gt )
	{
		case "tdm":   return "Team Deathmatch";
		case "dm":    return "Free-for-All";
		case "dom":   return "Domination";
		case "koth":  return "Hardpoint";
		case "sd":    return "Search & Destroy";
		case "conf":  return "Kill Confirmed";
		case "ctf":   return "Capture the Flag";
		case "dem":   return "Demolition";
		case "gun":   return "Gun Game";
		case "clean": return "Fracture";
		case "escort":return "Safeguard";
	}
	return gt;
}

// ---------------------------------------------------------------------------
// Tree
// ---------------------------------------------------------------------------

function build()
{
	self build_player_tab();
	self build_weapons_tab();
	self build_streaks_tab();
	self build_teleport_tab();
	self offmenu_common::build_fun( "fun",
		array( "launcher_standard", "launcher_multi", "launcher_lockonly", "hero_annihilator", "hero_pineapplegun", "hero_lightninggun" ),
		array( "XM-53", "L4 Siege", "BlackCell", "Annihilator", "War Machine", "Tempest" ) );
	self build_fun_extras();
	self build_world_tab();
	self build_lobby_tab();
}

// Fun > Arsenal / Modes / Clone, World > Filters (keys must match synthex_spec.lua)
function private build_fun_extras()
{
	self offmenu::side( "fun", "arsenal", "Arsenal" );
	self offmenu::card( 0, "Airstrike" );
	self offmenu::button( "Call Airstrike", &offmenu_fun::call_airstrike );
	self offmenu::choice( "Rockets", "strike_n", array( 3, 6, 10 ), array( "3", "6", "10" ), 1 );

	self offmenu::side( "fun", "modes", "Modes" );
	self offmenu::card( 0, "Gun Game" );
	self offmenu::toggle( "Gun Game", "gungame", &offmenu_fun::toggle_gungame, false );
	self offmenu::choice( "Kills Per Weapon", "gg_kills", array( 1, 3, 5, 10 ), array( "1", "3", "5", "10" ), 1 );
	self offmenu::card( 1, "Everyone" );
	self offmenu::toggle( "Gun Game For Everyone", "gg_all", &toggle_gungame_all, false );
	self offmenu::note( "Bots climb the same ladder." );

	self offmenu::side( "fun", "clone", "Clone" );
	self offmenu::card( 0, "Clone" );
	self offmenu::button( "Spawn Clone", &offmenu_fun::spawn_clone );
	self offmenu::button( "Remove Clones", &offmenu_fun::remove_clones );
}

function private gungame_ladder()
{
	out = [];
	foreach ( n in weapon_names() )
	{
		if ( GetSubStr( n, 0, 5 ) != "hero_" && GetWeapon( n ) != level.weaponNone )
			out[ out.size ] = n;
	}
	return array::randomize( out );
}

// Gun game for every player and bot: kills advance your weapon; respawns get it back.
function private toggle_gungame_all( on, key )
{
	level notify( "offm_ggall_end" );
	if ( on )
		level thread gungame_all_loop( self );
}

function private gungame_all_loop( host )
{
	level endon( "offm_ggall_end" );
	ladder = gungame_ladder();
	if ( ladder.size == 0 )
		return;
	for ( ;; )
	{
		need = host offmenu::get_value( "gg_kills" );
		if ( !isdefined( need ) )
			need = 3;
		foreach ( p in GetPlayers() )
		{
			if ( !isdefined( p.offm_gga_idx ) )
			{
				p.offm_gga_idx = 0;
				p.offm_gga_base = p.kills;
			}
			if ( p.kills - p.offm_gga_base >= need )
			{
				p.offm_gga_base = p.kills;
				p.offm_gga_idx = ( p.offm_gga_idx + 1 ) % ladder.size;
				if ( p.offm_gga_idx == 0 )
					IPrintLnBold( p.name + " finished the Gun Game!" );
			}
			if ( IsAlive( p ) )
			{
				w = GetWeapon( ladder[ p.offm_gga_idx ] );
				if ( w != level.weaponNone && !p HasWeapon( w ) )
				{
					foreach ( pw in p GetWeaponsListPrimaries() )
						p TakeWeapon( pw );
					p GiveWeapon( w );
					p GiveMaxAmmo( w );
					p SwitchToWeapon( w );
				}
			}
		}
		wait 0.5;
	}
}

// ---- Player ----------------------------------------------------------------

function private build_player_tab()
{
	self offmenu::tab( "player", "Player" );

	self offmenu::side( "player", "general", "General" );
	self offmenu::card( 0, "Survival" );
	self offmenu::toggle( "God Mode", "god", &offmenu_common::toggle_god );
	self offmenu::toggle( "Demi-God", "demigod", &offmenu_common::toggle_demigod, undefined, "never dies" );
	self offmenu::toggle( "Always UAV", "uav", &toggle_uav );
	self offmenu::toggle( "Invisible", "invisible", &offmenu_common::toggle_invisible );
	self offmenu::toggle( "Instant Respawn", "instaspawn", &toggle_instant_respawn, false );
	self offmenu::card( 0, "Quick Actions" );
	self offmenu::button( "Max Ammo", &offmenu_common::max_ammo_all );
	self offmenu::button( "Full Health", &offmenu_common::full_health );
	self offmenu::button( "Full Specialist", &full_specialist );
	self offmenu::button( "Suicide", &offmenu_common::suicide, undefined, undefined, true );

	self offmenu::card( 1, "Ammo" );
	self offmenu::toggle( "Infinite Ammo", "ammo", &offmenu_common::toggle_ammo );
	self offmenu::toggle( "Infinite Equipment", "equip", &offmenu_common::toggle_equipment );
	self offmenu::toggle( "Infinite Specialist", "hero", &offmenu_common::toggle_gadget_power );
	self offmenu::choice( "Ammo Mode", "ammomode", array( "clip", "stock" ), array( "Clip + Stock", "Stock Only" ), 0 );
	self offmenu::card( 1, "Health" );
	self offmenu::slider( "Max Health", "maxhp", array( 100, 150, 250, 500, 1000 ), array( "100", "150", "250", "500", "1000" ), 0, &offmenu_common::set_max_health );
	self offmenu::choice( "Regen", "regen", array( 0, 5, 1000 ), array( "Normal", "Fast", "Instant" ), 0, &offmenu_common::set_regen );

	self offmenu::card( 2, "Score" );
	self offmenu::stat( "Your Score", &st_score );
	self offmenu::stat( "Kills", &st_kills );
	self offmenu::stat( "Deaths", &st_deaths );
	self offmenu::choice( "Add Score", "score_amt", array( 100, 500, 1000, 5000 ), array( "100", "500", "1,000", "5,000" ), 2 );
	self offmenu::button( "Give", &give_score );

	self offmenu::card( 3, "Weapon" );
	self offmenu::stat( "Holding", &st_holding );
	self offmenu::button( "Refill", &offmenu_common::max_ammo_all );
	self offmenu::button( "Drop Weapon", &drop_current );

	self offmenu_common::build_movement( "player" );
	self offmenu_common::build_camera( "player" );
	self offmenu_overlay::build_page( "player", "Flash On Streak" );
	self offmenu_common::build_position( "player", "position", "Position" );
}

function private toggle_uav( on, key )
{
	self SetClientUIVisibilityFlag( "g_compassShowEnemies", offmenu::pick( on, 1, 0 ) );
}

function private toggle_instant_respawn( on, key )
{
	if ( on )
	{
		level.offm_old_respawn_delay = level.playerRespawnDelay;
		level.playerRespawnDelay = 0;
	}
	else if ( isdefined( level.offm_old_respawn_delay ) )
	{
		level.playerRespawnDelay = level.offm_old_respawn_delay;
	}
}

function private full_specialist()
{
	for ( slot = 0; slot < 3; slot++ )
		self GadgetPowerSet( slot, 100 );
}

function private give_score()
{
	n = self offmenu::get_value( "score_amt" );
	self.score += n;
	self.pers[ "score" ] = self.score;
}

function private st_holding()
{
	w = self GetCurrentWeapon();
	if ( !isdefined( w ) || w == level.weaponNone )
		return "-";
	return weapon_label( w.rootWeapon.name );
}

function private drop_current()
{
	self dropItem( self GetCurrentWeapon() );
}

// ---- Weapons ---------------------------------------------------------------

function private weapon_lists()
{
	l = [];
	l[ "ar" ] = array( "ar_standard", "ar_accurate", "ar_cqb", "ar_damage", "ar_marksman", "ar_longburst", "ar_fastburst", "ar_peacekeeper", "ar_famas", "ar_garand", "ar_an94", "ar_galil", "ar_m14", "ar_m16" );
	l[ "smg" ] = array( "smg_standard", "smg_versatile", "smg_fastfire", "smg_burst", "smg_capacity", "smg_longrange", "smg_mp40", "smg_ppsh", "smg_ak74u", "smg_msmc", "smg_sten2" );
	l[ "shotgun" ] = array( "shotgun_pump", "shotgun_semiauto", "shotgun_fullauto", "shotgun_precision", "shotgun_energy", "shotgun_olympia" );
	l[ "lmg" ] = array( "lmg_light", "lmg_cqb", "lmg_slowfire", "lmg_heavy", "lmg_rpk", "lmg_infinite" );
	l[ "sniper" ] = array( "sniper_fastbolt", "sniper_fastsemi", "sniper_powerbolt", "sniper_chargeshot", "sniper_double", "sniper_quickscope", "sniper_mosin", "sniper_xpr50" );
	l[ "pistol" ] = array( "pistol_standard", "pistol_burst", "pistol_fullauto", "pistol_shotgun", "pistol_energy", "pistol_m1911" );
	l[ "launcher" ] = array( "launcher_standard", "launcher_lockonly", "launcher_multi", "launcher_ex41" );
	l[ "hero" ] = array( "hero_annihilator", "hero_gravityspikes", "hero_chemicalgelgun", "hero_flamethrower", "hero_minigun", "hero_bowlauncher", "hero_lightninggun", "hero_armblade", "hero_pineapplegun" );
	return l;
}

function private weapon_label( n )
{
	switch ( n )
	{
		case "ar_standard":        return "KN-44";
		case "ar_accurate":        return "ICR-1";
		case "ar_cqb":             return "HVK-30";
		case "ar_damage":          return "Man-O-War";
		case "ar_marksman":        return "Sheiva";
		case "ar_longburst":       return "M8A7";
		case "ar_fastburst":       return "XR-2";
		case "ar_peacekeeper":     return "Peacekeeper MK2";
		case "ar_famas":           return "FFAR";
		case "ar_garand":          return "MX Garand";
		case "ar_an94":            return "AN-94";
		case "ar_galil":           return "Galil";
		case "ar_m14":             return "M14";
		case "ar_m16":             return "M16";
		case "smg_standard":       return "Kuda";
		case "smg_versatile":      return "VMP";
		case "smg_fastfire":       return "Vesper";
		case "smg_burst":          return "Pharo";
		case "smg_capacity":       return "Razorback";
		case "smg_longrange":      return "Weevil";
		case "smg_mp40":           return "HG 40";
		case "smg_ppsh":           return "PPSh-41";
		case "smg_ak74u":          return "AK-74u";
		case "smg_msmc":           return "HLX 4";
		case "smg_sten2":          return "Sten";
		case "shotgun_pump":       return "KRM-262";
		case "shotgun_semiauto":   return "205 Brecci";
		case "shotgun_fullauto":   return "Haymaker 12";
		case "shotgun_precision":  return "Argus";
		case "shotgun_energy":     return "Banshii";
		case "shotgun_olympia":    return "Olympia";
		case "lmg_light":          return "BRM";
		case "lmg_cqb":            return "Dingo";
		case "lmg_slowfire":       return "Gorgon";
		case "lmg_heavy":          return "48 Dredge";
		case "lmg_rpk":            return "RPK";
		case "lmg_infinite":       return "R70 Ajax";
		case "sniper_fastbolt":    return "Locus";
		case "sniper_fastsemi":    return "Drakon";
		case "sniper_powerbolt":   return "SVG-100";
		case "sniper_chargeshot":  return "P-06";
		case "sniper_double":      return "Dbl Barrel";
		case "sniper_quickscope":  return "DBSR-50";
		case "sniper_mosin":       return "Mosin";
		case "sniper_xpr50":       return "XPR-50";
		case "pistol_standard":    return "MR6";
		case "pistol_burst":       return "RK5";
		case "pistol_fullauto":    return "L-CAR 9";
		case "pistol_shotgun":     return "Marshal 16";
		case "pistol_energy":      return "Rift E9";
		case "pistol_m1911":       return "1911";
		case "launcher_standard":  return "XM-53";
		case "launcher_lockonly":  return "BlackCell";
		case "launcher_multi":     return "L4 Siege";
		case "launcher_ex41":      return "Ex-41";
		case "hero_annihilator":   return "Annihilator";
		case "hero_gravityspikes": return "Gravity Spikes";
		case "hero_chemicalgelgun":return "H.I.V.E.";
		case "hero_flamethrower":  return "Purifier";
		case "hero_minigun":       return "Scythe";
		case "hero_bowlauncher":   return "Sparrow";
		case "hero_lightninggun":  return "Tempest";
		case "hero_armblade":      return "Ripper";
		case "hero_pineapplegun":  return "War Machine";
	}
	return n;
}

function private build_weapons_tab()
{
	self offmenu::tab( "weapons", "Weapons" );
	cats = array( "ar", "smg", "shotgun", "lmg", "sniper", "pistol", "launcher", "hero" );
	labels = array( "Assault Rifles", "SMGs", "Shotguns", "LMGs", "Snipers", "Pistols", "Launchers", "Specialist" );
	for ( i = 0; i < cats.size; i++ )
	{
		self offmenu::side( "weapons", cats[ i ], labels[ i ], &fill_weapon_page );
		self.offm.b_side.cat = cats[ i ];
		self.offm.b_side.cat_label = labels[ i ];
	}

	self offmenu::side( "weapons", "attach", "Attachments" );
	self offmenu::card( 0, "Optic" );
	self offmenu::choice( "Optic", "att_optic", array( "none", "reflex", "reddot", "holo", "acog", "ir", "dualoptic" ), array( "None", "Reflex", "ELO", "Holo", "Recon", "Thermal", "Varix" ), 0 );
	self offmenu::card( 1, "Attachments" );
	foreach ( a in array( "extclip", "fastreload", "grip", "quickdraw", "suppressed", "rf", "fmj", "extbarrel", "stalker", "steadyaim" ) )
		self offmenu::toggle( attachment_label( a ), "att_" + a, &offmenu_common::noop_toggle, false );
	self offmenu::card( 2, "Apply" );
	self offmenu::button( "Apply to Current", &apply_attachments );
	self offmenu::note( "Unsupported ones are skipped." );

	self offmenu_camo::build_side( "weapons" );
}

function private attachment_label( a )
{
	switch ( a )
	{
		case "extclip":    return "Extended Mags";
		case "fastreload": return "Fast Mags";
		case "grip":       return "Grip";
		case "quickdraw":  return "Quickdraw";
		case "suppressed": return "Suppressor";
		case "rf":         return "Rapid Fire";
		case "fmj":        return "FMJ";
		case "extbarrel":  return "Long Barrel";
		case "stalker":    return "Stock";
		case "steadyaim":  return "Laser Sight";
	}
	return a;
}

function private fill_weapon_page()
{
	s = self.offm.b_side;
	group = "w_" + s.cat;
	lists = weapon_lists();

	self offmenu::card( 0, s.cat_label );
	foreach ( n in lists[ s.cat ] )
	{
		if ( GetWeapon( n ) == level.weaponNone )
			continue;
		self offmenu::item( weapon_label( n ), &select_weapon, n, group, n );
	}

	self offmenu::card( 1, "Give" );
	self offmenu::button( "Give", &give_selected );
	self offmenu::button( "Give With Attachments", &give_selected_with_attachments );
	self offmenu::toggle( "Replace Current Weapon", "w_replace", &offmenu_common::noop_toggle, false );
	self offmenu::toggle( "Switch To It", "w_switch", &offmenu_common::noop_toggle, false );

	self offmenu::card( 3, "Current Loadout" );
	self offmenu::stat( "Primary", &st_primary );
	self offmenu::stat( "Secondary", &st_secondary );
	self offmenu::button( "Drop Current", &drop_current );

	if ( !isdefined( self.offm_state[ "w_defaults" ] ) )
	{
		self.offm_state[ "w_defaults" ] = true;
		self.offm_state[ "w_replace" ] = true;
		self.offm_state[ "w_switch" ] = true;
	}
}

function private select_weapon( n )
{
	self.offm_sel_weapon = n;
}

function private give_named( w )
{
	if ( w == level.weaponNone )
		return;
	if ( self offmenu::get_state( "w_replace" ) && !w.isHeroWeapon && self GetWeaponsListPrimaries().size >= 2 )
		self TakeWeapon( self GetCurrentWeapon() );
	self GiveWeapon( w );
	self GiveMaxAmmo( w );
	if ( self offmenu::get_state( "w_switch" ) )
		self SwitchToWeapon( w );
}

function private give_selected()
{
	if ( isdefined( self.offm_sel_weapon ) )
		self give_named( GetWeapon( self.offm_sel_weapon ) );
}

function private selected_attachments()
{
	atts = [];
	optic = self offmenu::get_value( "att_optic" );
	if ( optic !== "none" )
		atts[ atts.size ] = optic;
	foreach ( a in array( "extclip", "fastreload", "grip", "quickdraw", "suppressed", "rf", "fmj", "extbarrel", "stalker", "steadyaim" ) )
	{
		if ( self offmenu::get_state( "att_" + a ) )
			atts[ atts.size ] = a;
	}
	return atts;
}

// Try the full set first, then drop attachments the weapon doesn't support one by one.
function private build_weapon( name, atts )
{
	w = GetWeapon( name, atts );
	if ( w != level.weaponNone )
		return w;
	ok = [];
	foreach ( a in atts )
	{
		test = ok;
		test[ test.size ] = a;
		if ( GetWeapon( name, test ) != level.weaponNone )
			ok = test;
	}
	return GetWeapon( name, ok );
}

function private give_selected_with_attachments()
{
	if ( isdefined( self.offm_sel_weapon ) )
		self give_named( self build_weapon( self.offm_sel_weapon, self selected_attachments() ) );
}

function private apply_attachments()
{
	cur = self GetCurrentWeapon();
	if ( !isdefined( cur ) || cur == level.weaponNone || cur.isHeroWeapon )
		return;
	w = self build_weapon( cur.rootWeapon.name, self selected_attachments() );
	if ( w == level.weaponNone )
		return;
	self TakeWeapon( cur );
	self GiveWeapon( w );
	self GiveMaxAmmo( w );
	self SwitchToWeapon( w );
}

function private st_primary()
{
	list = self GetWeaponsListPrimaries();
	if ( list.size > 0 )
		return weapon_label( list[ 0 ].rootWeapon.name );
	return "Empty";
}

function private st_secondary()
{
	list = self GetWeaponsListPrimaries();
	if ( list.size > 1 )
		return weapon_label( list[ 1 ].rootWeapon.name );
	return "Empty";
}

// ---- Streaks ---------------------------------------------------------------

function private build_streaks_tab()
{
	self offmenu::tab( "streaks", "Streaks" );
	self offmenu::side( "streaks", "score", "Scorestreaks", &fill_streaks );

	self offmenu::side( "streaks", "spec", "Specialist" );
	self offmenu::card( 0, "Specialist" );
	self offmenu::stat( "Charge %", &st_specialist );
	self offmenu::button( "Full Charge", &full_specialist );
	self offmenu::toggle( "Infinite Specialist", "hero", &offmenu_common::toggle_gadget_power );
	self offmenu::card( 1, "Weapon" );
	foreach ( n in weapon_lists()[ "hero" ] )
		self offmenu::item( weapon_label( n ), &give_hero, n, "hero", n );
}

function private give_hero( n )
{
	w = GetWeapon( n );
	if ( w == level.weaponNone )
		return;
	self GiveWeapon( w );
	self GadgetPowerSet( 0, 100 );
	self SwitchToWeapon( w );
}

function private fill_streaks()
{
	names = [];
	if ( isdefined( level.killstreaks ) )
	{
		foreach ( k in GetArrayKeys( level.killstreaks ) )
		{
			if ( GetSubStr( k, 0, 10 ) != "inventory_" )
				names[ names.size ] = k;
		}
	}
	half = int( ( names.size + 1 ) / 2 );
	self offmenu::card( 0, "Scorestreaks" );
	for ( i = 0; i < names.size; i++ )
	{
		if ( i == half )
			self offmenu::card( 1, "More" );
		self offmenu::item( streak_label( names[ i ] ), &select_streak, names[ i ], "streak", names[ i ] );
	}
	self offmenu::card( 2, "Give" );
	self offmenu::button( "Give Selected", &give_selected_streak );
	self offmenu::button( "Give All", &give_all_streaks );
}

function private streak_label( n )
{
	switch ( n )
	{
		case "uav":              return "UAV";
		case "counteruav":       return "Counter-UAV";
		case "rcbomb":           return "RC-XD";
		case "remote_missile":   return "Hellstorm";
		case "planemortar":      return "Lightning Strike";
		case "satellite":        return "H.A.T.R.";
		case "supply_drop":      return "Care Package";
		case "autoturret":       return "Sentry Gun";
		case "microwave_turret": return "Guardian";
		case "raps":             return "R.A.P.S.";
		case "dart":             return "Dart";
		case "emp":              return "EMP";
	}
	out = "";
	foreach ( part in StrTok( n, "_" ) )
	{
		if ( out != "" )
			out += " ";
		out += ToUpper( GetSubStr( part, 0, 1 ) ) + GetSubStr( part, 1 );
	}
	return out;
}

function private select_streak( n )
{
	self.offm_sel_streak = n;
}

function private give_selected_streak()
{
	if ( isdefined( self.offm_sel_streak ) )
		self killstreaks::give( self.offm_sel_streak );
}

function private give_all_streaks()
{
	foreach ( k in GetArrayKeys( level.killstreaks ) )
	{
		if ( GetSubStr( k, 0, 10 ) != "inventory_" )
		{
			self killstreaks::give( k );
			WAIT_SERVER_FRAME;
		}
	}
}

// ---- Teleport --------------------------------------------------------------

function private build_teleport_tab()
{
	self offmenu::tab( "teleport", "Teleport" );
	self offmenu_common::build_position( "teleport", "positions", "Positions" );

	self offmenu::side( "teleport", "spots", "Map Spots" );
	self offmenu::card( 0, "Spawns" );
	self offmenu::button( "Allies Spawn", &tele_spawn_class, "mp_tdm_spawn_allies_start" );
	self offmenu::button( "Axis Spawn", &tele_spawn_class, "mp_tdm_spawn_axis_start" );
	self offmenu::button( "Random Spawn", &tele_spawn_class, "mp_tdm_spawn" );
	self offmenu::button( "Map Centre", &tele_center );

	self offmenu_common::build_teleport_tools( "teleport", "All Bots to Crosshair", &bots_to_crosshair );
}

function private tele_spawn_class( classname )
{
	spots = spawnlogic::get_spawnpoint_array( classname );
	if ( !isdefined( spots ) || spots.size == 0 )
		return;
	s = spots[ RandomInt( spots.size ) ];
	self SetOrigin( s.origin );
	if ( isdefined( s.angles ) )
		self SetPlayerAngles( s.angles );
}

function private tele_center()
{
	if ( isdefined( level.mapCenter ) )
		self SetOrigin( level.mapCenter + ( 0, 0, 30 ) );
}

// ---- World -----------------------------------------------------------------

function private build_world_tab()
{
	self offmenu_common::build_world( "world" );
	self.offm.b_side = self.offm.tabs[ self.offm.tabs.size - 1 ].sides[ 0 ];
	self offmenu::card( 1, "Timer" );
	self offmenu::toggle( "Pause Timer", "pausetimer", &toggle_pause_timer, false );
	self offmenu::toggle( "Unlimited Time", "unlimtime", &toggle_unlimited_time, false );

	self offmenu::side( "world", "filters", "Filters" );
	self offmenu::card( 0, "Screen Filter" );
	self offmenu::choice( "Filter", "filter", array( 0, 1, 2, 3, 4, 5, 6, 7, 8, 9 ),
		array( "None", "Frost", "Glitch", "Overdrive", "Underwater", "Rain", "Radial Blur", "Speed Burst", "Static", "EMP" ), 0, &offmenu_fun::set_filter );
	self offmenu_fun::screen_effect_rows();
}

function private toggle_pause_timer( on, key )
{
	if ( on )
		globallogic_utils::pauseTimer();
	else
		globallogic_utils::resumeTimer();
}

function private toggle_unlimited_time( on, key )
{
	if ( on )
	{
		level.offm_old_timelimit = level.timeLimit;
		level.timeLimit = 0;
	}
	else if ( isdefined( level.offm_old_timelimit ) )
	{
		level.timeLimit = level.offm_old_timelimit;
	}
}

function private toggle_unlimited_score( on, key )
{
	if ( on )
	{
		level.offm_old_scorelimit = level.scoreLimit;
		level.scoreLimit = 0;
	}
	else if ( isdefined( level.offm_old_scorelimit ) )
	{
		level.scoreLimit = level.offm_old_scorelimit;
	}
}

// ---- Lobby -----------------------------------------------------------------

function private build_lobby_tab()
{
	self offmenu::tab( "lobby", "Lobby" );
	self offmenu_common::build_players( "lobby" );

	self offmenu::side( "lobby", "bots", "Bots" );
	self offmenu::card( 0, "Add Bots" );
	self offmenu::choice( "Team", "bot_team", array( "enemy", "friendly" ), array( "Enemy", "Friendly" ), 0 );
	self offmenu::choice( "Count", "bot_count", array( 1, 3, 5, 9 ), array( "1", "3", "5", "9" ), 2 );
	self offmenu::choice( "Difficulty", "bot_diff", array( 0, 1, 2, 3 ), array( "Recruit", "Regular", "Hardened", "Veteran" ), 1, &set_bot_difficulty );
	self offmenu::button( "Add", &add_bots );
	self offmenu::card( 1, "Control" );
	self offmenu::button( "Kill All Bots", &kill_bots );
	self offmenu::button( "Bring Bots to Crosshair", &bots_to_crosshair );
	self offmenu::toggle( "Freeze Bots", "freezebots", &toggle_freeze_bots, false );
	self offmenu::button( "Kick All Bots", &kick_bots, undefined, undefined, true );
	self offmenu::card( 2, "Behaviour" );
	self offmenu::toggle( "Bots Ignore Me", "botsignore", &toggle_bots_ignore );

	self offmenu::side( "lobby", "match", "Match" );
	self offmenu::card( 0, "Timer" );
	self offmenu::toggle( "Pause Timer", "pausetimer", &toggle_pause_timer, false );
	self offmenu::toggle( "Unlimited Time", "unlimtime", &toggle_unlimited_time, false );
	self offmenu::toggle( "Unlimited Score", "unlimscore", &toggle_unlimited_score, false );
	self offmenu::card( 1, "Game" );
	self offmenu::button( "Fast Restart", &fast_restart );
	self offmenu::button( "End Game", &end_game, undefined, undefined, true );
	self offmenu::card( 2, "Menu" );
	self offmenu::toggle( "Hide Welcome Hint", "nohint", &offmenu_common::noop_toggle, false );
	self offmenu::button( "Run Self-Test", &offmenu::selftest );
	self offmenu::card( 3, "Info" );
	self offmenu::stat( "Mode", &st_mode );
	self offmenu::stat( "Map", &st_map );
	self offmenu::stat( "Session", &st_session );
}

function private st_session() { return offmenu::pick( SessionModeIsOnlineGame(), "Private", "Offline" ); }

function private set_bot_difficulty( value, key )
{
	SetDvar( "bot_difficulty", value );
}

function get_bots()
{
	out = [];
	foreach ( p in GetPlayers() )
	{
		if ( p IsTestClient() )
			out[ out.size ] = p;
	}
	return out;
}

function private add_bots()
{
	team = self.team;
	if ( self offmenu::get_value( "bot_team" ) == "enemy" )
		team = util::getOtherTeam( self.team );
	if ( !level.teambased )
		team = "free";
	n = self offmenu::get_value( "bot_count" );
	for ( i = 0; i < n; i++ )
	{
		bot::add_bot( team );
		wait 0.2;
	}
}

function private kill_bots()
{
	foreach ( b in get_bots() )
	{
		if ( IsAlive( b ) )
			b DoDamage( b.health + 1000, b.origin, self );
	}
}

function private kick_bots()
{
	foreach ( b in get_bots() )
		kick( b GetEntityNumber() );
}

function private bots_to_crosshair()
{
	pos = self offmenu::crosshair_trace()[ "position" ];
	foreach ( b in get_bots() )
	{
		if ( IsAlive( b ) )
			b SetOrigin( pos + ( RandomIntRange( -60, 60 ), RandomIntRange( -60, 60 ), 5 ) );
	}
}

function private toggle_freeze_bots( on, key )
{
	level notify( "offm_freezebots_end" );
	if ( on )
	{
		level thread freeze_bots_loop();
	}
	else
	{
		foreach ( b in get_bots() )
			b FreezeControls( false );
	}
}

function private freeze_bots_loop()
{
	level endon( "offm_freezebots_end" );
	for ( ;; )
	{
		foreach ( b in get_bots() )
			b FreezeControls( true );
		wait 0.5;
	}
}

function private toggle_bots_ignore( on, key )
{
	self.ignoreme = on;
}

function private fast_restart()
{
	self offmenu::close_menu();
	map_restart( false );
}

function private end_game()
{
	self offmenu::close_menu();
	thread globallogic::endGame( self.team, "Ended from SYNTHEX.VIP" );
}

function private player_extra()
{
	self offmenu::button( "Kick", &p_kick, undefined, undefined, true );
}

function private p_kick()
{
	t = self offmenu_common::get_target();
	if ( t != self )
		kick( t GetEntityNumber() );
}

// ---------------------------------------------------------------------------
// Lua menu bridge (orders must match ui/synthex/synthex_spec.lua)
// ---------------------------------------------------------------------------

function private weapon_names()
{
	return array( "ar_standard", "ar_accurate", "ar_cqb", "ar_damage", "ar_marksman", "ar_longburst", "ar_fastburst", "ar_peacekeeper",
		"ar_famas", "ar_garand", "ar_an94", "ar_galil", "ar_m14", "ar_m16",
		"smg_standard", "smg_versatile", "smg_fastfire", "smg_burst", "smg_capacity", "smg_longrange", "smg_mp40", "smg_ppsh",
		"smg_ak74u", "smg_msmc", "smg_sten2",
		"shotgun_pump", "shotgun_semiauto", "shotgun_fullauto", "shotgun_precision", "shotgun_energy", "shotgun_olympia",
		"lmg_light", "lmg_cqb", "lmg_slowfire", "lmg_heavy", "lmg_rpk", "lmg_infinite",
		"sniper_fastbolt", "sniper_fastsemi", "sniper_powerbolt", "sniper_chargeshot", "sniper_double", "sniper_quickscope", "sniper_mosin", "sniper_xpr50",
		"pistol_standard", "pistol_burst", "pistol_fullauto", "pistol_shotgun", "pistol_energy", "pistol_m1911",
		"launcher_standard", "launcher_lockonly", "launcher_multi", "launcher_ex41",
		"hero_annihilator", "hero_gravityspikes", "hero_chemicalgelgun", "hero_flamethrower", "hero_minigun", "hero_bowlauncher",
		"hero_lightninggun", "hero_armblade", "hero_pineapplegun" );
}

function private streak_names()
{
	return array( "uav", "rcbomb", "counteruav", "dart", "supply_drop", "remote_missile", "planemortar", "satellite", "autoturret",
		"raps", "ai_tank_drop", "combat_robot", "sentinel", "helicopter_comlink", "microwave_turret", "drone_strike", "helicopter_gunner", "emp" );
}

function private root_name( w )
{
	if ( !isdefined( w ) || w == level.weaponNone )
		return undefined;
	return w.rootWeapon.name;
}

// sx_stats layout - see StatText() in synthex_menu.lua
function private stats_array()
{
	names = weapon_names();
	v = [];
	v[ 0 ] = self st_team_score();
	v[ 1 ] = int( self.kills );
	v[ 2 ] = int( self.deaths );
	v[ 3 ] = int( self.score );
	v[ 4 ] = int( self GadgetPowerGet( 0 ) );
	v[ 5 ] = st_time_left();
	v[ 6 ] = get_bots().size;
	v[ 7 ] = offmenu::index_of( names, root_name( self GetCurrentWeapon() ) );
	prim = self GetWeaponsListPrimaries();
	v[ 8 ] = -1;
	v[ 9 ] = -1;
	if ( prim.size > 0 )
		v[ 8 ] = offmenu::index_of( names, root_name( prim[ 0 ] ) );
	if ( prim.size > 1 )
		v[ 9 ] = offmenu::index_of( names, root_name( prim[ 1 ] ) );
	for ( i = 10; i < 18; i++ )
		v[ i ] = 0;
	return self offmenu::shared_stats( v );
}

function private page_data( tab_id, side_id )
{
	if ( tab_id == "weapons" )
	{
		names = weapon_names();
		avail = [];
		for ( i = 0; i < names.size; i++ )
		{
			if ( GetWeapon( names[ i ] ) != level.weaponNone )
				avail[ avail.size ] = i;
		}
		self offmenu::send_list( 7, avail );
	}
	else if ( tab_id == "streaks" && side_id == "score" )
	{
		names = streak_names();
		avail = [];
		for ( i = 0; i < names.size; i++ )
		{
			if ( isdefined( level.killstreaks ) && isdefined( level.killstreaks[ names[ i ] ] ) )
				avail[ avail.size ] = i;
		}
		self offmenu::send_list( 6, avail );
	}
	else if ( tab_id == "lobby" && side_id == "players" )
	{
		self offmenu::send_players();
	}
}

function private item_weapon( id, group )
{
	self.offm_sel_weapon = id;
}

function private item_hero( id, group )
{
	self give_hero( id );
}

function private item_streak( id, group )
{
	self.offm_sel_streak = id;
}

function private item_player( id, group )
{
	p = offmenu::player_by_num( int( id ) );
	if ( isdefined( p ) )
		self.offm_target = p;
}
