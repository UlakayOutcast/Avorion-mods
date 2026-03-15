local MiningSquadReturnManager = {}
function MiningSquadReturnManager.returnMiningSquads(factionIndex, callingPlayer, factionData, fms)
    local fData = factionData[factionIndex]
    fData.harvest = false
    if fData.salvage == false then
        fms.clearFactionLootPickups(factionIndex)
    end
    for shipIndex, shipData in pairs(fData.ships) do
        fms.removeShipFromAsteroidTargets(factionIndex, shipIndex, true)
        shipData.harvest = false
        local controller = FighterController(Uuid(shipIndex))
        for squadIndex, _ in pairs(shipData.miningSquads) do
            local isAlsoSalvaging = shipData.salvageSquads and shipData.salvageSquads[squadIndex] ~= nil
            local isCurrentlySalvaging = shipData.salvage and isAlsoSalvaging
            if not isCurrentlySalvaging then
                controller:setSquadOrders(squadIndex, FighterOrders.Return, Uuid())
            end
        end
    end
    fms.factionOperationStopped(factionIndex, callingPlayer, true)
end
return MiningSquadReturnManager
