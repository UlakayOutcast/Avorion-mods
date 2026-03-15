package.path = package.path .. ";data/scripts/lib/?.lua"
package.path = package.path .. ";data/scripts/uiLib/?.lua"
--include ("dialogues")
--include ("capPortrait")
include("callable")
include("captainPackList")
include("config_manager")

-- Don't remove or alter the following comment, it tells the game the namespace this script lives in. If you remove it, the script will break.
-- namespace Builder
local Builder = {}
Builder.__index = Builder
local PublicNamespace = {}
--prevent double click on choices
local dialog_CD = 0

local player_stats = {}
local entity = Entity()

local user_config
local hub = {}
local hooks = 0
hub.vars = {} 
hub.vars.layers = {} 
hub.vars.hidden_layers = {}
hub.vars.hud = {}

local fixed_resolution
local fixed_position

--/////////dev tools
--clear save data on F5 or on load
local disable_restore = false
local show_saved_data = false
--simulate client - server delay, in seconds
local high_ping

local mod_list = {ModManager():getEnabledMods()}
for _, mod_id in pairs(mod_list) do
	if mod_id == "3473880618" then
		package.path = package.path .. ";data/scripts/realCaptains2/?.lua"	
		include ("packList")
		break
	end
end	

local function new()
    local instance = {}
    return setmetatable(instance, Builder)
end

--all of them are mandatory
local hook_list = {
	"initialize",
	"onKeyboardEvent",
	"onMouseEvent",
	"onCloseWindow",
	"onShowWindow",
	"onDialogClick",	
}

function Builder:initialize()
	if onClient() then
		local vars = hub.vars
		if vars.sync_requested then return end
		vars.sync_requested = true
		self:deferredCallback_(1, "requestClientSync")
	else
		if not entity then return print("UI lib Error: somehow there is no entity. Rare bug, reason unknown") end
		Entity():addScriptOnce("data/scripts/uiLib/securer.lua")
	end
--[[
	if onServer() then
		--precautions. Original initialize function is redefined, so the station will break and lose all goods if something is broken here
		if not self then return end
		if not self.id then return end
		entity:invokeFunction("data/scripts/uiLib/securer.lua", "hook", self.id)
	end
	--]]
end

function Builder:hook(master_namespace, config, config_entry)
	hooks = hooks + 1
	local master = master_namespace
	local player = Player()
	self.master = master_namespace
	self.vars = {}
	local vars = self.vars	
	if not config then print("error no config") return end	
	vars.config = config[config_entry]
	if not vars.config then print("error no such entry in the config: ", config_entry) return end
	
	--todo check if server dont need that data
	if vars.config.dialogs then
		package.path = package.path .. ";" .. vars.config.dialogs.path .. "/?.lua"
		local config_ = include(vars.config.dialogs.file_name)
		vars.dialog_config = config_
	end
	
	if vars.config.functions then
		package.path = package.path .. ";" .. vars.config.functions.path .. "/?.lua"
		local config_ = include(vars.config.functions.file_name)
		vars.functions = config_
		vars.functions.getInstance(self)
	end
	
	if vars.config.hooks then
		package.path = package.path .. ";" .. vars.config.hooks.path .. "/?.lua"
		local config_ = include(vars.config.hooks.file_name)
		vars.hooks = config_
		config_.setHooks(self, master_namespace)
	end
	
	vars.config.background_conditions = vars.config.background_conditions or {}
	local background_conditions = vars.config.background_conditions
	background_conditions.default = background_conditions.default or "hide"
	background_conditions.distance = background_conditions.distance or 0
	
	if not hub.vars.config then
		hub.vars.config = config.hub
		hub.vars.config.background_conditions = hub.vars.config.background_conditions or {}
		local background_conditions = config.hub.background_conditions
		if background_conditions then
			background_conditions.default = background_conditions.default or "hide"
			background_conditions.distance = background_conditions.distance or 0
		end
	end
	
	if config.VI_lines then
		vars.VI_lines = config.VI_lines
		vars.VI_path = config.VI_path
		if not vars.VI_path then print("error no VI path in the config") return end	
	end

	local packs = config.captain_packs
	if packs then
		if vars.config.captains and vars.config.captains.pack then
			vars.captain_pack = packs[vars.config.captains.pack]
		end
	end	
	
	self.id = vars.config.id or 10
	vars.layers = {}
	vars.hidden_layers = {}
	vars.hud = {}
	vars.hud.resources = {}
	vars.hud.stats = {}
	vars.hud.deferred = 0
	vars.hud.waiting_sync = {}
	
	self.data = {}
	self.data.dialog = {}

	--extend existing master functions with new functionality from the Builder without replacing them
	for _, func in pairs(hook_list) do
		if master[func] then
			local original = master[func]
			master[func] = function(...)
				original(...)
				self[func](self, ...)
			end
		else
			master[func] = function(...)
				self[func](self, ...)
			end
		end		
	end
	
	master.invokeServerUIB = function(func, ...)
		invokeServerFunction("invokeServerUIB2", func, ...)
	end
	master.invokeServerUIB2 = function(func, ...)
		self[func](self, ...)	
	end	
	callable(master, "invokeServerUIB2")
	
	master.invokeClientUIB = function(client, func, ...)
		if type(client) == "number" then
			invokeClientFunction(Player(client), "invokeServerUIB2", func, ...)
		else
			invokeClientFunction(client, "invokeClientUIB2", func, ...)
		end		
	end
	master.invokeClientUIB2 = function(func, ...)
		self[func](self, ...)
	end	
	callable(master, "invokeClientUIB2")	

	master.deferredCallbackUIB = function(delay, func, ...)
		deferredCallback(delay, "deferredCallbackUIB2", func, ...)
	end
	
	master.deferredCallbackUIB2 = function(func, ...)
		self[func](self, ...)
	end

--[[	
	if master.secure then
		local original = master.secure
		master.secure = function()
			local master_data = original()
			return self:secure(master_data)
		end
	else
		master.secure = function()
			return self:secure()
		end
	end
	
	if master.restore then
		local original = master.restore
		master.restore = function(restored_data)
			--print("restored data", restored_data.master_data)
			local master_data = restored_data.master_data
			original(master_data)
			self:restore(restored_data)
		end
	else
		master.restore = function(restored_data)
			self:restore(restored_data)
		end
	end
	--]]
	
	if onClient() then
		--prevent multiple triggering, specifics of my master_namespace-builder hook mechanic with multiple instances of the builder script available
		if hooks == 1 then
			self:registerCallback_(entity, "onStartDialog", "onShowHub")
		end
		if player.craft then
			faction = Faction(player.craft.factionIndex)
			if faction.isPlayer then
				vars.faction = player
			else
				vars.faction = player.alliance
			end
		else
			vars.faction = player
		end			
		--todo add registartion
		--self:registerCallback_(vars.faction, "onResourcesChanged", "updateHud")
		
		local mod_list = {ModManager():getEnabledMods()}
		for _, mod_id in pairs(mod_list) do
			if mod_id == "3473880618" then
				vars.real_captains = true	
				break
			end
		end
	end
end

function Builder:syncClient(key, value)
	if onServer() then
		--cant think of better handling of nested tables for now. I need to access tabl.a.b.c.d = value by single variable, like tabl[variable] = value
		local player = Player(callingPlayer)
		if not player then print("Cannot sync Server -> Client : no calling player") return end
		self:invokeClientFunction_(player, "syncClient", key, value)
		return
	end
	
	if type(key) == "string" then
		self.data[key] = value
	else
		local target = self.data
		local lenght = #key
		local last_key
		for k, v in ipairs(key) do
			if k ~= lenght then
				target = target[v]
				last_key = v
			end
		end
		target[last_key] = value
	end
end
--callable

function Builder:syncVar(key, value)
	if onClient() then
		--cant think of better handling of nested tables for now. I need to access tabl.a.b.c.d = value by single variable, like tabl[variable] = value
		self:invokeServerFunction_("syncVar", key, value)
		return
	end
	
	if type(key) == "string" then
		self.vars[key] = value
	else
		local target = self.vars
		local lenght = #key
		local last_key
		for k, v in ipairs(key) do
			if k ~= lenght then
				target = target[v]
				last_key = v
			end
		end
		target[last_key] = value
	end
end
--callable
function Builder:syncVarClient(key, value)
	if onServer() then
		--cant think of better handling of nested tables for now. I need to access tabl.a.b.c.d = value by single variable, like tabl[variable] = value
		local player = Player(callingPlayer)
		if not player then print("Cannot sync var Server -> Client : no calling player") return end
		self:invokeClientFunction_(player, "syncVarClient", key, value)
		return
	end
	
	if type(key) == "string" then
		self.vars[key] = value
	else
		local target = self.vars
		local lenght = #key
		local last_key
		for k, v in ipairs(key) do
			if k ~= lenght then
				target = target[v]
				last_key = v
			end
		end
		target[last_key] = value
	end
end
--callable

function Builder:test()
	print("test")
	print(tostring(self.vars.faction.money))
end

function Builder:deferredCallback_(delay, func, ...)
	local master = self.master
	master.deferredCallbackUIB(delay, func, ...)
end

function Builder:invokeServerFunction_(func, ...)
	local master = self.master
	master.invokeServerUIB(func, ...)
end

function Builder:invokeClientFunction_(client, func, ...)
	local master = self.master
	master.invokeClientUIB(client, func, ...)
end

function Builder:registerCallback_(who, callback_name, callback_function)
	master = self.master
	if master[callback_function] then
		local original = master[callback_function]
		master[callback_function] = function(...)
			original(...)
			self[callback_function](self, ...)
		end
	else
		master[callback_function] = function(...)
			self[callback_function](self, ...)
		end
	end
	who:registerCallback(callback_name, callback_function)
end

function Builder:initUI(window, tabbed_window)
	local vars = self.vars
	local config = self.vars.config
	vars.window = window
	vars.tabbed_window = tabbed_window
	if not vars.window then return print("error no window") end
	vars.layers[500] = vars.window

--[[ todo implement later
	if config.background.static ~= nil then
		vars.bg_static = config.background.bg_static
	else
		vars.bg_static = true
	end
--]]	

	local resolution = getResolution()
	--change size according to the difference with fullHd, keep 16:9 ratio at all costs
	fixed_resolution = vec2(1920*resolution.y/1080, resolution.y)
	fixed_position = vec2((resolution.x - fixed_resolution.x)/2, 0)
	
	if not hub.vars.window then
		self:buildHubWindow(resolution)
	end
	self:buildBackground(resolution)	
	self:buildFrame()
	self:buildHud(resolution)
	self:buildSound()
	self:buildTabs()
	
	--dev tool
	if high_ping then
		self:deferredCallback_(high_ping, "initialSync")
	else
		self:initialSync()
	end
end

function Builder:buildHubWindow(resolution)
	--several instances of uiBulder will try to create copies of this window, dont need that
	local config = hub.vars.config
	if not config then return end	
	local vars = hub.vars
	local menu = ScriptUI()
	local window = menu:createWindow(Rect(vec2(0, 0)))
	vars.window = window
	window.showCloseButton = false
	window.moveable = false 
	window:hide()
	vars.layers[50] = window
	
	local bg = window:createWindow(Rect(vec2(0, 0)))
	bg.showCloseButton = false
	bg.moveable = false 
	bg:hide()
	--must be lower than 101, otherwise will not be visible
	vars.layers[100] = bg
	vars.hud.bg = bg
	
	local border = bg:createPicture(Rect(vec2(fixed_position.x, resolution.y)), "data/textures/icons/nothing.png")
	border.position = vec2(0, 0)
	
	border = bg:createPicture(Rect(vec2(fixed_position.x, resolution.y)), "data/textures/icons/nothing.png")
	border.position = vec2(resolution.x - fixed_position.x, 0)
		
	local path = config.background.path or ""
	local number = config.background.number or 1
	local format_ = config.background.format_ or "png" 
	path = path .. "/" .. math.random(1, number) .. "." .. format_
	local picture = bg:createPicture(Rect(fixed_resolution), "data/textures/icons/nothing.png")
	picture.position = fixed_position
	picture.flipped = true	
	
	vars.hud.bg_picture = picture
	vars.ui_initialized = true

	if vars.data_restored then
		--print("if resored")
		if vars.hud.bg_path then
			--print("if bg path")
			vars.hud.bg_picture.picture = vars.hud.bg_path
		else
			vars.hud.bg_picture.picture = path
			vars.hud.bg_path = path
			--print("no bg path", path)
			self:syncHub("bg_path", path)
		end
	else
		vars.hud.bg_path = path
	end
end

function Builder:buildBackground(resolution)
	local vars = self.vars
	local master = self.master
	local bg = vars.window:createWindow(Rect(vec2(0, 0)))
	bg.showCloseButton = false
    bg.moveable = false 
	bg:hide()
	vars.layers[1000] = bg
	vars.hud.bg = bg
	
	local border = bg:createPicture(Rect(vec2(fixed_position.x, resolution.y)), "data/textures/icons/nothing.png")
	border.position = vec2(0, 0)
	
	border = bg:createPicture(Rect(vec2(fixed_position.x, resolution.y)), "data/textures/icons/nothing.png")
	border.position = vec2(resolution.x - fixed_position.x, 0)	
	
	local picture, path = self:buildBackgroundPicture(vars.config.background)
	if picture then
		picture.picture = "data/textures/icons/nothing.png"
		vars.hud.bg_picture = picture
		vars.hud.bg_path = path
	end
	
	local func = "onBackButton"
	local button = vars.window:createButton(Rect(vec2(40, 40)), "", func)
	button.hasFrame = false
	button.position = vars.window.position - vec2(0, 40)
	
	if master[func] then
		local original = master[func]
		master[func] = function(...)
			original(...)
			self[func](self, ...)
		end
	else
		master[func] = function(...)
			self[func](self, ...)
		end
	end	
end

function Builder:buildBackgroundPicture(config)
	if not config.path then print("UI lib Error: no path for background picture") return end
	local vars = self.vars
	local path = config.path .. "/" .. math.random(1, config.number or 1) .. "." .. (config.format_ or "png")
	local picture = vars.hud.bg:createPicture(Rect(fixed_resolution), path)
	picture.position = fixed_position
	picture.flipped = true
	return picture, path
end

function Builder:buildTabs()
	local vars = self.vars
	local config = vars.config.tabbed_window
	if not vars.tabbed_window or not config then return end
	vars.tabbed_window_tabs = {}
	local master = self.master
	for tab_name, tabl in pairs(config) do
		local tab
		local entry
		if vars.config.tabbed_window_translated then
			local name = tab_name%_t
			tab = vars.tabbed_window:getTab(name)
			vars.tabbed_window_tabs[name] = {}	
			entry = vars.tabbed_window_tabs[name]	
			entry.name = name
			entry.name_en = tab_name
		else
			tab = vars.tabbed_window:getTab(tab_name)
			vars.tabbed_window_tabs[tab_name] = {}	
			entry = vars.tabbed_window_tabs[tab_name]
			entry.name = tab_name
			entry.name_en = tab_name
		end
		entry.tab = tab
		if tab then
			if tabl.background then
				local picture, path = self:buildBackgroundPicture(tabl.background)
				if not picture then print("UI lib Error: cannot create tabbed window background") break return end
				picture:hide()
				entry.picture = picture
			end
			if tabl.dialogs then			
				package.path = package.path .. ";" .. tabl.dialogs.path .. "/?.lua"
				local config_ = include(tabl.dialogs.file_name)
				entry.dialog_config = config_
			end
			
			local function_name = tab.onShowFunction
			if function_name == "" then
				tab.onShowFunction = "showTabUIB"
				master.showTabUIB = function(...)
					self:onShowTab(...)
				end
			else
				local original = master[function_name]
				master[function_name] = function(...)
					original(...)
					self:onShowTab(...)
				end
			end
		else
			print("Error: no tab in tabbed window with this name", tab_name)
		end
	end
end

function Builder:setBackground(path, save)
	local vars = self.vars
	--[[todo add tabs
	local tab
	if vars.tabbed_window then
		tab = vars.tabbed_window:getActiveTab()
	end
	local entry = vars.tabbed_window_tabs[tab.name]
	--]]
	if not path then print("UI lib Error: cannot set background path: no path") return end
	vars.hud.bg_picture.picture = path
	--todo delay this function after restoration
	if not self.data.bg_path then return end
	if save then
		vars.hud.bg_path = path
		self.data.bg_path = path
		self:sync("bg_path", vars.hud.bg_path)
	end
end

function Builder:resetBackground()
	local vars = self.vars
	--[[todo add tabs
	local tab
	if vars.tabbed_window then
		tab = vars.tabbed_window:getActiveTab()
	end
	local entry = vars.tabbed_window_tabs[tab.name]
	--]]
	
	--todo delay this function after restoration
	if not self.data.bg_path then return end
	vars.hud.bg_picture.picture = self.data.bg_path
end

function Builder:createLayer(layer)
	local vars = self.vars
	local window = vars.window:createWindow(Rect(vec2(0, 0)))
	vars.layers[layer] = window
	return window
end

function Builder:onBackButton()
	ScriptUI():restartInteraction()
end

function Builder:buildFrame()
	local vars = self.vars
	--actual size in the .png file
	local frame_size = vec2(1400, 807)
	local frame_size_2 = vec2(1265, 714)
	local frame_corner = vec2(68, 62)
	local position_offset = vec2(1, -39)
	local size_offset = vec2(-1, 39)
	local difference = frame_size/frame_size_2
	local window_size = vars.window.size
		
	local frame = vars.window:createPicture(Rect(vec2(0, 0), window_size*difference + size_offset), "data/textures/uiLib/centerFrame.png")
	local frame_vs_window_diff = frame_size/(difference*window_size + size_offset)
	frame.position = frame.position - frame_corner/frame_vs_window_diff + position_offset
	frame.flipped = true
	
	vars.hud.frame = frame
end

function Builder:buildHud(resolution)
	local vars = self.vars
	local res = getResolution()
	local size_fix = fixed_resolution/vec2(1920, 1080)
	
	local hud_layer_1 = vars.window:createWindow(Rect(vec2(0, 0)))
	hud_layer_1.position = vec2(0, 0)
	hud_layer_1.showCloseButton = false
	hud_layer_1:hide()
	hud_layer_2 = vars.window:createWindow(Rect(vec2(0, 0)))
	hud_layer_2.position = vec2(0, 0)
	hud_layer_2.showCloseButton = false
	hud_layer_2:hide()

	vars.layers[250] = hud_layer_1
	vars.layers[240] = hud_layer_2

	local resource_container = hud_layer_2:createContainer(Rect(vec2(0, 0)))
	vars.hud.resources_container = resource_container
	local top_container_1 = hud_layer_1:createContainer(Rect(vec2(0, 0)))
	local top_container_2 = hud_layer_2:createContainer(Rect(vec2(0, 0)))
	vars.hud.top_bar_container_1 = top_container_1
	vars.hud.top_bar_container_2 = top_container_2

	--todo fix docked tooltip change
	local hud_picture_list = {
		{name = "resource_shadow", creator = hud_layer_1, size = vec2(300, 240)/1.09, position = vec2(0, 0), path = "data/textures/uiLib/resource_shadow.png"},
		{name = "resource_frame", creator = resource_container, size = vec2(300, 240), position = vec2(0, 0), path = "data/textures/uiLib/resource_frame.png"},
		{name = "top_bar", creator = top_container_1, size = vec2(855, 40), position = vec2(532.5, 0), path = "data/textures/uiLib/top_bar.png"},
		{name = "docking_icon", creator = top_container_2, size = vec2(60, 30), position = vec2(587.5, 6), tooltip = "Docking status of your ship"%_t, path = "data/textures/uiLib/docking_icon.png"},
		{name = "docking_status", creator = top_container_2, size = vec2(82, 30), position = vec2(655.5, 6), tooltip = "Docked"%_t, path = "data/textures/uiLib/docking_green.png"},	
		{name = "cargo_icon", creator = top_container_2, size = vec2(28, 28), position = vec2(759.5, 6), tooltip = "Free cargo space in your current ship"%_t, path = "data/textures/uiLib/cargo_icon.png"},
		{name = "money_icon", creator = top_container_2, size = vec2(28, 28), position = vec2(1077.5, 7), tooltip = "Money"%_t, path = "data/textures/uiLib/money_icon.png"},
		{name = "cargo_underlay_icon", creator = top_container_2, size = vec2(210, 30), position = vec2(795.5, 6), path = "data/textures/uiLib/value_underlay.png"},	
		{name = "money_underlay_icon", creator = top_container_2, size = vec2(210, 30), position = vec2(1112.5, 6), path = "data/textures/uiLib/value_underlay.png"},	
		{name = "player_dialog_frame", creator = hud_layer_2, size = vec2(500, 175), position = vec2(445, 865), flipped_x = true, path = "data/textures/uiLib/dialog_frame.png"},	
		{name = "npc_dialog_frame", creator = hud_layer_2, size = vec2(500, 175), position = vec2(975, 865), path = "data/textures/uiLib/dialog_frame.png"},	
		{name = "npc_dialog_shadow", creator = hud_layer_1, size = vec2(500, 175), position = vec2(975, 865), path = "data/textures/uiLib/dialog_shadow_tr_3.png"},		
		{name = "player_dialog_shadow", creator = hud_layer_1, size = vec2(500, 175), position = vec2(445, 865), path = "data/textures/uiLib/dialog_shadow_tr_3.png"},		
		{name = "npc_portrait_frame", creator = hud_layer_1, size = vec2(383, 315), position = vec2(1487, 735), path = "data/textures/uiLib/portrait_frame.png"},		
		{name = "npc_portrait", creator = hud_layer_2, size = vec2(256, 256), position = vec2(1520, 764), path = "data/textures/uiLib/static_small.png"},		
		{name = "player_portrait_frame", creator = hud_layer_1, size = vec2(383, 315), position = vec2(50, 735), flipped_x = true, path = "data/textures/uiLib/portrait_frame.png"},		
		{name = "player_portrait", creator = hud_layer_2, size = vec2(256, 256), position = vec2(145, 764), path = "data/textures/uiLib/static_small.png"},		
	}
	
	local hud_resource_list = {
		{caption = "Credits", color = ColorRGB(1, 1, 1)},
		{caption = "Iron", color = ColorRGB(1, 0.7, 0.5)},
		{caption = "Titanium", color = ColorRGB(1, 1, 1)},
		{caption = "Naonite", color = ColorRGB(0.3, 1, 0.3)},
		{caption = "Trinium", color = ColorRGB(0.3, 0.6, 1)},
		{caption = "Xanion", color = ColorRGB(1, 1, 0.3)},
		{caption = "Ogonite", color = ColorRGB(1, 0.5, 0.2)},
		{caption = "Avorion", color = ColorRGB(1, 0.15, 0.15)},		
	}
		
	local hud_stats_list = {
		{name = "cargo_value", position = vec2(810, 8)},	
		{name = "cargo_diff", position = vec2(810, 42)},	
		{name = "money_value", position = vec2(1127, 8)},	
		{name = "money_diff", position = vec2(1127, 42)},			
	}
	
	--create underlay + overlay pictures
	for _, line in pairs(hud_picture_list) do
		local element = line.creator:createPicture(Rect(line.size*size_fix), line.path)
		if line.flipped ~= false then
			element.flipped = true
		end
		if line.flipped_x then
			element.flippedX = true
		end
		element.position = line.position*size_fix + fixed_position
		if line.tooltip then 
			element.tooltip = line.tooltip
		end
		vars.hud[line.name] = element
	end
		
	--create resources tab
	local lister = UIVerticalLister(Rect(fixed_position.x, fixed_position.y, fixed_position.x, fixed_position.y), 4*size_fix.y, 0)
	lister.marginTop = 3*size_fix.y
	lister.marginLeft = 5*size_fix.y
	local lister_2 = UIVerticalLister(Rect(fixed_position.x, fixed_position.y, 255*size_fix.y + fixed_position.x, 300*size_fix.y), 4*size_fix.y, 0)
	lister_2.marginTop = 3*size_fix.y

	for i = 1, 8 do
		local line = hud_resource_list[i]
		local label = resource_container:createLabel(Rect(vec2(96, 22)*size_fix), "", 22*size_fix.y)
		label:setLeftAligned()
		local label_2 = resource_container:createLabel(Rect(vec2(148, 22)*size_fix), "", 22*size_fix.y)
		label.caption = line.caption
		label.color = line.color
		label_2.color = line.color
		label_2:setRightAligned()
		lister:placeElementTopLeft(label)
		lister_2:placeElementTopRight(label_2)
		
		vars.hud.resources[i] = label_2
	end
	
	--create top bar values
	for _, line in pairs(hud_stats_list) do
		local label = top_container_2:createLabel(Rect(vec2(180, 22)*size_fix), "", 22*size_fix.y)
		label:setRightAligned()
		label.position = line.position*size_fix + fixed_position
		vars.hud.stats[line.name] = label
	end
	
	--create player + npc text containers
	local listbox = hud_layer_2:createListBox(Rect(vec2(450, 135)*size_fix))
	listbox.position = vec2(470, 890)*size_fix + fixed_position
	listbox.fontSize = 18*size_fix.y
	listbox.rowHeight = 30*size_fix.y
	listbox.onSelectFunction = "onDialogClick"

	vars.hud.player_text = listbox
	
	local textfield = hud_layer_2:createTextField(Rect(vec2(440, 125)*size_fix), "")
	textfield.position = vec2(1005, 890)*size_fix + fixed_position
	textfield.fontSize = 18*size_fix.y
	textfield.padding = 0
	textfield.scrollable = true

	vars.hud.npc_text = textfield
end

function Builder:buildSound()
	local vars = self.vars
	local config = vars.config.sound
	vars.sound_manager = {}
	if config then
		vars.sound_manager.ambient = SoundSource(config.path, vec3(0, 0, 0), 1000000)
		config.volume = config.volume or 1
		vars.sound_manager.ambient.volume = config.volume
		--vars.sound_manager.source:play()
	end
	local config = vars.config.music
	if config then
		config.volume = config.volume or 1
		vars.sound_manager.music = Music()	
		local path = config.path .. "/" .. math.random(1, config.number or 1) .. ".ogg"
		vars.music_path = path			
	end
end

function Builder:setSound(path, volume, play)
	if not user_config then print("Error: cannot set sound, user config is not loaded yet") return end
	local vars = self.vars
	if vars.sound_manager.ambient then
		vars.sound_manager.ambient:terminate()
	end
	vars.sound_manager.ambient = SoundSource(path, vec3(0, 0, 0), 1000000)
	volume = volume or 1
	local user_volume = user_config.sound_volume/100
	if user_volume < volume then
		vars.sound_manager.ambient.volume = user_volume
	else
		vars.sound_manager.ambient.volume = volume
	end
	if play then
		vars.sound_manager.ambient:play()
	end
end

function Builder:showPortraits()	
	local vars = self.vars
	vars.hud.player_portrait.picture = "data/textures/uiLib/static_small.png"	
	vars.hud.npc_portrait.picture = "data/textures/uiLib/static_small.png"	
	if vars.real_captains then
		local player = Player()
		local captain
		if player.craft and not player.craft.isDrone then
			captain = player.craft:getCaptain()
		end
		if captain then
			local portrait = RealCaptains_getPortrait(captain)
			if portrait then
				vars.hud.player_portrait:fadeTo(RealCaptains_getPortrait(captain), 1)
			else
				vars.hud.player_portrait:fadeTo("data/textures/icons/question-mark.png", 1)
			end
		else
			vars.hud.player_portrait:fadeTo("data/textures/icons/question-mark.png", 1)
		end	
	else
		vars.hud.player_portrait.tooltip = "The portrait of your captain will be here if you subscribe to the Real captains 2 mod"
		vars.hud.player_portrait:fadeTo("data/textures/icons/question-mark.png", 1)
	end
	--todo fix order and conditions to add flexibility
	if vars.npc_captain then
		local dialog = vars.dialog
		if not(dialog and dialog.lines[dialog.current].hide_portrait == true) then
			vars.hud.npc_portrait:fadeTo(vars.npc_captain, 1)
		end
	end
end

--triggers after 'onShowTab'
function Builder:onShowWindow()
	local vars = self.vars
	if not vars.window or not vars.window.visible then return end
	vars.player_stats = player_stats
	vars.hud.deferred = 0
	self:updateHud(0)
	vars.hud.stats.cargo_diff.caption = ""
	vars.hud.stats.money_diff.caption = ""
	
	vars.money_changed = false
	vars.crew_changed = false
	if vars.hud_is_hidden == nil then
		vars.hud_is_hidden = false
	end
	--Builder.syncReadDialog()

	self:showLayers()
			
	local conditions = vars.config.background_conditions	
	local show = false
	if user_config.always_show_background and not conditions.ignore_settings then
		show = true
	elseif conditions.default == "show" then
		show = true
	elseif player_stats.is_docked or player_stats.other_docked then
		show = true
	elseif player_stats.craft.index == Entity().dockingParent then
		show = true
	elseif conditions.distance > 0 and player_stats.craft:getNearestDistance(Entity()) <= conditions.distance/10 then
		show = true
	end
	if not show then
		vars.hud.bg:hide()
	end

	--useless to show resources if background is hidden
	if user_config.show_recources and vars.hud.bg.visible then
		vars.hud.resources_container:show()
		vars.hud.resource_shadow:show()
	else
		vars.hud.resources_container:hide()
		vars.hud.resource_shadow:hide()
	end
	
	if user_config.show_top_bar then
		vars.hud.top_bar_container_1:show()
		vars.hud.top_bar_container_2:show()
	else
		vars.hud.top_bar_container_1:hide()
		vars.hud.top_bar_container_2:hide()
	end
	
	if vars.sound_manager.ambient then
		local user_volume = user_config.sound_volume/100
		vars.sound_manager.ambient:play()	
		if user_volume < vars.config.sound.volume then
			vars.sound_manager.ambient.volume = user_volume
		else
			vars.sound_manager.ambient.volume = vars.config.sound.volume
		end
	end
	
	if vars.sound_manager.music then
		self:playTrack(vars.music_path, true, "config_volume")
	end

	--todo check for bugs on multiple tabs, dialog showing is not complete yet
	if vars.restored then
		--for tabs, if current tab is non-existent or does not contain dialog
		if not vars.active_tab or not vars.active_tab.dialog_config then
			if vars.dialog_config then
				local dialog_config = vars.dialog_config.default_dialog
				if dialog_config then
					self:constructDialog(dialog_config.lines, dialog_config)
				else
					vars.hud.npc_text.text = "..."
					vars.hud.player_text:clear()
					vars.hud.player_text:addEntry("...")
				end
			end
		end
	elseif not vars.dialog_wait_sync then
		--nil, 1 or 2 
		vars.dialog_wait_sync = 1
	end
	self:showPortraits()
	self:autoUpdateHud()
end

--todo add dialog saving/restoring for tabbed windows
function Builder:onShowTab()
	local vars = self.vars
	local tab = vars.tabbed_window:getActiveTab()
	local entry = vars.tabbed_window_tabs[tab.name]
	if not vars.active_tab then		
		vars.active_tab = entry
	else
		if vars.active_tab.picture then
			vars.active_tab.picture:hide()
		end		
		vars.active_tab = entry
	end	
	if entry.picture then
		entry.picture:show()
		vars.hud.bg_picture:hide()	
	else
		vars.hud.bg_picture:show()	
	end
	local config_entry = vars.config.tabbed_window[entry.name_en]
	--todo disable default sound for this case
	if config_entry.sound then
		self:setSound(config_entry.sound.path, config_entry.sound.volume, true)
	end	
	--todo refresh on each tab press only if its required by config
	if vars.restored then
		local dialog_config = entry.dialog_config.default_dialog
		if dialog_config then
			self:constructDialog(dialog_config.lines, dialog_config)
			vars.dialog_source = tab.name
		elseif vars.dialog_source ~= "UIB_window" then
			if vars.dialog_config then
				local dialog_config = vars.dialog_config.default_dialog
				if dialog_config then
					self:constructDialog(dialog_config.lines, dialog_config)
					--default window, named like that to prevent name clash
					--todo check if actually needed
					vars.dialog_source = "UIB_window"
				else
					vars.hud.npc_text.text = "..."
					vars.hud.player_text:clear()
					vars.hud.player_text:addEntry("...")
					vars.dialog_source = nil
				end
			end	
		end
	else
		--nil, 1 or 2 
		vars.dialog_wait_sync = 1
	end
end

function Builder:onShowHub()
	--///// Hub code	
	local vars = hub.vars
	if (not vars.window) then return end
	--need to to every time backspace is pressed to move hub background underneath
	for i, window in pairs(vars.layers) do
		window.layer = -i
	end		
	
	--disable script triggering when backspace was hit, because its not a fresh interaction with entity
	if vars.backspace_time and (vars.backspace_time + 0.2) > os.clock() then return end
	local player = Player()
	local _, config = player:invokeFunction("data/scripts/player/uiLib/UIManager.lua", "sendUserConfig", "u3548610240")
	if not config then 
		print("Error: 'Real Stations' user config failed to load. Default settings will be used")
		local _, config_ = player:invokeFunction("data/scripts/player/uiLib/UIManager.lua", "sendDefaultConfig", "u3548610240")
		user_config	= config_
	else
		user_config	= config
	end
	
	self:refreshPlayerStats()

	if vars.config then
		local conditions = vars.config.background_conditions	
		local show = false
		if user_config.always_show_background and not conditions.ignore_settings then
			show = true
		elseif conditions.default == "show" then
			show = true
		elseif player_stats.is_docked or player_stats.other_docked then
			show = true
		elseif player_stats.craft.index == Entity().dockingParent then
			show = true
		elseif conditions.distance > 0 and player_stats.craft:getNearestDistance(Entity()) <= conditions.distance/10 then
			show = true
		end
		if show then		
			local orderer = {}
			for k in pairs(vars.layers) do
				if not vars.hidden_layers[k] then
					table.insert(orderer, k) 
				end
			end
			table.sort(orderer, function(a, b) return a > b end)
			for _, k in ipairs(orderer) do 
				vars.layers[k]:show()
			end

			for i, window in pairs(vars.layers) do
				window.layer = -i
			end		
		else
			for _, layer in pairs(vars.layers) do
				layer:hide()
			end
		end
	else
		print("no co")
	end
	--///// Builder instance code
	local vars = self.vars
	vars.player_stats = player_stats
	
	local VI_lines = vars.VI_lines
	if VI_lines and player_stats.is_docked then
		self:playVoice("docked")
	end
end

function Builder:showLayers()
	local vars = self.vars
	local orderer = {}
	for k in pairs(vars.layers) do
		if not vars.hidden_layers[k] then
			table.insert(orderer, k) 
		end
	end
	table.sort(orderer, function(a, b) return a > b end)
	for _, k in ipairs(orderer) do 
		vars.layers[k]:show()
	end
end

--instead of onResourceUpdate callback, no need to catch every resource change immediately
function Builder:autoUpdateHud()
	local vars = self.vars
	if not vars.window or not vars.window.visible then return end
	local faction = player_stats.faction
	if user_config.show_recources then
		local resources = {faction:getResources()}
		local label = vars.hud.resources[1]
		label.caption = createMonetaryString(faction.money)
		for i = 2, 8 do
			local label = vars.hud.resources[i]
			label.caption = createMonetaryString(resources[i - 1])
		end
	end	
	vars.hud.stats.money_value.caption = createMonetaryString(faction.money)
	self:deferredCallback_(3, "autoUpdateHud")
end

function Builder:updateHud(time_stamp)
	local vars = self.vars
	if not vars.window or not vars.window.visible then return end
	--if player clicked several times then only latest click will be processed (vars.hud.deferred = timestamp of latest click)
	if time_stamp ~= vars.hud.deferred then return end
	local player = player_stats.player
	local faction = player_stats.faction
	local craft = player_stats.craft
	if craft then
		vars.hud.stats.cargo_value.caption = createMonetaryString(player.craft.freeCargoSpace)
		if vars.cargo_old then
			local cargo_diff = craft.freeCargoSpace - vars.cargo_old
			local label = vars.hud.stats.cargo_diff
			if cargo_diff > 0 then
				label.color = ColorRGB(0.5, 1, 0.5)
				label.caption = "+" .. createMonetaryString(cargo_diff)
				self:playVoice("sell_cargo")
			elseif cargo_diff < 0 then
				label.color = ColorRGB(1, 0.5, 0.5)
				label.caption = createMonetaryString(cargo_diff)
				self:playVoice("buy_cargo")
				if craft.freeCargoSpace < 3 then
					self:playVoice("full_cargo")
				end
			end
			if cargo_diff ~= 0 and craft.occupiedCargoSpace == 0 then
				self:playVoice("sold_all_cargo")	
			end
			vars.cargo_old = nil
		end
		if craft:isInDockingArea(entity) then
			vars.hud.docking_status.picture = "data/textures/uiLib/docking_green.png"
			vars.hud.docking_status.tooltip = "Docked"
		else
			vars.hud.docking_status.picture = "data/textures/uiLib/docking_red.png"
			vars.hud.docking_status.tooltip = "Not docked"
		end
	end
	
	if user_config.show_recources then
		local resources = {faction:getResources()}
		local label = vars.hud.resources[1]
		label.caption = createMonetaryString(faction.money)
		for i = 2, 8 do
			local label = vars.hud.resources[i]
			label.caption = createMonetaryString(resources[i - 1])
		end
	end
	
	vars.hud.stats.money_value.caption = createMonetaryString(faction.money)
	if vars.money_old then
		local money_diff = faction.money - vars.money_old
		local label = vars.hud.stats.money_diff			
		if money_diff > 0 then
			label.color = ColorRGB(0.5, 1, 0.5)
			label.caption = "+" .. createMonetaryString(money_diff)
			vars.money_changed = true
		elseif money_diff < 0 then
			label.color = ColorRGB(1, 0.5, 0.5)
			vars.money_changed = true
		end
		vars.money_old = nil	
	end
end

--47395
--todo fix multiple triggering on equipment dock
function Builder:onCloseWindow()
	local clock_ = os.clock()
	--prevent second pass of onCloseWindow()
	--if hub.vars.backspace_time and hub.vars.backspace_time == clock_ then return end
	hub.vars.backspace_time = clock_
	local vars = self.vars
	--hiding layers triggers second pass of onClose() automatically by Avorion scripts
	for _, layer in pairs(vars.layers) do
		layer:hide()
	end
	if vars.sound_manager.ambient then
		vars.sound_manager.ambient:stop()
	end
	if vars.sound_manager.music then		
		vars.sound_manager.music.autoPlay = true
		--to encourage next vanilla track to play earlier
		vars.sound_manager.music:fadeOut(1)		
		vars.sound_manager.music:playSilence(0.1)
	end
	if vars.money_changed and not vars.crew_changed then
		self:playVoice("trade_happened")
		vars.money_changed = false
	end	
	if vars.crew_changed then
		self:playVoice("crew_is_hired")
		vars.crew_changed = false
	end

	--vars.hud.pl_text:clear()
	--vars.hud.npc_text.text = ""
	--Builder.saveReadDialog()
end

function Builder:fadePortrait(who, path, duration)
	if not path then print("ERROR: uiBuilder: unable to fadePortrait, no path") end
	duration = duration or 1
	if who == "player" then
		self.vars.hud.player_portrait:fadeTo(path, duration)
	elseif who == "npc" then
		self.vars.hud.npc_portrait:fadeTo(path, duration)
	else
		print("ERROR: uiBuilder: unable to fadePortrait, wrong target")
	end
end

function Builder:playVoice(name)
	if onServer() then
		local player = Player(callingPlayer)
		if not player then return end
		self:invokeClientFunction_(player, "playVoice", name)
		return
	end
	local lines_ = self.vars.VI_lines
	if not lines_ then print("Error: no VI_lines for this UIBuilder instance") return end
	local path = self.vars.VI_path
	if not path then print("Error: no VI_path for this UIBuilder instance") return end
	local entry = lines_[name]
	if not entry then print("Error: no VI line with this name found", name) return end
	local duration = entry.duration
	path = path .. "/" .. entry.path
	type_ = type_ or SoundType.Other
	volume = volume or 1
	--prevent ignoring user settings
	local user_volume = user_config.VI_volume/100
	if user_volume < volume then
		volume = user_volume
	end
	local id = entry.id
	local frequency = entry.frequency or 0
	local source = entry.source or Entity().index.string
	Player():invokeFunction("data/scripts/player/uiLib/UIManager.lua", "addVoiceEntry", path, duration, type_, volume, id, frequency, source)
end

function Builder:onKeyboardEvent(key, pressed)
	if not pressed then return end
	local vars = self.vars
	if not self.vars.window or not self.vars.window.visible then return end
	if key == KeyboardKey.Space then
		if self.vars.hud.bg.visible then
			for _, layer in pairs(self.vars.layers) do
				layer:hide()
			end
			for _, layer in pairs(hub.vars.layers) do
				layer:hide()
			end
			self.vars.window:show()
		else		
			self:showLayers()
		end	
	elseif key == KeyboardKey.Backspace then
		self:onBackButton()
	end
end

function Builder:onMouseEvent(key, pressed, x, y)
	if not pressed then return end	
	local vars = self.vars
	if not self.vars.window or not self.vars.window.visible then return end
	if key == MouseButton.Left then
		vars.money_old = player_stats.faction.money
		if player_stats.craft then 
			vars.cargo_old = player_stats.craft.freeCargoSpace
		end
		--calculate difference in stats when something was clicked on and several moments after the event
		vars.hud.deferred = os.clock()
		self:deferredCallback_(0.25, "updateHud", vars.hud.deferred)
	end
end

--todo make as an alternative to the securer.lua
--[[
function Builder:secure(master_data)
	if not self.data then
		self.data = {}	
	end	
	self.data.master_data = master_data
	--print("builder secure")
	return self.data
end

function Builder:restore(restored_data)
	--print("builder restore")
	self.data = restored_data or {}
end
--]]

--toto try several times before giving up
function Builder:requestClientSync(data_in)
	if onClient() then
		if not data_in then
			self:invokeServerFunction_("requestClientSync")
		else			
			hub.data = data_in
			--print("request sync 2", type(hub.data),	hub.data.bg_path)
			self:restoreHub()
		end	
		
		return		
	end
	--load data that is secured by external script (because only 1 namespace per file is allowed and we have several instances of uiBuilder, also the builder is included in a master file - so no callbacks and secure/restore possible without intervention in master's functions)
	local _, data = Entity():invokeFunction("data/scripts/uiLib/securer.lua", "sendData", 1)
	hub.data = data
	--impossible in normal circumstances, but installing mid-playthgrough or some other factors can break securer script attachement
	if not data then
		print("Real Stations error: entity cannot restore saved data. This entity was already existing before, therefore reloading save will help entities in loaded sectors to repair")
		hub.data = {}
	end
	local player = Player(callingPlayer)
	if not player then return end
	--print("request sync", data.bg_path)	
	if disable_restore then
		hub.data = {}
		self:invokeClientFunction_(player, "requestClientSync", hub.data)
	else
		self:invokeClientFunction_(player, "requestClientSync", hub.data)
	end	
end
--callable

function Builder:restoreHub()
	local vars = hub.vars
	vars.data_restored = true
	--print("restore hub")
	if hub.data.bg_path then
		--print("if path")
		vars.hud.bg_path = hub.data.bg_path
		if vars.ui_initialized then
			vars.hud.bg_picture:fadeTo(hub.data.bg_path, 1)
		end
	elseif vars.ui_initialized then
		--print("if initialized")
		vars.hud.bg_picture:fadeTo(vars.hud.bg_path, 1)
		self:syncHub("bg_path", vars.hud.bg_path)
	end
	--////////dev tools
	if show_saved_data then
		print("----------HUB DATA----------")
		print("BG", hub.data.bg_path)
	end
end

function Builder:syncHub(key, value)
	if onClient() then
		--cant think of better handling of nested tables for now. I need to access tabl.a.b.c.d = value by single variable, like tabl[variable] = value
		self:invokeServerFunction_("syncHub", key, value)
		return
	end
	
	if type(key) == "string" then
		hub.data[key] = value
		--print("sync hub", key, value)
	else
		local target = hub.data
		local lenght = #key
		local last_key
		for k, v in ipairs(key) do
			if k ~= lenght then
				target = target[v]
				last_key = v
			end
		end
		target[last_key] = value
	end
	
	Entity():invokeFunction("data/scripts/uiLib/securer.lua", "receiveData", 1, hub.data)
	--print(a)
end
--callable

function Builder:sync(key, value)
	if onClient() then
		--print(key, type(value))
		--cant think of better handling of nested tables for now. I need to access tabl.a.b.c.d = value by single variable, like tabl[variable] = value
		self:invokeServerFunction_("sync", key, value)
		return
	end
	
	if type(key) == "string" then
		self.data[key] = value
		--print(key, type(value))
	else
		local target = self.data
		local lenght = #key
		local last_key
		for k, v in ipairs(key) do
			if k ~= lenght then
				target = target[v]
				last_key = v
			end
		end
		target[last_key] = value
	end
	
	Entity():invokeFunction("data/scripts/uiLib/securer.lua", "receiveData", self.id, self.data)
end
--callable

function Builder:initialSync(data_in)
	if onClient() then
		if not data_in then
			self:invokeServerFunction_("initialSync")
		else
			self.data = data_in
			self.data.dialog = self.data.dialog or {}
			self:restoreHud()
		end	
		
		return
	end
	--load data that is secured by external script (because only 1 namespace per file is allowed and we have several instances of uiBuilder, also the builder is included in a master file - so no callbacks and secure/restore possible without intervention in master's functions)
	local _, data = Entity():invokeFunction("data/scripts/uiLib/securer.lua", "sendData", self.id)
	self.data = data
	--impossible in normal circumstances, but installing mid-playthgrough or some other factors can break securer script attachement
	if not data then
		print("Real Stations error: entity cannot restore saved data. This entity was already existing before, therefore reloading save will help entities in loaded sectors to repair")
		self.data = {}
	end
	local player = Player(callingPlayer)
	if not player then return end
	self.vars.restored = true
	--print("restored d", type(self.data.dialog))
	self.data.dialog = self.data.dialog or {}
	if disable_restore then
		self.data = {}
		self.data.dialog = {}
		self:invokeClientFunction_(player, "initialSync", self.data)
	else
		self:invokeClientFunction_(player, "initialSync", self.data)
	end	
end
--callable

function Builder:restoreHud()
	--///// Builder instance code
	
	local vars = self.vars
	self.vars.restored = true
	
	--save is loaded -> apply changes from previous interactions
	if vars.dialog_config then
		local dialog_config = vars.dialog_config.default_dialog
		if dialog_config then
			local restored_data = self.data.dialog
			--print(type(next(self.data.dialog)))
			for _, node in pairs(dialog_config.lines) do
				local restored_node = restored_data[node.name]
				if restored_node then
					--print("rest", node.name)
					for flag, value in pairs(restored_node) do
						node[flag] = value
					end
				end
			end
		end
	end
	--todo add error or hide if not
	if vars.config.captains then 
		vars.npc_captain = self:fakeCaptain()
	end
	if vars.sound_manager.music then
		if self.data.music_path then
			vars.music_path = self.data.music_path
		else			
			self.data.music_path = vars.music_path
			self:sync("music_path", self.data.music_path)
		end
	end
	--prevent player from noticing background change by changing from black to new background
	if self.data.bg_path then
		if vars.window.visible then
			vars.hud.bg_picture:fadeTo(self.data.bg_path, 1)
		else
			vars.hud.bg_picture.picture = self.data.bg_path
		end
	else
		if vars.window.visible then
			vars.hud.bg_picture:fadeTo(vars.hud.bg_path, 1)
		else
			vars.hud.bg_picture.picture = vars.hud.bg_path
		end	
		self:sync("bg_path", vars.hud.bg_path)
	end
	--todo add dialog save loading for tab
	if vars.dialog_wait_sync then
		if vars.window.visible then
			local entry = vars.active_tab
			if entry then
				if entry.dialog_config then
					local dialog_config = entry.dialog_config.default_dialog
					if dialog_config then
						self:constructDialog(dialog_config.lines, dialog_config)
						vars.dialog_source = entry.name	
					end
				end
			else
				if vars.dialog_config then
					local dialog_config = vars.dialog_config.default_dialog
					if dialog_config then
						self:constructDialog(dialog_config.lines, dialog_config)
					else
						vars.hud.npc_text.text = "..."
						vars.hud.player_text:clear()
						vars.hud.player_text:addEntry("...")
					end
				end
			end
		end
		--todo reconsider this flag values
		vars.dialog_wait_sync = 2
	end
end

--checks on hud restore, returns to hud restore
--todo replace existing captain with RC pack if RC enabled after 
function Builder:fakeCaptain()
	local captain
	local vars = self.vars	
	local captain_portrait = self.data.captain_portrait
	local has_captain = false
	--prevent missing textures if real captains mod or some packs were disabled
	if captain_portrait then
		--remove old incorrect paths from my saves
		if type(captain_portrait) == "table" then
			if captain_portrait.is_real_captains then
				if vars.real_captains then
					local packs = RealCaptains_getList()
					if captain_portrait.pack_name and packs[captain_portrait.pack_name] then				
						has_captain = true
						captain = captain_portrait.path
					end
				end
			else
				has_captain = true
				captain = captain_portrait.path
			end	
		else
			captain_portrait = nil
		end
	end
	if not has_captain then
		local pack = vars.captain_pack
		if vars.real_captains and vars.config.captains.allow_real_captains then
			local pack_name
			captain, pack_name = RealCaptains_fakeCaptain()
			self.data.captain_portrait = {}
			self.data.captain_portrait.path = captain
			self.data.captain_portrait.is_real_captains = true
			self.data.captain_portrait.pack_name = pack_name
			self:sync("captain_portrait", self.data.captain_portrait)			
		elseif pack then
			captain = self:generateFakeCaptain(pack)		
			self.data.captain_portrait = {}
			self.data.captain_portrait.path = captain
			self:sync("captain_portrait", self.data.captain_portrait)	
		else
			return
		end
	end
	return captain
end

--called on Builder:fakeCaptain() if needed to generate captain without Real Captains mod
function Builder:generateFakeCaptain(pack_in, seed, size)
	local pack = pack_in
	if seed then
		math.randomseed(seed)
	end
	local race
	local total_spawn_weight = 0
    for _, race_ in ipairs(pack.races) do
        total_spawn_weight = total_spawn_weight + race_.race_chance
    end
    local random_weight = math.random(total_spawn_weight)
    local current_weigth = 0
    for _, race_ in ipairs(pack.races) do
        current_weigth = current_weigth + race_.race_chance
        if random_weight <= current_weigth then
            race = race_
			break
        end
    end
		
	if race.males == 0 and race.males_chance ~= 0 then
		return
	elseif race.males ~= 0 and race.males_chance == 0 then
		return
	end
	if race.females == 0 and race.females_chance ~= 0 then
		return
	elseif race.females ~= 0 and race.females_chance == 0 then
		return	
	end
	if race.males == 0 and race.females == 0 then
		return
	end
	
	local males_chance = race.males_chance or 0
	local females_chance = race.females_chance or 0
	if math.random(males_chance + females_chance) <= males_chance then
		gender = "males"
	else
		gender = "females"
	end
		
	local portrait
	
	local chance_tabl = race["portrait_chance_" .. gender]
	local total_gender_count = race[gender]
	if not chance_tabl then
		portrait = math.random(1, total_gender_count)
	else
		local total_spawn_weight = 0
		local complete_chance_tabl = {}
		
		for i = 1, total_gender_count do
			local weight = chance_tabl[i]
			if weight == nil then
				complete_chance_tabl[i] = 100
				total_spawn_weight = total_spawn_weight + 100
			else
				complete_chance_tabl[i] = weight
				total_spawn_weight = total_spawn_weight + weight
			end		
		end

		local random_weight = math.random(total_spawn_weight)
		local current_weigth = 0
		for id, weight in ipairs(complete_chance_tabl) do
			current_weigth = current_weigth + weight
			if random_weight <= current_weigth then
				portrait = id
				break
			end
		end
	end
	
	local path = pack.path .. "/"
	if size == "small" then
		if race["has_small_" .. gender] then
			path = path .. "small/"
		elseif race["portrait_small_" .. gender] then
			if race["portrait_small_" .. gender][tonumber(portrait)] then
				path = path .. "small/"
			end
		end
	end
	path = path .. race.folder_name .. "/" .. gender .. "/" .. portrait .. ".png"
	return path
end

function Builder:addQueue(config)
	local vars = self.vars
	if not vars.queue_list then
		vars.queue_list = {}
		vars.queue_last = 0
	end
	vars.queue_last = vars.queue_last + 1
	vars.queue_list[vars.queue_last] = config
	self:deferredCallback_(config[1].delay or 0, "playQueue", vars.queue_last, 1)
end

--loops on itself until all steps are done
function Builder:playQueue(id, step)
	local vars = self.vars
	local tabl = vars.queue_list[id]
	local entry = tabl[step]
	vars.functions[entry.function_](id, step)
	local next_entry = tabl[step + 1]
	if next_entry then
		self:deferredCallback_(next_entry.delay or 0, "playQueue", id, step + 1)
	else
		vars.queue_list[id] = nil
		if not next(vars.queue_list) then
			vars.queue_last = 0
		end
	end
end

function Builder:playTrack(path, loop, volume, fadeout, save)
	local vars = self.vars
	if vars.sound_manager.music then
		if loop == nil then
			loop = true
		end
		volume = volume or 1
		if volume == "config_volume" then
			volume = vars.config.music.volume
		end
		local user_volume = user_config.music_volume/100
		vars.sound_manager.music.autoPlay = false
		vars.sound_manager.music:fadeOut(fadeout or 0.2)		

		if user_volume < volume then
			vars.sound_manager.music:playTrack(path, loop, user_volume)
		else
			vars.sound_manager.music:playTrack(path, loop, volume)
		end	
		if save then
			vars.music_path = path
			self.data.music_path = path
			self:sync("music_path", path)
		end
	end
end

function Builder:setBackgroundOverlay(path, fade_time)
	local vars = self.vars
	if not vars.hud.background_overlay_picture then
		local window = self:createLayer(999)
		local picture = window:createPicture(Rect(getResolution()), "data/textures/uiLib/transparent.png")
		picture.position = vec2(0, 0)
		vars.hud.background_overlay_picture = picture
		self:showLayers()	
	end
	if not path then print("UI lib Error: no path for setBackgroundOverlay") return end
	if fade_time then
		vars.hud.background_overlay_picture:fadeTo(path, fade_time)
	else
		vars.hud.background_overlay_picture.picture = path
	end
end

function Builder:toggleHud(show)
	local vars = self.vars
	if show and vars.hud_is_hidden == true then
		for i, position in pairs(vars.layers_positions_old) do
			vars.layers[i].position = position
		end
		vars.layers_positions_old = nil
		vars.hud_is_hidden = false
	elseif not show and vars.hud_is_hidden == false then
		vars.layers_positions_old = {}
		local new_pos = getResolution()*2
		for i, window in pairs(vars.layers) do
			if i ~= 1000 and i ~= 999 then
				vars.layers_positions_old[i] = window.position
				window.position = new_pos
			end
		end
		vars.hud_is_hidden = true		
	end
end

function Builder:fadeEffect(a, b, type_, toggle_hud)
	local vars = self.vars
	if not vars.overlay_is_fading then
		vars.overlay_is_fading = true
		self:fadeEffectDo(1, a, b, type_, toggle_hud)
	end
end

function Builder:fadeEffectDo(step, a, b, type_, toggle_hud)
	if step == 1 then
		if toggle_hud then
			self:toggleHud(false)
		end
		if type_ == "fade_in" then
			self:setBackgroundOverlay("data/textures/uiLib/transparent.png")
			self:setBackgroundOverlay("data/textures/icons/nothing.png", a)
			self:deferredCallback_(a + 0.1, "fadeEffectDo", 2, a, b, type_, toggle_hud)
		else
			self:setBackgroundOverlay("data/textures/icons/nothing.png", a)
			self:setBackgroundOverlay("data/textures/uiLib/transparent.png")
			self:deferredCallback_(a + 0.1, "fadeEffectDo", 2, a, b, type_, toggle_hud)			
		end
	elseif step == 2 then
		if type_ == "fade_in" then
			if b then
				self:setBackgroundOverlay("data/textures/uiLib/transparent.png", b)
				self:deferredCallback_(b + 0.1, "fadeEffectDo", 3, nil, nil, nil, toggle_hud)
			else
				self.vars.overlay_is_fading = false
				if toggle_hud then
					self:toggleHud(true)
				end	
			end
		else
			if b then
				self:setBackgroundOverlay("data/textures/icons/nothing.png", b)
				self:deferredCallback_(b + 0.1, "fadeEffectDo", 3, nil, nil, nil, toggle_hud)
			else
				self.vars.overlay_is_fading = false
				if toggle_hud then
					self:toggleHud(true)
				end		
			end	
		end
	else
		self.vars.overlay_is_fading = false
		if toggle_hud then
			self:toggleHud(true)
		end	
	end
end

function Builder:refreshPlayerStats()
	local player = Player()
	player_stats.player = player
	local craft = player.craft
	if craft then
		if craft.isDrone then
			player_stats.is_drone = true
		end
		
		player_stats.max_cargo = craft.maxCargoSpace or 0
		player_stats.craft = craft
		player_stats.is_docked = craft:isInDockingArea(entity)
		player_stats.other_docked = entity:isInDockingArea(craft)
		--player_stats.crew_num = craft.crewSize
		player_stats.captain = craft:getCaptain()
		
		local faction = Faction(craft.factionIndex)		
		if faction.isPlayer then
			player_stats.faction = player
		else
			player_stats.faction = player.alliance
		end
	end
end

--/////Dialogs
--todo add delay for sync data
--todo make a new table for this to preserve the original (as a separate optional function)
function Builder:constructDialog(lines_, config)
	local vars = self.vars
	vars.dialog = {}
	local dialog = vars.dialog
	config = config or {}
	dialog.lines = lines_
	--to be able to backtrack choices and branches
	dialog.path = {}
	dialog.wait_sync = config.wait_sync or false
	dialog.first = config.first or 1
	table.insert(dialog.path, 1, dialog.first)
	dialog.names = {}
	dialog.changes = config.changes or {}
	config.default_flags = config.default_flags or {}
	
	for flag, value in pairs(config.default_flags) do
		for i, node in pairs(lines_) do
			node[flag] = value
		end
	end
	
	for i, node in pairs(lines_) do
		dialog.names[node.name] = i
		node.id = i
		--todo check, looks suspicious, dont remember why its here
		if config.disable_leave then
			node.disable_leave = true
		end
	end
	if config.responses then 
		for name, responses in pairs(config.responses) do
			local node_id = dialog.names[name]
			dialog.lines[node_id].responses = responses
		end
	end
	if config.unlocks then 
		for name, unlocks in pairs(config.unlocks) do
			local node_id = dialog.names[name]
			dialog.lines[node_id].unlocks = unlocks
		end
	end
	if config.flags then
		for flagName, tabl in pairs(config.flags) do		
			for _, name in pairs(tabl.list) do
				local node_id = dialog.names[name]
				dialog.lines[node_id][flagName] = tabl.value
			end
		end
	end
	local func = vars.dialog.lines[dialog.first].func
	if func then
		local changes_1, changes_2 = vars.functions[func](self, vars.dialog.lines[dialog.first].name, nil)
		if changes_1 then
			local name = vars.dialog.lines[dialog.first].name
			local node = vars.dialog.changes[name]
			if node then
				if type(changes_1) == "table" then
					for _, value in pairs(changes_1) do
						if node[value] then
							for node_name, tabl in pairs(node[value]) do
								for flag, value in pairs(tabl) do
									local id = vars.dialog.names[node_name]
									vars.dialog.lines[id][flag] = value	
								end
							end
						end
					end
				else			
					if node[changes_1] then
						for node_name, tabl in pairs(node[changes_1]) do
							for flag, value in pairs(tabl) do
								local id = vars.dialog.names[node_name]
								vars.dialog.lines[id][flag] = value	
							end
						end
					end
				end
			end
		end	
		if changes_2 then
			for node_name, tabl in pairs(changes_2) do
				for flag, value in pairs(tabl) do
					local id = vars.dialog.names[node_name]
					vars.dialog.lines[id][flag] = value
				end				
			end
		end
	end
	self:fillDialog(dialog.first)
end

--todo replace with showDialog
--todo replace naming: dialog -> lines
--todo add back_text as player text
function Builder:fillDialog(i, state)
	local vars = self.vars
	vars.dialog.current = i
	local dialog = vars.dialog.lines
	local pl = vars.hud.player_text
	local npc = vars.hud.npc_text
	pl:clear()
	local node = dialog[i]

	--todo save previous
	--todo overwrite other places that show portrait
	if node.hide_portrait then
		vars.hud.npc_portrait.picture = "data/textures/uiLib/static_small.png"
	else
		--todo add source
		--fixbug: cannot replace picture if portrait is currently fading
		if vars.npc_captain then
			if node.fade_portrait then
				--vars.hud.npc_portrait:fadeTo(self.data.captain_portrait.path, 1)
				vars.hud.npc_portrait:fadeTo(vars.npc_captain, 1)
			else
				--vars.hud.npc_portrait.picture = self.data.captain_portrait.path
				vars.hud.npc_portrait.picture = vars.npc_captain
			end
		end
	end
	
	if node.pl_text == nil then
		node.pl_text = "-"
	end
	if node.npc_text == nil then
		node.npc_text = "-"
	end
	node.was_read = true
	if node.unlocks then
		for _, name in pairs(node.unlocks) do
			local id = vars.dialog.names[name]
			dialog[id].unlocked = true
		end
	end
	if node.show_back == nil then
		node.show_back = false
	end
	
	local temp = node.npc_text 	
	local from = vars.dialog.from
	if state == "back" then
		if from ~= nil then
			if dialog[from].text_back ~= nil then
				temp = dialog[from].text_back
			end
		end
	elseif node.temp_npc_text then
		temp = node.temp_npc_text
		node.temp_npc_text = nil
	end
	--todo add possibility to influence randomness of npc text
	if type(temp) == "table" then
		npc.text = temp[math.random(1, #temp)]
	else
		npc.text = temp
	end
	
	if node.npc_inner then
		npc.text = "* " .. npc.text .. " *"
		npc.fontColor = ColorRGB(1, 1, 0.6)
	else
		npc.fontColor = ColorRGB(1, 1, 1)
	end
	
	local noResp = true
	--scan possible responses to check if they have already been read to make it visbile to the player
	if node.responses then
		local read_list = {}
		for _, name in pairs(node.responses) do
			local id = vars.dialog.names[name]
			local response = dialog[id]
			local conflict = false
			if response.conflicts then
				if next(response.conflicts) then
					for _, opponent in pairs(response.conflicts) do
						if dialog[opponent].was_read then
							conflict = true
							--print("true conflict", i, opponent)
						end
					end
				end
			end
			if not conflict and (not response.locked or response.unlocked) then
				if (not response.was_read) or (response.ignore_read) then
					if response.pl_text == nil then
						response.pl_text = "-"
					end
					pl:addEntry(response.pl_text, id)					
					noResp = false
					local tabl = {}
					tabl.pl_inner = response.pl_inner
					tabl.pl_text = response.pl_text
					--insert every line to keep ipairs order
					if response.was_read then
						tabl.was_read = true
						table.insert(read_list, tabl)
					else
						tabl.was_read = false
						table.insert(read_list, tabl)
					end
				end
			end
		end
		if next(read_list) then
			for i, tabl in ipairs(read_list) do
				--make inner player lines yellow and * * to separate from usual "voiced" lines
				if tabl.pl_inner then	
					tabl.pl_text = "* " .. tabl.pl_text .. " *"
				end

				if tabl.was_read == true then
					pl:setEntry(i - 1, tabl.pl_text, false, false, ColorRGB(0.6, 0.6, 0.6))
				elseif tabl.pl_inner then
					pl:setEntry(i - 1, tabl.pl_text, false, false, ColorRGB(1, 1, 0.6))
				end
			end
		end
	else
		noResp = true
	end

	if node.show_back then
		if vars.dialog.path[2] then
			for k, n in ipairs(vars.dialog.path) do
				if n ~= i and dialog[n].return_here then
					pl:addEntry("", "back")
					pl:setEntry(pl.rows - 1, "* " .. "Back "%_t .. "*", false, false, ColorRGB(1, 1, 0.6))
					vars.dialog.back = k
					break
				end
			end		
		end
	end
	if node.add_leave or (not node.disable_leave and noResp) then
		pl:addEntry("", "close")
		pl:setEntry(pl.rows - 1, "* " .. "Leave "%_t .. "*", false, false, ColorRGB(1, 1, 0.6))
	end
end

--not added right now
function Builder:syncReadDialog(data_in, data_in_2)
	if onClient() then
		if data_in then
			if vars.dialog then								
				for _, nodeName in pairs(data_in) do
					local node_id = vars.dialog.names[nodeName]
					vars.dialog.lines[node_id].was_read = true
				end
				
				if data_in_2 then
					for nodeName, flag_list in pairs(data_in_2) do
						for flag, value in pairs(flag_list) do
							local node = vars.dialog.lines[vars.dialog.names[nodeName]]
							node[flag] = value
						end		
					end
				end
				
				if vars.dialog.wait_sync then
					Builder.fillDialog(vars.dialog.first)
				end
			end
			client_restored = true
			Builder.toggleUI()
		else
			Builder.invokeFunction("S", "syncReadDialog")
		end		
	else
		--local player = Player(callingPlayer)
		--if not player then return end
		local tabl = self.data.read_list or {}
		Builder.invokeFunction("C", "syncReadDialog", tabl, self.data.saved_dialog)
	end
end

--todo expand jump and changes, some places are missing them
--todo shorten vars.dialog.lines to lines_
function Builder:onDialogClick(index)
	if index == -1 then return end	
	if os.clock() < dialog_CD then return end
	local vars = self.vars
	if not vars.window.visible then return end
	dialog_CD = os.clock() + 0.3
	local selected = vars.hud.player_text.selectedValue
	--without this its hard for player to notice if click was successfull
	self:blinkDialog()
	if selected == "close" then 
		--self:onCloseWindow()
		self:onBackButton()
	elseif selected == "back" then
		--dialog path is like 1, 2, 3, back_here, 4, 5. If cliciked on 'back', the 1, 2, 3 will be deleted from path as latest picked lines, 4 and 5 are oldest, when dialog started. So several 'back' options can be clicked in row and return player higher and higher to the start of the dialog
		local tabl = {}
		for i = vars.dialog.back, #vars.dialog.path do 
			table.insert(tabl, vars.dialog.path[i])
		end
		vars.dialog.path = tabl
		local func = vars.dialog.lines[vars.dialog.path[1]].back_function
		local from = vars.dialog.current
		vars.dialog.from = from
		--todo add shared_functions
		if func then
			local node_ = vars.dialog.lines[vars.dialog.path[1]]
			local changes_1, changes_2 = vars.functions[func](node_.name, vars.dialog.lines[from].name, "back")
			if changes_1 then
				local name = node_.name
				local node = vars.dialog.changes[name]
				if node then
					if type(changes_1) == "table" then
						for _, value in pairs(changes_1) do
							if node[value] then
								for node_name, tabl in pairs(node[value]) do
									for flag, value in pairs(tabl) do
										local id = vars.dialog.names[node_name]
										vars.dialog.lines[id][flag] = value	
									end
								end
							end
						end
					else			
						if node[changes_1] then
							for node_name, tabl in pairs(node[changes_1]) do
								for flag, value in pairs(tabl) do
									local id = vars.dialog.names[node_name]
									vars.dialog.lines[id][flag] = value	
								end
							end
						end
					end
				end
			end						
			if changes_2 then
				for node_name, tabl in pairs(changes_2) do
					for flag, value in pairs(tabl) do
						local id = vars.dialog.names[node_name]
						vars.dialog.lines[id][flag] = value
					end				
				end
			end
		end
		
		--prevent filling dialog when alredy jumped to some other line
		if vars.dialog_jump then
			local id = vars.dialog.names[vars.dialog_jump.node_name]
			vars.dialog.path = {}
			for _, node_name_ in ipairs(vars.dialog_jump.path) do
				table.insert(vars.dialog.path, 1, vars.dialog.names[node_name_])
			end
			table.insert(vars.dialog.path, 1, id)
			self:fillDialog(id)
			vars.dialog_jump = nil
			return
		end
		
		self:fillDialog(vars.dialog.path[1], "back")
		local func = vars.dialog.lines[vars.dialog.path[1]].post_back_function
		--todo add dialog jump here as well
		if func then
			local node_ = vars.dialog.lines[vars.dialog.path[1]]
			local changes_1, changes_2 = vars.functions[func](node_.name, vars.dialog.lines[from].name, "back")
			if changes_1 then
				local name = node_.name
				local node = vars.dialog.changes[name]
				if node then
					if type(changes_1) == "table" then
						for _, value in pairs(changes_1) do
							if node[value] then
								for node_name, tabl in pairs(node[value]) do
									for flag, value in pairs(tabl) do
										local id = vars.dialog.names[node_name]
										vars.dialog.lines[id][flag] = value	
									end
								end
							end
						end
					else			
						if node[changes_1] then
							for node_name, tabl in pairs(node[changes_1]) do
								for flag, value in pairs(tabl) do
									local id = vars.dialog.names[node_name]
									vars.dialog.lines[id][flag] = value	
								end
							end
						end
					end
				end
			end	
			if changes_2 then
				for node_name, tabl in pairs(changes_2) do
					for flag, value in pairs(tabl) do
						local id = vars.dialog.names[node_name]
						vars.dialog.lines[id][flag] = value
					end				
				end
			end
		end		
	else
		--todo fix names to make more readable
		local node_ = vars.dialog.lines[selected]
		local func = node_.func
		local from = vars.dialog.current
		--prevent immediate dialog filling on click
		--client check -> server check -> 'func', if all steps returned true
		--client check -> 'func' if check is true and there is no server check
		--if cant pass check, dialog is stuck at same node
		--todo add changes and arg passing
		local condition_check_client = node_.condition_check_client
		local condition_check_server = node_.condition_check_server 
		if condition_check_client and condition_check_client.function_ then
			local go_next = {vars.functions[condition_check_client.function_](node_.name, vars.dialog.lines[from].name)}
			if go_next[1] then
				if condition_check_server and condition_check_server.function_ then
					table.remove(go_next, 1)
					vars.disable_dialog_blink = true
					vars.hud.npc_text:hide()
					vars.hud.player_text:hide()
					self:serverDialogClick(condition_check_server.function_, node_.func, node_.name, vars.dialog.lines[from].name, nil, go_next)
					--test
					--self:deferredCallback_(1, "serverDialogClick", condition_check_server.function_, node_.func, node_.name, vars.dialog.lines[from].name, nil, go_next)
					return
				end
			else
				local npc = vars.hud.npc_text
				if condition_check_client.temp_npc_text then
					npc.text = condition_check_client.temp_npc_text
				end
				if condition_check_client.npc_inner then
					npc.text = "* " .. npc.text .. " *"
					npc.fontColor = ColorRGB(1, 1, 0.6)
				else
					npc.fontColor = ColorRGB(1, 1, 1)
				end
				return
			end
		elseif condition_check_server and condition_check_server.function_ then
			vars.disable_dialog_blink = true
			vars.hud.npc_text:hide()
			vars.hud.player_text:hide()
			self:serverDialogClick(condition_check_server.function_, node_.func, node_.name, vars.dialog.lines[from].name)
			--test
			--self:deferredCallback_(1, "serverDialogClick", condition_check_server.function_, node_.func, node_.name, vars.dialog.lines[from].name)
			return
		else
			--table.insert(vars.dialog.path, 1, selected)
		end
		
		table.insert(vars.dialog.path, 1, selected)
		--saves read lines on disk
		if not node_.ignore_read then
			self:syncReadDialogLine(node_.name)
		end
		
		if func then
			self:triggerDialogChanges(func, node_, vars.dialog.lines[from].name)
		end
		
		--prevent filling dialog when alredy jumped to some other line
		if vars.dialog_jump then
			local id = vars.dialog.names[vars.dialog_jump.node_name]
			vars.dialog.path = {}
			for _, node_name_ in ipairs(vars.dialog_jump.path) do
				table.insert(vars.dialog.path, 1, vars.dialog.names[node_name_])
			end
			table.insert(vars.dialog.path, 1, id)
			self:fillDialog(id)
			vars.dialog_jump = nil
			return
		end
		
		self:fillDialog(selected)
		local func = vars.dialog.lines[selected].post_func
		if func then
			self:triggerDialogChanges(func, node_, vars.dialog.lines[from].name)
		end
	end	
end

--triggers after client onDialogClick conditions was met, the 2nd step
function Builder:serverDialogClick(server_function_name, client_function_name, line, from, state, args)
	if onClient() then
		self:invokeServerFunction_("serverDialogClick", server_function_name, client_function_name, line, from, state, args)
	else
		args = args or {}
		local go_next = {self.vars.functions[server_function_name](line, from, state, table.unpack(args))}
		self:clientDialogClick(client_function_name, line, from, state, go_next)
	end
end
--callable

--todo add on check fail functions
--triggers after serverDialogClick conditions was met, the last, 3th step
function Builder:clientDialogClick(function_name, line, from, state, args)
	if onServer() then
		local player = Player(callingPlayer)
		if not player then return end
		self:invokeClientFunction_(player, "clientDialogClick", function_name, line, from, state, args)
		
		return
	end
	
	args = args or {}
	local vars = self.vars
	local node_id = vars.dialog.names[line]
	local node = vars.dialog.lines[node_id]
	vars.hud.npc_text:show()
	vars.hud.player_text:show()
	vars.disable_dialog_blink = nil
	
	--not successfull serverDialogClick check, show according npc text on fail
	if not args[1] then
		local text = node.condition_check_server.temp_npc_text
		if text then
			vars.hud.npc_text.text = text
		end
		return 
	end
	table.remove(args, 1)
	table.insert(vars.dialog.path, 1, node_id)
	
	if not function_name then
		--todo reconsider using jump in this conditions
		self:fillDialog(node_id)
		return
	end
	
	self:triggerDialogChanges(function_name, node, from, state, args)
	
	--prevent filling dialog when alredy jumped to some other line
	if vars.dialog_jump then
		local id = vars.dialog.names[vars.dialog_jump.node_name]
		vars.dialog.path = {}
		for _, node_name_ in ipairs(vars.dialog_jump.path) do
			table.insert(vars.dialog.path, 1, vars.dialog.names[node_name_])
		end
		table.insert(vars.dialog.path, 1, id)
		self:fillDialog(id)
		vars.dialog_jump = nil
		return
	end
	self:fillDialog(node_id)
	--todo add post func
end
--callable

function Builder:triggerDialogChanges(function_name, node, previous_node_name, state, args)
	args = args or {}
	local vars = self.vars
	local node_name = node.name
	local changes_1, changes_2 = vars.functions[function_name](node_name, previous_node_name, state, table.unpack(args))
	if changes_1 then	
		local node_ = vars.dialog.changes[node_name]
		if node_ then
			if type(changes_1) == "table" then
				for _, value in ipairs(changes_1) do
					if node_[value] then
						for node_name_, tabl in pairs(node_[value]) do
							for flag, value in pairs(tabl) do
								local id = vars.dialog.names[node_name_]
								vars.dialog.lines[id][flag] = value	
							end
						end
					end
				end
			else			
				if node_[changes_1] then
					for node_name_, tabl in pairs(node_[changes_1]) do
						for flag, value in pairs(tabl) do
							local id = vars.dialog.names[node_name_]
							vars.dialog.lines[id][flag] = value	
						end
					end
				end
			end
		end
	end	
	if changes_2 then
		for node_name_, tabl in pairs(changes_2) do
			for flag, value in pairs(tabl) do
				local id = vars.dialog.names[node_name_]
				vars.dialog.lines[id][flag] = value
			end				
		end
	end
end

function Builder:jumpToDialogLine(node_name, path)
	local vars = self.vars
	vars.dialog_jump = {node_name = node_name, path = path or {}}
end

--triggers every time the dialog is successfully clicked. Potential optimisation
function Builder:syncReadDialogLine(node_name)
	if onClient() then
		self:invokeServerFunction_("syncReadDialogLine", node_name)
		return
	end
	
	local entry = self.data.dialog[node_name] or {}
	entry.was_read = true
	self.data.dialog[node_name] = entry
	
	Entity():invokeFunction("data/scripts/uiLib/securer.lua", "receiveData", self.id, self.data)
	--print("save line", node_name)
end

function Builder:saveDialog(tabl)
	if not vars.dialog then print("Can not save dialog: no active dialog") return end
	local to_save = {}
	for nodeName, flag_list in pairs(tabl) do
		to_save[nodeName] = {}
		for _, flag in pairs(flag_list) do
			local node = vars.dialog.lines[vars.dialog.names[nodeName]]
			to_save[nodeName][flag] = node[flag]
		end		
	end
	Builder.invokeFunction("S", "syncSaveDialog", to_save)
end

function Builder:blinkDialog(second_invoke)
	local vars = self.vars
	if vars.disable_dialog_blink then return end
	if not second_invoke then
		vars.hud.npc_text:hide()
		vars.hud.player_text:hide()	
		self:deferredCallback_(0.15, "blinkDialog", true)
		
		return
	end
	
	vars.hud.npc_text:show()
	vars.hud.player_text:show()		
end

function Builder:testSecure(property, value)
	if onClient() then
		self:invokeServerFunction_("testSecure", property, value)
		return
	end
	local entity = entity
	if not valid(entity) then return end
	--entity:sendCallback("UILib_secure", property, value)
	local _, a = entity:invokeFunction("data/scripts/uiLib/securer.lua", "testFu", "babaduy")
	print(a)
	--entity:sendCallback("UILib_restore", self)
end
--callable

function Builder:testInstance(input)
	print("I am a new instance", input)
end

function Builder:testCallable(input)
	print("I am a callable", input)
	if onServer() then 
		self:invokeClientFunction_(Player().index, "testCallable", input)
	end
end
--callable

PublicNamespace.CreateUIBuilder = setmetatable({new = new}, {__call = function(_, ...) return new(...) end})

function PublicNamespace.CreateNamespace()
    local result = {}
	--instance == new instance, because uiBuilder initializes only once per station, but there are several windows that needs to be modified. Crewboard, bulletinboard, etc., all of them must be separated in order to save custom values and properly auto hook functions
    --todo remove internal functions from here
	local instance = PublicNamespace.CreateUIBuilder()
    result.instance = instance
	result.testInstance = function(...) return instance:testInstance(...) end
	result.hook = function(...) return instance:hook(...) end
	result.initUI = function(...) return instance:initUI(...) end
	
	result.playVoice = function(...) return instance:playVoice(...) end
	
	result.showLayers = function(...) return instance:showLayers(...) end
	result.showPortraits = function(...) return instance:showPortraits(...) end
	result.fakeCaptain = function(...) return instance:fakeCaptain(...) end
	result.generateFakeCaptain = function(...) return instance:generateFakeCaptain(...) end
	result.fadePortrait = function(...) return instance:fadePortrait(...) end
	
	--result.secure = function(...) return instance:secure(...) end
	--result.restore = function(...) return instance:restore(...) end

	result.sync = function(...) return instance:sync(...) end
	result.syncClient = function(...) return instance:syncClient(...) end
	result.syncVar = function(...) return instance:syncVar(...) end
	result.syncVarClient = function(...) return instance:syncVarClient(...) end

		
	result.constructDialog = function(...) return instance:constructDialog(...) end

	result.testCallable = function(...) return instance:testCallable(...) end
	result.testInstance = function(...) return instance:testInstance(...) end
	result.test = function(...) return instance:test(...) end
	result.testSecure = function(...) return instance:testSecure(...) end

    return result
end

return PublicNamespace
