local UIIntializationManager = {}
MainUIManager = include("MainUIManager")
function UIIntializationManager.initializeUI(ensureYieldUICallback, ensureAutomationUICallback, loadWindowPos_clientCallback, initScanUICallback, checkIfFirstTimeLoadCallback, updateCheckboxStatesCallback, onLoadCallback)
    local uiElements = MainUIManager.initializeUI()
    window = uiElements.window
    unminimizedHeight = uiElements.unminimizedHeight
    uiContainer = uiElements.uiContainer
    startMiningButton = uiElements.startMiningButton
    stopMiningButton = uiElements.stopMiningButton
    startSalvageButton = uiElements.startSalvageButton
    stopSalvageButton = uiElements.stopSalvageButton
    recallFullShipsButton = uiElements.recallFullShipsButton
    balanceCrewButton = uiElements.balanceCrewButton
    autoBalanceCrewCheckbox = uiElements.autoBalanceCrewCheckbox
    miningAmountLeftLabel = uiElements.miningAmountLeftLabel
    shipListEx = uiElements.shipListEx
    minimizeButton = uiElements.minimizeButton
    if ensureYieldUICallback then
        ensureYieldUICallback()
    end
    if ensureAutomationUICallback then
        ensureAutomationUICallback()
    end
    loadWindowPos_clientCallback()
    window:hide()
    if onClient() and Player() and Player().craft then
        pcall(function()
            scanAccuracy, foremanMaterialLevel = ForemanSystemManager.getAndSetForemanModuleMiningAccuracy(Player().craft.id, scanAccuracy, foremanMaterialLevel)
        end)
    end
    if onClient() then
        yieldVisiblePreference = true  -- Default to showing yield window
        automationVisible = false
    end
    checkIfFirstTimeLoadCallback()
    if window then
        window:show()
        shouldUpdate = true
        if automationVisible then
            ensureAutomationUICallback()
            if automationWindow then
                automationWindow:show()
            end
        end
    end
    deferredCallback(0.1, "updateCheckboxStates")
    deferredCallback(0.5, "updateCheckboxStates")
    deferredCallback(0.1, "onLoad")
    return {
        window = window,
        uiContainer = uiContainer,
        unminimizedHeight = unminimizedHeight,
        shipListEx = shipListEx,
        startMiningButton = startMiningButton,
        stopMiningButton = stopMiningButton,
        startSalvageButton = startSalvageButton,
        stopSalvageButton = stopSalvageButton,
        recallFullShipsButton = recallFullShipsButton,
        balanceCrewButton = balanceCrewButton,
        yieldSalvageCountLabel = yieldSalvageCountLabel,
        miningAmountLeftLabel = miningAmountLeftLabel,
        scanProgress = scanProgress,
        autoScanCheckbox = autoScanCheckbox,
        autoMineCheckbox = autoMineCheckbox,
        autoDockCheckbox = autoDockCheckbox,
        autoScanLabel = autoScanLabel,
        autoMineLabel = autoMineLabel,
        autoDockLabel = autoDockLabel,
        filterCheckBoxes = {} -- Empty table for now, will be populated later if needed
    }
end
return UIIntializationManager
