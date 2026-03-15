local SectorUpdateManager = {}
-- Persistent timer variables
local lootCheckInterval = 1
local lootCheckTimeLeft = 1

-- Sector debugging flag - set to true to enable debugging output
local SECTOR_DEBUG_ENABLED = false

function SectorUpdateManager.updateServer(timeStep, fms, factionData, pendingCacheUpdates, cacheUpdateIndex, MAX_UPDATES_PER_FRAME, MIN_WRECKAGE_RESOURCES, SALVAGE_DEBUG_ENABLED, onServer, _cargoCheckLeft, _cargoCheckInterval, _asteroidCleanupLeft, _asteroidCleanupInterval, ScanningManager, WreckageManagement, LootManager, fighterChatterTimeLeft, fighterChatterIntervalMin, fighterChatterIntervalMax, getCachedEntitiesByTypeAndFaction, EntityType, playRandomDialogue, fighterChatterMessage, randomEntry, random, getRandomChatterLine, CombatUtils, DEBUG_COMBAT_MESSAGES)
    if SECTOR_DEBUG_ENABLED then
        print("Foreman: SectorUpdateManager.updateServer called")
    end
    fms._validationCacheValid = true
    WreckageValidation.markCacheValid()
    _cargoCheckLeft = _cargoCheckLeft - timeStep
    if _cargoCheckLeft <= 0 then
        _cargoCheckLeft = _cargoCheckInterval
        if fms.shipCargoCheck then
            fms.shipCargoCheck()
        end
    end
    _asteroidCleanupLeft = _asteroidCleanupLeft - timeStep
    if _asteroidCleanupLeft <= 0 then
        _asteroidCleanupLeft = _asteroidCleanupInterval
        fms.cleanupDepletedAsteroids()
    end
    if fms.asteroidTargetsUpdate then
        fms.asteroidTargetsUpdate()
    end
    if fms.salvageTargetsUpdate then
        fms.salvageTargetsUpdate(timeStep)
    end
    if ScanningManager.updateScanningStatuses then
        ScanningManager.updateScanningStatuses(timeStep)
    end
    if fms.updateJumpHandling then
        fms.updateJumpHandling(timeStep)
    end
    lootCheckTimeLeft = lootCheckTimeLeft - timeStep
    if lootCheckTimeLeft <= 0 then
        lootCheckTimeLeft = lootCheckInterval
        if SECTOR_DEBUG_ENABLED then
            print("Foreman: SectorUpdateManager - checking loot for factions")
        end
        for factionIndex, data in pairs(factionData) do
            if SECTOR_DEBUG_ENABLED then
                print("Foreman: SectorUpdateManager - faction", factionIndex, "salvage:", data.salvage, "harvest:", data.harvest)
            end
            if data.salvage or data.harvest then
                if SECTOR_DEBUG_ENABLED then
                    print("Foreman: SectorUpdateManager - calling checkLootForPickup for faction", factionIndex)
                end
                fms.checkLootForPickup(factionIndex)
            end
        end
    end
    LootManager.updateLootChatterTimer(timeStep)
    for _, fData in pairs(factionData) do
        if fData.salvage or fData.harvest then
            fighterChatterTimeLeft = fighterChatterTimeLeft - timeStep
            break
        end
    end
    if fighterChatterTimeLeft <= 0 then
        fighterChatterTimeLeft = math.random(fighterChatterIntervalMin, fighterChatterIntervalMax)
        local eligibleFactions = {}
        for fIdx, fData in pairs(factionData) do
            if fData.salvage or fData.harvest then
                table.insert(eligibleFactions, fIdx)
            end
        end
        if #eligibleFactions > 0 then
            local randomFaction = eligibleFactions[math.random(#eligibleFactions)]
            local factionFighters = {}
            local fighters = getCachedEntitiesByTypeAndFaction(EntityType.Fighter, randomFaction)
            for _, v in pairs(fighters) do
                table.insert(factionFighters, v.id)
            end
            if #factionFighters > 0 then
                if #factionFighters > 3 and math.random() < 0.2 then
                    playRandomDialogue(factionFighters)
                else
                    fighterChatterMessage(randomEntry(random(), factionFighters), getRandomChatterLine())
                end
            end
        end
    end
    fms._combatCheckLeft = (fms._combatCheckLeft or 0) - timeStep
    if fms._combatCheckLeft <= 0 then
        fms._combatCheckLeft = 1  -- Update every 1 second instead of 2 for more responsive targeting
        CombatManager.updateCombat(factionData, false)
    end
    
    -- Return the updated fighterChatterTimeLeft so it can be used in the next update
    return fighterChatterTimeLeft
end
return SectorUpdateManager
