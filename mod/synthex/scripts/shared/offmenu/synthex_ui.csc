// SYNTHEX.VIP - client side: loads the Lua menu + overlay, and draws the screen filters chosen in World > Filters.

#using scripts\codescripts\struct;
#using scripts\shared\clientfield_shared;
#using scripts\shared\duplicaterender_mgr;
#using scripts\shared\filter_shared;
#using scripts\shared\system_shared;

#insert scripts\shared\duplicaterender.gsh;
#insert scripts\shared\shared.gsh;
#insert scripts\shared\version.gsh;

#namespace synthex_ui;

#define SX_FILTER_SLOT 6

REGISTER_SYSTEM( "synthex_ui", &__init__, "duplicate_render" )

function __init__()
{
	LuiLoad( "ui.synthex.synthex_menu" );
	LuiLoad( "ui.synthex.synthex_overlay" );
	clientfield::register( "toplayer", "synthex_filter", VERSION_SHIP, 4, "int", &on_filter, !CF_HOST_ONLY, !CF_CALLBACK_ZERO_ON_NEW_ENT );
	clientfield::register( "actor", "synthex_zcham", VERSION_SHIP, 9, "int", &on_zcham, !CF_HOST_ONLY, !CF_CALLBACK_ZERO_ON_NEW_ENT );
	// gun chams: same materials on the local player, which the engine also applies to the first-person gun
	clientfield::register( "toplayer", "synthex_gcham", VERSION_SHIP, 9, "int", &on_gcham, !CF_HOST_ONLY, !CF_CALLBACK_ZERO_ON_NEW_ENT );
	register_cham_filters();
}

// ---------------------------------------------------------------------------
// Zombie chams. Clientfield value = speed * 128 + style * 8 + colour.
// Styles: 1 solid (material swap, depth tested)  2 through walls (extra pass, no depth test)  3 thermal  4 = 1 + 2
//         5 rim glow (extra pass)  6 glitch  7 hex shimmer  8 flow  9 hacked (material swap)
// Colours 0..6 (see cham_colours), 7 = rainbow: cycles the colours (speed 0..3 = 4 / 2.4 / 1.2 / 0.6 s per cycle).
// Materials mc/sx_cham_<style>_<colour> come from tools/gen_chams.py. Keep their number small (49): the client
// only maps a limited number of duplicate-render materials, and past that styles silently stop drawing.
// ---------------------------------------------------------------------------

function private cham_colours()
{
	return array( "pink", "red", "orange", "yellow", "green", "cyan", "blue" );
}

function private style_material( style )
{
	switch ( style )
	{
		case 1: return "z";
		case 2: return "w";
		case 5: return "rim";
		case 6: return "glitch";
		case 7: return "clone";
		case 8: return "flow";
	}
	return "hacked";
}

function private register_cham_filters()
{
	foreach ( style in array( 1, 2, 5, 6, 7, 8, 9 ) )
	{
		// through walls and rim glow are drawn again on top of the zombie; the rest replace its material
		overlay = ( style == 2 || style == 5 );
		foreach ( k in cham_colours() )
		{
			name = "sxzc_" + style + "_" + k;
			material = "mc/sx_cham_" + style_material( style ) + "_" + k;
			if ( overlay )
				duplicate_render::set_dr_filter_framebuffer_duplicate( name, 40, name, undefined, DR_TYPE_FRAMEBUFFER_DUPLICATE, material, DR_CULL_NEVER );
			else
				duplicate_render::set_dr_filter_framebuffer( name, 40, name, undefined, DR_TYPE_FRAMEBUFFER, material, DR_CULL_NEVER );
		}
	}
	// gun chams: the first-person gun has its own depth range and the zombie overlays draw over opaque passes,
	// so solid / flow / hacked go on the gun as an extra pass instead (same materials, no new ones)
	foreach ( k in cham_colours() )
	{
		duplicate_render::set_dr_filter_framebuffer_duplicate( "sxgc_1_" + k, 41, "sxgc_1_" + k, undefined, DR_TYPE_FRAMEBUFFER_DUPLICATE, "mc/sx_cham_w_" + k, DR_CULL_NEVER );
		duplicate_render::set_dr_filter_framebuffer_duplicate( "sxgc_8_" + k, 41, "sxgc_8_" + k, undefined, DR_TYPE_FRAMEBUFFER_DUPLICATE, "mc/sx_cham_flow_" + k, DR_CULL_NEVER );
		duplicate_render::set_dr_filter_framebuffer_duplicate( "sxgc_9_" + k, 41, "sxgc_9_" + k, undefined, DR_TYPE_FRAMEBUFFER_DUPLICATE, "mc/sx_cham_hacked_" + k, DR_CULL_NEVER );
	}
	duplicate_render::set_dr_filter_framebuffer( "sxzc_thermal", 40, "sxzc_thermal", undefined, DR_TYPE_FRAMEBUFFER, DR_METHOD_THERMAL_MATERIAL, DR_CULL_NEVER );
}

function private cham_flags( style, key, gun )
{
	flags = [];
	if ( IS_TRUE( gun ) && ( style == 1 || style == 8 || style == 9 ) )
		flags[ flags.size ] = "sxgc_" + style + "_" + key;
	else if ( style == 3 )
		flags[ flags.size ] = "sxzc_thermal";
	else if ( style == 4 )
	{
		flags[ flags.size ] = "sxzc_1_" + key;
		flags[ flags.size ] = "sxzc_2_" + key;
	}
	else if ( style > 0 )
		flags[ flags.size ] = "sxzc_" + style + "_" + key;
	return flags;
}

function private set_cham_flags( localClientNum, flags )
{
	if ( isdefined( self.sx_cham_flags ) )
	{
		foreach ( f in self.sx_cham_flags )
			self duplicate_render::set_dr_flag( f, false );
	}
	foreach ( f in flags )
		self duplicate_render::set_dr_flag( f, true );
	self.sx_cham_flags = flags;
	self duplicate_render::update_dr_filters( localClientNum );
}

function private on_zcham( localClientNum, oldVal, newVal, bNewEnt, bInitialSnap, fieldName, bWasTimeJump )
{
	self apply_cham( localClientNum, newVal, false );
}

function private on_gcham( localClientNum, oldVal, newVal, bNewEnt, bInitialSnap, fieldName, bWasTimeJump )
{
	self apply_cham( localClientNum, newVal, true );
}

function private apply_cham( localClientNum, newVal, gun )
{
	self notify( "sx_rainbow" );
	speed = Int( newVal / 128 );
	style = Int( ( newVal % 128 ) / 8 );
	c = newVal % 8;
	if ( c == 7 && style != 3 && style > 0 )
	{
		self thread rainbow( localClientNum, style, speed, gun );
		return;
	}
	cols = cham_colours();
	if ( c > 6 )
		c = 0;
	self set_cham_flags( localClientNum, cham_flags( style, cols[ c ], gun ) );
}

// all zombies use the same clock, so they change colour together
function private rainbow( localClientNum, style, speed, gun )
{
	self endon( "sx_rainbow" );
	self endon( "entityshutdown" );
	order = array( "red", "orange", "yellow", "green", "cyan", "blue", "pink" );
	cycles = array( 4000, 2400, 1200, 600 );
	cycle = cycles[ speed ];
	last = -1;
	for ( ;; )
	{
		i = Int( GetServerTime( localClientNum ) * order.size / cycle ) % order.size;
		if ( i != last )
		{
			self set_cham_flags( localClientNum, cham_flags( style, order[ i ], gun ) );
			last = i;
		}
		WAIT_CLIENT_FRAME;
	}
}

// 1 frost, 2 glitch, 3 overdrive, 4 underwater, 5 rain, 6 radial blur, 7 speed burst, 8 static, 9 emp
function private on_filter( localClientNum, oldVal, newVal, bNewEnt, bInitialSnap, fieldName, bWasTimeJump )
{
	player = GetLocalPlayer( localClientNum );
	if ( !isdefined( player ) )
		return;
	disable( player, oldVal );
	enable( player, newVal );
}

function private enable( player, v )
{
	switch ( v )
	{
		case 1: filter::init_filter_frost( player ); filter::enable_filter_frost( player, SX_FILTER_SLOT ); filter::set_filter_frost_layer_one( player, SX_FILTER_SLOT, 1 ); filter::set_filter_frost_layer_two( player, SX_FILTER_SLOT, 1 ); break;
		case 2: filter::init_filter_ev_interference( player ); filter::enable_filter_ev_interference( player, SX_FILTER_SLOT ); filter::set_filter_ev_interference_amount( player, SX_FILTER_SLOT, 1 ); break;
		case 3: filter::init_filter_overdrive( player ); filter::enable_filter_overdrive( player, SX_FILTER_SLOT ); filter::set_filter_overdrive( player, SX_FILTER_SLOT, 0, 1 ); break;
		case 4: filter::init_filter_water_dive( player ); filter::enable_filter_water_dive( player, SX_FILTER_SLOT ); filter::set_filter_water_dive_bubbles( player, SX_FILTER_SLOT, 1 ); break;
		case 5: filter::init_filter_raindrops( player ); filter::enable_filter_raindrops( player, SX_FILTER_SLOT ); filter::set_filter_raindrops_amount( player, SX_FILTER_SLOT, 1.0 ); break;
		case 6: filter::init_filter_radialblur( player ); filter::enable_filter_radialblur( player, SX_FILTER_SLOT ); filter::set_filter_radialblur_amount( player, SX_FILTER_SLOT, 1.0 ); break;
		case 7: filter::init_filter_speed_burst( player ); filter::enable_filter_speed_burst( player, SX_FILTER_SLOT ); filter::set_filter_speed_burst( player, SX_FILTER_SLOT, 0, 1 ); break;
		case 8: filter::init_filter_oob( player ); filter::enable_filter_oob( player, SX_FILTER_SLOT ); break;
		case 9: filter::init_filter_emp( player ); filter::enable_filter_emp( player, SX_FILTER_SLOT ); filter::set_filter_emp_amount( player, SX_FILTER_SLOT, 1.0 ); break;
	}
}

function private disable( player, v )
{
	switch ( v )
	{
		case 1: filter::disable_filter_frost( player, SX_FILTER_SLOT ); break;
		case 2: filter::disable_filter_ev_interference( player, SX_FILTER_SLOT ); break;
		case 3: filter::disable_filter_overdrive( player, SX_FILTER_SLOT ); break;
		case 4: filter::disable_filter_water_dive( player, SX_FILTER_SLOT ); break;
		case 5: filter::disable_filter_raindrops( player, SX_FILTER_SLOT ); break;
		case 6: filter::disable_filter_radialblur( player, SX_FILTER_SLOT ); break;
		case 7: filter::disable_filter_speed_burst( player, SX_FILTER_SLOT ); break;
		case 8: filter::disable_filter_oob( player, SX_FILTER_SLOT ); break;
		case 9: filter::disable_filter_emp( player, SX_FILTER_SLOT ); break;
	}
}
