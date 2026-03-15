local UnifiedWreckageCache = {}
local CACHE_CONFIG = {
    MIN_WRECKAGE_RESOURCES = 1,
    CACHE_REFRESH_INTERVAL = 2, -- Reduced from 5 for faster response to depletion
    MAX_CACHE_SIZE = 1000,
    VALIDATION_CACHE_TTL = 0.2, -- Reduced from 0.5 for more frequent validation
    ASSIGNMENT_GRACE_PERIOD = 0 -- NO grace period - only reassign when actually idle
}
local SALVAGE_DEBUG_ENABLED = false -- Debug flag for UnifiedWreckageCache
local wreckageCache = {}
local validationCache = {}
local lastValidationTime = 0

function UnifiedWreckageCache.getConfig()
    return CACHE_CONFIG
end

function UnifiedWreckageCache.setDebugEnabled(enabled)
    SALVAGE_DEBUG_ENABLED = enabled
end

function UnifiedWreckageCache.isDebugEnabled()
    return SALVAGE_DEBUG_ENABLED
end

-- Force cache refresh when wreckages are depleted
function UnifiedWreckageCache.forceRefresh()
    if SALVAGE_DEBUG_ENABLED then
        print("[SALVAGE DEBUG] UnifiedWreckageCache: Force refreshing cache due to wreckage depletion")
    end
    UnifiedWreckageCache.refreshCache(true)
end

-- Check if any cached wreckages have been depleted and need refresh
function UnifiedWreckageCache.checkForDepletedWreckages()
    local depletedCount = 0
    local currentTime = appTime() -- Use appTime instead of os.time for better precision
    
    for wreckageId, wreckageData in pairs(wreckageCache) do
        if wreckageData.entity and valid(wreckageData.entity) then
            -- Check if wreckage still has resources
            local resourceAmount = 0
            local success, result = pcall(function()
                return wreckageData.entity:getMineableResources()
            end)
            
            if success and result then
                for _, amount in pairs({result}) do
                    resourceAmount = resourceAmount + amount
                end
            end
            
            -- If wreckage is depleted, mark for removal
            if resourceAmount < CACHE_CONFIG.MIN_WRECKAGE_RESOURCES then
                depletedCount = depletedCount + 1
                -- Immediately remove depleted wreckage from cache
                UnifiedWreckageCache.removeWreckage(wreckageId)
                if SALVAGE_DEBUG_ENABLED then
                    print(string.format("[SALVAGE DEBUG] UnifiedWreckageCache: Wreckage %s depleted (resources: %d), removed immediately", wreckageId, resourceAmount))
                end
            end
        else
            -- Entity is invalid, mark for removal
            depletedCount = depletedCount + 1
            UnifiedWreckageCache.removeWreckage(wreckageId)
        end
    end
    
    -- If we found depleted wreckages, force a refresh to update spatial grid
    if depletedCount > 0 then
        if SALVAGE_DEBUG_ENABLED then
            print(string.format("[SALVAGE DEBUG] UnifiedWreckageCache: Found %d depleted wreckages, forcing refresh", depletedCount))
        end
        UnifiedWreckageCache.forceRefresh()
        return true
    end
    
    return false
end

function UnifiedWreckageCache.setConfig(config)
    for key, value in pairs(config) do
        if CACHE_CONFIG[key] then
            CACHE_CONFIG[key] = value
        end
    end
end
function UnifiedWreckageCache.addWreckage(wreckageId, entity, material, resourceAmount)
    if not valid(entity) or not material then
        return false
    end
    wreckageCache[wreckageId] = {
        entity = entity,
        translationf = entity.translationf,
        material = material,
        resourceAmount = resourceAmount or 0,
        lastSeen = 0,
        assigned = false,
        assignedSquads = {},
        workArea = nil,
        isValid = true
    }
    validationCache[wreckageId] = nil
    return true
end
function UnifiedWreckageCache.getWreckage(wreckageId)
    return wreckageCache[wreckageId]
end
function UnifiedWreckageCache.removeWreckage(wreckageId)
    local wreckageData = wreckageCache[wreckageId]
    wreckageCache[wreckageId] = nil
    validationCache[wreckageId] = nil
end
function UnifiedWreckageCache.validateWreckage(wreckageId)
    local currentTime = appTime()
    if validationCache[wreckageId] and (currentTime - validationCache[wreckageId].timestamp) < CACHE_CONFIG.VALIDATION_CACHE_TTL then
        return validationCache[wreckageId].isValid
    end
    local wreckageData = wreckageCache[wreckageId]
    if not wreckageData then
        if SALVAGE_DEBUG_ENABLED then
            print(string.format("[SALVAGE DEBUG] UnifiedWreckageCache.validateWreckage: Wreckage %s not found in cache", wreckageId))
        end
        validationCache[wreckageId] = {isValid = false, timestamp = currentTime}
        return false
    end
    if not valid(wreckageData.entity) then
        if SALVAGE_DEBUG_ENABLED then
            print(string.format("[SALVAGE DEBUG] UnifiedWreckageCache.validateWreckage: Wreckage %s entity is invalid", wreckageId))
        end
        wreckageData.isValid = false
        validationCache[wreckageId] = {isValid = false, timestamp = currentTime}
        return false
    end
    if wreckageData.assigned and wreckageData.assignedTime then
        local timeSinceAssignment = currentTime - wreckageData.assignedTime
        if timeSinceAssignment < CACHE_CONFIG.ASSIGNMENT_GRACE_PERIOD then
            validationCache[wreckageId] = {isValid = true, timestamp = currentTime}
            return true
        end
    end
    local resourcesLeft = 0
    local success, result = pcall(function()
        return wreckageData.entity:getMineableResources()
    end)
    if success and result then
        for _, amount in pairs({result}) do
            resourcesLeft = resourcesLeft + amount
        end
    end
    local isValid = resourcesLeft >= CACHE_CONFIG.MIN_WRECKAGE_RESOURCES
    
    if SALVAGE_DEBUG_ENABLED then
        print(string.format("[SALVAGE DEBUG] UnifiedWreckageCache.validateWreckage: Wreckage %s - resources: %.1f, min_required: %d, valid: %s", 
            wreckageId, resourcesLeft, CACHE_CONFIG.MIN_WRECKAGE_RESOURCES, tostring(isValid)))
    end
    
    wreckageData.isValid = isValid
    wreckageData.resourceAmount = resourcesLeft
    
    -- If wreckage is depleted, immediately remove it from cache
    if not isValid then
        if SALVAGE_DEBUG_ENABLED then
            print(string.format("[SALVAGE DEBUG] UnifiedWreckageCache.validateWreckage: Removing depleted wreckage %s (resources: %.1f)", wreckageId, resourcesLeft))
        end
        UnifiedWreckageCache.removeWreckage(wreckageId)
        validationCache[wreckageId] = {isValid = false, timestamp = currentTime}
        return false
    end
    
    if isValid and wreckageData.assigned then
        local hasActiveSquads = false
        for squadId, _ in pairs(wreckageData.assignedSquads) do
            hasActiveSquads = true
            break
        end
        if not hasActiveSquads then
            wreckageData.assigned = false
            wreckageData.assignedSquads = {}
        end
    end
    validationCache[wreckageId] = {isValid = isValid, timestamp = currentTime}
    return isValid
end
function UnifiedWreckageCache.assignSquadToWreckage(wreckageId, squadId)
    local wreckageData = wreckageCache[wreckageId]
    if wreckageData then
        wreckageData.assigned = true
        wreckageData.assignedTime = appTime() -- Record assignment time for grace period
        wreckageData.assignedSquads[squadId] = true
        return true
    end
    return false
end
function UnifiedWreckageCache.unassignSquadFromWreckage(wreckageId, squadId)
    local wreckageData = wreckageCache[wreckageId]
    if wreckageData then
        wreckageData.assignedSquads[squadId] = nil
        if not next(wreckageData.assignedSquads) then
            wreckageData.assigned = false
        end
        return true
    end
    return false
end
function UnifiedWreckageCache.getUnassignedWreckages()
    if SALVAGE_DEBUG_ENABLED then
        print("[SALVAGE DEBUG] UnifiedWreckageCache.getUnassignedWreckages: Function called - DEBUG ENABLED")
        local cacheCount = 0
        for _ in pairs(wreckageCache) do cacheCount = cacheCount + 1 end
        print(string.format("[SALVAGE DEBUG] UnifiedWreckageCache.getUnassignedWreckages: Cache has %d entries", cacheCount))
    end
    local unassigned = {}
    for wreckageId, wreckageData in pairs(wreckageCache) do
        if SALVAGE_DEBUG_ENABLED then
            print(string.format("[SALVAGE DEBUG] CACHE LOOP: wreckageId=%s, wreckageData type=%s, exists=%s", 
                wreckageId, type(wreckageData), wreckageData and "true" or "false"))
        end
        if SALVAGE_DEBUG_ENABLED then
            print(string.format("[SALVAGE DEBUG] UnifiedWreckageCache.getUnassignedWreckages: Checking wreckage %s", wreckageId))
            print(string.format("[SALVAGE DEBUG]   wreckageData type: %s", type(wreckageData)))
            print(string.format("[SALVAGE DEBUG]   wreckageData exists: %s", wreckageData and "true" or "false"))
            if wreckageData and type(wreckageData) == "table" then
                print(string.format("[SALVAGE DEBUG]   wreckageData.assigned: %s", tostring(wreckageData.assigned)))
                print(string.format("[SALVAGE DEBUG]   wreckageData.entity exists: %s", wreckageData.entity and "true" or "false"))
                print(string.format("[SALVAGE DEBUG]   wreckageData.resourceAmount: %.1f", wreckageData.resourceAmount or 0))
            end
        end
        
        if wreckageData and type(wreckageData) == "table" and not wreckageData.assigned and UnifiedWreckageCache.validateWreckage(wreckageId) then
            if SALVAGE_DEBUG_ENABLED then
                print(string.format("[SALVAGE DEBUG] UnifiedWreckageCache.getUnassignedWreckages: Adding wreckage %s to unassigned list", wreckageId))
            end
            table.insert(unassigned, {
                id = wreckageId,
                data = wreckageData
            })
        else
            if SALVAGE_DEBUG_ENABLED then
                print(string.format("[SALVAGE DEBUG] UnifiedWreckageCache.getUnassignedWreckages: Skipping wreckage %s - data: %s, assigned: %s, valid: %s", 
                    wreckageId, 
                    wreckageData and "true" or "false",
                    (wreckageData and type(wreckageData) == "table" and wreckageData.assigned) and "true" or "false",
                    UnifiedWreckageCache.validateWreckage(wreckageId) and "true" or "false"))
            end
        end
    end
    if SALVAGE_DEBUG_ENABLED then
        print(string.format("[SALVAGE DEBUG] UnifiedWreckageCache.getUnassignedWreckages: Returning %d unassigned wreckages", #unassigned))
    end
    return unassigned
end
function UnifiedWreckageCache.getAssignedWreckages()
    local assigned = {}
    for wreckageId, wreckageData in pairs(wreckageCache) do
        if wreckageData.assigned and UnifiedWreckageCache.validateWreckage(wreckageId) then
            table.insert(assigned, {
                id = wreckageId,
                data = wreckageData
            })
        end
    end
    return assigned
end
function UnifiedWreckageCache.getWreckagesInWorkArea(center, radius, miningFilters)
    local wreckages = {}
    for wreckageId, wreckageData in pairs(wreckageCache) do
        if UnifiedWreckageCache.validateWreckage(wreckageId) then
            local distance = distance2(wreckageData.translationf, center)
            if distance <= radius then
                local material = wreckageData.material
                if material and miningFilters[material.value] == true then
                    table.insert(wreckages, {
                        id = wreckageId,
                        data = wreckageData,
                        distance = distance
                    })
                end
            end
        end
    end
    table.sort(wreckages, function(a, b) return a.distance < b.distance end)
    return wreckages
end
function UnifiedWreckageCache.refreshCache(forceRefresh)
    local allWreckages = getCachedEntitiesByType(EntityType.Wreckage)
    local addedCount = 0
    local removedCount = 0
    local existingWreckages = {}
    
    -- Debug: Log cache refresh
    if forceRefresh and SALVAGE_DEBUG_ENABLED then
        print(string.format("[SALVAGE DEBUG] UnifiedWreckageCache.refreshCache: Found %d total wrecks in sector", #allWreckages))
    end
    for _, entity in ipairs(allWreckages) do
        if valid(entity) and entity:hasComponent(ComponentType.MineableMaterial) then
            local material = entity:getMineableMaterial()
            if material then
                local wreckageId = tostring(entity.index)
                existingWreckages[wreckageId] = true
                local existingData = wreckageCache[wreckageId]
                if not existingData or forceRefresh then
                    local resourceAmount = 0
                    for _, amount in pairs({entity:getMineableResources()}) do
                        resourceAmount = resourceAmount + amount
                    end
                    if resourceAmount >= CACHE_CONFIG.MIN_WRECKAGE_RESOURCES then
                        UnifiedWreckageCache.addWreckage(wreckageId, entity, material, resourceAmount)
                        addedCount = addedCount + 1
                        -- Debug: Log added wreckage
                        if forceRefresh and SALVAGE_DEBUG_ENABLED then
                            print(string.format("[SALVAGE DEBUG] Added wreckage %s with %d resources (material level %d)", wreckageId, resourceAmount, material.value))
                        end
                    end
                end
            end
        end
    end
    for wreckageId, _ in pairs(wreckageCache) do
        if not existingWreckages[wreckageId] then
            UnifiedWreckageCache.removeWreckage(wreckageId)
            removedCount = removedCount + 1
        end
    end
    return addedCount, removedCount
end
function UnifiedWreckageCache.cleanup()
    local cleanedCount = 0
    for wreckageId, wreckageData in pairs(wreckageCache) do
        local shouldRemove = false
        if not valid(wreckageData.entity) then
            shouldRemove = true
        else
            local resourcesLeft = 0
            local success, result = pcall(function()
                return wreckageData.entity:getMineableResources()
            end)
            if success and result then
                for _, amount in pairs({result}) do
                    resourcesLeft = resourcesLeft + amount
                end
            end
            if resourcesLeft < CACHE_CONFIG.MIN_WRECKAGE_RESOURCES then
                shouldRemove = true
            end
        end
        if shouldRemove then
            UnifiedWreckageCache.removeWreckage(wreckageId)
            cleanedCount = cleanedCount + 1
        end
    end
    return cleanedCount
end
function UnifiedWreckageCache.getStats()
    local total = 0
    local assigned = 0
    local unassigned = 0
    local invalid = 0
    for _, wreckageData in pairs(wreckageCache) do
        total = total + 1
        if wreckageData.assigned then
            assigned = assigned + 1
        else
            unassigned = unassigned + 1
        end
        if not wreckageData.isValid then
            invalid = invalid + 1
        end
    end
    return {
        total = total,
        assigned = assigned,
        unassigned = unassigned,
        invalid = invalid
    }
end
function UnifiedWreckageCache.getAllWreckages()
    return wreckageCache
end
function UnifiedWreckageCache.clear()
    wreckageCache = {}
    validationCache = {}
end
function UnifiedWreckageCache.forceRefreshValidation(wreckageId)
    validationCache[wreckageId] = nil
    return UnifiedWreckageCache.validateWreckage(wreckageId)
end
function UnifiedWreckageCache.forceRefreshNearbyValidation(centerPos, maxDistance)
    local refreshedCount = 0
    for wreckageId, wreckageData in pairs(wreckageCache) do
        if valid(wreckageData.entity) then
            local distance = distance2(wreckageData.translationf, centerPos)
            if distance <= maxDistance then
                validationCache[wreckageId] = nil
                UnifiedWreckageCache.validateWreckage(wreckageId)
                refreshedCount = refreshedCount + 1
            end
        end
    end
    return refreshedCount
end
function UnifiedWreckageCache.forceRefreshAllValidation()
    local refreshedCount = 0
    for wreckageId, _ in pairs(validationCache) do
        validationCache[wreckageId] = nil
        refreshedCount = refreshedCount + 1
    end
    return refreshedCount
end
function UnifiedWreckageCache.getUnassignedWreckages()
    local unassigned = {}
    local totalWreckages = 0
    local assignedWreckages = 0
    local invalidWreckages = 0
    for wreckageId, wreckageData in pairs(wreckageCache) do
        totalWreckages = totalWreckages + 1
        if wreckageData.assigned then
            assignedWreckages = assignedWreckages + 1
        elseif not UnifiedWreckageCache.validateWreckage(wreckageId) then
            invalidWreckages = invalidWreckages + 1
        else
            table.insert(unassigned, {
                id = wreckageId,
                data = wreckageData
            })
        end
    end
    return unassigned
end
return UnifiedWreckageCache
