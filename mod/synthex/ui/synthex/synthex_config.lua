-- SYNTHEX.VIP - saved config (Settings > Config). Used by synthex_menu.lua.

require( "ui.synthex.synthex_spec" )

local Spec = CoD.SynthexSpec
CoD.SynthexState = CoD.SynthexState or { tab = 1, side = {}, cursor = {}, toggles = {}, values = {}, sel = {}, inited = false }
local State = CoD.SynthexState

-- ---------------------------------------------------------------------------
-- Config: every toggle / slider saved to disk, loaded back on request or on start.
-- Storage: a text file through Lua io when the game allows it, otherwise archived dvars written with
-- writeconfig to players/synthex_cfg.cfg. One line per mode: "zm:key=val,..." / "mp:...". Only values that
-- differ from the defaults are written.
-- ---------------------------------------------------------------------------

local CFG_FILES = { "players/mods/synthex/synthex_config.txt", "players/synthex_config.txt", "synthex_config.txt" }
local CFG_SKIP = { noclip = true, forge = true, freezetime = true, nospawn = true, pauserounds = true, freezezm = true, posslot = true }
CoD.SynthexCfg = CoD.SynthexCfg or { store = "-", last = "-" }
local Cfg = CoD.SynthexCfg

local function SendTo( controller, msg )
	Engine.SendMenuResponse( controller, "SynthexMenu", ( string.gsub( msg, " ", "_" ) ) )
end

local function CfgRows( zm )
	local rows = {}
	for _, tab in ipairs( Spec.Build( zm ) ) do
		for _, side in ipairs( tab.sides ) do
			local cards = side.cards
			-- pages built from script data (perks, power-ups): build them as if everything were available
			if not cards and side.build then
				local everything = setmetatable( {}, { __index = function () return true end } )
				local ok, built = pcall( side.build, { available = everything } )
				if ok and type( built ) == "table" then cards = built end
			end
			for _, card in ipairs( cards or {} ) do
				for _, r in ipairs( card.rows or {} ) do
					local k = r.key
					if k and not r.lua and not CFG_SKIP[ k ] and not string.find( k, "^att_" )
						and ( r.k == "toggle" or r.k == "slider" or r.k == "choice" ) then
						rows[ k ] = r
					end
				end
			end
		end
	end
	return rows
end

-- The build tools only accept globals they know, and io is not one of them. If the game has the library,
-- reach it through the debug library (registry / function environments) instead.
local function IOLib()
	if Cfg.io ~= nil then return Cfg.io or nil end
	local found = false
	pcall( function ()
		if not debug then return end
		local function try( t )
			if not found and type( t ) == "table" and type( t.io ) == "table" and type( t.io.open ) == "function" then found = t.io end
		end
		if debug.getregistry then
			local reg = debug.getregistry()
			if type( reg ) == "table" then
				try( reg._LOADED )
				try( reg )
			end
		end
		if debug.getfenv then
			try( debug.getfenv( Engine.ExecNow ) )
			try( debug.getfenv( pcall ) )
			try( debug.getfenv( function () end ) )
		end
	end )
	Cfg.io = found
	return found or nil
end

local function DefaultToggle( key ) return Spec.DefaultOn[ key ] == true end

local function FileRead()
	local lib = IOLib()
	if not lib then return nil end
	for _, path in ipairs( CFG_FILES ) do
		local ok, text = pcall( function ()
			local f = lib.open( path, "r" )
			if not f then return nil end
			local t = f.read( f, "*a" )
			f:close()
			return t
		end )
		if ok and text then return text end
	end
	return nil
end

local function FileWrite( text )
	local lib = IOLib()
	if not lib then return false end
	for _, path in ipairs( CFG_FILES ) do
		local ok, res = pcall( function ()
			local f = lib.open( path, "w" )
			if not f then return false end
			f:write( text )
			f:close()
			return true
		end )
		if ok and res then return true end
	end
	return false
end

local function DvarGet( name )
	local ok, v = pcall( Engine.GetDvarString, name )
	if ok and type( v ) == "string" then return v end
	return ""
end

-- store = { zm = "...", mp = "...", auto = true/false }
local function ReadStore( controller )
	local store = { zm = "", mp = "", auto = false }
	local text = FileRead()
	if text then
		Cfg.store = "File"
		for line in string.gmatch( text, "[^\r\n]+" ) do
			local m, body = string.match( line, "^(%a+):(.*)$" )
			if m == "auto" then store.auto = body == "1"
			elseif m == "zm" or m == "mp" then store[ m ] = body end
		end
		return store
	end
	pcall( Engine.ExecNow, controller, "exec synthex_cfg.cfg" )
	store.zm, store.mp = DvarGet( "synthex_cfg_zm" ), DvarGet( "synthex_cfg_mp" )
	store.auto = DvarGet( "synthex_cfg_auto" ) == "1"
	if store.zm ~= "" or store.mp ~= "" then
		Cfg.store = "Game Config"
		return store
	end
	-- nothing on disk: fall back to what was saved earlier in this session
	if Cfg.mem then
		Cfg.store = "This Session Only"
		return { zm = Cfg.mem.zm, mp = Cfg.mem.mp, auto = Cfg.mem.auto }
	end
	Cfg.store = "Empty"
	return store
end

local function WriteStore( controller, store )
	Cfg.mem = { zm = store.zm, mp = store.mp, auto = store.auto }
	local auto = store.auto and "1" or "0"
	if FileWrite( "auto:" .. auto .. "\nzm:" .. store.zm .. "\nmp:" .. store.mp .. "\n" ) then
		Cfg.store = "File"
		return true
	end
	pcall( function ()
		Engine.ExecNow( controller, "seta synthex_cfg_zm \"" .. store.zm .. "\"" )
		Engine.ExecNow( controller, "seta synthex_cfg_mp \"" .. store.mp .. "\"" )
		Engine.ExecNow( controller, "seta synthex_cfg_auto " .. auto )
		Engine.ExecNow( controller, "writeconfig synthex_cfg.cfg" )
	end )
	-- verify: clear the marker dvar, exec the written file, and see if it comes back
	local marker = store.zm .. "|" .. store.mp .. "|" .. auto
	local ok = pcall( function ()
		Engine.ExecNow( controller, "seta synthex_cfg_auto x" )
		Engine.ExecNow( controller, "exec synthex_cfg.cfg" )
	end )
	ok = ok and DvarGet( "synthex_cfg_auto" ) == auto and ( DvarGet( "synthex_cfg_zm" ) .. "|" .. DvarGet( "synthex_cfg_mp" ) .. "|" .. auto ) == marker
	Cfg.store = ok and "Game Config" or "Unavailable"
	return ok
end

local function Serialize( zm )
	local parts = {}
	for key, r in pairs( CfgRows( zm ) ) do
		if r.k == "toggle" then
			local on = State.toggles[ key ] == true
			if on ~= DefaultToggle( key ) then parts[ #parts + 1 ] = key .. "=" .. ( on and "1" or "0" ) end
		else
			local idx = State.values[ key ] or r.def
			if idx ~= r.def then parts[ #parts + 1 ] = key .. "=" .. idx end
		end
	end
	table.sort( parts )
	return table.concat( parts, "," ), #parts
end

local function Parse( body )
	local out = {}
	for key, val in string.gmatch( body or "", "([%w_]+)=(%d+)" ) do out[ key ] = tonumber( val ) end
	return out
end

-- Send messages a few per frame so the server's command buffer never overflows.
local function Pump( host, controller, queue, done )
	local i, t = 1, nil
	t = LUI.UITimer.newElementTimer( 50, false, function ()
		for _ = 1, 3 do
			if i > #queue then break end
			pcall( SendTo, controller, queue[ i ] )
			i = i + 1
		end
		if i > #queue then
			if t and not t:isClosed() then t:close() end
			if done then pcall( done ) end
		end
	end )
	host:addElement( t )
end

-- Bring State (and the server) to the target: saved values over defaults. Everything that is not at its
-- default is sent even if State already agrees, because the server starts every game from defaults.
local function Apply( host, controller, zm, saved, onDone )
	local vals, toggles, n = {}, {}, 0
	for key, r in pairs( CfgRows( zm ) ) do
		if r.k == "toggle" then
			local want = DefaultToggle( key )
			if saved[ key ] ~= nil then want = saved[ key ] == 1 end
			if want ~= DefaultToggle( key ) or ( State.toggles[ key ] == true ) ~= want then
				State.toggles[ key ] = want
				toggles[ #toggles + 1 ] = "t|" .. key .. "|" .. ( want and "1" or "0" )
				if key == "ov_on" and CoD.SynthexOverlayShow then pcall( CoD.SynthexOverlayShow, controller, want ) end
			end
		else
			local want = saved[ key ] or r.def
			if want < 0 or want >= #r.labels then want = r.def end
			if want ~= r.def or ( State.values[ key ] or r.def ) ~= want then
				State.values[ key ] = want
				vals[ #vals + 1 ] = "v|" .. key .. "|" .. want
				if ApplyClientSide then pcall( ApplyClientSide, r, want ) end
			end
		end
		if saved[ key ] ~= nil then n = n + 1 end
	end
	-- values first, so toggles that read a slider start with the right one
	for _, m in ipairs( toggles ) do vals[ #vals + 1 ] = m end
	vals[ #vals + 1 ] = "cfgdone|" .. n
	Pump( host, controller, vals, onDone )
	return n
end

local function RedrawOpenMenu()
	if CoD.SynthexMenuOpen and CoD.SynthexRedraw then pcall( CoD.SynthexRedraw ) end
end

function Cfg.Save( menu )
	local store = ReadStore( menu.controller )
	local body, n = Serialize( menu.zm )
	store[ menu.zm and "zm" or "mp" ] = body
	store.auto = State.toggles.cfg_auto == true
	if WriteStore( menu.controller, store ) then
		Cfg.last = "Saved " .. n .. " settings"
	else
		Cfg.store = "This Session Only"
		Cfg.last = "Saved " .. n .. " (disk not writable)"
	end
end

function Cfg.Load( menu )
	local store = ReadStore( menu.controller )
	local body = store[ menu.zm and "zm" or "mp" ]
	if body == "" then
		Cfg.last = "Nothing saved yet"
		return
	end
	local n = Apply( menu, menu.controller, menu.zm, Parse( body ), RedrawOpenMenu )
	Cfg.last = "Loaded " .. n .. " settings"
end

function Cfg.Reset( menu )
	Apply( menu, menu.controller, menu.zm, {}, RedrawOpenMenu )
	Cfg.last = "Reset to defaults"
end

function Cfg.SetAuto( menu, on )
	local store = ReadStore( menu.controller )
	store.auto = on
	WriteStore( menu.controller, store )
	Cfg.last = on and "Auto-load on" or "Auto-load off"
end

-- Script asked for the saved config (game start, or first menu open). Always answer with cfgdone.
-- Each request carries an id; model subscriptions can replay the last event, so answer each id once.
function Cfg.OnRequest( host, controller, model )
	local data = model and CoD.GetScriptNotifyData( model )
	local id = data and data[1]
	if id == nil or id == Cfg.lastRequest then return end
	Cfg.lastRequest = id
	local zm = Engine.IsZombiesGame()
	local store = ReadStore( controller )
	if store.zm ~= "" or store.mp ~= "" then State.toggles.cfg_auto = store.auto end
	local body = store[ zm and "zm" or "mp" ]
	if not store.auto or body == "" then
		pcall( SendTo, controller, "cfgdone|0" )
		return
	end
	local n = Apply( host, controller, zm, Parse( body ), RedrawOpenMenu )
	Cfg.last = "Auto-loaded " .. n .. " settings"
end

-- Listener that lives on the UI root, so the start-up request is answered while the menu is closed.
function Cfg.StartWatcher()
	local w = CoD.SynthexCfgWatcher
	if w and not w:isClosed() then return end
	local root = LUI.roots.UIRoot0 or LUI.roots.UIRootFull
	if not root then return end
	w = LUI.UIElement.new()
	w:setLeftRight( true, false, 0, 1 )
	w:setTopBottom( true, false, 0, 1 )
	root:addElement( w )
	w:subscribeToGlobalModel( 0, "PerController", "scriptNotify", function ( model )
		if Engine.GetModelValue( model ) == "sx_cfg" and not CoD.SynthexMenuOpen then
			pcall( Cfg.OnRequest, w, 0, model )
		end
	end )
	CoD.SynthexCfgWatcher = w
end
pcall( Cfg.StartWatcher )

function Cfg.Action( menu, r )
	if r.k == "toggle" then
		local on = not State.toggles[ r.key ]
		State.toggles[ r.key ] = on
		if r.key == "cfg_auto" then Cfg.SetAuto( menu, on ) end
	elseif r.label == "Save Config" then Cfg.Save( menu )
	elseif r.label == "Load Config" then Cfg.Load( menu )
	elseif r.label == "Reset To Defaults" then Cfg.Reset( menu )
	end
end

function Cfg.Refresh( controller )
	ReadStore( controller )
end
