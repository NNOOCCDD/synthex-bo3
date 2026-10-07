// SYNTHEX.VIP - universal weapon camos ("gun chams"): one camo on every gun you hold, and one on the knife.
// Uses the game's own camo table (gamedata/weapons/common/attachmentTable.csv, camo indices).

#using scripts\codescripts\struct;
#using scripts\shared\clientfield_shared;
#using scripts\shared\util_shared;
#using scripts\shared\offmenu\offmenu_core;

#insert scripts\shared\shared.gsh;

#namespace offmenu_camo;

function camo_values()
{
	return array(
		15, 16, 17, 1, 2, 3, 4, 5, 6, 7, 8, 9,
		10, 11, 12, 13, 14, 18, 19, 20, 21, 22, 23, 24,
		25, 126, 26, 75, 76, 77, 78, 79, 80, 81, 84, 86,
		88, 122, 124, 36, 38, 39, 40, 42, 43, 44, 46, 47,
		48, 49, 50, 51, 52, 53, 54, 55, 56, 57, 58, 59,
		60, 61, 62, 63, 64, 65, 66, 68, 83, 27, 28, 29,
		30, 33, 35, 45, 67, 82, 89, 119, 131, 134, 135, 136,
		137, 138, 93, 95, 96, 97, 98, 99, 103, 104, 105, 106,
		107, 109, 111, 112, 113, 116, 117 );
}

function camo_labels()
{
	return array(
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
		"CWL Rise Nation" );
}

// Weapons > Camo
function build_side( tab_id )
{
	self offmenu::side( tab_id, "camo", "Camo" );
	self offmenu::card( 0, "Guns" );
	self offmenu::toggle( "Universal Camo", "camo_on", &toggle_camo );
	self offmenu::choice( "Camo", "camo_gun", camo_values(), camo_labels(), 2, &camo_changed );
	self offmenu::note( "Every gun you hold, picked up ones too." );
	self offmenu::card( 1, "Knife" );
	self offmenu::toggle( "Knife Camo", "kcamo_on", &toggle_camo );
	self offmenu::choice( "Camo", "camo_knife", camo_values(), camo_labels(), 2, &camo_changed );
	self offmenu::note( "Only knives that take camos (MP combat knife)." );
	self offmenu::card( 2, "Gun Chams" );
	self offmenu::toggle( "Gun Chams", "gc_on", &gun_chams_changed );
	self offmenu::choice( "Style", "gc_style", array( 1, 5, 7, 8, 9 ), array( "Solid", "Rim Glow", "Hex Shimmer", "Flow", "Hacked" ), 0, &gun_chams_changed );
	self offmenu::choice( "Colour", "gc_col", array( 0, 1, 2, 3, 4, 5, 6, 7 ), array( "Pink", "Red", "Orange", "Yellow", "Green", "Cyan", "Blue", "Rainbow" ), 0, &gun_chams_changed );
	self offmenu::slider( "Rainbow Speed", "gc_speed", array( 0, 1, 2, 3 ), array( "Slow", "Normal", "Fast", "Very Fast" ), 1, &gun_chams_changed );
	self offmenu::note( "Redraws your gun and arms, plain parts too." );
}

// Gun chams: the same cham materials as the zombies, on your own player (the engine draws them on the
// first-person gun and arms, like the Active Camo specialist ability). Value = speed * 128 + style * 8 + colour.
function private gun_chams_changed( value, key )
{
	v = 0;
	if ( self offmenu::get_state( "gc_on" ) )
		v = self offmenu::get_value( "gc_speed" ) * 128 + self offmenu::get_value( "gc_style" ) * 8 + self offmenu::get_value( "gc_col" );
	self clientfield::set_to_player( "synthex_gcham", v );
}

function toggle_camo( on, key )
{
	self notify( "offm_camo_end" );
	if ( self offmenu::get_state( "camo_on" ) || self offmenu::get_state( "kcamo_on" ) )
		self thread camo_loop();
	else
		self restore_all();
}

function private camo_changed( value, key )
{
	self notify( "offm_camo_refresh" );
}

function private camo_loop()
{
	self endon( "disconnect" );
	self endon( "offm_camo_end" );
	if ( !isdefined( self.offm_camo_set ) )
		self.offm_camo_set = [];
	for ( ;; )
	{
		gun_on = self offmenu::get_state( "camo_on" );
		knife_on = self offmenu::get_state( "kcamo_on" );
		held = [];
		foreach ( w in self GetWeaponsList() )
		{
			if ( !isdefined( w ) || w == level.weaponNone )
				continue;
			if ( w.weapClass == "melee" )
				want = offmenu::pick( knife_on, self offmenu::get_value( "camo_knife" ), -1 );
			else if ( w.isPrimary )
				want = offmenu::pick( gun_on, self offmenu::get_value( "camo_gun" ), -1 );
			else
				continue;
			held[ w.name ] = true;
			if ( self.offm_camo_set[ w.name ] === want )
				continue;
			if ( want < 0 )
			{
				// switched off for this kind: put the weapon's own options back once
				if ( isdefined( self.offm_camo_set[ w.name ] ) )
					self restore( w );
				self.offm_camo_set[ w.name ] = want;
				continue;
			}
			self UpdateWeaponOptions( w, self CalcWeaponOptions( want, 0, 0, 0, 0 ) );
			self.offm_camo_set[ w.name ] = want;
		}
		// forget weapons we no longer hold (a re-bought weapon comes back with its default options)
		foreach ( name in GetArrayKeys( self.offm_camo_set ) )
		{
			if ( !isdefined( held[ name ] ) )
				self.offm_camo_set[ name ] = undefined;
		}
		self util::waittill_any_timeout( 0.5, "weapon_change", "offm_camo_refresh" );
	}
}

function private restore( w )
{
	if ( isdefined( level.offm_default_weapon_options ) )
		self UpdateWeaponOptions( w, self [[ level.offm_default_weapon_options ]]( w ) );
	else
		self UpdateWeaponOptions( w, self CalcWeaponOptions( 0, 0, 0, 0, 0 ) );
}

function private restore_all()
{
	if ( !isdefined( self.offm_camo_set ) )
		return;
	foreach ( w in self GetWeaponsList() )
	{
		if ( isdefined( w ) && isdefined( self.offm_camo_set[ w.name ] ) && self.offm_camo_set[ w.name ] >= 0 )
			self restore( w );
	}
	self.offm_camo_set = [];
}
