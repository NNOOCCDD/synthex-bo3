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
//   5 rim glow, 6 glitch, 7 hex shimmer (extra pass over the zombie)   8 flow, 9 hacked (material swap)
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
		add_cham_filter( 6, c, true, "mc/sx_cham_glitch_" + col );
		add_cham_filter( 7, c, true, "mc/sx_cham_clone_" + col );
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

function private cham_flags( v )
{
	flags = [];
	if ( v <= 0 )
		return flags;
	style = Int( v / 8 );
	c = v % 8;
	if ( style == 3 )
		flags[ flags.size ] = "sxzc_thermal";
	else if ( style == 4 )
	{
		flags[ flags.size ] = "sxzc_" + ( 8 + c );
		flags[ flags.size ] = "sxzc_" + ( 16 + c );
	}
	else
		flags[ flags.size ] = "sxzc_" + v;
	return flags;
}

function private on_zcham( localClientNum, oldVal, newVal, bNewEnt, bInitialSnap, fieldName, bWasTimeJump )
{
	foreach ( f in cham_flags( oldVal ) )
		self duplicate_render::set_dr_flag( f, false );
	foreach ( f in cham_flags( newVal ) )
		self duplicate_render::set_dr_flag( f, true );
	self duplicate_render::update_dr_filters( localClientNum );
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
