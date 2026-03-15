local EntityJumpHandling = {}
function EntityJumpHandling.onEntityJump(shipIndex, x, y, sectorChangeType, factionData, asteroidTargets, salvageTargets)
    local entity = Sector():getEntity(shipIndex)
    if entity.isShip and entity.playerOrAllianceOwned then
        local factionIndex = entity.factionIndex
        local data = factionData[factionIndex]
        if data then
            data.ships[tostring(shipIndex)] = nil
            CombatUtils.invalidateFighterWeaponCache()
            if getTableLength(data.ships) == 0 then
                -- Preserve scan status even when all ships leave the sector
                local sectorScanned = data.sectorScanned
                factionData[factionIndex] = nil
                if getTableLength(factionData) == 0 then
                    factionData = {}
                    asteroidTargets = {}
                    salvageTargets = {}
                end
                -- If this faction had scanned the sector, preserve that information
                if sectorScanned then
                    if not factionData[factionIndex] then
                        factionData[factionIndex] = {}
                    end
                    factionData[factionIndex].sectorScanned = sectorScanned
                end
            end
        end
        if ScanningManager.hasActiveScan(factionIndex) then
            local scanData = ScanningManager.getScanData(factionIndex)
            if scanData and scanData.sectorScanStarter == tostring(shipIndex) then
                ScanningManager.scanCancelled(factionIndex)
            end
        end
    end
end
return EntityJumpHandling
