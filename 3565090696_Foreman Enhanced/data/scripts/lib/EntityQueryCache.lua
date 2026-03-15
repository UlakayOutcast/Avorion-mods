package.path = package.path .. ";data/scripts/lib/?.lua"
local _entityCache = {
    entities = {},
    lastUpdate = 0,
    cacheLifetime = 0.5, -- Cache for 0.5 seconds
    entityTypes = {
        [EntityType.Ship] = {},
        [EntityType.Station] = {},
        [EntityType.Asteroid] = {},
        [EntityType.Fighter] = {},
        [EntityType.Loot] = {},
        [EntityType.Wreckage] = {}
    }
}
local _cacheInvalidated = false
function initializeEntityCache()
    _entityCache.lastUpdate = 0
    _cacheInvalidated = true
end
function invalidateEntityCache()
    _cacheInvalidated = true
end
function getCachedEntitiesByType(entityType)
    local currentTime = os.clock()
    if _cacheInvalidated or (currentTime - _entityCache.lastUpdate) > _entityCache.cacheLifetime then
        -- Add error handling to prevent threading issues
        local success, error = pcall(function()
            refreshEntityCache()
        end)
        if not success then
            print("[ERROR] Failed to refresh entity cache:", error)
            -- Return empty table if cache refresh fails
            return {}
        end
    end
    return _entityCache.entityTypes[entityType] or {}
end
function refreshEntityCache()
    local currentTime = os.clock()
    for entityType, _ in pairs(_entityCache.entityTypes) do
        _entityCache.entityTypes[entityType] = {}
    end
    
    -- Add error handling to prevent crashes during entity access
    local function safeGetEntities(entityType)
        local success, entities = pcall(function()
            return {Sector():getEntitiesByType(entityType)}
        end)
        if success then
            return entities
        else
            return {}
        end
    end
    
    local allEntities = safeGetEntities(EntityType.Ship)
    for _, entity in pairs(allEntities) do
        if valid(entity) then
            table.insert(_entityCache.entityTypes[EntityType.Ship], entity)
        end
    end
    allEntities = safeGetEntities(EntityType.Station)
    for _, entity in pairs(allEntities) do
        if valid(entity) then
            table.insert(_entityCache.entityTypes[EntityType.Station], entity)
        end
    end
    allEntities = safeGetEntities(EntityType.Asteroid)
    for _, entity in pairs(allEntities) do
        if valid(entity) then
            table.insert(_entityCache.entityTypes[EntityType.Asteroid], entity)
        end
    end
    allEntities = safeGetEntities(EntityType.Fighter)
    for _, entity in pairs(allEntities) do
        if valid(entity) then
            table.insert(_entityCache.entityTypes[EntityType.Fighter], entity)
        end
    end
    allEntities = safeGetEntities(EntityType.Loot)
    for _, entity in pairs(allEntities) do
        if valid(entity) then
            table.insert(_entityCache.entityTypes[EntityType.Loot], entity)
        end
    end
    allEntities = safeGetEntities(EntityType.Wreckage)
    for _, entity in pairs(allEntities) do
        if valid(entity) then
            table.insert(_entityCache.entityTypes[EntityType.Wreckage], entity)
        end
    end
    _entityCache.lastUpdate = currentTime
    _cacheInvalidated = false
end
function getCachedEntitiesByTypes(entityTypes)
    local currentTime = os.clock()
    if _cacheInvalidated or (currentTime - _entityCache.lastUpdate) > _entityCache.cacheLifetime then
        refreshEntityCache()
    end
    local result = {}
    for _, entityType in pairs(entityTypes) do
        result[entityType] = _entityCache.entityTypes[entityType] or {}
    end
    return result
end
function getCachedEntitiesByTypeAndFaction(entityType, factionIndex)
    local entities = getCachedEntitiesByType(entityType)
    local filtered = {}
    for _, entity in pairs(entities) do
        if entity.factionIndex == factionIndex then
            table.insert(filtered, entity)
        end
    end
    return filtered
end
function getCachedPlayerOwnedEntities(entityType)
    local entities = getCachedEntitiesByType(entityType)
    local filtered = {}
    for _, entity in pairs(entities) do
        if entity.playerOrAllianceOwned then
            table.insert(filtered, entity)
        end
    end
    return filtered
end
function getEntityCacheStats()
    return {
        lastUpdate = _entityCache.lastUpdate,
        cacheAge = os.clock() - _entityCache.lastUpdate,
        isInvalidated = _cacheInvalidated,
        entityCounts = {
            ships = #(_entityCache.entityTypes[EntityType.Ship] or {}),
            stations = #(_entityCache.entityTypes[EntityType.Station] or {}),
            asteroids = #(_entityCache.entityTypes[EntityType.Asteroid] or {}),
            fighters = #(_entityCache.entityTypes[EntityType.Fighter] or {}),
            loot = #(_entityCache.entityTypes[EntityType.Loot] or {}),
            wreckages = #(_entityCache.entityTypes[EntityType.Wreckage] or {})
        }
    }
end
