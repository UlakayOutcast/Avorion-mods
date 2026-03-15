local SectorChangeManager = {}
function SectorChangeManager.onSectorChanged(x, y, harvest, salvage, sectorScanned, mineableCache, clearShipListCallback, registerSectorCallbacksCallback, onLoadCallback)
    harvest = false
    salvage = false
    sectorScanned = false
    if mineableCache then
        mineableCache = { t = 0, total = 0, count = 0, perOre = { [0] = 0,[1] = 0,[2] = 0,[3] = 0,[4] = 0,[5] = 0,[6] = 0 }, asteroidData = {}, lastAsteroidCount = 0, filtersChanged = false, lastUpdateTime = 0 }
    end
    if onClient() then
        clearShipListCallback()
        registerSectorCallbacksCallback()
    end
    onLoadCallback()
    return harvest, salvage, sectorScanned, mineableCache
end
return SectorChangeManager
