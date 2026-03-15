local WreckageSearch = {}
local UnifiedWreckageCache = include("UnifiedWreckageCache")
local SALVAGE_DEBUG_ENABLED = false
function WreckageSearch.getNearestWreckage(shipIndex, lastSalvageLocation, miningFilters, wreckageCache, validateWreckageResources)
    local minDist = math.huge
    local newTarget = nil
    local MAX_SEARCH_DISTANCE = 2000 -- Maximum distance to search for targets (prevent cross-sector flights)
    local VERY_CLOSE_DISTANCE = 500  -- Prioritize very close targets
    if SALVAGE_DEBUG_ENABLED and onServer() then
        Sector():broadcastChatMessage(Entity(), ChatMessageType.Chatter, 
            string.format("[TARGET DEBUG] getNearestWreckage called for ship %s", tostring(shipIndex)))
    end
    local refreshedCount = UnifiedWreckageCache.forceRefreshNearbyValidation(lastSalvageLocation, MAX_SEARCH_DISTANCE)
    if SALVAGE_DEBUG_ENABLED and onServer() and refreshedCount > 0 then
        Sector():broadcastChatMessage(Entity(), ChatMessageType.Chatter, 
            string.format("[TARGET DEBUG] Force refreshed validation for %d nearby wreckages", refreshedCount))
    end
    local nearbyWreckages = {}
    local allWreckages = UnifiedWreckageCache.getAllWreckages()
    local totalWreckages = 0
    local assignedWreckages = 0
    local invalidWreckages = 0
    for wreckageId, wreckageData in pairs(allWreckages) do
        totalWreckages = totalWreckages + 1
        if valid(wreckageData.entity) then
            if wreckageData.assigned then
                assignedWreckages = assignedWreckages + 1
            else
                local dist = distance2(wreckageData.translationf, lastSalvageLocation)
                if dist <= MAX_SEARCH_DISTANCE then
                    table.insert(nearbyWreckages, {
                        id = wreckageId,
                        data = wreckageData,
                        distance = dist
                    })
                end
            end
        else
            invalidWreckages = invalidWreckages + 1
        end
    end
    if SALVAGE_DEBUG_ENABLED and onServer() then
        Sector():broadcastChatMessage(Entity(), ChatMessageType.Chatter, 
            string.format("[TARGET DEBUG] Search from ship %s: %d total, %d assigned, %d invalid, %d nearby", 
                tostring(shipIndex), totalWreckages, assignedWreckages, invalidWreckages, #nearbyWreckages))
    end
    table.sort(nearbyWreckages, function(a, b) return a.distance < b.distance end)
    local materialFiltered = 0
    local validationFailed = 0
    local foundTargets = 0
    for _, wreckage in ipairs(nearbyWreckages) do
        if wreckage and wreckage.data and wreckage.data.entity then
            local material = wreckage.data.entity:getMineableMaterial()
            if material and miningFilters[material.value] == true then
                if validateWreckageResources(wreckage.id) then
                    foundTargets = foundTargets + 1
                    if wreckage.distance < minDist then
                        minDist = wreckage.distance
                    end
                    newTarget = Uuid(wreckage.id)
                    if SALVAGE_DEBUG_ENABLED and onServer() then
                        Sector():broadcastChatMessage(Entity(), ChatMessageType.Chatter, 
                            string.format("[TARGET DEBUG] Found valid target %s at distance %.1f", wreckage.id, wreckage.distance))
                    end
                    if wreckage.distance <= VERY_CLOSE_DISTANCE then
                        if SALVAGE_DEBUG_ENABLED and onServer() then
                            Sector():broadcastChatMessage(Entity(), ChatMessageType.Chatter, 
                                string.format("[TARGET DEBUG] VERY CLOSE target found at %.1f, stopping search", wreckage.distance))
                        end
                        break
                    end
                end
            else
                validationFailed = validationFailed + 1
                if SALVAGE_DEBUG_ENABLED and onServer() then
                    Sector():broadcastChatMessage(Entity(), ChatMessageType.Chatter, 
                        string.format("[TARGET DEBUG] Target %s failed validation (distance: %.1f)", wreckage.id, wreckage.distance))
                end
            end
        else
            materialFiltered = materialFiltered + 1
        end
    end
    if SALVAGE_DEBUG_ENABLED and onServer() then
        Sector():broadcastChatMessage(Entity(), ChatMessageType.Chatter, 
            string.format("[TARGET DEBUG] Material filtered: %d, validation failed: %d, found targets: %d", 
                materialFiltered, validationFailed, foundTargets))
    end
    if not newTarget then
        local allWreckages = getCachedEntitiesByType(EntityType.Wreckage)
        if SALVAGE_DEBUG_ENABLED and onServer() then
            Sector():broadcastChatMessage(Entity(), ChatMessageType.Chatter, 
                string.format("[FOREMAN] Searching %d total wreckages for uncached targets", #allWreckages))
        end
        local uncachedNearby = {}
        local cachedWreckages = UnifiedWreckageCache.getAllWreckages()
        for _, wreckage in ipairs(allWreckages) do
            if valid(wreckage) then
                local wreckageId = tostring(wreckage.index)
                if not cachedWreckages[wreckageId] then
                    local dist = distance2(wreckage.translationf, lastSalvageLocation)
                    if dist <= MAX_SEARCH_DISTANCE then
                        table.insert(uncachedNearby, {
                            entity = wreckage,
                            id = wreckageId,
                            distance = dist
                        })
                    end
                end
            end
        end
        table.sort(uncachedNearby, function(a, b) return a.distance < b.distance end)
        for _, wreckage in ipairs(uncachedNearby) do
            local material = wreckage.entity:getMineableMaterial()
            if material and miningFilters[material.value] == true then
                if SALVAGE_DEBUG_ENABLED and onServer() then
                    Sector():broadcastChatMessage(Entity(), ChatMessageType.Chatter, 
                        string.format("[FOREMAN] Uncached wreckage %s: material=%d, distance=%.1f", wreckage.id, material.value, wreckage.distance))
                end
                if wreckage.distance < minDist then
                    local amount = 0
                    for _, j in pairs({wreckage.entity:getMineableResources()}) do
                        amount = amount + j
                    end
                    if amount >= 1 then
                        minDist = wreckage.distance
                        newTarget = wreckage.entity.id
                        UnifiedWreckageCache.addWreckage(wreckage.id, wreckage.entity, material, amount)
                        if SALVAGE_DEBUG_ENABLED and onServer() then
                            Sector():broadcastChatMessage(Entity(), ChatMessageType.Chatter, 
                                string.format("[FOREMAN] Found uncached wreckage %s, added to cache (distance: %.1f)", wreckage.id, wreckage.distance))
                        end
                        if wreckage.distance <= VERY_CLOSE_DISTANCE then
                            break
                        end
                    else
                        if SALVAGE_DEBUG_ENABLED and onServer() then
                            Sector():broadcastChatMessage(Entity(), ChatMessageType.Chatter, 
                                string.format("[FOREMAN] Uncached wreckage %s has insufficient resources: %d", wreckage.id, amount))
                        end
                    end
                end
            else
                if SALVAGE_DEBUG_ENABLED and onServer() then
                    local reason = not material and "no material" or "filtered out"
                    Sector():broadcastChatMessage(Entity(), ChatMessageType.Chatter, 
                        string.format("[FOREMAN] Uncached wreckage %s rejected: %s", wreckage.id, reason))
                end
            end
        end
    end
    if SALVAGE_DEBUG_ENABLED and onServer() then
        if newTarget then
            Sector():broadcastChatMessage(Entity(), ChatMessageType.Chatter, 
                string.format("[TARGET DEBUG] FINAL RESULT: Found target %s at distance %.1f", tostring(newTarget), minDist))
        else
            Sector():broadcastChatMessage(Entity(), ChatMessageType.Chatter, 
                string.format("[TARGET DEBUG] FINAL RESULT: NO TARGET FOUND for ship %s", tostring(shipIndex)))
        end
    end
    if not newTarget then
        local refreshedCount = UnifiedWreckageCache.forceRefreshAllValidation()
        if SALVAGE_DEBUG_ENABLED and onServer() and refreshedCount > 0 then
            Sector():broadcastChatMessage(Entity(), ChatMessageType.Chatter, 
                string.format("[TARGET DEBUG] Force refreshed ALL validation cache: %d entries", refreshedCount))
        end
    end
    return newTarget
end
function WreckageSearch.getNearestWreckageExpanding(shipIndex, lastSalvageLocation, miningFilters, wreckageCache, validateWreckageResources)
    local minDist = math.huge
    local newTarget = nil
    local MAX_SEARCH_DISTANCE = 3000 -- Increased maximum distance for expanding search
    local SEARCH_RADIUS_STEP = 200   -- Expand search radius by 200 units each step
    for searchRadius = 200, MAX_SEARCH_DISTANCE, SEARCH_RADIUS_STEP do
        local foundInRadius = false
        for wreckageId, wreckageData in pairs(wreckageCache) do
            if valid(wreckageData.entity) then
                local material = wreckageData.entity:getMineableMaterial()
                if material and miningFilters[material.value] == true then
                    if validateWreckageResources(wreckageId) and not wreckageData.assigned then
                        local dist = distance2(wreckageData.translationf, lastSalvageLocation)
                        if dist <= searchRadius and dist < minDist then
                            minDist = dist
                            newTarget = Uuid(wreckageId)
                            foundInRadius = true
                        end
                    end
                end
            end
        end
        if foundInRadius then
            break
        end
        local allWreckages = getCachedEntitiesByType(EntityType.Wreckage)
        for _, wreckage in ipairs(allWreckages) do
            if valid(wreckage) then
                local material = wreckage:getMineableMaterial()
                if material and miningFilters[material.value] == true then
                    local wreckageId = tostring(wreckage.index)
                    if not UnifiedWreckageCache.getWreckage(wreckageId) then
                        local dist = distance2(wreckage.translationf, lastSalvageLocation)
                        if dist <= searchRadius and dist < minDist then
                            local amount = 0
                            for _, j in pairs({wreckage:getMineableResources()}) do
                                amount = amount + j
                            end
                            if amount >= 1 then
                                minDist = dist
                                newTarget = wreckage.id
                                foundInRadius = true
                                UnifiedWreckageCache.addWreckage(wreckageId, wreckage, material, amount)
                            end
                        end
                    end
                end
            end
        end
        if foundInRadius then
            break
        end
    end
    return newTarget
end
return WreckageSearch
