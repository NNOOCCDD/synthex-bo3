-- SYNTHEX.VIP - in-game menu (LUI). Opened by script with OpenLUIMenu( "SynthexMenu" ).
--
-- Talks to script with Engine.SendMenuResponse( controller, "SynthexMenu", msg ):
--   t|key|0/1          toggle            v|key|index        slider / choice
--   b|tab|side|label   button            i|group|id         list item
--   pu|name            spawn power-up    p|tab|side         page opened (script refreshes data)
--   close
-- Script sends data back through LUINotifyEvent (scriptNotify model):
--   sx_stats  offset, v0..vN                 sx_list  code, reset(1/0), index...

require( "ui.synthex.synthex_spec" )
require( "ui.synthex.synthex_config" )

local Spec = CoD.SynthexSpec
local MENU_NAME = "SynthexMenu"

-- Layout (1280x720 base)
local PX, PY, PW, PH = 30, 90, 1220, 540
local HEAD_H, NAV_H, SIDE_W = 58, 70, 170
local PAD, GAP, COLS = 16, 14, 4
local CARD_W = math.floor( ( PW - SIDE_W - PAD * 2 - GAP * ( COLS - 1 ) ) / COLS )
local ROW_H, SLIDER_H, BTN_H, CARD_HEAD_H = 26, 40, 30, 34
local FONT = "fonts/default.ttf"
local FONT_COND = "fonts/RefrigeratorDeluxe-Regular.ttf"

local Col = {
	bg = { 0.114, 0.114, 0.122 }, chrome = { 0.145, 0.145, 0.153 }, panel = { 0.149, 0.149, 0.157 },
	edge = { 0.188, 0.188, 0.2 }, line = { 0.224, 0.224, 0.235 }, field = { 0.122, 0.122, 0.129 },
	raise = { 0.184, 0.184, 0.196 }, text = { 0.85, 0.85, 0.86 }, white = { 0.9, 0.9, 0.91 },
	muted = { 0.55, 0.55, 0.565 }, dim = { 0.365, 0.365, 0.38 }, pink = { 0.827, 0.612, 0.698 },
	pinkdeep = { 0.659, 0.439, 0.541 }, glow = { 1, 0.31, 0.65 }, danger = { 0.906, 0.639, 0.639 },
	hl = { 0.188, 0.188, 0.2 }
}

-- Persistent state (survives the menu closing; one per session)
CoD.SynthexState = CoD.SynthexState or { tab = 1, side = {}, cursor = {}, toggles = {}, values = {}, sel = {}, inited = false }
CoD.SynthexData = CoD.SynthexData or { stats = {}, lists = {} }
local State, Data = CoD.SynthexState, CoD.SynthexData

if not State.inited then
	for k, _ in pairs( Spec.DefaultOn ) do State.toggles[k] = true end
	State.inited = true
end

-- ---------------------------------------------------------------------------
-- Element helpers
-- ---------------------------------------------------------------------------

-- The menu is laid out at full size around (PX, PY) and drawn scaled to SCALE, anchored at the top-left corner
-- with a MARGIN gap (1280x720 base units).
local SCALE, MARGIN = 0.75, 24

local function PlaceRaw( e, x, y, w, h )
	e:setLeftRight( true, false, x, x + w )
	e:setTopBottom( true, false, y, y + h )
end

local function Place( e, x, y, w, h )
	local sx = MARGIN + ( x - PX ) * SCALE
	local sy = MARGIN + ( y - PY ) * SCALE
	e:setLeftRight( true, false, sx, sx + w * SCALE )
	e:setTopBottom( true, false, sy, sy + h * SCALE )
end

local function Rect( parent, x, y, w, h, c, a )
	local e = LUI.UIImage.new()
	Place( e, x, y, w, h )
	e:setRGB( c[1], c[2], c[3] )
	e:setAlpha( a or 1 )
	parent:addElement( e )
	return e
end

local function Text( parent, x, y, w, h, str, c, align, font )
	local e = LUI.UIText.new()
	Place( e, x, y, w, h )
	e:setTTF( font or FONT )
	e:setRGB( c[1], c[2], c[3] )
	e:setAlignment( align or Enum.LUIAlignment.LUI_ALIGNMENT_LEFT )
	e:setText( str or "" )
	parent:addElement( e )
	return e
end

local function SetColor( e, c ) e:setRGB( c[1], c[2], c[3] ) end

local function Hit( parent, x, y, w, h, onClick, onEnter, name )
	local e = LUI.UIElement.new()
	Place( e, x, y, w, h )
	e:setHandleMouse( true )
	e:setHandleMouseMove( true )
	e:registerEventHandler( "leftmousedown", function () return true end )
	e:registerEventHandler( "leftmouseup", function ( el, ev )
		if onClick then onClick() end
		return true
	end )
	e:registerEventHandler( "mouseenter", function ( el, ev )
		if onEnter then onEnter() end
		return true
	end )
	parent:addElement( e )
	return e
end

local function Comma( n )
	local s = tostring( math.floor( n ) )
	local out = s:reverse():gsub( "(%d%d%d)", "%1," ):reverse()
	if out:sub( 1, 1 ) == "," then out = out:sub( 2 ) end
	return out
end

local function Clock( secs )
	secs = math.floor( secs or 0 )
	return string.format( "%02d:%02d", math.floor( secs / 60 ), secs % 60 )
end

-- ---------------------------------------------------------------------------
-- Stats (indices must match the script's sx_stats order)
-- ---------------------------------------------------------------------------

local NearestNames = { [0] = "-", "Zombie", "Crawler", "Special", "Boss" }

local function S( i ) return Data.stats[i] or 0 end

local function WeaponName( list, idx )
	if idx == nil or idx < 0 then return "-" end
	local w = list[ idx + 1 ]
	if w then return w[2] end
	return "-"
end

local function PlayerName( num )
	for _, p in ipairs( Data.players or {} ) do
		if p.num == num then return p.name end
	end
	return "-"
end

local function StatText( key, zm )
	local wl = zm and Spec.ZMWeapons or Spec.MPWeapons
	if zm then
		if key == "round" then return tostring( S( 0 ) ) end
		if key == "points" then return Comma( S( 1 ) ) end
		if key == "kills" then return Comma( S( 2 ) ) end
		if key == "headshots" then return Comma( S( 3 ) ) end
		if key == "downs" then return tostring( S( 4 ) ) end
		if key == "zleft" then return tostring( S( 5 ) ) end
		if key == "zalive" then return tostring( S( 6 ) ) end
		if key == "rtime" then return Clock( S( 7 ) ) end
		if key == "power" then return S( 8 ) == 1 and "On" or "Off" end
		if key == "holding" then return WeaponName( wl, S( 9 ) ) end
		if key == "upgraded" then return S( 10 ) == 1 and "Yes" or "No" end
		if key == "slot_w1" then return S( 11 ) >= 0 and WeaponName( wl, S( 11 ) ) or "Empty" end
		if key == "slot_w2" then return S( 12 ) >= 0 and WeaponName( wl, S( 12 ) ) or "Empty" end
		if key == "slot_w3" then return S( 13 ) >= 0 and WeaponName( wl, S( 13 ) ) or "Empty" end
		if key == "esp_tracked" then return tostring( S( 14 ) ) end
		if key == "esp_specials" then return tostring( S( 15 ) ) end
		if key == "esp_out" then return tostring( S( 16 ) ) end
		if key == "esp_nearest" then return NearestNames[ S( 17 ) ] or "-" end
		if key == "mode" then return #( Data.players or {} ) > 1 and "Zombies - Co-op" or "Zombies - Solo" end
	else
		if key == "score" then return Comma( S( 3 ) ) end
		if key == "kills" then return tostring( S( 1 ) ) end
		if key == "deaths" then return tostring( S( 2 ) ) end
		if key == "specpct" then return tostring( S( 4 ) ) .. "%" end
		if key == "holding" then return WeaponName( wl, S( 7 ) ) end
		if key == "prim" then return S( 8 ) >= 0 and WeaponName( wl, S( 8 ) ) or "Empty" end
		if key == "sec" then return S( 9 ) >= 0 and WeaponName( wl, S( 9 ) ) or "Empty" end
		if key == "mode" then
			local ok, name = pcall( function () return Engine.Localize( Engine.GetGametypeName() ) end )
			return ok and name or "-"
		end
	end
	if key == "px" then return tostring( S( 18 ) ) end
	if key == "py" then return tostring( S( 19 ) ) end
	if key == "pz" then return tostring( S( 20 ) ) end
	if key == "yaw" then return tostring( S( 21 ) ) end
	if key == "cfg_store" then return CoD.SynthexCfg and CoD.SynthexCfg.store or "-" end
	if key == "cfg_last" then return CoD.SynthexCfg and CoD.SynthexCfg.last or "-" end
	if key == "slot1" then return ( S( 22 ) % 2 >= 1 ) and "Saved" or "Empty" end
	if key == "slot2" then return ( S( 22 ) % 4 >= 2 ) and "Saved" or "Empty" end
	if key == "slot3" then return ( S( 22 ) % 8 >= 4 ) and "Saved" or "Empty" end
	if key == "selhp" then return tostring( S( 23 ) ) end
	if key == "selgod" then return S( 24 ) == 1 and "On" or "Off" end
	if key == "selname" then return PlayerName( S( 26 ) ) end
	if key == "session" then return S( 25 ) == 1 and "Private" or "Offline" end
	if key == "map" then
		local m = Engine.GetCurrentMap()
		return Spec.MapNames[m] or m
	end
	return "-"
end

-- ---------------------------------------------------------------------------
-- Menu
-- ---------------------------------------------------------------------------

-- Menu responses travel like a console command: a space ends the message. Send spaces as "_".
local function Send( menu, msg )
	Engine.SendMenuResponse( menu.controller, MENU_NAME, ( string.gsub( msg, " ", "_" ) ) )
end

local function CurrentTab( menu ) return menu.tabs[ State.tab ] or menu.tabs[1] end

local function CurrentSide( menu )
	local tab = CurrentTab( menu )
	local si = State.side[ tab.id ] or 1
	if si > #tab.sides then si = 1 end
	return tab.sides[ si ], si
end

local function PageKey( menu )
	local tab = CurrentTab( menu )
	local side = CurrentSide( menu )
	return tab.id .. "/" .. side.id
end

local DrawPage, DrawChrome, UpdateCursor, RefreshValues

-- Redraws must not happen inside a click handler of an element they destroy (it left the mouse dead on that
-- page). Defer them to the next frame instead.
local function Later( menu, fn )
	local t
	t = LUI.UITimer.newElementTimer( 1, true, function ()
		pcall( fn )
		if t and not t:isClosed() then t:close() end
	end )
	menu:addElement( t )
end

local function RowInteractive( r )
	return r.k == "toggle" or r.k == "slider" or r.k == "choice" or r.k == "button" or r.k == "item"
end

local function Activate( menu, r )
	if not r then return end
	if r.lua then
		CoD.SynthexCfg.Action( menu, r )
		RefreshValues( menu )
		return
	end
	local tab = CurrentTab( menu )
	local side = CurrentSide( menu )
	if r.k == "toggle" then
		local on = not State.toggles[ r.key ]
		State.toggles[ r.key ] = on
		Send( menu, "t|" .. r.key .. "|" .. ( on and "1" or "0" ) )
		if r.key == "ov_on" and CoD.SynthexOverlayShow then
			pcall( CoD.SynthexOverlayShow, menu.controller, on )
		end
	elseif r.k == "slider" or r.k == "choice" then
		local idx = ( State.values[ r.key ] or r.def ) + 1
		if idx >= #r.labels then idx = ( r.k == "choice" ) and 0 or ( #r.labels - 1 ) end
		State.values[ r.key ] = idx
		Send( menu, "v|" .. r.key .. "|" .. idx )
		ApplyClientSide( r, idx )
	elseif r.k == "button" then
		if side.dynamic == "powerups" and r.id then
			Send( menu, "pu|" .. r.id )
		else
			Send( menu, "b|" .. tab.id .. "|" .. side.id .. "|" .. r.label )
		end
	elseif r.k == "item" then
		State.sel[ r.group ] = r.id
		Send( menu, "i|" .. r.group .. "|" .. tostring( r.id ) )
	end
	RefreshValues( menu )
end

-- Settings that live on the client (the server can't set them): field of view.
function ApplyClientSide( r, idx )
	if r.key == "fov" then
		pcall( function () Engine.SetDvar( "cg_fov_default", tonumber( r.labels[ idx + 1 ] ) ) end )
	end
end

local function ChangeValue( menu, r, dir )
	if not r or ( r.k ~= "slider" and r.k ~= "choice" ) then return end
	local n = #r.labels
	local idx = ( State.values[ r.key ] or r.def ) + dir
	if r.k == "slider" then
		if idx < 0 then idx = 0 end
		if idx > n - 1 then idx = n - 1 end
	else
		idx = idx % n
	end
	if idx == ( State.values[ r.key ] or r.def ) then return end
	State.values[ r.key ] = idx
	Send( menu, "v|" .. r.key .. "|" .. idx )
	ApplyClientSide( r, idx )
	RefreshValues( menu )
end

local function SwitchTab( menu, dir )
	State.tab = ( ( State.tab - 1 + dir ) % #menu.tabs ) + 1
	DrawChrome( menu )
	DrawPage( menu )
end

local function SwitchSide( menu, dir )
	local tab = CurrentTab( menu )
	local _, si = CurrentSide( menu )
	State.side[ tab.id ] = ( ( si - 1 + dir ) % #tab.sides ) + 1
	DrawChrome( menu )
	DrawPage( menu )
end

local function MoveCursor( menu, dir )
	local n = #menu.nav
	if n == 0 then return end
	local key = PageKey( menu )
	State.cursor[ key ] = ( ( ( State.cursor[ key ] or 0 ) + dir ) % n )
	UpdateCursor( menu )
end

local function CursorRow( menu )
	if #menu.nav == 0 then return nil end
	return menu.nav[ ( State.cursor[ PageKey( menu ) ] or 0 ) + 1 ]
end

-- ---- chrome ----------------------------------------------------------------

DrawChrome = function ( menu )
	if menu.chrome then menu.chrome:close() end
	local root = LUI.UIElement.new()
	PlaceRaw( root, 0, 0, 1280, 720 )
	menu:addElement( root )
	menu.chrome = root

	-- frame
	Rect( root, PX, PY, PW, PH, Col.bg, 0.97 )
	Rect( root, PX, PY, PW, HEAD_H, Col.chrome )
	Rect( root, PX, PY + HEAD_H - 1, PW, 1, Col.pinkdeep )

	-- brand: "SYNTHEX" white + ".VIP" pink, joined exactly using the measured text width
	local brand = Text( root, PX + 20, PY + 15, 220, 28, "SYNTHEX", Col.white, nil, FONT )
	local ok, bw = pcall( function () return brand:getTextWidth() end )
	if not ok or not bw or bw <= 0 then bw = 92 * SCALE end
	bw = bw / SCALE
	Text( root, PX + 20 + bw, PY + 15, 80, 28, ".VIP", Col.pink, nil, FONT )

	-- status chips (right side of header)
	local zm = menu.zm
	local chips
	if zm then
		chips = { { "Round", "round", 90 }, { "Points", "points", 140 }, { "Map", "map", 210 }, { "Offline - Host", nil, 130, true } }
	else
		chips = { { "Mode", "mode", 200 }, { "Score", "score", 120 }, { "Kills", "kills", 100 }, { "Offline - Host", nil, 130, true } }
	end
	menu.chipValues = {}
	local x = PX + PW - 16
	for i = #chips, 1, -1 do
		local c = chips[i]
		x = x - c[3]
		Rect( root, x, PY + 13, c[3], 32, Col.field )
		Rect( root, x, PY + 13, c[3], 1, Col.line )
		if c[4] then
			Rect( root, x + 10, PY + 26, 7, 7, Col.glow )
			Text( root, x + 22, PY + 20, c[3] - 26, 18, c[1], Col.pink )
		else
			Text( root, x + 10, PY + 20, c[3] - 20, 18, c[1], Col.muted )
			local v = Text( root, x + 10, PY + 20, c[3] - 20, 18, "", Col.text, Enum.LUIAlignment.LUI_ALIGNMENT_RIGHT )
			table.insert( menu.chipValues, { elem = v, key = c[2] } )
		end
		x = x - 8
	end

	-- side panel
	local tab = CurrentTab( menu )
	local _, si = CurrentSide( menu )
	local sideTop = PY + HEAD_H
	local sideH = PH - HEAD_H - NAV_H
	Rect( root, PX, sideTop, SIDE_W, sideH, Col.chrome )
	Rect( root, PX + SIDE_W, sideTop, 1, sideH, Col.line )
	for i, s in ipairs( tab.sides ) do
		local y = sideTop + 14 + ( i - 1 ) * 36
		local active = ( i == si )
		if active then
			Rect( root, PX, y, SIDE_W, 36, Col.hl )
			Rect( root, PX, y, 3, 36, Col.pink )
		end
		Text( root, PX + 16, y + 9, SIDE_W - 30, 18, s.label, active and Col.white or Col.muted )
		Hit( root, PX, y, SIDE_W, 36, function ()
			State.side[ tab.id ] = i
			Later( menu, function () DrawChrome( menu ) DrawPage( menu ) end )
		end, nil, "side:" .. s.id )
	end

	-- bottom bar
	local navTop = PY + PH - NAV_H
	Rect( root, PX, navTop, PW, NAV_H, Col.chrome )
	Rect( root, PX, navTop, PW, 1, Col.line )
	local tabW = 92
	local tabsW = #menu.tabs * tabW
	local tx0 = PX + math.floor( ( PW - tabsW ) / 2 )
	for i, t in ipairs( menu.tabs ) do
		local x = tx0 + ( i - 1 ) * tabW
		local active = ( i == State.tab )
		if active then
			Rect( root, x + 4, navTop + 8, tabW - 8, NAV_H - 16, Col.hl )
			Rect( root, x + 4, navTop + NAV_H - 10, tabW - 8, 2, Col.pink )
		end
		Text( root, x, navTop + 25, tabW, 20, t.label, active and Col.white or Col.muted, Enum.LUIAlignment.LUI_ALIGNMENT_CENTER )
		Hit( root, x + 4, navTop + 8, tabW - 8, NAV_H - 16, function ()
			State.tab = i
			Later( menu, function () DrawChrome( menu ) DrawPage( menu ) end )
		end, nil, "tab:" .. t.id )
	end
	Text( root, PX + 16, navTop + 18, 260, 15, "Q / E  tabs     A / D  sides     W / S  move", Col.dim )
	Text( root, PX + 16, navTop + 38, 260, 15, "F / Click  select     < >  value     V  close", Col.dim )

	-- mode badge
	Rect( root, PX + PW - 16 - 110, navTop + 10, 110, NAV_H - 20, Col.raise )
	Text( root, PX + PW - 16 - 110, navTop + 25, 110, 18, zm and "Zombies" or "Multiplayer", Col.text, Enum.LUIAlignment.LUI_ALIGNMENT_CENTER )
end

-- ---- page -------------------------------------------------------------------

local function RowHeight( r )
	if r.k == "slider" then return SLIDER_H end
	if r.k == "button" then return BTN_H + 6 end
	return ROW_H
end

local function DrawRow( menu, parent, r, x, y, w )
	local h = RowHeight( r )
	r.x, r.y, r.w, r.h = x, y, w, h
	local mid = y + math.floor( h / 2 )
	r.elems = {}

	if r.k == "toggle" then
		Rect( parent, x, mid - 7, 14, 14, { 0.235, 0.235, 0.25 } )
		r.elems.box = Rect( parent, x + 2, mid - 5, 10, 10, Col.field )
		r.elems.label = Text( parent, x + 22, mid - 8, w - 22, 16, r.label, Col.text )
		if r.hint then Text( parent, x, mid - 6, w, 12, r.hint, Col.dim, Enum.LUIAlignment.LUI_ALIGNMENT_RIGHT ) end
	elseif r.k == "slider" then
		Text( parent, x, y + 3, w - 100, 16, r.label, Col.text )
		Text( parent, x + w - 92, y + 3, 14, 16, "<", Col.pink, Enum.LUIAlignment.LUI_ALIGNMENT_CENTER )
		r.elems.value = Text( parent, x + w - 76, y + 3, 60, 16, "", Col.text, Enum.LUIAlignment.LUI_ALIGNMENT_CENTER )
		Text( parent, x + w - 14, y + 3, 14, 16, ">", Col.pink, Enum.LUIAlignment.LUI_ALIGNMENT_CENTER )
		r.arrowL = { x = x + w - 100, w = 30 }
		r.arrowR = { x = x + w - 22, w = 30 }
		Rect( parent, x, y + 26, w, 6, Col.field )
		r.elems.fill = Rect( parent, x, y + 26, 2, 6, Col.pink )
		r.elems.knob = Rect( parent, x, y + 23, 4, 12, { 0.945, 0.86, 0.894 } )
	elseif r.k == "choice" then
		Text( parent, x, mid - 8, w, 16, r.label, Col.text )
		Rect( parent, x + w - 120, y + 2, 120, h - 4, Col.field )
		r.elems.value = Text( parent, x + w - 100, mid - 7, 80, 14, "", Col.text, Enum.LUIAlignment.LUI_ALIGNMENT_CENTER )
		Text( parent, x + w - 118, mid - 7, 14, 14, "<", Col.pink, Enum.LUIAlignment.LUI_ALIGNMENT_CENTER )
		Text( parent, x + w - 16, mid - 7, 14, 14, ">", Col.pink, Enum.LUIAlignment.LUI_ALIGNMENT_CENTER )
		r.arrowL = { x = x + w - 124, w = 30 }
		r.arrowR = { x = x + w - 26, w = 30 }
	elseif r.k == "button" then
		r.elems.bg = Rect( parent, x, y + 3, w, BTN_H, Col.raise )
		Rect( parent, x, y + 3, w, 1, { 0.231, 0.231, 0.247 } )
		Text( parent, x, y + 3 + 8, w, 15, r.label, r.danger and Col.danger or Col.text, Enum.LUIAlignment.LUI_ALIGNMENT_CENTER )
	elseif r.k == "item" then
		r.elems.bg = Rect( parent, x - 14, y, w + 28, h, Col.hl, 0 )
		r.elems.mark = Rect( parent, x - 14, y, 2, h, Col.pink, 0 )
		r.elems.label = Text( parent, x, mid - 8, w, 16, r.label, Col.muted )
	elseif r.k == "stat" then
		Text( parent, x, mid - 8, w, 16, r.label, Col.muted )
		r.elems.value = Text( parent, x, mid - 8, w, 16, "", Col.text, Enum.LUIAlignment.LUI_ALIGNMENT_RIGHT )
	elseif r.k == "note" then
		Text( parent, x, mid - 6, w, 12, r.label, Col.dim )
	end

	if RowInteractive( r ) then
		local idx = #menu.nav
		table.insert( menu.nav, r )
		local function focus()
			State.cursor[ PageKey( menu ) ] = idx
			UpdateCursor( menu )
		end
		if r.k == "slider" or r.k == "choice" then
			-- Non-overlapping zones (LUI hands the click to the first element that takes it):
			-- label = select row, "<" = lower, value = select row, ">" = raise.
			local lx, rx = r.arrowL.x, r.arrowR.x
			Hit( parent, x - 14, y, lx - ( x - 14 ), h, focus, focus, "row:" .. r.label )
			Hit( parent, lx, y, r.arrowL.w, h, function () focus() ChangeValue( menu, r, -1 ) end, focus, "lt:" .. r.label )
			Hit( parent, lx + r.arrowL.w, y, rx - ( lx + r.arrowL.w ), h, focus, focus, "val:" .. r.label )
			Hit( parent, rx, y, ( x + w + 14 ) - rx, h, function () focus() ChangeValue( menu, r, 1 ) end, focus, "gt:" .. r.label )
		else
			Hit( parent, x - 14, y, w + 28, h, function () focus() Activate( menu, r ) end, focus, "row:" .. r.label )
		end
	end
	return h
end

DrawPage = function ( menu, fromData )
	if menu.page then menu.page:close() end
	local page = LUI.UIElement.new()
	PlaceRaw( page, 0, 0, 1280, 720 )
	menu:addElement( page )
	menu.page = page
	menu.nav = {}
	menu.statRows = {}

	local tab = CurrentTab( menu )
	local side = CurrentSide( menu )
	local cards = side.cards
	if side.build then
		local d = Data.lists[ side.dynamic ] or {}
		local ok, built = pcall( side.build, d )
		cards = ok and built or {}
	end
	menu.cards = cards

	-- cursor highlight (under rows)
	menu.cursorBg = Rect( page, 0, 0, 1, 1, Col.pink, 0 )
	menu.cursorBar = Rect( page, 0, 0, 2, 1, Col.pink, 0 )

	local top = PY + HEAD_H + PAD
	local bottom = PY + PH - NAV_H - PAD
	local colY = {}
	for c = 0, COLS - 1 do colY[c] = top end

	for c = 0, COLS - 1 do
		for _, card in ipairs( cards ) do
			if card.col == c then
				local x = PX + SIDE_W + PAD + c * ( CARD_W + GAP )
				local y = colY[c]
				local h = CARD_HEAD_H + 12
				for _, r in ipairs( card.rows ) do h = h + RowHeight( r ) end
				if y + h > bottom then h = bottom - y end
				if h > CARD_HEAD_H then
					Rect( page, x, y, CARD_W, h, Col.panel )
					Rect( page, x, y, CARD_W, 1, Col.edge )
					Rect( page, x, y + CARD_HEAD_H, CARD_W, 1, Col.line )
					Text( page, x + 14, y + 9, CARD_W - 28, 17, card.title, Col.white )
					local ry = y + CARD_HEAD_H + 6
					for _, r in ipairs( card.rows ) do
						if ry + RowHeight( r ) > y + h then break end
						ry = ry + DrawRow( menu, page, r, x + 14, ry, CARD_W - 28 )
						if r.k == "stat" then table.insert( menu.statRows, r ) end
					end
					colY[c] = y + h + GAP
				end
			end
		end
	end

	local key = PageKey( menu )
	if ( State.cursor[ key ] or 0 ) >= #menu.nav then State.cursor[ key ] = 0 end
	UpdateCursor( menu )
	RefreshValues( menu )
	-- Only real page changes ask the script for data; redraws caused by that data must not (that looped forever).
	if not fromData then
		Send( menu, "p|" .. tab.id .. "|" .. side.id )
	end
end

UpdateCursor = function ( menu )
	local r = CursorRow( menu )
	if not r or not menu.cursorBg then
		if menu.cursorBg then menu.cursorBg:setAlpha( 0 ) menu.cursorBar:setAlpha( 0 ) end
		return
	end
	Place( menu.cursorBg, r.x - 14, r.y, r.w + 28, r.h )
	Place( menu.cursorBar, r.x - 14, r.y, 2, r.h )
	menu.cursorBg:setAlpha( 0.08 )
	menu.cursorBar:setAlpha( 1 )
end

RefreshValues = function ( menu )
	if not menu.cards then return end
	for _, card in ipairs( menu.cards ) do
		for _, r in ipairs( card.rows ) do
			local e = r.elems
			if e then
				if r.k == "toggle" and e.box then
					local on = State.toggles[ r.key ] == true
					SetColor( e.box, on and Col.pink or Col.field )
					SetColor( e.label, on and Col.text or Col.muted )
				elseif ( r.k == "slider" or r.k == "choice" ) and e.value then
					local idx = State.values[ r.key ] or r.def
					e.value:setText( r.labels[ idx + 1 ] or "" )
					if e.fill then
						local frac = ( #r.labels > 1 ) and ( idx / ( #r.labels - 1 ) ) or 1
						local fw = math.max( 2, math.floor( r.w * frac ) )
						Place( e.fill, r.x, r.y + 26, fw, 6 )
						Place( e.knob, r.x + fw - 2, r.y + 23, 4, 12 )
					end
				elseif r.k == "item" and e.label then
					local sel = State.sel[ r.group ] == r.id
					SetColor( e.label, sel and Col.white or Col.muted )
					e.bg:setAlpha( sel and 1 or 0 )
					e.mark:setAlpha( sel and 1 or 0 )
				elseif r.k == "stat" and e.value then
					e.value:setText( StatText( r.stat, menu.zm ) )
				end
			end
		end
	end
	if menu.chipValues then
		for _, c in ipairs( menu.chipValues ) do
			c.elem:setText( StatText( c.key, menu.zm ) )
		end
	end
end

-- ---- script data -------------------------------------------------------------

local ListCodes = { [1] = "zm_weapons", [2] = "perks", [3] = "perks_owned", [4] = "powerups", [5] = "players", [6] = "streaks", [7] = "mp_weapons", [8] = "spots_machines", [9] = "spots_flags" }

local function OnScriptNotify( menu, model )
	local name = Engine.GetModelValue( model )
	if name == "sx_cfg" then
		CoD.SynthexCfg.OnRequest( menu, menu.controller, model )
		return
	end
	if name ~= "sx_stats" and name ~= "sx_list" then return end
	local data = CoD.GetScriptNotifyData( model )
	if not data then return end

	if name == "sx_stats" then
		local offset = data[1] or 0
		for i = 2, #data do
			Data.stats[ offset + i - 2 ] = data[i]
		end
		RefreshValues( menu )
		return
	end

	-- sx_list: code, reset, indices...
	local code, reset = data[1], data[2]
	local which = ListCodes[ code ]
	if not which then return end
	Data.raw = Data.raw or {}
	if reset == 1 or not Data.raw[ which ] then Data.raw[ which ] = {} end
	for i = 3, #data do
		if data[i] ~= nil and data[i] >= 0 then Data.raw[ which ][ data[i] ] = true end
	end

	-- derive page data
	local L = Data.lists
	L.zm_weapons = { available = Data.raw.zm_weapons }
	L.mp_weapons = { available = Data.raw.mp_weapons }
	L.powerups = { available = Data.raw.powerups }
	L.streaks = { available = Data.raw.streaks }
	L.perks = { available = Data.raw.perks }
	local flags = Data.raw.spots_flags or {}
	L.spots = { pap = flags[0], box = flags[1], power = flags[2], machines = Data.raw.spots_machines }

	if which == "perks_owned" then
		for i, p in ipairs( Spec.Perks ) do
			State.toggles[ "perk_" .. p[1] ] = Data.raw.perks_owned[ i - 1 ] == true
		end
	end
	if which == "players" then
		local list = {}
		local nums = {}
		for num, _ in pairs( Data.raw.players ) do table.insert( nums, num ) end
		table.sort( nums )
		local names = {}
		pcall( function ()
			for team = 0, 3 do
				local pl = Engine.GetInGamePlayerList( menu.controller, team )
				if pl then
					for _, p in pairs( pl ) do
						if p.clientNum ~= nil and p.playerName then names[ p.clientNum ] = p.playerName end
					end
				end
			end
		end )
		for _, num in ipairs( nums ) do
			table.insert( list, { num = num, name = names[ num ] or ( "Player " .. ( num + 1 ) ) } )
		end
		Data.players = list
		L.players = { players = list }
	end

	local side = CurrentSide( menu )
	if side.dynamic and ( side.dynamic == which or ( which == "spots_flags" and side.dynamic == "spots" ) or ( which == "perks_owned" and side.dynamic == "perks" ) ) then
		DrawPage( menu, true )
	else
		RefreshValues( menu )
	end
end

-- ---- creation ----------------------------------------------------------------

local function AddKey( menu, controller, button, key, fn )
	menu:AddButtonCallbackFunction( menu, controller, button, key, function ( el, m, ctrl, model )
		fn()
		return true
	end, function () return true end, false )
end

function LUI.createMenu.SynthexMenu( controller )
	local menu = CoD.Menu.NewForUIEditor( MENU_NAME )
	menu.soundSet = "default"
	menu:setOwner( controller )
	menu:setLeftRight( true, true, 0, 0 )
	menu:setTopBottom( true, true, 0, 0 )
	menu.controller = controller
	menu.zm = Engine.IsZombiesGame()
	menu.tabs = Spec.Build( menu.zm )
	if State.tab > #menu.tabs then State.tab = 1 end

	pcall( CoD.SynthexCfg.StartWatcher )
	if CoD.SynthexCfg.store == "-" then pcall( CoD.SynthexCfg.Refresh, controller ) end
	CoD.SynthexRedraw = function () Later( menu, function () if not menu:isClosed() then DrawPage( menu, true ) end end ) end
	DrawChrome( menu )
	DrawPage( menu )
	if CoD.SynthexOverlayShow then
		pcall( CoD.SynthexOverlayShow, controller, State.toggles.ov_on == true )
	end

	local B = Enum.LUIButton
	AddKey( menu, controller, B.LUI_KEY_LB, "Q", function () SwitchTab( menu, -1 ) end )
	AddKey( menu, controller, B.LUI_KEY_RB, "E", function () SwitchTab( menu, 1 ) end )
	AddKey( menu, controller, B.LUI_KEY_LEFT, "A", function () SwitchSide( menu, -1 ) end )
	AddKey( menu, controller, B.LUI_KEY_RIGHT, "D", function () SwitchSide( menu, 1 ) end )
	AddKey( menu, controller, B.LUI_KEY_UP, "W", function () MoveCursor( menu, -1 ) end )
	AddKey( menu, controller, B.LUI_KEY_DOWN, "S", function () MoveCursor( menu, 1 ) end )
	AddKey( menu, controller, B.LUI_KEY_XBA_PSCROSS, "F", function () Activate( menu, CursorRow( menu ) ) end )
	AddKey( menu, controller, B.LUI_KEY_LTRIG, "Z", function () ChangeValue( menu, CursorRow( menu ), -1 ) end )
	AddKey( menu, controller, B.LUI_KEY_RTRIG, "X", function () ChangeValue( menu, CursorRow( menu ), 1 ) end )
	AddKey( menu, controller, B.LUI_KEY_PCKEY_MWHEELUP, nil, function () ChangeValue( menu, CursorRow( menu ), 1 ) end )
	AddKey( menu, controller, B.LUI_KEY_PCKEY_MWHEELDOWN, nil, function () ChangeValue( menu, CursorRow( menu ), -1 ) end )
	-- Close: B / Backspace / V (melee). Never Esc - on PC the game uses it for its own pause menu.
	local function CloseMenu()
		-- close locally as well, so input is never left locked if the script side is not answering
		Send( menu, "close" )
		if not menu:isClosed() then menu:close() end
	end
	AddKey( menu, controller, B.LUI_KEY_XBB_PSCIRCLE, "BACKSPACE", CloseMenu )
	AddKey( menu, controller, B.LUI_KEY_NONE, "V", CloseMenu )

	-- If the game opens its own menus, get out of the way cleanly.
	menu:registerEventHandler( "close_all_ingame_menus", function () CloseMenu() return true end )
	menu:registerEventHandler( "open_migration_menu", function () CloseMenu() return true end )

	menu:subscribeToGlobalModel( controller, "PerController", "scriptNotify", function ( model )
		pcall( OnScriptNotify, menu, model )
	end )

	Engine.LockInput( controller, true )
	Engine.SetUIActive( controller, true )
	CoD.SynthexMenuOpen = true

	LUI.OverrideFunction_CallOriginalSecond( menu, "close", function ( m )
		CoD.SynthexMenuOpen = false
		Engine.LockInput( controller, false )
		Engine.SetUIActive( controller, false )
	end )

	menu:processEvent( { name = "menu_loaded", controller = controller } )
	return menu
end
