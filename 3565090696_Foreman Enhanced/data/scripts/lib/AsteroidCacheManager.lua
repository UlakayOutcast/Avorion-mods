local AsteroidCacheManager = {}

function AsteroidCacheManager.invalidateAsteroidCache(mineableCache)
    if mineableCache then
        mineableCache.t = 0
        mineableCache.total = 0
        mineableCache.count = 0
        mineableCache.perOre = { [0] = 0, [1] = 0, [2] = 0, [3] = 0, [4] = 0, [5] = 0, [6] = 0 }
        mineableCache.lastUpdateTime = 0
        mineableCache.filtersChanged = true
    end
end

function AsteroidCacheManager.invalidateAsteroidCacheOnDestruction(mineableCache)
    if mineableCache then
        mineableCache.t = 0
        mineableCache.asteroidData = {}
        mineableCache.asteroidHashes = {}
        mineableCache.lastAsteroidCount = 0
        mineableCache.lastUpdateTime = 0
    end
end

function AsteroidCacheManager.invalidateAsteroidCacheOnFilterChange(mineableCache)
    if mineableCache and mineableCache.t > 0 then
        mineableCache.filtersChanged = true
    end
end

return AsteroidCacheManager
