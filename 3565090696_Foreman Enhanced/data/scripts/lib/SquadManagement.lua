function getAsteroidSquadCount(asteroidIndex, asteroidTargets)
    local target = asteroidTargets[tostring(asteroidIndex)]
    if target == nil or target.ships == nil then return 0 end
    
    local count = 0
    for _, shipData in pairs(target.ships) do
        if shipData and shipData.squads then
            for _ in pairs(shipData.squads) do
                count = count + 1
            end
        end
    end
    return count
end

function getWreckageSquadCount(wreckageIndex, salvageAssignments)
    local assignment = salvageAssignments[wreckageIndex]
    if assignment and assignment.squads then
        return getTableLength(assignment.squads)
    end
    return 0
end

function getAsteroidWithLeastSquads(asteroidKeys, asteroids, miningFilters, commandingAsteroidMaterialLevel, squadMaxMaterial, asteroidTargets, validateAsteroidResources)
    local minSquads = math.huge
    local selectedKey = nil
    local selectedData = nil
    
    for _, key in pairs(asteroidKeys) do
        local data = asteroids[key]
        if data and miningFilters[data.material] == true and 
           (commandingAsteroidMaterialLevel == nil or commandingAsteroidMaterialLevel >= data.material) and 
           squadMaxMaterial >= data.material and validateAsteroidResources(key) then
            local squadCount = getAsteroidSquadCount(key, asteroidTargets)
            if squadCount < minSquads then
                minSquads = squadCount
                selectedKey = key
                selectedData = data
            end
        end
    end
    return selectedKey, selectedData
end
function getWreckageWithLeastSquads(wreckageKeys, miningFilters, squadMaxMaterial, salvageAssignments, validateWreckageResources)
    local minSquads = math.huge
    local selectedKey = nil
    local selectedData = nil
    for _, key in pairs(wreckageKeys) do
        local wreckage = Entity(Uuid(key))
        if valid(wreckage) then
            local wreckageMaterial = wreckage:getMineableMaterial()
            if wreckageMaterial and squadMaxMaterial >= wreckageMaterial.value and validateWreckageResources(key) then
                local squadCount = getWreckageSquadCount(key, salvageAssignments)
                if squadCount < minSquads then
                    minSquads = squadCount
                    selectedKey = key
                    selectedData = { translationf = wreckage.translationf }
                end
            end
        end
    end
    return selectedKey, selectedData
end
function getCurrentHelperCap(miningFilters)
    return 1000000
end
function getSquadsWithMiningFighters(shipId)
    local hangar = Hangar(shipId)
    local hangarSquads = {hangar:getSquads()}
    local squads = {}
    for _, squadIndex in pairs(hangarSquads) do
        if hangar:getSquadMainWeaponCategory(squadIndex) == WeaponCategory.Mining then
            table.insert(squads, squadIndex)
        end
    end
    return squads
end
function getSquadsWithSalvageFighters(shipId)
    local hangar = Hangar(shipId)
    local hangarSquads = {hangar:getSquads()}
    local squads = {}
    for _, squadIndex in pairs(hangarSquads) do
        if hangar:getSquadMainWeaponCategory(squadIndex) == WeaponCategory.Salvaging then
            table.insert(squads, squadIndex)
        end
    end
    return squads
end
local SquadManagement = {
    getAsteroidSquadCount = getAsteroidSquadCount,
    getWreckageSquadCount = getWreckageSquadCount,
    getAsteroidWithLeastSquads = getAsteroidWithLeastSquads,
    getWreckageWithLeastSquads = getWreckageWithLeastSquads,
    getCurrentHelperCap = getCurrentHelperCap,
    getSquadsWithMiningFighters = getSquadsWithMiningFighters,
    getSquadsWithSalvageFighters = getSquadsWithSalvageFighters
}
return SquadManagement
