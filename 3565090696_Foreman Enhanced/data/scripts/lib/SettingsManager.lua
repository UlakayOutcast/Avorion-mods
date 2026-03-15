local SettingsManager = {}
AutomationManager = include("AutomationManager")
WindowManager = include("WindowManager")

-- Automation debugging flag - set to true to enable debugging output
local AUTOMATION_DEBUG_ENABLED = false

function SettingsManager.onGameExit()
    if onClient() then
        invokeServerFunction("saveSettingsToServer", 
            AutomationManager.getAutoScanEnabled(), 
            AutomationManager.getAutoMineEnabled(), 
            AutomationManager.getAutoDockEnabled(), 
            AutomationManager.getAutoDockWhenFull(),
            AutomationManager.getAutoLootEnabled())
    end
end

function SettingsManager.onPlayerLeft()
    if onClient() then
        invokeServerFunction("saveSettingsToServer", 
            AutomationManager.getAutoScanEnabled(), 
            AutomationManager.getAutoMineEnabled(), 
            AutomationManager.getAutoDockEnabled(), 
            AutomationManager.getAutoDockWhenFull(),
            AutomationManager.getAutoLootEnabled())
    end
end

function SettingsManager.periodicSaveSettings(fromUpdate)
    if onClient() then
        invokeServerFunction("saveSettingsToServer", 
            AutomationManager.getAutoScanEnabled(), 
            AutomationManager.getAutoMineEnabled(), 
            AutomationManager.getAutoDockEnabled(), 
            AutomationManager.getAutoDockWhenFull(),
            AutomationManager.getAutoLootEnabled())
    end
end

function SettingsManager.saveAutomationSettings(yieldVisiblePreference)
    AutomationManager.saveAutomationSettingsWrapper(yieldVisiblePreference)
end

function SettingsManager.forceSaveSettings(yieldVisiblePreference)
    if onClient() then
        invokeServerFunction("saveSettingsToServer", 
            AutomationManager.getAutoScanEnabled(), 
            AutomationManager.getAutoMineEnabled(), 
            AutomationManager.getAutoDockEnabled(), 
            AutomationManager.getAutoDockWhenFull(), 
            AutomationManager.getAutoLootEnabled(),
            yieldVisiblePreference)
    end
end

function SettingsManager.loadSettingsFromServer()
    if onServer() then
        -- CRITICAL FIX: Don't fallback to random player - this causes wrong settings to load
        if callingPlayer == nil then
            print("Foreman: ERROR - loadSettingsFromServer called without callingPlayer. Cannot determine which player's settings to load.")
            return
        end
        
        local player = Player(callingPlayer)
        if not player then 
            print("Foreman: ERROR - Could not get Player object for callingPlayer:", callingPlayer)
        end
        
        local savedAutoScan, savedAutoMine, savedAutoDock, savedAutoDockWhenFull, savedAutoLoot, savedYieldVisible

        -- Try loading from player values if API supports getValue
        if player and type(player.getValue) == "function" then
            savedAutoScan = player:getValue("foreman_autoScan")
            savedAutoMine = player:getValue("foreman_autoMine")
            savedAutoDock = player:getValue("foreman_autoDock")
            savedAutoDockWhenFull = player:getValue("foreman_autoDockWhenFull")
            savedAutoLoot = player:getValue("foreman_autoLoot")
            savedYieldVisible = player:getValue("foreman_yieldVisible")
            if AUTOMATION_DEBUG_ENABLED then
                print("Foreman: Loaded from player - scan:", savedAutoScan, "mine:", savedAutoMine, "dock:", savedAutoDock, "dockWhenFull:", savedAutoDockWhenFull, "loot:", savedAutoLoot, "yieldVisible:", savedYieldVisible)
            end
        end
        
        -- Fallback to galaxy values if nothing stored on player
        if savedAutoScan == nil then
            local galaxy = Galaxy()
            if galaxy and type(galaxy.getValue) == "function" then
                local playerIndex = player and player.index or callingPlayer
                savedAutoScan = galaxy:getValue("foreman_" .. playerIndex .. "_autoScan")
                savedAutoMine = galaxy:getValue("foreman_" .. playerIndex .. "_autoMine")
                savedAutoDock = galaxy:getValue("foreman_" .. playerIndex .. "_autoDock")
                savedAutoDockWhenFull = galaxy:getValue("foreman_" .. playerIndex .. "_autoDockWhenFull")
                savedAutoLoot = galaxy:getValue("foreman_" .. playerIndex .. "_autoLoot")
                savedYieldVisible = galaxy:getValue("foreman_" .. playerIndex .. "_yieldVisible")
                if AUTOMATION_DEBUG_ENABLED then
                    print("Foreman: Loaded from galaxy - scan:", savedAutoScan, "mine:", savedAutoMine, "dock:", savedAutoDock, "dockWhenFull:", savedAutoDockWhenFull, "loot:", savedAutoLoot, "yieldVisible:", savedYieldVisible)
                end
            end
        end
        
        -- Send to client; client side will handle defaults if nil
        local recipient = player or Player(callingPlayer)
        if recipient then
            -- Call the callable on the Foreman UI script instance rather than a plain global string
            invokeClientFunction(recipient, "receiveLoadedSettings", savedAutoScan, savedAutoMine, savedAutoDock, savedAutoDockWhenFull, savedAutoLoot, savedYieldVisible)
        else
            print("Foreman: ERROR - No valid recipient to send loaded settings to.")
        end
    end
end

function SettingsManager.receiveLoadedSettings(scan, mine, dock, dockWhenFull, loot, yieldVisible, fm, yieldVisiblePreference, yieldWindow)
    if onClient() then
        if AUTOMATION_DEBUG_ENABLED then
            print("Foreman: receiveLoadedSettings called - scan:", scan, "mine:", mine, "dock:", dock, "dockWhenFull:", dockWhenFull, "loot:", loot, "yieldVisible:", yieldVisible)
            print("Foreman: Current values before applying - scan:", AutomationManager.getAutoScanEnabled(), "mine:", AutomationManager.getAutoMineEnabled(), "dock:", AutomationManager.getAutoDockEnabled(), "dockWhenFull:", AutomationManager.getAutoDockWhenFull(), "loot:", AutomationManager.getAutoLootEnabled())
        end
        -- Always apply loaded values, even if they are false
        if scan ~= nil then AutomationManager.setAutoScanEnabled(scan) end
        if mine ~= nil then AutomationManager.setAutoMineEnabled(mine) end
        if dock ~= nil then AutomationManager.setAutoDockEnabled(dock) end
        if dockWhenFull ~= nil then AutomationManager.setAutoDockWhenFull(dockWhenFull) end
        if loot ~= nil then AutomationManager.setAutoLootEnabled(loot) end
        if AUTOMATION_DEBUG_ENABLED then
            print("Foreman: Applied settings - scan:", AutomationManager.getAutoScanEnabled(), "mine:", AutomationManager.getAutoMineEnabled(), "dock:", AutomationManager.getAutoDockEnabled(), "dockWhenFull:", AutomationManager.getAutoDockWhenFull(), "loot:", AutomationManager.getAutoLootEnabled())
            print("Foreman: Calling updateAutomationButtonColors and updateCheckboxStates")
        end
        fm.updateAutomationButtonColors()
        fm.updateCheckboxStates()
        -- Only initialize if any values are still nil after loading
        if AutomationManager.getAutoScanEnabled() == nil or AutomationManager.getAutoMineEnabled() == nil or AutomationManager.getAutoDockEnabled() == nil or AutomationManager.getAutoDockWhenFull() == nil or AutomationManager.getAutoLootEnabled() == nil then
            if AUTOMATION_DEBUG_ENABLED then
                print("Foreman: Some values are nil after loading, initializing defaults")
            end
            AutomationManager.initializeAutomationSettingsWrapper()
        else
            if AUTOMATION_DEBUG_ENABLED then
                print("Foreman: All values loaded successfully, no initialization needed")
            end
        end
        if AUTOMATION_DEBUG_ENABLED then
            print("Foreman: receiveLoadedSettings completed")
        end
        if yieldVisible ~= nil then 
            yieldVisiblePreference = yieldVisible
        else
            yieldVisiblePreference = true -- Default to showing yield window
        end
        if yieldWindow then
            if yieldVisiblePreference then
                yieldWindow:show()
            else
                yieldWindow:hide()
            end
        end
    end
end
function SettingsManager.saveSettingsToServer(scan, mine, dock, dockWhenFull, loot, yieldVisible)
    if onServer() then
        if AUTOMATION_DEBUG_ENABLED then
            print("Foreman: Saving settings - scan:", scan, "mine:", mine, "dock:", dock, "dockWhenFull:", dockWhenFull, "loot:", loot, "yieldVisible:", yieldVisible)
            print("Foreman: Saving as booleans - scan:", scan == 1 or scan == true, "mine:", mine == 1 or mine == true, "dock:", dock == 1 or dock == true, "dockWhenFull:", dockWhenFull == 1 or dockWhenFull == true, "loot:", loot == 1 or loot == true, "yieldVisible:", yieldVisible == 1 or yieldVisible == true)
        end
        
        -- CRITICAL FIX: Don't fallback to random player - this causes wrong settings to be saved
        if callingPlayer == nil then
            print("Foreman: ERROR - saveSettingsToServer called without callingPlayer. Cannot determine which player's settings to save.")
            return
        end
        
        local player = Player(callingPlayer)
        if not player then 
            print("Foreman: ERROR - Could not get Player object for callingPlayer:", callingPlayer)
            return 
        end
        
        if player then
            -- Ensure boolean values are stored as booleans, not numbers
            player:setValue("foreman_autoScan", scan == 1 or scan == true)
            player:setValue("foreman_autoMine", mine == 1 or mine == true)
            player:setValue("foreman_autoDock", dock == 1 or dock == true)
            player:setValue("foreman_autoDockWhenFull", dockWhenFull == 1 or dockWhenFull == true)
            player:setValue("foreman_autoLoot", loot == 1 or loot == true)
            player:setValue("foreman_yieldVisible", yieldVisible == 1 or yieldVisible == true)
            if AUTOMATION_DEBUG_ENABLED then
                print("Foreman: Settings saved for player", player.index)
            end
        end
    end
end
function SettingsManager.forceSaveModData(yieldVisiblePreference)
    if onServer() then
        local player = Player(callingPlayer)
        local galaxy = Galaxy()
        galaxy:setValue("foreman_" .. player.index .. "_autoScan", AutomationManager.getAutoScanEnabled() == true)
        galaxy:setValue("foreman_" .. player.index .. "_autoMine", AutomationManager.getAutoMineEnabled() == true) 
        galaxy:setValue("foreman_" .. player.index .. "_autoDock", AutomationManager.getAutoDockEnabled() == true)
        galaxy:setValue("foreman_" .. player.index .. "_autoDockWhenFull", AutomationManager.getAutoDockWhenFull() == true)
        galaxy:setValue("foreman_" .. player.index .. "_autoLoot", AutomationManager.getAutoLootEnabled() == true)
        galaxy:setValue("foreman_" .. player.index .. "_yieldVisible", yieldVisiblePreference)
    end
end
function SettingsManager.syncToServer(scan, mine, dock, dockWhenFull, loot)
    if onServer() then
        AutomationManager.loadSettingsFromServer(scan, mine, dock, dockWhenFull, loot)
    end
end
function SettingsManager.confirmSave(scan, mine, dock)
    if onClient() then
    end
end
function SettingsManager.secure()
    local windowPosTable = nil
    local serverPos = WindowManager.getServerSavedWindowPos()
    if serverPos ~= nil then
        windowPosTable = { x = serverPos.x, y = serverPos.y }
    end
    local saveData = {
        windowPos = windowPosTable,
        autoScan = AutomationManager.getAutoScanEnabled(),
        autoMine = AutomationManager.getAutoMineEnabled(),
        autoDock = AutomationManager.getAutoDockEnabled(),
        autoLoot = AutomationManager.getAutoLootEnabled()
    }
    return saveData
end
function SettingsManager.restore(values)
    if values and values.windowPos ~= nil then
        WindowManager.setServerSavedWindowPos(vec2(values.windowPos.x, values.windowPos.y))
    end
    -- Don't restore automation settings from serialized state
    -- They should only be loaded from the proper settings storage
    -- Don't set any defaults here - let the receiveLoadedSettings handle initialization
    if AUTOMATION_DEBUG_ENABLED then
        print("Foreman: Restore called - not setting any automation defaults (will be handled by settings loading)")
    end
end
return SettingsManager
