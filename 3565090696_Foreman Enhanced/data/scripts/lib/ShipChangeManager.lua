local ShipChangeManager = {}
ShipValidation = include("ShipValidation")
function ShipChangeManager.onShipChanged(playerIndex, newShipId, oldShipId, window, shipHasForemanSystem, scanAccuracy, foremanMaterialLevel, sectorScanned, readyToLoad, initializeUICallback, showCallback, hideCallback, forceRefreshCallback, getSectorScanStatusCallback)
    if playerIndex == Player().index then
        if Player().alliance then
            Player().alliance:registerCallback("onShipNameUpdated", "onShipNameUpdated")
        end
        local entity = Entity(oldShipId)
        if entity then
            entity:unregisterCallback("onSystemsChanged", "onSystemsChanged_player")
        end
        local ship = Player().craft
        if ship then
            ship:registerCallback("onSystemsChanged", "onSystemsChanged_player")
        end
        if ShipValidation.shipHasForemanModule(newShipId) then
            if not window then initializeUICallback() end
            shipHasForemanSystem = true
            scanAccuracy, foremanMaterialLevel = ForemanSystemManager.getAndSetForemanModuleMiningAccuracy(newShipId, scanAccuracy, foremanMaterialLevel)
            showCallback()
            readyToLoad = true
            if entity then
                local newship = Entity(newShipId)
                if newship.factionIndex ~= entity.factionIndex then
                    forceRefreshCallback()
                end
            end
            if sectorScanned == false then
                getSectorScanStatusCallback()
            end
        else
            shipHasForemanSystem = false
            hideCallback()
        end
        return shipHasForemanSystem, scanAccuracy, foremanMaterialLevel, readyToLoad
    end
end
return ShipChangeManager
