local AsteroidTargetManager = {}

function AsteroidTargetManager.clearAsteroidTarget(asteroidIndex, asteroidTargets)
    if asteroidTargets[asteroidIndex] == nil or asteroidTargets[asteroidIndex].ships == nil then 
        return 
    end
    
    for i, v in pairs(asteroidTargets[asteroidIndex].ships) do
        for _, j in pairs(v.squads) do
            asteroidTargets[asteroidIndex].ships[i].squads[j] = nil
        end
        asteroidTargets[asteroidIndex].ships[i].squads = nil
        asteroidTargets[asteroidIndex].ships[i] = nil
    end
    
    asteroidTargets[asteroidIndex].ships = nil
    asteroidTargets[asteroidIndex] = nil
end

function AsteroidTargetManager.clearAsteroidTargets(asteroidTargets)
    for a, _ in pairs(asteroidTargets) do
        for i, v in pairs(asteroidTargets[a].ships) do
            for _, j in pairs(v.squads) do
                asteroidTargets[a].ships[i].squads[j] = nil
            end
            asteroidTargets[a].ships[i].squads = nil
            asteroidTargets[a].ships[i] = nil
        end
        asteroidTargets[a].ships = nil
        asteroidTargets[a] = nil
    end
end
function AsteroidTargetManager.addSquadsToAsteroid(asteroidIndex, translationf, factionIndex, shipIndex, squadsToAdd, asteroidTargets)
    if asteroidTargets[tostring(asteroidIndex)] == nil then
        asteroidTargets[tostring(asteroidIndex)] = { index = asteroidIndex, translationf = translationf, ships = {} }
    end
    if asteroidTargets[tostring(asteroidIndex)].ships[tostring(shipIndex)] == nil then
        asteroidTargets[tostring(asteroidIndex)].ships[tostring(shipIndex)] = { factionIndex = factionIndex, shipIndex = shipIndex, squads = {} }
    end
    for _, i in pairs(squadsToAdd) do
        table.insert(asteroidTargets[tostring(asteroidIndex)].ships[tostring(shipIndex)].squads, i)
    end
end
function AsteroidTargetManager.removeAsteroidTarget(asteroidIndex, asteroidTargets)
    if asteroidTargets[tostring(asteroidIndex)] then
        for _,v in pairs(asteroidTargets[tostring(asteroidIndex)].ships) do
            v.squads = nil
        end
        asteroidTargets[tostring(asteroidIndex)].ships = nil
        asteroidTargets[tostring(asteroidIndex)] = nil
    end
end
return AsteroidTargetManager
