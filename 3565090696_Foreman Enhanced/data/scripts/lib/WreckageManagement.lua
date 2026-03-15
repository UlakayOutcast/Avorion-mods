local WreckageManagement = {}
local SalvageWorkAreaManager = include("SalvageWorkAreaManager")
local UnifiedWreckageCache = include("UnifiedWreckageCache")
local SquadManagement = include("SquadManagement")

function WreckageManagement.initializeWreckages(wreckages, getCachedEntitiesByType)
    UnifiedWreckageCache.refreshCache(true)
    local allWreckages = UnifiedWreckageCache.getAllWreckages()
    
    for wreckageId, wreckageData in pairs(allWreckages) do
        if valid(wreckageData.entity) and wreckageData.material then
            wreckages[wreckageId] = wreckageData.material.value
        end
    end
end

function WreckageManagement.removeWreckage(wreckageId, wreckages, salvageTargets, removeWreckageFromCache, invalidateWreckageValidationCache)
    if wreckages[tostring(wreckageId)] then
        wreckages[tostring(wreckageId)] = nil
    end
    if salvageTargets[tostring(wreckageId)] then
        salvageTargets[tostring(wreckageId)] = nil
    end
    UnifiedWreckageCache.removeWreckage(tostring(wreckageId))
    invalidateWreckageValidationCache()
end

function WreckageManagement.assignFactionSalvagingSquadsRandomly(factionIndex, miningFilters, factionData, getWreckages, getTableLength, addSquadsToWreckage, SALVAGE_DEBUG_ENABLED, onServer)
    local fData = factionData[factionIndex]
    local commandingSalvageMaterialLevel = factionData[factionIndex].commandingSalvageMaterialLevel
    for shipIndex, shipData in pairs(fData.ships) do
        if shipData.isJumping then
            return -- Don't assign salvage squads if any ship is jumping
        end
    end
    local totalSquads = 0
    for _,v in pairs(fData.ships) do
        totalSquads = totalSquads + getTableLength(v.salvageSquads)
    end
    
    -- Get all available wreckages for the faction
    local allWreckages = {}
    local wreckageKeys = {}
    for shipIndex, shipData in pairs(fData.ships) do
        local ship = Entity(Uuid(shipIndex))
        if valid(ship) then
            local hangar = Hangar(ship.id)
            local squads = {hangar:getSquads()}
            local highestHarvestableMaterial = nil
            for _, index in pairs(squads) do
                if hangar:getSquadMainWeaponCategory(index) == WeaponCategory.Salvaging then
                    local squadHighestMaterial = hangar:getHighestMaterialInSquadMainCategory(index).value
                    if highestHarvestableMaterial == nil or highestHarvestableMaterial < squadHighestMaterial + 3 then
                        highestHarvestableMaterial = squadHighestMaterial + 3
                    end
                end
            end
            if highestHarvestableMaterial then
                local sectorWreckages = getWreckages(ship.id, miningFilters, highestHarvestableMaterial, true)
                for _, wreckage in pairs(sectorWreckages) do
                    if valid(wreckage) then
                        local wreckageId = tostring(wreckage.index)
                        if not allWreckages[wreckageId] then
                            allWreckages[wreckageId] = wreckage
                            table.insert(wreckageKeys, wreckageId)
                        end
                    end
                end
            end
            break -- Only need to get wreckages once per faction
        end
    end
    
    local wreckagesNum = getTableLength(allWreckages)
    local takenWreckages = {}
    
    for shipIndex, shipData in pairs(fData.ships) do
        local ship = Entity(Uuid(shipIndex))
        if not valid(ship) then goto continue end
        local hangar = Hangar(ship.id)
        local controller = FighterController(Uuid(shipIndex))
        local shipWentActive = false
        local shipPos = ship.translationf
        local assignedSquads = {}
        local assignedWreckages = {}
        
        for i, rawSquad in pairs(shipData.salvageSquads) do
            local squadId = string.format("%s_%d", shipIndex, i)
            if rawSquad and ship.freeCargoSpace <= 150 then
                goto continue
            end
            
            local squadMaxMaterial = hangar:getHighestMaterialInSquadMainCategory(i).value + 3
            local targetWreckage = nil
            local selectedKey = nil
            
            -- Use asteroid-style distribution logic
            if wreckagesNum >= totalSquads then
                -- More wreckages than squads: try to give each squad a unique target
                local retryCount = 3
                while retryCount > 0 and selectedKey == nil do
                    retryCount = retryCount - 1
                    local candidateKey = wreckageKeys[math.random(#wreckageKeys)]
                    local wreckage = allWreckages[candidateKey]
                    if wreckage and valid(wreckage) and not takenWreckages[candidateKey] and not assignedWreckages[candidateKey] then
                        local wreckageMaterial = wreckage:getMineableMaterial()
                        if wreckageMaterial and squadMaxMaterial >= wreckageMaterial.value then
                            -- Check UnifiedWreckageCache to ensure not already assigned
                            local wreckageData = UnifiedWreckageCache.getWreckage(candidateKey)
                            if not wreckageData or not wreckageData.assigned then
                                selectedKey = candidateKey
                                targetWreckage = wreckage
                            end
                        end
                    end
                end
                if selectedKey then
                    takenWreckages[selectedKey] = true
                    assignedWreckages[selectedKey] = true
                    wreckagesNum = math.max(0, wreckagesNum - 1)
                    totalSquads = math.max(0, totalSquads - 1)
                end
            else
                -- Fewer wreckages than squads: distribute squads evenly across available targets
                local remainingKeys = {}
                for _, key in pairs(wreckageKeys) do
                    local wreckage = allWreckages[key]
                    if wreckage and valid(wreckage) and not assignedWreckages[key] then
                        local wreckageMaterial = wreckage:getMineableMaterial()
                        if wreckageMaterial and squadMaxMaterial >= wreckageMaterial.value then
                            local wreckageData = UnifiedWreckageCache.getWreckage(key)
                            if not wreckageData or not wreckageData.assigned then
                                table.insert(remainingKeys, key)
                            end
                        end
                    end
                end
                if #remainingKeys > 0 then
                    selectedKey, targetWreckage = SquadManagement.getWreckageWithLeastSquads(remainingKeys, miningFilters, squadMaxMaterial, {}, function(id) return true end)
                end
            end
            
            if targetWreckage and valid(targetWreckage) then
                assignedSquads[i] = true
                shipWentActive = true
                addSquadsToWreckage(targetWreckage.index, targetWreckage.translationf, factionIndex, shipIndex, { i })
                controller:setSquadOrders(i, FighterOrders.Attack, targetWreckage.id)
            else
                controller:setSquadOrders(i, FighterOrders.Return, Uuid())
            end
            ::continue::
        end
        factionData[factionIndex].ships[tostring(shipIndex)].salvage = shipWentActive
        factionData[factionIndex].ships[tostring(shipIndex)].isActive = shipWentActive
        ::continue::
    end
end
function WreckageManagement.launchSalvageFightersOnStandby(factionIndex, factionData)
    local fData = factionData[factionIndex]
    for shipIndex, shipData in pairs(fData.ships) do
        if shipData.isJumping then
            return -- Don't launch salvage squads if any ship is jumping
        end
    end
    for shipIndex, shipData in pairs(fData.ships) do
        local ship = Entity(Uuid(shipIndex))
        if not valid(ship) then goto continue end
        local hangar = Hangar(ship.id)
        local controller = FighterController(Uuid(shipIndex))
        if not controller or not hangar then goto continue end
        for i, _ in pairs(shipData.salvageSquads) do
            controller:setSquadOrders(i, FighterOrders.Defend, ship.id)
        end
        factionData[factionIndex].ships[tostring(shipIndex)].salvage = true
        factionData[factionIndex].ships[tostring(shipIndex)].isActive = true
        ::continue::
    end
end
function WreckageManagement.processPendingCacheUpdates(pendingCacheUpdates, cacheUpdateIndex, MAX_UPDATES_PER_FRAME, MIN_WRECKAGE_RESOURCES, SALVAGE_DEBUG_ENABLED, onServer, forceProcessAll, wreckageCache)
    local maxUpdates = forceProcessAll and #pendingCacheUpdates or MAX_UPDATES_PER_FRAME
    local processed = 0
    while cacheUpdateIndex <= #pendingCacheUpdates and processed < maxUpdates do
        local entityId = pendingCacheUpdates[cacheUpdateIndex]
        local entity = Entity(entityId)
        if valid(entity) and entity:hasComponent(ComponentType.MineableMaterial) then
            local mineableMaterial = entity:getMineableMaterial()
            if mineableMaterial and mineableMaterial.amount >= MIN_WRECKAGE_RESOURCES then
                local wreckageId = tostring(entity.index)
                if not UnifiedWreckageCache.getWreckage(wreckageId) then
                    UnifiedWreckageCache.addWreckage(wreckageId, entity, mineableMaterial, mineableMaterial.amount)
                end
            end
        end
        cacheUpdateIndex = cacheUpdateIndex + 1
        processed = processed + 1
    end
    if cacheUpdateIndex > #pendingCacheUpdates then
        pendingCacheUpdates = {}
        cacheUpdateIndex = 1
    end
    return cacheUpdateIndex
end
function WreckageManagement.refreshWreckageCache(forceRefresh, MIN_WRECKAGE_RESOURCES, TARGET_THRESHOLD, SALVAGE_DEBUG_ENABLED, onServer, getAvailableTargetCount, wreckageCache, lastCacheRefresh, smartScanActive)
    local addedCount, removedCount = UnifiedWreckageCache.refreshCache(forceRefresh)
    if addedCount > 0 or removedCount > 0 or forceRefresh then
        SalvageWorkAreaManager.updateSpatialGrid()
    end
    local availableTargets = getAvailableTargetCount()
    if availableTargets < TARGET_THRESHOLD then
        smartScanActive = true
    else
        smartScanActive = false
    end
    return smartScanActive
end
function WreckageManagement.getAvailableTargetCount(wreckageCache, MIN_WRECKAGE_RESOURCES)
    local unassigned = UnifiedWreckageCache.getUnassignedWreckages()
    return #unassigned
end
function WreckageManagement.getBestAvailableTarget(shipPos, wreckageCache, MIN_WRECKAGE_RESOURCES)
    local unassigned = UnifiedWreckageCache.getUnassignedWreckages()
    local bestTarget = nil
    local bestDistance = math.huge
    -- No distance limit - find the closest available target in the sector
    for _, wreckage in ipairs(unassigned) do
        if wreckage and wreckage.data and valid(wreckage.data.entity) then
            local dist = distance2(wreckage.data.translationf, shipPos)
            if dist < bestDistance then
                bestDistance = dist
                bestTarget = {
                    id = wreckage.id,
                    entity = wreckage.data.entity,
                    translationf = wreckage.data.translationf,
                    material = wreckage.data.material,
                    resourceAmount = wreckage.data.resourceAmount,
                    distance = dist
                }
            end
        end
    end
    return bestTarget
end
function WreckageManagement.markTargetAsAssigned(wreckageId, wreckageCache)
end
function WreckageManagement.markTargetAsUnassigned(wreckageId, wreckageCache)
end
function WreckageManagement.assignSquadToWreckage(wreckageIndex, shipIndex, squadIndex, salvageAssignments, wreckageCache)
    local squadKey = string.format("%s_%d", shipIndex, squadIndex)
    UnifiedWreckageCache.assignSquadToWreckage(wreckageIndex, squadKey)
    if not salvageAssignments[wreckageIndex] then
        salvageAssignments[wreckageIndex] = {squads = {}, assignedTime = appTime()}
    end
    salvageAssignments[wreckageIndex].squads[squadKey] = true
    salvageAssignments[wreckageIndex].assignedTime = appTime() -- Update assignment time
end
function WreckageManagement.removeSquadFromWreckage(wreckageIndex, shipIndex, squadIndex, salvageAssignments, wreckageCache)
    local squadKey = string.format("%s_%d", shipIndex, squadIndex)
    UnifiedWreckageCache.unassignSquadFromWreckage(wreckageIndex, squadKey)
    if salvageAssignments[wreckageIndex] and salvageAssignments[wreckageIndex].squads then
        salvageAssignments[wreckageIndex].squads[squadKey] = nil
        if not next(salvageAssignments[wreckageIndex].squads) then
            salvageAssignments[wreckageIndex] = nil
        end
    end
end
function WreckageManagement.removeWreckageFromCache(wreckageIndex, wreckageCache, salvageAssignments)
    UnifiedWreckageCache.removeWreckage(wreckageIndex)
    if salvageAssignments then
        salvageAssignments[wreckageIndex] = nil
    end
end
function WreckageManagement.assignStandbyFightersToTargets(factionIndex, factionData, wreckageCache, salvageAssignments, wreckages, getCachedEntitiesByType, getTableLength, CACHE_REFRESH_INTERVAL, MIN_WRECKAGE_RESOURCES, TARGET_THRESHOLD, SALVAGE_DEBUG_ENABLED, onServer, MAX_SQUADS_PER_WRECKAGE, lastCacheRefresh, smartScanActive, validateWreckageResources, removeSquadFromWreckage, assignSquadToWreckage, processPendingCacheUpdates, pendingCacheUpdates, cacheUpdateIndex, MAX_UPDATES_PER_FRAME)
    local fData = factionData[factionIndex]
    if not fData.salvageStandbyMode then return end
    lastCacheRefresh = lastCacheRefresh + 1 -- Called every 1 second (reduced from 3)
    local refreshInterval = getTableLength(wreckageCache) == 0 and 2 or CACHE_REFRESH_INTERVAL
    if lastCacheRefresh >= refreshInterval then
        smartScanActive = WreckageManagement.refreshWreckageCache(false, MIN_WRECKAGE_RESOURCES, TARGET_THRESHOLD, SALVAGE_DEBUG_ENABLED, onServer, function() return WreckageManagement.getAvailableTargetCount(wreckageCache, MIN_WRECKAGE_RESOURCES) end, wreckageCache, lastCacheRefresh, smartScanActive)
    end
    for shipIndex, shipData in pairs(fData.ships) do
        if shipData.isJumping then
            return -- Don't assign targets if any ship is jumping
        end
    end
    if not fData.salvage then
        return
    end
    WreckageManagement.initializeWreckages(wreckages, getCachedEntitiesByType)
    local unassignedSquads = {}
    local shipPositions = {}
    for shipIndex, shipData in pairs(fData.ships) do
        local ship = Entity(Uuid(shipIndex))
        if not valid(ship) then goto continue end
        local hangar = Hangar(ship.id)
        local controller = FighterController(Uuid(shipIndex))
        if not controller or not hangar then goto continue end
        shipPositions[shipIndex] = ship.translationf
        for i, _ in pairs(shipData.salvageSquads) do
            local deployedFighters = {controller:getDeployedFighters(i)}
            if #deployedFighters > 0 then
                local alreadyAssigned = false
                for wreckageId, assignment in pairs(salvageAssignments) do
                    local squadKey = string.format("%s_%d", shipIndex, i)
                    if assignment.squads and assignment.squads[squadKey] then
                        local wreckage = Entity(Uuid(wreckageId))
                        local assignmentTime = assignment.assignedTime or 0
                        local currentTime = appTime()
                        local timeSinceAssignment = currentTime - assignmentTime
                        local isInGracePeriod = timeSinceAssignment < 2.0 -- 2 second grace period (reduced from 5)
                        if valid(wreckage) and (validateWreckageResources(wreckageId) or isInGracePeriod) then
                            alreadyAssigned = true
                            controller:setSquadOrders(i, FighterOrders.Attack, wreckage.id)
                            break
                        else
                            removeSquadFromWreckage(wreckageId, shipIndex, i)
                            cacheUpdateIndex = processPendingCacheUpdates(pendingCacheUpdates, cacheUpdateIndex, MAX_UPDATES_PER_FRAME, MIN_WRECKAGE_RESOURCES, SALVAGE_DEBUG_ENABLED, onServer, true, wreckageCache)
                        end
                    end
                end
                if not alreadyAssigned then
                    local squadMaxMaterial = hangar:getHighestMaterialInSquadMainCategory(i).value + 1
                    table.insert(unassignedSquads, {
                        shipIndex = shipIndex,
                        squadIndex = i,
                        shipPos = ship.translationf,
                        maxMaterial = squadMaxMaterial,
                        controller = controller
                    })
                end
            end
        end
        ::continue::
    end
    if #unassignedSquads == 0 then
        return
    end
    local availableWreckages = {}
    for wreckageId, wreckageData in pairs(wreckageCache) do
        if valid(wreckageData.entity) then
            local squadCount = SquadManagement.getWreckageSquadCount(wreckageId, salvageAssignments)
            if squadCount < MAX_SQUADS_PER_WRECKAGE then
                local distances = {}
                for shipIndex, shipPos in pairs(shipPositions) do
                    distances[shipIndex] = distance2(wreckageData.translationf, shipPos)
                end
                table.insert(availableWreckages, {
                    id = wreckageId,
                    entity = wreckageData.entity,
                    translationf = wreckageData.translationf,
                    material = wreckageData.material,
                    distances = distances
                })
            end
        end
    end
    -- Smart assignment: Try unique targets first, then fall back to shared targets
    local takenWreckages = {}
    
    for _, squad in ipairs(unassignedSquads) do
        local selectedWreckage = nil
        local bestDistance = math.huge
        
        -- PHASE 1: Try to find a UNIQUE target (no other squads assigned)
        for _, wreckage in ipairs(availableWreckages) do
            if wreckage.material and squad.maxMaterial >= wreckage.material.value and
               fData.miningFilters[wreckage.material.value] == true then
                
                local squadCount = SquadManagement.getWreckageSquadCount(wreckage.id, salvageAssignments)
                -- Check if this is a unique target (no squads assigned yet)
                if squadCount == 0 and not takenWreckages[wreckage.id] then
                    local dist = wreckage.distances[squad.shipIndex]
                    if dist < bestDistance then
                        bestDistance = dist
                        selectedWreckage = wreckage
                    end
                end
            end
        end
        
        -- PHASE 2: If no unique target found, find the CLOSEST available target (even if shared)
        if not selectedWreckage then
            bestDistance = math.huge
            for _, wreckage in ipairs(availableWreckages) do
                if wreckage.material and squad.maxMaterial >= wreckage.material.value and
                   fData.miningFilters[wreckage.material.value] == true then
                    
                    local squadCount = SquadManagement.getWreckageSquadCount(wreckage.id, salvageAssignments)
                    -- Check if this target can accept more squads
                    if squadCount < MAX_SQUADS_PER_WRECKAGE and not takenWreckages[wreckage.id] then
                        local dist = wreckage.distances[squad.shipIndex]
                        if dist < bestDistance then
                            bestDistance = dist
                            selectedWreckage = wreckage
                        end
                    end
                end
            end
        end
        
        if selectedWreckage then
            local squadId = string.format("%s_%d", squad.shipIndex, squad.squadIndex)
            assignSquadToWreckage(selectedWreckage.id, squad.shipIndex, squad.squadIndex)
            squad.controller:setSquadOrders(squad.squadIndex, FighterOrders.Attack, selectedWreckage.entity.id)
            takenWreckages[selectedWreckage.id] = true
        end
    end
end
return WreckageManagement
