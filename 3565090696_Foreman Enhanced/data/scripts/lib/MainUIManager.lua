local MainUIManager = {}
WindowManager = include("WindowManager")
function MainUIManager.initializeUI()
    local res = getResolution()
    local size = vec2(res.x * 0.75, res.y * 0.15)  -- Moved to top-right to avoid Material UI overlap
    local size2 = size + vec2(300, 470)  -- Increased height to prevent bottom clipping
    local window = Hud():createWindow(Rect(size, size2))
    local unminimizedHeight = window.height
    window.caption = "Foreman"
    window.showCloseButton = false
    window.moveable = 1
    WindowManager.setClientWindowLastPos(window.position)
    local btnShowInfo = window:createButton(Rect(5,-28,25,-8), "", "showInfo")
    btnShowInfo.overlayIcon = "data/textures/icons/question-mark.png"
    btnShowInfo.overlayIconPadding = 0
    btnShowInfo.overlayIconSizeFactor = 1
    btnShowInfo.tooltip = "Show info"%_t
    local btnToggleYield = window:createButton(Rect(80,-28,100,-8), "", "toggleYieldWindow")
    btnToggleYield.overlayIcon = "data/textures/icons/asteroid.png"
    btnToggleYield.overlayIconPadding = 0
    btnToggleYield.overlayIconSizeFactor = 1
    btnToggleYield.tooltip = "Show per-material yields"%_t
    local btnToggleAutomation = window:createButton(Rect(235,-28,255,-8), "", "toggleAutomationWindow")
    btnToggleAutomation.overlayIcon = "data/textures/icons/mod-uploaded.png"
    btnToggleAutomation.overlayIconPadding = 0
    btnToggleAutomation.overlayIconSizeFactor = 1
    btnToggleAutomation.tooltip = "Show automation settings"%_t
    local minimizeButton = window:createButton(Rect(275,-28,295,-8), "X", "toggleMinimize")
    minimizeButton.textSize = 14
    local uiContainer = window:createContainer(Rect(0, 0, 300, 470))  -- Match increased window height
    local startMiningButton = uiContainer:createButton(Rect(5, 10, 85, 28), "Mine"%_t, "startMiningPressed")
    local stopMiningButton = uiContainer:createButton(Rect(90, 10, 160, 28), "Stop"%_t, "stopMiningPressed")
    local startSalvageButton = uiContainer:createButton(Rect(5, 32, 85, 50), "Salvage"%_t, "startSalvagingPressed")
    local stopSalvageButton = uiContainer:createButton(Rect(90, 32, 160, 50), "Stop"%_t, "stopSalvagingPressed")
    local recallFullShipsButton = uiContainer:createButton(Rect(195, 10, 295, 50), "Recall full ships"%_t, "recallFullShips")
    recallFullShipsButton.textSize = 10
    local balanceCrewButton = uiContainer:createButton(Rect(195, 52, 295, 70), "Balance crew"%_t, "balanceCrewNow")
    balanceCrewButton.textSize = 10
    local autoBalanceCrewCheckbox = uiContainer:createButton(Rect(90, 52, 160, 70), "Auto"%_t, "toggleAutoBalanceCrew")
    autoBalanceCrewCheckbox.textSize = 10
    startMiningButton:hide()
    stopMiningButton:hide()
    stopMiningButton.active = false
    stopSalvageButton.active = false
    recallFullShipsButton.active = false
    balanceCrewButton.active = true
    autoBalanceCrewCheckbox.active = true
    local miningAmountLeftLabel = uiContainer:createLabel(Rect(5, 55, 295, 70), "", 14)
    miningAmountLeftLabel:setLeftAligned()
    miningAmountLeftLabel:hide() -- hide by default; used only for auto-dock countdown
    local color1 = Material(MaterialType.Iron).color
    local color2 = Material(MaterialType.Titanium).color
    local color3 = Material(MaterialType.Naonite).color
    local color4 = Material(MaterialType.Trinium).color
    local color5 = Material(MaterialType.Xanion).color
    local color6 = Material(MaterialType.Ogonite).color
    local color7 = Material(MaterialType.Avorion).color
    local alpha = 0.3
    color1.a = alpha
    color2.a = alpha
    color3.a = alpha
    color4.a = alpha
    color5.a = alpha
    color6.a = alpha
    color7.a = alpha
    local shipListEx = uiContainer:createListBoxEx(Rect(vec2(5, 80), vec2(295, 350)), 5, 5)
    shipListEx.onSelectFunction = "onShipRowSelected"
    shipListEx.entriesSelectable = true
    shipListEx.columns = 9
    shipListEx:setColumnWidth(0, 35)
    shipListEx:setColumnWidth(1, 100)
    shipListEx:setColumnWidth(2, 20)
    shipListEx:setColumnWidth(3, 20)
    shipListEx:setColumnWidth(4, 20)
    shipListEx:setColumnWidth(5, 20)
    shipListEx:setColumnWidth(6, 20)
    shipListEx:setColumnWidth(7, 0)
    shipListEx:setColumnWidth(8, 0)
    local btnForceRefresh = uiContainer:createButton(Rect(275,60,295,80), "", "forceRefresh")
    btnForceRefresh.overlayIcon = "data/textures/icons/auto-targeting.png"
    btnForceRefresh.overlayIconPadding = 0
    btnForceRefresh.overlayIconSizeFactor = 1
    btnForceRefresh.tooltip = "Force refresh ship list"%_t
    return {
        window = window,
        unminimizedHeight = unminimizedHeight,
        uiContainer = uiContainer,
        startMiningButton = startMiningButton,
        stopMiningButton = stopMiningButton,
        startSalvageButton = startSalvageButton,
        stopSalvageButton = stopSalvageButton,
        recallFullShipsButton = recallFullShipsButton,
        balanceCrewButton = balanceCrewButton,
        autoBalanceCrewCheckbox = autoBalanceCrewCheckbox,
        miningAmountLeftLabel = miningAmountLeftLabel,
        shipListEx = shipListEx,
        minimizeButton = minimizeButton
    }
end
return MainUIManager
