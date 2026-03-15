local ShipNameUpdateManager = {}
function ShipNameUpdateManager.onShipNameUpdated(name, newName, ships, shipListEx, setShipIconStatusesCallback)
    local shipId = ShipListManager.onShipNameUpdated(name, newName, ships, shipListEx)
    setShipIconStatusesCallback(shipId)
end
return ShipNameUpdateManager
