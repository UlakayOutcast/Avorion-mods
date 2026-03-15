local SalvageSquadManager = {}
local SalvageWorkAreaManager = include("SalvageWorkAreaManager")
function SalvageSquadManager.assignSalvageSquadsOptimally(factionIndex, shipIndex, miningFilters, factionData, fms, getWreckages, getHighestSalvageableMaterial, getTableLength)
    local salvageSquads = factionData[factionIndex].ships[tostring(shipIndex)].salvageSquads
    local ship = Entity(Uuid(shipIndex))
    local controller = FighterController(Uuid(shipIndex))
     local hangar = Hangar(ship.id)
    local wreckages = getWreckages(shipIndex, miningFilters, getHighestSalvageableMaterial(shipIndex), true)
    local squadsNum = getTableLength(salvageSquads)
    local wreckagesNum = getTableLength(wreckages)
    if wreckagesNum == 0 then
        return
    end
    local shipWentActive = false
    local shipPos = ship.translationf
    local assignedSquads = {}
    local assignedWreckages = {}
    
    -- Use asteroid-style distribution logic
    if wreckagesNum >= squadsNum then
        -- More wreckages than squads: try to give each squad a unique target
        local wreckageKeys = {}
        for _, wreckage in pairs(wreckages) do
            if valid(wreckage) then
                table.insert(wreckageKeys, tostring(wreckage.index))
            end
        end
        
        for i, rawSquad in pairs(salvageSquads) do
            if assignedSquads[i] then goto continue end
            if rawSquad and ship.freeCargoSpace <= 150 then
                goto continue
            end
            
            local squadMaxMaterial = hangar:getHighestMaterialInSquadMainCategory(i).value + 3
            local targetWreckage = nil
            local selectedKey = nil
            local retryCount = 3
            
            while retryCount > 0 and selectedKey == nil do
                retryCount = retryCount - 1
                local candidateKey = wreckageKeys[math.random(#wreckageKeys)]
                for _, wreckage in pairs(wreckages) do
                    if tostring(wreckage.index) == candidateKey and valid(wreckage) and not assignedWreckages[candidateKey] then
                        local wreckageMaterial = wreckage:getMineableMaterial()
                        if wreckageMaterial and squadMaxMaterial >= wreckageMaterial.value then
                            local SalvageWorkAreaManager = include("SalvageWorkAreaManager")
                            local UnifiedWreckageCache = include("UnifiedWreckageCache")
                            local wreckageData = UnifiedWreckageCache.getWreckage(candidateKey)
                            if not wreckageData or not wreckageData.assigned then
                                selectedKey = candidateKey
                                targetWreckage = wreckage
                                break
                            end
                        end
                    end
                end
            end
            
            if targetWreckage and valid(targetWreckage) then
                assignedSquads[i] = true
                assignedWreckages[selectedKey] = true
                shipWentActive = true
                local squadId = string.format("%s_%d", shipIndex, i)
                SalvageWorkAreaManager.assignSquadToTarget(squadId, selectedKey, targetWreckage.translationf)
                fms.addSquadsToWreckage(targetWreckage.index, targetWreckage.translationf, factionIndex, shipIndex, { i })
                controller:setSquadOrders(i, FighterOrders.Attack, targetWreckage.id)
            else
                controller:setSquadOrders(i, FighterOrders.Return, Uuid())
            end
            ::continue::
        end
    else
        -- Fewer wreckages than squads: distribute squads evenly across available targets
        local remainingKeys = {}
        for _, wreckage in pairs(wreckages) do
            if valid(wreckage) then
                table.insert(remainingKeys, tostring(wreckage.index))
            end
        end
        
        for i, rawSquad in pairs(salvageSquads) do
            if assignedSquads[i] then goto continue end
            if rawSquad and ship.freeCargoSpace <= 150 then
                goto continue
            end
            
            local squadMaxMaterial = hangar:getHighestMaterialInSquadMainCategory(i).value + 3
            local selectedKey, targetWreckage = SquadManagement.getWreckageWithLeastSquads(remainingKeys, miningFilters, squadMaxMaterial, {}, function(id) return true end)
            
            if targetWreckage and valid(targetWreckage) then
                assignedSquads[i] = true
                shipWentActive = true
                local squadId = string.format("%s_%d", shipIndex, i)
                SalvageWorkAreaManager.assignSquadToTarget(squadId, selectedKey, targetWreckage.translationf)
                fms.addSquadsToWreckage(targetWreckage.index, targetWreckage.translationf, factionIndex, shipIndex, { i })
                controller:setSquadOrders(i, FighterOrders.Attack, targetWreckage.id)
            else
                controller:setSquadOrders(i, FighterOrders.Return, Uuid())
            end
            ::continue::
        end
    end
    
    factionData[factionIndex].ships[tostring(shipIndex)].salvage = shipWentActive
    factionData[factionIndex].ships[tostring(shipIndex)].isActive = shipWentActive
end
function SalvageSquadManager.assignSalvageSquadsRandomly(factionIndex, shipIndex, miningFilters, factionData, fms, getWreckages, getHighestSalvageableMaterial, getTableLength)
    return SalvageSquadManager.assignSalvageSquadsOptimally(factionIndex, shipIndex, miningFilters, factionData, fms, getWreckages, getHighestSalvageableMaterial, getTableLength)
end
return SalvageSquadManager
