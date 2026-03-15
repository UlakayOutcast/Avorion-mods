package.path = package.path .. ";data/scripts/?.lua"
package.path = package.path .. ";data/scripts/lib/?.lua"

include("FighterChattering")
ForemanLib = include("ForemanLib")
include("EntityQueryCache")
LootManager = include("LootManager")
include("ForemanSectorCache")
ArrayUtils = include("ArrayUtils")
AsteroidValidation = include("AsteroidValidation")
AsteroidUtils = include("AsteroidUtils")
AsteroidManagement = include("AsteroidManagement")
WreckageValidation = include("WreckageValidation")
WreckageSearch = include("WreckageSearch")
SquadManagement = include("SquadManagement")
CombatUtils = include("CombatUtils")
CombatManager = include("CombatManager")
PlayerOperations = include("PlayerOperations")
ShipDataManager = include("ShipDataManager")
AsteroidCleanup = include("AsteroidCleanup")
SalvageTargetCounter = include("SalvageTargetCounter")
UnifiedWreckageCache = include("UnifiedWreckageCache")
AsteroidTargetManager = include("AsteroidTargetManager")
SalvageTargetManager = include("SalvageTargetManager")
ScanningManager = include("ScanningManager")
WreckageManagement = include("WreckageManagement")
JumpHandling = include("JumpHandling")
SalvageTargetsUpdate = include("SalvageTargetsUpdate")
CrewBalance = include("CrewBalance")
EntityJumpHandling = include("EntityJumpHandling")
EntityDestructionHandling = include("EntityDestructionHandling")
JumpRouteHandling = include("JumpRouteHandling")
SquadOrdersHandling = include("SquadOrdersHandling")
SalvageShipHandling = include("SalvageShipHandling")
ShipAIStateManager = include("ShipAIStateManager")
ShipTargetRemovalManager = include("ShipTargetRemovalManager")
SectorInitializationManager = include("SectorInitializationManager")
SectorUpdateManager = include("SectorUpdateManager")
EntityCreationManager = include("EntityCreationManager")
EntityRemovalManager = include("EntityRemovalManager")
HarvestingManager = include("HarvestingManager")
SalvagingManager = include("SalvagingManager")
SalvageSquadManager = include("SalvageSquadManager")
AsteroidTargetUpdateManager = include("AsteroidTargetUpdateManager")
MiningSquadReturnManager = include("MiningSquadReturnManager")
SalvageSquadReturnManager = include("SalvageSquadReturnManager")
IdleFighterAssignmentManager = include("IdleFighterAssignmentManager")
ShipSquadReturnManager = include("ShipSquadReturnManager")
MainWrapper = include("MainWrapper")
fms = {}
local DEBUG_COMBAT_MESSAGES = false
local MINING_FILTER_DEBUG = false
local DEBUG_YIELD = false
local fighterChatterIntervalMin = 1 * 60
local fighterChatterIntervalMax = 5 * 60
local fighterChatterTimeLeft = math.random(fighterChatterIntervalMin, fighterChatterIntervalMax)
local asteroids = {}
local wreckages = {}
local scans = {}
local factionData = {}
local asteroidTargets = {}
local salvageTargets = {}
local _escortJumpState = {}
local MAX_SQUADS_PER_ASTEROID = 1
local HELPER_MAX_SQUADS_PER_ASTEROID = 2
local MAX_SQUADS_PER_WRECKAGE = 1
local HELPER_MAX_SQUADS_PER_WRECKAGE = 2
local _serverCallbacksRegistered = false

-- Missing function that CombatManager.lua expects
function fighterChatterMessage(fighterId, message)
    if valid(Entity(fighterId)) and message then
        Sector():broadcastChatMessage(Entity(fighterId), ChatMessageType.Chatter, message)
    end
end

function playRandomDialogue(factionFighters)
    if not factionFighters or #factionFighters < 2 then
        return
    end
    
    local dialogue = getRandomDialogue()
    if not dialogue then
        return
    end
    
    local time = 0
    local talkers = {}
    
    for _, v in pairs(dialogue) do
        local talkerIndex = v.i
        local message = v.m
        
        if talkers[talkerIndex] == nil then
            local id = randomEntry(random(), factionFighters)
            talkers[talkerIndex] = id
            factionFighters[id] = nil
        end
        
        deferredCallback(time, "fighterChatterMessage", talkers[talkerIndex], message)
        
        if v.d == nil then break end
        
        local delay = v.d
        time = time + delay
    end
end

function fms.getUpdateInterval() return ForemanLib.getUpdateInterval() end
callable(fms, "getUpdateInterval")
-- Ensure engine can query update interval from this script
function getUpdateInterval()
    return fms.getUpdateInterval()
end
function fms.invalidateAsteroidValidationCache()
    AsteroidUtils.invalidateValidationCache(fms)
end
callable(fms, "invalidateAsteroidValidationCache")
function fms.initialize()
    SectorInitializationManager.initialize(scans, factionData)
end
callable(fms, "initialize")
function fms.onSectorGenerated(time)
    AsteroidManagement.initializeAsteroids(asteroids, getCachedEntitiesByType, fms.invalidateAsteroidValidationCache)
    salvageTargets = {}
    wreckageCache = {}
    WreckageValidation.invalidateWreckageValidationCache()
    -- Don't clear factionData entirely - preserve scan status across sector changes
    -- Only clear non-scan related data to ensure fresh state for new sector
    for factionIndex, data in pairs(factionData) do
        if data then
            -- Preserve scan status but clear other sector-specific data
            local sectorScanned = data.sectorScanned
            factionData[factionIndex] = {}
            if sectorScanned then
                factionData[factionIndex].sectorScanned = sectorScanned
            end
        end
    end
    -- Don't clear scans table - let active scans complete naturally
    -- This prevents breaking scan completion callbacks when jumping sectors
end
function fms.onRestoredFromDisk(time)
    AsteroidManagement.initializeAsteroids(asteroids, getCachedEntitiesByType, fms.invalidateAsteroidValidationCache)
    ShipDataManager.initializeFactionData(factionData, getCachedEntitiesByType)
    salvageTargets = {}
    wreckageCache = {}
    WreckageValidation.invalidateWreckageValidationCache()
end
local lootCheckInterval = 1
local lootCheckTimeLeft = 1
local _cargoCheckInterval = 0.5
local _cargoCheckLeft = 0
local _asteroidCleanupInterval = 5
local _asteroidCleanupLeft = 5
local pendingCacheUpdates = {} -- Queue of entities that need cache updates
local cacheUpdateIndex = 1 -- Current position in update queue
local MAX_UPDATES_PER_FRAME = 5 -- Maximum cache updates per frame
local salvageAssignments = {} -- [wreckageId] = {squads = {shipIndex_squadIndex, ...}}
local function getAvailableTargetCount()
    local unassigned = UnifiedWreckageCache.getUnassignedWreckages()
    return #unassigned
end
local function refreshWreckageCache(forceRefresh)
    return UnifiedWreckageCache.refreshCache(forceRefresh)
end
local function validateWreckageResources(wreckageId)
    return UnifiedWreckageCache.validateWreckage(wreckageId)
end
local function getWreckages(shipIndex, miningFilters, maxMaterial, includeAssigned)
    local ship
    if type(shipIndex) == "string" then
        ship = Entity(shipIndex)
    else
        ship = Entity(Uuid(shipIndex))
    end
    if not valid(ship) then return {} end
    local shipPos = ship.translationf
    local wreckages = {}
    local allWreckages = UnifiedWreckageCache.getAllWreckages()
    for wreckageId, wreckageData in pairs(allWreckages) do
        if valid(wreckageData.entity) then
            local material = wreckageData.entity:getMineableMaterial()
            if material and miningFilters[material.value] == true and material.value <= maxMaterial then
                if includeAssigned or not wreckageData.assigned then
                    if validateWreckageResources(wreckageId) then
                        table.insert(wreckages, wreckageData.entity)
                    end
                end
            end
        end
    end
    return wreckages
end
local function getHighestSalvageableMaterial(shipIndex)
    local ship
    if type(shipIndex) == "string" then
        ship = Entity(shipIndex)
    else
        ship = Entity(Uuid(shipIndex))
    end
    if not valid(ship) then return 0 end
    local hangar = Hangar(ship.id)
    if not hangar then return 0 end
    local squads = {hangar:getSquads()}
    local highestMaterial = 0
    for _, index in pairs(squads) do
        if hangar:getSquadMainWeaponCategory(index) == WeaponCategory.Salvaging then
            local squadMaterial = hangar:getHighestMaterialInSquadMainCategory(index).value
            if squadMaterial > highestMaterial then
                highestMaterial = squadMaterial
            end
        end
    end
    return highestMaterial + 1
end
local function assignSquadToWreckage(wreckageId, shipIndex, squadIndex)
    local squadKey = string.format("%s_%d", shipIndex, squadIndex)
    UnifiedWreckageCache.assignSquadToWreckage(wreckageId, squadKey)
    if not salvageAssignments[wreckageId] then
        salvageAssignments[wreckageId] = {squads = {}}
    end
    salvageAssignments[wreckageId].squads[squadKey] = true
end
local function removeSquadFromWreckage(wreckageId, shipIndex, squadIndex)
    local squadKey = string.format("%s_%d", shipIndex, squadIndex)
    UnifiedWreckageCache.unassignSquadFromWreckage(wreckageId, squadKey)
    if salvageAssignments[wreckageId] then
        salvageAssignments[wreckageId].squads[squadKey] = nil
        if not next(salvageAssignments[wreckageId].squads) then
            salvageAssignments[wreckageId] = nil
        end
    end
end
function fms.updateServer(timeStep)
    fighterChatterTimeLeft = SectorUpdateManager.updateServer(timeStep, fms, factionData, pendingCacheUpdates, cacheUpdateIndex, MAX_UPDATES_PER_FRAME, MIN_WRECKAGE_RESOURCES, SALVAGE_DEBUG_ENABLED, onServer, _cargoCheckLeft, _cargoCheckInterval, _asteroidCleanupLeft, _asteroidCleanupInterval, ScanningManager, WreckageManagement, LootManager, fighterChatterTimeLeft, fighterChatterIntervalMin, fighterChatterIntervalMax, getCachedEntitiesByTypeAndFaction, EntityType, playRandomDialogue, fighterChatterMessage, randomEntry, random, getRandomChatterLine, CombatUtils, DEBUG_COMBAT_MESSAGES)
end
callable(fms, "updateServer")
function fms.updateJumpHandling(timeStep)
    JumpHandling.updateJumpHandling(factionData, timeStep, getCachedEntitiesByType, onServer, appTime, _escortJumpState)
end
function fms.updateCombat()
    CombatManager.updateCombat(factionData, DEBUG_COMBAT_MESSAGES)
end
function fms.getOperationsStatus(playerIndex, factionIndex)
    PlayerOperations.getOperationsStatus(playerIndex, factionIndex, factionData)
end
callable(fms, "getOperationsStatus")
function fms.onEntityEntered(shipIndex)
    ShipDataManager.onEntityEntered(shipIndex, factionData)
end
function fms.onEntityJump(shipIndex, x, y, sectorChangeType)
    EntityJumpHandling.onEntityJump(shipIndex, x, y, sectorChangeType, factionData, asteroidTargets, salvageTargets)
end
function fms.onDestroyed(shipIndex, lastDamageInflictor)
    EntityDestructionHandling.onDestroyed(shipIndex, lastDamageInflictor, factionData)
end
function fms.onEntityCreated(entityId)
    EntityCreationManager.onEntityCreated(entityId, asteroids, wreckages, factionData, pendingCacheUpdates, IMMEDIATE_CACHE_UPDATE, SALVAGE_DEBUG_ENABLED, onServer, fms, WreckageValidation, ShipDataManager, LootManager)
end
function fms.onEntityRemoved(entityId)
    EntityRemovalManager.onEntityRemoved(entityId, factionData, SALVAGE_DEBUG_ENABLED, onServer, fms)
end
function fms.onShipAIStateChanged(entityId, oldState, newState)
    ShipAIStateManager.onShipAIStateChanged(entityId, oldState, newState, factionData)
end
function fms.onShipJumpRouteCalculationStarted(entityId)
    JumpRouteHandling.onShipJumpRouteCalculationStarted(entityId, factionData)
end
function fms.miningFilterChanged(factionIndex, index, value)
    if MINING_FILTER_DEBUG then
        print("[FILTER DEBUG] SERVER: miningFilterChanged called - faction: " .. factionIndex .. ", material: " .. index .. ", value: " .. tostring(value))
    end
    ShipDataManager.miningFilterChanged(factionIndex, index, value, factionData)
    
    -- Immediately reassign all mining squads to ensure they respect the new filters
    if factionData[factionIndex] and factionData[factionIndex].ships then
        if MINING_FILTER_DEBUG then
            print("[FILTER DEBUG] SERVER: Reassigning all mining squads due to filter change...")
        end
        for shipIndex, shipData in pairs(factionData[factionIndex].ships) do
            if shipData.miningSquads and getTableLength(shipData.miningSquads) > 0 then
                if MINING_FILTER_DEBUG then
                    print("[FILTER DEBUG] SERVER: Reassigning squads for ship " .. shipIndex)
                end
                fms.assignMiningSquadsRandomly(factionIndex, shipIndex)
            end
        end
    end
end
callable(fms, "miningFilterChanged")
function fms.addSquadsToAsteroid(asteroidIndex, translationf, factionIndex, shipIndex, squadsToAdd)
    AsteroidTargetManager.addSquadsToAsteroid(asteroidIndex, translationf, factionIndex, shipIndex, squadsToAdd, asteroidTargets)
end
function fms.addSquadsToWreckage(wreckageIndex, translationf, factionIndex, shipIndex, squadsToAdd)
    SalvageTargetManager.addSquadsToWreckage(wreckageIndex, translationf, factionIndex, shipIndex, squadsToAdd, salvageTargets)
    
    -- Update UnifiedWreckageCache to ensure proper synchronization
    for _, squadIndex in pairs(squadsToAdd) do
        local squadKey = string.format("%s_%d", shipIndex, squadIndex)
        UnifiedWreckageCache.assignSquadToWreckage(tostring(wreckageIndex), squadKey)
    end
end
function fms.removeAsteroidTarget(asteroidIndex)
    AsteroidTargetManager.removeAsteroidTarget(asteroidIndex, asteroidTargets)
end
function fms.removeSalvageTarget(wreckageIndex)
    SalvageTargetManager.removeSalvageTarget(wreckageIndex, salvageTargets)
    
    -- Update UnifiedWreckageCache to ensure proper synchronization
    UnifiedWreckageCache.removeWreckage(tostring(wreckageIndex))
end
function fms.removeShipFromAsteroidTargets(factionIndex, inShipIndex, returnNormalSquads)
    ShipTargetRemovalManager.removeShipFromAsteroidTargets(factionIndex, inShipIndex, returnNormalSquads, asteroidTargets, factionData, fms.getSquadsWithMiningFighters, getTableLength)
end
function fms.removeShipFromSalvageTargets(factionIndex, inShipIndex, returnNormalSquads)
    ShipTargetRemovalManager.removeShipFromSalvageTargets(factionIndex, inShipIndex, returnNormalSquads, salvageTargets, factionData, fms.getSquadsWithSalvageFighters, getTableLength)
end
local lastCacheRefresh = 0
local CACHE_REFRESH_INTERVAL = 5 -- seconds (reduced from 10 for faster response)
local SMART_SCAN_INTERVAL = 1 -- seconds - scan when targets running low (reduced from 2 for faster response)
local FAST_ASSIGNMENT_INTERVAL = 0.5 -- seconds - assign targets to idle fighters (reduced from 1.0 for faster assignment)
local IMMEDIATE_CACHE_UPDATE = true -- Update cache immediately when new entities are created
local MAX_CACHED_TARGETS = 10000 -- Maximum targets to cache (increased to allow all targets)
local TARGET_THRESHOLD = 10 -- Start scanning when fewer than this many targets available
local MIN_WRECKAGE_RESOURCES = 1  -- Minimum salvageable resources
local smartScanActive = false
local lastSmartScan = 0
local lastFastAssignment = 0
local SALVAGE_DEBUG_ENABLED = false -- Debug enabled
function fms.removeAsteroid(asteroidIndex)
    AsteroidManagement.removeAsteroid(asteroidIndex, asteroids, fms.invalidateAsteroidValidationCache)
end
function fms.removeWreckage(wreckageId)
    WreckageManagement.removeWreckage(wreckageId, wreckages, salvageTargets, function(wreckageIndex) WreckageManagement.removeWreckageFromCache(wreckageIndex, wreckageCache, salvageAssignments) end, WreckageValidation.invalidateWreckageValidationCache)
end
function fms.startScanning(factionIndex, starterPlayerIndex, scanningTime, shipIndex)
    ShipDataManager.checkAndCreateFactionData(factionIndex, factionData)
    ScanningManager.startScanningServer(factionIndex, starterPlayerIndex, scanningTime, shipIndex)
end
callable(fms, "startScanning")
function fms.scanCancelled(factionIndex)
    ScanningManager.scanCancelled(factionIndex)
end
function fms.scanComplete(factionIndex, scanNum)
    ScanningManager.scanComplete(factionIndex, scanNum)
end
function fms.getScanStatus(factionIndex, playerIndex)
    ScanningManager.getScanStatus(factionIndex, playerIndex)
end
callable(fms, "getScanStatus")

-- Server-side yield summary to avoid client entity access timing issues
function fms.getYieldSummary(factionIndex, wantsPerOre)
    if DEBUG_YIELD then
        print(string.format("[Foreman] getYieldSummary called (faction=%s, perOre=%s)", tostring(factionIndex), tostring(wantsPerOre)))
    end
    -- Ensure faction data is initialized for this faction
    ShipDataManager.checkAndCreateFactionData(factionIndex, factionData)
    -- Ensure asteroid list is initialized for this sector
    AsteroidManagement.initializeAsteroids(asteroids, getCachedEntitiesByType, fms.invalidateAsteroidValidationCache)

    local total = 0
    local asteroidCount = 0
    local perOre = { [0] = 0, [1] = 0, [2] = 0, [3] = 0, [4] = 0, [5] = 0, [6] = 0 }

    local fData = factionData[factionIndex] or {}
    local filters = fData.miningFilters or {}
    local matCap = fData.commandingAsteroidMaterialLevel

    local entities = { Sector():getEntitiesByType(EntityType.Asteroid) }
    for _, e in pairs(entities) do
        if valid(e) then
            local amounts = { e:getMineableResources() }
            local sum = 0
            for _, a in pairs(amounts) do sum = sum + (a or 0) end
            if sum > 0 then
                local mat = e:getMineableMaterial()
                if mat then
                    local m = mat.value
                    local passFilter = (filters[m] ~= false)
                    local passLevel = (matCap == nil) or (m <= matCap)
                    if passFilter and passLevel then
                        asteroidCount = asteroidCount + 1
                        total = total + sum
                        if wantsPerOre then
                            perOre[m] = (perOre[m] or 0) + sum
                        end
                    end
                end
            end
        end
    end

    -- Send result back to the requesting player
    if DEBUG_YIELD then
        print(string.format("[Foreman] getYieldSummary totals: total=%d count=%d", total, asteroidCount))
    end
    -- Send result back to the calling client (Player() without id is nil on server)
    if callingPlayer then
        invokeClientFunction(Player(callingPlayer), "receiveYieldSummary", total, asteroidCount, wantsPerOre and perOre or nil)
    end
end

-- Global wrapper so invokeSectorFunction can call it remotely
function getYieldSummary(factionIndex, wantsPerOre)
    return fms.getYieldSummary(factionIndex, wantsPerOre)
end
-- Register both versions for maximum compatibility
callable(fms, "getYieldSummary")
callable(nil, "getYieldSummary")
function fms.factionOperationStarted(factionIndex, starterPlayerIndex, miningOperation)
    PlayerOperations.factionOperationStarted(factionIndex, starterPlayerIndex, miningOperation, factionData)
end
function fms.factionOperationStopped(factionIndex, stopperPlayerIndex, miningOperation)
    PlayerOperations.factionOperationStopped(factionIndex, stopperPlayerIndex, miningOperation, factionData)
end
function fms.startHarvesting(factionIndex, starterPlayerIndex, commandingAsteroidMaterialLevel, inMiningFilters)
    HarvestingManager.startHarvesting(factionIndex, starterPlayerIndex, commandingAsteroidMaterialLevel, inMiningFilters, factionData, asteroids, asteroidTargets, fms, ShipDataManager, AsteroidManagement, AsteroidUtils, getCachedEntitiesByType, getTableLength, MAX_SQUADS_PER_ASTEROID)
end
callable(fms, "startHarvesting")
function fms.startSalvagingWithShip(factionIndex, shipIndex)
    SalvageShipHandling.startSalvagingWithShip(factionIndex, shipIndex, factionData, fms.assignSalvageSquadsRandomly)
end
function fms.startSalvagingPeriodic(factionIndex)
    MainWrapper.startSalvagingPeriodic(factionIndex, factionData, fms)
end
function fms.startSalvaging(factionIndex, starterPlayerIndex, commandingSalvageMaterialLevel, inMiningFilters)
    SalvagingManager.startSalvaging(factionIndex, starterPlayerIndex, commandingSalvageMaterialLevel, inMiningFilters, factionData, fms, ShipDataManager, WreckageManagement, MIN_WRECKAGE_RESOURCES, TARGET_THRESHOLD, SALVAGE_DEBUG_ENABLED, onServer, lastCacheRefresh, smartScanActive)
end
callable(fms, "startSalvaging")
function fms.assignMiningSquadsRandomly(factionIndex, shipIndex)
    -- Debug output to check filter values
    if MINING_FILTER_DEBUG then
        if factionData[factionIndex] and factionData[factionIndex].miningFilters then
            print("[FILTER DEBUG] assignMiningSquadsRandomly - Current filters for faction " .. factionIndex .. ":")
            for material, enabled in pairs(factionData[factionIndex].miningFilters) do
                print("[FILTER DEBUG]   Material " .. material .. ": " .. (enabled and "enabled" or "disabled") .. " (type: " .. type(enabled) .. ")")
            end
            
            -- Also debug available asteroids and their materials
            print("[FILTER DEBUG] Available asteroids in sector:")
            for asteroidKey, asteroidData in pairs(asteroids) do
                local filterEnabled = factionData[factionIndex].miningFilters[asteroidData.material] ~= false
                print("[FILTER DEBUG]   Asteroid " .. asteroidKey .. " (material " .. asteroidData.material .. "): " .. (filterEnabled and "FILTERED IN" or "FILTERED OUT"))
            end
        else
            print("[FILTER DEBUG] No mining filters found for faction " .. factionIndex)
        end
    end
    
    AsteroidManagement.assignMiningSquadsRandomly(factionIndex, shipIndex, factionData, asteroids, asteroidTargets, getTableLength, MAX_SQUADS_PER_ASTEROID, fms.addSquadsToAsteroid)
end
function fms.assignStandbyFightersToTargets(factionIndex)
    if SALVAGE_DEBUG_ENABLED and onServer() then
        Sector():broadcastChatMessage(Entity(), ChatMessageType.Chatter, 
            string.format("[SALVAGE DEBUG] assignStandbyFightersToTargets called for faction %d", factionIndex))
    end
    MainWrapper.assignStandbyFightersToTargets(factionIndex, factionData, salvageAssignments, salvageTargets, wreckages, getCachedEntitiesByType, getTableLength, CACHE_REFRESH_INTERVAL, MIN_WRECKAGE_RESOURCES, TARGET_THRESHOLD, SALVAGE_DEBUG_ENABLED, onServer, MAX_SQUADS_PER_WRECKAGE, lastCacheRefresh, smartScanActive, MainWrapper.validateWreckageResources, removeSquadFromWreckage, assignSquadToWreckage, pendingCacheUpdates, cacheUpdateIndex, MAX_UPDATES_PER_FRAME)
end
function fms.assignSalvageSquadsRandomly(factionIndex, shipIndex, miningFilters)
    MainWrapper.assignSalvageSquadsRandomly(factionIndex, shipIndex, miningFilters, factionData, fms)
end


function fms.shipCargoCheck()
    MainWrapper.shipCargoCheck(factionData)
end
function fms.cleanupDepletedAsteroids()
    MainWrapper.cleanupDepletedAsteroids(asteroids, factionData, fms)
end
function fms.getAsteroidCount(factionIndex)
    return MainWrapper.getAsteroidCount(factionIndex, factionData, asteroids, fms)
end
callable(fms, "getAsteroidCount")
function fms.getSalvageTargetCount(factionIndex)
    return MainWrapper.getSalvageTargetCount(factionIndex, factionData, getWreckageCache(), getTableLength, CACHE_REFRESH_INTERVAL, MIN_WRECKAGE_RESOURCES, TARGET_THRESHOLD, SALVAGE_DEBUG_ENABLED, onServer, lastCacheRefresh, smartScanActive, MainWrapper.validateWreckageResources)
end
callable(fms, "getSalvageTargetCount")
function fms.asteroidTargetsUpdate()
    MainWrapper.asteroidTargetsUpdate(asteroidTargets, asteroids, factionData, fms)
end
local salvageCheckInterval = 5 -- Increased from 3 to reduce jitter frequency
local salvageCheckTimeleft = 0
function fms.salvageTargetsUpdate(timeStep)
    MainWrapper.salvageTargetsUpdate(timeStep, factionData, salvageTargets, salvageCheckTimeleft, salvageCheckInterval, TARGET_THRESHOLD, SMART_SCAN_INTERVAL, FAST_ASSIGNMENT_INTERVAL, SALVAGE_DEBUG_ENABLED, smartScanActive, lastSmartScan, lastFastAssignment, appTime, onServer, getTableLength, getAvailableTargetCount, refreshWreckageCache, MainWrapper.validateWreckageResources, removeSquadFromWreckage, assignSquadToWreckage, fms, MIN_WRECKAGE_RESOURCES)
end
function fms.returnMiningSquads(factionIndex, callingPlayer)
    MainWrapper.returnMiningSquads(factionIndex, callingPlayer, factionData, fms)
end
callable(fms, "returnMiningSquads")
function fms.returnSalvageSquads(factionIndex, callingPlayer)
    MainWrapper.returnSalvageSquads(factionIndex, callingPlayer, factionData, fms)
end
callable(fms, "returnSalvageSquads")
function fms.returnShipSquads(factionIndex, shipIds)
    ShipSquadReturnManager.returnShipSquads(factionIndex, shipIds, factionData, fms)
end
callable(fms, "returnShipSquads")
function fms.balanceCrewForForemanShips(factionIndex, targetEntityId, allowOverdrawPilots, depth)
    return MainWrapper.balanceCrewForForemanShips(factionIndex, targetEntityId, allowOverdrawPilots, depth, onServer, nil, fms)
end
callable(fms, "balanceCrewForForemanShips")
callable(fms, "removeWreckage")
function fms.clearFactionLootPickups(factionIndex)
    MainWrapper.clearFactionLootPickups(factionIndex, getTableLength)
end
function fms.getSquadsWithMiningFighters(shipId)
    return MainWrapper.getSquadsWithMiningFighters(shipId)
end
function fms.getSquadsWithSalvageFighters(shipId)
    return MainWrapper.getSquadsWithSalvageFighters(shipId)
end
function fms.onSquadOrdersChanged(entityIndex, squadIndex, orders, targetId)
    MainWrapper.onSquadOrdersChanged(entityIndex, squadIndex, orders, targetId, fms)
end
function fms.checkLootForPickup(factionIndex)
    MainWrapper.checkLootForPickup(factionIndex, fms)
end

function fms.setFighterMoveOrder(fighterIndex, lootIndex, bIgnoreMotherShip, bSquadOrdersChanged)
    MainWrapper.setFighterMoveOrder(fighterIndex, lootIndex, bIgnoreMotherShip, bSquadOrdersChanged)
end
function fms.setFighterFlyToLocation(fighterIndex, lootIndex)
    MainWrapper.setFighterFlyToLocation(fighterIndex, lootIndex)
end
function fms.onSystemUpgradeLootCollected(collectorIndex, lootIndex)
    MainWrapper.onSystemUpgradeLootCollected(collectorIndex, lootIndex, fms)
end
function fms.onTurretLootCollected(collectorIndex, lootIndex)
    MainWrapper.onTurretLootCollected(collectorIndex, lootIndex, fms)
end
function fms.handleLootDrop(lootIndex)
    MainWrapper.handleLootDrop(lootIndex, fms)
end
function fms.onLootCollected(collectorIndex, lootIndex)
    MainWrapper.onLootCollected(collectorIndex, lootIndex)
end
function fms.assignIdleFightersToTargets(factionIndex)
    IdleFighterAssignmentManager.assignIdleFightersToTargets(factionIndex, factionData, salvageAssignments, salvageTargets, MIN_WRECKAGE_RESOURCES, SALVAGE_DEBUG_ENABLED, onServer, assignSquadToWreckage)
end
function onSectorGenerated(time)
    fms.onSectorGenerated(time)
end
function onRestoredFromDisk(time)
    fms.onRestoredFromDisk(time)
end
function onEntityEntered(shipIndex)
    fms.onEntityEntered(shipIndex)
end
function onEntityJump(shipIndex, x, y, sectorChangeType)
    fms.onEntityJump(shipIndex, x, y, sectorChangeType)
end
function onDestroyed(shipIndex, lastDamageInflictor)
    fms.onDestroyed(shipIndex, lastDamageInflictor)
end
function onSystemUpgradeLootCollected(collectorIndex, lootIndex)
    fms.onSystemUpgradeLootCollected(collectorIndex, lootIndex)
end
function onTurretLootCollected(collectorIndex, lootIndex)
    fms.onTurretLootCollected(collectorIndex, lootIndex)
end
function onSquadOrdersChanged(entityIndex, squadIndex, orders, targetId)
    fms.onSquadOrdersChanged(entityIndex, squadIndex, orders, targetId)
end
function onEntityCreated(entityId)
    fms.onEntityCreated(entityId)
end
function onEntityRemoved(entityId)
    fms.onEntityRemoved(entityId)
end
function onShipAIStateChanged(entityId, oldState, newState)
    fms.onShipAIStateChanged(entityId, oldState, newState)
end
function initialize()
    fms.initialize()
end
function getOperationsStatus(playerIndex, factionIndex)
    return fms.getOperationsStatus(playerIndex, factionIndex)
end
-- Register both versions for maximum compatibility
callable(fms, "getOperationsStatus")
callable(nil, "getOperationsStatus")
function getScanStatus(factionIndex, playerIndex)
    return fms.getScanStatus(factionIndex, playerIndex)
end
-- Register both versions for maximum compatibility
callable(fms, "getScanStatus")
callable(nil, "getScanStatus")
function startScanning(factionIndex, starterPlayerIndex, scanningTime, shipIndex)
    return fms.startScanning(factionIndex, starterPlayerIndex, scanningTime, shipIndex)
end
-- Register both versions for maximum compatibility
callable(fms, "startScanning")
callable(nil, "startScanning")
function scanComplete(factionIndex, scanNum)
    return fms.scanComplete(factionIndex, scanNum)
end
function startSalvaging(factionIndex, starterPlayerIndex, commandingSalvageMaterialLevel, inMiningFilters)
    return fms.startSalvaging(factionIndex, starterPlayerIndex, commandingSalvageMaterialLevel, inMiningFilters)
end
-- Register both versions for maximum compatibility
callable(fms, "startSalvaging")
callable(nil, "startSalvaging")
function startHarvesting(factionIndex, starterPlayerIndex, commandingAsteroidMaterialLevel, inMiningFilters)
    return fms.startHarvesting(factionIndex, starterPlayerIndex, commandingAsteroidMaterialLevel, inMiningFilters)
end
-- Register both versions for maximum compatibility
callable(fms, "startHarvesting")
callable(nil, "startHarvesting")
function returnMiningSquads(factionIndex, callingPlayer)
    return fms.returnMiningSquads(factionIndex, callingPlayer)
end
-- Register both versions for maximum compatibility
callable(fms, "returnMiningSquads")
callable(nil, "returnMiningSquads")
function returnSalvageSquads(factionIndex, callingPlayer)
    return fms.returnSalvageSquads(factionIndex, callingPlayer)
end
-- Register both versions for maximum compatibility
callable(fms, "returnSalvageSquads")
callable(nil, "returnSalvageSquads")
function returnShipSquads(factionIndex, shipIds)
    return fms.returnShipSquads(factionIndex, shipIds)
end
-- Register both versions for maximum compatibility
callable(fms, "returnShipSquads")
callable(nil, "returnShipSquads")
function balanceCrewForForemanShips(factionIndex, targetEntityId, allowOverdrawPilots, depth)
    return fms.balanceCrewForForemanShips(factionIndex, targetEntityId, allowOverdrawPilots, depth)
end
-- Register both versions for maximum compatibility
callable(fms, "balanceCrewForForemanShips")
callable(nil, "balanceCrewForForemanShips")
function miningFilterChanged(factionIndex, index, value)
    return fms.miningFilterChanged(factionIndex, index, value)
end
-- Register both versions for maximum compatibility
callable(fms, "miningFilterChanged")
callable(nil, "miningFilterChanged")
function assignMiningSquadsRandomly(factionIndex, shipIndex)
    return fms.assignMiningSquadsRandomly(factionIndex, shipIndex)
end
-- Register both versions for maximum compatibility
callable(fms, "assignMiningSquadsRandomly")
callable(nil, "assignMiningSquadsRandomly")
function assignSalvageSquadsRandomly(factionIndex, shipIndex, miningFilters)
    return fms.assignSalvageSquadsRandomly(factionIndex, shipIndex, miningFilters)
end
-- Register both versions for maximum compatibility
callable(fms, "assignSalvageSquadsRandomly")
callable(nil, "assignSalvageSquadsRandomly")
function setFighterFlyToLocation(fighterIndex, lootIndex)
    return fms.setFighterFlyToLocation(fighterIndex, lootIndex)
end
function updateServer(timeStep)
    return fms.updateServer(timeStep)
end
