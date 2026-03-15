local AsteroidCleanup = {}

function AsteroidCleanup.cleanupDepletedAsteroids(asteroids, factionData, validateAsteroidResources, removeAsteroid)
    local depletedAsteroids = {}
    
    for asteroidIndex, _ in pairs(asteroids) do
        if not validateAsteroidResources(asteroidIndex) then
            table.insert(depletedAsteroids, asteroidIndex)
        end
    end
    
    for _, asteroidIndex in pairs(depletedAsteroids) do
        removeAsteroid(asteroidIndex)
    end
    
    if #depletedAsteroids > 0 then
        for factionIndex, _ in pairs(factionData) do
            for _, player in pairs({Sector():getPlayers()}) do
                if player.index == factionIndex or player.allianceIndex == factionIndex then
                    player:invokeFunction("data/scripts/ForemanManager.lua", "forceAsteroidCountUpdateWrapper", factionIndex)
                end
            end
        end
    end
end

return AsteroidCleanup
