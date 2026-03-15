-- Foreman Enhanced - Performance Optimized Version

-- Debug flag for mining filter debugging
local MINING_FILTER_DEBUG = false

package.path = package.path .. ";data/scripts/lib/?.lua"
package.path = package.path .. ";data/scripts/?.lua"
package.path = package.path .. ";data/pictures/?.png"

include("callable")
include("randomext")
include("utility")
include("ForemanLib")
include("FighterChattering")
include("EntityQueryCache")

-- Debug flag - set to true to enable debug output
local DEBUG_FOREMAN = false

-- Debug print function
local function debugPrint(...)
    if DEBUG_FOREMAN then
        print("Foreman:", ...)
    end
end

-- Module includes
AutomationManager = include("AutomationManager")
WindowManager = include("WindowManager")
CrewBalance = include("CrewBalance")
InfoManager = include("InfoManager")
ScanningUIManager = include("ScanningUIManager")
YieldUIManager = include("YieldUIManager")
AsteroidCacheManager = include("AsteroidCacheManager")
ShipValidation = include("ShipValidation")
MiningFilterManager = include("MiningFilterManager")
UtilityFunctions = include("UtilityFunctions")
MainUIManager = include("MainUIManager")
ShipStatusManager = include("ShipStatusManager")
ForemanSystemManager = include("ForemanSystemManager")
MessageManager = include("MessageManager")
ScanningManager = include("ScanningManager")
SalvageTargetManager = include("SalvageTargetManager")
ShipListManager = include("ShipListManager")
InitializationManager = include("InitializationManager")
SettingsManager = include("SettingsManager")
StateManager = include("StateManager")
UpdateManager = include("UpdateManager")
UpdateLoopManager = include("UpdateLoopManager")
ScanningUIStateManager = include("ScanningUIStateManager")
ScanningEventManager = include("ScanningEventManager")
EntityLoadingManager = include("EntityLoadingManager")
SectorArrivalManager = include("SectorArrivalManager")
EntityEventManager = include("EntityEventManager")
SectorChangeManager = include("SectorChangeManager")
CallbackRegistrationManager = include("CallbackRegistrationManager")
FighterEventManager = include("FighterEventManager")
ShipChangeManager = include("ShipChangeManager")
CraftSeatEventManager = include("CraftSeatEventManager")
ShipStatusUpdateManager = include("ShipStatusUpdateManager")
ShipDiscoveryManager = include("ShipDiscoveryManager")
SectorLeftManager = include("SectorLeftManager")
ShipCallbackRegistrationManager = include("ShipCallbackRegistrationManager")
ShipNameUpdateManager = include("ShipNameUpdateManager")
FighterChatterManager = include("FighterChatterManager")
SaveConfirmationManager = include("SaveConfirmationManager")
ModDistributionManager = include("ModDistributionManager")
AutoDockMessageManager = include("AutoDockMessageManager")
ForemanInfoMessageManager = include("ForemanInfoMessageManager")
UIIntializationManager = include("UIIntializationManager")
SettingsRequestManager = include("SettingsRequestManager")
JumpHandling = include("JumpHandling")
MainWrapper = include("MainWrapper")
AutomationToggleManager = include("AutomationToggleManager")
PlayerOperations = include("PlayerOperations")
ShipEventHandler = include("ShipEventHandler")
DeferredCallbackManager = include("DeferredCallbackManager")
GlobalCallbackManager = include("GlobalCallbackManager")
AutoDockManager = include("AutoDockManager")
WindowVisibilityManager = include("WindowVisibilityManager")
GlobalBridgeFunctions = include("GlobalBridgeFunctions")
AsteroidUtils = include("AsteroidUtils")
-- All wrapper functions are now consolidated in MainWrapper

-- Namespace fm
fm = {}

local sectorScanned = false
local sectorScanTime = 0
local sectorScanTimeRemaining = nil
local shouldUpdate = false
-- Automation settings are now managed by AutomationManager module
-- processedFullShips is now managed by AutomationManager module
-- Window position tracking is now managed by WindowManager module
local window
local readyToLoad = false
local shipListEx
local ships = {}
local shipUuidToRow = {}
local prevToggleStates = {}
local miningAmountLeftLabel
local minimizeButton
local startMiningButton
local stopMiningButton
local startSalvageButton
local stopSalvageButton
local recallFullShipsButton
local balanceCrewButton
local autoBalanceCrewCheckbox
local scanContainer
local scanButton
local activeScanFactionIndex = nil
local scanProgress
local scanLabel
local scanAccuracy
local autoScanCheckbox
local autoMineCheckbox
local autoDockCheckbox
local autoDockWhenFullCheckbox
local autoLootCheckbox
local autoScanLabel
local autoMineLabel
local autoDockLabel
local autoDockWhenFullLabel
local autoLootLabel

-- Yield UI elements
local yieldWindow
local yieldHeaderLabel
local yieldAccuracyLabel
local yieldAsteroidCountLabel
local yieldSalvageCountLabel
local yieldLabels = {}
local yieldNameLabels = {}
local yieldValueLabels = {}
local yieldRowButtons = {}
local yieldVisiblePreference = true  -- Default to true (shown)
-- yieldLastClick variables are now managed by YieldUIManager module
local yieldStatusOverride = nil

-- Automation settings panel
local automationWindow
local automationVisible = false

local harvest = false
local salvage = false

-- Auto-dock timer variables
local autoDockTimer = 5
local autoDockDelay = 5  -- 5 second delay
local autoDockPending = false

local fullCargoThreshHold = 400

local miningFilters = {}
-- Initialize mining filters with default values (all materials enabled)
for i = 0, 6 do
    miningFilters[i] = true
end
fm.miningFilters = miningFilters
local foremanMaterialLevel
local shipHasForemanSystem = false

local filterCheckBoxes = {}

local uiRefreshInterval = 1
local uiRefreshtimeLeft = uiRefreshInterval

local cargoRefheshInterval = 1.0  -- Optimized: Reduced from 0.1 to 1.0 for better performance
local cargoTimeLeft = cargoRefheshInterval

-- Salvage count update timer for more frequent updates during active salvaging
local salvageCountUpdateInterval = 0.3  -- Update salvage count every 0.3 seconds for real-time feel
local salvageCountUpdateLeft = salvageCountUpdateInterval

-- Manual periodic save timer since deferred callbacks might not work
local periodicSaveInterval = 10.0
local periodicSaveTimeLeft = periodicSaveInterval



function fm.initialize()
    InitializationManager.initialize(fm)
end


function fm.onGameExit()
    SettingsManager.onGameExit()
end

function fm.onPlayerLeft()
    SettingsManager.onPlayerLeft()
end

function fm.periodicSaveSettings(fromUpdate)
    SettingsManager.periodicSaveSettings(fromUpdate)
end

-- Unified function to save automation settings
function fm.saveAutomationSettings()
    SettingsManager.saveAutomationSettings(yieldVisiblePreference)
end

function fm.delayedAutoScan()
    AutomationManager.delayedAutoScanWrapper(sectorScanned, sectorScanTimeRemaining, ScanningManager.startScanning)
end

function fm.delayedAutoMine()
    AutomationManager.delayedAutoMineWrapper(sectorScanned, harvest, fm.startMiningPressed)
end

function fm.delayedAutoDock()
    AutoDockManager.delayedAutoDock(fm.getMineableAmountInVicinity, AutomationManager)
end

function fm.secure()
    return SettingsManager.secure()
end

function fm.restore(values)
    SettingsManager.restore(values)
end

-- Global secure/restore wrappers so Avorion can serialize this script's state
function secure()
    return fm.secure()
end

function restore(values)
    fm.restore(values)
end

function fm.getUpdateInterval()
    return UpdateManager.getUpdateInterval()
end

function fm.update(timeStep)
    periodicSaveTimeLeft, cargoTimeLeft, uiRefreshtimeLeft, autoDockPending, autoDockTimer, sectorScanTimeRemaining, harvest, salvageCountUpdateLeft = UpdateLoopManager.update(
        timeStep, fm, window, shouldUpdate, minimized, 
        periodicSaveTimeLeft, periodicSaveInterval, cargoTimeLeft, cargoRefheshInterval,
        uiRefreshtimeLeft, uiRefreshInterval, autoDockPending, autoDockTimer, autoDockDelay,
        sectorScanned, sectorScanTimeRemaining, sectorScanTime, shipHasForemanSystem,
        scanAccuracy, harvest, salvage, ships, miningAmountLeftLabel, scanProgress,
        startMiningButton, stopMiningButton, yieldSalvageCountLabel, filterCheckBoxes,
        salvageCountUpdateLeft, salvageCountUpdateInterval
    )
end

-- Wrapper function for forceAsteroidCountUpdate (called from AsteroidCleanup)
function fm.forceAsteroidCountUpdateWrapper(factionIndex)
    YieldUIManager.forceAsteroidCountUpdate(factionIndex, shipHasForemanSystem, sectorScanned, fm._mineableCache, scanAccuracy, fm.getMineableAmountInVicinity, fm.updateYieldUI)
end
callable(fm, "forceAsteroidCountUpdateWrapper")

-- Add missing callable declarations for functions called from other scripts
callable(fm, "getSalvageTargetCount")
callable(fm, "getMineableAmountInVicinity")
callable(fm, "updateYieldUI")
callable(fm, "onLoad")
callable(fm, "clearShipList")
callable(fm, "forceRefresh")
callable(fm, "updateAutomationButtonColors")
callable(fm, "saveAutomationSettings")
callable(fm, "onShipRowSelected")
callable(fm, "updateCheckboxStates")
callable(fm, "onSectorChanged")
callable(fm, "onPlayerLeft")
callable(fm, "resetAutomationSettings")
callable(fm, "periodicSaveSettings")
callable(fm, "delayedAutoScan")
callable(fm, "delayedAutoMine")
callable(fm, "delayedAutoDock")
callable(fm, "startMiningPressed")
callable(fm, "stopMiningPressed")
callable(fm, "startSalvagingPressed")
callable(fm, "stopSalvagingPressed")
callable(fm, "scanButtonPressed")
callable(fm, "toggleYieldWindow")
callable(fm, "toggleAutomationWindow")
callable(fm, "initialize")
callable(fm, "requestLoadFromServer")
callable(fm, "onJump")

function fm.invalidateAsteroidCache()
    AsteroidCacheManager.invalidateAsteroidCache(fm._mineableCache)
end

function fm.invalidateAsteroidCacheOnDestruction()
    AsteroidCacheManager.invalidateAsteroidCacheOnDestruction(fm._mineableCache)
end

function fm.invalidateAsteroidCacheOnFilterChange()
    AsteroidCacheManager.invalidateAsteroidCacheOnFilterChange(fm._mineableCache)
end

function fm.onStateChanged(newState, oldState)
    StateManager.onStateChanged(newState, oldState, window, fm)
end

function fm.saveWindowPos_server(position)
    WindowManager.saveWindowPos_server(position)
end
callable(fm, "saveWindowPos_server")

function fm.loadWindowPos_client()
    WindowManager.loadWindowPos_client()
end

function fm.sendWindowPos_server()
    WindowManager.sendWindowPos_server(callingPlayer)
end
callable(fm, "sendWindowPos_server")

function fm.setWindowPos_client(position)
    WindowManager.setWindowPos_client(position, window)
end
callable(fm, "setWindowPos_client")

function fm.show()
    WindowVisibilityManager.show(window, WindowManager, function() shouldUpdate = true end)
end

function fm.hide()
    WindowVisibilityManager.hide(window, WindowManager, function() shouldUpdate = false end)
end

local uiContainer
local minimized = false
local unminimizedHeight
local callbacksRegistered = false

function fm.toggleMinimize()
    minimized = WindowManager.toggleMinimize(window, minimized, unminimizedHeight, uiContainer)
end

function fm.initializeUI()
    local uiElements = UIIntializationManager.initializeUI(nil, fm.ensureAutomationUI, fm.loadWindowPos_client, nil, InfoManager.checkIfFirstTimeLoad, fm.updateCheckboxStates, fm.onLoad)
    
    -- Assign UI elements to local variables
    window = uiElements.window
    uiContainer = uiElements.uiContainer
    unminimizedHeight = uiElements.unminimizedHeight
    shipListEx = uiElements.shipListEx
    startMiningButton = uiElements.startMiningButton
    stopMiningButton = uiElements.stopMiningButton
    startSalvageButton = uiElements.startSalvageButton
    stopSalvageButton = uiElements.stopSalvageButton
    recallFullShipsButton = uiElements.recallFullShipsButton
    balanceCrewButton = uiElements.balanceCrewButton
    yieldSalvageCountLabel = uiElements.yieldSalvageCountLabel
    miningAmountLeftLabel = uiElements.miningAmountLeftLabel
    scanProgress = uiElements.scanProgress
    autoScanCheckbox = uiElements.autoScanCheckbox
    autoMineCheckbox = uiElements.autoMineCheckbox
    autoDockCheckbox = uiElements.autoDockCheckbox
    autoScanLabel = uiElements.autoScanLabel
    autoMineLabel = uiElements.autoMineLabel
    autoDockLabel = uiElements.autoDockLabel
    filterCheckBoxes = uiElements.filterCheckBoxes
    
    -- Ensure local scanAccuracy and foremanMaterialLevel are populated for this module
    if onClient() and Player() and Player().craft then
        local ok, sa, fml = pcall(function()
            local sa2, fml2 = ForemanSystemManager.getAndSetForemanModuleMiningAccuracy(Player().craft.id, scanAccuracy, foremanMaterialLevel)
            return sa2, fml2
        end)
        if ok then
            scanAccuracy = sa
            foremanMaterialLevel = fml
            fm.foremanMaterialLevel = foremanMaterialLevel
        end
    end
    
    -- Now that UI elements are assigned, call the UI-dependent callbacks
    fm.ensureYieldUI()
    fm.ensureAutomationUI()
    fm.initScanUI()
end
-- Crew balancing: client triggers sector function on server



function fm.tryAddShipToList(shipId)
    ShipListManager.tryAddShipToList(shipId, ships, shipListEx, shipUuidToRow)
end

function fm.createShipUIElement(shipId)
    ShipListManager.createShipUIElement(shipId, ships, shipListEx, shipUuidToRow)
end

function fm.setCargoFillPercentage(rowIndex, freePercentage)
    ShipStatusManager.setCargoFillPercentage(shipListEx, rowIndex, freePercentage)
end

local shipSelectionDoubleClickTime = 0.4
local shipSelectionChanged = false
local clickedShipId
local clickedShipUuid
local clickedShipUuidStr

-- Handle row selection to detect checkbox clicks
function fm.onShipRowSelected(index)
    -- Call the original ship selection logic
    clickedShipId, clickedShipUuid, clickedShipUuidStr, shipSelectionChanged = ShipListManager.onShipRowSelected(index, ships, clickedShipId, clickedShipUuid, clickedShipUuidStr, shipSelectionChanged)
end

-- Global bridge for row selection callback
       function onShipRowSelected(index)
    GlobalBridgeFunctions.onShipRowSelected(index, fm)
end


function fm.clearClickedShipId()
    shipSelectionChanged, clickedShipId = ShipListManager.clearClickedShipId(shipSelectionChanged, clickedShipId)
end


function fm.updateShipListFreeCargo()
    ShipListManager.updateShipListFreeCargo(ships, recallFullShipsButton, fm.setCargoFillPercentage)
end

function fm.setShipIconStatuses(shipIndex)
    ShipListManager.setShipIconStatuses(shipIndex, ships, shipListEx)
end

-- oreTooltips is now managed by YieldUIManager module

function fm.setMiningAmountLabelText(resourcesToMine, asteroidCount, resources, scanAccuracy, filterCheckBoxes)
    YieldUIManager.setMiningAmountLabelText(resourcesToMine, asteroidCount, resources, scanAccuracy, filterCheckBoxes)
end

callable(fm, "onIronChecked")
callable(fm, "onTitaniumChecked")
callable(fm, "onNaoniteChecked")
callable(fm, "onTriniumChecked")
callable(fm, "onXanionChecked")
callable(fm, "onOgoniteChecked")
callable(fm, "onAvorionChecked")

function fm.syncMiningFilterToServer(miningFilterIndex, value)
    MiningFilterManager.syncMiningFilterToServer(miningFilterIndex, value)
end


callable(MessageManager, "sendFactionMessage")

function fm.getSectorOperationsStatus_server()
    PlayerOperations.getSectorOperationsStatus_server(callingPlayer)
end
callable(fm, "getSectorOperationsStatus_server")

function fm.sectorOperationsStatus_received(playerIndex, harvestStatus, salvageStatus, inMiningFilters)
    harvest, salvage = PlayerOperations.sectorOperationsStatus_received(playerIndex, harvestStatus, salvageStatus, inMiningFilters, harvest, salvage, miningFilters, filterCheckBoxes, startMiningButton, stopMiningButton, startSalvageButton, stopSalvageButton, recallFullShipsButton)
end
callable(fm, "sectorOperationsStatus_received")

function fm.startMiningPressed()
    harvest, autoDockPending, autoDockTimer, foremanMaterialLevel, scanAccuracy = PlayerOperations.startMiningPressed(harvest, startMiningButton, stopMiningButton, autoDockPending, autoDockTimer, foremanMaterialLevel, scanAccuracy, miningFilters, fm.getMineableAmountInVicinity)
end

function fm.startSalvagingPressed()
    salvage, autoDockPending, autoDockTimer = PlayerOperations.startSalvagingPressed(salvage, startSalvageButton, stopSalvageButton, yieldSalvageCountLabel, fm.getSalvageTargetCount, autoDockPending, autoDockTimer, foremanMaterialLevel, miningFilters)
end

function fm.launchMiningFighters(factionIndex, foremanMaterial, inMiningFilters)
    harvest = PlayerOperations.launchMiningFighters(factionIndex, foremanMaterial, inMiningFilters, harvest, callingPlayer)
end
callable(fm, "launchMiningFighters")

function fm.launchSalvageFighters(factionIndex, foremanMaterial, inMiningFilters)
    salvage = PlayerOperations.launchSalvageFighters(factionIndex, foremanMaterial, inMiningFilters, salvage, callingPlayer)
end
callable(fm, "launchSalvageFighters")

function fm.restartMiningOnFilterChange(factionIndex)
    if onClient() then
        if MINING_FILTER_DEBUG then
            print("[FILTER DEBUG] Client calling restartMiningOnFilterChange for faction " .. factionIndex)
        end
        invokeServerFunction("restartMiningOnFilterChange", factionIndex)
    else
        if MINING_FILTER_DEBUG then
            print("[FILTER DEBUG] Server calling assignMiningSquadsRandomly for each ship")
        end
        -- Use existing callable function to reassign squads for each ship
        local x, y = Sector():getCoordinates()
        -- Get all ships for this faction and reassign their squads
        local entities = {Sector():getEntitiesByType(EntityType.Ship)}
        for _, entity in pairs(entities) do
            if entity.factionIndex == factionIndex then
                invokeSectorFunction(x, y, true, "data/scripts/sector/ForemanSector.lua", "assignMiningSquadsRandomly", factionIndex, entity.index)
            end
        end
    end
end
callable(fm, "restartMiningOnFilterChange")


function fm.operationStarted(miningOperation)
    harvest, salvage = PlayerOperations.operationStarted(miningOperation, harvest, startMiningButton, stopMiningButton, salvage, startSalvageButton, stopSalvageButton, fm.getMineableAmountInVicinity)
end
callable(fm, "operationStarted")

function fm.operationStopped(miningOperation)
    harvest, salvage = PlayerOperations.operationStopped(miningOperation, harvest, startMiningButton, stopMiningButton, salvage, startSalvageButton, stopSalvageButton)
end
callable(fm, "operationStopped")

function fm.stopMiningPressed()
    harvest, autoDockPending, autoDockTimer = PlayerOperations.stopMiningPressed(harvest, startMiningButton, stopMiningButton, autoDockPending, autoDockTimer, salvage, recallFullShipsButton)
end

function fm.stopSalvagingPressed()
    salvage, autoDockPending, autoDockTimer = PlayerOperations.stopSalvagingPressed(salvage, startSalvageButton, stopSalvageButton, yieldSalvageCountLabel, fm.getSalvageTargetCount, autoDockPending, autoDockTimer, harvest, recallFullShipsButton)
end

function fm.returnMiningSquads(factionIndex)
    harvest = PlayerOperations.returnMiningSquads(factionIndex, harvest, callingPlayer)
end
callable(fm, "returnMiningSquads")

function fm.returnSalvageSquads(factionIndex)
    salvage = PlayerOperations.returnSalvageSquads(factionIndex, salvage, callingPlayer)
end
callable(fm, "returnSalvageSquads")

function fm.recallFullShips()
    ShipListManager.recallFullShips(ships, recallFullShipsButton)
end

function fm.checkAutoDockWhenFull()
    AutomationManager.checkAutoDockWhenFull(ships, harvest, salvage)
end

function fm.initScanUI()
    ScanningUIManager.initScanUI(uiContainer, window)
    
    -- Get references to UI elements for backward compatibility
    scanButton = ScanningUIManager.getScanButton()
    scanContainer = ScanningUIManager.getScanContainer()
    scanProgress = ScanningUIManager.getScanProgress()
    scanLabel = ScanningUIManager.getScanLabel()
end

-- Ensure Yield UI container exists
function fm.ensureYieldUI()
    YieldUIManager.ensureYieldUI(uiContainer, miningFilters)
    
    -- Get references to UI elements for backward compatibility
    yieldWindow = YieldUIManager.getYieldWindow()
    yieldHeaderLabel = YieldUIManager.getYieldHeaderLabel()
    yieldAccuracyLabel = YieldUIManager.getYieldAccuracyLabel()
    yieldAsteroidCountLabel = YieldUIManager.getYieldAsteroidCountLabel()
    yieldSalvageCountLabel = YieldUIManager.getYieldSalvageCountLabel()
    yieldNameLabels = YieldUIManager.getYieldNameLabels()
    yieldValueLabels = YieldUIManager.getYieldValueLabels()
    yieldRowButtons = YieldUIManager.getYieldRowButtons()
end

-- Ensure Automation Settings UI container exists
function fm.ensureAutomationUI()
    AutomationManager.ensureAutomationUI(uiContainer, window)
    
    -- Get references to UI elements for backward compatibility
    automationWindow = AutomationManager.getAutomationWindow()
    autoScanLabel = AutomationManager.getAutoScanLabel()
    autoScanCheckbox = AutomationManager.getAutoScanCheckbox()
    autoMineLabel = AutomationManager.getAutoMineLabel()
    autoMineCheckbox = AutomationManager.getAutoMineCheckbox()
    autoDockLabel = AutomationManager.getAutoDockLabel()
    autoDockCheckbox = AutomationManager.getAutoDockCheckbox()
    autoDockWhenFullLabel = AutomationManager.getAutoDockWhenFullLabel()
    autoDockWhenFullCheckbox = AutomationManager.getAutoDockWhenFullCheckbox()
    autoLootLabel = AutomationManager.getAutoLootLabel()
    autoLootCheckbox = AutomationManager.getAutoLootCheckbox()
end

function fm.toggleYieldWindow()
    yieldVisiblePreference = YieldUIManager.toggleYieldWindow(uiContainer, miningFilters, yieldVisiblePreference, fm.saveAutomationSettings)
end


function fm.toggleAutomationWindow()
    automationVisible = AutomationManager.toggleAutomationWindow(uiContainer, automationVisible, nil, nil, window)
end

-- Update Yield UI according to scanAccuracy
function fm.updateYieldUI(totalAmount, asteroidCount, perOre)
    YieldUIManager.updateYieldUI(totalAmount, asteroidCount, perOre, window, uiContainer, sectorScanned, shipHasForemanSystem, yieldVisiblePreference, scanAccuracy, miningFilters, fm.getSalvageTargetCount)
end

-- Update yield UI with fresh data after scan completion
function fm.updateYieldUIAfterScan()
    -- Ensure shipHasForemanSystem and scan params are populated after a jump
    if onClient() and Player() and Player().craft then
        local craft = Player().craft
        if ShipValidation.shipHasForemanModule(craft.id) then
            shipHasForemanSystem = true
            local ok, sa, fml = pcall(function()
                return ForemanSystemManager.getAndSetForemanModuleMiningAccuracy(craft.id, scanAccuracy, foremanMaterialLevel)
            end)
            if ok then
                scanAccuracy = sa
                foremanMaterialLevel = fml
                fm.foremanMaterialLevel = foremanMaterialLevel
            end
        end
    end
    -- Try local calculation first
    YieldUIManager.updateYieldUIAfterScan(scanAccuracy, fm.getMineableAmountInVicinity, fm.updateYieldUI)
    -- Request authoritative numbers from server as fallback
    if onClient() then
        local wantsPerOre = (scanAccuracy == 4) or (scanAccuracy == 2)
        local craft = Player() and Player().craft
        if craft then
            local x, y = Sector():getCoordinates()
            -- Call the sector script where the callable is registered
            invokeSectorFunction(x, y, true, "data/scripts/sector/ForemanSector.lua", "getYieldSummary", craft.factionIndex, wantsPerOre)
        end
    end
end

-- Receive authoritative server-side yield numbers (fallback)
function fm.receiveYieldSummary(total, count, per)
    -- Ensure the yield panel is visible after first server summary in a sector
    yieldVisiblePreference = true
    if yieldWindow then yieldWindow:show() end
    fm.updateYieldUI(total or 0, count or 0, per)
end
callable(fm, "receiveYieldSummary")

function fm.onYieldRowClickedIndex(materialIndex)
    YieldUIManager.onYieldRowClickedIndex(materialIndex, miningFilters, scanAccuracy, fm.syncMiningFilterToServer, fm.invalidateAsteroidCacheOnFilterChange, fm.getMineableAmountInVicinity, fm.updateYieldUI, fm)
end

-- Create per-row global bridges so Avorion UI can call them
for i = 0, 6, 1 do
    local idx = i
    _G["onYieldRowClickedIdx" .. tostring(idx)] = function(btn)
        YieldUIManager.onYieldRowClickedIndex(idx, miningFilters, scanAccuracy, fm.syncMiningFilterToServer, fm.invalidateAsteroidCacheOnFilterChange, fm.getMineableAmountInVicinity, fm.updateYieldUI, fm)
    end
end

function fm.scanButtonPressed()
    ScanningManager.scanButtonPressed()
end

function fm.startScanning(factionIndex, scanTime, shipIndex)
    ScanningManager.startScanning(factionIndex, scanTime, shipIndex)
end
callable(fm, "startScanning")

-- New toggle button callbacks (like yield buttons)
function fm.onAutoScanToggle()
    AutomationManager.onAutoScanToggle(fm.updateAutomationButtonColors, fm.saveAutomationSettings)
end
callable(fm, "onAutoScanToggle")

function fm.onAutoMineToggle()
    AutomationManager.onAutoMineToggle(fm.updateAutomationButtonColors, fm.saveAutomationSettings)
end
callable(fm, "onAutoMineToggle")

function fm.onAutoDockToggle()
    AutomationManager.onAutoDockToggle(fm.updateAutomationButtonColors, fm.saveAutomationSettings)
end

function fm.onAutoDockWhenFullToggle()
    AutomationToggleManager.onAutoDockWhenFullToggle(fm)
end

function fm.onAutoLootToggle()
    AutomationManager.onAutoLootToggle(fm.updateAutomationButtonColors, fm.saveAutomationSettings)
end
callable(fm, "onAutoDockToggle")
callable(fm, "onAutoDockWhenFullToggle")
callable(fm, "onAutoLootToggle")

-- Legacy checkbox callbacks (kept for compatibility)
function fm.onAutoScanChecked(checkbox, value)
    AutomationToggleManager.onAutoScanChecked(checkbox, value, fm)
end
callable(fm, "onAutoScanChecked")

function fm.onAutoMineChecked(checkbox, value)
    AutomationToggleManager.onAutoMineChecked(checkbox, value, fm)
end
callable(fm, "onAutoMineChecked")

function fm.onAutoDockChecked(checkbox, value)
    AutomationToggleManager.onAutoDockChecked(checkbox, value, fm)
end
callable(fm, "onAutoDockChecked")



function fm.forceSaveSettings()
    SettingsManager.forceSaveSettings(yieldVisiblePreference)
end

-- Update automation label colors (red=off, green=on, like yield buttons)
function fm.updateAutomationButtonColors()
    StateManager.updateAutomationButtonColors(autoScanLabel, autoMineLabel, autoDockLabel, autoDockWhenFullLabel, autoLootLabel)
end

function fm.updateCheckboxStates()
    StateManager.updateCheckboxStates(fm, autoScanLabel, autoMineLabel, autoDockLabel, autoDockWhenFullLabel, autoLootLabel)
end

function fm.requestLoadFromServer()
    SettingsRequestManager.requestLoadFromServer()
end
-- Global wrapper for deferred call
function requestLoadFromServer()
    GlobalBridgeFunctions.requestLoadFromServer(fm)
end

function fm.loadSettingsFromServer()
    SettingsRequestManager.loadSettingsFromServer()
end

function fm.receiveLoadedSettings(scan, mine, dock, dockWhenFull, loot, yieldVisible)
    SettingsRequestManager.receiveLoadedSettings(scan, mine, dock, dockWhenFull, loot, yieldVisible, fm, yieldVisiblePreference, yieldWindow)
end

-- Ensure ship list selection callback is globally exposed
function onShipSelected(index)
    clickedShipId, clickedShipUuid, clickedShipUuidStr, shipSelectionChanged = ShipListManager.onShipSelected(index, ships, clickedShipId, clickedShipUuid, clickedShipUuidStr, shipSelectionChanged)
end

-- Global function for deferred callback
function updateCheckboxStates()
    GlobalBridgeFunctions.updateCheckboxStates(fm)
end

-- Global wrapper for sector change callback
function onSectorChanged(x, y)
    GlobalBridgeFunctions.onSectorChanged(x, y, fm)
end

-- Global wrapper for player left callback
function onPlayerLeft()
    GlobalBridgeFunctions.onPlayerLeft(fm)
end


function enableSaving()
    InitializationManager.enableSaving(fm)
end

function fm.showScan()
    ScanningUIStateManager.showScan(scanProgress, scanButton, autoScanCheckbox, autoMineCheckbox, autoDockCheckbox, autoScanLabel, autoMineLabel, autoDockLabel, scanLabel, scanContainer)
end

function fm.hideScan()
    ScanningUIStateManager.hideScan(scanProgress, scanButton, autoScanCheckbox, autoMineCheckbox, autoDockCheckbox, autoScanLabel, autoMineLabel, autoDockLabel, scanLabel, scanContainer)
    -- Show the mining/salvaging buttons
    if startMiningButton then startMiningButton:show() end
    if stopMiningButton then stopMiningButton:show() end
    if startSalvagingButton then startSalvagingButton:show() end
    if stopSalvagingButton then stopSalvagingButton:show() end
end


function fm.scanStarted(scanTime)
    sectorScanTimeRemaining, sectorScanTime = ScanningEventManager.scanStarted(scanTime, fm.showScan, sectorScanTimeRemaining, sectorScanTime)
    if onClient() then
        local craft = Player() and Player().craft
        if craft then activeScanFactionIndex = craft.factionIndex end
    end
end
callable(fm, "scanStarted")

function fm.scanCancelled()
    sectorScanTimeRemaining = ScanningEventManager.scanCancelled(fm.hideScan, sectorScanTimeRemaining)
    activeScanFactionIndex = nil
end
callable(fm, "scanCancelled")

function fm.sectorScanComplete()
    if onServer() then
        invokeClientFunction(Player(), "sectorScanComplete")
    else
        sectorScanned = true
        sectorScanTimeRemaining = nil
        activeScanFactionIndex = nil

		-- Ensure shipHasForemanSystem and scan parameters are populated before updating yield UI
		if onClient() and Player() and Player().craft then
			local craft = Player().craft
			if ShipValidation.shipHasForemanModule(craft.id) then
				shipHasForemanSystem = true
				local ok, sa, fml = pcall(function()
					return ForemanSystemManager.getAndSetForemanModuleMiningAccuracy(craft.id, scanAccuracy, foremanMaterialLevel)
				end)
				if ok then
					scanAccuracy = sa
					foremanMaterialLevel = fml
					fm.foremanMaterialLevel = foremanMaterialLevel
				end
			end
		end

        -- Force cache refresh since scan just completed with fresh data
        fm.invalidateAsteroidCache()
        -- Also refresh entity cache so asteroid list is up-to-date
        if invalidateEntityCache then invalidateEntityCache() end

		-- Force an asteroid count update to populate labels immediately
		if onClient() then
			local factionIndex = nil
			local craft = Player() and Player().craft
			if craft then factionIndex = craft.factionIndex end
			if factionIndex then
				local success, error = pcall(function()
					YieldUIManager.forceAsteroidCountUpdate(factionIndex, shipHasForemanSystem, sectorScanned, fm._mineableCache, scanAccuracy, fm.getMineableAmountInVicinity, fm.updateYieldUI)
				end)
				if not success then
					print("[ERROR] Failed to update asteroid count:", error)
				end
			end
		end

        fm.hideScan()
        scanButton:hide()
        autoScanCheckbox:show()
        autoMineCheckbox:show()
        autoDockCheckbox:show()
        autoScanLabel:show()
        autoMineLabel:show()
        autoDockLabel:show()
        startMiningButton:show()
        stopMiningButton:show()
        
        -- Update yields immediately
        local success, error = pcall(function()
            fm.updateYieldUIAfterScan()
        end)
        if not success then
            print("[ERROR] Failed to update yield UI after scan:", error)
        end
        
        -- Ensure the yield panel is visible after a scan completes
        yieldVisiblePreference = true
        if yieldWindow then yieldWindow:show() end
        SettingsManager.saveAutomationSettings(yieldVisiblePreference)
        
        -- Auto-mine if enabled and asteroids are found
        if AutomationManager.getAutoMineEnabled() then
            local resourcesLeftTotal, asteroidCount = fm.getMineableAmountInVicinity(true)
            if resourcesLeftTotal > 0 and asteroidCount > 0 then
                deferredCallback(0.5, "delayedAutoMine")
            end
        end
    end
end

callable(fm, "sectorScanComplete")

function fm.cancelScan()
    sectorScanTimeRemaining = MainWrapper.cancelScan()
end

function fm.getSectorScanStatus(factionIndex)
    ScanningManager.getSectorScanStatus(factionIndex)
end
callable(fm, "getSectorScanStatus")


function fm.receiveScanStatus(scanTime, timeLeft)
    sectorScanTimeRemaining, sectorScanTime = ScanningEventManager.receiveScanStatus(scanTime, timeLeft, fm.showScan, sectorScanTimeRemaining, sectorScanTime)
    if onClient() then
        local craft = Player() and Player().craft
        if craft then activeScanFactionIndex = craft.factionIndex end
    end
end
callable(fm, "receiveScanStatus")

function fm.getActiveScanFactionIndex()
    return activeScanFactionIndex
end

function fm.onLoad()
    EntityLoadingManager.onLoad(fm.handleNewShip)
end

function fm.onConfirmSectorArrival(x, y)
    SectorArrivalManager.onConfirmSectorArrival(x, y, sectorScanned, window, scanButton, autoScanCheckbox, autoMineCheckbox, autoDockCheckbox, autoScanLabel, autoMineLabel, autoDockLabel, startMiningButton, stopMiningButton, fm.show, fm.getSectorScanStatus, fm.onLoad, fm.registerShipCallbacks, readyToLoad)
end

function fm.onEntityCreated_client(entityId)
    EntityEventManager.onEntityCreated_client(entityId, readyToLoad, fm.handleNewShip)
end

function fm.onSectorChanged(x, y)
    debugPrint("onSectorChanged called for sector", x, y)
    harvest, salvage, sectorScanned, fm._mineableCache = SectorChangeManager.onSectorChanged(x, y, harvest, salvage, sectorScanned, fm._mineableCache, fm.clearShipList, fm.registerSectorCallbacks, fm.onLoad)
    debugPrint("After sector change - sectorScanned:", sectorScanned, "harvest:", harvest, "salvage:", salvage)
	-- Ensure server-side salvage operation is stopped on sector change to prevent auto-resume
	if onClient() then
		local craft = Player() and Player().craft
		if craft then
			invokeServerFunction("returnSalvageSquads", craft.factionIndex, Player().index)
		end
	end
	
	-- Immediately update yield UI to show placeholders since sector is no longer scanned
	if onClient() then
		debugPrint("Updating yield UI to show placeholders after sector change")
		fm.updateYieldUI(0, 0, nil)
	end
end

function fm.registerSectorCallbacks()
    CallbackRegistrationManager.registerSectorCallbacks(callbacksRegistered)
end

function fm.onFighterAdded(shipId, squadIndex, fighterIndex, landed)
    FighterEventManager.onFighterAdded(shipId, squadIndex, fighterIndex, landed, fm.setShipIconStatuses)
end

function fm.onFighterRemoved(shipId, squadIndex, fighterIndex, started)
    FighterEventManager.onFighterRemoved(shipId, squadIndex, fighterIndex, started, fm.setShipIconStatuses)
end

function fm.onShipChanged(playerIndex, newShipId, oldShipId)
    shipHasForemanSystem, scanAccuracy, foremanMaterialLevel, readyToLoad = ShipChangeManager.onShipChanged(playerIndex, newShipId, oldShipId, window, shipHasForemanSystem, scanAccuracy, foremanMaterialLevel, sectorScanned, readyToLoad, fm.initializeUI, fm.show, fm.hide, fm.forceRefresh, fm.getSectorScanStatus)
end

function fm.onCraftSeatEntered_client(shipIndex, seat, playerIndex, firstPlayer)
    CraftSeatEventManager.onCraftSeatEntered_client(shipIndex, seat, playerIndex, firstPlayer, ships, shipListEx)
end

function fm.onCraftSeatLeft_client(shipIndex, seat, playerIndex, playersRemaining)
    CraftSeatEventManager.onCraftSeatLeft_client(shipIndex, seat, playerIndex, playersRemaining, ships, shipListEx)
end

function fm.onSystemsChanged(shipId)
    ShipStatusUpdateManager.onSystemsChanged(shipId)
end

function fm.updateShipStatus(shipId)
    ShipStatusUpdateManager.updateShipStatus(shipId, fm.handleNewShip, fm.tryRemoveShipFromList)
end

function fm.onSystemsChanged_player(shipId)
    DeferredCallbackManager.onSystemsChanged_player(shipId)
end

function fm.deferredOnSystemsChanged_player(shipId)
    shipHasForemanSystem, scanAccuracy, foremanMaterialLevel, readyToLoad = ShipStatusUpdateManager.deferredOnSystemsChanged_player(shipId, shipHasForemanSystem, fm.setShipIconStatuses, fm.registerShipCallbacks, fm.show, readyToLoad, ForemanSystemManager.getAndSetForemanModuleMiningAccuracy, scanAccuracy, foremanMaterialLevel, fm.hide)
end

function fm.forceRefresh()
    MainWrapper.forceRefresh(fm)
end


function fm.handleNewShip(shipId)
    ShipDiscoveryManager.handleNewShip(shipId, fm.registerShipCallbacks, fm.tryAddShipToList, fm.setShipIconStatuses)
end

function fm.onSectorLeft(playerIndex, x, y, sectorChangeType)
    SectorLeftManager.onSectorLeft(playerIndex, x, y, sectorChangeType, sectorScanned, window, fm.hide)
end

function fm.registerShipCallbacks(shipId)
    ShipCallbackRegistrationManager.registerShipCallbacks(shipId)
end


function fm.tryRemoveShipFromList(shipId)
    ShipListManager.tryRemoveShipFromList(shipId, ships, shipListEx)
end


function fm.onShipNameUpdated(name, newName)
    ShipNameUpdateManager.onShipNameUpdated(name, newName, ships, shipListEx, fm.setShipIconStatuses)
end

function fm.fighterChatterMessage(fighterId, message)
    FighterChatterManager.fighterChatterMessage(fighterId, message)
end
callable(fm, "fighterChatterMessage")


function fm.onEntityRemoved_client(shipId)
    EntityEventManager.onEntityRemoved_client(shipId, fm.tryRemoveShipFromList)
end

function fm.clearShipList()
    ShipListManager.clearShipList(shipListEx, ships)
end

-- Get salvage target count from ForemanSector script
function fm.getSalvageTargetCount()
    -- Use SalvageTargetManager directly for client-side compatibility
    return SalvageTargetManager.getSalvageTargetCount()
end

function fm.balanceCrewNow()
    MainWrapper.balanceCrewNow()
end

function fm.toggleAutoBalanceCrew()
    MainWrapper.toggleAutoBalanceCrew()
end

function fm.getMineableAmountInVicinity(ignoreCargoSpace, perOre)
    return MainWrapper.getMineableAmountInVicinity(ignoreCargoSpace, perOre, fm)
end

-- Reset automation settings to defaults
function fm.resetAutomationSettings()
    MainWrapper.resetAutomationSettings()
end

-- Global function for test checkbox callbacks button
function resetAutomationSettings()
    GlobalBridgeFunctions.resetAutomationSettings(fm)
end

-- Global function for deferred callback
function periodicSaveSettings()
    GlobalBridgeFunctions.periodicSaveSettings(fm)
end

-- Global function for deferred callback
function delayedAutoScan()
    GlobalBridgeFunctions.delayedAutoScan(fm)
end

-- Global function for deferred callback
function delayedAutoMine()
    GlobalBridgeFunctions.delayedAutoMine(fm)
end

-- Global function for deferred callback
function delayedAutoDock()
    GlobalBridgeFunctions.delayedAutoDock(fm)
end

-- Global function for deferred callback
function updateYieldUIAfterScan()
    fm.updateYieldUIAfterScan()
end

function showLoadedMessage()
    MainWrapper.showLoadedMessage()
end

-- Global functions for button callbacks
function showInfo()
    if InfoManager and InfoManager.showInfo then
        InfoManager.showInfo()
    end
end

function infoNextPagePressed()
    if InfoManager and InfoManager.infoNextPagePressed then
        InfoManager.infoNextPagePressed()
    end
end

function infoPrevPagePressed()
    if InfoManager and InfoManager.infoPrevPagePressed then
        InfoManager.infoPrevPagePressed()
    end
end

function fm.infoNextPagePressed()
    if InfoManager and InfoManager.infoNextPagePressed then
        InfoManager.infoNextPagePressed()
    end
end

function fm.infoPrevPagePressed()
    if InfoManager and InfoManager.infoPrevPagePressed then
        InfoManager.infoPrevPagePressed()
    end
end

function fm.showInfo()
    if InfoManager and InfoManager.showInfo then
        InfoManager.showInfo()
    end
end

function toggleMinimize()
    minimized = WindowManager.toggleMinimize(window, minimized, unminimizedHeight, uiContainer)
end

function startMiningPressed()
    GlobalBridgeFunctions.startMiningPressed(fm)
end

function stopMiningPressed()
    GlobalBridgeFunctions.stopMiningPressed(fm)
end

function startSalvagingPressed()
    GlobalBridgeFunctions.startSalvagingPressed(fm)
end

function stopSalvagingPressed()
    GlobalBridgeFunctions.stopSalvagingPressed(fm)
end

function recallFullShips()
    ShipListManager.recallFullShips(ships, recallFullShipsButton)
end

function forceRefresh()
    fm.forceRefresh()
end

function scanButtonPressed()
    GlobalBridgeFunctions.scanButtonPressed(fm)
end

-- Global for yield toggle button
function toggleYieldWindow()
    GlobalBridgeFunctions.toggleYieldWindow(fm)
end

-- Global for automation toggle button
function toggleAutomationWindow()
    GlobalBridgeFunctions.toggleAutomationWindow(fm)
end

-- Global wrappers for new toggle button callbacks
function onAutoScanToggle()
    GlobalBridgeFunctions.onAutoScanToggle(fm)
end

function onAutoMineToggle()
    GlobalBridgeFunctions.onAutoMineToggle(fm)
end

function onAutoDockToggle()
    GlobalBridgeFunctions.onAutoDockToggle(fm)
end

-- Legacy global wrappers for checkbox callbacks (kept for compatibility)
function onAutoScanChecked(checkbox, value)
    GlobalBridgeFunctions.onAutoScanChecked(checkbox, value, fm)
end

function onAutoMineChecked(checkbox, value)
    GlobalBridgeFunctions.onAutoMineChecked(checkbox, value, fm)
end

function onAutoDockChecked(checkbox, value)
    GlobalBridgeFunctions.onAutoDockChecked(checkbox, value, fm)
end

function onAutoDockWhenFullToggle()
    GlobalBridgeFunctions.onAutoDockWhenFullToggle(fm)
end

function onAutoLootToggle()
    fm.onAutoLootToggle()
end


function fm.onIronChecked(checkbox, value)
    MiningFilterManager.onIronChecked(miningFilters, fm.invalidateAsteroidCacheOnFilterChange, fm.syncMiningFilterToServer, checkbox, value)
end
callable(fm, "onIronChecked")

function fm.onTitaniumChecked(checkbox, value)
    MiningFilterManager.onTitaniumChecked(miningFilters, fm.invalidateAsteroidCacheOnFilterChange, fm.syncMiningFilterToServer, checkbox, value)
end
callable(fm, "onTitaniumChecked")

function fm.onNaoniteChecked(checkbox, value)
    MiningFilterManager.onNaoniteChecked(miningFilters, fm.invalidateAsteroidCacheOnFilterChange, fm.syncMiningFilterToServer, checkbox, value)
end
callable(fm, "onNaoniteChecked")

function fm.onTriniumChecked(checkbox, value)
    MiningFilterManager.onTriniumChecked(miningFilters, fm.invalidateAsteroidCacheOnFilterChange, fm.syncMiningFilterToServer, checkbox, value)
end
callable(fm, "onTriniumChecked")

function fm.onXanionChecked(checkbox, value)
    MiningFilterManager.onXanionChecked(miningFilters, fm.invalidateAsteroidCacheOnFilterChange, fm.syncMiningFilterToServer, checkbox, value)
end
callable(fm, "onXanionChecked")

function fm.onOgoniteChecked(checkbox, value)
    MiningFilterManager.onOgoniteChecked(miningFilters, fm.invalidateAsteroidCacheOnFilterChange, fm.syncMiningFilterToServer, checkbox, value)
end
callable(fm, "onOgoniteChecked")

function fm.onAvorionChecked(checkbox, value)
    MiningFilterManager.onAvorionChecked(miningFilters, fm.invalidateAsteroidCacheOnFilterChange, fm.syncMiningFilterToServer, checkbox, value)
end
callable(fm, "onAvorionChecked")

-- Global wrapper functions for callable registrations
function onIronChecked(checkbox, value)
    fm.onIronChecked(checkbox, value)
end
callable(nil, "onIronChecked")

function onTitaniumChecked(checkbox, value)
    fm.onTitaniumChecked(checkbox, value)
end
callable(nil, "onTitaniumChecked")

function onNaoniteChecked(checkbox, value)
    fm.onNaoniteChecked(checkbox, value)
end
callable(nil, "onNaoniteChecked")

function onTriniumChecked(checkbox, value)
    fm.onTriniumChecked(checkbox, value)
end
callable(nil, "onTriniumChecked")

function onXanionChecked(checkbox, value)
    fm.onXanionChecked(checkbox, value)
end
callable(nil, "onXanionChecked")

function onOgoniteChecked(checkbox, value)
    fm.onOgoniteChecked(checkbox, value)
end
callable(nil, "onOgoniteChecked")

function onAvorionChecked(checkbox, value)
    fm.onAvorionChecked(checkbox, value)
end
callable(nil, "onAvorionChecked")

-- Global initialize function that Avorion looks for
function initialize()
    GlobalBridgeFunctions.initialize(fm)
end


function fm.sendAutoScanMessage()
    MainWrapper.sendAutoScanMessage()
end
callable(fm, "sendAutoScanMessage")

function fm.sendAutoMineMessage()
    MainWrapper.sendAutoMineMessage()
end
callable(fm, "sendAutoMineMessage")

function fm.sendAutoDockMessage()
    MainWrapper.sendAutoDockMessage()
end
callable(fm, "sendAutoDockMessage")

function fm.sendAutoDockWhenFullMessage(shipCount)
    MainWrapper.sendAutoDockWhenFullMessage(shipCount)
end
callable(fm, "sendAutoDockWhenFullMessage")

--

-- Save automation settings manually


function fm.saveSettingsToServer(scan, mine, dock, dockWhenFull, loot, yieldVisible)
    SettingsManager.saveSettingsToServer(scan, mine, dock, dockWhenFull, loot, yieldVisible)
end

function fm.sendSaveConfirmationMessage()
    MainWrapper.sendSaveConfirmationMessage()
end

function fm.sendLoadConfirmationMessage()
    MainWrapper.sendLoadConfirmationMessage()
end


function fm.forceSaveModData()
    SettingsManager.forceSaveModData(yieldVisiblePreference)
end

function fm.syncToServer(scan, mine, dock, dockWhenFull)
    SettingsManager.syncToServer(scan, mine, dock, dockWhenFull)
end

function fm.confirmSave(scan, mine, dock)
    SettingsManager.confirmSave(scan, mine, dock)
end

-- Mod Distribution System
function fm.checkAndDistributeModFiles(player)
    ModDistributionManager.checkAndDistributeModFiles(player, fm.sendModFilesToClient)
end

function fm.sendModFilesToClient(player)
    ModDistributionManager.sendModFilesToClient(player)
end

function fm.receiveModFiles(modInfo)
    ModDistributionManager.receiveModFiles(modInfo)
end
callable(fm, "saveSettingsToServer")
callable(fm, "loadSettingsFromServer")
callable(fm, "confirmSave")
callable(fm, "receiveLoadedSettings")
callable(fm, "forceSaveModData")
callable(fm, "syncToServer")
callable(fm, "checkAndDistributeModFiles")
callable(fm, "receiveModFiles")
callable(fm, "sendSaveConfirmationMessage")
callable(fm, "sendLoadConfirmationMessage")

--


-- Server-side function for auto-dock notification
function fm.sendAutoDockMessageServer()
    MainWrapper.sendAutoDockMessageServer()
end
callable(fm, "sendAutoDockMessageServer")

-- Server helper to safely send Foreman info lines (guards empty/whitespace)
function fm.sendForemanInfo(text)
    MainWrapper.sendForemanInfo(text)
end
callable(fm, "sendForemanInfo")


function fm.onJump(shipId)
    return MainWrapper.onJump(shipId)
end

function onJump(shipId)
    GlobalCallbackManager.onJump(shipId, fm)
end

function onShipCaptainChanged(shipId, captain)
    ShipEventHandler.onShipCaptainChanged(shipId, captain, fm.setShipIconStatuses)
end

function onShipJumpRouteCalculationStarted(shipId)
    JumpRouteHandling.onShipJumpRouteCalculationStarted(shipId, factionData)
end

function onEntityCreated_client(entityId)
    fm.onEntityCreated_client(entityId)
end

function onEntityRemoved_client(shipId)
    fm.onEntityRemoved_client(shipId)
end

function onCraftSeatEntered_client(shipIndex, seat, playerIndex, firstPlayer)
    fm.onCraftSeatEntered_client(shipIndex, seat, playerIndex, firstPlayer)
end

function onCraftSeatLeft_client(shipIndex, seat, playerIndex, playersRemaining)
    fm.onCraftSeatLeft_client(shipIndex, seat, playerIndex, playersRemaining)
end

function onSystemsChanged(shipId)
    fm.onSystemsChanged(shipId)
end

function onCrewChanged(shipId)
    fm.updateShipStatus(shipId)
end

function onFighterAdded(shipId, squadIndex, fighterIndex, landed)
    fm.onFighterAdded(shipId, squadIndex, fighterIndex, landed)
end

function onFighterRemoved(shipId, squadIndex, fighterIndex, started)
    fm.onFighterRemoved(shipId, squadIndex, fighterIndex, started)
end

function onSquadAdded(shipId, squadIndex)
    fm.updateShipStatus(shipId)
end

function onSquadRemoved(shipId, squadIndex)
    fm.updateShipStatus(shipId)
end


function onStateChanged(newState, oldState)
    fm.onStateChanged(newState, oldState)
end

function updateShipStatus(shipId)
    return fm.updateShipStatus(shipId)
end

function deferredOnSystemsChanged_player(shipId)
    return fm.deferredOnSystemsChanged_player(shipId)
end

function balanceCrewNow()
    return fm.balanceCrewNow()
end

function toggleAutoBalanceCrew()
    return fm.toggleAutoBalanceCrew()
end

function onShipChanged(playerIndex, newShipId, oldShipId)
    return fm.onShipChanged(playerIndex, newShipId, oldShipId)
end

function onShipNameUpdated(name, newName)
    return fm.onShipNameUpdated(name, newName)
end

function onSectorLeft(playerIndex, x, y, sectorChangeType)
    return fm.onSectorLeft(playerIndex, x, y, sectorChangeType)
end

function onConfirmSectorArrival(x, y)
    return fm.onConfirmSectorArrival(x, y)
end

function onGameExit()
    return fm.onGameExit()
end