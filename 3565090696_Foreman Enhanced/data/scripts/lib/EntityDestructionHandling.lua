local EntityDestructionHandling = {}
function EntityDestructionHandling.onDestroyed(shipIndex, lastDamageInflictor, factionData)
    local entity = Sector():getEntity(shipIndex)
    if not entity then return end
    if entity.isShip and entity.playerOrAllianceOwned then
        local data = factionData[entity.factionIndex]
        if data ~= nil then
            local x, y = Sector():getCoordinates()
            data.ships[tostring(shipIndex)] = nil
            if getTableLength(data.ships) == 0 then
                factionData[entity.factionIndex] = nil
            end
        end
        CombatManager.cleanupCombatState(shipIndex)
    end
end
return EntityDestructionHandling
