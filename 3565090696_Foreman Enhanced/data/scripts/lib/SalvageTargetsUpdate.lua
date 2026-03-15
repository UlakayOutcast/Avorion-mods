local SalvageTargetsUpdate = {}
local SalvageWorkAreaManager = include("SalvageWorkAreaManager")
local UnifiedWreckageCache = include("UnifiedWreckageCache")
local SalvageTargetManager = include("SalvageTargetManager")

function SalvageTargetsUpdate.updateSalvageTargets(
    timeStep, 
    factionData, 
    salvageTargets, 
    salvageCheckTimeleft, 
    salvageCheckInterval,
    TARGET_THRESHOLD,
    SMART_SCAN_INTERVAL,
    FAST_ASSIGNMENT_INTERVAL,
    SALVAGE_DEBUG_ENABLED,
    smartScanActive,
    lastSmartScan,
    lastFastAssignment,
    appTime,
    onServer,
    getTableLength,
    getAvailableTargetCount,
    refreshWreckageCache,
    validateWreckageResources,
    removeSquadFromWreckage,
    assignSquadToWreckage,
    fms,
    MIN_WRECKAGE_RESOURCES
)
    local wreckagesSalvaged = {}
    local anyShipJumping = false
    for factionIndex, fData in pairs(factionData) do
        if fData.salvage then
            for shipIndex, shipData in pairs(fData.ships) do
                if shipData.isJumping then
                    anyShipJumping = true
                    break
                end
            end
            if anyShipJumping then break end
        end
    end
    if anyShipJumping then
        return -- Don't do any salvage operations if any ship is jumping
    end
    local currentTime = appTime()
    local availableTargets = getAvailableTargetCount()
    if availableTargets < TARGET_THRESHOLD then
        smartScanActive = true
    end
    if smartScanActive and (currentTime - lastSmartScan) >= SMART_SCAN_INTERVAL then
        lastSmartScan = currentTime
        refreshWreckageCache(false) -- Don't force refresh, just update cache
        availableTargets = getAvailableTargetCount()
        if availableTargets >= TARGET_THRESHOLD then
            smartScanActive = false
        end
    end
    if (currentTime - lastFastAssignment) >= FAST_ASSIGNMENT_INTERVAL then
        lastFastAssignment = currentTime
        for factionIndex, fData in pairs(factionData) do
            if fData.salvage and fData.salvageStandbyMode then
                if not anyShipJumping then
                    fms.assignIdleFightersToTargets(factionIndex)
                end
            end
        end
    end
    salvageCheckTimeleft = salvageCheckTimeleft - timeStep
    if salvageCheckTimeleft <= 0 then
        salvageCheckTimeleft = salvageCheckInterval
        for factionIndex, fData in pairs(factionData) do
            if fData.salvage then
                if not anyShipJumping then
                    if fData.salvageStandbyMode then
                        fms.assignStandbyFightersToTargets(factionIndex)
                    else
                        fms.startSalvagingPeriodic(factionIndex)
                    end
                end
            end
        end
    end
    if getTableLength(salvageTargets) == 0 then
        for factionIndex, fData in pairs(factionData) do
            if fData.salvage then
                if not fData.salvageStandbyMode then
                    if not anyShipJumping then
                        for shipIndex, shipData in pairs(fData.ships) do
                            if shipData.salvage and shipData.salvageSquads then
                                local controller = FighterController(Uuid(shipIndex))
                                if controller then
                                    for squadIndex, _ in pairs(shipData.salvageSquads) do
                                        local isAlsoMining = shipData.miningSquads and shipData.miningSquads[squadIndex] ~= nil
                                        local isCurrentlyMining = shipData.harvest and isAlsoMining
                                        if not isCurrentlyMining then
                                            controller:setSquadOrders(squadIndex, FighterOrders.Defend, Uuid(shipIndex))
                                        end
                                    end
                                end
                            end
                        end
                    end
                else
                end
            end
        end
        return
    end
    local wreckagesToRemove = {}
    for wreckageId, wreckageData in pairs(salvageTargets) do
        local wreckageIndex = Uuid(wreckageId)
        local wreckage = Entity(wreckageIndex)
        local resourcesLeft = 0
        if valid(wreckage) then
            for _, j in pairs({wreckage:getMineableResources()}) do
                resourcesLeft = resourcesLeft + j
            end
        end
        if resourcesLeft < MIN_WRECKAGE_RESOURCES then
            table.insert(wreckagesSalvaged, wreckageId)
            for _, shipData in pairs(wreckageData.ships) do
                local shipIndex = shipData.shipIndex
                for squadIndex, _ in pairs(shipData.squads) do
                    removeSquadFromWreckage(wreckageId, shipIndex, squadIndex)
                end
            end
            table.insert(wreckagesToRemove, wreckageId)
            for _, shipData in pairs(wreckageData.ships) do
                local shipIndex = shipData.shipIndex
                local ship = Entity(shipIndex)
                local cargoSpaceLeft = ship.freeCargoSpace >= 150
                local controller = FighterController(shipIndex)
                local newTargetIndex = nil
                local bestTarget = nil
                local bestDistance = math.huge
                local unassigned = UnifiedWreckageCache.getUnassignedWreckages()
                for _, wreckage in ipairs(unassigned) do
                    if wreckage and wreckage.data and wreckage.data.material then
                        local material = wreckage.data.material
                        if factionData[shipData.factionIndex].miningFilters[material.value] == true then
                            if validateWreckageResources(wreckage.id) then
                                local distance = distance2(wreckage.data.translationf, wreckageData.translationf)
                                if distance < bestDistance then
                                    bestDistance = distance
                                    bestTarget = Uuid(wreckage.id)
                                end
                            end
                        end
                    end
                end
                if bestTarget then
                    newTargetIndex = bestTarget
                end
                if newTargetIndex == nil then 
                    goto continue 
                end
                local newWreckage = Entity(newTargetIndex)
                for _, index in pairs(shipData.squads) do
                    local rawSquad = shipData.squads[index]
                    if newWreckage then
                        local squadKey = string.format("%s_%d", shipIndex, index)
                        UnifiedWreckageCache.unassignSquadFromWreckage(wreckageId, squadKey)
                        local squadId = string.format("%s_%d", shipIndex, index)
                        local squadKey = string.format("%s_%d", shipIndex, index)
                        UnifiedWreckageCache.assignSquadToWreckage(tostring(newWreckage.index), squadKey)
                        if rawSquad then
                            if cargoSpaceLeft then
                                controller:setSquadOrders(index, FighterOrders.Attack, newWreckage.id)
                                fms.addSquadsToWreckage(newWreckage.index, newWreckage.translationf, shipData.factionIndex, shipIndex, { index })
                            end
                        else
                            controller:setSquadOrders(index, FighterOrders.Attack, newWreckage.id)
                            fms.addSquadsToWreckage(newWreckage.index, newWreckage.translationf, shipData.factionIndex, shipIndex, { index })
                        end
                    end
                end
                ::continue::
            end
        end
    end
    if #wreckagesToRemove > 0 then
        for _, wreckageId in pairs(wreckagesToRemove) do
            fms.removeWreckage(wreckageId)
        end
        UnifiedWreckageCache = include("UnifiedWreckageCache")
        UnifiedWreckageCache.refreshCache(true)
    end
    if #wreckagesSalvaged > 0 then
        for _,v in pairs(wreckagesSalvaged) do
            SalvageTargetManager.clearSalvageTarget(v, salvageTargets)
        end
    end
    local currentTime = appTime()
    local reassertInterval = 10 -- Only reassert every 10 seconds instead of every 3 seconds
    if not SalvageTargetsUpdate._lastReassertion then
        SalvageTargetsUpdate._lastReassertion = {}
    end
    for wreckageId, wreckageData in pairs(salvageTargets) do
        local wIndex = Uuid(wreckageId)
        local wreck = Entity(wIndex)
        if valid(wreck) then
            for shipId, shipEntry in pairs(wreckageData.ships or {}) do
                local ship = Entity(Uuid(shipId))
                if valid(ship) then
                    local fIdx = shipEntry.factionIndex or ship.factionIndex
                    local sData = factionData[fIdx] and factionData[fIdx].ships and factionData[fIdx].ships[tostring(shipId)] or nil
                    if sData and not sData.isJumping then
                        local controller = FighterController(Uuid(shipId))
                        local hangar = Hangar(Uuid(shipId))
                        if controller and hangar then
                            for _, squadIndex in pairs(shipEntry.squads or {}) do
                                local isRaw = sData.salvageSquads and sData.salvageSquads[squadIndex]
                                if (not isRaw) or (ship.freeCargoSpace >= 150) then
                                    local squadKey = string.format("%s_%d_%s", shipId, squadIndex, wreckageId)
                                    local lastReassert = SalvageTargetsUpdate._lastReassertion[squadKey] or 0
                                    if (currentTime - lastReassert) >= reassertInterval then
                                        controller:setSquadOrders(squadIndex, FighterOrders.Attack, wIndex)
                                        SalvageTargetsUpdate._lastReassertion[squadKey] = currentTime
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
    end
end
return SalvageTargetsUpdate
