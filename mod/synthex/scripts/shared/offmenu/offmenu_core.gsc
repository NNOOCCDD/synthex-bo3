// SYNTHEX.VIP - menu engine (shared by zm + mp).
//
// The menu itself is drawn in Lua (ui/synthex/synthex_menu.lua). This file:
//   - opens it with ADS + Melee (host only, offline / private sessions only)
//   - keeps the option registry the Lua side talks to (same keys and labels)
//   - runs options when the menu sends a response, and streams stats / lists back with LUINotifyEvent.
//
// Mode files build the registry with:
//   offmenu::set_builder( &fn )                                 fn runs on the player once
//   self offmenu::tab( id, label )
//   self offmenu::side( tab_id, side_id, label, [fill_fn] )     fill_fn rebuilds rows when the page opens
//   self offmenu::card( col, title )
//   self offmenu::toggle( label, key, &fn, [persistent], [hint] )      fn( state, key )
//   self offmenu::button( label, &fn, [arg1], [arg2], [danger] )       fn( arg1, arg2 )
//   self offmenu::slider( label, key, values, labels, default_index, &fn )   fn( value, key )
//   self offmenu::choice( ... )  same as slider
//   self offmenu::item / stat / note  (kept for the fill functions; the Lua side shows its own versions)
// and the hooks:
//   level.offm_item_handlers[ group or prefix ] = &fn       fn( id, group ) for list rows (i|group|id)
//   level.offm_powerup_fn = &fn                              fn( name )      (pu|name)
//   level.offm_stats_fn = &fn                                returns an array of ints (sx_stats)
//   level.offm_page_fn = &fn                                 fn( tab, side ) sends lists for a page

#using scripts\codescripts\struct;
#using scripts\shared\callbacks_shared;
#using scripts\shared\system_shared;
#using scripts\shared\util_shared;

#insert scripts\shared\shared.gsh;

#precache( "material", "white" );
#precache( "lui_menu", "SynthexMenu" );
#precache( "eventstring", "sx_stats" );
#precache( "eventstring", "sx_list" );
#precache( "eventstring", "sx_cfg" );

#namespace offmenu;

#define MENU_NAME     "SynthexMenu"
#define STATS_WAIT    0.5

REGISTER_SYSTEM( "offmenu", &__init__, undefined )

function __init__()
{
	level.offm_colors = SpawnStruct();
	c = level.offm_colors;
	c.bg       = ( 0.114, 0.114, 0.122 );
	c.line     = ( 0.224, 0.224, 0.235 );
	c.text     = ( 0.85, 0.85, 0.86 );
	c.white    = ( 0.9, 0.9, 0.91 );
	c.muted    = ( 0.55, 0.55, 0.565 );
	c.dim      = ( 0.365, 0.365, 0.38 );
	c.pink     = ( 0.827, 0.612, 0.698 );
	c.pinkdeep = ( 0.659, 0.439, 0.541 );

	if ( !isdefined( level.offm_item_handlers ) )
		level.offm_item_handlers = [];

	callback::on_connect( &on_player_connect );
	callback::on_spawned( &on_player_spawned );
}

function set_builder( fn )
{
	level.offm_builder = fn;
}

// ---------------------------------------------------------------------------
// Session gate
// ---------------------------------------------------------------------------

function is_session_allowed()
{
	// Offline, LAN or private (custom) games only - never public matchmaking.
	return SessionModeIsPrivate() || !SessionModeIsOnlineGame();
}

function is_allowed_player()
{
	if ( self IsTestClient() )
		return false;
	return self IsHost();
}

// ---------------------------------------------------------------------------
// Lifecycle
// ---------------------------------------------------------------------------

function on_player_connect()
{
	self.offm_state = [];
	self.offm_val = [];
}

function on_player_spawned()
{
	if ( !is_session_allowed() || !self is_allowed_player() )
	{
		self IPrintLn( "SYNTHEX.VIP: menu disabled in this session" );
		return;
	}

	self.offm_spawn_origin = self.origin;

	if ( !isdefined( self.offm ) )
	{
		self.offm = SpawnStruct();
		self.offm.tabs = [];
		self.offm.open = false;
		self.offm.toggle_fns = [];
		self.offm.no_reapply = [];
		self.offm.value_rows = [];

		if ( isdefined( level.offm_builder ) )
			self [[ level.offm_builder ]]();

		self thread input_loop();
		self thread watch_death();
		self thread welcome();
		self thread request_config();
	}
	else
	{
		self reapply_toggles();
	}
}

function private welcome()
{
	self endon( "disconnect" );
	wait 2;
	if ( !self get_state( "nohint" ) )
		self IPrintLn( "^6SYNTHEX^7.VIP loaded - hold ^3[{+speed_throw}]^7 and press ^3[{+melee}]^7 to open" );
}

function private watch_death()
{
	self endon( "disconnect" );
	for ( ;; )
	{
		self waittill( "death" );
		if ( self.offm.open )
			self close_menu();
	}
}

// Per-life effects end on death; turn active toggles back on after respawn.
function private reapply_toggles()
{
	foreach ( key, fn in self.offm.toggle_fns )
	{
		if ( self get_state( key ) && !IS_TRUE( self.offm.no_reapply[ key ] ) )
			self thread [[ fn ]]( true, key );
	}
}

// ---------------------------------------------------------------------------
// Registry builder
// ---------------------------------------------------------------------------

function tab( id, label )
{
	t = SpawnStruct();
	t.id = id;
	t.label = label;
	t.sides = [];
	self.offm.tabs[ self.offm.tabs.size ] = t;
	self.offm.b_tab = t;
	return t;
}

function private find_tab( id )
{
	foreach ( t in self.offm.tabs )
	{
		if ( t.id == id )
			return t;
	}
	return undefined;
}

function private find_side( tab_id, side_id )
{
	t = self find_tab( tab_id );
	if ( !isdefined( t ) )
		return undefined;
	foreach ( s in t.sides )
	{
		if ( s.id == side_id )
			return s;
	}
	return undefined;
}

function side( tab_id, side_id, label, fill_fn )
{
	t = self find_tab( tab_id );
	s = SpawnStruct();
	s.id = side_id;
	s.tab_id = tab_id;
	s.label = label;
	s.cards = [];
	s.fill = fill_fn;
	t.sides[ t.sides.size ] = s;
	self.offm.b_side = s;
	return s;
}

function card( col, title )
{
	c = SpawnStruct();
	c.col = col;
	c.title = title;
	c.rows = [];
	s = self.offm.b_side;
	s.cards[ s.cards.size ] = c;
	self.offm.b_card = c;
	return c;
}

function private new_row( kind, label )
{
	r = SpawnStruct();
	r.kind = kind;
	r.label = label;
	c = self.offm.b_card;
	c.rows[ c.rows.size ] = r;
	return r;
}

function toggle( label, key, fn, persistent, hint )
{
	r = self new_row( "toggle", label );
	r.key = key;
	r.fn = fn;
	r.hint = hint;
	self.offm.toggle_fns[ key ] = fn;
	if ( isdefined( persistent ) && !persistent )
		self.offm.no_reapply[ key ] = true;
	if ( !isdefined( self.offm_state[ key ] ) )
		self.offm_state[ key ] = false;
	return r;
}

function button( label, fn, arg1, arg2, danger )
{
	r = self new_row( "button", label );
	r.fn = fn;
	r.arg1 = arg1;
	r.arg2 = arg2;
	r.danger = IS_TRUE( danger );
	return r;
}

function slider( label, key, values, labels, default_index, fn )
{
	r = self new_row( "slider", label );
	r.key = key;
	r.values = values;
	r.labels = labels;
	r.fn = fn;
	if ( !isdefined( self.offm_val[ key ] ) )
		self.offm_val[ key ] = default_index;
	self.offm.value_rows[ key ] = r;
	return r;
}

function choice( label, key, values, labels, default_index, fn )
{
	r = self slider( label, key, values, labels, default_index, fn );
	r.kind = "choice";
	return r;
}

function item( label, fn, arg, group, id )
{
	r = self new_row( "item", label );
	r.fn = fn;
	r.arg1 = arg;
	r.group = group;
	r.id = id;
	return r;
}

function stat( label, value_fn )
{
	r = self new_row( "stat", label );
	r.value_fn = value_fn;
	return r;
}

function note( text )
{
	return self new_row( "note", text );
}

// ---------------------------------------------------------------------------
// State helpers
// ---------------------------------------------------------------------------

function get_state( key )
{
	return isdefined( self.offm_state[ key ] ) && self.offm_state[ key ];
}

function set_state( key, value )
{
	self.offm_state[ key ] = value;
}

function get_value( key )
{
	r = self.offm.value_rows[ key ];
	if ( !isdefined( r ) )
		return undefined;
	return r.values[ self.offm_val[ key ] ];
}

function set_selected( group, id )
{
	self.offm_state[ "sel_" + group ] = id;
}

function get_selected( group )
{
	return self.offm_state[ "sel_" + group ];
}

// ---------------------------------------------------------------------------
// Open / close / input
// ---------------------------------------------------------------------------

function open_menu()
{
	if ( self.offm.open || !IsAlive( self ) )
		return;
	self.offm.open = true;
	self.offm.lui = self OpenLUIMenu( MENU_NAME );
	self notify( "offm_opened" );
	self thread response_loop();
	self thread stats_loop();
	// saved config not applied yet this game (the start-up request went unanswered): ask again now the menu is up
	if ( !IS_TRUE( self.offm_cfg_done ) )
		self thread ask_config( 0.3 );
}

// ---------------------------------------------------------------------------
// Saved config: the Lua side keeps the file. On start we ask for it (sx_cfg); Lua replies with the
// usual t| / v| messages for every saved setting, then "cfgdone".
// ---------------------------------------------------------------------------

function private request_config()
{
	self endon( "disconnect" );
	wait 1.5;
	self thread config_listen();
	self ask_config( 0 );
}

function private ask_config( delay )
{
	self endon( "disconnect" );
	if ( delay > 0 )
		wait delay;
	self LUINotifyEvent( &"sx_cfg", 1, GetTime() );
}

// While the menu is closed nobody else listens for menu responses: take them for a while.
function private config_listen()
{
	self endon( "disconnect" );
	self endon( "offm_cfg_done" );
	self thread config_listen_timeout( 20 );
	for ( ;; )
	{
		self waittill( "menuresponse", menu, response );
		if ( menu != MENU_NAME || self.offm.open )
			continue;
		self thread handle_response( response );
	}
}

function private config_listen_timeout( secs )
{
	self endon( "disconnect" );
	self endon( "offm_cfg_done" );
	wait secs;
	self notify( "offm_cfg_done" );
}

function close_menu()
{
	if ( !self.offm.open )
		return;
	self.offm.open = false;
	if ( isdefined( self.offm.lui ) )
		self CloseLUIMenu( self.offm.lui );
	self.offm.lui = undefined;
	self notify( "offm_closed" );
}

function private input_loop()
{
	self endon( "disconnect" );
	for ( ;; )
	{
		if ( IsAlive( self ) && self AdsButtonPressed() && self MeleeButtonPressed() )
		{
			// The game only sees these buttons while the menu is NOT holding input, so if we get here with
			// open == true the Lua menu already closed without telling us: reset and open fresh.
			if ( self.offm.open )
				self close_menu();
			self thread open_menu();
			while ( self MeleeButtonPressed() )
				WAIT_SERVER_FRAME;
		}
		WAIT_SERVER_FRAME;
	}
}

// ---------------------------------------------------------------------------
// Responses from the Lua menu
// ---------------------------------------------------------------------------

function private response_loop()
{
	self endon( "disconnect" );
	self endon( "offm_closed" );
	for ( ;; )
	{
		self waittill( "menuresponse", menu, response );
		if ( menu != MENU_NAME )
			continue;
		// Own thread: a script error in one option must never kill the listener (the menu holds input while open).
		self thread handle_response( response );
	}
}

function handle_response( response )
{
	parts = StrTok( response, "|" );
	if ( parts.size == 0 )
		return;

	switch ( parts[ 0 ] )
	{
		case "close":
			self close_menu();
			break;

		case "cfgdone":
			self.offm_cfg_done = true;
			self notify( "offm_cfg_done" );
			if ( parts.size > 1 && parts[ 1 ] != "0" )
				self IPrintLn( "^6SYNTHEX^7.VIP config loaded (" + parts[ 1 ] + " settings)" );
			break;

		case "t":
			if ( parts.size < 3 )
				return;
			key = parts[ 1 ];
			state = ( parts[ 2 ] == "1" );
			self.offm_state[ key ] = state;
			fn = self.offm.toggle_fns[ key ];
			if ( isdefined( fn ) )
				self thread [[ fn ]]( state, key );
			break;

		case "v":
			if ( parts.size < 3 )
				return;
			key = parts[ 1 ];
			r = self.offm.value_rows[ key ];
			if ( !isdefined( r ) )
				return;
			idx = int( parts[ 2 ] );
			if ( idx < 0 || idx >= r.values.size )
				return;
			self.offm_val[ key ] = idx;
			if ( isdefined( r.fn ) )
				self thread [[ r.fn ]]( r.values[ idx ], key );
			break;

		case "b":
			if ( parts.size < 4 )
				return;
			r = self find_button( parts[ 1 ], parts[ 2 ], parts[ 3 ] );
			if ( isdefined( r ) && isdefined( r.fn ) )
				self thread call_button( r );
			break;

		case "i":
			if ( parts.size < 3 )
				return;
			group = parts[ 1 ];
			id = parts[ 2 ];
			self.offm_state[ "sel_" + group ] = id;
			handler = level.offm_item_handlers[ group ];
			if ( !isdefined( handler ) && GetSubStr( group, 0, 2 ) == "w_" )
				handler = level.offm_item_handlers[ "w_" ];
			if ( isdefined( handler ) )
				self thread [[ handler ]]( id, group );
			break;

		case "pu":
			if ( parts.size >= 2 && isdefined( level.offm_powerup_fn ) )
				self thread [[ level.offm_powerup_fn ]]( parts[ 1 ] );
			break;

		case "p":
			if ( parts.size < 3 )
				return;
			self page_opened( parts[ 1 ], parts[ 2 ] );
			break;
	}
}

// GSC errors when a function gets more arguments than it declares, so pass only the ones the button has.
function private call_button( r )
{
	if ( isdefined( r.arg2 ) )
		self [[ r.fn ]]( r.arg1, r.arg2 );
	else if ( isdefined( r.arg1 ) )
		self [[ r.fn ]]( r.arg1 );
	else
		self [[ r.fn ]]();
}

function private find_button( tab_id, side_id, label )
{
	s = self find_side( tab_id, side_id );
	if ( !isdefined( s ) )
		return undefined;
	foreach ( c in s.cards )
	{
		foreach ( r in c.rows )
		{
			if ( r.kind == "button" && wire_label( r.label ) == label )
				return r;
		}
	}
	return undefined;
}

// Labels arrive with spaces sent as "_" (a space would end the menu response).
function wire_label( label )
{
	parts = StrTok( label, " " );
	out = "";
	for ( i = 0; i < parts.size; i++ )
	{
		if ( i > 0 )
			out += "_";
		out += parts[ i ];
	}
	return out;
}

// A page opened in the menu: rebuild dynamic rows (so their buttons / toggles are registered) and send its data.
function private page_opened( tab_id, side_id )
{
	self.offm.cur_tab = tab_id;
	self.offm.cur_side = side_id;
	s = self find_side( tab_id, side_id );
	if ( isdefined( s ) && isdefined( s.fill ) )
	{
		s.cards = [];
		self.offm.b_side = s;
		self [[ s.fill ]]();
	}
	if ( isdefined( level.offm_page_fn ) )
		self [[ level.offm_page_fn ]]( tab_id, side_id );
	self send_stats();
}

// ---------------------------------------------------------------------------
// Data to the Lua menu
// ---------------------------------------------------------------------------

function private stats_loop()
{
	self endon( "disconnect" );
	self endon( "offm_closed" );
	for ( ;; )
	{
		self send_stats();
		wait STATS_WAIT;
	}
}

function send_stats()
{
	if ( !isdefined( level.offm_stats_fn ) )
		return;
	vals = self [[ level.offm_stats_fn ]]();
	// LUINotifyEvent takes at most 5 values here (stock scripts never pass more), so send offset + 4 values.
	for ( off = 0; off < vals.size; off += 4 )
	{
		v = [];
		for ( i = 0; i < 4; i++ )
		{
			if ( off + i < vals.size && isdefined( vals[ off + i ] ) )
				v[ i ] = int( vals[ off + i ] );
			else
				v[ i ] = 0;
		}
		self LUINotifyEvent( &"sx_stats", 5, off, v[ 0 ], v[ 1 ], v[ 2 ], v[ 3 ] );
	}
}

// Sends a list of indices to the menu in chunks of 3 (padding is -1, which the Lua side ignores).
function send_list( code, indices )
{
	reset = 1;
	off = 0;
	for ( ;; )
	{
		v = [];
		for ( i = 0; i < 3; i++ )
		{
			if ( off + i < indices.size )
				v[ i ] = int( indices[ off + i ] );
			else
				v[ i ] = -1;
		}
		self LUINotifyEvent( &"sx_list", 5, code, reset, v[ 0 ], v[ 1 ], v[ 2 ] );
		reset = 0;
		off += 3;
		if ( off >= indices.size )
			break;
	}
}

// Index of a name in an array of names, or -1.
function index_of( list, name )
{
	if ( !isdefined( name ) )
		return -1;
	for ( i = 0; i < list.size; i++ )
	{
		if ( list[ i ] == name )
			return i;
	}
	return -1;
}

// ---------------------------------------------------------------------------
// Helpers for mode files
// ---------------------------------------------------------------------------

function crosshair_trace( dist )
{
	if ( !isdefined( dist ) )
		dist = 100000;
	eye = self GetEye();
	fwd = AnglesToForward( self GetPlayerAngles() );
	return BulletTrace( eye, eye + fwd * dist, false, self );
}

function get_human_players()
{
	out = [];
	foreach ( p in GetPlayers() )
	{
		if ( !p IsTestClient() )
			out[ out.size ] = p;
	}
	return out;
}

function player_by_num( num )
{
	foreach ( p in GetPlayers() )
	{
		if ( p GetEntityNumber() == num )
			return p;
	}
	return undefined;
}

// Shared tail of the stats array (indices 18..26): position, save slots, selected player, session.
function shared_stats( vals )
{
	vals[ 18 ] = int( self.origin[ 0 ] );
	vals[ 19 ] = int( self.origin[ 1 ] );
	vals[ 20 ] = int( self.origin[ 2 ] );
	vals[ 21 ] = int( AbsAngleClamp360( self GetPlayerAngles()[ 1 ] ) );
	bits = 0;
	if ( isdefined( self.offm_slots ) )
	{
		if ( isdefined( self.offm_slots[ 0 ] ) ) bits += 1;
		if ( isdefined( self.offm_slots[ 1 ] ) ) bits += 2;
		if ( isdefined( self.offm_slots[ 2 ] ) ) bits += 4;
	}
	vals[ 22 ] = bits;
	t = self.offm_target;
	if ( !isdefined( t ) || !IsPlayer( t ) )
		t = self;
	vals[ 23 ] = int( t.health );
	vals[ 24 ] = pick( IS_TRUE( t.offm_god ), 1, 0 );
	vals[ 25 ] = pick( SessionModeIsOnlineGame(), 1, 0 );
	vals[ 26 ] = t GetEntityNumber();
	return vals;
}

// Players list for Lobby > Players (entity numbers).
function send_players()
{
	nums = [];
	foreach ( p in GetPlayers() )
		nums[ nums.size ] = p GetEntityNumber();
	self send_list( 5, nums );
}

// ---------------------------------------------------------------------------
// Self-test: runs every registered option once and writes a marker before each, so errors in the console log
// point at the feature. Skips destructive buttons. Restores toggles that were on.
// ---------------------------------------------------------------------------

function selftest()
{
	self endon( "disconnect" );
	self notify( "offm_selftest" );
	self endon( "offm_selftest" );
	skip = array( "Suicide", "Kill", "End Game", "Restart Map", "Fast Restart", "Kick", "Kick All Bots", "Take All Weapons",
		"Take", "Take Current", "Drop", "Drop Current", "To Sky (+2000)", "Run Self-Test", "Remove All", "Give All", "Add",
		"Upgrade All", "Give 10,000 Points", "Give All Perks", "Revive", "Freeze", "Unfreeze",
		// would change the match itself (rounds, points, doors, power) or move the player
		"Apply", "Skip 1", "Skip 5", "Reset to 500", "Open All Doors & Debris", "Turn On Power", "Load", "Back to Spawn",
		"To Crosshair", "Teleport to Pack-a-Punch", "All Players to Me", "All Zombies to Crosshair", "All Bots to Crosshair",
		"Allies Spawn", "Axis Spawn", "Random Spawn", "Map Centre", "Player Spawn", "Power Switch", "Bring to Me", "Go to Player" );
	skip_toggles = array( "freezetime", "nospawn", "pauserounds", "freezezm", "noclip", "hidehud", "invisible", "ov_on", "esp_on" );
	was_on = [];
	foreach ( key, fn in self.offm.toggle_fns )
	{
		if ( self get_state( key ) )
			was_on[ was_on.size ] = key;
	}

	self IPrintLnBold( "SYNTHEX self-test running..." );
	count = 0;
	foreach ( t in self.offm.tabs )
	{
		foreach ( s in t.sides )
		{
			if ( isdefined( s.fill ) )
			{
				PrintLnMarker( self, "fill " + t.id + "/" + s.id );
				s.cards = [];
				self.offm.b_side = s;
				self [[ s.fill ]]();
				wait 0.1;
			}
			foreach ( c in s.cards )
			{
				foreach ( r in c.rows )
				{
					tag = t.id + "/" + s.id + "/" + r.label;
					if ( r.kind == "toggle" && isdefined( r.fn ) && !IsInArray( skip_toggles, r.key ) )
					{
						PrintLnMarker( self, "toggle " + tag );
						self thread [[ r.fn ]]( true, r.key );
						wait 0.25;
						self thread [[ r.fn ]]( false, r.key );
						wait 0.15;
						count++;
					}
					else if ( ( r.kind == "slider" || r.kind == "choice" ) && isdefined( r.fn ) )
					{
						PrintLnMarker( self, "value " + tag );
						self thread [[ r.fn ]]( r.values[ self.offm_val[ r.key ] ], r.key );
						wait 0.15;
						count++;
					}
					else if ( r.kind == "button" && isdefined( r.fn ) && !IsInArray( skip, r.label ) )
					{
						PrintLnMarker( self, "button " + tag );
						self thread call_button( r );
						wait 0.3;
						count++;
					}
				}
			}
		}
	}
	foreach ( key in was_on )
		self thread [[ self.offm.toggle_fns[ key ] ]]( true, key );
	PrintLnMarker( self, "done " + count );
	self IPrintLnBold( "SYNTHEX self-test done (" + count + " checks)" );
}

function private PrintLnMarker( player, text )
{
	player IPrintLn( "^0SXT " + text );
}

// GSC has no ?: operator. Both values are evaluated, so only use this when both are safe to read.
function pick( cond, a, b )
{
	if ( IS_TRUE( cond ) )
		return a;
	return b;
}
