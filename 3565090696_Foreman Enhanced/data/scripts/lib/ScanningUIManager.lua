local ScanningUIManager = {}
local scanButton = nil
local scanContainer = nil
local scanProgress = nil
local scanLabel = nil

function ScanningUIManager.initScanUI(uiContainer, window)
    scanButton = uiContainer:createButton(Rect(5,10,160,28), "Scan asteroids"%_t, "scanButtonPressed")
    scanButton.textSize = 10
    
    scanContainer = window:createContainer(Rect(5,10,160,28))
    scanContainer:createFrame(Rect(0,0,160,18))
    scanProgress = scanContainer:createProgressBar(Rect(0,0,160,18), ColorRGB(0,1,0))
    scanProgress.layer = 10
    
    scanLabel = scanContainer:createLabel(Rect(0,1,160,18), "SCANNING"%_t, 14)
    scanLabel.layer = 11
    scanLabel.centered = true
    scanLabel.outline = true
    scanLabel.fontSize = 14
    scanContainer:hide()
end

function ScanningUIManager.getScanButton()
    return scanButton
end

function ScanningUIManager.getScanContainer()
    return scanContainer
end

function ScanningUIManager.getScanProgress()
    return scanProgress
end

function ScanningUIManager.getScanLabel()
    return scanLabel
end

return ScanningUIManager
