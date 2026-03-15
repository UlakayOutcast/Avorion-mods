-- MainWrapper.lua - Consolidated wrapper functions for Foreman Enhanced
-- This file consolidates all wrapper scripts to reduce file count and simplify imports

local MainWrapper = {}

-- Include all required modules
AutomationManager = include("AutomationManager")
-- MessageWrapperManager functions are called directly to avoid circular dependencies
LootManager = include("LootManager")
ScanningManager = include("ScanningManager")
CrewBalance = include("CrewBalance")
JumpHandling = include("JumpHandling")
ScanningEventManager = include("ScanningEventManager")
ShipDataManager = include("ShipDataManager")
SquadOrdersHandling = include("SquadOrdersHandling")
MiningSquadReturnManager = include("MiningSquadReturnManager")
SalvageSquadReturnManager = include("SalvageSquadReturnManager")
IdleFighterAssignmentManager = include("IdleFighterAssignmentManager")
-- SalvageSquadAssignmentWrapper functions are now consolidated in this file
SalvageTargetCounter = include("SalvageTargetCounter")
WreckageManagement = include("WreckageManagement")
WreckageValidation = include("WreckageValidation")
AsteroidManagement = include("AsteroidManagement")
AsteroidUtils = include("AsteroidUtils")
AsteroidTargetUpdateManager = include("AsteroidTargetUpdateManager")
AsteroidCleanup = include("AsteroidCleanup")
SquadManagement = include("SquadManagement")
AsteroidTargetManager = include("AsteroidTargetManager")
SalvageTargetsUpdate = include("SalvageTargetsUpdate")
UnifiedWreckageCache = include("UnifiedWreckageCache")
ForemanSystemManager = include("ForemanSystemManager")
-- Message managers are client-side only, include conditionally
if onClient() then
    MessageManager = include("MessageManager")
    SaveConfirmationManager = include("SaveConfirmationManager")
    AutoDockMessageManager = include("AutoDockMessageManager")
    ForemanInfoMessageManager = include("ForemanInfoMessageManager")
end

-- Automation debugging flag - set to true to enable debugging output
local AUTOMATION_DEBUG_ENABLED = false

-- ============================================================================
-- CANCEL SCAN WRAPPER
-- ============================================================================
function MainWrapper.cancelScan()
    ScanningManager.cancelScan()
    return nil
end

-- ============================================================================
-- FIGHTER MOVE ORDER WRAPPER
-- ============================================================================
function MainWrapper.setFighterMoveOrder(fighterIndex, lootIndex, bIgnoreMotherShip, bSquadOrdersChanged)
    LootManager.setFighterMoveOrder(fighterIndex, lootIndex, bIgnoreMotherShip, bSquadOrdersChanged, getRandomGoAfterLootLine, fighterChatterMessage)
end

-- ============================================================================
-- FORCE REFRESH WRAPPER
-- ============================================================================
function MainWrapper.forceRefresh(fm)
    fm.clearShipList()
    fm.onLoad()
end

-- ============================================================================
-- FIGHTER FLY TO LOCATION WRAPPER
-- ============================================================================
function MainWrapper.setFighterFlyToLocation(fighterIndex, lootIndex)
    LootManager.setFighterFlyToLocation(fighterIndex, lootIndex, getRandomLootPickedUpLine, getRandomWrongLootPickedUpLine, fighterChatterMessage)
end

-- ============================================================================
-- ASTEROID CLEANUP WRAPPER
-- ============================================================================
local function cleanupDepletedAsteroids(asteroids, factionData, fms)
    AsteroidCleanup.cleanupDepletedAsteroids(asteroids, factionData, function(asteroidIndex) 
        return AsteroidUtils.validateAsteroidResources(asteroidIndex, asteroids, fms._validationCacheValid, fms._asteroidValidationCache) 
    end, fms.removeAsteroid)
end

function MainWrapper.cleanupDepletedAsteroids(asteroids, factionData, fms)
    cleanupDepletedAsteroids(asteroids, factionData, fms)
end

-- ============================================================================
-- LOOT CHECK WRAPPER
-- ============================================================================
function MainWrapper.checkLootForPickup(factionIndex, fms)
    if AUTOMATION_DEBUG_ENABLED then
        print("Foreman: MainWrapper.checkLootForPickup called for faction", factionIndex)
    end
    -- Only check for loot if auto-loot is enabled
    local autoLootEnabled = false -- Default to false to respect user's choice
    
    -- Check galaxy storage first
    local galaxy = Galaxy()
    local savedAutoLoot = nil
    if galaxy and galaxy.getValue then
        local success, result = pcall(function() return galaxy:getValue("foreman_" .. factionIndex .. "_autoLoot") end)
        if success then
            savedAutoLoot = result
        else
            if AUTOMATION_DEBUG_ENABLED then
                print("Foreman: Error getting galaxy value:", result)
            end
        end
    end
    if AUTOMATION_DEBUG_ENABLED then
        print("Foreman: Server-side autoloot check for faction", factionIndex, "- galaxy value:", savedAutoLoot)
    end
    if savedAutoLoot ~= nil then
        autoLootEnabled = savedAutoLoot
    else
        -- Check player storage as fallback
        local player = Player(factionIndex)
        if player then
            savedAutoLoot = player:getValue("foreman_autoLoot")
            if AUTOMATION_DEBUG_ENABLED then
                print("Foreman: Server-side autoloot check for faction", factionIndex, "- player value:", savedAutoLoot)
            end
            if savedAutoLoot ~= nil then
                autoLootEnabled = savedAutoLoot
            end
        end
    end
    
    if AUTOMATION_DEBUG_ENABLED then
        print("Foreman: Server-side autoloot decision for faction", factionIndex, "- final value:", autoLootEnabled)
    end
    if autoLootEnabled then
        LootManager.checkLootForPickup(factionIndex, getCachedEntitiesByType, getTableLength, fms.setFighterMoveOrder)
    end
end

-- ============================================================================
-- SQUAD WRAPPER
-- ============================================================================
function MainWrapper.getSquadsWithMiningFighters(shipId)
    return SquadManagement.getSquadsWithMiningFighters(shipId)
end

function MainWrapper.getSquadsWithSalvageFighters(shipId)
    return SquadManagement.getSquadsWithSalvageFighters(shipId)
end

-- ============================================================================
-- AUTOMATION SETTINGS WRAPPER
-- ============================================================================
function MainWrapper.resetAutomationSettings()
    AutomationManager.resetAutomationSettings()
end

-- ============================================================================
-- AUTO MESSAGE WRAPPER
-- ============================================================================
function MainWrapper.sendAutoScanMessage()
    if MessageManager and MessageManager.sendAutoScanMessage then
        MessageManager.sendAutoScanMessage()
    end
end

function MainWrapper.sendAutoMineMessage()
    if MessageManager and MessageManager.sendAutoMineMessage then
        MessageManager.sendAutoMineMessage()
    end
end

function MainWrapper.sendAutoDockMessage()
    if MessageManager and MessageManager.sendAutoDockMessage then
        MessageManager.sendAutoDockMessage()
    end
end

function MainWrapper.sendAutoDockWhenFullMessage(shipCount)
    if MessageManager and MessageManager.sendAutoDockWhenFullMessage then
        MessageManager.sendAutoDockWhenFullMessage(shipCount)
    end
end

-- ============================================================================
-- CONFIRMATION MESSAGE WRAPPER
-- ============================================================================
function MainWrapper.sendSaveConfirmationMessage()
    if SaveConfirmationManager and SaveConfirmationManager.sendSaveConfirmationMessage then
        SaveConfirmationManager.sendSaveConfirmationMessage()
    end
end

function MainWrapper.sendLoadConfirmationMessage()
    if SaveConfirmationManager and SaveConfirmationManager.sendLoadConfirmationMessage then
        SaveConfirmationManager.sendLoadConfirmationMessage()
    end
end

-- ============================================================================
-- CREW BALANCE WRAPPER
-- ============================================================================
function MainWrapper.balanceCrewForForemanShips(factionIndex, targetEntityId, allowOverdrawPilots, depth, onServer, foreman, fms)
    return CrewBalance.balanceCrewForForemanShips(factionIndex, targetEntityId, allowOverdrawPilots, depth, onServer, foreman, fms)
end

function MainWrapper.balanceCrewNow()
    return CrewBalance.balanceCrewNow()
end

function MainWrapper.toggleAutoBalanceCrew()
    return CrewBalance.toggleAutoBalanceCrew()
end

-- ============================================================================
-- INFO WRAPPER
-- ============================================================================
function MainWrapper.showInfo()
    -- showInfo is handled directly by client-side code, not through MainWrapper
    -- This function exists only for compatibility but should not be called
    -- The actual showInfo implementation is in ForemanManager.lua or InfoManager.lua
end

function MainWrapper.showLoadedMessage()
    if MessageManager and MessageManager.showLoadedMessage then
        MessageManager.showLoadedMessage()
    end
end

-- ============================================================================
-- JUMP WRAPPER
-- ============================================================================
function MainWrapper.onJump(shipId)
    return JumpHandling.onJump(shipId)
end

-- ============================================================================
-- LOOT COLLECTED WRAPPER
-- ============================================================================
function MainWrapper.onSystemUpgradeLootCollected(collectorIndex, lootIndex, fms)
    fms.onLootCollected(collectorIndex, lootIndex)
end

function MainWrapper.onTurretLootCollected(collectorIndex, lootIndex, fms)
    fms.onLootCollected(collectorIndex, lootIndex)
end

-- ============================================================================
-- LOOT DROP WRAPPER
-- ============================================================================
function MainWrapper.handleLootDrop(lootIndex, fms)
    -- Only handle loot drops if auto-loot is enabled
    -- On server side, we need to check if any player faction has auto-loot enabled
    -- Since LootManager.handleLootDrop iterates through all factions, we'll create a wrapper
    -- that only calls the original function if at least one faction has autoloot enabled
    local hasAutoLootEnabled = false
    local playerFactions = {Sector():getPresentFactions()}
    local galaxy = Galaxy()
    
    for i = #playerFactions, 1, -1 do
        if Faction(playerFactions[i]).isAIFaction then
            table.remove(playerFactions, i)
        end
    end
    
    for _, factionIndex in pairs(playerFactions) do
        local autoLootEnabled = false -- Default to false to respect user's choice
        
        -- Check galaxy storage first
        local savedAutoLoot = nil
        if galaxy and galaxy.getValue then
            local success, result = pcall(function() return galaxy:getValue("foreman_" .. factionIndex .. "_autoLoot") end)
            if success then
                savedAutoLoot = result
            else
                if AUTOMATION_DEBUG_ENABLED then
                    print("Foreman: LootDrop error getting galaxy value:", result)
                end
            end
        end
        if AUTOMATION_DEBUG_ENABLED then
            print("Foreman: LootDrop server-side autoloot check for faction", factionIndex, "- galaxy value:", savedAutoLoot)
        end
        if savedAutoLoot ~= nil then
            autoLootEnabled = savedAutoLoot
        else
            -- Check player storage as fallback
            local player = Player(factionIndex)
            if player then
                savedAutoLoot = player:getValue("foreman_autoLoot")
                if AUTOMATION_DEBUG_ENABLED then
                    print("Foreman: LootDrop server-side autoloot check for faction", factionIndex, "- player value:", savedAutoLoot)
                end
                if savedAutoLoot ~= nil then
                    autoLootEnabled = savedAutoLoot
                end
            end
        end
        
        if AUTOMATION_DEBUG_ENABLED then
            print("Foreman: LootDrop server-side autoloot decision for faction", factionIndex, "- final value:", autoLootEnabled)
        end
        if autoLootEnabled then
            hasAutoLootEnabled = true
            break
        end
    end
    
    if hasAutoLootEnabled then
        LootManager.handleLootDrop(lootIndex, getTableLength, fms.setFighterMoveOrder)
    end
end

-- ============================================================================
-- LOOT PICKUP WRAPPER
-- ============================================================================
function MainWrapper.clearFactionLootPickups(factionIndex, getTableLength)
    LootManager.clearFactionLootPickups(factionIndex, getTableLength)
end

-- ============================================================================
-- MINEABLE AMOUNT WRAPPER
-- ============================================================================
function MainWrapper.getMineableAmountInVicinity(ignoreCargoSpace, perOre, fm)
    local currentForemanMaterialLevel = fm.foremanMaterialLevel
    local currentMiningFilters = fm.miningFilters or {}
    if currentForemanMaterialLevel == nil and onClient() and Player() and Player().craft then
        local ok, sa, fml = pcall(function()
            local sa2, fml2 = ForemanSystemManager.getAndSetForemanModuleMiningAccuracy(Player().craft.id, fm.scanAccuracy or -1, fm.foremanMaterialLevel)
            return sa2, fml2
        end)
        if ok then
            fm.scanAccuracy = sa
            fm.foremanMaterialLevel = fml
            currentForemanMaterialLevel = fml
        end
    end
    return AsteroidUtils.getMineableAmountInVicinity(ignoreCargoSpace, perOre, fm._mineableCache, currentForemanMaterialLevel, currentMiningFilters)
end

-- ============================================================================
-- ON SYSTEMS CHANGED PLAYER WRAPPER
-- ============================================================================
function MainWrapper.onSystemsChanged_player(shipId)
    deferredCallback(0.1, "deferredOnSystemsChanged_player", shipId)
end

-- ============================================================================
-- SALVAGE TARGET COUNT WRAPPER
-- ============================================================================
function MainWrapper.getSalvageTargetCount(factionIndex, factionData, wreckageCache, getTableLength, CACHE_REFRESH_INTERVAL, MIN_WRECKAGE_RESOURCES, TARGET_THRESHOLD, SALVAGE_DEBUG_ENABLED, onServer, lastCacheRefresh, smartScanActive, validateWreckageResources)
    return SalvageTargetCounter.getSalvageTargetCount(factionIndex, factionData, wreckageCache, getTableLength, function(forceRefresh) return WreckageManagement.refreshWreckageCache(forceRefresh, MIN_WRECKAGE_RESOURCES, TARGET_THRESHOLD, SALVAGE_DEBUG_ENABLED, onServer, function() return WreckageManagement.getAvailableTargetCount(wreckageCache, MIN_WRECKAGE_RESOURCES) end, wreckageCache, lastCacheRefresh, smartScanActive) end, validateWreckageResources)
end

-- ============================================================================
-- SECTOR SCAN COMPLETE WRAPPER
-- ============================================================================
function MainWrapper.sectorScanComplete(fm, sectorScanned, sectorScanTimeRemaining, scanAccuracy)
    sectorScanned, sectorScanTimeRemaining = ScanningEventManager.sectorScanComplete(fm.hideScan, fm.invalidateAsteroidCache, fm.getMineableAmountInVicinity, nil, sectorScanned, sectorScanTimeRemaining)
    if sectorScanned then
        deferredCallback(0.5, function()
            local wantsPerOre = (scanAccuracy == 4) or (scanAccuracy == 2)
            local resourcesLeftTotal, asteroidCount, resources = fm.getMineableAmountInVicinity(true, wantsPerOre)
            fm.updateYieldUI(resourcesLeftTotal, asteroidCount, (wantsPerOre and resources) or nil)
        end)
    end
    return sectorScanned, sectorScanTimeRemaining
end

-- ============================================================================
-- SERVER MESSAGE WRAPPER
-- ============================================================================
function MainWrapper.sendAutoDockMessageServer()
    if AutoDockMessageManager and AutoDockMessageManager.sendAutoDockMessage then
        AutoDockMessageManager.sendAutoDockMessage()
    end
end

function MainWrapper.sendForemanInfo(text)
    if ForemanInfoMessageManager and ForemanInfoMessageManager.sendForemanInfo then
        ForemanInfoMessageManager.sendForemanInfo(text)
    end
end

-- ============================================================================
-- SHIP CARGO CHECK WRAPPER
-- ============================================================================
function MainWrapper.shipCargoCheck(factionData)
    ShipDataManager.shipCargoCheck(factionData)
end

-- ============================================================================
-- SQUAD ORDERS WRAPPER
-- ============================================================================
function MainWrapper.onSquadOrdersChanged(entityIndex, squadIndex, orders, targetId, fms)
    SquadOrdersHandling.onSquadOrdersChanged(entityIndex, squadIndex, orders, targetId, LootManager.getAssignedFighters(), fms.setFighterMoveOrder)
end

-- ============================================================================
-- SQUAD RETURN WRAPPER
-- ============================================================================
function MainWrapper.returnMiningSquads(factionIndex, callingPlayer, factionData, fms)
    MiningSquadReturnManager.returnMiningSquads(factionIndex, callingPlayer, factionData, fms)
end

function MainWrapper.returnSalvageSquads(factionIndex, callingPlayer, factionData, fms)
    SalvageSquadReturnManager.returnSalvageSquads(factionIndex, callingPlayer, factionData, fms)
end

-- ============================================================================
-- STANDBY FIGHTER ASSIGNMENT WRAPPER
-- ============================================================================
function MainWrapper.assignStandbyFightersToTargets(factionIndex, factionData, salvageAssignments, salvageTargets, wreckages, getCachedEntitiesByType, getTableLength, CACHE_REFRESH_INTERVAL, MIN_WRECKAGE_RESOURCES, TARGET_THRESHOLD, SALVAGE_DEBUG_ENABLED, onServer, MAX_SQUADS_PER_WRECKAGE, lastCacheRefresh, smartScanActive, validateWreckageResources, removeSquadFromWreckage, assignSquadToWreckage, pendingCacheUpdates, cacheUpdateIndex, MAX_UPDATES_PER_FRAME)
    IdleFighterAssignmentManager.assignIdleFightersToTargets(factionIndex, factionData, salvageAssignments, salvageTargets, MIN_WRECKAGE_RESOURCES, SALVAGE_DEBUG_ENABLED, onServer, assignSquadToWreckage)
end

-- ============================================================================
-- START SALVAGING PERIODIC WRAPPER
-- ============================================================================
function MainWrapper.startSalvagingPeriodic(factionIndex, factionData, fms)
    local fData = factionData[factionIndex]
    if fData then
        MainWrapper.assignSalvageSquadsRandomly(factionIndex, 0, fData.miningFilters, factionData, fms)
    end
end

-- ============================================================================
-- WRECKAGE VALIDATION WRAPPER
-- ============================================================================
local function validateWreckageResources(wreckageIndex, wreckageCache)
    return WreckageValidation.validateWreckageResources(wreckageIndex, wreckageCache)
end

function MainWrapper.validateWreckageResources(wreckageIndex, wreckageCache)
    return validateWreckageResources(wreckageIndex, wreckageCache)
end

-- ============================================================================
-- ASTEROID COUNT WRAPPER
-- ============================================================================
function MainWrapper.getAsteroidCount(factionIndex, factionData, asteroids, fms)
    return AsteroidManagement.getAsteroidCount(factionIndex, factionData, asteroids, function(asteroidIndex) 
        return AsteroidUtils.validateAsteroidResources(asteroidIndex, asteroids, fms._validationCacheValid, fms._asteroidValidationCache) 
    end)
end

-- ============================================================================
-- ASTEROID TARGETS UPDATE WRAPPER
-- ============================================================================
function MainWrapper.asteroidTargetsUpdate(asteroidTargets, asteroids, factionData, fms)
    AsteroidTargetUpdateManager.asteroidTargetsUpdate(asteroidTargets, asteroids, factionData, fms, AsteroidUtils, SquadManagement, AsteroidTargetManager)
end

-- ============================================================================
-- LOOT COLLECTED HANDLER WRAPPER
-- ============================================================================
function MainWrapper.onLootCollected(collectorIndex, lootIndex)
    LootManager.onLootCollected(collectorIndex, lootIndex, getRandomLootPickedUpLine, getRandomWrongLootPickedUpLine, fighterChatterMessage)
end

-- ============================================================================
-- SALVAGE SQUAD ASSIGNMENT WRAPPER
-- ============================================================================
function MainWrapper.assignSalvageSquadsRandomly(factionIndex, shipIndex, miningFilters, factionData, fms)
    WreckageManagement.assignFactionSalvagingSquadsRandomly(factionIndex, miningFilters, factionData, 
        function(shipId, filters, maxMaterial, includeAssigned)
            local ship = Entity(Uuid(tostring(shipId)))
            if not valid(ship) then return {} end
            local wreckages = {}
            local allWreckages = UnifiedWreckageCache.getAllWreckages()
            for wreckageId, wreckageData in pairs(allWreckages) do
                if valid(wreckageData.entity) then
                    local material = wreckageData.entity:getMineableMaterial()
                    if material and filters[material.value] == true and material.value <= maxMaterial then
                        if includeAssigned or not wreckageData.assigned then
                            if UnifiedWreckageCache.validateWreckage(wreckageId) then
                                table.insert(wreckages, wreckageData.entity)
                            end
                        end
                    end
                end
            end
            return wreckages
        end, 
        function(t) 
            local count = 0
            for _ in pairs(t) do 
                count = count + 1 
            end
            return count 
        end, 
        fms.addSquadsToWreckage,
        true,  -- SALVAGE_DEBUG_ENABLED
        function() return true end  -- onServer (placeholder)
    )
end

-- ============================================================================
-- SALVAGE TARGETS UPDATE WRAPPER
-- ============================================================================
function MainWrapper.salvageTargetsUpdate(timeStep, factionData, salvageTargets, salvageCheckTimeleft, salvageCheckInterval, TARGET_THRESHOLD, SMART_SCAN_INTERVAL, FAST_ASSIGNMENT_INTERVAL, SALVAGE_DEBUG_ENABLED, smartScanActive, lastSmartScan, lastFastAssignment, appTime, onServer, getTableLength, getAvailableTargetCount, refreshWreckageCache, validateWreckageResources, removeSquadFromWreckage, assignSquadToWreckage, fms, MIN_WRECKAGE_RESOURCES)
    SalvageTargetsUpdate.updateSalvageTargets(
        timeStep, 
        factionData, 
        salvageTargets, 
        salvageCheckTimeleft, 
        salvageCheckInterval,
        TARGET_THRESHOLD,
        SMART_SCAN_INTERVAL,
        FAST_ASSIGNMENT_INTERVAL,
        SALVAGE_DEBUG_ENABLED,
        smartScanActive,
        lastSmartScan,
        lastFastAssignment,
        appTime,
        onServer,
        getTableLength,
        getAvailableTargetCount,
        refreshWreckageCache,
        validateWreckageResources,
        removeSquadFromWreckage,
        assignSquadToWreckage,
        fms,
        MIN_WRECKAGE_RESOURCES
    )
end

return MainWrapper
