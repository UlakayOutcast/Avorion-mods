local GlobalBridgeFunctions = {}
function GlobalBridgeFunctions.onShipRowSelected(index, fm)
    fm.onShipRowSelected(index)
end
function GlobalBridgeFunctions.updateCheckboxStates(fm)
    fm.updateCheckboxStates()
end
function GlobalBridgeFunctions.onSectorChanged(x, y, fm)
    fm.onSectorChanged(x, y)
end
function GlobalBridgeFunctions.onPlayerLeft(fm)
    fm.onPlayerLeft()
end
function GlobalBridgeFunctions.resetAutomationSettings(fm)
    fm.resetAutomationSettings()
end
function GlobalBridgeFunctions.periodicSaveSettings(fm)
    fm.periodicSaveSettings()
end
function GlobalBridgeFunctions.delayedAutoScan(fm)
    fm.delayedAutoScan()
end
function GlobalBridgeFunctions.delayedAutoMine(fm)
    fm.delayedAutoMine()
end
function GlobalBridgeFunctions.delayedAutoDock(fm)
    fm.delayedAutoDock()
end
function GlobalBridgeFunctions.startMiningPressed(fm)
    fm.startMiningPressed()
end
function GlobalBridgeFunctions.stopMiningPressed(fm)
    fm.stopMiningPressed()
end
function GlobalBridgeFunctions.startSalvagingPressed(fm)
    fm.startSalvagingPressed()
end
function GlobalBridgeFunctions.stopSalvagingPressed(fm)
    fm.stopSalvagingPressed()
end
function GlobalBridgeFunctions.scanButtonPressed(fm)
    fm.scanButtonPressed()
end
function GlobalBridgeFunctions.toggleYieldWindow(fm)
    fm.toggleYieldWindow()
end
function GlobalBridgeFunctions.toggleAutomationWindow(fm)
    fm.toggleAutomationWindow()
end
function GlobalBridgeFunctions.onAutoScanToggle(fm)
    fm.onAutoScanToggle()
end
function GlobalBridgeFunctions.onAutoMineToggle(fm)
    fm.onAutoMineToggle()
end
function GlobalBridgeFunctions.onAutoDockToggle(fm)
    fm.onAutoDockToggle()
end
function GlobalBridgeFunctions.onAutoScanChecked(checkbox, value, fm)
    fm.onAutoScanChecked(checkbox, value)
end
function GlobalBridgeFunctions.onAutoMineChecked(checkbox, value, fm)
    fm.onAutoMineChecked(checkbox, value)
end
function GlobalBridgeFunctions.onAutoDockChecked(checkbox, value, fm)
    fm.onAutoDockChecked(checkbox, value)
end
function GlobalBridgeFunctions.onAutoDockWhenFullToggle(fm)
    fm.onAutoDockWhenFullToggle()
end
function GlobalBridgeFunctions.initialize(fm)
    fm.initialize()
end
function GlobalBridgeFunctions.requestLoadFromServer(fm)
    fm.requestLoadFromServer()
end
return GlobalBridgeFunctions
