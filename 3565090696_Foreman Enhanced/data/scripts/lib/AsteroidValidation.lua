local function validateAsteroidResources(asteroidIndex, asteroids, cacheValid, asteroidValidationCache)
    local asteroidKey = tostring(asteroidIndex)
    
    if not asteroidValidationCache then
        asteroidValidationCache = {}
    end
    
    if cacheValid and asteroidValidationCache[asteroidKey] ~= nil then
        return asteroidValidationCache[asteroidKey]
    end
    
    local asteroid = Entity(Uuid(asteroidIndex))
    if not valid(asteroid) then
        asteroidValidationCache[asteroidKey] = false
        return false
    end
    
    local trackedAsteroid = asteroids[asteroidKey]
    if trackedAsteroid then
        local resourcesLeft = 0
        if valid(asteroid) then
            for _, j in pairs({asteroid:getMineableResources()}) do
                resourcesLeft = resourcesLeft + j
            end
        else
            asteroids[asteroidKey] = nil
            asteroidValidationCache[asteroidKey] = false
            return false
        end
        if resourcesLeft ~= trackedAsteroid.amount then
            trackedAsteroid.amount = resourcesLeft
            if resourcesLeft <= 0 then
                asteroids[asteroidKey] = nil
                asteroidValidationCache[asteroidKey] = false
                return false
            end
        end
        asteroidValidationCache[asteroidKey] = (resourcesLeft > 0)
        return resourcesLeft > 0
    end
    local resourcesLeft = 0
    if valid(asteroid) then
        for _, j in pairs({asteroid:getMineableResources()}) do
            resourcesLeft = resourcesLeft + j
        end
        if resourcesLeft > 0 then
            local mineableMaterial = asteroid:getMineableMaterial()
            if mineableMaterial then
                asteroids[asteroidKey] = {
                    translationf = asteroid.translationf,
                    material = mineableMaterial.value,
                    amount = resourcesLeft
                }
                asteroidValidationCache[asteroidKey] = true
                return true
            end
        end
    end
    asteroidValidationCache[asteroidKey] = false
    return false
end
return {
    validateAsteroidResources = validateAsteroidResources
}
