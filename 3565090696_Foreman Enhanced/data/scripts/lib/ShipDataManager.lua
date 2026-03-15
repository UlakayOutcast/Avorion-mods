local ShipDataManager = {}

-- Debug flag for mining filter debugging
local MINING_FILTER_DEBUG = false
function ShipDataManager.checkAndCreateFactionData(factionIndex, factionData)
    if not factionData[factionIndex] then
        factionData[factionIndex] = { 
            sectorScanned = false, 
            sectorScanTimeLeft = nil, 
            commandingAsteroidMaterialLevel = nil, 
            harvest = false, 
            salvage = false, 
            miningFilters = {}, 
            ships = {} 
        }
    end
    
    -- Initialize mining filters with default values (all materials allowed by default)
    if not factionData[factionIndex].miningFilters then
        factionData[factionIndex].miningFilters = {}
    end
    
    -- Ensure all material types have explicit values (default to true = allow mining)
    for materialIndex = 0, 6 do
        if factionData[factionIndex].miningFilters[materialIndex] == nil then
            factionData[factionIndex].miningFilters[materialIndex] = true
        end
    end
end
function ShipDataManager.checkAndCreateShipData(factionIndex, shipIndex, factionData)
    ShipDataManager.checkAndCreateFactionData(factionIndex, factionData)
    if factionData[factionIndex].ships[tostring(shipIndex)] == nil then
        local ship = Entity(Uuid(shipIndex))
        local hangar = Hangar(ship.id)
        if not hangar then return false end
        local materialLevel = nil
        for upgrade, permanent in pairs(ShipSystem(shipIndex):getUpgrades()) do
            if permanent and upgrade.script == "data/scripts/systems/foremansystem.lua" then
                local ret, _, _, miningMaterial, _, _, _, _ = ship:invokeFunction("data/scripts/systems/foremansystem.lua", "getBonuses", upgrade.seed.int32, upgrade.rarity, permanent)
                if materialLevel == nil or materialLevel < miningMaterial then
                    materialLevel = miningMaterial
                end
            end
        end
        if materialLevel == nil then return false end
        local shipData = { 
            fighterPickUpLoot = false, 
            harvest = false, 
            salvage = false, 
            hasRawFighters = false, 
            miningSquads = {}, 
            salvageSquads = {} 
        }
        local squads = {hangar:getSquads()}
        local hasRawFighters = false
        for _, index in pairs(squads) do
            local mainCategory = hangar:getSquadMainWeaponCategory(index)
            local rawSquad = hangar:getSquadHasRawMinersOrSalvagers(index)
            if rawSquad then hasRawFighters = true end
            if mainCategory == WeaponCategory.Mining then
                shipData.miningSquads[index] = rawSquad
            elseif mainCategory == WeaponCategory.Salvaging then
                shipData.salvageSquads[index] = rawSquad
            end
        end
        shipData.hasRawFighters = hasRawFighters
        factionData[factionIndex].ships[tostring(shipIndex)] = shipData
        return true
    end
    return false
end
function ShipDataManager.onEntityEntered(shipIndex, factionData)
    local entity = Entity(shipIndex)
    if entity.isShip and entity.playerOrAllianceOwned then
        entity:registerCallback("onAIStateChanged", "onShipAIStateChanged")
        entity:registerCallback("onJumpRouteCalculationStarted", "onShipJumpRouteCalculationStarted")
        if ShipDataManager.checkAndCreateShipData(entity.factionIndex, entity.index, factionData) then
            if factionData[entity.factionIndex].harvest then
                deferredCallback(3, "assignMiningSquadsRandomly", entity.factionIndex, entity.index)
            end
            if factionData[entity.factionIndex].salvage then
                deferredCallback(3, "assignSalvageSquadsRandomly", entity.factionIndex, entity.index)
            end
        end
    end
end
function ShipDataManager.initializeFactionData(factionData, getCachedEntitiesByType)
    local ships = getCachedEntitiesByType(EntityType.Ship)
    local stations = getCachedEntitiesByType(EntityType.Station)
    for _,v in pairs(ships) do
        if v.playerOrAllianceOwned then
            ShipDataManager.checkAndCreateShipData(v.factionIndex, v.index, factionData)
            Entity(v.id):registerCallback("onAIStateChanged", "onShipAIStateChanged")
            Entity(v.id):registerCallback("onJumpRouteCalculationStarted", "onShipJumpRouteCalculationStarted")
        end
    end
    for _,v in pairs(stations) do
        if v.playerOrAllianceOwned then
            ShipDataManager.checkAndCreateShipData(v.factionIndex, v.index, factionData)
        end
    end
end
function ShipDataManager.miningFilterChanged(factionIndex, index, value, factionData)
    ShipDataManager.checkAndCreateFactionData(factionIndex, factionData)
    factionData[factionIndex].miningFilters[index] = value
    if MINING_FILTER_DEBUG then
        print("[FILTER DEBUG] SERVER: ShipDataManager.miningFilterChanged - Set material " .. index .. " to " .. tostring(value) .. " for faction " .. factionIndex)
        
        -- Debug: Show all current filters after this change
        print("[FILTER DEBUG] SERVER: Current filters for faction " .. factionIndex .. " after change:")
        for material, enabled in pairs(factionData[factionIndex].miningFilters) do
            print("[FILTER DEBUG] SERVER:   Material " .. material .. ": " .. (enabled and "enabled" or "disabled"))
        end
    end
end
function ShipDataManager.shipCargoCheck(factionData)
    for _, data in pairs(factionData) do
        for shipIndex, shipData in pairs(data.ships) do
            if shipData.isActive then
                local ship = Entity(shipIndex)
                if ship then
                    if ship.freeCargoSpace <= 150 then
                        shipData.harvest = false
                        shipData.salvage = false
                        shipData.isActive = false
                    end
                end
            end
        end
    end
end
return ShipDataManager
