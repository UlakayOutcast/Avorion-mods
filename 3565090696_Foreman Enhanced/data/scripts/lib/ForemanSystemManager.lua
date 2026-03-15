local ForemanSystemManager = {}
function ForemanSystemManager.getAndSetForemanModuleMiningAccuracy(shipIndex, currentScanAccuracy, currentForemanMaterialLevel)
    if onClient() then
        local scanAccuracy = currentScanAccuracy or -1
        local foremanMaterialLevel = currentForemanMaterialLevel or nil
        local shipSystem = ShipSystem(shipIndex)
        if shipSystem then
            for upgrade, permanent in pairs(shipSystem:getUpgrades()) do
                if permanent and upgrade.script == "data/scripts/systems/foremansystem.lua" then
                    local success, ret, squads, maxSquads, miningMaterial, fighterCargoPickup, fighterPickUpLoot, sectorScanningSpeed, miningAmountAccuracy = pcall(function()
                        return Entity(shipIndex):invokeFunction("data/scripts/systems/foremansystem.lua", "getBonuses", upgrade.seed.int32, upgrade.rarity, permanent)
                    end)
                    if success and ret == 0 then
                        if scanAccuracy < miningAmountAccuracy then
                            scanAccuracy = miningAmountAccuracy
                        end
                        if foremanMaterialLevel == nil or foremanMaterialLevel < miningMaterial then
                            foremanMaterialLevel = miningMaterial
                        end
                    elseif not success then
                        print("Foreman: Failed to get foreman system bonuses for ship " .. tostring(shipIndex) .. ": " .. tostring(ret))
                    end
                end
            end
        end
        return scanAccuracy, foremanMaterialLevel
    end
    return currentScanAccuracy, currentForemanMaterialLevel
end
return ForemanSystemManager
