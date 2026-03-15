local SalvageTargetCounter = {}
local UnifiedWreckageCache = include("UnifiedWreckageCache")
function SalvageTargetCounter.getSalvageTargetCount(factionIndex, factionData, wreckageCache, getTableLength, refreshWreckageCache, validateWreckageResources)
    local SALVAGE_DEBUG_ENABLED = false -- Debug enabled
    if SALVAGE_DEBUG_ENABLED then
        print("[FOREMAN DEBUG] getSalvageTargetCount called")
    end
    if not factionData or not factionData[factionIndex] then 
        if SALVAGE_DEBUG_ENABLED then
            print("[FOREMAN DEBUG] No faction data, returning 0")
        end
        return 0 
    end
    UnifiedWreckageCache.cleanup()
    local unassigned = UnifiedWreckageCache.getUnassignedWreckages()
    local count = #unassigned
    
    -- Debug: Also check total wrecks in sector
    local allWreckages = getCachedEntitiesByType(EntityType.Wreckage)
    local totalWrecks = 0
    local validWrecks = 0
    for _, entity in pairs(allWreckages) do
        if valid(entity) and entity:hasComponent(ComponentType.MineableMaterial) then
            totalWrecks = totalWrecks + 1
            local resources = 0
            for _, amount in pairs({entity:getMineableResources()}) do
                resources = resources + amount
            end
            if resources >= 1 then
                validWrecks = validWrecks + 1
            end
        end
    end
    
    if SALVAGE_DEBUG_ENABLED then
        print(string.format("[FOREMAN DEBUG] Total wrecks in sector: %d, Valid wrecks: %d, Unassigned from cache: %d", totalWrecks, validWrecks, count))
    end
    return count
end
return SalvageTargetCounter
