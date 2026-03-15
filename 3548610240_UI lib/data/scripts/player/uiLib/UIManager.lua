package.path = package.path .. ";data/scripts/uiLib/?.lua"
package.path = package.path .. ";data/scripts/lib/?.lua"
include("callable")
include("config_manager")
local vi_lines = include("vi_lines")
-- namespace UIManager
UIManager = {}
local self = UIManager
local queue = {}
local frequency_list = {}
local config_callbacks = {}
local next_sound
local last_sound
local sound_end_time = 0
local vi
local vars = {}
self.data = {}
--local client_clock = 0

--todo**1 add other targets

function UIManager.sendUserConfig(config_id)
	return ConfigManager_sendUserConfig(config_id)
end

function UIManager.setUserConfig(config_id, data_in)
	ConfigManager_setUserConfig(config_id, data_in)
	local copy = ConfigManager_copyTable(data_in)
	local callback = config_callbacks[config_id]
	if config_id == "u3548610240" then
		vars.config = copy
	end
	if callback then
		--todo**1 add other targets
		if callback.target == "player" then
			if callback.target_id then
				local player = Player(target_id)
				if player then
					player:invokeFunction(callback.script_path, callback.function_name, copy)
				end
			else			
				Player():invokeFunction(callback.script_path, callback.function_name, copy)
			end
		end
		
		return		
	end
end

function UIManager.sendDefaultConfig(config_id)
	return ConfigManager_sendDefaultConfig(config_id)
end

function UIManager.addConfigCallback(config_id, target, target_id, script_path, function_name)
	config_callbacks[config_id] = {target = target, target_id = target_id, script_path = script_path, function_name = function_name}
end

function UIManager.initialize()
	if onClient() then
		vars.config = ConfigManager_sendUserConfig("u3548610240") or {}
		vars.sector_relations = {}
		vars.keyboard_timeout = 0
		vi = vi_lines[1]
		if not vi then return end
		UIManager.fillVIdata()
		if vi.announcement.save_loaded then
			local player = Player()
			player:registerCallback("onConfirmSectorArrival", "onConfirmSectorArrival")		
			player:registerCallback("onMailAdded", "onMailAdded")		
			player:registerCallback("onShipChanged", "onShipChanged")
			player:registerCallback("onStateChanged", "onStateChanged")
			player:registerCallback("onRelationStatusChanged", "onRelationStatusChanged")
			player:registerCallback("onRelationLevelChanged", "onRelationLevelChanged")
			local entity = Player().craft
			if valid(entity) then
				UIManager.registerEntityCallbacksClient(entity.id)
				invokeServerFunction("registerEntityCallbacks", entity.id)
				invokeServerFunction("registerServerCallbacks")
				local system = ShipSystem(entity.id)
				if system then
					vars.ship_systems = system.numUpgrades
				end
			end
		end
	end
end

function UIManager.registerServerCallbacks()
	local player = Player()
	player:registerCallback("onMaxBuildableMaterialChanged", "onMaxBuildableMaterialChanged")
end
callable(UIManager, "registerServerCallbacks")

function UIManager.fillVIdata()
	vi.announcement = vi.announcement or {}
	vi.error = vi.error or {}
	vi.warning = vi.warning or {}
end

function UIManager.addVIline(path, name, frequency, source)
	if onServer() then
		invokeClientFunction(Player(), "addVIline", path, name, frequency, source)
		
		return
	end
	
	if not vi then return end
	local duration = vi[path][name]
	if not duration then print("UILIB Error: can not add VI line - missing duration") end
	frequency = frequency or 0
	source = source or 1
	local volume = vars.config.VI_volume/100 or 1
	local id = 1
	UIManager.addVoiceEntry("uiLib/VI/" .. "1/" .. path .. "/" .. name, duration, SoundType.Other, volume, id, frequency, source)
end

--technically silence .wav is not needed, but its more convenient to use default functions for silence
function UIManager.addVIsilence(duration)
	if not vi then return end
	duration = duration or 1
	local id = 1
	UIManager.addVoiceEntry("uiLib/silence", duration, SoundType.Other, 0, id, 0, "silence")
end

--[[
function UIManager.updateFactionInfo()
	local craft = Player().craft
	if not craft then
		vars.sector_relations = {}
		vars.faction = Player()
		return
	end
	print(craft)
	local faction = Faction(craft.factionIndex)
	vars.faction = faction
	local factions = {Sector():getPresentFactions()}
	vars.sector_relations = {}
	for _, faction_index in pairs(factions) do
		vars.sector_relations[faction_index] = faction:getRelationStatus(faction_index)	
	end
end
--]]
------------callbacks Client-------------
------------Player

function UIManager.onRelationStatusChanged(index, status, status_before)
	if status == status_before then return end
	--print(status_before)
	UIManager.addVIline("announcement", "changed_relations", 1, "relations_1")
	UIManager.addVIsilence(0.15)
	if status == RelationStatus.War then
		UIManager.addVIline("misc", "war", 0, "relations_2")
	elseif status == RelationStatus.Ceasefire then
		UIManager.addVIline("misc", "ceasefire", 0, "relations_2")
	elseif status == RelationStatus.Neutral then
		UIManager.addVIline("misc", "neutral", 0, "relations_2")
	elseif status == RelationStatus.Allies then
		UIManager.addVIline("misc", "ally", 0, "relations_2")
	end
end

function UIManager.getRelationLevel(level)
	if level >= 80000 then
		return 5
	elseif level >= 30000 then
		return 4
	elseif level >= -30000 then
		return 3
	elseif level >= -80000 then
		return 2
	else
		return 1	
	end
end

function UIManager.onRelationLevelChanged(index, level, level_before)
	local level_ = UIManager.getRelationLevel(level)
	local level_before_ = UIManager.getRelationLevel(level_before)
	if level_ == level_before_ then return end
	--print(level, level_, level_before_)
	UIManager.addVIline("announcement", "changed_relations_level", 1, "relations_l_1")
	UIManager.addVIsilence(0.15)
	if level_ == 5 then
		UIManager.addVIline("misc", "excellent", 1, "relations_l_2")
	elseif level_ == 4 then
		UIManager.addVIline("misc", "good", 1, "relations_l_2")
	elseif level_ == 3 then
		UIManager.addVIline("misc", "neutral", 1, "relations_l_2")
	elseif level_ == 2 then
		UIManager.addVIline("misc", "bad", 1, "relations_l_2")
	else
		UIManager.addVIline("misc", "hostile", 1, "relations_l_2")	
	end
end

function UIManager.onMailAdded()
	UIManager.addVIline("announcement", "got_mail", 5, "mail")
end

function UIManager.onConfirmSectorArrival()
	if not vars.login_callback then
		UIManager.onLogIn()
	end
	local sector = Sector()
	--sector:registerCallback("onShotFired", "onShotFired")
	sector:registerCallback("onDestroyed", "onEntityDestroyed")
	local craft = Player().craft
	if not craft then return end
	--UIManager.updateFactionInfo()
	local ship_ai = ShipAI(craft.index)
	if not ship_ai then return end
	if ship_ai:enemyShipsPresent(true) then
		UIManager.addVIline("warning", "hostile_ships", 0, "threat_1")
		UIManager.addVIsilence(0.15)
		UIManager.addVIline("warning", "threat_level", 0, "threat_2")
		UIManager.addVIsilence(0.15)
		local enemy_list = {ship_ai:getEnemyShips()}
		local threat = 0
		for _, enemy in pairs(enemy_list) do
			threat = threat + enemy.firePower
		end
		local strength = craft.firePower
		local strength_diff = strength - threat
		if strength_diff > 0 then
			if strength/threat > 1.25 then
				UIManager.addVIline("misc", "low", 0, "threat_3")
			else
				UIManager.addVIline("misc", "medium", 0, "threat_3")
			end
		else
			local div = threat/strength
			if div > 1.25 then
				if div < 2 then
					UIManager.addVIline("misc", "high", 0, "threat_3")	
				else
					UIManager.addVIline("misc", "extremely_high", 0, "threat_3")
				end
			else
				UIManager.addVIline("misc", "medium", 0, "threat_3")
			end			
		end
	end
	--Player():unregisterCallback("onConfirmSectorArrival", "onConfirmSectorArrival")		
end

function UIManager.onShipChanged(player_index, new_id, old_id)
	local system = ShipSystem(Entity(new_id).index)
	if system then
		vars.ship_systems = system.numUpgrades
	end
	--UIManager.updateFactionInfo()
	
	UIManager.registerEntityCallbacksClient(new_id, old_id)
	invokeServerFunction("registerEntityCallbacks", new_id, old_id)
end

function UIManager.onStateChanged(newState, oldState)
	if oldState == PlayerStateType.BuildCraft and newState == PlayerStateType.Fly then
		if vars.ship_plan_changed then
			vars.ship_plan_changed = nil
			UIManager.addVIline("announcement", "buildmode_change", 5, "buildmode")
		end
	end
end

------------Ship

function UIManager.onShieldDeactivate()
	UIManager.addVIline("warning", "shields_lost", 5, "shields")
end

------------Sector

function UIManager.onEntityDestroyed(index)
	local entity = Entity(index)
	if not entity or not entity.isShip then return end
	local player_craft = Player().craft
	if not player_craft then return end
	
	if entity.factionIndex == player_craft.factionIndex then
		UIManager.addVIline("warning", "ship_lost", 1, "ship_destroyed")
	else
		local ship_ai = ShipAI(player_craft.index)
		if ship_ai:isEnemy(entity) then
			local enemy_list = {ship_ai:getEnemyShips()}
			if #enemy_list == 1 then 
				UIManager.addVIline("announcement", "enemy_defeated", 1, "enemy_defeated")	
			end
		end
	end
end

------------callbacks Server-------------
------------Player

function UIManager.onMaxBuildableMaterialChanged()
	UIManager.addVIline("announcement", "new_material", 1, "material")
end
------------Ship

function UIManager.onJumpRouteCalculationStarted()
	local player = Player()
	if not player then return end
	invokeClientFunction(player, "addVIline", "announcement", "calculating_jump", 60, "jump_prepare")
end

function UIManager.onSystemsChanged()
	local player = Player()
	if not player then return end
	local craft = player.craft
	if not valid(craft) then return end
	local system = ShipSystem(craft.index)
	if system then
		invokeClientFunction(player, "onSystemsChangedClient", system.numUpgrades)
	end
end

function UIManager.onPlanModifiedByBuilding()
	vars.ship_plan_changed = true
end

function UIManager.onCaptainChanged(index, captain)
	local entity = Entity(index)
	if not valid(entity) then return end
	if not captain then
		entity:setCaptain(UIManager.createVIcaptain())
	end
end

function UIManager.onPassengerAdded(index, passenger)
	local entity = Entity(index)
	if not valid(entity) then return end
	if passenger.name == "VI" then
		local crew = entity.crew
		local passengers = {crew:getPassengers()}
		for passenger_index, captain in pairs(passengers) do
			if captain.name == "VI" then
				crew:removePassenger(passenger_index - 1)				
			end
		end
		entity.crew = crew
	end
end

------------Callbacks 2 step
--todo redo state check, add new system slot available line
function UIManager.onSystemsChangedClient(ship_systems)
	if Player().state == PlayerStateType.BuildCraft then return end
	if vars.ship_systems then
		if vars.ship_systems < ship_systems then
			UIManager.addVIline("announcement", "system_add", 10, "s_subsystems")
		else
			UIManager.addVIline("announcement", "system_remove", 10, "r_subsystems")
		end
		vars.ship_systems = ship_systems
	end
end

function UIManager.onLogIn(playtime, old_save)
	if onClient() then
		vars.login_callback = true
		if not playtime then
			invokeServerFunction("onLogIn")
		else
			--playtime is a precaution, if secure-restore somehow gets broken
			if not old_save and playtime/60 < 10 then
				UIManager.addVIline("announcement", "fresh_save")
			else
				UIManager.addVIline("announcement", "save_loaded")	
			end
		end
		return
	end
	local player = Player()
	if not player then return end
	invokeClientFunction(player, "onLogIn", player.playtime, self.data.old_save)
	self.data.old_save = true 
end
callable(UIManager, "onLogIn")

------------Functions

function UIManager.createVIcaptain()
	local captain = Captain()
	captain.name = "VI"
	captain.genderId = CaptainGenderId.Female
	captain.tier = 0
	captain.primaryClass = 0
	captain.secondaryClass = 0
	captain.level = 0
	captain.experience = 0
	captain.requiredLevelUpExperience = 350
	captain.salary = 0
	return captain
end

function UIManager.registerEntityCallbacksClient(new_id, old_id)
	local entity = Entity(new_id)
	if valid(entity) then
		entity:registerCallback("onPlanModifiedByBuilding", "onPlanModifiedByBuilding")
		--entity:registerCallback("onShieldActivate", "onShieldActivate")
		entity:registerCallback("onShieldDeactivate", "onShieldDeactivate")	
	end
	if not old_id then return end
	entity = Entity(old_id)
	if valid(entity) then
		entity:unregisterCallback("onPlanModifiedByBuilding", "onPlanModifiedByBuilding")
		--entity:unregisterCallback("onShieldActivate", "onShieldActivate")
		entity:unregisterCallback("onShieldDeactivate", "onShieldDeactivate")
	end
end

function UIManager.registerEntityCallbacks(new_id, old_id)
	local entity = Entity(new_id)
	if valid(entity) then
		local captain = entity:getCaptain()
		if not captain or (captain.name == "VI" or captain.experience ~= 0) then
			entity:setCaptain(UIManager.createVIcaptain())
		end
		
		entity:registerCallback("onJumpRouteCalculationStarted", "onJumpRouteCalculationStarted")
		entity:registerCallback("onSystemsChanged", "onSystemsChanged")
		entity:registerCallback("onCaptainChanged", "onCaptainChanged")
		entity:registerCallback("onPassengerAdded", "onPassengerAdded")	
		--entity:registerCallback("onPlanModifiedByBuilding", "onPlanModifiedByBuilding")
	end
	if not old_id then return end
	entity = Entity(old_id)
	if valid(entity) then
		entity:unregisterCallback("onJumpRouteCalculationStarted", "onJumpRouteCalculationStarted")
		entity:unregisterCallback("onSystemsChanged", "onSystemsChanged")
		entity:unregisterCallback("onCaptainChanged", "onCaptainChanged")
		entity:unregisterCallback("onPassengerAdded", "onPassengerAdded")
		--entity:unregisterCallback("onPlanModifiedByBuilding", "onPlanModifiedByBuilding")
	end
end
callable(UIManager, "registerEntityCallbacks")

--[[
function UIManager.onShieldActivate()
	print("on shield ac")
end
--]]

--todo clear unused entries
-- 2 addVoiceEntry() with the same source name, within frequency (seconds) timespan = second entry will be ignored. This is done to reduce constant repeating of the same voice line every few seconds
function UIManager.addVoiceEntry(path, duration, type_, volume, id, frequency, source)
	if duration == nil then return print("UI Lib Error: no duration for voice line") end
	local clock_ = os.clock()
	local entry = frequency_list[id]
	if not entry then 
		frequency_list[id] = {}
		entry = frequency_list[id]
	end
	if entry[source] and entry[source] > clock_ then
		do return true end
	end
		
	if not next(queue) then
		queue[1] = {path = path, duration = duration, type_ = type_, volume = volume, id = id, frequency = frequency}
		next_sound = 1
		last_sound = 1
	else
		last_sound = last_sound + 1 
		queue[last_sound] = {path = path, duration = duration, type_ = type_, volume = volume}		
	end
	if sound_end_time < clock_ then
		sound_end_time = 0
	end	
	frequency_list[id][source] = clock_ + frequency
end

function UIManager.updateClient(step)
	if next(queue) and (sound_end_time < os.clock()) then
		local sound = queue[next_sound]
		playSound(sound.path, sound.type_, sound.volume)
		sound_end_time = sound.duration + os.clock()
		queue[next_sound] = nil
		next_sound = next_sound + 1
	end
	--temp solution
	if vi then
		if Keyboard():keyPressed(73) and os.clock() > vars.keyboard_timeout then
			local entity = Player().craft
			if entity then
				local target = entity.selectedObject
				if target and target.isStation then
					local err = entity:invokeFunction("data/scripts/entity/orderchain.lua", "onUserDockToStationOrder", target.index)		
					if err == 0 then
						UIManager.addVIline("announcement", "docking", 1, "new_ai_order")						
					end
				end
			end
			
			vars.keyboard_timeout = os.clock() + 0.5			
		end
	end
end

------------savedata-------------
function UIManager.secure()
	return self.data
end

function UIManager.restore(restored_data)
	self.data = restored_data or {}
end
