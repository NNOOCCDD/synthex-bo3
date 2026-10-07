-- SYNTHEX.VIP - stats overlay (LUI). Opened by script with OpenLUIMenu( "SynthexOverlay", true ).
-- No input capture. Reads its settings from CoD.SynthexState (set in the main menu) and stats from
-- the same sx_stats events the menu uses. Script sends sx_flash on a new round / streak.

require( "ui.synthex.synthex_spec" )

local Spec = CoD.SynthexSpec
local FONT = "fonts/default.ttf"

local Col = {
	bg = { 0.114, 0.114, 0.122 }, line = { 0.224, 0.224, 0.235 }, text = { 0.85, 0.85, 0.86 },
	white = { 0.9, 0.9, 0.91 }, muted = { 0.55, 0.55, 0.565 }, dim = { 0.365, 0.365, 0.38 },
	pink = { 0.827, 0.612, 0.698 }, pinkdeep = { 0.659, 0.439, 0.541 }
}

CoD.SynthexState = CoD.SynthexState or { tab = 1, side = {}, cursor = {}, toggles = {}, values = {}, sel = {}, inited = false }
CoD.SynthexData = CoD.SynthexData or { stats = {}, lists = {} }
local State, Data = CoD.SynthexState, CoD.SynthexData

if not State.inited then
	for k, _ in pairs( Spec.DefaultOn ) do State.toggles[k] = true end
	State.inited = true
end

local function On( key ) return State.toggles[ key ] == true end
local function Val( key, def ) return State.values[ key ] or def end
local function S( i ) return Data.stats[i] or 0 end

local function Comma( n )
	local s = tostring( math.floor( n ) )
	local out = s:reverse():gsub( "(%d%d%d)", "%1," ):reverse()
	if out:sub( 1, 1 ) == "," then out = out:sub( 2 ) end
	return out
end

local function Clock( secs )
	secs = math.floor( secs or 0 )
	if secs < 0 then secs = 0 end
	return string.format( "%02d:%02d", math.floor( secs / 60 ), secs % 60 )
end

local function MapName()
	local m = Engine.GetCurrentMap()
	return Spec.MapNames[m] or m
end

-- key, label, value function (order = order shown)
local ZMRows = {
	{ "ov_s_round", "Round", function () return tostring( S( 0 ) ) end },
	{ "ov_s_left", "Zombies Left", function () return tostring( S( 5 ) ) end },
	{ "ov_s_points", "Points", function () return Comma( S( 1 ) ) end },
	{ "ov_s_kills", "Kills", function () return Comma( S( 2 ) ) end },
	{ "ov_s_hs", "Headshots", function () return Comma( S( 3 ) ) end },
	{ "ov_s_map", "Map", MapName },
	{ "ov_s_gtime", "Game Time", function () return Clock( S( 27 ) ) end },
	{ "ov_s_rtime", "Round Time", function () return Clock( S( 7 ) ) end },
	{ "ov_s_alive", "Players Alive", function () return tostring( S( 28 ) ) end }
}
local MPRows = {
	{ "ov_s_mode", "Mode", function ()
		local ok, n = pcall( function () return Engine.Localize( Engine.GetGametypeName() ) end )
		return ok and n or "-"
	end },
	{ "ov_s_score", "Team Score", function () return Comma( S( 0 ) ) end },
	{ "ov_s_time", "Time Left", function () return Clock( S( 5 ) ) end },
	{ "ov_s_kills", "Kills", function () return tostring( S( 1 ) ) end },
	{ "ov_s_deaths", "Deaths", function () return tostring( S( 2 ) ) end },
	{ "ov_s_pscore", "Your Score", function () return Comma( S( 3 ) ) end },
	{ "ov_s_spec", "Specialist", function () return tostring( S( 4 ) ) .. "%" end },
	{ "ov_s_bots", "Bots", function () return tostring( S( 6 ) ) end },
	{ "ov_s_map", "Map", MapName }
}

local Tags = { { "god", "GOD" }, { "ammo", "AMMO" }, { "esp_on", "ESP" }, { "noclip", "NOCLIP" }, { "invisible", "INVIS" }, { "ignoreme", "IGNORED" }, { "uav", "UAV" } }

local function Place( e, x, y, w, h )
	e:setLeftRight( true, false, x, x + w )
	e:setTopBottom( true, false, y, y + h )
end

local function Rect( parent, x, y, w, h, c, a )
	local e = LUI.UIImage.new()
	Place( e, x, y, w, h )
	e:setRGB( c[1], c[2], c[3] )
	e:setAlpha( a or 1 )
	parent:addElement( e )
	return e
end

local function Text( parent, x, y, w, h, str, c, align )
	local e = LUI.UIText.new()
	Place( e, x, y, w, h )
	e:setTTF( FONT )
	e:setRGB( c[1], c[2], c[3] )
	e:setAlignment( align or Enum.LUIAlignment.LUI_ALIGNMENT_LEFT )
	e:setText( str or "" )
	parent:addElement( e )
	return e
end

-- Rebuilds the panel when the layout-affecting settings change; otherwise just updates text.
local function LayoutKey( rows )
	local k = tostring( Val( "ov_pos", 0 ) ) .. "/" .. tostring( Val( "ov_size", 1 ) ) .. "/" .. tostring( Val( "ov_alpha", 3 ) )
	for _, r in ipairs( rows ) do k = k .. ( On( r[1] ) and "1" or "0" ) end
	k = k .. ( On( "ov_logo" ) and "L" or "" ) .. ( On( "ov_tags" ) and "T" or "" ) .. ( On( "ov_hint" ) and "H" or "" )
	return k
end

local function Build( ov )
	if ov.panel then ov.panel:close() end
	local rows = ov.zm and ZMRows or MPRows
	ov.layout = LayoutKey( rows )

	local scale = ( { 0.85, 1.0, 1.2 } )[ Val( "ov_size", 1 ) + 1 ] or 1
	local alpha = ( { 0.3, 0.5, 0.65, 0.8, 0.95 } )[ Val( "ov_alpha", 3 ) + 1 ] or 0.8
	local pos = Val( "ov_pos", 0 )         -- 0 TR, 1 TL, 2 BR, 3 BL
	local rowH = math.floor( 19 * scale )
	local font = math.floor( 14 * scale )
	local w = math.floor( 210 * scale )

	local shown = {}
	for _, r in ipairs( rows ) do
		if On( r[1] ) then table.insert( shown, r ) end
	end
	local h = 10 + #shown * rowH
	if On( "ov_logo" ) then h = h + rowH + 6 end
	if On( "ov_tags" ) then h = h + rowH end
	if On( "ov_hint" ) then h = h + rowH end

	local margin = 18
	local x = ( pos == 1 or pos == 3 ) and margin or ( 1280 - margin - w )
	local y = ( pos == 0 or pos == 1 ) and ( margin + 40 ) or ( 720 - margin - h )

	local panel = LUI.UIElement.new()
	Place( panel, 0, 0, 1280, 720 )
	ov:addElement( panel )
	ov.panel = panel

	ov.bg = Rect( panel, x, y, w, h, Col.bg, alpha )
	Rect( panel, x, y, w, 2, Col.pinkdeep )
	ov.flashRect = Rect( panel, x, y, w, h, Col.pinkdeep, 0 )

	local cy = y + 5
	if On( "ov_logo" ) then
		local brand = Text( panel, x + 10, cy, w, font + 2, "SYNTHEX", Col.white )
		local ok, bw = pcall( function () return brand:getTextWidth() end )
		if not ok or not bw or bw <= 0 then bw = math.floor( 62 * scale ) end
		Text( panel, x + 10 + bw, cy, 60, font + 2, ".VIP", Col.pink )
		cy = cy + rowH + 2
		Rect( panel, x + 8, cy - 2, w - 16, 1, Col.line )
		cy = cy + 4
	end

	ov.values = {}
	for _, r in ipairs( shown ) do
		Text( panel, x + 10, cy, w - 20, font, r[2], Col.muted )
		local v = Text( panel, x + 10, cy, w - 20, font, "", Col.text, Enum.LUIAlignment.LUI_ALIGNMENT_RIGHT )
		table.insert( ov.values, { elem = v, fn = r[3] } )
		cy = cy + rowH
	end

	ov.tags = nil
	if On( "ov_tags" ) then
		ov.tags = Text( panel, x + 10, cy + 2, w - 20, math.floor( font * 0.8 ), "", Col.pink )
		cy = cy + rowH
	end
	if On( "ov_hint" ) then
		Text( panel, x + 10, cy + 2, w - 20, math.floor( font * 0.8 ), "Aim + Melee  open menu", Col.dim )
	end
end

local function Update( ov )
	local rows = ov.zm and ZMRows or MPRows
	if LayoutKey( rows ) ~= ov.layout then Build( ov ) end

	-- hide while the main menu is open (if set)
	local hidden = On( "ov_hidemenu" ) and CoD.SynthexMenuOpen == true
	if ov.panel then ov.panel:setAlpha( hidden and 0 or 1 ) end

	for _, v in ipairs( ov.values or {} ) do
		local ok, str = pcall( v.fn )
		v.elem:setText( ok and str or "-" )
	end
	if ov.tags then
		local t = ""
		for _, tag in ipairs( Tags ) do
			if On( tag[1] ) then t = t .. tag[2] .. "   " end
		end
		ov.tags:setText( t )
	end
end

-- Shown / hidden by the main menu when "Enabled" is toggled. It is attached straight to the player's UI root
-- instead of being a script-opened menu: the game tracks one script-opened menu per player, and a second one
-- made the main menu's responses get dropped.
local function Attach( ov, controller )
	Build( ov )
	Update( ov )

	local timer = LUI.UITimer.newElementTimer( 500, false, function () pcall( Update, ov ) end )
	ov:addElement( timer )
	ov.timer = timer

	ov:subscribeToGlobalModel( controller, "PerController", "scriptNotify", function ( model )
		local name = Engine.GetModelValue( model )
		if name == "sx_stats" then
			local data = CoD.GetScriptNotifyData( model )
			if data then
				local offset = data[1] or 0
				for i = 2, #data do Data.stats[ offset + i - 2 ] = data[i] end
			end
		elseif name == "sx_flash" and On( "ov_flash" ) and ov.flashRect then
			pcall( function ()
				ov.flashRect:setAlpha( 0.6 )
				ov.flashRect:beginAnimation( "keyframe", 900, false, false, CoD.TweenType.Linear )
				ov.flashRect:setAlpha( 0 )
			end )
		end
	end )
end

function CoD.SynthexOverlayShow( controller, on )
	local cur = CoD.SynthexOverlayElem
	if on then
		if cur and not cur:isClosed() then return end
		local root = LUI.roots[ "UIRoot" .. controller ] or LUI.roots.UIRootFull
		if not root then return end
		local ov = LUI.UIElement.new()
		ov:setLeftRight( true, true, 0, 0 )
		ov:setTopBottom( true, true, 0, 0 )
		ov.controller = controller
		ov.zm = Engine.IsZombiesGame()
		root:addElement( ov )
		Attach( ov, controller )
		CoD.SynthexOverlayElem = ov
	else
		if cur and not cur:isClosed() then cur:close() end
		CoD.SynthexOverlayElem = nil
	end
end
