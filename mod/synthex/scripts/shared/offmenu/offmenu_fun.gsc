// SYNTHEX.VIP - fun features shared by zm + mp: airstrike, gun game, screen filters, clone (mp).

#using scripts\codescripts\struct;
#using scripts\shared\clientfield_shared;
#using scripts\shared\system_shared;
#using scripts\shared\util_shared;
#using scripts\shared\offmenu\offmenu_core;

#insert scripts\shared\shared.gsh;
#insert scripts\shared\version.gsh;

#namespace offmenu_fun;

REGISTER_SYSTEM( "offmenu_fun", &__init__, undefined )

function __init__()
{
	// 0 = none, 1.. = filter (see synthex_ui.csc)
	clientfield::register( "toplayer", "synthex_filter", VERSION_SHIP, 4, "int" );
	// zombie chams: style * 8 + colour (0 = off), drawn by synthex_ui.csc
	clientfield::register( "actor", "synthex_zcham", VERSION_SHIP, 7, "int" );
}

// ---------------------------------------------------------------------------
// Airstrike: rockets fall from the sky around the crosshair point
// ---------------------------------------------------------------------------

function call_airstrike()
{
	target = self offmenu::crosshair_trace()[ "position" ];
	count = self offmenu::get_value( "strike_n" );
	if ( !isdefined( count ) )
		count = 6;
	rocket = GetWeapon( "launcher_standard" );
	if ( rocket == level.weaponNone )
		return;
	self IPrintLnBold( "Airstrike inbound" );
	wait 0.6;
	for ( i = 0; i < count; i++ )
	{
		spread = ( RandomIntRange( -220, 220 ), RandomIntRange( -220, 220 ), 0 );
		start = target + spread + ( RandomIntRange( -400, 400 ), RandomIntRange( -400, 400 ), 2600 );
		MagicBullet( rocket, start, target + spread, self );
		wait 0.15;
	}
}

// ---------------------------------------------------------------------------
// Gun game: your weapon steps through a ladder every N kills.
// The ladder comes from the mode file (level.offm_gungame_ladder = &fn returning weapon names).
// ---------------------------------------------------------------------------

function toggle_gungame( on, key )
{
	self notify( "offm_gungame_end" );
	if ( on )
		self thread gungame_loop();
}

function private gungame_loop()
{
	self endon( "disconnect" );
	self endon( "offm_gungame_end" );
	if ( !isdefined( level.offm_gungame_ladder ) )
		return;
	ladder = self [[ level.offm_gungame_ladder ]]();
	if ( ladder.size == 0 )
		return;
	self.offm_gg_index = 0;
	self give_ladder_weapon( ladder[ 0 ] );
	base = self.kills;
	for ( ;; )
	{
		wait 0.25;
		need = self offmenu::get_value( "gg_kills" );
		if ( !isdefined( need ) )
			need = 3;
		if ( self.kills - base < need )
			continue;
		base = self.kills;
		self.offm_gg_index++;
		if ( self.offm_gg_index >= ladder.size )
		{
			self IPrintLnBold( "^6Gun Game complete!" );
			self.offm_gg_index = 0;
		}
		self give_ladder_weapon( ladder[ self.offm_gg_index ] );
	}
}

function give_ladder_weapon( name )
{
	w = GetWeapon( name );
	if ( w == level.weaponNone )
		return;
	foreach ( p in self GetWeaponsListPrimaries() )
		self TakeWeapon( p );
	self GiveWeapon( w );
	self GiveMaxAmmo( w );
	self SwitchToWeapon( w );
	self IPrintLn( "Gun Game: ^6" + ( self.offm_gg_index + 1 ) );
}

// ---------------------------------------------------------------------------
// Screen filters (drawn client side by synthex_ui.csc)
// ---------------------------------------------------------------------------

function set_filter( value, key )
{
	self clientfield::set_to_player( "synthex_filter", value );
}

// ---------------------------------------------------------------------------
// Clone (multiplayer: uses the mp human spawner, like the Prophet clone ability)
// ---------------------------------------------------------------------------

function spawn_clone()
{
	pos = self.origin + AnglesToForward( ( 0, self GetPlayerAngles()[ 1 ], 0 ) ) * 80;
	clone = SpawnActor( "spawner_bo3_human_male_reaper_mp", pos, ( 0, self GetPlayerAngles()[ 1 ] + 180, 0 ), "", true );
	if ( !isdefined( clone ) )
	{
		self IPrintLn( "Clone not available here" );
		return;
	}
	clone.ignoreall = true;
	clone.ignoreme = true;
	clone.team = self.team;
	body = self GetCharacterBodyModel();
	if ( isdefined( body ) )
		clone SetModel( body );
	head = self GetCharacterHeadModel();
	if ( isdefined( head ) )
	{
		if ( isdefined( clone.head ) )
			clone Detach( clone.head );
		clone Attach( head );
	}
	helmet = self GetCharacterHelmetModel();
	if ( isdefined( helmet ) )
		clone Attach( helmet );
	clone SetGoal( clone.origin, true );
	if ( !isdefined( self.offm_clones ) )
		self.offm_clones = [];
	self.offm_clones[ self.offm_clones.size ] = clone;
}

function remove_clones()
{
	if ( !isdefined( self.offm_clones ) )
		return;
	foreach ( c in self.offm_clones )
	{
		if ( isdefined( c ) )
			c Delete();
	}
	self.offm_clones = [];
}
