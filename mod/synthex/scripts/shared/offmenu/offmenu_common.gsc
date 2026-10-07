// SYNTHEX.VIP - features and pages shared by zm + mp.
// Mode files call the page builders (build_movement, build_camera, ...) and reuse the feature functions.

#using scripts\codescripts\struct;
#using scripts\shared\util_shared;
#using scripts\shared\offmenu\offmenu_core;

#insert scripts\shared\shared.gsh;

#namespace offmenu_common;

// ---------------------------------------------------------------------------
// Value tables (values + display labels for sliders / choices)
// ---------------------------------------------------------------------------

function private v( a, b, c, d, e, f, g, h )
{
	out = [];
	if ( isdefined( a ) ) out[ out.size ] = a;
	if ( isdefined( b ) ) out[ out.size ] = b;
	if ( isdefined( c ) ) out[ out.size ] = c;
	if ( isdefined( d ) ) out[ out.size ] = d;
	if ( isdefined( e ) ) out[ out.size ] = e;
	if ( isdefined( f ) ) out[ out.size ] = f;
	if ( isdefined( g ) ) out[ out.size ] = g;
	if ( isdefined( h ) ) out[ out.size ] = h;
	return out;
}

// ---------------------------------------------------------------------------
// Player > Movement / Camera / Position
// ---------------------------------------------------------------------------

function build_movement( tab_id )
{
	self offmenu::side( tab_id, "movement", "Movement" );

	self offmenu::card( 0, "Speed" );
	self offmenu::slider( "Movement Speed", "speed", v( 1.0, 1.25, 1.5, 2.0, 3.0 ), v( "1x", "1.25x", "1.5x", "2x", "3x" ), 0, &set_speed );
	self offmenu::toggle( "Super Sprint", "supersprint", &toggle_super_sprint );
	self offmenu::toggle( "Infinite Sprint", "infsprint", &toggle_infinite_sprint );

	self offmenu::card( 1, "Jumping" );
	self offmenu::toggle( "Super Jump", "superjump", &toggle_jumps );
	self offmenu::toggle( "Infinite Jump", "infjump", &toggle_jumps, undefined, "jump again in mid-air" );
	self offmenu::slider( "Jump Boost", "jumpboost", v( 400, 550, 750, 1000, 1400 ), v( "400", "550", "750", "1000", "1400" ), 2 );
	self offmenu::toggle( "Double Jump Anywhere", "doublejump", &toggle_double_jump );

	self offmenu::card( 2, "No Clip" );
	self offmenu::toggle( "No Clip", "noclip", &toggle_noclip );
	self offmenu::slider( "Fly Speed", "flyspeed", v( 10, 20, 30, 45 ), v( "Slow", "Normal", "Fast", "Faster" ), 1 );
	self offmenu::slider( "Sprint Boost", "flyboost", v( 1.5, 2.5, 4.0 ), v( "1.5x", "2.5x", "4x" ), 1 );
	self offmenu::note( "Move to fly, Jump up, Crouch down." );

	self offmenu::card( 3, "Safety" );
	self offmenu::toggle( "No Fall Damage", "nofall", &toggle_no_fall );
	self offmenu::toggle( "Return If Out Of Map", "oob", &toggle_oob_return );
}

function build_camera( tab_id )
{
	self offmenu::side( tab_id, "camera", "Camera" );

	self offmenu::card( 0, "View" );
	self offmenu::toggle( "Third Person", "thirdperson", &toggle_thirdperson );
	self offmenu::slider( "Field of View", "fov", v( 65, 75, 80, 90, 100, 110, 120 ), v( "65", "75", "80", "90", "100", "110", "120" ), 2 );
	self offmenu::toggle( "Hide HUD", "hidehud", &toggle_hide_hud );

	self offmenu::card( 1, "Photo Mode" );
	self offmenu::toggle( "Freeze Time", "freezetime", &toggle_freeze_time, false );
	self offmenu::toggle( "Hide Weapon", "hideweapon", &toggle_hide_weapon );
	self offmenu::note( "Use with No Clip for screenshots." );
}

function build_position( tab_id, side_id, label )
{
	self offmenu::side( tab_id, side_id, label );

	self offmenu::card( 0, "Save Slots" );
	self offmenu::choice( "Slot", "posslot", v( 0, 1, 2 ), v( "Slot 1", "Slot 2", "Slot 3" ), 0 );
	self offmenu::button( "Save", &save_pos );
	self offmenu::button( "Load", &load_pos );
	self offmenu::stat( "Slot 1", &slot_status_1 );
	self offmenu::stat( "Slot 2", &slot_status_2 );
	self offmenu::stat( "Slot 3", &slot_status_3 );

	self offmenu::card( 1, "Quick" );
	self offmenu::button( "To Crosshair", &tele_crosshair );
	self offmenu::button( "To Sky (+2000)", &tele_up );
	self offmenu::button( "Back to Spawn", &tele_spawn );

	self offmenu::card( 2, "Current" );
	self offmenu::stat( "X", &pos_x );
	self offmenu::stat( "Y", &pos_y );
	self offmenu::stat( "Z", &pos_z );
	self offmenu::stat( "Facing", &pos_yaw );
}

// ---------------------------------------------------------------------------
// Teleport tab (Map Spots page is mode-specific)
// ---------------------------------------------------------------------------

function build_teleport_tools( tab_id, bring_label, bring_fn )
{
	self offmenu::side( tab_id, "tools", "Tools" );
	self offmenu::card( 0, "Teleport Gun" );
	self offmenu::toggle( "Teleport Gun", "telegun", &toggle_telegun );
	self offmenu::note( "Shoot to teleport where it lands." );
	self offmenu::card( 1, "Bring" );
	self offmenu::button( "All Players to Me", &bring_all_players );
	self offmenu::button( bring_label, bring_fn );
}

// ---------------------------------------------------------------------------
// Fun tab
// ---------------------------------------------------------------------------

function build_fun( tab_id, magic_values, magic_labels )
{
	self offmenu::tab( tab_id, "Fun" );

	self offmenu::side( tab_id, "bullets", "Bullets" );
	self offmenu::card( 0, "Explosive Bullets" );
	self offmenu::toggle( "Explosive Bullets", "explo", &toggle_explosive_bullets );
	self offmenu::slider( "Radius", "explo_r", v( 100, 160, 220, 300, 400 ), v( "100", "160", "220", "300", "400" ), 2 );
	self offmenu::slider( "Damage", "explo_d", v( 150, 300, 600, 1500, 5000 ), v( "150", "300", "600", "1500", "5000" ), 2 );

	self offmenu::card( 1, "Magic Bullets" );
	self offmenu::toggle( "Magic Bullets", "magic", &toggle_magic_bullets );
	self offmenu::choice( "Fires", "magic_w", magic_values, magic_labels, 0 );

	self offmenu::card( 3, "Rapid Fire" );
	self offmenu::toggle( "Rapid Fire", "rapid", &toggle_rapid_fire );
	self offmenu::slider( "Fire Rate", "rapid_r", v( 5, 10, 20, 40 ), v( "5/s", "10/s", "20/s", "40/s" ), 1 );
	self offmenu::note( "Hold fire: your gun shoots at the crosshair this fast, snipers too." );

	self offmenu::card( 2, "Extras" );
	self offmenu::toggle( "Fast Reload", "fastreload", &toggle_fast_reload );
	self offmenu::toggle( "Fast Weapon Swap", "fastswap", &toggle_fast_swap );
	self offmenu::toggle( "No Recoil", "norecoil", &toggle_no_recoil );

	self offmenu::side( tab_id, "forge", "Forge" );
	self offmenu::card( 0, "Forge Mode" );
	self offmenu::toggle( "Forge Mode", "forge", &toggle_forge );
	self offmenu::slider( "Hold Distance", "forge_d", v( 80, 150, 250, 400 ), v( "80", "150", "250", "400" ), 1 );
	self offmenu::note( "Aim at an object, hold Use to carry." );
	self offmenu::card( 1, "Options" );
	self offmenu::toggle( "Rotate With View", "forge_rot", &noop_toggle );
}

// ---------------------------------------------------------------------------
// World tab (Time card 2 is mode-specific and added by the caller)
// ---------------------------------------------------------------------------

function build_world( tab_id )
{
	self offmenu::tab( tab_id, "World" );

	self offmenu::side( tab_id, "time", "Time" );
	self offmenu::card( 0, "Speed" );
	self offmenu::toggle( "Slow Motion", "slowmo", &toggle_slowmo, false );
	self offmenu::slider( "Game Speed", "timescale", v( 0.25, 0.5, 0.75, 1.0, 1.5, 2.0 ), v( "0.25x", "0.5x", "0.75x", "1.0x", "1.5x", "2.0x" ), 3, &set_timescale );

	self offmenu::side( tab_id, "physics", "Physics" );
	self offmenu::card( 0, "Gravity" );
	self offmenu::toggle( "Low Gravity", "lowgrav", &toggle_low_gravity, false );
	self offmenu::slider( "Gravity", "gravity", v( 100, 200, 400, 600, 800, 1200 ), v( "100", "200", "400", "600", "800", "1200" ), 4, &set_gravity );
	self offmenu::card( 1, "Jumping (everyone)" );
	self offmenu::slider( "Jump Height", "jump_h", v( 39, 60, 100, 200, 400 ), v( "39", "60", "100", "200", "400" ), 0, &set_jump_height );
	self offmenu::card( 2, "Movement (everyone)" );
	self offmenu::slider( "Player Speed", "all_speed", v( 1.0, 1.25, 1.5, 2.0 ), v( "1.0x", "1.25x", "1.5x", "2.0x" ), 0, &set_all_speed );
}

// ---------------------------------------------------------------------------
// Lobby > Players (actions card 1 gets mode extras through level.offm_player_extra)
// ---------------------------------------------------------------------------

function build_players( tab_id )
{
	self offmenu::side( tab_id, "players", "Players", &fill_players );
}

function private fill_players()
{
	self offmenu::card( 0, "Players" );
	foreach ( p in GetPlayers() )
		self offmenu::item( p.name, &pick_player, p, "player", p GetEntityNumber() );

	self offmenu::card( 1, "Actions" );
	self offmenu::button( "Bring to Me", &p_bring );
	self offmenu::button( "Go to Player", &p_goto );
	self offmenu::button( "Give God", &p_god, true );
	self offmenu::button( "Remove God", &p_god, false );
	self offmenu::button( "Freeze", &p_freeze, true );
	self offmenu::button( "Unfreeze", &p_freeze, false );
	if ( isdefined( level.offm_player_extra ) )
		self [[ level.offm_player_extra ]]();
	self offmenu::button( "Kill", &p_kill, undefined, undefined, true );

	self offmenu::card( 2, "Selected" );
	self offmenu::stat( "Name", &sel_name );
	self offmenu::stat( "Health", &sel_health );
	self offmenu::stat( "God Mode", &sel_god );
}

function private pick_player( p )
{
	self.offm_target = p;
}

function get_target()
{
	t = self.offm_target;
	if ( !isdefined( t ) || !IsPlayer( t ) )
		t = self;
	return t;
}

function private sel_name()   { return self get_target().name; }
function private sel_health() { return int( self get_target().health ); }
function private sel_god()    { return offmenu::pick( IS_TRUE( self get_target().offm_god ), "On", "Off" ); }

function private p_bring()          { self get_target() SetOrigin( self.origin + AnglesToForward( self GetPlayerAngles() ) * 60 ); }
function private p_goto()           { self SetOrigin( self get_target().origin + ( 0, 0, 5 ) ); }
function private p_freeze( on )     { self get_target() FreezeControls( on ); }
function private p_kill()           { t = self get_target(); t DoDamage( t.health + 1000, t.origin, self ); }

function private p_god( on )
{
	t = self get_target();
	t.offm_god = on;
	if ( on )
		t EnableInvulnerability();
	else
		t DisableInvulnerability();
}

// ---------------------------------------------------------------------------
// Survival / health / ammo (used by mode General pages)
// ---------------------------------------------------------------------------

function toggle_god( on, key )
{
	self.offm_god = on;
	if ( on )
		self EnableInvulnerability();
	else
		self DisableInvulnerability();
}

function toggle_demigod( on, key )
{
	self notify( "offm_demigod_end" );
	if ( on )
		self thread demigod_loop();
}

function private demigod_loop()
{
	self endon( "disconnect" );
	self endon( "death" );
	self endon( "offm_demigod_end" );
	for ( ;; )
	{
		if ( self.health < 40 )
			self.health = self.maxhealth;
		WAIT_SERVER_FRAME;
	}
}

function toggle_invisible( on, key )
{
	if ( on )
		self Hide();
	else
		self Show();
	self.ignoreme = on;
}

function toggle_ammo( on, key )
{
	self notify( "offm_ammo_end" );
	if ( on )
		self thread ammo_loop();
}

function private ammo_loop()
{
	self endon( "disconnect" );
	self endon( "death" );
	self endon( "offm_ammo_end" );
	for ( ;; )
	{
		w = self GetCurrentWeapon();
		if ( isdefined( w ) && w != level.weaponNone )
		{
			if ( self offmenu::get_value( "ammomode" ) !== "stock" )
			{
				self SetWeaponAmmoClip( w, w.clipSize );
				if ( isdefined( w.dualWieldWeapon ) && w.dualWieldWeapon != level.weaponNone )
					self SetWeaponAmmoClip( w.dualWieldWeapon, w.dualWieldWeapon.clipSize );
			}
			self GiveMaxAmmo( w );
		}
		wait 0.05;
	}
}

function toggle_equipment( on, key )
{
	self notify( "offm_equip_end" );
	if ( on )
		self thread equipment_loop();
}

function private equipment_loop()
{
	self endon( "disconnect" );
	self endon( "death" );
	self endon( "offm_equip_end" );
	for ( ;; )
	{
		foreach ( w in self GetWeaponsList( true ) )
		{
			if ( w.isGrenadeWeapon || w.inventoryType == "offhand" )
				self GiveMaxAmmo( w );
		}
		wait 0.25;
	}
}

function toggle_gadget_power( on, key )
{
	self notify( "offm_gadget_end" );
	if ( on )
		self thread gadget_loop();
}

function private gadget_loop()
{
	self endon( "disconnect" );
	self endon( "death" );
	self endon( "offm_gadget_end" );
	for ( ;; )
	{
		for ( slot = 0; slot < 3; slot++ )
			self GadgetPowerSet( slot, 100 );
		wait 0.25;
	}
}

function set_max_health( value, key )
{
	self.maxhealth = value;
	self.health = value;
}

function set_regen( value, key )
{
	self notify( "offm_regen_end" );
	if ( value > 0 )
		self thread regen_loop( value );
}

function private regen_loop( per_tick )
{
	self endon( "disconnect" );
	self endon( "death" );
	self endon( "offm_regen_end" );
	self thread track_damage_time();
	for ( ;; )
	{
		if ( self.health < self.maxhealth && GetTime() - self.offm_last_damage > 1500 )
			self.health = int( min( self.maxhealth, self.health + per_tick ) );
		wait 0.1;
	}
}

function private track_damage_time()
{
	self endon( "disconnect" );
	self endon( "death" );
	self endon( "offm_regen_end" );
	self.offm_last_damage = 0;
	for ( ;; )
	{
		self waittill( "damage" );
		self.offm_last_damage = GetTime();
	}
}

function max_ammo_all()
{
	foreach ( w in self GetWeaponsList( true ) )
	{
		self GiveMaxAmmo( w );
		self SetWeaponAmmoClip( w, w.clipSize );
	}
}

function full_health()
{
	self.health = self.maxhealth;
}

function suicide()
{
	self offmenu::close_menu();
	self DisableInvulnerability();
	self DoDamage( self.health + 1000, self.origin );
}

// ---------------------------------------------------------------------------
// Movement
// ---------------------------------------------------------------------------

function set_speed( scale, key )
{
	self.offm_speed = scale;
	self SetMoveSpeedScale( scale );
}

function toggle_super_sprint( on, key )
{
	self notify( "offm_supersprint_end" );
	if ( on )
		self thread super_sprint_loop();
}

function private super_sprint_loop()
{
	self endon( "disconnect" );
	self endon( "death" );
	self endon( "offm_supersprint_end" );
	for ( ;; )
	{
		if ( !IS_TRUE( self.offm.open ) )
		{
			base = offmenu::pick( isdefined( self.offm_speed ), self.offm_speed, 1.0 );
			self SetMoveSpeedScale( offmenu::pick( self IsSprinting(), base * 1.8, base ) );
		}
		WAIT_SERVER_FRAME;
	}
}

function toggle_infinite_sprint( on, key )
{
	if ( on )
	{
		self SetPerk( "specialty_unlimitedsprint" );
		self SetPerk( "specialty_longersprint" );
	}
	else
	{
		self UnsetPerk( "specialty_unlimitedsprint" );
		self UnsetPerk( "specialty_longersprint" );
	}
}

// Super Jump and Infinite Jump share one loop. The server only sees the jump button every 50 ms, by which
// time a normal jump has already left the ground, so a jump counts as "from the ground" if the player was
// standing on the previous frame.
function toggle_jumps( on, key )
{
	self notify( "offm_jump_end" );
	if ( self offmenu::get_state( "superjump" ) || self offmenu::get_state( "infjump" ) )
		self thread jump_loop();
}

function private jump_loop()
{
	self endon( "disconnect" );
	self endon( "offm_jump_end" );
	was_pressed = false;
	was_ground = true;
	for ( ;; )
	{
		WAIT_SERVER_FRAME;
		if ( !IsAlive( self ) )
			continue;
		pressed = self JumpButtonPressed();
		ground = self IsOnGround();
		if ( pressed && !was_pressed && !IS_TRUE( self.offm.open ) )
		{
			boost = self offmenu::get_value( "jumpboost" );
			if ( was_ground && self offmenu::get_state( "superjump" ) )
				self thread push_up( boost );
			else if ( !was_ground && self offmenu::get_state( "infjump" ) )
				self thread push_up( offmenu::pick( self offmenu::get_state( "superjump" ), boost, 400 ) );
		}
		was_pressed = pressed;
		was_ground = ground;
	}
}

// hold the upward velocity for a few frames (a single SetVelocity can be eaten by ground movement)
function private push_up( speed )
{
	self endon( "disconnect" );
	if ( self IsOnGround() )
		self SetOrigin( self.origin + ( 0, 0, 2 ) );
	for ( i = 0; i < 3; i++ )
	{
		vel = self GetVelocity();
		self SetVelocity( ( vel[ 0 ], vel[ 1 ], speed ) );
		WAIT_SERVER_FRAME;
	}
}

function toggle_double_jump( on, key )
{
	self AllowDoubleJump( on );
}

function toggle_noclip( on, key )
{
	self notify( "offm_noclip_end" );
	if ( on )
		self thread noclip_loop();
}

function private noclip_loop()
{
	self endon( "disconnect" );
	anchor = Spawn( "script_origin", self.origin );
	self PlayerLinkTo( anchor );
	self thread noclip_cleanup( anchor );

	self endon( "death" );
	self endon( "offm_noclip_end" );
	for ( ;; )
	{
		if ( !IS_TRUE( self.offm.open ) )
		{
			angles = self GetPlayerAngles();
			move = self GetNormalizedMovement();
			speed = self offmenu::get_value( "flyspeed" );
			if ( self SprintButtonPressed() )
				speed *= self offmenu::get_value( "flyboost" );
			delta = AnglesToForward( angles ) * move[ 0 ] * speed + AnglesToRight( angles ) * move[ 1 ] * speed;
			if ( self JumpButtonPressed() )
				delta += ( 0, 0, speed );
			if ( self StanceButtonPressed() )
				delta -= ( 0, 0, speed );
			anchor.origin = anchor.origin + delta;
		}
		WAIT_SERVER_FRAME;
	}
}

function private noclip_cleanup( anchor )
{
	self util::waittill_any( "offm_noclip_end", "death", "disconnect" );
	if ( isdefined( self ) )
		self Unlink();
	anchor Delete();
}

function toggle_no_fall( on, key )
{
	if ( on )
		self SetPerk( "specialty_fallheight" );
	else
		self UnsetPerk( "specialty_fallheight" );
}

function toggle_oob_return( on, key )
{
	self notify( "offm_oob_end" );
	if ( on )
		self thread oob_loop();
}

function private oob_loop()
{
	self endon( "disconnect" );
	self endon( "death" );
	self endon( "offm_oob_end" );
	last_safe = self.origin;
	for ( ;; )
	{
		if ( self IsOnGround() )
			last_safe = self.origin;
		else if ( self.origin[ 2 ] < last_safe[ 2 ] - 1500 && !self offmenu::get_state( "noclip" ) )
			self SetOrigin( last_safe );
		wait 0.2;
	}
}

// ---------------------------------------------------------------------------
// Camera
// ---------------------------------------------------------------------------

function toggle_thirdperson( on, key )
{
	self SetClientThirdPerson( on );
}

function set_fov( value, key )
{
	SetDvar( "cg_fov", value );
}

function toggle_hide_hud( on, key )
{
	self SetClientUIVisibilityFlag( "hud_visible", offmenu::pick( on, 0, 1 ) );
}

function set_tp_range( value, key )
{
	SetDvar( "cg_thirdPersonRange", value );
}

function set_tp_angle( value, key )
{
	SetDvar( "cg_thirdPersonAngle", value );
}

function toggle_freeze_time( on, key )
{
	if ( on )
		SetSlowMotion( 1.0, 0.05, 0.3 );
	else
		SetSlowMotion( 0.05, 1.0, 0.3 );
}

function toggle_hide_weapon( on, key )
{
	if ( on )
		self HideViewModel();
	else
		self ShowViewModel();
}

// ---------------------------------------------------------------------------
// Position / teleport
// ---------------------------------------------------------------------------

function save_pos()
{
	slot = self offmenu::get_value( "posslot" );
	if ( !isdefined( self.offm_slots ) )
		self.offm_slots = [];
	s = SpawnStruct();
	s.origin = self.origin;
	s.angles = self GetPlayerAngles();
	self.offm_slots[ slot ] = s;
}

function load_pos()
{
	slot = self offmenu::get_value( "posslot" );
	if ( !isdefined( self.offm_slots ) || !isdefined( self.offm_slots[ slot ] ) )
		return;
	self SetOrigin( self.offm_slots[ slot ].origin );
	self SetPlayerAngles( self.offm_slots[ slot ].angles );
}

function private slot_status( slot )
{
	if ( isdefined( self.offm_slots ) && isdefined( self.offm_slots[ slot ] ) )
		return "Saved";
	return "Empty";
}
function private slot_status_1() { return self slot_status( 0 ); }
function private slot_status_2() { return self slot_status( 1 ); }
function private slot_status_3() { return self slot_status( 2 ); }

function private pos_x()   { return int( self.origin[ 0 ] ); }
function private pos_y()   { return int( self.origin[ 1 ] ); }
function private pos_z()   { return int( self.origin[ 2 ] ); }
function private pos_yaw() { return int( AbsAngleClamp360( self GetPlayerAngles()[ 1 ] ) ); }

function tele_crosshair()
{
	trace = self offmenu::crosshair_trace();
	self SetOrigin( trace[ "position" ] + ( 0, 0, 5 ) );
}

function tele_up()
{
	self SetOrigin( self.origin + ( 0, 0, 2000 ) );
}

function tele_spawn()
{
	if ( isdefined( self.offm_spawn_origin ) )
		self SetOrigin( self.offm_spawn_origin );
}

function toggle_telegun( on, key )
{
	self notify( "offm_telegun_end" );
	if ( on )
		self thread telegun_loop();
}

function private telegun_loop()
{
	self endon( "disconnect" );
	self endon( "death" );
	self endon( "offm_telegun_end" );
	for ( ;; )
	{
		self waittill( "weapon_fired" );
		trace = self offmenu::crosshair_trace();
		self SetOrigin( trace[ "position" ] + ( 0, 0, 5 ) );
	}
}

function bring_all_players()
{
	i = 0;
	foreach ( p in GetPlayers() )
	{
		if ( p == self )
			continue;
		i++;
		p SetOrigin( self.origin + ( 40 * i, 0, 5 ) );
	}
}

// ---------------------------------------------------------------------------
// Fun
// ---------------------------------------------------------------------------

function toggle_explosive_bullets( on, key )
{
	self notify( "offm_explo_end" );
	if ( on )
		self thread explosive_loop();
}

function private explosive_loop()
{
	self endon( "disconnect" );
	self endon( "death" );
	self endon( "offm_explo_end" );
	for ( ;; )
	{
		self waittill( "weapon_fired", weapon );
		pos = self offmenu::crosshair_trace()[ "position" ];
		RadiusDamage( pos, self offmenu::get_value( "explo_r" ), self offmenu::get_value( "explo_d" ), 50, self, "MOD_EXPLOSIVE", weapon );
		PlaySoundAtPosition( "wpn_grenade_explode", pos );
	}
}

function toggle_magic_bullets( on, key )
{
	self notify( "offm_magic_end" );
	if ( on )
		self thread magic_loop();
}

function private magic_loop()
{
	self endon( "disconnect" );
	self endon( "death" );
	self endon( "offm_magic_end" );
	for ( ;; )
	{
		self waittill( "weapon_fired" );
		w = GetWeapon( self offmenu::get_value( "magic_w" ) );
		if ( w == level.weaponNone )
			continue;
		eye = self GetEye();
		fwd = AnglesToForward( self GetPlayerAngles() );
		MagicBullet( w, eye + fwd * 30, self offmenu::crosshair_trace()[ "position" ], self );
	}
}

// Rapid Fire: the game has no fire-rate control for players, so while fire is held, extra bullets of the
// weapon in hand are fired from the eye to the crosshair at the chosen rate (several per frame above 20/s).
function toggle_rapid_fire( on, key )
{
	self notify( "offm_rapid_end" );
	if ( on )
		self thread rapid_fire_loop();
}

function private rapid_fire_loop()
{
	self endon( "disconnect" );
	self endon( "offm_rapid_end" );
	owed = 0.0;
	for ( ;; )
	{
		WAIT_SERVER_FRAME;
		w = self GetCurrentWeapon();
		if ( !IsAlive( self ) || IS_TRUE( self.offm.open ) || !self AttackButtonPressed() || !isdefined( w ) || w == level.weaponNone || !w.isPrimary )
		{
			owed = 0.0;
			continue;
		}
		if ( self GetWeaponAmmoClip( w ) <= 0 && self GetWeaponAmmoStock( w ) <= 0 )
			continue;
		rate = self offmenu::get_value( "rapid_r" );
		if ( !isdefined( rate ) )
			rate = 10;
		owed += rate * 0.05;
		eye = self GetEye();
		fwd = AnglesToForward( self GetPlayerAngles() );
		target = self offmenu::crosshair_trace()[ "position" ];
		while ( owed >= 1 )
		{
			MagicBullet( w, eye + fwd * 20, target, self );
			owed -= 1;
		}
	}
}

function toggle_fast_reload( on, key )
{
	if ( on )
		self SetPerk( "specialty_fastreload" );
	else
		self UnsetPerk( "specialty_fastreload" );
}

function toggle_fast_swap( on, key )
{
	if ( on )
		self SetPerk( "specialty_fastweaponswitch" );
	else
		self UnsetPerk( "specialty_fastweaponswitch" );
}

// No Recoil: there is no recoil scale for players in script, so while you are firing any upward kick of the
// view is pulled straight back down every frame (horizontal aim is left alone).
function toggle_no_recoil( on, key )
{
	self notify( "offm_norecoil_end" );
	if ( on )
	{
		self thread no_recoil_fired();
		self thread no_recoil_loop();
	}
}

function private no_recoil_fired()
{
	self endon( "disconnect" );
	self endon( "offm_norecoil_end" );
	for ( ;; )
	{
		self waittill( "weapon_fired" );
		self.offm_last_fire = GetTime();
	}
}

function private no_recoil_loop()
{
	self endon( "disconnect" );
	self endon( "offm_norecoil_end" );
	prev = self GetPlayerAngles();
	for ( ;; )
	{
		WAIT_SERVER_FRAME;
		cur = self GetPlayerAngles();
		firing = isdefined( self.offm_last_fire ) && GetTime() - self.offm_last_fire < 200;
		// pitch goes negative when the view moves up
		if ( firing && IsAlive( self ) && !IS_TRUE( self.offm.open ) && AngleClamp180( cur[ 0 ] - prev[ 0 ] ) < 0 )
		{
			cur = ( prev[ 0 ], cur[ 1 ], cur[ 2 ] );
			self SetPlayerAngles( cur );
		}
		prev = cur;
	}
}

function toggle_forge( on, key )
{
	self notify( "offm_forge_end" );
	if ( on )
		self thread forge_loop();
}

function private forge_loop()
{
	self endon( "disconnect" );
	self endon( "death" );
	self endon( "offm_forge_end" );
	for ( ;; )
	{
		if ( !IS_TRUE( self.offm.open ) && self UseButtonPressed() )
		{
			ent = self offmenu::crosshair_trace( 2000 )[ "entity" ];
			if ( isdefined( ent ) && ent != self )
			{
				while ( self UseButtonPressed() && isdefined( ent ) && !IS_TRUE( self.offm.open ) )
				{
					pos = self GetEye() + AnglesToForward( self GetPlayerAngles() ) * self offmenu::get_value( "forge_d" );
					if ( IsPlayer( ent ) || IsAI( ent ) )
						ent SetOrigin( pos );
					else
						ent.origin = pos;
					if ( self offmenu::get_state( "forge_rot" ) && !IsPlayer( ent ) )
						ent.angles = ( 0, self GetPlayerAngles()[ 1 ], 0 );
					WAIT_SERVER_FRAME;
				}
			}
		}
		WAIT_SERVER_FRAME;
	}
}

function noop_toggle( on, key )
{
}

function noop()
{
}

// ---------------------------------------------------------------------------
// World (level-wide)
// ---------------------------------------------------------------------------

function toggle_slowmo( on, key )
{
	cur = self offmenu::get_value( "timescale" );
	if ( on )
		SetSlowMotion( cur, 0.35, 0.5 );
	else
		SetSlowMotion( 0.35, cur, 0.5 );
}

function set_timescale( value, key )
{
	SetSlowMotion( value, value, 0 );
}

function toggle_low_gravity( on, key )
{
	SetDvar( "bg_gravity", offmenu::pick( on, 200, self offmenu::get_value( "gravity" ) ) );
}

function set_gravity( value, key )
{
	SetDvar( "bg_gravity", value );
}

function set_jump_height( value, key )
{
	SetJumpHeight( value );
}

function set_all_speed( value, key )
{
	foreach ( p in GetPlayers() )
	{
		p SetMoveSpeedScale( value );
	}
}
