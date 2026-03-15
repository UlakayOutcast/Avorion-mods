local ShipCallbackRegistrationManager = {}
function ShipCallbackRegistrationManager.registerShipCallbacks(shipId)
    local ship = Entity(shipId)
    ship:registerCallback("onJump", "onJump")
    ship:registerCallback("onCaptainChanged", "onShipCaptainChanged")
end
return ShipCallbackRegistrationManager
