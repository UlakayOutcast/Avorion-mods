local EntityCreationManager = {}
function EntityCreationManager.onEntityCreated(entityId, asteroids, wreckages, factionData, pendingCacheUpdates, IMMEDIATE_CACHE_UPDATE, SALVAGE_DEBUG_ENABLED, onServer, fms, WreckageValidation, ShipDataManager, LootManager)
    local entity = Entity(entityId)
    invalidateEntityCache()
    if entity.isShip or entity.isStation or entity.isFighter then
        CombatUtils.invalidateGlobalCombatContext()
    end
    if IMMEDIATE_CACHE_UPDATE and valid(entity) and entity:hasComponent(ComponentType.MineableMaterial) then
        table.insert(pendingCacheUpdates, entityId)
        if SALVAGE_DEBUG_ENABLED and onServer() then
            Sector():broadcastChatMessage(Entity(), ChatMessageType.Chatter, 
                string.format("[FOREMAN] Queued new entity for cache update: %s", tostring(entityId)))
        end
    end
    if entity.isAsteroid then
        local amount = 0
        if valid(entity) then
            for _, j in pairs({entity:getMineableResources()}) do
                amount = amount + j
            end
            if amount > 0 then
                local mineableMaterial = entity:getMineableMaterial()
                if mineableMaterial then
                    asteroids[tostring(entity.index)] = { translationf = entity.translationf, material = mineableMaterial.value, amount = amount}
                    fms.invalidateAsteroidValidationCache()
                end
            end
        end
    elseif entity.isWreckage then
        local amount = 0
        if valid(entity) then
            for _, j in pairs({entity:getMineableResources()}) do
                amount = amount + j
            end
            if amount >= 10 then
                local mineableMaterial = entity:getMineableMaterial()
                if mineableMaterial then
                    wreckages[tostring(entity.index)] = mineableMaterial.value
                    WreckageValidation.invalidateWreckageValidationCache()
                end
            else
                Sector():deleteEntity(entity)
            end
        end
    elseif (entity.isShip or entity.isStation) and entity.playerOrAllianceOwned then
        if ShipDataManager.checkAndCreateShipData(entity.factionIndex, entity.index, factionData) then
            if factionData[entity.factionIndex].harvest then
                fms.startMiningWithShip(entity.factionIndex, entity.index)
            end
            if factionData[entity.factionIndex].salvage then
                fms.startSalvagingWithShip(entity.factionIndex, entity.index)
            end
        end
    elseif entity.isLoot then
        if entity:hasComponent(ComponentType.SystemUpgradeLoot) or entity:hasComponent(ComponentType.TurretLoot) then
            fms.handleLootDrop(entity.index)
        end
    end
end
return EntityCreationManager
