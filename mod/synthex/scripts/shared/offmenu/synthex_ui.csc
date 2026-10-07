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
	clientfield::register( "actor", "synthex_zcham", VERSION_SHIP, 7, "int", &on_zcham, !CF_HOST_ONLY, !CF_CALLBACK_ZERO_ON_NEW_ENT );
	register_cham_filters();
}

// ---------------------------------------------------------------------------
// Zombie chams. Value = style * 8 + colour. Styles:
//   1 solid (material swap, depth tested)   2 through walls (extra pass, no depth test)   3 thermal   4 = 1 + 2
//   5 rim glow (extra pass over the zombie)   6 glitch, 7 hex shimmer, 8 flow, 9 hacked (material swap)
// Glitch / hex shimmer materials ignore script vectors: zombies use scriptVector0 for their own damage effects.
// Materials mc/sx_cham_* are built from the game's Specialty techsets (see gdts/synthex.gdt).
// ---------------------------------------------------------------------------

function private cham_colours()
{
	return array( "pink", "red", "green", "cyan", "gold", "white", "purple" );
}

function private register_cham_filters()
{
	cols = cham_colours();
	for ( c = 0; c < cols.size; c++ )
	{
		col = cols[ c ];
		add_cham_filter( 1, c, false, "mc/sx_cham_" + col + "_z" );
		add_cham_filter( 2, c, true, "mc/sx_cham_" + col );
		add_cham_filter( 5, c, true, "mc/sx_cham_rim_" + col );
		add_cham_filter( 6, c, false, "mc/sx_cham_glitch_" + col );
		add_cham_filter( 7, c, false, "mc/sx_cham_clone_" + col );
		add_cham_filter( 8, c, false, "mc/sx_cham_flow_" + col );
		add_cham_filter( 9, c, false, "mc/sx_cham_hacked_" + col );
	}
	duplicate_render::set_dr_filter_framebuffer( "sxzc_thermal", 40, "sxzc_thermal", undefined, DR_TYPE_FRAMEBUFFER, DR_METHOD_THERMAL_MATERIAL, DR_CULL_NEVER );
}

// overlay = drawn again on top of the zombie; otherwise the zombie's own material is replaced
function private add_cham_filter( style, c, overlay, material )
{
	name = "sxzc_" + ( style * 8 + c );
	if ( overlay )
		duplicate_render::set_dr_filter_framebuffer_duplicate( name, 40, name, undefined, DR_TYPE_FRAMEBUFFER_DUPLICATE, material, DR_CULL_NEVER );
	else
		duplicate_render::set_dr_filter_framebuffer( name, 40, name, undefined, DR_TYPE_FRAMEBUFFER, material, DR_CULL_NEVER );
}

function private cham_rgb( c )
{
	switch ( c )
	{
		case 0: return ( 1, 0.31, 0.65 );
		case 1: return ( 1, 0.12, 0.12 );
		case 2: return ( 0.3, 1, 0.4 );
		case 3: return ( 0.2, 0.85, 1 );
		case 4: return ( 1, 0.75, 0.2 );
		case 5: return ( 1, 1, 1 );
	}
	return ( 0.62, 0.3, 1 );
}

// flags for style + colour (colour 7 = rainbow, drawn with the pink materials and re-tinted every frame)
function private cham_flags( style, c )
{
	flags = [];
	if ( c == 7 )
		c = 0;
	if ( style == 3 )
		flags[ flags.size ] = "sxzc_thermal";
	else if ( style == 4 )
	{
		flags[ flags.size ] = "sxzc_" + ( 8 + c );
		flags[ flags.size ] = "sxzc_" + ( 16 + c );
	}
	else if ( style > 0 )
		flags[ flags.size ] = "sxzc_" + ( style * 8 + c );
	return flags;
}

// styles whose colour is the material's "Tint" (cg02 = scriptVector2), so script can recolour them
function private tint_style( style )
{
	return style == 1 || style == 2 || style == 4 || style == 5;
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
	self notify( "sx_rainbow" );
	style = Int( newVal / 8 );
	c = newVal % 8;
	self set_cham_flags( localClientNum, cham_flags( style, c ) );
	if ( !tint_style( style ) )
	{
		if ( c == 7 && style != 3 )
			self thread rainbow_steps( localClientNum, style );
		return;
	}
	if ( c == 7 )
		self thread rainbow_tint( localClientNum );
	else
	{
		rgb = cham_rgb( c );
		self MapShaderConstant( localClientNum, 0, "scriptVector2", rgb[ 0 ], rgb[ 1 ], rgb[ 2 ], 1 );
	}
}

// hue 0..1 -> rgb
function private hue_rgb( t )
{
	h = ( t - Int( t ) ) * 6;	// t is never negative
	i = Int( h );
	f = h - i;
	q = 1 - f;
	switch ( i )
	{
		case 0: return ( 1, f, 0 );
		case 1: return ( q, 1, 0 );
		case 2: return ( 0, 1, f );
		case 3: return ( 0, q, 1 );
		case 4: return ( f, 0, 1 );
	}
	return ( 1, 0, q );
}

// smooth rainbow: one full cycle every 3 seconds, all zombies in step
function private rainbow_tint( localClientNum )
{
	self endon( "sx_rainbow" );
	self endon( "entityshutdown" );
	for ( ;; )
	{
		rgb = hue_rgb( GetServerTime( localClientNum ) / 3000.0 );
		self MapShaderConstant( localClientNum, 0, "scriptVector2", rgb[ 0 ], rgb[ 1 ], rgb[ 2 ], 1 );
		WAIT_CLIENT_FRAME;
	}
}

// glitch / hex shimmer / flow / hacked have the colour baked in: step through the colours in hue order
function private rainbow_steps( localClientNum, style )
{
	self endon( "sx_rainbow" );
	self endon( "entityshutdown" );
	order = array( 1, 4, 2, 3, 6, 0 );
	for ( i = 0; ; i = ( i + 1 ) % order.size )
	{
		self set_cham_flags( localClientNum, cham_flags( style, order[ i ] ) );
		wait 0.2;
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
		case 1: filter::init_filter_frost( player ); filter::enable_filter_frost( player, SX_FILTER_SLOT ); break;
		case 2: filter::init_filter_ev_interference( player ); filter::enable_filter_ev_interference( player, SX_FILTER_SLOT ); break;
		case 3: filter::init_filter_overdrive( player ); filter::enable_filter_overdrive( player, SX_FILTER_SLOT ); break;
		case 4: filter::init_filter_water_dive( player ); filter::enable_filter_water_dive( player, SX_FILTER_SLOT ); break;
		case 5: filter::init_filter_raindrops( player ); filter::enable_filter_raindrops( player, SX_FILTER_SLOT ); filter::set_filter_raindrops_amount( player, SX_FILTER_SLOT, 1.0 ); break;
		case 6: filter::init_filter_radialblur( player ); filter::enable_filter_radialblur( player, SX_FILTER_SLOT ); filter::set_filter_radialblur_amount( player, SX_FILTER_SLOT, 1.0 ); break;
		case 7: filter::init_filter_speed_burst( player ); filter::enable_filter_speed_burst( player, SX_FILTER_SLOT ); break;
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
