package.path = package.path .. ";data/scripts/lib/?.lua"
include("EntityQueryCache")
function getMineableAsteroids(entityId, miningFilters, ignoreCargoSpace)
    local ship = Entity(entityId)
    if not valid(ship) then
        return {}
    end
    local freeCargoSpace = math.huge
    if valid(ship) and ship.freeCargoSpace ~= nil then
        if ignoreCargoSpace ~= nil and not ignoreCargoSpace then
            local success, cargoSpace = pcall(function()
                return ship.freeCargoSpace
            end)
            if success and cargoSpace then
                freeCargoSpace = cargoSpace
            end
        end
    end
    local highestHarvestableMaterial = nil
    if valid(ship) then
        local success, material = pcall(function()
            return getHighestMineableAsteroidMaterial(ship.id)
        end)
        if success then
            highestHarvestableMaterial = material
        end
    end
    local entities = getCachedEntitiesByType(EntityType.Asteroid)
    local list = {}
    local cargoThreshHold = (freeCargoSpace - 150) * 40
    for _, v in pairs(entities) do
        local function getEntityData(entity)
            if not valid(entity) then
                return nil
            end
            local success, resources = pcall(function()
                return {entity:getMineableResources()}
            end)
            if not success then return nil end
            local success2, material = pcall(function()
                return entity:getMineableMaterial()
            end)
            if not success2 or not material then return nil end
            local totalResources = 0
            for _, amount in pairs(resources) do
                totalResources = totalResources + amount
            end
            return {
                resources = totalResources,
                material = material,
                valid = true
            }
        end
        local data = getEntityData(v)
        if not data or data.resources <= 0 then
            goto continue
        end
        if v.isObviouslyMineable or (not v.isObviouslyMineable and highestHarvestableMaterial ~= nil and highestHarvestableMaterial >= data.material.value) then
            if miningFilters[data.material.value] == true and highestHarvestableMaterial >= data.material.value and cargoThreshHold >= data.resources then
                table.insert(list, v)
            end
        end
        ::continue::
    end
    return list
end
local miningScripts = {
    "data/scripts/systems/miningsystem.lua",
    "internal/dlc/rift/systems/miningcarrierhybrid.lua",
}
function getHighestMineableAsteroidMaterial(shipId)
    local entity = Entity(shipId)
    local system = ShipSystem(shipId)
    local highestMaterialLevel
    for upgrade, permanent in pairs(system:getUpgrades()) do
        for _, miningScript in pairs(miningScripts) do
            if upgrade.script == miningScript then
                local ret, materialLevel = entity:invokeFunction(miningScript, "getBonuses", upgrade.seed.int32, upgrade.rarity, permanent)
                if ret == 0 then
                    if highestMaterialLevel == nil or materialLevel > highestMaterialLevel then
                        highestMaterialLevel = materialLevel + 1
                    end
                end
            end
        end
    end
    return highestMaterialLevel
end
function hasMiningSystem(shipId)
    local ship = Entity(shipId)
    local shipSystem = ShipSystem(shipId)
    if ship == nil or shipSystem == nil then return false end
    local systems = {shipSystem:getUpgrades()}
    for _,v in pairs(systems) do
        if v.script == "data/scripts/systems/miningsystem.lua" then
            return true
        end
    end
    return false
end
function getWreckages(entityId, miningFilters, highestHarvestableMaterial, ignoreCargoSpace)
    if highestHarvestableMaterial == nil then return {} end
    local ship = Entity(entityId)
    if ship == nil then return {} end
    local freeCargoSpace = math.huge
    if ship.freeCargoSpace ~= nil then
        if ignoreCargoSpace ~= nil and not ignoreCargoSpace then
            freeCargoSpace = ship.freeCargoSpace
        end
    end
    local stations = getCachedEntitiesByType(EntityType.Station)
    local clamps = DockingClamps(entityId)
    local list = {}
    for _, v in pairs({Sector():getEntitiesByComponent(ComponentType.MineableMaterial)}) do
        if v.type ~= EntityType.Wreckage or (clamps and clamps:isDocked(v)) then goto continue end
        for _, s in pairs(stations) do
            if s:isInsideShield(v.translationf) then
                goto continue
            end
        end
        local function getWreckageData(entity)
            if not valid(entity) then
                return nil
            end
            local success, material = pcall(function()
                return entity:getMineableMaterial()
            end)
            if not success or not material then return nil end
            local success2, resources = pcall(function()
                return {entity:getMineableResources()}
            end)
            if not success2 then return nil end
            local totalResources = 0
            for _, amount in pairs(resources) do
                totalResources = totalResources + amount
            end
            return {
                material = material,
                resources = totalResources,
                valid = true
            }
        end
        local data = getWreckageData(v)
        if not data or data.resources <= 10 then
            goto continue
        end
        if miningFilters[data.material.value] == true and highestHarvestableMaterial + 1 >= data.material.value and freeCargoSpace > 100 then
            table.insert(list, v)
        end
        ::continue::
    end
    return list
end
function getHighestHarvestableMaterial(entityId)
    local entity = Entity(entityId)
    if entity == nil then
        return 0
    end
    local hangar = Hangar(entityId)
    local squads = {hangar:getSquads()}
    local highestHarvestableMaterial = nil
    for _, index in pairs(squads) do
        if hangar:getSquadMainWeaponCategory(index) == WeaponCategory.Mining then
            local squadHighestMaterial = hangar:getHighestMaterialInSquadMainCategory(index).value
            if highestHarvestableMaterial == nil or highestHarvestableMaterial < squadHighestMaterial + 1 then
                highestHarvestableMaterial = squadHighestMaterial + 1
            end
        end
    end
    return highestHarvestableMaterial
end
function getHighestSalvageableMaterial(entityId)
    local entity = Entity(entityId)
    if entity == nil then return 0 end
    local hangar = Hangar(entityId)
    local squads = {hangar:getSquads()}
    local highestHarvestableMaterial = nil
    for _, index in pairs(squads) do
        if hangar:getSquadMainWeaponCategory(index) == WeaponCategory.Salvaging then
            local squadHighestMaterial = hangar:getHighestMaterialInSquadMainCategory(index).value
            if highestHarvestableMaterial == nil or highestHarvestableMaterial < squadHighestMaterial + 1 then
                highestHarvestableMaterial = squadHighestMaterial + 1
            end
        end
    end
    return highestHarvestableMaterial
end
function getTableLength(table)
    if table == nil then return 0 end
    local length = 0
    for i,v in pairs(table) do
        length = length + 1
    end
    return length
end
function redToGreenGradient(percentage)
    local r = 1
    local g = 1
    if percentage > 0.5 then
        r = 1 - (2 * (percentage - 0.5))
    else
        g = 1 - (2 * (1 - percentage - 0.5))
    end
    return ColorRGB(r,g,0)
end
function getUpdateInterval()
    return 0.2
end
local ForemanLib = {
    getUpdateInterval = getUpdateInterval,
    getMineableAsteroids = getMineableAsteroids,
    getHighestMineableAsteroidMaterial = getHighestMineableAsteroidMaterial,
    hasMiningSystem = hasMiningSystem,
    getWreckages = getWreckages,
    getHighestHarvestableMaterial = getHighestHarvestableMaterial,
    getHighestSalvageableMaterial = getHighestSalvageableMaterial,
    getTableLength = getTableLength,
    redToGreenGradient = redToGreenGradient
}
return ForemanLib
