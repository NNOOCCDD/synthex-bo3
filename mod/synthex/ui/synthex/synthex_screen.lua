-- SYNTHEX.VIP - screen overlay effects (Visuals > Screen Filters > Overlay Effects).
-- Built only from plain coloured rectangles, so they work on every map (the game's own filters depend on
-- what the map loaded). Settings come from CoD.SynthexState values sfx_effect / sfx_col / sfx_str.

CoD.SynthexState = CoD.SynthexState or { tab = 1, side = {}, cursor = {}, toggles = {}, values = {}, sel = {}, inited = false }
local State = CoD.SynthexState

-- index order = menu order (offmenu_zm / offmenu_mp "Overlay Effects")
local EFFECTS = { "off", "tint", "rainbow", "vignette", "scanlines", "crt", "nightvision", "grid", "glitch", "bars", "edgeglow" }
local COLOURS = { { 1, 0.31, 0.65 }, { 1, 0.1, 0.1 }, { 1, 0.5, 0.05 }, { 1, 0.92, 0.15 }, { 0.25, 1, 0.35 }, { 0.15, 0.9, 1 }, { 0.2, 0.35, 1 }, { 1, 1, 1 } }
local STRENGTH = { 0.5, 1, 1.6 }
local W, H = 1280, 720

local function Rect( parent, x, y, w, h, c, a )
	local e = LUI.UIImage.new()
	e:setLeftRight( true, false, x, x + w )
	e:setTopBottom( true, false, y, y + h )
	e:setRGB( c[1], c[2], c[3] )
	e:setAlpha( a )
	parent:addElement( e )
	return e
end

-- smooth 0..1..0 wave without the sine function (the game's own Lua never calls it, so it may be missing)
local function Wave( t )
	local x = t - math.floor( t )
	local tri = ( x < 0.5 ) and ( x * 2 ) or ( 2 - x * 2 )
	return tri * tri * ( 3 - 2 * tri )
end

local function Hue( t )
	local h = ( t - math.floor( t ) ) * 6
	local i = math.floor( h )
	local f = h - i
	local q = 1 - f
	if i == 0 then return { 1, f, 0 } elseif i == 1 then return { q, 1, 0 } elseif i == 2 then return { 0, 1, f }
	elseif i == 3 then return { 0, q, 1 } elseif i == 4 then return { f, 0, 1 } end
	return { 1, 0, q }
end

-- soft frame towards the screen edges: 12 nested bands, stronger at the edge
local function Vignette( fx, c, a, list )
	for i = 1, 12 do
		local inset = ( i - 1 ) * 14
		local alpha = a * ( ( 13 - i ) / 12 ) ^ 2 * 0.35
		for _, r in ipairs( {
			{ inset, inset, W - inset * 2, 14 }, { inset, H - inset - 14, W - inset * 2, 14 },
			{ inset, inset + 14, 14, H - inset * 2 - 28 }, { W - inset - 14, inset + 14, 14, H - inset * 2 - 28 } } ) do
			local e = Rect( fx, r[1], r[2], r[3], r[4], c, alpha )
			if list then table.insert( list, { e = e, base = alpha } ) end
		end
	end
end

local function Scanlines( fx, a )
	local holder = LUI.UIElement.new()
	holder:setLeftRight( true, true, 0, 0 )
	holder:setTopBottom( true, true, 0, 0 )
	fx:addElement( holder )
	for y = 0, H + 4, 4 do
		Rect( holder, 0, y, W, 1, { 0, 0, 0 }, 0.35 * a )
	end
	return holder
end

local function Build( fx, effect, c, a )
	local anim = { t = 0 }
	if effect == "tint" then
		Rect( fx, 0, 0, W, H, c, 0.12 * a )
	elseif effect == "rainbow" then
		anim.tint = Rect( fx, 0, 0, W, H, c, 0.14 * a )
	elseif effect == "vignette" then
		Vignette( fx, { 0, 0, 0 }, a * 1.6 )
	elseif effect == "scanlines" then
		anim.lines = Scanlines( fx, a )
	elseif effect == "crt" then
		Rect( fx, 0, 0, W, H, c, 0.05 * a )
		anim.lines = Scanlines( fx, a )
		Vignette( fx, { 0, 0, 0 }, a * 1.4 )
	elseif effect == "nightvision" then
		Rect( fx, 0, 0, W, H, { 0.2, 1, 0.3 }, 0.18 * a )
		anim.lines = Scanlines( fx, a * 0.8 )
		Vignette( fx, { 0, 0, 0 }, a * 1.8 )
	elseif effect == "grid" then
		anim.grid = {}
		for x = 0, W, 40 do table.insert( anim.grid, Rect( fx, x, 0, 1, H, c, 0.12 * a ) ) end
		for y = 0, H, 40 do table.insert( anim.grid, Rect( fx, 0, y, W, 1, c, 0.12 * a ) ) end
		anim.gridA = 0.12 * a
	elseif effect == "glitch" then
		anim.bands = {}
		for i = 1, 8 do table.insert( anim.bands, Rect( fx, 0, 0, 1, 1, ( i % 3 == 0 ) and { 1, 1, 1 } or c, 0 ) ) end
		anim.bandA = 0.35 * a
	elseif effect == "bars" then
		Rect( fx, 0, 0, W, 88, { 0, 0, 0 }, 1 )
		Rect( fx, 0, H - 88, W, 88, { 0, 0, 0 }, 1 )
	elseif effect == "edgeglow" then
		anim.glow = {}
		Vignette( fx, c, a * 1.8, anim.glow )
	end
	return anim
end

local function Tick( anim )
	anim.t = anim.t + 1
	if anim.tint then
		local c = Hue( Engine.milliseconds() / 3000 )
		anim.tint:setRGB( c[1], c[2], c[3] )
	end
	if anim.lines then
		local off = anim.t % 4
		anim.lines:setTopBottom( true, true, off, off )
	end
	if anim.grid then
		local a = anim.gridA * ( 0.4 + 0.6 * Wave( anim.t / 40 ) )
		for _, e in ipairs( anim.grid ) do e:setAlpha( a ) end
	end
	if anim.glow then
		local k = 0.45 + 0.55 * Wave( anim.t / 30 )
		for _, g in ipairs( anim.glow ) do g.e:setAlpha( g.base * k ) end
	end
	if anim.bands and anim.t % 2 == 0 then
		local on = math.random() < 0.55
		for _, e in ipairs( anim.bands ) do
			if on and math.random() < 0.7 then
				local y = math.random( 0, H - 20 )
				local h = math.random( 2, 18 )
				local x = math.random( -200, 400 )
				e:setLeftRight( true, false, x, x + math.random( 300, W ) )
				e:setTopBottom( true, false, y, y + h )
				e:setAlpha( anim.bandA * math.random() )
			else
				e:setAlpha( 0 )
			end
		end
	end
end

-- (Re)build from the current settings. Called when a setting changes, when the menu opens and after a config load.
function CoD.SynthexScreenRefresh( controller )
	controller = controller or 0
	local cur = CoD.SynthexScreenElem
	if cur and not cur:isClosed() then cur:close() end
	CoD.SynthexScreenElem = nil

	local effect = EFFECTS[ ( State.values.sfx_effect or 0 ) + 1 ] or "off"
	if effect == "off" then return end
	local c = COLOURS[ ( State.values.sfx_col or 0 ) + 1 ] or COLOURS[1]
	local a = STRENGTH[ ( State.values.sfx_str or 1 ) + 1 ] or 1

	local root = LUI.roots[ "UIRoot" .. controller ] or LUI.roots.UIRootFull
	if not root then return end
	local fx = LUI.UIElement.new()
	fx:setLeftRight( true, true, 0, 0 )
	fx:setTopBottom( true, true, 0, 0 )
	root:addElement( fx )
	local anim = Build( fx, effect, c, a )
	local timer = LUI.UITimer.newElementTimer( 50, false, function () pcall( Tick, anim ) end )
	fx:addElement( timer )
	CoD.SynthexScreenElem = fx
end
