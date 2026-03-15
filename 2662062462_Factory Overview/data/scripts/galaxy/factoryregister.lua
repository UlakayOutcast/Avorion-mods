local rf = {} -- registered factories, multi level. First level keyed by the faction index, second level by factory id
local initial = {} -- same as above, but only gets updated once, this will be used to calculate profitability over time

--[[
Inner content structure
	factoryData['id'] = self.id
	factoryData['name'] = self.name
	factoryData['title'] = self.title
	factoryData['money_gained'] = stats.moneyGainedFromGoods
	factoryData['money_tax'] = stats.moneyGainedFromTax
	factoryData['money_spent'] = stats.moneySpentOnGoods
	factoryData['location'] = "0x0"
	... other fields, see in factory.lua, merge function
]]--

-- Entry point to call from the factories to register. 
function register(factionIndex, allianceFactory, entity_data) 
	--print("Register called " .. tostring(factionIndex) .. " + " .. tostring(entity_data['id']) )
	fi = factionIndex
	if allianceFactory then
		fi = 'a_' .. factionIndex
	end
	createOrUpdate(fi, entity_data)
end

-- creates or updates the factory registry with the state passed in
function createOrUpdate(factionIndex, entity_data)
	if not rf[factionIndex] then -- factories are registered for their faction, only player owned factories are stored, but for all players
		rf[factionIndex] = {}
	end
	local entityId = tostring(entity_data['id'])
	if not entityId then 
		print("Issue with register call in Galaxy, data is not formatted correctly")
		return 
	end

	local faction_registry = rf[factionIndex]
	local existingContent = faction_registry[entityId] -- inside the faction, all entities are stored with their id
	
	if not existingContent then
		--print("Previously not registered: " .. entityId)
		registerNewFactory(factionIndex, entity_data) -- registering the content for later comparisons
	end
	faction_registry[entityId] = entity_data -- overwriting the previous data
end

function registerNewFactory(factionIndex, entity_data) -- too lazy to generalise both the previous function and this one. You can repeat yourself once, right?
	if not initial[factionIndex] then -- factories are registered for their faction
		initial[factionIndex] = {}
	end
	local entityId = tostring(entity_data['id'])
	if not entityId then -- ideally we shouldn't be here if this is happening, but things change
		print("Issue with registerNewFactory call in Galaxy, data is not formatted correctly")
		return 
	end
	
	local existingContent = initial[factionIndex][entityId] -- inside the faction, all entities are stored with their id
	
	if not existingContent then
		--print("Initial register for " .. tostring(entity_data['name']))
		entity_data['time'] = os.time()
		initial[factionIndex][entityId] = entity_data -- registering the content for later comparisons
	else 
		-- this is an issue, this function should be called only once for each factory
		print("!!! Double registering " .. tostring(entity_data['name']))
	end
end

-- used by the player to get a list of all of their factories. Combines current and initial data
function getFactoriesFor(factionId, allianceFactory) 
	fi = factionId
	if allianceFactory then
		fi = 'a_' .. factionId
	end
	if rf[fi] then
		return merge(fi) 
		--return rf[factionId]
	else
		print("FactionID [" .. tostring(fi) .. "] is not registered.")
		return {}
	end
end

function printRegisteredFactions() -- just for debugging
	local retVal = ""
	for key, _ in pairs(rf) do
		retVal = retVal .. tostring(key) .. ", "
	end
	print("Registered faction indices: " .. retVal)
end

-- Merges the initial and the current data into a single record for the requesting client, calculates working strings and profitability
function merge(factionId)
	local rf_content = rf[factionId]
	local init_content = initial[factionId]
	if not rf_content or not init_content then
		print("Missing content in merge for " .. tostring(factionId))
		return {}
	else
		local factories = {}
		for index, data in pairs(rf_content) do
			local init_fdata = init_content[index]
			
			local factoryData = {}
			factoryData['id'] = data['id']
			factoryData['index'] = data['index']
			factoryData['name'] = data['name']
			factoryData['title'] = data['title']
			factoryData['money_gained'] = data['money_gained']
			factoryData['money_tax'] = data['money_tax']
			factoryData['money_spent'] = data['money_spent']
			factoryData['location'] = data['location']
			factoryData = calculateProfitability(data, init_fdata, factoryData)
			factoryData = addWorkingStrings(data, init_fdata, factoryData)

			factories[index] = factoryData
		end
		return factories
	end
end


-- Work out the percentage of time spent in different working states, as in working vs. errors
function addWorkingStrings(data, init_fdata, factoryData)
	local totalTime = data['runtime']
	if not totalTime or totalTime == 0 then
		print("Error elapsed time in registered factory data in Galaxy / 1")
		factoryData['working_state'] = {}
		factoryData['working_state']["Error with data"] = "100%"
		return factoryData
	end

	if not data['production_register']  then
		print("Error production register is empty in registered factory data in Galaxy")
		factoryData['working_state'] = {}
		factoryData['working_state']["Error with data"] = "100%"
		return factoryData
	end

	local time_check = 0
	local production_percentages = {}


	for reason, time in pairs(data['production_register']) do
		time_check = time_check + time
		production_percentages[reason] = string.format("%.2f%%", (time / totalTime) * 100)
	end

	factoryData['working_state'] = production_percentages

	if time_check == 0 or math.abs( (time_check-totalTime) / totalTime) > 0.01 then
		print("Error with time calc: " .. tostring(time_check) .. " vs. " .. tostring(totalTime)) 
	end

	return factoryData
end

-- Calculates the expected profit / hour based on the elapsed time and money changes since the beginning of this play session
function calculateProfitability(data, init_fdata, factoryData)
	local totalTime = data['runtime'] -- actual elapsed time in seconds
	if not totalTime or totalTime == 0 then
		print("Error in elapsed time in registered factory data in Galaxy / 2")
		return factoryData
	end

	local total_money_gained = data['money_gained'] - init_fdata['money_gained'] -- current - the gains at the beginning of the session
	local total_money_tax = data['money_tax'] - init_fdata['money_tax']
	local total_money_spent = data['money_spent'] - init_fdata['money_spent']

	local total_profit = total_money_gained + total_money_tax - total_money_spent -- profit in this play session
	local profitability = 3600 * (total_profit / totalTime) -- profit / second scaled up to the hour

	factoryData['profitability'] = profitability
	
	return factoryData
end