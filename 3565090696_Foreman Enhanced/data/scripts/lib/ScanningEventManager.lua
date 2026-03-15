local ScanningEventManager = {}
AutomationManager = include("AutomationManager")
function ScanningEventManager.scanStarted(scanTime, showScanCallback, sectorScanTimeRemaining, sectorScanTime)
    if onServer() then
        invokeClientFunction(Player(), "scanStarted", scanTime)
    else
        showScanCallback()
        return scanTime, scanTime  -- Return the new values for sectorScanTimeRemaining and sectorScanTime
    end
end
function ScanningEventManager.scanCancelled(hideScanCallback, sectorScanTimeRemaining)
    if onServer() then
        invokeClientFunction(Player(), "scanCancelled")
    else
        hideScanCallback()
        return nil  -- Return nil for sectorScanTimeRemaining
    end
end
function ScanningEventManager.sectorScanComplete(hideScanCallback, invalidateAsteroidCacheCallback, getMineableAmountInVicinityCallback, updateYieldUICallback, sectorScanned, sectorScanTimeRemaining)
    if onServer() then
        invokeClientFunction(Player(), "sectorScanComplete")
    else
        invalidateAsteroidCacheCallback()
        hideScanCallback()
        if AutomationManager.getAutoMineEnabled() then
            local resourcesLeftTotal, asteroidCount = getMineableAmountInVicinityCallback(true)
            if resourcesLeftTotal > 0 and asteroidCount > 0 then
                deferredCallback(0.5, "delayedAutoMine")
            end
        end
        return true, nil
    end
end
function ScanningEventManager.receiveScanStatus(scanTime, timeLeft, showScanCallback, sectorScanTimeRemaining, sectorScanTime)
    if onServer() then
        invokeClientFunction(Player(), "receiveScanStatus", scanTime, timeLeft)
    else
        showScanCallback()
        return timeLeft, scanTime  -- Return the new values for sectorScanTimeRemaining and sectorScanTime
    end
end
return ScanningEventManager
