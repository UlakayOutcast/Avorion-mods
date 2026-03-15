local ScanningUIStateManager = {}
function ScanningUIStateManager.showScan(scanProgress, scanButton, autoScanCheckbox, autoMineCheckbox, autoDockCheckbox, autoScanLabel, autoMineLabel, autoDockLabel, scanLabel, scanContainer)
    scanProgress.progress = 0
    if scanButton then scanButton:hide() end
    if autoScanCheckbox then autoScanCheckbox:hide() end
    if autoMineCheckbox then autoMineCheckbox:hide() end
    if autoDockCheckbox then autoDockCheckbox:hide() end
    if autoScanLabel then autoScanLabel:hide() end
    if autoMineLabel then autoMineLabel:hide() end
    if autoDockLabel then autoDockLabel:hide() end
    if scanLabel then scanLabel:show() end
    if scanProgress then scanProgress:show() end
    if scanContainer then scanContainer:show() end
end
function ScanningUIStateManager.hideScan(scanProgress, scanButton, autoScanCheckbox, autoMineCheckbox, autoDockCheckbox, autoScanLabel, autoMineLabel, autoDockLabel, scanLabel, scanContainer)
    scanProgress.progress = 0
    if scanButton then scanButton:hide() end
    if autoScanCheckbox then autoScanCheckbox:show() end
    if autoMineCheckbox then autoMineCheckbox:show() end
    if autoDockCheckbox then autoDockCheckbox:show() end
    if autoScanLabel then autoScanLabel:show() end
    if autoMineLabel then autoMineLabel:show() end
    if autoDockLabel then autoDockLabel:show() end
    if scanLabel then scanLabel:hide() end
    if scanProgress then scanProgress:hide() end
    if scanContainer then scanContainer:hide() end
end
return ScanningUIStateManager
