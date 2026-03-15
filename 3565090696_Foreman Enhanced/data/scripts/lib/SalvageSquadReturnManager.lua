local SalvageSquadReturnManager = {}
function SalvageSquadReturnManager.returnSalvageSquads(factionIndex, callingPlayer, factionData, fms)
    local fData = factionData[factionIndex]
    if not fData then
        print("ERROR: SalvageSquadReturnManager.returnSalvageSquads - factionData[" .. tostring(factionIndex) .. "] is nil")
        return
    end
    fData.salvage = false
    fData.salvageStandbyMode = false -- Clear standby mode flag
    if fData.harvest == false then
        fms.clearFactionLootPickups(factionIndex)
    end
    for shipIndex, shipData in pairs(fData.ships) do
        fms.removeShipFromSalvageTargets(factionIndex, shipIndex, true)
        shipData.salvage = false
        local controller = FighterController(Uuid(shipIndex))
        for squadIndex, _ in pairs(shipData.salvageSquads) do
            local isAlsoMining = shipData.miningSquads and shipData.miningSquads[squadIndex] ~= nil
            local isCurrentlyMining = shipData.harvest and isAlsoMining
            if not isCurrentlyMining then
                controller:setSquadOrders(squadIndex, FighterOrders.Return, Uuid())
            end
        end
    end
    fms.factionOperationStopped(factionIndex, callingPlayer, false)
end
return SalvageSquadReturnManager
