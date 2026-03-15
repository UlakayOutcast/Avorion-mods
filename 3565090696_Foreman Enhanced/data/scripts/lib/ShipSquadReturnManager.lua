local ShipSquadReturnManager = {}

function ShipSquadReturnManager.returnShipSquads(factionIndex, shipIds, factionData, fms)
    local fData = factionData[factionIndex]
    if not fData then return end
    
    for _, shipId in pairs(shipIds) do
        local shipData = fData.ships[shipId]
        if shipData then
            local hasActiveMining = shipData.harvest and getTableLength(shipData.miningSquads or {}) > 0
            local hasActiveSalvage = shipData.salvage and getTableLength(shipData.salvageSquads or {}) > 0
            
            if hasActiveMining or hasActiveSalvage then
                fms.removeShipFromAsteroidTargets(factionIndex, shipId, true)
                fms.removeShipFromSalvageTargets(factionIndex, shipId, true)
                shipData.harvest = false
                shipData.salvage = false
                
                local controller = FighterController(Uuid(shipId))
                if controller then
                    for squadIndex, hasRawFighters in pairs(shipData.miningSquads or {}) do
                        if hasRawFighters then
                            controller:setSquadOrders(squadIndex, FighterOrders.Return, Uuid())
                        end
                    end
                    
                    for squadIndex, hasRawFighters in pairs(shipData.salvageSquads or {}) do
                        if hasRawFighters then
                            controller:setSquadOrders(squadIndex, FighterOrders.Return, Uuid())
                        end
                    end
                end
            end
        end
    end
end

return ShipSquadReturnManager
