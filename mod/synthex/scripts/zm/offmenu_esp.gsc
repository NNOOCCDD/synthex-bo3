// SYNTHEX.VIP - Zombie ESP (zombies mode only, AI enemies and map items; never players).
// Markers are per-player waypoint hud elems that follow their target (see shared/entityheadicons_shared.gsc).
// ESP pauses while the menu is open to keep the hud elem count down.

#using scripts\codescripts\struct;
#using scripts\shared\clientfield_shared;
#using scripts\shared\util_shared;
#using scripts\shared\offmenu\offmenu_core;

#insert scripts\shared\shared.gsh;


#precache( "material", "white" );
#precache( "material", "synthex_esp_diamond" );
#precache( "material", "synthex_esp_dot" );
#precache( "material", "synthex_esp_box" );
#precache( "material", "headicon_dead" );

#namespace offmenu_esp;

// Script hud elems a client actually draws: ~22 regular + ~26 archival. Markers use the regular list,
// health bars and map items the archival one.
#define ESP_MAX_MARKERS   20
#define ESP_MAX_ARCHIVAL  24

// Constant-size waypoints ignore the SetShader size, so markers are 3D waypoints (size in world units)
// rescaled with distance every tick: world size = screen size * distance / ESP_PX_SCALE.
#define ESP_PX_SCALE      500

// ---------------------------------------------------------------------------
// Pages: ESP tab with Enemies / Style / Labels / Map Items
// ---------------------------------------------------------------------------

function build_tab()
{
	self offmenu::tab( "esp", "ESP" );
	colors = array( "pink", "gold", "red", "white", "green", "cyan" );
	color_labels = array( "Pink", "Gold", "Red", "White", "Green", "Cyan" );

	self offmenu::side( "esp", "enemies", "Enemies" );
	self offmenu::card( 0, "Zombie ESP" );
	self offmenu::toggle( "Enabled", "esp_on", &on_toggle );
	self offmenu::toggle( "Through Walls", "esp_walls", &noop );
	self offmenu::slider( "Max Distance", "esp_dist", array( 750, 1500, 3000, 6000, 100000 ), array( "750", "1,500", "3,000", "6,000", "Any" ), 2 );
	self offmenu::slider( "Max Markers", "esp_max", array( 8, 16, 24, 32 ), array( "8", "16", "24", "32" ), 2 );
	self offmenu::card( 1, "Show" );
	self offmenu::toggle( "Regular Zombies", "esp_reg", &noop );
	self offmenu::toggle( "Crawlers", "esp_crawl", &noop );
	self offmenu::toggle( "Special Enemies", "esp_spec", &noop, undefined, "dogs, spiders" );
	self offmenu::toggle( "Bosses", "esp_boss", &noop, undefined, "Margwa, Panzer" );
	self offmenu::card( 2, "Live" );
	self offmenu::stat( "Tracked", &live_tracked );
	self offmenu::stat( "Nearest", &live_nearest );
	self offmenu::stat( "Specials", &live_specials );
	self offmenu::stat( "Out of Range", &live_out_of_range );

	self offmenu::side( "esp", "style", "Style" );
	self offmenu::card( 0, "Marker" );
	self offmenu::choice( "Style", "esp_style", array( "synthex_esp_diamond", "synthex_esp_dot", "synthex_esp_box", "headicon_dead" ), array( "Diamond", "Dot", "Box", "Skull" ), 0 );
	self offmenu::slider( "Size", "esp_size", array( 3, 5, 8, 12, 16, 22 ), array( "XS", "S", "M", "L", "XL", "XXL" ), 2 );
	self offmenu::slider( "Opacity", "esp_alpha", array( 0.4, 0.6, 0.85, 1.0 ), array( "40%", "60%", "85%", "100%" ), 2 );
	self offmenu::card( 1, "Colours" );
	self offmenu::choice( "Regular", "esp_c_reg", colors, color_labels, 0 );
	self offmenu::choice( "Special", "esp_c_spec", colors, color_labels, 1 );
	self offmenu::choice( "Boss", "esp_c_boss", colors, color_labels, 2 );
	self offmenu::toggle( "Red When Close", "esp_redclose", &noop );
	self offmenu::slider( "Close Range", "esp_close", array( 150, 300, 500, 800 ), array( "150", "300", "500", "800" ), 1 );

	self offmenu::side( "esp", "labels", "Labels" );
	self offmenu::card( 0, "Labels" );
	self offmenu::toggle( "Distance", "esp_l_dist", &noop );
	self offmenu::toggle( "Health Bar", "esp_l_hp", &noop );
	self offmenu::card( 1, "Behaviour" );
	self offmenu::toggle( "Edge Arrows", "esp_edge", &noop, undefined, "off-screen" );
	self offmenu::toggle( "Nearest Zombie Only", "esp_nearest", &noop );
	self offmenu::toggle( "Pulse When Close", "esp_pulse", &noop );

	self offmenu::side( "esp", "items", "Map Items" );
	self offmenu::card( 0, "Items" );
	self offmenu::toggle( "Mystery Box", "esp_i_box", &noop );
	self offmenu::toggle( "Pack-a-Punch", "esp_i_pap", &noop );
	self offmenu::toggle( "Perk Machines", "esp_i_perks", &noop );
	self offmenu::toggle( "Wall Weapons", "esp_i_wall", &noop );
	self offmenu::toggle( "Buildable Parts", "esp_i_parts", &noop );
	self offmenu::toggle( "Power-Ups On Ground", "esp_i_pow", &noop );
	self offmenu::card( 1, "Style" );
	self offmenu::choice( "Colour", "esp_c_item", colors, color_labels, 3 );
	self offmenu::slider( "Size", "esp_i_size", array( 3, 5, 8, 12, 16, 22 ), array( "XS", "S", "M", "L", "XL", "XXL" ), 2 );

	self offmenu::side( "esp", "chams", "Chams" );
	self offmenu::card( 0, "Zombie Chams" );
	self offmenu::toggle( "Enabled", "zc_on", &toggle_chams );
	self offmenu::choice( "Style", "zc_style", array( 1, 2, 4, 3 ), array( "Solid", "Through Walls", "Solid + Walls", "Thermal" ), 2, &chams_changed );
	self offmenu::choice( "Colour", "zc_col", array( 0, 1, 2, 3, 4, 5, 6 ), array( "Pink", "Red", "Green", "Cyan", "Gold", "White", "Purple" ), 0, &chams_changed );
	self offmenu::card( 1, "About" );
	self offmenu::note( "Solid: zombies drawn in one flat colour." );
	self offmenu::note( "Through Walls: coloured silhouette you can see through walls." );
	self offmenu::note( "Thermal: heat-vision look." );

	// defaults (first build only)
	if ( !isdefined( self.offm_state[ "esp_init" ] ) )
	{
		self.offm_state[ "esp_init" ] = true;
		foreach ( k in array( "esp_walls", "esp_reg", "esp_crawl", "esp_spec", "esp_boss", "esp_redclose", "esp_l_dist", "esp_edge", "esp_pulse", "esp_i_box", "esp_i_pap", "esp_i_parts", "esp_i_pow" ) )
			self.offm_state[ k ] = true;
	}

	self thread watch_menu();
}

function private noop( a, b )
{
}

function private on_toggle( on, key )
{
	self notify( "offm_esp_stop" );
	self clear_markers();
	if ( on )
		self thread esp_loop();
}

function private watch_menu()
{
	self endon( "disconnect" );
	for ( ;; )
	{
		self util::waittill_any( "offm_opened", "offm_closed" );
		if ( !self offmenu::get_state( "esp_on" ) )
			continue;
		self notify( "offm_esp_stop" );
		self clear_markers();
		if ( !self.offm.open )
			self thread esp_loop();
	}
}

// ---------------------------------------------------------------------------
// Classification
// ---------------------------------------------------------------------------

function classify( ai )
{
	switch ( ai.archetype )
	{
		case "margwa":
		case "mechz":
		case "thrasher":
		case "raz":
		case "sentinel_drone":
		case "apothicon_fury":
			return "boss";
		case "zombie":
			if ( IS_TRUE( ai.missinglegs ) )
				return "crawl";
			return "reg";
		case "zombie_quad":
			return "reg";
	}
	return "spec";
}

function private wanted( cls )
{
	return self offmenu::get_state( "esp_" + cls );
}

function private color_value( name )
{
	switch ( name )
	{
		case "pink":  return ( 1, 0.31, 0.65 );
		case "gold":  return ( 0.95, 0.76, 0.31 );
		case "red":   return ( 1, 0.35, 0.35 );
		case "green": return ( 0.4, 0.95, 0.5 );
		case "cyan":  return ( 0.35, 0.85, 1 );
	}
	return ( 0.9, 0.9, 0.91 );
}

// ---------------------------------------------------------------------------
// Markers
// ---------------------------------------------------------------------------

function private clear_markers()
{
	foreach ( list in array( self.offm_esp_tracked, self.offm_esp_items, self.offm_esp_bars ) )
	{
		if ( !isdefined( list ) )
			continue;
		foreach ( m in list )
		{
			if ( isdefined( m ) )
				m Destroy();
		}
	}
	self.offm_esp_tracked = [];
	self.offm_esp_items = [];
	self.offm_esp_bars = [];
}

function private make_marker( target, offset_z, material, size, color, alpha, show_dist, edge, archived )
{
	m = NewClientHudElem( self );
	m.archived = IS_TRUE( archived );
	m.hidewheninmenu = true;
	m.x = 0;
	m.y = 0;
	m.z = offset_z;
	m.color = color;
	m.alpha = alpha;
	m.offm_edge = edge;
	m.offm_dist = show_dist;
	m.offm_target = target;
	m.offm_ws = size;
	m.offm_hs = size;
	m SetShader( material, size, size );
	m apply_waypoint( material );
	return m;
}

// SetShader turns a waypoint back into a plain screen icon, so every resize must redo the waypoint
// and the target.
function private apply_waypoint( material )
{
	if ( IS_TRUE( self.offm_edge ) )
		self SetWaypoint( false, material, IS_TRUE( self.offm_dist ), false );
	else
		self SetWaypoint( false, undefined, IS_TRUE( self.offm_dist ), true );
	if ( isdefined( self.offm_target ) )
		self SetTargetEnt( self.offm_target );
}

function private make_point_marker( origin, material, size, color, alpha )
{
	m = NewClientHudElem( self );
	m.archived = true;
	m.hidewheninmenu = true;
	m.x = origin[ 0 ];
	m.y = origin[ 1 ];
	m.z = origin[ 2 ] + 40;
	m.color = color;
	m.alpha = alpha;
	ws = world_size( size, Distance( self.origin, origin ) );
	m SetShader( material, ws, ws );
	m SetWaypoint( false, undefined, false, true );
	return m;
}

// on-screen size (px) -> world size at distance d
function private world_size( px, d )
{
	return int( max( 1, px * max( d, 1 ) / ESP_PX_SCALE + 0.5 ) );
}

function private set_marker_size( m, material, w, h )
{
	// only resize on a real change (>15%), each resize rebuilds the waypoint
	if ( isdefined( m.offm_ws ) && isdefined( m.offm_hs ) && abs( m.offm_ws - w ) <= m.offm_ws * 0.15 && abs( m.offm_hs - h ) <= m.offm_hs * 0.15 )
		return;
	if ( !isdefined( m.offm_target ) || IsAlive( m.offm_target ) )
	{
		m SetShader( material, w, h );
		m apply_waypoint( material );
	}
	m.offm_ws = w;
	m.offm_hs = h;
}

function private esp_loop()
{
	self endon( "disconnect" );
	self endon( "offm_esp_stop" );

	self.offm_esp_live = SpawnStruct();
	tracked = [];      // entnum -> marker
	bars = [];         // entnum -> health bar
	item_tick = 0;

	for ( ;; )
	{
		max_dist = self offmenu::get_value( "esp_dist" );
		max_n = self offmenu::get_value( "esp_max" );
		material = self offmenu::get_value( "esp_style" );
		size = self offmenu::get_value( "esp_size" );
		alpha = self offmenu::get_value( "esp_alpha" );
		close_r = self offmenu::get_value( "esp_close" );
		walls = self offmenu::get_state( "esp_walls" );
		eye = self GetEye();

		// Candidates sorted by distance
		cands = [];
		out_of_range = 0;
		specials = 0;
		foreach ( ai in GetAITeamArray( level.zombie_team ) )
		{
			if ( !IsAlive( ai ) )
				continue;
			cls = classify( ai );
			if ( cls == "spec" || cls == "boss" )
				specials++;
			if ( !self wanted( cls ) )
				continue;
			d = Distance( self.origin, ai.origin );
			if ( d > max_dist )
			{
				out_of_range++;
				continue;
			}
			if ( !walls && !SightTracePassed( eye, ai.origin + ( 0, 0, 48 ), false, ai ) )
				continue;
			c = SpawnStruct();
			c.ai = ai;
			c.cls = cls;
			c.d = d;
			cands[ cands.size ] = c;
		}
		cands = sort_by_distance( cands );
		if ( self offmenu::get_state( "esp_nearest" ) )
			max_n = 1;
		if ( max_n > ESP_MAX_MARKERS )
			max_n = ESP_MAX_MARKERS;
		show_hp = self offmenu::get_state( "esp_l_hp" );
		items_used = 0;
		if ( isdefined( self.offm_esp_items ) )
			items_used = self.offm_esp_items.size;
		max_bars = ESP_MAX_ARCHIVAL - items_used;

		keep = [];
		keep_bars = [];
		for ( i = 0; i < cands.size && i < max_n; i++ )
		{
			c = cands[ i ];
			num = c.ai GetEntityNumber();
			col = color_value( self offmenu::get_value( "esp_c_" + c.cls ) );
			if ( c.cls == "crawl" )
				col = color_value( self offmenu::get_value( "esp_c_reg" ) );
			if ( self offmenu::get_state( "esp_redclose" ) && c.d < close_r )
				col = ( 1, 0.2, 0.2 );

			m = tracked[ num ];
			if ( !isdefined( m ) || m.offm_material !== material )
			{
				if ( isdefined( m ) )
					m Destroy();
				// just above the head (bosses are taller)
				z = offmenu::pick( c.cls == "boss", 125, 84 );
				if ( c.cls == "crawl" )
					z = 40;
				m = self make_marker( c.ai, z, material, size, col, alpha, self offmenu::get_state( "esp_l_dist" ), self offmenu::get_state( "esp_edge" ), false );
				m.offm_z = z;
				m.offm_material = material;
			}
			ws = world_size( size, c.d );
			set_marker_size( m, material, ws, ws );
			m.color = col;
			if ( self offmenu::get_state( "esp_pulse" ) && c.d < close_r )
				m.alpha = offmenu::pick( int( GetTime() / 250 ) % 2 == 0, alpha, alpha * 0.35 );
			else
				m.alpha = alpha;
			keep[ num ] = m;

			// health bar: a thin bar just above the marker, green -> red as health drops
			if ( show_hp && keep_bars.size < max_bars )
			{
				b = bars[ num ];
				if ( !isdefined( b ) )
				{
					b = self make_marker( c.ai, m.offm_z, "white", 1, ( 0.4, 0.95, 0.5 ), alpha, false, false, true );
				}
				frac = 1.0;
				if ( isdefined( c.ai.maxhealth ) && c.ai.maxhealth > 0 )
					frac = max( 0.05, min( 1.0, c.ai.health / c.ai.maxhealth ) );
				// bar: 3x the marker width at full health, sits just above the marker
				bw = world_size( max( 3, size * 3 ) * frac, c.d );
				bh = world_size( max( 1.5, size * 0.3 ), c.d );
				set_marker_size( b, "white", bw, bh );
				b.z = m.offm_z + ws * 0.5 + bh + world_size( 2, c.d );
				b.color = ( 1 - frac, 0.35 + 0.6 * frac, 0.35 );
				b.alpha = alpha;
				keep_bars[ num ] = b;
			}
		}

		// Destroy markers / bars for zombies we no longer show
		foreach ( num, m in tracked )
		{
			if ( !isdefined( keep[ num ] ) && isdefined( m ) )
				m Destroy();
		}
		foreach ( num, b in bars )
		{
			if ( !isdefined( keep_bars[ num ] ) && isdefined( b ) )
				b Destroy();
		}
		tracked = keep;
		bars = keep_bars;
		self.offm_esp_tracked = tracked;
		self.offm_esp_bars = bars;

		self.offm_esp_live.tracked = keep.size;
		self.offm_esp_live.specials = specials;
		self.offm_esp_live.out = out_of_range;
		self.offm_esp_live.nearest = undefined;
		if ( cands.size > 0 )
			self.offm_esp_live.nearest = cands[ 0 ];

		// Map items refresh every second (also rescales them for distance)
		item_tick--;
		if ( item_tick <= 0 )
		{
			item_tick = 5;
			self refresh_items();
		}

		wait 0.2;
	}
}

function private sort_by_distance( arr )
{
	// insertion sort - arrays are small (<= ~30)
	for ( i = 1; i < arr.size; i++ )
	{
		cur = arr[ i ];
		j = i - 1;
		while ( j >= 0 && arr[ j ].d > cur.d )
		{
			arr[ j + 1 ] = arr[ j ];
			j--;
		}
		arr[ j + 1 ] = cur;
	}
	return arr;
}

function private refresh_items()
{
	if ( isdefined( self.offm_esp_items ) )
	{
		foreach ( m in self.offm_esp_items )
		{
			if ( isdefined( m ) )
				m Destroy();
		}
	}
	self.offm_esp_items = [];

	col = color_value( self offmenu::get_value( "esp_c_item" ) );
	size = self offmenu::get_value( "esp_i_size" );
	items = self.offm_esp_items;

	if ( self offmenu::get_state( "esp_i_box" ) && isdefined( level.chests ) && isdefined( level.chest_index ) && isdefined( level.chests[ level.chest_index ] ) )
		items[ items.size ] = self make_point_marker( level.chests[ level.chest_index ].origin, "synthex_esp_box", size, col, 0.9 );

	if ( self offmenu::get_state( "esp_i_pap" ) )
	{
		foreach ( e in GetEntArray( "zm_pack_a_punch", "targetname" ) )
			items[ items.size ] = self make_point_marker( e.origin, "synthex_esp_dot", size, col, 0.9 );
	}

	if ( self offmenu::get_state( "esp_i_perks" ) )
	{
		foreach ( e in GetEntArray( "zombie_vending", "targetname" ) )
			items[ items.size ] = self make_point_marker( e.origin, "synthex_esp_dot", size, col, 0.9 );
	}

	if ( self offmenu::get_state( "esp_i_wall" ) && isdefined( level._spawned_wallbuys ) )
	{
		foreach ( s in level._spawned_wallbuys )
		{
			if ( isdefined( s ) && isdefined( s.origin ) )
				items[ items.size ] = self make_point_marker( s.origin, "synthex_esp_dot", size, col, 0.7 );
		}
	}

	if ( self offmenu::get_state( "esp_i_pow" ) && isdefined( level.active_powerups ) )
	{
		foreach ( p in level.active_powerups )
		{
			if ( isdefined( p ) )
				items[ items.size ] = self make_point_marker( p.origin, "synthex_esp_dot", size, ( 0.4, 0.95, 0.5 ), 0.9 );
		}
	}

	if ( self offmenu::get_state( "esp_i_parts" ) && isdefined( level.zombie_include_craftables ) )
	{
		models = [];
		foreach ( craftable in level.zombie_include_craftables )
		{
			if ( !isdefined( craftable.a_pieceStubs ) )
				continue;
			foreach ( ps in craftable.a_pieceStubs )
			{
				if ( isdefined( ps.modelName ) )
					models[ ps.modelName ] = true;
			}
		}
		foreach ( e in GetEntArray( "script_model", "classname" ) )
		{
			if ( isdefined( e.model ) && isdefined( models[ e.model ] ) )
				items[ items.size ] = self make_point_marker( e.origin, "synthex_esp_dot", size, ( 0.35, 0.85, 1 ), 0.9 );
		}
	}

	self.offm_esp_items = items;
}

// ---------------------------------------------------------------------------
// Live stats on the Enemies page
// ---------------------------------------------------------------------------

function private live_tracked()
{
	if ( !isdefined( self.offm_esp_live ) )
		return 0;
	return int( self.offm_esp_live.tracked );
}

function private live_specials()
{
	if ( !isdefined( self.offm_esp_live ) )
		return 0;
	return int( self.offm_esp_live.specials );
}

function private live_out_of_range()
{
	if ( !isdefined( self.offm_esp_live ) )
		return 0;
	return int( self.offm_esp_live.out );
}

function private live_nearest()
{
	if ( !isdefined( self.offm_esp_live ) || !isdefined( self.offm_esp_live.nearest ) )
		return "-";
	n = self.offm_esp_live.nearest;
	switch ( n.cls )
	{
		case "boss":  return "Boss";
		case "spec":  return "Special";
		case "crawl": return "Crawler";
	}
	return "Zombie";
}

// ---------------------------------------------------------------------------
// Zombie chams: each zombie gets a clientfield, synthex_ui.csc swaps its material (duplicate render)
// ---------------------------------------------------------------------------

function private toggle_chams( on, key )
{
	self notify( "offm_chams_end" );
	if ( on )
		self thread chams_loop();
	else
		set_all_chams( 0 );
}

function private chams_changed( value, key )
{
	self notify( "offm_chams_refresh" );
}

function private chams_value()
{
	return self offmenu::get_value( "zc_style" ) * 8 + self offmenu::get_value( "zc_col" );
}

function private chams_loop()
{
	self endon( "disconnect" );
	self endon( "offm_chams_end" );
	for ( ;; )
	{
		set_all_chams( self chams_value() );
		self util::waittill_any_timeout( 0.3, "offm_chams_refresh" );
	}
}

function private set_all_chams( v )
{
	foreach ( ai in GetAITeamArray( level.zombie_team ) )
	{
		if ( !IsAlive( ai ) || ai.offm_zcham === v )
			continue;
		ai clientfield::set( "synthex_zcham", v );
		ai.offm_zcham = v;
	}
}
