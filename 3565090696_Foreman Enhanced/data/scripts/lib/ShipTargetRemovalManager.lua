local ShipTargetRemovalManager = {}
function ShipTargetRemovalManager.removeShipFromAsteroidTargets(factionIndex, inShipIndex, returnNormalSquads, asteroidTargets, factionData, getSquadsWithMiningFighters, getTableLength)
    local miningSquadsNum = getTableLength(getSquadsWithMiningFighters(Uuid(inShipIndex)))
    local miningSquadsToRemove = {}
    for asteroidIndex, asteroidData in pairs(asteroidTargets) do
        for shipIndex, shipData in pairs(asteroidData.ships) do
            if shipIndex == inShipIndex then
                local ship = Entity(Uuid(shipIndex))
                local controller = FighterController(Uuid(shipIndex))
                if returnNormalSquads then
                    for index, squadIndex in pairs(shipData.squads) do
                        table.insert(miningSquadsToRemove, squadIndex)
                        shipData.squads[squadIndex] = nil
                    end
                    asteroidData.ships[shipIndex] = nil
                else
                    for index, squadIndex in pairs(shipData.squads) do
                        local rawSquad = shipData.squads[index]
                        if rawSquad then
                            table.insert(miningSquadsToRemove, squadIndex)
                            if controller then
                                controller:setSquadOrders(squadIndex, FighterOrders.Defend, ship.id)
                            end
                            shipData.squads[index] = nil
                        end
                    end
                    if getTableLength(asteroidData.ships[shipIndex].squads) == 0 then
                        asteroidData.ships[shipIndex] = nil
                    end
                end
            end
        end
        if getTableLength(asteroidTargets[asteroidIndex].ships) == 0 then
            asteroidTargets[asteroidIndex] = nil
        end
    end
    local shipData = factionData[factionIndex].ships[tostring(inShipIndex)]
    if getTableLength(miningSquadsToRemove) == miningSquadsNum then
        shipData.harvest = false
    end
    if shipData.harvest == false and shipData.salvage == false then
        shipData.isActive = false
    end
end
function ShipTargetRemovalManager.removeShipFromSalvageTargets(factionIndex, inShipIndex, returnNormalSquads, salvageTargets, factionData, getSquadsWithSalvageFighters, getTableLength)
    local controller = FighterController(inShipIndex)
    local salvagingSquadsNum = getTableLength(getSquadsWithSalvageFighters(inShipIndex))
    local salvagingSquadsToRemove = {}
    for wreckageIndex, wreckageData in pairs(salvageTargets) do
        for shipIndex, shipData in pairs(wreckageData.ships) do
            if shipIndex == inShipIndex then
                local ship = Entity(shipIndex)
                for i,_ in pairs(shipData.squads) do
                    local rawSquad = shipData.squads[i]
                    if returnNormalSquads then
                        table.insert(salvagingSquadsToRemove, i)
                        if controller then
                            controller:setSquadOrders(i, FighterOrders.Defend, ship.id)
                        end
                        shipData.squads[i] = nil
                    else
                        if rawSquad then
                            table.insert(salvagingSquadsToRemove, i)
                            if controller then
                                controller:setSquadOrders(i, FighterOrders.Defend, ship.id)
                            end
                            shipData.squads[i] = nil
                        end
                    end
                end
                if getTableLength(wreckageData.ships[shipIndex].squads) == 0 then
                    wreckageData.ships[shipIndex] = nil
                end
            end
        end
        if getTableLength(salvageTargets[wreckageIndex].ships) == 0 then
            salvageTargets[wreckageIndex] = nil
        end
    end
    local shipData = factionData[factionIndex].ships[tostring(inShipIndex)]
    if getTableLength(salvagingSquadsToRemove) == salvagingSquadsNum then
        shipData.salvage = false
    end
    if shipData.harvest == false and shipData.salvage == false then
        shipData.isActive = false
    end
end
return ShipTargetRemovalManager
