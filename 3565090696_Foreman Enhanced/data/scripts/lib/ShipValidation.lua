local ShipValidation = {}

function ShipValidation.isCarrier(shipId)
    local hasMiningFighters = false
    local hasSalvagingFighters = false
    local hasRawFighters = false
    local hangar = Hangar(shipId)
    local squads = {hangar:getSquads()}
    
    for _, index in pairs(squads) do
        local weaponCategory = hangar:getSquadMainWeaponCategory(index)
        hasRawFighters = hasRawFighters or hangar:getSquadHasRawMinersOrSalvagers(index)
        if weaponCategory == WeaponCategory.Mining then
            hasMiningFighters = true
            break
        elseif weaponCategory == WeaponCategory.Salvaging then
            hasSalvagingFighters = true
            break
        end
    end
    
    if hasMiningFighters or hasSalvagingFighters then
        return true, hasRawFighters
    end
    return false, false
end

function ShipValidation.shipHasForemanModule(shipId)
    local shipSystem = ShipSystem(shipId)
    if shipSystem then
        for upgrade, permanent in pairs(shipSystem:getUpgrades()) do
            if permanent and upgrade.script == "data/scripts/systems/foremansystem.lua" then
                return true
            end
        end
    end
    return false
end
function ShipValidation.getShipMiningAndSalvagingMaterial(shipId)
    local maxMiningMaterial = nil
    local maxSalvageMaterial = nil
    local hangar = Hangar(shipId)
    local squads = {hangar:getSquads()}
    for i,v in pairs(squads) do
        local material = hangar:getHighestMaterialInSquadMainCategory(v)
        if hangar:getSquadMainWeaponCategory(v) == WeaponCategory.Mining then
            if maxMiningMaterial == nil or maxMiningMaterial.value < material.value then
                maxMiningMaterial = material
            end
        elseif hangar:getSquadMainWeaponCategory(v) == WeaponCategory.Salvaging then
            if maxSalvageMaterial == nil or maxSalvageMaterial.value < material.value then
                maxSalvageMaterial = material
            end
        end
    end
    return maxMiningMaterial, maxSalvageMaterial
end
return ShipValidation
