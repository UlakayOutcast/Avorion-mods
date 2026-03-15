local AsteroidManagement = {}

-- Debug flag for mining filter debugging
local MINING_FILTER_DEBUG = false

function AsteroidManagement.initializeAsteroids(asteroids, getCachedEntitiesByType, invalidateAsteroidValidationCache)
    local entities = getCachedEntitiesByType(EntityType.Asteroid)
    
    for _, v in pairs(entities) do
        if valid(v) then
            local amount = 0
            for _, j in pairs({v:getMineableResources()}) do
                amount = amount + j
            end
            
            if amount > 0 then
                local mineableMaterial = v:getMineableMaterial()
                if mineableMaterial then
                    asteroids[tostring(v.index)] = { translationf = v.translationf, material = mineableMaterial.value, amount = amount}
                    invalidateAsteroidValidationCache()
                end
            end
        end
    end
end

function AsteroidManagement.getAsteroidCount(factionIndex, factionData, asteroids, validateAsteroidResources)
    if not factionData[factionIndex] then return 0 end
    local count = 0
    local miningFilters = factionData[factionIndex].miningFilters or {}
    for asteroidIndex, asteroidInfo in pairs(asteroids) do
        if not validateAsteroidResources(asteroidIndex) then
        end
    end
    for asteroidIndex, asteroidInfo in pairs(asteroids) do
        -- Default to true (allow mining) if filter is not set, only block if explicitly set to false
        if miningFilters[asteroidInfo.material] ~= false then
            count = count + 1
        end
    end
    return count
end
function AsteroidManagement.getNearestAsteroid(location, miningFilters, asteroids, validateAsteroidResources)
    local newAsteroidIndex = nil
    local newAsteroidData = nil
    local minDist = math.huge
    for i, v in pairs(asteroids) do
        -- Default to true (allow mining) if filter is not set, only block if explicitly set to false
        if miningFilters[v.material] ~= false and validateAsteroidResources(i) then
            local dist = distance(v.translationf, location)
            if dist < minDist then
                minDist = dist
                newAsteroidIndex = i
                newAsteroidData = v
            end
        end
    end
    return newAsteroidIndex, newAsteroidData
end
function AsteroidManagement.getNearestAsteroidForSquad(location, miningFilters, squadMaterial, asteroids, validateAsteroidResources)
    local newAsteroidIndex = nil
    local newAsteroidData = nil
    local minDist = math.huge
    for i, v in pairs(asteroids) do
        -- Default to true (allow mining) if filter is not set, only block if explicitly set to false
        if miningFilters[v.material] ~= false and squadMaterial >= v.material and validateAsteroidResources(i) then
            local dist = distance(v.translationf, location)
            if dist < minDist then
                minDist = dist
                newAsteroidIndex = i
                newAsteroidData = v
            end
        end
    end
    return newAsteroidIndex, newAsteroidData
end
function AsteroidManagement.removeAsteroid(asteroidIndex, asteroids, invalidateAsteroidValidationCache)
    if asteroids[tostring(asteroidIndex)] then
        asteroids[tostring(asteroidIndex)] = nil
        invalidateAsteroidValidationCache()
    end
end
function AsteroidManagement.assignFactionMiningSquadsRandomly(factionIndex, miningFilters, factionData, asteroids, asteroidTargets, getCachedEntitiesByType, invalidateAsteroidValidationCache, validateAsteroidResources, addSquadsToAsteroid, getTableLength, MAX_SQUADS_PER_ASTEROID)
    local fData = factionData[factionIndex]
    local commandingAsteroidMaterialLevel = factionData[factionIndex].commandingAsteroidMaterialLevel
    local keyset = {}
    local filteredAsteroids = {}
    for shipIndex, shipData in pairs(fData.ships) do
        if shipData.isJumping then
            return -- Don't assign mining squads if any ship is jumping
        end
    end
    if getTableLength(asteroids) == 0 then
        AsteroidManagement.initializeAsteroids(asteroids, getCachedEntitiesByType, invalidateAsteroidValidationCache)
    end
    for i,v in pairs(asteroids) do
        -- Default to true (allow mining) if filter is not set, only block if explicitly set to false
        if miningFilters[v.material] ~= false then
            filteredAsteroids[i] = v
            table.insert(keyset, i)
        end
    end
    local totalSquads = 0
    for _,v in pairs(fData.ships) do
        totalSquads = totalSquads + getTableLength(v.miningSquads)
    end
    local asteroidsNum = getTableLength(filteredAsteroids)
    local takenRoids = {}
    for shipIndex, shipData in pairs(fData.ships) do
        local controller = FighterController(Uuid(shipIndex))
        local ship = Entity(Uuid(shipIndex))
        if not valid(ship) then goto continue end
        local hangar = Hangar(ship.id)
        local shipWentActive = false
        for i, rawSquad in pairs(shipData.miningSquads) do
            local retryCount = 3
            local selectedKey = nil
            local selectedData = nil
            local squadMaxMaterial = hangar:getHighestMaterialInSquadMainCategory(i).value + 1
            if asteroidsNum >= totalSquads then
                while retryCount > 0 and selectedKey == nil do
                    retryCount = retryCount - 1
                    local candidateKey = keyset[math.random(#keyset)]
                    local data = filteredAsteroids[candidateKey]
                    if data and (commandingAsteroidMaterialLevel == nil or commandingAsteroidMaterialLevel >= data.material) and squadMaxMaterial >= data.material and takenRoids[candidateKey] == nil and SquadManagement.getAsteroidSquadCount(candidateKey, asteroidTargets) < MAX_SQUADS_PER_ASTEROID and validateAsteroidResources(candidateKey) then
                        selectedKey = candidateKey
                        selectedData = data
                    end
                end
                if selectedKey then
                    takenRoids[selectedKey] = true
                    ArrayUtils.removeFromArray(keyset, selectedKey)
                    asteroidsNum = math.max(0, asteroidsNum - 1)
                    totalSquads = math.max(0, totalSquads - 1)
                end
            else
                while retryCount > 0 and selectedKey == nil and asteroidsNum > 0 do
                    retryCount = retryCount - 1
                    local candidateKey = keyset[math.random(asteroidsNum)]
                    local data = filteredAsteroids[candidateKey]
                    if data and SquadManagement.getAsteroidSquadCount(candidateKey, asteroidTargets) < MAX_SQUADS_PER_ASTEROID and takenRoids[candidateKey] == nil and validateAsteroidResources(candidateKey) then
                        selectedKey = candidateKey
                        selectedData = data
                    else
                        ArrayUtils.removeFromArray(keyset, candidateKey)
                        asteroidsNum = math.max(0, asteroidsNum - 1)
                    end
                end
                if selectedKey == nil then
                    local remainingKeys = {}
                    for k, v in pairs(filteredAsteroids) do
                        if (commandingAsteroidMaterialLevel == nil or commandingAsteroidMaterialLevel >= v.material) and squadMaxMaterial >= v.material and validateAsteroidResources(k) then
                            table.insert(remainingKeys, k)
                        end
                    end
                    if #remainingKeys > 0 then
                        selectedKey, selectedData = SquadManagement.getAsteroidWithLeastSquads(remainingKeys, asteroids, miningFilters, commandingAsteroidMaterialLevel, squadMaxMaterial, asteroidTargets, validateAsteroidResources)
                    end
                end
            end
            if selectedKey then
                if rawSquad then
                    if ship.freeCargoSpace > 150 then
                        shipWentActive = true
                        addSquadsToAsteroid(selectedKey, selectedData.translationf, factionIndex, shipIndex, { i })
                        controller:setSquadOrders(i, FighterOrders.Attack, Uuid(selectedKey))
                    end
                else
                    shipWentActive = true
                    addSquadsToAsteroid(selectedKey, selectedData.translationf, factionIndex, shipIndex, { i })
                    controller:setSquadOrders(i, FighterOrders.Attack, Uuid(selectedKey))
                end
            else
                controller:setSquadOrders(i, FighterOrders.Return, Uuid())
            end
        end
        factionData[factionIndex].ships[tostring(shipIndex)].harvest = shipWentActive
        factionData[factionIndex].ships[tostring(shipIndex)].isActive = shipWentActive
        ::continue::
    end
end
function AsteroidManagement.assignMiningSquadsRandomly(factionIndex, shipIndex, factionData, asteroids, asteroidTargets, getTableLength, MAX_SQUADS_PER_ASTEROID, addSquadsToAsteroid)
    local miningSquads = factionData[factionIndex].ships[tostring(shipIndex)].miningSquads
    local controller = FighterController(shipIndex)
    local squadsNum = getTableLength(miningSquads)
    local asteroidsNum = getTableLength(asteroids)
    local commandingAsteroidMaterialLevel = factionData[factionIndex].commandingAsteroidMaterialLevel
    local miningFilters = factionData[factionIndex].miningFilters or {}
    local ship = Entity(shipIndex)
    local hangar = Hangar(ship.id)
    local shipWentActive = false
    local takenRoids = {}
    local keyset = {}
    
    -- First, reassign any squads that are currently mining asteroids with disabled materials
    if MINING_FILTER_DEBUG then
        print("[FILTER DEBUG] Checking existing squad assignments for filter compliance...")
    end
    if controller and valid(controller) then
        for i, rawSquad in pairs(miningSquads) do
            -- Check if squad is currently mining by looking at deployed fighters
            local deployedFighters = {controller:getDeployedFighters(i)}
            local isMiningDisabledMaterial = false
            local currentTarget = nil
            
            if deployedFighters and #deployedFighters > 0 then
                for _, fighter in pairs(deployedFighters) do
                    if valid(fighter) then
                        local fighterAI = FighterAI(fighter.id)
                        if fighterAI and fighterAI.orders == FighterOrders.Attack and valid(Entity(fighterAI.target)) then
                            local targetAsteroid = Entity(fighterAI.target)
                            local asteroidMaterial = targetAsteroid:getMineableMaterial()
                            -- Block mining if filter is explicitly set to false
                            if asteroidMaterial and miningFilters[asteroidMaterial.value] == false then
                                isMiningDisabledMaterial = true
                                currentTarget = fighterAI.target
                                if MINING_FILTER_DEBUG then
                                    print("[FILTER DEBUG] Squad " .. i .. " is mining disabled material " .. asteroidMaterial.value .. ", will reassign to valid target")
                                end
                                break
                            end
                        end
                    end
                end
            end
            
            if isMiningDisabledMaterial then
                -- Find a new valid target for this squad
                local squadMaxMaterial = hangar:getHighestMaterialInSquadMainCategory(i).value + 1
                local newTarget, newTargetData = AsteroidManagement.getNearestAsteroidForSquad(ship.translationf, miningFilters, squadMaxMaterial, asteroids, function(asteroidIndex) return AsteroidUtils.validateAsteroidResources(asteroidIndex, asteroids, factionData._validationCacheValid, factionData._asteroidValidationCache) end)
                
                if newTarget then
                    if MINING_FILTER_DEBUG then
                        print("[FILTER DEBUG] Reassigning squad " .. i .. " to new target " .. newTarget .. " (material " .. newTargetData.material .. ")")
                    end
                    controller:setSquadOrders(i, FighterOrders.Attack, Uuid(newTarget))
                    addSquadsToAsteroid(newTarget, newTargetData.translationf, factionIndex, shipIndex, { i })
                else
                    if MINING_FILTER_DEBUG then
                        print("[FILTER DEBUG] No valid targets found for squad " .. i .. ", returning to ship")
                    end
                    controller:setSquadOrders(i, FighterOrders.Return, Uuid())
                end
            end
        end
    else
        if MINING_FILTER_DEBUG then
            print("[FILTER DEBUG] FighterController is not valid, skipping existing squad check")
        end
    end
    -- Debug: Show current mining filters
    if MINING_FILTER_DEBUG then
        print("[FILTER DEBUG] Current mining filters for faction " .. factionIndex .. ":")
        for material, enabled in pairs(miningFilters) do
            print("[FILTER DEBUG]   Material " .. material .. ": " .. tostring(enabled) .. " (type: " .. type(enabled) .. ")")
        end
        
        -- Also show all possible materials (0-6) to catch missing ones
        print("[FILTER DEBUG] All material filters (including missing ones):")
        for materialIndex = 0, 6 do
            local value = miningFilters[materialIndex]
            local status = "nil"
            if value == true then status = "ALLOWED"
            elseif value == false then status = "BLOCKED"
            end
            print("[FILTER DEBUG]   Material " .. materialIndex .. ": " .. status .. " (value: " .. tostring(value) .. ")")
        end
    end
    
    for k, v in pairs(asteroids) do
        local filterValue = miningFilters[v.material]
        -- Default to true (allow mining) if filter is not set, only block if explicitly set to false
        local filterEnabled = filterValue ~= false
        local materialLevelOk = commandingAsteroidMaterialLevel == nil or v.material <= commandingAsteroidMaterialLevel
        local validationOk = AsteroidUtils.validateAsteroidResources(k, asteroids, factionData._validationCacheValid, factionData._asteroidValidationCache)
        local squadCountOk = SquadManagement.getAsteroidSquadCount(k, asteroidTargets) < MAX_SQUADS_PER_ASTEROID
        
        if MINING_FILTER_DEBUG then
            print("[FILTER DEBUG] Asteroid " .. k .. " (material " .. v.material .. "): filter=" .. tostring(filterEnabled) .. " (value=" .. tostring(filterValue) .. ", type=" .. type(filterValue) .. "), level=" .. tostring(materialLevelOk) .. ", valid=" .. tostring(validationOk) .. ", squads=" .. tostring(squadCountOk))
        end
        
        if filterEnabled and materialLevelOk and validationOk then
            if squadCountOk then
                table.insert(keyset, k)
                if MINING_FILTER_DEBUG then
                    print("[FILTER DEBUG]   -> ADDED to keyset")
                end
            else
                if MINING_FILTER_DEBUG then
                    print("[FILTER DEBUG]   -> REJECTED (too many squads)")
                end
            end
        else
            if MINING_FILTER_DEBUG then
                print("[FILTER DEBUG]   -> REJECTED (filter/level/validation failed)")
            end
        end
    end
    local keysetCount = #keyset
    asteroidsNum = keysetCount
    for i, rawSquad in pairs(miningSquads) do
        local retryCount = 3
        local selectedKey = nil
        local selectedData = nil
        local squadMaxMaterial = hangar:getHighestMaterialInSquadMainCategory(i).value + 1
        if asteroidsNum >= squadsNum then
            while retryCount > 0 and selectedKey == nil and keysetCount > 0 do
                retryCount = retryCount - 1
                local candidateKey = keyset[math.random(keysetCount)]
                local data = asteroids[candidateKey]
                if data and miningFilters[data.material] ~= false and (commandingAsteroidMaterialLevel == nil or commandingAsteroidMaterialLevel >= data.material) and squadMaxMaterial >= data.material and
                   takenRoids[candidateKey] == nil and SquadManagement.getAsteroidSquadCount(candidateKey, asteroidTargets) < MAX_SQUADS_PER_ASTEROID and
                   AsteroidUtils.validateAsteroidResources(candidateKey, asteroids, factionData._validationCacheValid, factionData._asteroidValidationCache) then
                    selectedKey = candidateKey
                    selectedData = data
                else
                    if ArrayUtils.removeFromArray(keyset, candidateKey) then keysetCount = keysetCount - 1 end
                end
            end
        else
            while retryCount > 0 and selectedKey == nil and keysetCount > 0 do
                retryCount = retryCount - 1
                local candidateKey = keyset[math.random(keysetCount)]
                local data = asteroids[candidateKey]
                if data and miningFilters[data.material] == true and SquadManagement.getAsteroidSquadCount(candidateKey, asteroidTargets) < MAX_SQUADS_PER_ASTEROID and takenRoids[candidateKey] == nil and
                   AsteroidUtils.validateAsteroidResources(candidateKey, asteroids, factionData._validationCacheValid, factionData._asteroidValidationCache) then
                    selectedKey = candidateKey
                    selectedData = data
                else
                    if ArrayUtils.removeFromArray(keyset, candidateKey) then keysetCount = keysetCount - 1 end
                end
            end
            if selectedKey == nil then
                local remainingKeys = {}
                for k, v in pairs(asteroids) do
                    if miningFilters[v.material] == true and (commandingAsteroidMaterialLevel == nil or v.material <= commandingAsteroidMaterialLevel) and AsteroidUtils.validateAsteroidResources(k, asteroids, factionData._validationCacheValid, factionData._asteroidValidationCache) then
                        table.insert(remainingKeys, k)
                    end
                end
                if #remainingKeys > 0 then
                    selectedKey, selectedData = SquadManagement.getAsteroidWithLeastSquads(remainingKeys, asteroids, miningFilters, commandingAsteroidMaterialLevel, squadMaxMaterial, asteroidTargets, function(asteroidIndex) return AsteroidUtils.validateAsteroidResources(asteroidIndex, asteroids, factionData._validationCacheValid, factionData._asteroidValidationCache) end)
                end
            end
        end
        if selectedKey then
            if rawSquad then
                if ship.freeCargoSpace > 150 then
                    shipWentActive = true
                    addSquadsToAsteroid(selectedKey, selectedData.translationf, factionIndex, shipIndex, { i })
                    takenRoids[selectedKey] = true
                    if ArrayUtils.removeFromArray(keyset, selectedKey) then keysetCount = keysetCount - 1 end
                    controller:setSquadOrders(i, FighterOrders.Attack, Uuid(selectedKey))
                end
            else
                shipWentActive = true
                addSquadsToAsteroid(selectedKey, selectedData.translationf, factionIndex, shipIndex, { i })
                takenRoids[selectedKey] = true
                if ArrayUtils.removeFromArray(keyset, selectedKey) then keysetCount = keysetCount - 1 end
                controller:setSquadOrders(i, FighterOrders.Attack, Uuid(selectedKey))
            end
        else
            controller:setSquadOrders(i, FighterOrders.Return, Uuid())
        end
    end
    factionData[factionIndex].ships[tostring(shipIndex)].harvest = shipWentActive
    factionData[factionIndex].ships[tostring(shipIndex)].isActive = shipWentActive
end
return AsteroidManagement
