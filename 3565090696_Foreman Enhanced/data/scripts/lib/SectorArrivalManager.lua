local SectorArrivalManager = {}
ShipValidation = include("ShipValidation")
AutomationManager = include("AutomationManager")
function SectorArrivalManager.onConfirmSectorArrival(x, y, sectorScanned, window, scanButton, autoScanCheckbox, autoMineCheckbox, autoDockCheckbox, autoScanLabel, autoMineLabel, autoDockLabel, startMiningButton, stopMiningButton, showCallback, getSectorScanStatusCallback, onLoadCallback, registerShipCallbacksCallback, readyToLoad)
    local ship = Player().craft
    if not ship then return end
    -- Don't set sectorScanned = false here as it interferes with the scan status check
    if ShipValidation.shipHasForemanModule(ship.id) then
        if window then
            if scanButton then scanButton:show() end
            if autoScanCheckbox then autoScanCheckbox:show() end
            if autoMineCheckbox then autoMineCheckbox:show() end
            if autoDockCheckbox then autoDockCheckbox:show() end
            if autoScanLabel then autoScanLabel:show() end
            if autoMineLabel then autoMineLabel:show() end
            if autoDockLabel then autoDockLabel:show() end
            startMiningButton:hide()
            stopMiningButton:hide()
            showCallback()
            getSectorScanStatusCallback()
            -- Check auto-scan setting - only auto-scan if explicitly enabled
            local autoScanEnabled = AutomationManager.getAutoScanEnabled()
            if autoScanEnabled == true then
                deferredCallback(1.0, "delayedAutoScan")
                elseif autoScanEnabled == nil then
                -- Settings not loaded yet, retry after a delay
                deferredCallback(2.0, "delayedAutoScan")
            end
        end
    end
    readyToLoad = true
    onLoadCallback()
    if ship and ship.isShip then
        registerShipCallbacksCallback(ship.id)
        ship:registerCallback("onSystemsChanged", "onSystemsChanged_player")
    end
end
return SectorArrivalManager
