local AsteroidTargetUpdateManager = {}

function AsteroidTargetUpdateManager.asteroidTargetsUpdate(asteroidTargets, asteroids, factionData, fms, AsteroidUtils, SquadManagement, AsteroidTargetManager)
    local asteroidsMined = {}
    
    for asteroidId, asteroidData in pairs(asteroidTargets) do
        local asteroid = Entity(Uuid(asteroidId))
        local resourcesLeft = 0
        
        if valid(asteroid) then
            for _, j in pairs({asteroid:getMineableResources()}) do
                resourcesLeft = resourcesLeft + j
            end
        end
        
        if resourcesLeft == 0 then
            table.insert(asteroidsMined, asteroidId)
            fms.removeAsteroid(asteroidId)
            local tempAssignments = {}
            
            for _, shipData in pairs(asteroidData.ships) do
                local shipIndex = shipData.shipIndex
                local ship = Entity(shipIndex)
                local cargoSpaceLeft = ship.freeCargoSpace >= 150
                local controller = FighterController(shipIndex)
                local hangar = Hangar(shipIndex)
                for _, index in pairs(shipData.squads) do
                    local rawSquad = shipData.squads[index]
                    local squadMaterial = hangar:getHighestMaterialInSquadMainCategory(index).value + 1
                    local bestAsteroidIndex = nil
                    local bestAsteroidData = nil
                    local minSquads = math.huge
                    local minDistance = math.huge
                    for asteroidKey, asteroidInfo in pairs(asteroids) do
                        if asteroidKey ~= tostring(asteroidId) and 
                           factionData[shipData.factionIndex].miningFilters[asteroidInfo.material] == true and
                           squadMaterial >= asteroidInfo.material and
                           AsteroidUtils.validateAsteroidResources(asteroidKey, asteroids, fms._validationCacheValid, fms._asteroidValidationCache) then
                            local currentSquads = SquadManagement.getAsteroidSquadCount(asteroidKey, asteroidTargets)
                            local tempSquads = tempAssignments[asteroidKey] or 0
                            local totalSquads = currentSquads + tempSquads
                            local dist = distance(asteroidData.translationf, asteroidInfo.translationf)
                            if totalSquads < minSquads or (totalSquads == minSquads and dist < minDistance) then
                                minSquads = totalSquads
                                minDistance = dist
                                bestAsteroidIndex = asteroidKey
                                bestAsteroidData = asteroidInfo
                            end
                        end
                    end
                    if bestAsteroidIndex then
                        tempAssignments[bestAsteroidIndex] = (tempAssignments[bestAsteroidIndex] or 0) + 1
                        if rawSquad then
                            if cargoSpaceLeft then
                                controller:setSquadOrders(index, FighterOrders.Attack, Uuid(bestAsteroidIndex))
                                fms.addSquadsToAsteroid(bestAsteroidIndex, bestAsteroidData.translationf, shipData.factionIndex, shipIndex, { index })
                            end
                        else
                            controller:setSquadOrders(index, FighterOrders.Attack, Uuid(bestAsteroidIndex))
                            fms.addSquadsToAsteroid(bestAsteroidIndex, bestAsteroidData.translationf, shipData.factionIndex, shipIndex, { index })
                        end
                    end
                end
                local hasActiveSquads = false
                for _, index in pairs(shipData.squads) do
                    local squadMaterial = hangar:getHighestMaterialInSquadMainCategory(index).value + 1
                    for asteroidKey, asteroidInfo in pairs(asteroids) do
                        if factionData[shipData.factionIndex].miningFilters[asteroidInfo.material] == true and
                           squadMaterial >= asteroidInfo.material and
                           AsteroidUtils.validateAsteroidResources(asteroidKey, asteroids, fms._validationCacheValid, fms._asteroidValidationCache) then
                            hasActiveSquads = true
                            break
                        end
                    end
                    if hasActiveSquads then break end
                end
                if not hasActiveSquads then
                    local fData = factionData[ship.factionIndex]
                    fData.harvest = false
                    fData.ships[tostring(shipIndex)].harvest = false
                end
            end
        end
    end
    for _,v in pairs(asteroidsMined) do
        AsteroidTargetManager.clearAsteroidTarget(v, asteroidTargets)
    end
end
return AsteroidTargetUpdateManager
