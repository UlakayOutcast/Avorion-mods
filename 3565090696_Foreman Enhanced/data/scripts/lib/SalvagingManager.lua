local SalvagingManager = {}
function SalvagingManager.startSalvaging(factionIndex, starterPlayerIndex, commandingSalvageMaterialLevel, inMiningFilters, factionData, fms, ShipDataManager, WreckageManagement, MIN_WRECKAGE_RESOURCES, TARGET_THRESHOLD, SALVAGE_DEBUG_ENABLED, onServer, lastCacheRefresh, smartScanActive)
    SALVAGE_DEBUG_ENABLED = false -- Debug enabled
    if SALVAGE_DEBUG_ENABLED then
        print(string.format("[SALVAGE DEBUG] SalvagingManager.startSalvaging called for faction %d", factionIndex))
    end
    
    -- Check if mining filters are properly provided
    if not inMiningFilters or not next(inMiningFilters) then
        if SALVAGE_DEBUG_ENABLED then
            print("[SALVAGE DEBUG] No mining filters provided, attempting to get filters from player...")
        end
        
        -- Try to get mining filters from the player if not provided
        local player = Player(starterPlayerIndex)
        if player and player.craft then
            local foremanSystem = player.craft:getSystem(ComponentType.System)
            if foremanSystem then
                local ok, filters = pcall(function() return foremanSystem:getMiningFilters() end)
                if ok and filters then
                    inMiningFilters = filters
                    if SALVAGE_DEBUG_ENABLED then
                        print("[SALVAGE DEBUG] Retrieved mining filters from player craft system")
                    end
                end
            end
        end
        
        -- If still no filters, create default filters and continue
        if not inMiningFilters or not next(inMiningFilters) then
            if SALVAGE_DEBUG_ENABLED then
                print("[SALVAGE DEBUG] Creating default mining filters (all materials enabled)...")
            end
            -- Create default filters that allow all material types
            inMiningFilters = {}
            for i = 0, 10 do -- Material levels 0-10
                inMiningFilters[i] = true
            end
        end
    end
    ShipDataManager.initializeFactionData(factionData, getCachedEntitiesByType)
    local data = factionData[factionIndex]
    if data.salvage == true then 
        if SALVAGE_DEBUG_ENABLED then
            print(string.format("[SALVAGE DEBUG] Salvage already active for faction %d, returning", factionIndex))
        end
        return 
    end
    UnifiedWreckageCache = include("UnifiedWreckageCache")
    UnifiedWreckageCache.refreshCache(true) -- Force initial cache refresh
    local unassigned = UnifiedWreckageCache.getUnassignedWreckages()
    if SALVAGE_DEBUG_ENABLED then
        print(string.format("[SALVAGE DEBUG] After cache refresh: %d unassigned wreckages found", #unassigned))
    end
    data.commandingSalvageMaterialLevel = commandingSalvageMaterialLevel
    data.miningFilters = inMiningFilters
    data.salvage = true
    data.salvageStandbyMode = true -- New flag for standby mode
    
    if SALVAGE_DEBUG_ENABLED then
        print(string.format("[SALVAGE DEBUG] Mining filters for faction %d:", factionIndex))
        if inMiningFilters then
            for material, enabled in pairs(inMiningFilters) do
                print(string.format("[SALVAGE DEBUG]   Material %d: %s", material, enabled and "enabled" or "disabled"))
            end
        else
            if SALVAGE_DEBUG_ENABLED then
                print("[SALVAGE DEBUG]   No mining filters provided!")
            end
        end
    end
    for shipIndex, _ in pairs(data.ships) do
        ShipDataManager.checkAndCreateShipData(factionIndex, shipIndex, factionData)
    end
    WreckageManagement.launchSalvageFightersOnStandby(factionIndex, factionData)
    fms.factionOperationStarted(factionIndex, starterPlayerIndex, false)
end
return SalvagingManager
