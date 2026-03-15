local EntityEventManager = {}
function EntityEventManager.onEntityCreated_client(entityId, readyToLoad, handleNewShipCallback)
    local entity = Entity(entityId)
    if readyToLoad then
        if not entity.isDrone and not entity.isFighter and (entity.isShip or entity.isStation) and entity.playerOrAllianceOwned and entity.factionIndex == Player().craft.factionIndex then
            handleNewShipCallback(entityId)
        end
    end
end
function EntityEventManager.onEntityRemoved_client(shipId, tryRemoveShipFromListCallback)
    tryRemoveShipFromListCallback(shipId)
end
return EntityEventManager
