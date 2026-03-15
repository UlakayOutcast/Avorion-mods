local CombatUtils = {}

function CombatUtils.getNearestHostileTargetForShip(shipIndex)
    local ship = Entity(Uuid(shipIndex))
    if not valid(ship) then return nil end
    
    local ai = ShipAI(ship.index)
    if not ai then return nil end
    
    local nearest
    local nearestDist = math.huge
    local entityTypes = {EntityType.Ship, EntityType.Station}
    local cachedEntities = getCachedEntitiesByTypes(entityTypes)
    local candidates = {}
    
    for _, ship in pairs(cachedEntities[EntityType.Ship]) do
        table.insert(candidates, ship)
    end
    
    for _, station in pairs(cachedEntities[EntityType.Station]) do
        table.insert(candidates, station)
    end
    
    for _, target in pairs(candidates) do
        if valid(target) and tostring(target.factionIndex) ~= ship.factionIndex then
            local ok, isEnemy = pcall(function() return ai:isEnemy(target) end)
            if ok and isEnemy then
                local d = distance2(target.translationf, ship.translationf)
                if d < nearestDist then
                    nearest = target
                    nearestDist = d
                end
            elseif target.type == EntityType.Station and not ok then
                if onServer() then
                    local targetName = target.name or "Unknown"
                    local shipName = ship.name or "Unknown"
                    print(string.format("[FOREMAN DEBUG] Station %s (faction %d) enemy check failed for ship %s (faction %d)",
                        targetName, tostring(target.factionIndex), shipName, tostring(ship.factionIndex)))
                end
            end
        end
    end
    return nearest
end
function CombatUtils.getSquadsWithCombatFighters(shipId)
    local hangar = Hangar(shipId)
    if not hangar then return {} end
    local hangarSquads = {hangar:getSquads()}
    local squads = {}
    for _, squadIndex in pairs(hangarSquads) do
        if hangar:getSquadMainWeaponCategory(squadIndex) == WeaponCategory.Armed then
            table.insert(squads, squadIndex)
        end
    end
    return squads
end
function CombatUtils.getBestHostileTargetForShip(shipIndex, currentTargetId, combatAssignedTargets, targetDiversityCache, targetDiversityCacheAge, targetDiversityCacheMaxAge, debugCombatMessages)
    local ship = Entity(Uuid(shipIndex))
    if not valid(ship) then return nil end
    local ai = ShipAI(ship.index)
    if not ai then return nil end
    local function isEnemy(target)
        if not valid(target) then return false end
        if tostring(target.factionIndex) == ship.factionIndex then return false end
        local ok, res = pcall(function() return ai:isEnemy(target) end)
        if not ok then 
            local fallbackResult = tostring(target.factionIndex) ~= ship.factionIndex and tostring(target.factionIndex) ~= 0
            if target.type == EntityType.Station and onServer() then
                local targetName = target.name or "Unknown"
                print(string.format("[FOREMAN DEBUG] Station %s (faction %d) AI enemy check failed, using fallback: %s",
                    targetName, tostring(target.factionIndex), tostring(fallbackResult)))
            end
            return fallbackResult
        end
        return res
    end
    local function hullFrac(entity)
        if not valid(entity) then return 1 end
        local d = Durability(entity)
        if d and d.durability and d.maximum and d.maximum > 0 then
            return math.max(0, math.min(1, d.durability / d.maximum))
        end
        return 1
    end
    local function shieldFrac(entity)
        if not valid(entity) then return 1 end
        if entity.shieldDurability and entity.shieldMaxDurability and entity.shieldMaxDurability > 0 then
            return math.max(0, math.min(1, entity.shieldDurability / entity.shieldMaxDurability))
        end
        return 1
    end
    local function calculateTargetValue(target, fighterAnalysis)
        if not valid(target) then return 0 end
        local hp = hullFrac(target)
        local shield = shieldFrac(target)
        local distance = distance2(target.translationf, ship.translationf)
        local baseValue = 1.0
		if target.type == EntityType.Ship then
            local size = target.volume or 1
            if size > 1000 then
                baseValue = baseValue * 3.0  -- Capital ships
            elseif size > 100 then
                baseValue = baseValue * 2.0  -- Medium ships
            else
                baseValue = baseValue * 1.5  -- Small ships
            end
		elseif target.type == EntityType.Station then
			baseValue = baseValue * 0.5  -- Stations are low priority
        end
        local combatScore = 0
        if hp < 0.2 then
            combatScore = combatScore + 2.0  -- Nearly dead - high priority
        elseif hp < 0.5 then
            combatScore = combatScore + 1.5  -- Damaged - medium priority
        elseif hp < 0.8 then
            combatScore = combatScore + 1.0  -- Lightly damaged
        else
            combatScore = combatScore + 0.5  -- Full health - lower priority
        end
        if shield < 0.1 then
            combatScore = combatScore + 1.0  -- No shields - easier target
        elseif shield < 0.5 then
            combatScore = combatScore + 0.5  -- Weak shields
        end
        local specializationScore = 0
        if fighterAnalysis then
            if fighterAnalysis.isShieldSpecialist then
                if shield > 0.7 then
                    specializationScore = 2.0
                elseif shield > 0.4 then
                    specializationScore = 1.0
                elseif shield > 0.1 then
                    specializationScore = 0.2
                else
                    specializationScore = -0.5
                end
            elseif fighterAnalysis.isHullSpecialist then
                if hp < 0.3 then
                    specializationScore = 2.0
                elseif hp < 0.6 then
                    specializationScore = 1.0
                elseif hp < 0.8 then
                    specializationScore = 0.2
                else
                    specializationScore = -0.3
                end
            end
        end
        local distancePenalty = math.min(1.0, distance / 10000)  -- Normalize distance
        local finalScore = (baseValue + combatScore + specializationScore) * (1.0 - distancePenalty * 0.3)
        return finalScore
    end
    local function getTargetDiversityModifier(target)
        if not valid(target) then return 0 end
        local targetId = tostring(target.index)
        local currentTime = os.clock()
        local cacheKey = targetId
        if targetDiversityCache[cacheKey] and (currentTime - targetDiversityCacheAge) < targetDiversityCacheMaxAge then
            return targetDiversityCache[cacheKey]
        end
        local attackingSquads = 0
        if combatAssignedTargets then
            for key, assignedTargetId in pairs(combatAssignedTargets) do
                if assignedTargetId == targetId then
                    attackingSquads = attackingSquads + 1
                end
            end
        end
		local isHighValueTarget = false
		if target.type == EntityType.Ship and (target.volume or 1) > 2000 then
			isHighValueTarget = true
		end
        local modifier = 0
        if isHighValueTarget then
            if attackingSquads >= 3 then
                modifier = -1.0
            elseif attackingSquads >= 2 then
                modifier = 0.2
            end
        else
            if attackingSquads >= 2 then
                modifier = -2.0
            elseif attackingSquads >= 1 then
                modifier = -1.0
            end
        end
        targetDiversityCache[cacheKey] = modifier
        targetDiversityCacheAge = currentTime
        return modifier
    end
	local ships = getCachedEntitiesByType(EntityType.Ship)
	local stations = getCachedEntitiesByType(EntityType.Station)
	local candidates = {}
	for _, target in ipairs(ships) do
		table.insert(candidates, target)
	end
	for _, target in ipairs(stations) do
		table.insert(candidates, target)
	end
    if #candidates > 0 then
        local shipPos = ship.translationf
        local distances = {}
        for i, target in ipairs(candidates) do
            if valid(target) then
                distances[i] = {target = target, dist = distance2(target.translationf, shipPos)}
            end
        end
        table.sort(distances, function(a, b) return a.dist < b.dist end)
        candidates = {}
        for i = 1, #distances do
            candidates[i] = distances[i].target
        end
    end
    local bestTarget = nil
    local bestScore = 0
    local currentTarget = nil
    local currentScore = 0
    if currentTargetId then
        currentTarget = Entity(Uuid(currentTargetId))
        if valid(currentTarget) and currentTarget.factionIndex ~= ship.factionIndex and isEnemy(currentTarget) then
            currentScore = calculateTargetValue(currentTarget)
            currentScore = currentScore + getTargetDiversityModifier(currentTarget)
            currentScore = currentScore * 1.1
        end
    end
    for _, target in pairs(candidates) do
        if valid(target) and tostring(target.factionIndex) ~= ship.factionIndex and isEnemy(target) then
            local score = calculateTargetValue(target)
            score = score + getTargetDiversityModifier(target)
            if score > bestScore then
                bestScore = score
                bestTarget = target
            end
        end
    end
    if currentTarget and currentScore > 0 then
        if bestTarget and bestScore > currentScore * 1.25 then
            if onServer() and debugCombatMessages then
                Sector():broadcastChatMessage(ship, ChatMessageType.Chatter, 
                    string.format("[SMART AI] Ship %s: SWITCHING from %s (score: %.2f) to %s (score: %.2f) - tactical advantage detected", 
                    ship.name, currentTarget.name, currentScore, bestTarget.name, bestScore))
            end
            return bestTarget
        else
            if onServer() and debugCombatMessages and bestTarget then
                Sector():broadcastChatMessage(ship, ChatMessageType.Chatter, 
                    string.format("[SMART AI] Ship %s: MAINTAINING target %s (score: %.2f) - no better options (best alternative: %.2f)", 
                    ship.name, currentTarget.name, currentScore, bestScore))
            end
            return currentTarget
        end
    end
    if bestTarget then
        if onServer() and debugCombatMessages then
            Sector():broadcastChatMessage(ship, ChatMessageType.Chatter, 
                string.format("[SMART AI] Ship %s: NEW TARGET assigned: %s (score: %.2f)", 
                ship.name, bestTarget.name, bestScore))
        end
    end
    return bestTarget
end
local _fighterWeaponCache = {}
local _fighterWeaponCacheAge = 0
local _fighterWeaponCacheMaxAge = 2.0 -- Cache for 2 seconds (weapons don't change often)
function CombatUtils.analyzeFighterWeaponCapabilities(shipIndex, squadIndex)
    local currentTime = os.clock()
    local cacheKey = tostring(shipIndex) .. ":" .. tostring(squadIndex)
    if _fighterWeaponCache[cacheKey] and (currentTime - _fighterWeaponCacheAge) < _fighterWeaponCacheMaxAge then
        return _fighterWeaponCache[cacheKey]
    end
    local ship = Entity(Uuid(shipIndex))
    if not valid(ship) then return nil end
    local hangar = Hangar(ship.id)
    if not hangar then return nil end
    local fighter = hangar:getBlueprint(squadIndex)
    if not fighter then return nil end
    local analysis = {
        isShieldSpecialist = false,
        isHullSpecialist = false,
        isBalanced = false,
        shieldDamageMultiplier = 1.0,
        hullDamageMultiplier = 1.0,
        damageType = fighter.damageType or DamageType.Physical,
        shieldPenetration = fighter.shieldPenetration or 0.0,
        dps = fighter.dps or 0.0
    }
    if fighter.shieldDamageMultiplier then
        analysis.shieldDurabilityDamageMultiplier = fighter.shieldDamageMultiplier
    end
    if fighter.hullDamageMultiplier then
        analysis.hullDamageMultiplier = fighter.hullDamageMultiplier
    end
    local shieldAdvantage = analysis.shieldDurabilityDamageMultiplier - 1.0
    local hullAdvantage = analysis.hullDamageMultiplier - 1.0
    if shieldAdvantage > 0.5 and shieldAdvantage > hullAdvantage then
        analysis.isShieldSpecialist = true
    elseif hullAdvantage > 0.5 and hullAdvantage > shieldAdvantage then
        analysis.isHullSpecialist = true
    else
        analysis.isBalanced = true
    end
    if analysis.damageType == DamageType.Plasma then
        analysis.isShieldSpecialist = true
        analysis.shieldDurabilityDamageMultiplier = math.max(analysis.shieldDurabilityDamageMultiplier, 2.0)
    elseif analysis.damageType == DamageType.Energy then
        analysis.isShieldSpecialist = true
        analysis.shieldDurabilityDamageMultiplier = math.max(analysis.shieldDurabilityDamageMultiplier, 1.5)
    elseif analysis.damageType == DamageType.AntiMatter then
        analysis.isHullSpecialist = true
        analysis.hullDamageMultiplier = math.max(analysis.hullDamageMultiplier, 2.0)
    elseif analysis.damageType == DamageType.Electric then
        analysis.isBalanced = true
    elseif analysis.damageType == DamageType.Physical then
        analysis.isBalanced = true
    end
    _fighterWeaponCache[cacheKey] = analysis
    _fighterWeaponCacheAge = currentTime
    return analysis
end
function CombatUtils.invalidateFighterWeaponCache()
    _fighterWeaponCache = {}
    _fighterWeaponCacheAge = 0
end
function CombatUtils.getBestHostileTargetForSquad(shipIndex, squadIndex, currentTargetId, analyzeFighterWeaponCapabilities, getBestHostileTargetForShip, combatAssignedTargets, targetDiversityCache, targetDiversityCacheAge, targetDiversityCacheMaxAge, debugCombatMessages)
    local ship = Entity(Uuid(shipIndex))
    if not valid(ship) then return nil end
    local ai = ShipAI(ship.index)
    if not ai then return nil end
    local fighterAnalysis = analyzeFighterWeaponCapabilities(shipIndex, squadIndex)
    if not fighterAnalysis then
        return getBestHostileTargetForShip(shipIndex, currentTargetId, combatAssignedTargets, targetDiversityCache, targetDiversityCacheAge, targetDiversityCacheMaxAge, debugCombatMessages)
    end
    local function isEnemy(target)
        if not valid(target) then return false end
        if tostring(target.factionIndex) == ship.factionIndex then return false end
        local ok, res = pcall(function() return ai:isEnemy(target) end)
        if not ok then 
            local fallbackResult = tostring(target.factionIndex) ~= ship.factionIndex and tostring(target.factionIndex) ~= 0
            if target.type == EntityType.Station and onServer() then
                local targetName = target.name or "Unknown"
                print(string.format("[FOREMAN DEBUG] Station %s (faction %d) AI enemy check failed, using fallback: %s",
                    targetName, tostring(target.factionIndex), tostring(fallbackResult)))
            end
            return fallbackResult
        end
        return res
    end
    local function hullFrac(entity)
        if not valid(entity) then return 1 end
        local d = Durability(entity)
        if d and d.durability and d.maximum and d.maximum > 0 then
            return math.max(0, math.min(1, d.durability / d.maximum))
        end
        return 1
    end
    local function shieldFrac(entity)
        if not valid(entity) then return 1 end
        if entity.shieldDurability and entity.shieldMaxDurability and entity.shieldMaxDurability > 0 then
            return math.max(0, math.min(1, entity.shieldDurability / entity.shieldMaxDurability))
        end
        return 1
    end
    local function calculateTargetValue(target)
        if not valid(target) then return 0 end
        local hp = hullFrac(target)
        local shield = shieldFrac(target)
        local distance = distance2(target.translationf, ship.translationf)
        local baseValue = 1.0
		if target.type == EntityType.Ship then
            local size = target.volume or 1
            if size > 1000 then
                baseValue = 2.0  -- Capital ships
            elseif size > 100 then
                baseValue = 1.5  -- Medium ships
            end
		elseif target.type == EntityType.Station then
			baseValue = 0.5  -- Stations low priority
        end
        local specializationScore = 0
        if fighterAnalysis.isShieldSpecialist then
            if shield > 0.7 then
                specializationScore = 3.0  -- Heavily shielded - perfect target
            elseif shield > 0.4 then
                specializationScore = 1.5  -- Moderately shielded - good target
            elseif shield > 0.1 then
                specializationScore = 0.5  -- Lightly shielded - okay target
            else
                specializationScore = -1.0  -- No shields - waste of specialization
            end
        elseif fighterAnalysis.isHullSpecialist then
            if hp < 0.3 then
                specializationScore = 3.0  -- Nearly dead - perfect target
            elseif hp < 0.6 then
                specializationScore = 1.5  -- Damaged - good target
            elseif hp < 0.8 then
                specializationScore = 0.5  -- Lightly damaged - okay target
            else
                specializationScore = -0.5  -- Full health - less efficient
            end
        else
            specializationScore = (1.0 - hp) * 0.5
        end
        local distancePenalty = math.min(0.5, distance / 20000)
        local finalScore = (baseValue + specializationScore) * (1.0 - distancePenalty)
        local randomization = math.random() * 0.1  -- 0-0.1 random bonus
        local squadBias = (squadIndex % 3) * 0.05  -- Different bias per squad (0, 0.05, 0.1)
        finalScore = finalScore + randomization + squadBias
        return finalScore
    end
	local ships = getCachedEntitiesByType(EntityType.Ship)
	local stations = getCachedEntitiesByType(EntityType.Station)
	local candidates = {}
	for _, target in ipairs(ships) do
		table.insert(candidates, target)
	end
	for _, target in ipairs(stations) do
		table.insert(candidates, target)
	end
    local bestTarget = nil
    local bestScore = 0
    local currentTarget = nil
    local currentScore = 0
    if currentTargetId then
        currentTarget = Entity(Uuid(currentTargetId))
        if valid(currentTarget) and currentTarget.factionIndex ~= ship.factionIndex and isEnemy(currentTarget) then
            currentScore = calculateTargetValue(currentTarget)
            currentScore = currentScore * 1.2
        end
    end
    for _, target in pairs(candidates) do
        if valid(target) and tostring(target.factionIndex) ~= ship.factionIndex and isEnemy(target) then
            local score = calculateTargetValue(target)
            if score > bestScore then
                bestScore = score
                bestTarget = target
            end
        end
    end
    if currentTarget and currentScore > 0 then
        if bestTarget and bestScore > currentScore * 1.2 then
            return bestTarget
        else
            return currentTarget
        end
    end
    return bestTarget
end
local _globalCombatContext = nil
local _globalCombatContextAge = 0
local _globalCombatContextMaxAge = 0.5 -- Cache for 0.5 seconds
function CombatUtils.buildGlobalCombatContext()
    local currentTime = os.clock()
    if _globalCombatContext and (currentTime - _globalCombatContextAge) < _globalCombatContextMaxAge then
        return _globalCombatContext
    end
    local entityTypes = {EntityType.Ship, EntityType.Station, EntityType.Fighter}
    local cachedEntities = getCachedEntitiesByTypes(entityTypes)
    local candidates = {}
    for _, entityType in pairs(entityTypes) do
        for _, entity in pairs(cachedEntities[entityType]) do
            if valid(entity) then
                table.insert(candidates, entity)
            end
        end
    end
    _globalCombatContext = { candidates = candidates, metricCache = {} }
    _globalCombatContextAge = currentTime
    return _globalCombatContext
end
function CombatUtils.buildCombatContextForShip(ship)
    local ai = ShipAI(ship.index)
    if not ai then return nil end
    local globalCtx = CombatUtils.buildGlobalCombatContext()
    if not globalCtx then return nil end
    return { ship = ship, ai = ai, candidates = globalCtx.candidates, metricCache = globalCtx.metricCache }
end
function CombatUtils.selectBestHostileTarget(ctx, currentTargetId)
    local ship = ctx.ship
    local ai = ctx.ai
    local function cacheFor(entity)
        local key = tostring(entity.index)
        local cached = ctx.metricCache[key]
        if cached then return cached end
        local d = Durability(entity)
        local s = Shield(entity)
        local hp = 1
        if d and d.maximum and d.maximum > 0 then
            hp = math.max(0, math.min(1, d.durability / d.maximum))
        end
        local shield = 1
        if s and s.maximum and s.maximum > 0 then
            shield = math.max(0, math.min(1, s.shieldDurability / s.maximum))
        end
        cached = { hp = hp, shield = shield }
        ctx.metricCache[key] = cached
        return cached
    end
    local function isEnemy(target)
        if not valid(target) then return false end
        if tostring(target.factionIndex) == ship.factionIndex then return false end
        local ok, res = pcall(function() return ai:isEnemy(target) end)
        if not ok then 
            local fallbackResult = tostring(target.factionIndex) ~= ship.factionIndex and tostring(target.factionIndex) ~= 0
            if target.type == EntityType.Station and onServer() then
                local targetName = target.name or "Unknown"
                print(string.format("[FOREMAN DEBUG] Station %s (faction %d) AI enemy check failed, using fallback: %s",
                    targetName, tostring(target.factionIndex), tostring(fallbackResult)))
            end
            return fallbackResult
        end
        return res
    end
    local candidates = ctx.candidates
    if currentTargetId then
        local current = Entity(Uuid(currentTargetId))
        if valid(current) and current.factionIndex ~= ship.factionIndex and isEnemy(current) then
            local curC = cacheFor(current)
            if curC.hp < 0.3 then
                local bestForSwitch = nil
                local bestSwitchScore = 0
                for _, target in pairs(candidates) do
                    if valid(target) and tostring(target.factionIndex) ~= ship.factionIndex and isEnemy(target) then
                        local tc = cacheFor(target)
                        local hpAdvantage = (curC.hp - tc.hp) * 2.0
                        local shieldAdvantage = 0
                        if math.abs(curC.hp - tc.hp) < 0.2 then
                            shieldAdvantage = (cacheFor(current).shield - tc.shield) * 1.5
                        end
                        local switchScore = hpAdvantage + shieldAdvantage
                        if switchScore > 0.5 and tc.hp < curC.hp * 0.5 then
                            if switchScore > bestSwitchScore then
                                bestSwitchScore = switchScore
                                bestForSwitch = target
                            end
                        end
                    end
                end
                if bestForSwitch then
                    local bestHp = cacheFor(bestForSwitch).hp
                    if bestHp > curC.hp then
                        return current
                    end
                    return bestForSwitch
                else
                    return current
                end
            end
        end
    end
    local best
    local bestScore = -math.huge
    local curHp
    if currentTargetId then
        local current = Entity(Uuid(currentTargetId))
        if valid(current) then curHp = cacheFor(current).hp end
    end
    for _, target in pairs(candidates) do
        if valid(target) and tostring(target.factionIndex) ~= ship.factionIndex and isEnemy(target) then
            local tc = cacheFor(target)
            if curHp and tc.hp > curHp then
                goto continue_target_loop_ctx
            end
            local score = (1.0 - tc.hp) * 3.0
            if tc.hp > 0.9 then
                score = score + (1.0 - tc.shield) * 2.0
            end
            if score > bestScore then
                best = target
                bestScore = score
            end
            ::continue_target_loop_ctx::
        end
    end
    if best and curHp then
        local bestHp = cacheFor(best).hp
        if bestHp > curHp then
            return Entity(Uuid(currentTargetId))
        end
    end
    return best
end
function CombatUtils.invalidateGlobalCombatContext()
    _globalCombatContext = nil
end
return CombatUtils
