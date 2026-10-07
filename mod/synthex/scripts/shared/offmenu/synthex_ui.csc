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
	clientfield::register( "actor", "synthex_zcham", VERSION_SHIP, 6, "int", &on_zcham, !CF_HOST_ONLY, !CF_CALLBACK_ZERO_ON_NEW_ENT );
	register_cham_filters();
}

// ---------------------------------------------------------------------------
// Zombie chams. Value = style * 8 + colour. Styles: 1 solid (material swap, depth tested),
// 2 through walls (extra pass, no depth test), 3 thermal, 4 = 1 + 2. Materials: mc/sx_cham_<colour>[_z]
// (materialType hud_outline_model[_z], flat "Tint" colour; see gdts/synthex.gdt).
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
		solid = "sxzc_" + ( 8 + c );
		walls = "sxzc_" + ( 16 + c );
		duplicate_render::set_dr_filter_framebuffer( solid, 40, solid, undefined, DR_TYPE_FRAMEBUFFER, "mc/sx_cham_" + cols[ c ] + "_z", DR_CULL_NEVER );
		duplicate_render::set_dr_filter_framebuffer_duplicate( walls, 40, walls, undefined, DR_TYPE_FRAMEBUFFER_DUPLICATE, "mc/sx_cham_" + cols[ c ], DR_CULL_NEVER );
	}
	duplicate_render::set_dr_filter_framebuffer( "sxzc_thermal", 40, "sxzc_thermal", undefined, DR_TYPE_FRAMEBUFFER, DR_METHOD_THERMAL_MATERIAL, DR_CULL_NEVER );
}

function private cham_flags( v )
{
	flags = [];
	if ( v <= 0 )
		return flags;
	style = Int( v / 8 );
	c = v % 8;
	if ( style == 1 || style == 4 )
		flags[ flags.size ] = "sxzc_" + ( 8 + c );
	if ( style == 2 || style == 4 )
		flags[ flags.size ] = "sxzc_" + ( 16 + c );
	if ( style == 3 )
		flags[ flags.size ] = "sxzc_thermal";
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
