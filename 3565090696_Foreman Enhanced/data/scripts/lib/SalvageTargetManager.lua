local SalvageTargetManager = {}

function SalvageTargetManager.clearSalvageTarget(wreckageIndex, salvageTargets)
    if salvageTargets[wreckageIndex] == nil or salvageTargets[wreckageIndex].ships == nil then 
        return 
    end
    
    for i, v in pairs(salvageTargets[wreckageIndex].ships) do
        if not v.squads then return end
        for _, j in pairs(v.squads) do
            salvageTargets[wreckageIndex].ships[i].squads[j] = nil
        end
        salvageTargets[wreckageIndex].ships[i].squads = nil
        salvageTargets[wreckageIndex].ships[i] = nil
    end
    
    salvageTargets[wreckageIndex].ships = nil
    salvageTargets[wreckageIndex] = nil
end

function SalvageTargetManager.clearSalvageTargets(salvageTargets)
    for a, _ in pairs(salvageTargets) do
        for i, v in pairs(salvageTargets[a].ships) do
            if not v.squads then return end
            for _, j in pairs(v.squads) do
                salvageTargets[a].ships[i].squads[j] = nil
            end
            salvageTargets[a].ships[i].squads = nil
            salvageTargets[a].ships[i] = nil
        end
        salvageTargets[a].ships = nil
        salvageTargets[a] = nil
    end
end
function SalvageTargetManager.addSquadsToWreckage(wreckageIndex, translationf, factionIndex, shipIndex, squadsToAdd, salvageTargets)
    if salvageTargets[tostring(wreckageIndex)] == nil then
        salvageTargets[tostring(wreckageIndex)] = { index = wreckageIndex, translationf = translationf, ships = {} }
    end
    if salvageTargets[tostring(wreckageIndex)].ships[tostring(shipIndex)] == nil then
        salvageTargets[tostring(wreckageIndex)].ships[tostring(shipIndex)] = { factionIndex = factionIndex, shipIndex = shipIndex, squads = {} }
    end
    for _, i in pairs(squadsToAdd) do
        table.insert(salvageTargets[tostring(wreckageIndex)].ships[tostring(shipIndex)].squads, i)
    end
end
function SalvageTargetManager.removeSalvageTarget(wreckageIndex, salvageTargets)
    if salvageTargets[tostring(wreckageIndex)] then
        for _,v in pairs(salvageTargets[tostring(wreckageIndex)].ships) do
            v.squads = nil
        end
        salvageTargets[tostring(wreckageIndex)].ships = nil
        salvageTargets[tostring(wreckageIndex)] = nil
    end
end
function SalvageTargetManager.getSalvageTargetCount()
    if not (Player() and Player().craft) then
        return 0
    end
    
    -- For client-side compatibility, count wreckages directly
    local sector = Sector()
    if not sector then return 0 end
    
    local wreckages = {sector:getEntitiesByType(EntityType.Wreckage)}
    local count = 0
    
    for _, entity in pairs(wreckages) do
        if valid(entity) and entity:hasComponent(ComponentType.MineableMaterial) then
            local resources = 0
            for _, amount in pairs({entity:getMineableResources()}) do
                resources = resources + amount
            end
            if resources >= 1 then
                count = count + 1
            end
        end
    end
    
    return count
end
return SalvageTargetManager
