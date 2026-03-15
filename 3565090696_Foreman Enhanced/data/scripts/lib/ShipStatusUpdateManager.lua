local ShipStatusUpdateManager = {}
ShipValidation = include("ShipValidation")
function ShipStatusUpdateManager.onSystemsChanged(shipId)
    deferredCallback(0.1, "updateShipStatus", shipId)
end
function ShipStatusUpdateManager.updateShipStatus(shipId, handleNewShipCallback, tryRemoveShipFromListCallback)
    if ShipValidation.shipHasForemanModule(shipId) then
        handleNewShipCallback(shipId)
    else
        tryRemoveShipFromListCallback(shipId)
    end
end
function ShipStatusUpdateManager.deferredOnSystemsChanged_player(shipId, shipHasForemanSystem, setShipIconStatusesCallback, registerShipCallbacksCallback, showCallback, readyToLoad, getAndSetForemanModuleMiningAccuracyCallback, scanAccuracy, foremanMaterialLevel, hideCallback)
    if ShipValidation.shipHasForemanModule(shipId) then
        shipHasForemanSystem = true
        setShipIconStatusesCallback(shipId)
        registerShipCallbacksCallback(shipId)
        showCallback()
        readyToLoad = true
        scanAccuracy, foremanMaterialLevel = getAndSetForemanModuleMiningAccuracyCallback(shipId, scanAccuracy, foremanMaterialLevel)
    else
        shipHasForemanSystem = false
        hideCallback()
    end
    return shipHasForemanSystem, scanAccuracy, foremanMaterialLevel, readyToLoad
end
return ShipStatusUpdateManager
