// SYNTHEX.VIP - stats overlay. Drawn in Lua (ui/synthex/synthex_overlay.lua), which reads its settings from the
// menu state and its numbers from sx_stats. This file registers the settings, opens / closes the overlay and keeps
// stats flowing while it is shown.

#using scripts\codescripts\struct;
#using scripts\shared\util_shared;
#using scripts\shared\offmenu\offmenu_core;

#insert scripts\shared\shared.gsh;

#precache( "eventstring", "sx_flash" );

#namespace offmenu_overlay;

// Kept so mode files can describe their stats; the Lua overlay has its own matching rows.
function add_stat( key, label, kind, value_fn, default_on )
{
	if ( !isdefined( level.offm_ov_stats ) )
		level.offm_ov_stats = [];
	s = SpawnStruct();
	s.key = key;
	s.label = label;
	s.default_on = default_on;
	level.offm_ov_stats[ level.offm_ov_stats.size ] = s;
}

// Builds Player > Overlay (keys must match OverlaySide() in synthex_spec.lua).
function build_page( tab_id, flash_label )
{
	self offmenu::side( tab_id, "overlay", "Overlay" );

	self offmenu::card( 0, "Stats Overlay" );
	self offmenu::toggle( "Enabled", "ov_on", &toggle_overlay, false );
	self offmenu::choice( "Position", "ov_pos", array( "tr", "tl", "br", "bl" ), array( "Top Right", "Top Left", "Bottom Right", "Bottom Left" ), 0 );
	self offmenu::slider( "Opacity", "ov_alpha", array( 0.3, 0.5, 0.65, 0.8, 0.95 ), array( "30%", "50%", "65%", "80%", "95%" ), 3 );
	self offmenu::choice( "Size", "ov_size", array( 0.85, 1.0, 1.2 ), array( "Small", "Medium", "Large" ), 1 );
	self offmenu::toggle( "Show Logo", "ov_logo", &noop, false );

	self offmenu::card( 1, "Show" );
	foreach ( s in level.offm_ov_stats )
	{
		key = "ov_s_" + s.key;
		if ( !isdefined( self.offm_state[ key ] ) )
			self.offm_state[ key ] = IS_TRUE( s.default_on );
		self offmenu::toggle( s.label, key, &noop, false );
	}

	self offmenu::card( 2, "Extras" );
	self offmenu::toggle( "Active Features", "ov_tags", &noop, false );
	self offmenu::toggle( "Controls Hint", "ov_hint", &noop, false );
	self offmenu::toggle( flash_label, "ov_flash", &noop, false );
	self offmenu::toggle( "Hide While Menu Open", "ov_hidemenu", &noop, false );
}

function private noop( on, key )
{
}

// The Lua menu shows / hides the overlay itself; the script only keeps stats flowing while it's on.
function private toggle_overlay( on, key )
{
	self notify( "offm_ov_stop" );
	self.offm_ov_on = on;
	if ( on )
		self thread stats_loop();
}

function private stats_loop()
{
	self endon( "disconnect" );
	self endon( "offm_ov_stop" );
	for ( ;; )
	{
		if ( !IS_TRUE( self.offm.open ) )      // the menu sends its own stats while open
			self offmenu::send_stats();
		wait 1;
	}
}

// Short pink flash on the overlay - called by mode files on a new round / streak.
function flash()
{
	if ( IS_TRUE( self.offm_ov_on ) )
		self LUINotifyEvent( &"sx_flash", 0 );
}
