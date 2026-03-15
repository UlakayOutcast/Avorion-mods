local FighterEventManager = {}
function FighterEventManager.onFighterAdded(shipId, squadIndex, fighterIndex, landed, setShipIconStatusesCallback)
    local ship = Entity(shipId)
    if ship.factionIndex == Player().craft.factionIndex and not landed then
        setShipIconStatusesCallback(shipId)
    end
end
function FighterEventManager.onFighterRemoved(shipId, squadIndex, fighterIndex, started, setShipIconStatusesCallback)
    if not started then
        local ship = Entity(shipId)
        if (ship.factionIndex == Player().index or ship.factionIndex == Player().allianceIndex) then
            setShipIconStatusesCallback(shipId)
        end
    end
end
return FighterEventManager
