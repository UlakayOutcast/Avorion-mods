local AsteroidUtils = {}

-- Debug flag - set to true to enable debug output
local DEBUG_ASTEROID = false

-- Debug print function
local function debugPrint(...)
    if DEBUG_ASTEROID then
        print("Foreman:", ...)
    end
end

function AsteroidUtils.validateAsteroidResources(asteroidIndex, asteroids, validationCacheValid, asteroidValidationCache)
    return AsteroidValidation.validateAsteroidResources(asteroidIndex, asteroids, validationCacheValid, asteroidValidationCache)
end

function AsteroidUtils.invalidateValidationCache(validationCacheRef)
    validationCacheRef._validationCacheValid = false
end

function AsteroidUtils.countEligibleAsteroidsByFilter(miningFilters, asteroids)
    local c = 0
    for k, v in pairs(asteroids) do
        if miningFilters[v.material] ~= false then c = c + 1 end
    end
    return c
end

function AsteroidUtils.getMineableAmountInVicinity(ignoreCargoSpace, perOre, mineableCache, foremanMaterialLevel, miningFilters)
    if not (Player() and Player().craft) then
        return 0
    end
    mineableCache = mineableCache or { 
        t = 0, 
        total = 0, 
        count = 0, 
        perOre = { [0] = 0,[1] = 0,[2] = 0,[3] = 0,[4] = 0,[5] = 0,[6] = 0 },
        asteroidData = {},
        lastAsteroidCount = 0,
        filtersChanged = false,
        lastUpdateTime = 0,
        asteroidHashes = {}
    }
    local needsRecalculation = false
    local currentTime = os.clock()
    if mineableCache.filtersChanged then
        needsRecalculation = true
        mineableCache.filtersChanged = false
    end
    if not needsRecalculation and mineableCache.lastUpdateTime > 0 then
        local cacheAge = currentTime - mineableCache.lastUpdateTime
        if cacheAge > 10.0 then
            needsRecalculation = true
        end
    end
    local entities = getCachedEntitiesByType(EntityType.Asteroid)
    local currentAsteroidCount = #entities
    debugPrint("[DEBUG] getMineableAmountInVicinity - found", currentAsteroidCount, "asteroids in sector")
    
    -- If no entities found, try to refresh cache and try again
    if currentAsteroidCount == 0 then
        debugPrint("[DEBUG] No asteroids found, refreshing cache...")
        if invalidateEntityCache then invalidateEntityCache() end
        entities = getCachedEntitiesByType(EntityType.Asteroid)
        currentAsteroidCount = #entities
        debugPrint("[DEBUG] getMineableAmountInVicinity - after cache refresh, found", currentAsteroidCount, "asteroids in sector")
    end
    if not needsRecalculation and currentAsteroidCount ~= mineableCache.lastAsteroidCount then
        needsRecalculation = true
    end
    if not needsRecalculation then
        if perOre then
            return mineableCache.total, mineableCache.count, mineableCache.perOre
        else
            return mineableCache.total, mineableCache.count
        end
    end
    local total = 0
    local asteroidCount = 0
    local oreAmount = { [0] = 0, [1] = 0, [2] = 0, [3] = 0, [4] = 0, [5] = 0, [6] = 0 }
    local newAsteroidData = {}
    local newAsteroidHashes = {}
    debugPrint("[DEBUG] Processing", currentAsteroidCount, "asteroids...")
    debugPrint("[DEBUG] Mining filters:")
    for k, v in pairs(miningFilters) do
        debugPrint("[DEBUG]   ", k, "=", v)
    end
    debugPrint("[DEBUG] Foreman material level:", foremanMaterialLevel)
    
    for _, v in pairs(entities) do
        local function getAsteroidData(entity)
            if not valid(entity) then
                return nil
            end
            local success, resources = pcall(function() 
                return {entity:getMineableResources()} 
            end)
            if not success then return nil end
            local amount = 0
            for _, j in pairs(resources) do
                amount = amount + j
            end
            if amount <= 0 then return nil end
            local success2, material = pcall(function() 
                return entity:getMineableMaterial() 
            end)
            if not success2 or not material then return nil end
            local success3, translation = pcall(function() 
                return entity.translationf 
            end)
            if not success3 or not translation then return nil end
            return {
                amount = amount,
                material = material,
                translation = translation,
                valid = true
            }
        end
        local data = getAsteroidData(v)
        if not data then
            debugPrint("[DEBUG] Asteroid data invalid for entity", v.index)
            goto continue
        end
        local asteroidKey = tostring(v.index)
        asteroidCount = asteroidCount + 1
        local contentHash = string.format("%.2f_%.2f_%.2f_%d", 
            data.translation.x, data.translation.y, data.translation.z, data.amount)
        newAsteroidHashes[asteroidKey] = contentHash
        newAsteroidData[asteroidKey] = {
            x = data.translation.x,
            y = data.translation.y,
            z = data.translation.z,
            amount = data.amount,
            material = nil -- Will be set below if needed
        }
        
        debugPrint("[DEBUG] Asteroid", asteroidKey, "- material:", data.material.value, "amount:", data.amount, "obviouslyMineable:", v.isObviouslyMineable)
        debugPrint("[DEBUG] Filter check - miningFilters[", data.material.value, "] =", miningFilters[data.material.value])
        debugPrint("[DEBUG] Filter condition result:", (miningFilters[data.material.value] ~= false))
        
        if data.material ~= nil and (miningFilters[data.material.value] ~= false) and (v.isObviouslyMineable or (not v.isObviouslyMineable and (foremanMaterialLevel == nil or foremanMaterialLevel >= data.material.value))) then
            total = total + data.amount
            newAsteroidData[asteroidKey].material = data.material.value
            debugPrint("[DEBUG] ACCEPTED asteroid - material:", data.material.value, "amount:", data.amount, "total now:", total)
            if perOre then
                oreAmount[data.material.value] = oreAmount[data.material.value] + data.amount
            end
        else
            if data.material then
                debugPrint("[DEBUG] REJECTED asteroid - material:", data.material.value, "filter:", miningFilters[data.material.value], "obviouslyMineable:", v.isObviouslyMineable, "foremanLevel:", foremanMaterialLevel)
            end
        end
        ::continue::
    end
    mineableCache.t = currentTime
    mineableCache.total = total
    mineableCache.count = asteroidCount
    mineableCache.perOre = oreAmount
    mineableCache.asteroidData = newAsteroidData
    mineableCache.lastAsteroidCount = currentAsteroidCount
    mineableCache.filtersChanged = false
    mineableCache.lastUpdateTime = currentTime
    mineableCache.asteroidHashes = newAsteroidHashes
    
    debugPrint("[DEBUG] FINAL RESULT - total:", total, "asteroidCount:", asteroidCount)
    debugPrint("[DEBUG] Per-ore amounts:")
    for k, v in pairs(oreAmount) do
        if v > 0 then
            debugPrint("[DEBUG]   Material", k, "=", v)
        end
    end
    
    if perOre then
        return total, asteroidCount, oreAmount
    else
        return total, asteroidCount
    end
end
return AsteroidUtils
