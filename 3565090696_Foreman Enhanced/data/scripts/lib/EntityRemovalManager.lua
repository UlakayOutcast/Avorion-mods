local EntityRemovalManager = {}

function EntityRemovalManager.onEntityRemoved(entityId, factionData, SALVAGE_DEBUG_ENABLED, onServer, fms)
    invalidateEntityCache()
    CombatUtils.invalidateGlobalCombatContext()
    fms.removeAsteroid(entityId)
    
    UnifiedWreckageCache = include("UnifiedWreckageCache")
    local wreckageData = UnifiedWreckageCache.getWreckage(tostring(entityId))
    if wreckageData then
        if SALVAGE_DEBUG_ENABLED and onServer() then
            Sector():broadcastChatMessage(Entity(), ChatMessageType.Chatter, 
                string.format("[FOREMAN] Wreckage entity %s removed - will reassign squads", tostring(entityId)))
        end
        UnifiedWreckageCache.removeWreckage(tostring(entityId))
    end
    
    fms.removeWreckage(entityId)
    
    for factionIndex, fData in pairs(factionData) do
        for shipIndex, _ in pairs(fData.ships) do
            if shipIndex == tostring(entityId) then
                fms.scanCancelled(factionIndex)
                return
            end
        end
    end
end
return EntityRemovalManager
