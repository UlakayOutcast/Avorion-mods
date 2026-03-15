local InitializationManager = {}
MainWrapper = include("MainWrapper")
AutomationManager = include("AutomationManager")

-- Automation debugging flag - set to true to enable debugging output
local AUTOMATION_DEBUG_ENABLED = false
function InitializationManager.initialize(fm)
    if onClient() then
        invokeServerFunction("loadSettingsFromServer")
        -- Also try direct loading as fallback
        InitializationManager.loadSettingsDirectly()
    end
    -- Set defaults only if values are truly nil (first time loading)
    -- This ensures we have valid values even if settings loading fails
    if AutomationManager.getAutoScanEnabled() == nil then AutomationManager.setAutoScanEnabled(true) end
    if AutomationManager.getAutoMineEnabled() == nil then AutomationManager.setAutoMineEnabled(true) end
    if AutomationManager.getAutoDockEnabled() == nil then AutomationManager.setAutoDockEnabled(true) end
    if AutomationManager.getAutoDockWhenFull() == nil then AutomationManager.setAutoDockWhenFull(true) end
    if AutomationManager.getAutoLootEnabled() == nil then AutomationManager.setAutoLootEnabled(true) end
    fm._mineableCache = {
        t = 0,
        total = 0,
        count = 0,
        perOre = { [0] = 0, [1] = 0, [2] = 0, [3] = 0, [4] = 0, [5] = 0, [6] = 0 },
        asteroidHashes = {},
        lastAsteroidCount = 0,
        filtersChanged = false
    }
    initializeEntityCache()
    Player():registerCallback("onSectorChanged", "onSectorChanged")
    if onClient() then
        _G.onAutoScanChecked = function(checkbox, value)
            fm.onAutoScanChecked(checkbox, value)
        end
        _G.onAutoMineChecked = function(checkbox, value)
            fm.onAutoMineChecked(checkbox, value)
        end
        _G.onAutoDockChecked = function(checkbox, value)
            fm.onAutoDockChecked(checkbox, value)
        end
        _G.foremanForceRefresh = function()
            fm.forceRefresh()
        end
        _G.showInfo = function()
            showInfo()
        end
        for i = 0, 6, 1 do
            local idx = i
            _G["onYieldRowClickedIdx" .. tostring(idx)] = function(btn)
                fm.onYieldRowClickedIndex(idx)
            end
            fm["onYieldRowClickedIdx" .. tostring(idx)] = function(btn)
                fm.onYieldRowClickedIndex(idx)
            end
        end
        fm.initializeUI()
        Player():registerCallback("onStateChanged", "onStateChanged")
        Player():registerCallback("onShipChanged", "onShipChanged")
        if Player().alliance then
            Player().alliance:registerCallback("onShipNameUpdated", "onShipNameUpdated")
        end
        Player():registerCallback("onSectorLeft", "onSectorLeft")
        Player():registerCallback("onConfirmSectorArrival", "onConfirmSectorArrival")
        Player():registerCallback("onShipNameUpdated", "onShipNameUpdated")
        fm.registerSectorCallbacks()
        fm.show()
        Player():registerCallback("onGameExit", "onGameExit")
        Player():registerCallback("onPlayerLeft", "onPlayerLeft")
        -- Delayed settings loading to ensure UI is ready
        deferredCallback(1.0, "InitializationManager.loadSettingsDirectly")
    end
end
function InitializationManager.loadSettingsDirectly()
    if onClient() then
        local player = Player()
        if player then
            local savedAutoScan = player:getValue("foreman_autoScan")
            local savedAutoMine = player:getValue("foreman_autoMine")
            local savedAutoDock = player:getValue("foreman_autoDock")
            local savedAutoDockWhenFull = player:getValue("foreman_autoDockWhenFull")
            local savedAutoLoot = player:getValue("foreman_autoLoot")
            
            if AUTOMATION_DEBUG_ENABLED then
                print("Foreman: Direct loading - scan:", savedAutoScan, "mine:", savedAutoMine, "dock:", savedAutoDock, "dockWhenFull:", savedAutoDockWhenFull, "loot:", savedAutoLoot)
            end
            
            if savedAutoScan ~= nil then AutomationManager.setAutoScanEnabled(savedAutoScan) end
            if savedAutoMine ~= nil then AutomationManager.setAutoMineEnabled(savedAutoMine) end
            if savedAutoDock ~= nil then AutomationManager.setAutoDockEnabled(savedAutoDock) end
            if savedAutoDockWhenFull ~= nil then AutomationManager.setAutoDockWhenFull(savedAutoDockWhenFull) end
            if savedAutoLoot ~= nil then AutomationManager.setAutoLootEnabled(savedAutoLoot) end
            
            if AUTOMATION_DEBUG_ENABLED then
                print("Foreman: Direct loading completed - scan:", AutomationManager.getAutoScanEnabled(), "mine:", AutomationManager.getAutoMineEnabled(), "dock:", AutomationManager.getAutoDockEnabled(), "dockWhenFull:", AutomationManager.getAutoDockWhenFull(), "loot:", AutomationManager.getAutoLootEnabled())
            end
        end
    end
end

function InitializationManager.enableSaving(fm)
    fm.isInitializing = false
end
return InitializationManager
