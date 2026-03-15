local AutomationManager = {}
local autoScanEnabled = nil
local autoMineEnabled = nil
local autoDockEnabled = nil
local autoDockWhenFull = nil
local autoLootEnabled = nil

-- Automation debugging flag - set to true to enable debugging output
local AUTOMATION_DEBUG_ENABLED = false

function AutomationManager.initializeAutomationSettings()
    if AUTOMATION_DEBUG_ENABLED then
        print("Foreman: initializeAutomationSettings called - current values: scan:", autoScanEnabled, "mine:", autoMineEnabled, "dock:", autoDockEnabled, "dockWhenFull:", autoDockWhenFull, "loot:", autoLootEnabled)
    end
    -- Only set defaults if values are truly nil (not loaded yet)
    -- Don't override false values that were loaded from storage
    if autoScanEnabled == nil then 
        if AUTOMATION_DEBUG_ENABLED then
            print("Foreman: Setting autoScanEnabled to true (was nil)")
        end
        autoScanEnabled = true 
    end
    if autoMineEnabled == nil then 
        if AUTOMATION_DEBUG_ENABLED then
            print("Foreman: Setting autoMineEnabled to true (was nil)")
        end
        autoMineEnabled = true 
    end
    if autoDockEnabled == nil then 
        if AUTOMATION_DEBUG_ENABLED then
            print("Foreman: Setting autoDockEnabled to true (was nil)")
        end
        autoDockEnabled = true 
    end
    if autoDockWhenFull == nil then 
        if AUTOMATION_DEBUG_ENABLED then
            print("Foreman: Setting autoDockWhenFull to true (was nil)")
        end
        autoDockWhenFull = true 
    end
    if autoLootEnabled == nil then 
        if AUTOMATION_DEBUG_ENABLED then
            print("Foreman: Setting autoLootEnabled to true (was nil)")
        end
        autoLootEnabled = true 
    end
    if AUTOMATION_DEBUG_ENABLED then
        print("Foreman: initializeAutomationSettings completed - final values: scan:", autoScanEnabled, "mine:", autoMineEnabled, "dock:", autoDockEnabled, "dockWhenFull:", autoDockWhenFull, "loot:", autoLootEnabled)
    end
end

function AutomationManager.getAutoScanEnabled()
    return autoScanEnabled
end

function AutomationManager.getAutoMineEnabled()
    return autoMineEnabled
end

function AutomationManager.getAutoDockEnabled()
    return autoDockEnabled
end

function AutomationManager.getAutoDockWhenFull()
    return autoDockWhenFull
end

function AutomationManager.getAutoLootEnabled()
    return autoLootEnabled
end

function AutomationManager.setAutoScanEnabled(value)
    if AUTOMATION_DEBUG_ENABLED then
        print("Foreman: setAutoScanEnabled called with:", value, "current value:", autoScanEnabled)
    end
    autoScanEnabled = value
end
function AutomationManager.setAutoMineEnabled(value)
    if AUTOMATION_DEBUG_ENABLED then
        print("Foreman: setAutoMineEnabled called with:", value, "current value:", autoMineEnabled)
    end
    autoMineEnabled = value
end

function AutomationManager.setAutoDockEnabled(value)
    if AUTOMATION_DEBUG_ENABLED then
        print("Foreman: setAutoDockEnabled called with:", value, "current value:", autoDockEnabled)
    end
    autoDockEnabled = value
end

function AutomationManager.setAutoDockWhenFull(value)
    if AUTOMATION_DEBUG_ENABLED then
        print("Foreman: setAutoDockWhenFull called with:", value, "current value:", autoDockWhenFull)
    end
    autoDockWhenFull = value
end

function AutomationManager.setAutoLootEnabled(value)
    if AUTOMATION_DEBUG_ENABLED then
        print("Foreman: setAutoLootEnabled called with:", value, "current value:", autoLootEnabled)
    end
    autoLootEnabled = value
end

function AutomationManager.loadSettingsFromServer(scanEnabled, mineEnabled, dockEnabled, dockWhenFull, lootEnabled)
    autoScanEnabled = scanEnabled
    autoMineEnabled = mineEnabled
    autoDockEnabled = dockEnabled
    autoDockWhenFull = dockWhenFull
    autoLootEnabled = lootEnabled
end
function AutomationManager.delayedAutoScan(sectorScanned, sectorScanTimeRemaining, startScanningFunction)
    if onClient() and not sectorScanned and autoScanEnabled then
        if sectorScanTimeRemaining == nil then
            invokeServerFunction("sendAutoScanMessage")
            startScanningFunction()
        end
    end
end
function AutomationManager.delayedAutoMine(sectorScanned, harvest, startMiningFunction)
    if onClient() and autoMineEnabled and sectorScanned then
        if not harvest then
            invokeServerFunction("sendAutoMineMessage")
            startMiningFunction()
        end
    end
end
function AutomationManager.delayedAutoDock(getMineableAmountFunction, returnMiningSquadsFunction)
    if onClient() and autoDockEnabled then
        local resourcesLeftTotal = getMineableAmountFunction(true)
        if resourcesLeftTotal == 0 then
            invokeServerFunction("sendAutoDockMessage")
            returnMiningSquadsFunction(Player().craft.factionIndex, Player().index)
        end
    end
end
function AutomationManager.delayedAutoScanWrapper(sectorScanned, sectorScanTimeRemaining, startScanningCallback)
    AutomationManager.delayedAutoScan(sectorScanned, sectorScanTimeRemaining, startScanningCallback)
end
function AutomationManager.delayedAutoMineWrapper(sectorScanned, harvest, startMiningCallback)
    AutomationManager.delayedAutoMine(sectorScanned, harvest, startMiningCallback)
end
function AutomationManager.delayedAutoDockWrapper(getMineableAmountCallback, returnMiningSquadsCallback)
    AutomationManager.delayedAutoDock(getMineableAmountCallback, returnMiningSquadsCallback)
end
function AutomationManager.initializeAutomationSettingsWrapper()
    AutomationManager.initializeAutomationSettings()
end
function AutomationManager.saveAutomationSettingsWrapper(yieldVisiblePreference)
    if onClient() then
        invokeServerFunction("saveSettingsToServer", 
            AutomationManager.getAutoScanEnabled(), 
            AutomationManager.getAutoMineEnabled(), 
            AutomationManager.getAutoDockEnabled(), 
            AutomationManager.getAutoDockWhenFull(),
            AutomationManager.getAutoLootEnabled(),
            yieldVisiblePreference)
        invokeServerFunction("sendSaveConfirmationMessage")
    end
end
local automationWindow = nil
local autoScanLabel = nil
local autoScanCheckbox = nil
local autoMineLabel = nil
local autoMineCheckbox = nil
local autoDockLabel = nil
local autoDockCheckbox = nil
local autoDockWhenFullLabel = nil
local autoDockWhenFullCheckbox = nil
local autoLootLabel = nil
local autoLootCheckbox = nil
function AutomationManager.ensureAutomationUI(uiContainer, mainWindow)
    if automationWindow then return end
    if not uiContainer then return end
    
    -- Create a separate window for automation settings
    local res = getResolution()
    local mainWindowPos = mainWindow and mainWindow.position or vec2(res.x * 0.75, res.y * 0.15)
    local automationWindowPos = vec2(mainWindowPos.x + 320, mainWindowPos.y) -- Position to the right of main window
    local automationWindowSize = vec2(300, 200)
    
    automationWindow = Hud():createWindow(Rect(automationWindowPos, automationWindowPos + automationWindowSize))
    automationWindow.caption = "Automation Settings"
    automationWindow.showCloseButton = false
    automationWindow.moveable = 1
    automationWindow:hide() -- Start hidden
    
    local automationContainer = automationWindow:createContainer(Rect(0, 0, 300, 200))
    automationContainer:createFrame(Rect(0, 0, 290, 190))
    local automationHeaderLabel = automationContainer:createLabel(Rect(5, 2, 200, 18), "Automation Settings"%_t, 14)
    automationHeaderLabel:setLeftAligned()
    autoScanLabel = automationContainer:createLabel(Rect(10, 25, 200, 43), "Auto-scan on entry"%_t, 12)
    autoScanLabel:setLeftAligned()
    autoScanCheckbox = automationContainer:createButton(Rect(10, 25, 200, 43), " ", "onAutoScanToggle")
    autoScanCheckbox.textSize = 1
    autoScanCheckbox.tooltip = "Automatically scan for asteroids when entering a new sector (Green=ON, Red=OFF)"%_t
    autoScanCheckbox.layer = 20
    autoMineLabel = automationContainer:createLabel(Rect(10, 45, 200, 63), "Auto-mine after scan"%_t, 12)
    autoMineLabel:setLeftAligned()
    autoMineCheckbox = automationContainer:createButton(Rect(10, 45, 200, 63), " ", "onAutoMineToggle")
    autoMineCheckbox.textSize = 1
    autoMineCheckbox.tooltip = "Automatically start mining if asteroids are found after scanning (Green=ON, Red=OFF)"%_t
    autoMineCheckbox.layer = 20
    autoDockLabel = automationContainer:createLabel(Rect(10, 65, 200, 83), "Auto-dock when empty"%_t, 12)
    autoDockLabel:setLeftAligned()
    autoDockCheckbox = automationContainer:createButton(Rect(10, 65, 200, 83), " ", "onAutoDockToggle")
    autoDockCheckbox.textSize = 1
    autoDockCheckbox.tooltip = "Automatically dock fighters when no asteroids remain (Green=ON, Red=OFF)"%_t
    autoDockCheckbox.layer = 20
    autoDockWhenFullLabel = automationContainer:createLabel(Rect(10, 85, 200, 103), "Auto-dock when full"%_t, 12)
    autoDockWhenFullLabel:setLeftAligned()
    autoDockWhenFullCheckbox = automationContainer:createButton(Rect(10, 85, 200, 103), " ", "onAutoDockWhenFullToggle")
    autoDockWhenFullCheckbox.textSize = 1
    autoDockWhenFullCheckbox.tooltip = "Automatically dock fighters when cargo is full (Green=ON, Red=OFF)"%_t
    autoDockWhenFullCheckbox.layer = 20
    autoLootLabel = automationContainer:createLabel(Rect(10, 105, 200, 123), "Auto-collect loot"%_t, 12)
    autoLootLabel:setLeftAligned()
    autoLootCheckbox = automationContainer:createButton(Rect(10, 105, 200, 123), " ", "onAutoLootToggle")
    autoLootCheckbox.textSize = 1
    autoLootCheckbox.tooltip = "Automatically send fighters to collect valuable loot (system upgrades and turrets) (Green=ON, Red=OFF)"%_t
    autoLootCheckbox.layer = 20
    autoScanCheckbox:show()
    autoMineCheckbox:show()
    autoDockCheckbox:show()
    autoDockWhenFullCheckbox:show()
    autoLootCheckbox:show()
    automationWindow:hide()
end
function AutomationManager.getAutomationWindow()
    return automationWindow
end
function AutomationManager.getAutoScanLabel()
    return autoScanLabel
end
function AutomationManager.getAutoScanCheckbox()
    return autoScanCheckbox
end
function AutomationManager.getAutoMineLabel()
    return autoMineLabel
end
function AutomationManager.getAutoMineCheckbox()
    return autoMineCheckbox
end
function AutomationManager.getAutoDockLabel()
    return autoDockLabel
end
function AutomationManager.getAutoDockCheckbox()
    return autoDockCheckbox
end
function AutomationManager.getAutoDockWhenFullLabel()
    return autoDockWhenFullLabel
end
function AutomationManager.getAutoDockWhenFullCheckbox()
    return autoDockWhenFullCheckbox
end

function AutomationManager.getAutoLootLabel()
    return autoLootLabel
end

function AutomationManager.getAutoLootCheckbox()
    return autoLootCheckbox
end
function AutomationManager.toggleAutomationWindow(uiContainer, automationVisible, expandWindowCallback, contractWindowCallback, mainWindow)
    AutomationManager.ensureAutomationUI(uiContainer, mainWindow)
    if automationWindow.visible then
        automationWindow:hide()
        automationVisible = false
    else
        automationWindow:show()
        automationVisible = true
    end
    return automationVisible
end
local processedFullShips = {}
function AutomationManager.checkAutoDockWhenFull(ships, harvest, salvage)
    if onClient() and AutomationManager.getAutoDockWhenFull() then
        local fullShips = {}
        local hasFullShips = false
        local newFullShips = {} -- Ships that just became full
        for i, _ in pairs(ships) do
            local ship = Entity(i)
            if ship and ship.maxCargoSpace and ship.maxCargoSpace > 0 and ship.freeCargoSpace < 150 then
                table.insert(fullShips, i)
                hasFullShips = true
                if not processedFullShips[tostring(i)] then
                    table.insert(newFullShips, i)
                    processedFullShips[tostring(i)] = true
                end
            else
                processedFullShips[tostring(i)] = nil
            end
        end
        if #newFullShips > 0 and (harvest or salvage) then
            invokeServerFunction("sendAutoDockWhenFullMessage", #newFullShips)
            local x, y = Sector():getCoordinates()
            invokeSectorFunction(x, y, true, "data/scripts/sector/ForemanSector.lua", "returnShipSquads", Player().craft.factionIndex, newFullShips)
        end
    end
end
function AutomationManager.onAutoScanToggle(updateAutomationButtonColorsCallback, saveAutomationSettingsCallback)
    AutomationManager.setAutoScanEnabled(not AutomationManager.getAutoScanEnabled())
    updateAutomationButtonColorsCallback()
    saveAutomationSettingsCallback()
end
function AutomationManager.onAutoMineToggle(updateAutomationButtonColorsCallback, saveAutomationSettingsCallback)
    AutomationManager.setAutoMineEnabled(not AutomationManager.getAutoMineEnabled())
    updateAutomationButtonColorsCallback()
    saveAutomationSettingsCallback()
end
function AutomationManager.onAutoDockToggle(updateAutomationButtonColorsCallback, saveAutomationSettingsCallback)
    AutomationManager.setAutoDockEnabled(not AutomationManager.getAutoDockEnabled())
    updateAutomationButtonColorsCallback()
    saveAutomationSettingsCallback()
end

function AutomationManager.onAutoLootToggle(updateAutomationButtonColorsCallback, saveAutomationSettingsCallback)
    AutomationManager.setAutoLootEnabled(not AutomationManager.getAutoLootEnabled())
    updateAutomationButtonColorsCallback()
    saveAutomationSettingsCallback()
end
function AutomationManager.resetAutomationSettings()
    autoScanEnabled = true
    autoMineEnabled = true
    autoDockEnabled = true
    autoDockWhenFull = true
    autoLootEnabled = true
end
return AutomationManager
