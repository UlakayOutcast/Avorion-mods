local ShipDiscoveryManager = {}
ShipValidation = include("ShipValidation")
function ShipDiscoveryManager.handleNewShip(shipId, registerShipCallbacksCallback, tryAddShipToListCallback, setShipIconStatusesCallback)
    local ship = Entity(shipId)
    if ship.isDrone or ship.isFighter then return end
    if ship.factionIndex ~= Player().craft.factionIndex then return end
    registerShipCallbacksCallback(shipId)
    if ShipValidation.shipHasForemanModule(shipId) then
        tryAddShipToListCallback(shipId)
        setShipIconStatusesCallback(shipId)
    end
end
return ShipDiscoveryManager
