local EntityLoadingManager = {}

function EntityLoadingManager.onLoad(handleNewShipCallback)
    if not onClient() then return end
    
    local playerCraft = Player().craft
    if not playerCraft then return end
    
    local ships = getCachedPlayerOwnedEntities(EntityType.Ship)
    for _, v in pairs(ships) do
        if not v.isDrone and v.factionIndex == playerCraft.factionIndex then
            handleNewShipCallback(v.id)
        end
    end
    
    local stations = getCachedPlayerOwnedEntities(EntityType.Station)
    for _, v in pairs(stations) do
        if v.factionIndex == playerCraft.factionIndex then
            handleNewShipCallback(v.id)
        end
    end
end

return EntityLoadingManager
