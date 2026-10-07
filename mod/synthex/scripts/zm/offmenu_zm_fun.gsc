// SYNTHEX.VIP - zombies-only fun: force push, exploding zombies, zombie launcher, random weapon each round,
// auto pack-a-punch, aim assist (zombies only), instant revive, infinite downs, gun game ladder.

#using scripts\codescripts\struct;
#using scripts\shared\array_shared;
#using scripts\shared\laststand_shared;
#using scripts\shared\util_shared;
#using scripts\shared\offmenu\offmenu_core;

#using scripts\zm\_zm_laststand;
#using scripts\zm\_zm_perks;
#using scripts\zm\_zm_weapons;

#insert scripts\shared\shared.gsh;

#namespace offmenu_zm_fun;

// ---------------------------------------------------------------------------
// Force Push: every shot knocks zombies in front of you away as ragdolls (like the Thundergun)
// ---------------------------------------------------------------------------

function toggle_force_push( on, key )
{
	self notify( "offm_push_end" );
	if ( on )
		self thread force_push_loop();
}

function private force_push_loop()
{
	self endon( "disconnect" );
	self endon( "death" );
	self endon( "offm_push_end" );
	for ( ;; )
	{
		self waittill( "weapon_fired" );
		eye = self GetEye();
		fwd = AnglesToForward( self GetPlayerAngles() );
		foreach ( z in GetAITeamArray( level.zombie_team ) )
		{
			if ( !IsAlive( z ) )
				continue;
			to = z.origin + ( 0, 0, 40 ) - eye;
			d = Length( to );
			if ( d > 700 || VectorDot( VectorNormalize( to ), fwd ) < 0.85 )
				continue;
			self thread fling( z, fwd * 260 + ( 0, 0, 160 ) );
		}
	}
}

function fling( z, vec )
{
	if ( !IsAlive( z ) )
		return;
	z DoDamage( z.health + 666, z.origin, self );
	if ( isdefined( z ) )
	{
		z StartRagdoll();
		z LaunchRagdoll( vec );
	}
}

// ---------------------------------------------------------------------------
// Zombie Launcher: fling every zombie into the sky
// ---------------------------------------------------------------------------

function launch_all_zombies()
{
	foreach ( z in GetAITeamArray( level.zombie_team ) )
	{
		if ( IsAlive( z ) )
			self thread fling( z, ( RandomIntRange( -120, 120 ), RandomIntRange( -120, 120 ), RandomIntRange( 380, 620 ) ) );
		WAIT_SERVER_FRAME;
	}
}

// ---------------------------------------------------------------------------
// Exploding Zombies: zombies blow up when they die, damaging the ones around them
// ---------------------------------------------------------------------------

function toggle_exploding_zombies( on, key )
{
	level notify( "offm_explode_end" );
	level.offm_explode_owner = self;
	if ( on )
		level thread exploding_watch();
}

function private exploding_watch()
{
	level endon( "offm_explode_end" );
	for ( ;; )
	{
		foreach ( z in GetAITeamArray( level.zombie_team ) )
		{
			if ( IsAlive( z ) && !IS_TRUE( z.offm_explode ) )
			{
				z.offm_explode = true;
				z thread explode_on_death();
			}
		}
		wait 0.3;
	}
}

function private explode_on_death()
{
	level endon( "offm_explode_end" );
	self waittill( "death" );
	pos = self.origin + ( 0, 0, 30 );
	owner = level.offm_explode_owner;
	PlaySoundAtPosition( "wpn_grenade_explode", pos );
	WAIT_SERVER_FRAME;
	if ( isdefined( owner ) )
		RadiusDamage( pos, 170, 900, 250, owner, "MOD_EXPLOSIVE" );
	else
		RadiusDamage( pos, 170, 900, 250 );
}

// ---------------------------------------------------------------------------
// Random Weapon Each Round
// ---------------------------------------------------------------------------

function toggle_random_weapon( on, key )
{
	self notify( "offm_rndw_end" );
	if ( on )
		self thread random_weapon_loop();
}

function private random_weapon_loop()
{
	self endon( "disconnect" );
	self endon( "offm_rndw_end" );
	for ( ;; )
	{
		level waittill( "start_of_round" );
		pool = [];
		foreach ( w in GetArrayKeys( level.zombie_weapons ) )
		{
			if ( isdefined( w ) && w != level.weaponNone && !zm_weapons::is_weapon_upgraded( w ) && w.isPrimary )
				pool[ pool.size ] = w;
		}
		if ( pool.size == 0 )
			continue;
		pick = pool[ RandomInt( pool.size ) ];
		cur = self GetCurrentWeapon();
		if ( isdefined( cur ) && cur != level.weaponNone && cur.isPrimary )
			self TakeWeapon( cur );
		self zm_weapons::weapon_give( pick, false, false, true, true );
		self IPrintLnBold( "New round weapon!" );
	}
}

// ---------------------------------------------------------------------------
// Auto Pack-a-Punch: any weapon you hold gets upgraded
// ---------------------------------------------------------------------------

function toggle_auto_pap( on, key )
{
	self notify( "offm_autopap_end" );
	if ( on )
		self thread auto_pap_loop();
}

function private auto_pap_loop()
{
	self endon( "disconnect" );
	self endon( "death" );
	self endon( "offm_autopap_end" );
	for ( ;; )
	{
		wait 0.5;
		w = self GetCurrentWeapon();
		if ( !isdefined( w ) || w == level.weaponNone || zm_weapons::is_weapon_upgraded( w ) )
			continue;
		up = zm_weapons::get_upgrade_weapon( w, zm_weapons::weapon_supports_attachments( w ) );
		if ( !isdefined( up ) || up == level.weaponNone || up == w )
			continue;
		self TakeWeapon( w );
		self zm_weapons::weapon_give( up, true, false, true, true );
	}
}

// ---------------------------------------------------------------------------
// Aim Assist (zombies only): while aiming down sights, gently turns toward the nearest zombie head on screen
// ---------------------------------------------------------------------------

function toggle_aim_assist( on, key )
{
	self notify( "offm_aim_end" );
	if ( on )
		self thread aim_assist_loop();
}

function private aim_assist_loop()
{
	self endon( "disconnect" );
	self endon( "death" );
	self endon( "offm_aim_end" );
	for ( ;; )
	{
		WAIT_SERVER_FRAME;
		if ( IS_TRUE( self.offm.open ) || !self AdsButtonPressed() )
			continue;
		strength = self offmenu::get_value( "aim_str" );
		if ( !isdefined( strength ) )
			strength = 0.25;
		eye = self GetEye();
		angles = self GetPlayerAngles();
		fwd = AnglesToForward( angles );
		best = undefined;
		best_dot = 0.94;     // ~20 degree cone
		foreach ( z in GetAITeamArray( level.zombie_team ) )
		{
			if ( !IsAlive( z ) )
				continue;
			head = z GetTagOrigin( "j_head" );
			if ( !isdefined( head ) )
				head = z.origin + ( 0, 0, 64 );
			dir = VectorNormalize( head - eye );
			dot = VectorDot( dir, fwd );
			if ( dot > best_dot && SightTracePassed( eye, head, false, z ) )
			{
				best_dot = dot;
				best = head;
			}
		}
		if ( !isdefined( best ) )
			continue;
		want = VectorToAngles( best - eye );
		dp = AngleClamp180( want[ 0 ] - angles[ 0 ] );
		dy = AngleClamp180( want[ 1 ] - angles[ 1 ] );
		self SetPlayerAngles( ( angles[ 0 ] + dp * strength, angles[ 1 ] + dy * strength, 0 ) );
	}
}

// ---------------------------------------------------------------------------
// Revive: instant self revive when downed, and infinite downs (solo keeps Quick Revive)
// ---------------------------------------------------------------------------

function toggle_instant_revive( on, key )
{
	self notify( "offm_instrev_end" );
	if ( on )
		self thread instant_revive_loop();
}

function private instant_revive_loop()
{
	self endon( "disconnect" );
	self endon( "offm_instrev_end" );
	for ( ;; )
	{
		self waittill( "player_downed" );
		wait 0.2;
		if ( self laststand::player_is_in_laststand() )
			self zm_laststand::auto_revive( self );
	}
}

function toggle_infinite_downs( on, key )
{
	self notify( "offm_infdowns_end" );
	if ( on )
		self thread infinite_downs_loop();
}

function private infinite_downs_loop()
{
	self endon( "disconnect" );
	self endon( "offm_infdowns_end" );
	for ( ;; )
	{
		// Solo: Quick Revive gives the self revives; keep it and reset its use count.
		level.solo_lives_given = 0;
		if ( !self laststand::player_is_in_laststand() && IsAlive( self ) && !self HasPerk( "specialty_quickrevive" )
			&& isdefined( level._custom_perks ) && isdefined( level._custom_perks[ "specialty_quickrevive" ] ) )
			self zm_perks::give_perk( "specialty_quickrevive", false );
		wait 1;
	}
}

// ---------------------------------------------------------------------------
// Gun game ladder for zombies: the map's wall / box weapons, base versions, shuffled once
// ---------------------------------------------------------------------------

function gungame_ladder()
{
	names = [];
	foreach ( w in GetArrayKeys( level.zombie_weapons ) )
	{
		if ( isdefined( w ) && w != level.weaponNone && !zm_weapons::is_weapon_upgraded( w ) && w.isPrimary )
			names[ names.size ] = w.name;
	}
	return array::randomize( names );
}
