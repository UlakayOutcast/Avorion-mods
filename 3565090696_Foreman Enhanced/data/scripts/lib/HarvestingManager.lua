local HarvestingManager = {}

-- Debug flag for mining filter debugging
local MINING_FILTER_DEBUG = false
function HarvestingManager.startHarvesting(factionIndex, starterPlayerIndex, commandingAsteroidMaterialLevel, inMiningFilters, factionData, asteroids, asteroidTargets, fms, ShipDataManager, AsteroidManagement, AsteroidUtils, getCachedEntitiesByType, getTableLength, MAX_SQUADS_PER_ASTEROID)
    ShipDataManager.initializeFactionData(factionData, getCachedEntitiesByType)
    local data = factionData[factionIndex]
    if data.harvest == true then return end
    
    -- Debug: Show incoming mining filters
    if MINING_FILTER_DEBUG then
        print("[FILTER DEBUG] HarvestingManager.startHarvesting - Incoming filters for faction " .. factionIndex .. ":")
        if inMiningFilters then
            for material, enabled in pairs(inMiningFilters) do
                print("[FILTER DEBUG]   Material " .. material .. ": " .. tostring(enabled) .. " (type: " .. type(enabled) .. ")")
            end
        else
            print("[FILTER DEBUG]   No mining filters provided!")
        end
    end
    
    data.commandingAsteroidMaterialLevel = commandingAsteroidMaterialLevel or 6
    data.miningFilters = inMiningFilters
    data.harvest = true
    AsteroidManagement.initializeAsteroids(asteroids, getCachedEntitiesByType, fms.invalidateAsteroidValidationCache)
    local hasAnyFilter = false
    for _, v in pairs(inMiningFilters) do
        if v == true then hasAnyFilter = true break end
    end
    if getTableLength(asteroids) == 0 or not hasAnyFilter then
        data.harvest = false
        return
    end
    for shipIndex, _ in pairs(data.ships) do
        ShipDataManager.checkAndCreateShipData(factionIndex, shipIndex, factionData)
    end
    AsteroidManagement.assignFactionMiningSquadsRandomly(factionIndex, inMiningFilters, factionData, asteroids, asteroidTargets, getCachedEntitiesByType, fms.invalidateAsteroidValidationCache, function(asteroidIndex) return AsteroidUtils.validateAsteroidResources(asteroidIndex, asteroids, fms._validationCacheValid, fms._asteroidValidationCache) end, fms.addSquadsToAsteroid, getTableLength, MAX_SQUADS_PER_ASTEROID)
    fms.factionOperationStarted(factionIndex, starterPlayerIndex, true)
end
return HarvestingManager
