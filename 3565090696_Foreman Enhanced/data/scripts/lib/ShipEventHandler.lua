local ShipEventHandler = {}
function ShipEventHandler.onShipCaptainChanged(shipId, captain, setShipIconStatuses)
    setShipIconStatuses(shipId)
end
function ShipEventHandler.onCrewChanged(shipId, delta, profession, setShipIconStatuses)
    setShipIconStatuses(shipId)
end
function ShipEventHandler.onSquadAdded(shipId, index, setShipIconStatuses)
    setShipIconStatuses(shipId)
end
function ShipEventHandler.onSquadRemoved(shipId, index, setShipIconStatuses)
    setShipIconStatuses(shipId)
end
return ShipEventHandler
