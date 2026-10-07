// SYNTHEX.VIP - client side: loads the Lua menu + overlay, and draws the screen filters chosen in World > Filters.

#using scripts\codescripts\struct;
#using scripts\shared\clientfield_shared;
#using scripts\shared\filter_shared;
#using scripts\shared\system_shared;

#insert scripts\shared\shared.gsh;
#insert scripts\shared\version.gsh;

#namespace synthex_ui;

#define SX_FILTER_SLOT 6

REGISTER_SYSTEM( "synthex_ui", &__init__, undefined )

function __init__()
{
	LuiLoad( "ui.synthex.synthex_menu" );
	LuiLoad( "ui.synthex.synthex_overlay" );
	clientfield::register( "toplayer", "synthex_filter", VERSION_SHIP, 4, "int", &on_filter, !CF_HOST_ONLY, !CF_CALLBACK_ZERO_ON_NEW_ENT );
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
