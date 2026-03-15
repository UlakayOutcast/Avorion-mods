local autoturrets

local ticks = 0
local maxTicks = 1000000

function initialize()
    local entity = Entity()
    entity:registerCallback("onTurretAdded", "addTurret")
    entity:registerCallback("onTurretDestroyed", "updateTurrets")
    entity:registerCallback("onTurretRemoved", "updateTurrets")
    entity:registerCallback("onTurretRemovedByPlayer", "updateTurrets")
end

function addTurret(shipId, turretIndex)
    if autoturrets == nil then autoturrets = {} end
    local turret = Entity(turretIndex)
    if turret then
        local weapons = Weapons(turret)
        table.insert(autoturrets, {turret = Turret(turret), tAI = TurretAI(turret), weapons = weapons})
    end
end

function updateTurrets()
    autoturrets = {}
    for _, t in pairs({Entity():getTurrets()}) do
        local weapons = Weapons(t)
        table.insert(autoturrets, {turret = Turret(t), tAI = TurretAI(t), weapons = weapons})
    end
end

function getUpdateInterval()
    return 0.02
end


function updateServer(tick)
    --Updates turrets every ~10s
    if ticks % 500 == 0 then updateTurrets() end
    ticks = ticks + 1
    if ticks >= maxTicks then ticks = 0 end

    local cached = autoturrets
    if cached == nil then return end
    for _, turret_tuple in pairs(cached) do
        local turret = turret_tuple.turret
        local weapons = turret_tuple.weapons
        if turret == nil then return end
        if valid(turret) then
            local tAI = turret_tuple.tAI
            if tAI.targetedEntity ~= nil then
				if not turret.weaponsPlayerControlled then
					local target = Entity(tAI.targetedEntity)
					if valid(target) and target.isShip and weapons.shieldRepairRate == 0 and weapons.hullRepairRate == 0 then
						local entity = Entity()
                        local entityPos = entity.position.position
						local targetPos = target.position.position
						
						--test for block targeting which does not work
						--print("TargetPos"..targetPos.x.." "..targetPos.y.." "..targetPos.z)
						--local targetPlan = target.getFullPlanCopy(target)
						--local targetedBlock = targetPlan.getNthBlock(targetPlan, ticks % targetPlan.numBlocks)
						--targetPos = addV(targetPos, targetedBlock.orientation.position)
						--print("BlockPos"..targetedBlock.orientation.position.x.." "..targetedBlock.orientation.position.y.." "..targetedBlock.orientation.position.z)
						
						local relativePos = subV(targetPos, entityPos)

						local entityVelocity = Velocity(entity.id).velocity
						local targetVelocity = Velocity(target.id).velocity
						local relativeVelocity = subV(targetVelocity, entityVelocity)

						--disable if target is too fast
                        if length(relativeVelocity) > weapons.shotSpeed then return end
						--disable if target is too close based on target size and speed
						if length(targetVelocity) < 2000 and length(relativePos) / highestValue(target.size) < 5 then return end

						--set wiggle radius to 80% of target size or the maxium wiggle radius for the turret to continiously fire
						local targetRadius = 0.4 * lowestValue(target.size)
						local turretMaxTurnRadius = (1.125 * turret.turningSpeed * 3.14159 * length(relativePos)) / 180
						targetRadius = math.min(targetRadius, turretMaxTurnRadius)
						
						
						if weapons.shotSpeed == math.huge then
							tAI.aimedPosition = addRandomSpray(vec3(targetPos.x, targetPos.y, targetPos.z), targetRadius)
						else
							local a = dotV(relativeVelocity, relativeVelocity) - weapons.shotSpeed * weapons.shotSpeed
							local b = 2 * dotV(relativeVelocity, relativePos)
							local c = dotV(relativePos, relativePos)

							local p = -b / (2 * a)
							local q = math.sqrt((b * b) - 4 * a * c) / (2 * a)

							local t1 = p - q
							local t2 = p + q
							local travelTime
							if t1 > t2 and t2 > 0 then
								travelTime = t2
							else
								travelTime = t1
							end
							if travelTime < 0 then return end

							local relativePosWhenHit = addV(relativePos, mulV(relativeVelocity, travelTime))
							local aimAt = addRandomSpray(addV(relativePosWhenHit, entityPos), targetRadius)
							tAI.aimedPosition = vec3(aimAt.x, aimAt.y, aimAt.z)
                        end
					end
                end
            end
        end
    end
end

function length(vector)
    return math.sqrt(vector.x * vector.x + vector.y * vector.y + vector.z * vector.z)
end

function addV(vector1, vector2)
    return vec3(vector1.x + vector2.x, vector1.y + vector2.y, vector1.z + vector2.z)
end

function subV(vector1, vector2)
    return vec3(vector1.x - vector2.x, vector1.y - vector2.y, vector1.z - vector2.z)
end

function mulV(vector, value)
    return vec3(vector.x * value, vector.y * value, vector.z * value)
end

function dotV(vector1, vector2)
    return vector1.x * vector2.x + vector1.y * vector2.y + vector1.z * vector2.z
end

function lowestValue(vector)
	return math.min(vector.x, vector.y, vector.z)
end

function highestValue(vector)
	return math.max(vector.x, vector.y, vector.z)
end

function addRandomSpray(vector, radius)
	return vec3(vector.x + (math.random() - 0.5) * radius * 2, vector.y + (math.random() - 0.5) * radius * 2, vector.z + (math.random() - 0.5) * radius * 2)
end