package.path = package.path .. ";data/scripts/lib/?.lua"
package.path = package.path .. ";data/scripts/?.lua"

include ("randomext")

-- Don't remove or alter the following comment, it tells the game the namespace this script lives in. If you remove it, the script will break.
-- namespace Oppressor
Oppressor = {}
local self = Oppressor

self._Debug = 0

self.data = {}

local laser = nil

self.laserData = {}
self.laserData.from = nil
self.laserData.to = nil

function Oppressor.initialize(values)
    local _MethodName = "Initialize"
    self.Log(_MethodName, "Adding v29 of Oppressor.lua to entity.")

    self.data = values or {}

    if onServer() then
        if not _restoring then
            --[ADJUSTABLE VALUES]
            --Damage multiplier
            self.data.multiplier = self.data.multiplier or 1.25
            self.data.adder = self.data.adder or 0.5 --This seems like a lot, but we're already at 60 ticks of an exponential 1.25 buff.
            self.data.maxTicks = self.data.maxTicks or 60
            self.data.tickCycle = self.data.tickCycle or 30
        
            --Hook variables
            self.data.hookPower = self.data.hookPower or 15
            self.data.hookPullDuration = self.data.hookPullDuration or 10
            self.data.hookCycle = self.data.hookCycle or 20
            self.data.hookOffset = self.data.hookOffset or 0
            --No target priority here - we'll always be picking a random enemy.
        
            --Wreckage variables
            self.data.eatWrecksCycle = self.data.eatWrecksCycle or 10
        
            --[UNADJUSTABLE VALUES]
            --Can't be adjusted via the script.
            self.data.eatWrecksTimer = 0
            self.data.tickTimer = 0
            self.data.ticks = 0
        
            --Hook variables
            self.data.currentHookTarget = nil
            self.data.hookFireCycle = 0
            self.data.hookOffsetCycle = 0
            self.data.hookPullTime = 0
        end

        --register callbacks
        Entity():registerCallback("onDestroyed", "onDestroyed")
    end
end

function Oppressor.getUpdateInterval()
    return 0 --Update every frame.
end

function Oppressor.update(timeStep)
    local methodName = "Update"
    self.updateHookLaser()

    if onServer() then
        local _entity = Entity()

        --Handle damage buff first.
        self.data.tickTimer = (self.data.tickTimer or 0) + timeStep

        if self.data.tickTimer >= self.data.tickCycle then
            self.oppressorBuff()
            self.data.tickTimer = 0
        end

        --Eat nearby wreckages next.
        self.data.eatWrecksTimer = (self.data.eatWrecksTimer or 0) + timeStep
        if self.data.eatWrecksTimer >= self.data.eatWrecksCycle then
            self.eatWreckages(false)
            self.data.eatWrecksTimer = 0
        end

        --if there are no enemies, abort.
        if _entity:getValue("is_xsotan") then
            local myAI = ShipAI()
            if not myAI:isEnemyPresent(true) then
                return
            end
        end

        --next, handle laser
        self.data.hookOffsetCycle = (self.data.hookOffsetCycle or 0) + timeStep
        if self.data.hookOffsetCycle < self.data.hookOffset then
            return
        end

        if not self.data.currentHookTarget or not valid(self.data.currentHookTarget) then
            self.data.currentHookTarget = self.pickHookTarget()
            self.data.hookFireCycle = 0
        else
            self.data.hookFireCycle = (self.data.hookFireCycle or 0) + timeStep
            --self.Log(methodName, "timeStep is : " .. tostring(timeStep) .. " Hook fire cycle is : " .. tostring(self.data.hookFireCycle))

            if self.data.hookFireCycle >= self.data.hookCycle then
                self.Log(methodName, "Firing pull laser.")
                self.createHookLaser(15, _entity.translationf, self.data.currentHookTarget.translationf)

                self.data.hookActive = true
                self.data.hookActiveTime = 0
                self.data.hookFireCycle = 0
                --self.Log(methodName, "Target position is : " .. tostring(self.data.currentHookTarget.translationf))
            end

            if self.data.hookActive then
                self.data.hookActiveTime = (self.data.hookActiveTime or 0) + timeStep
                self.repositionTarget()
                if self.data.hookActiveTime >= self.data.hookPullDuration then
                    self.Log(methodName, "Hook active time is " .. tostring(self.data.hookActiveTime) .. " pull duration is " .. tostring(self.data.hookPullDuration))
                    self.data.hookActive = false
                    self.deleteCurrentLasers()
                    --self.Log(methodName, "Target position is: " .. tostring(self.data.currentHookTarget.translationf))
                end
            end
        end
    end
end

--region #DAMAGE BUFF functions

--region #SERVER only

function Oppressor.oppressorBuff()
    local _MethodName = "OppressorBuff"

    local _DamageMultiplier = (Entity().damageMultiplier or 1)

    if self.data.ticks <= self.data.maxTicks then
        _DamageMultiplier = _DamageMultiplier * self.data.multiplier
    else
        --Go additive after a while.
        _DamageMultiplier = _DamageMultiplier + self.data.adder
    end
    self.data.ticks = self.data.ticks + 1

    Entity().damageMultiplier = _DamageMultiplier

    self.Log(_MethodName, "Damage multiplier is now " .. tostring(_DamageMultiplier))

    broadcastInvokeClientFunction("animation")
end

function Oppressor.eatWreckages(fullPower)
    local methodName = "Eat Wreckages"
    self.Log(methodName, "Consuming")

    local _entity = Entity()
    local _sector = Sector()

    local sphere = _entity:getBoundingSphere()

    local radMultiplier = 4
    local blockDenominator = 30
    if fullPower then
        radMultiplier = 8
        blockDenominator = 25
    end

    local consumeSphere = Sphere(sphere.center, sphere.radius * radMultiplier) 
    local consumeCandidates = {Sector():getEntitiesByLocation(consumeSphere)}

    local consumedBuffIncrement = 0

    for _, consume in pairs(consumeCandidates) do
        if consume.type == EntityType.Wreckage then
            self.Log(methodName, "Found consume candidate")
            --Show jump animation
            broadcastInvokeClientFunction("consumeAnimation", consume.index, 5)

            --Create laser
            self.createConsumeLaser(_entity.translationf, consume.translationf)

            --Get the plan.
            local consumedPlan = consume:getMovePlan()
            --Increase by 1% per 25 blocks (1% per 30 blocks at reduced power)
            consumedBuffIncrement = consumedBuffIncrement + math.floor(consumedPlan.numBlocks / blockDenominator) 

            --finally, delete the entity
            _sector:deleteEntity(consume)
        end
    end

    --Once we've eaten all the plans, dmg buff the entity
    local damageMultiplier = (_entity.damageMultiplier or 1)
    local newDamageMultiplier = damageMultiplier * (1 + (consumedBuffIncrement * 0.01))

    self.Log(methodName, "Block increment is " .. tostring(consumedBuffIncrement) .. " New damage multiplier is " .. tostring(newDamageMultiplier))

    _entity.damageMultiplier = newDamageMultiplier

    broadcastInvokeClientFunction("animation")

    --Heal the entity by twice the % of buff.
    local healPct = consumedBuffIncrement * 0.02
    if _entity.durability < _entity.maxDurability then
        local healAmt = _entity.maxDurability * healPct
        if _entity.durability + healAmt > _entity.maxDurability then
            healAmt = _entity.maxDurability - _entity.durability
        end

        _entity.durability = _entity.durability + healAmt
    end
end

--endregion

--region #CLIENT only

function Oppressor.animation()
    local _sector = Sector()
    local _entity = Entity()
    local _random = random()

    local dirs = { _random:getDirection(), _random:getDirection(), _random:getDirection() }
    for _, dir in pairs(dirs) do
        _sector:createHyperspaceJumpAnimation(_entity, dir, ColorRGB(1.0, 0.0, 0.0), 0.3)
    end
end

function Oppressor.consumeAnimation(idx, anims)
    local _Sector = Sector()

    local _entity = Entity(idx)
    local _random = random()
    for _ = 1, anims do
        local dir = _random:getDirection()
        _Sector:createHyperspaceJumpAnimation(_entity, dir, ColorRGB(0.5, 0.5, 1.0), 0.3)
    end
end

function Oppressor.createConsumeLaser(from, to)
    if onServer() then
        broadcastInvokeClientFunction("createConsumeLaser", from, to)
        return
    end

    local _Color = ColorRGB(0.8, 0.0, 0.8)

    local _Sector = Sector()
    local _Laser = _Sector:createLaser(from, to, _Color, 16)

    _Laser.maxAliveTime = 1.0
    _Laser.collision = false
end

--endregion

--endregion

--region #MEATHOOK functions

--region #SERVER only

function Oppressor.onDestroyed()
    Oppressor.deleteCurrentLasers()
end

function Oppressor.pickHookTarget()
    local methodName = "Pick New Hook Target"

    local _sector = Sector()
    local _entity = Entity()
    --Get all xsotan minion entities.
    local oppressorPriorityTags = {
        "xsotan_summoner_minion",
        "xsotan_master_summoner_minion", --We're unlikely to see these, but hey! you never know.
        "xsotan_revenant"
    }

    local targetCandidates = {}

    for _, tag in pairs(oppressorPriorityTags) do
        local priorityEntities = { _sector:getEntitiesByScriptValue(tag) }
        for _, priorityEntity in pairs(priorityEntities) do
            table.insert(targetCandidates, priorityEntity)
        end
    end

    --If there are xsotan minion entities, prioritize those - otherwise we start eating normal xsotan
    if #targetCandidates == 0 then
        local xsotanEntities = { _sector:getEntitiesByScriptValue("is_xsotan") }
        for _, xsotan in pairs(xsotanEntities) do
            --Don't eat summoner xsotans.
            if xsotan.index ~= _entity.index and self.targetTagCheck(xsotan) then
                table.insert(targetCandidates, xsotan)
            end
        end
    end

    if #targetCandidates > 0 then
        self.Log(methodName, "Found at least one suitable candidate. Picking a random one.")
        return randomEntry(targetCandidates)
    else
        self.Log(methodName, "WARNING - Could not find any target candidates.")
        return nil
    end    
end

function Oppressor.targetTagCheck(entity)
    local forbiddenTags = self.getForbiddenTags()

    for _, tag in pairs(forbiddenTags) do
        if entity:getValue(tag) then
            return false
        end
    end

    return true
end

--[[
    Added for moddability! If you add a special Xsotan type and you don't want it to get eaten, you can modify this list by doing the following:

    local YourModName_getForbiddenTags = Oppressor.getForbiddenTags()
    function Oppressor.getForbiddenTags()
        local tags = YourModName_getForbiddenTags()

        table.insert(tags, "xsotan_YourXsotanType")

        return tags
    end
]]
function Oppressor.getForbiddenTags()
    return {
        "xsotan_warlock",
        "xsotan_summoner",
        "xsotan_parthenope",
        "xsotan_dreadnought"
    }
end

function Oppressor.repositionTarget()
    local methodName = "Reposition Target"
    
    local _entity = Entity()
    local myPosition = _entity.translationf
    local enemyPosition = self.data.currentHookTarget.translationf

    local radius = _entity:getBoundingSphere().radius
    local distanceToTarget = distance(myPosition, enemyPosition)
    local minPullDistance = radius * 2
    local minConsumeDistance = radius * 3

    if distanceToTarget > minPullDistance then
        local diffPosition = enemyPosition - myPosition
        local normalizedDiff = normalize(diffPosition)
        local shift = normalizedDiff * self.data.hookPower

        local targetPosition = self.data.currentHookTarget.position
        targetPosition.translation = targetPosition.translation - shift
        self.data.currentHookTarget.position = targetPosition

        local targetVelocity = Velocity(self.data.currentHookTarget.index)
        local normalizedVelocity = normalize(targetVelocity.velocity)
        targetVelocity.velocity = (targetVelocity.velocity - normalizedVelocity * 2)
    end

    if distanceToTarget < minConsumeDistance then --Eat it :)
        if (self.data.eatWrecksTimer or 0) <= 2 then --Bump this up a bit so we don't accidentally eat the wreck at reduced power.
            self.data.eatWrecksTimer = 2
        end

        self.Log(methodName, "Killing repositioning target. Turning off hook and eating.")
        self.data.currentHookTarget:destroy(_entity.index, 1, DamageType.Energy)
        self.data.hookActive = false
        self.deleteCurrentLasers()
        self.eatWreckages(true)
    end
end

--endregion

--region #CLIENT / SERVER

function Oppressor.createHookLaser(width, from, to)
    local methodName = "Create Laser"

    if onServer() then
        --self.Log(methodName, "Calling on Server => Invoking on Client")
        broadcastInvokeClientFunction("createHookLaser", width, from, to)
        return
    else
        --self.Log(methodName, "Calling on Client - values are: width : " .. tostring(width) .. " from : " ..tostring(from) .. " to : " .. tostring(to))
    end

    local laserColor = ColorRGB(0.0, 0.6, 1.0)
    laser = Sector():createLaser(vec3(), vec3(), laserColor, width or 1)
    laser.from = from
    laser.to = to
    laser.collision = false

    self.Log(methodName, "Making laser from : " .. tostring(from) .. " to : " .. tostring(to))
    if not laser then
        self.Log("WARNING! Laser is nil")
    end

    laser.maxAliveTime = 1.5
end

function Oppressor.updateHookLaser()
    local methodName = "Update Laser"

    if onServer() then
        --self.Log(methodName, "Called on server.") --CAREFUL WHEN ENABLING THIS - SPAM
        if not self.data.hookActive or not self.data.currentHookTarget then
            return
        end

        local _entity = Entity()
        local target = self.data.currentHookTarget

        local from = _entity.translationf
        local to = target.translationf

        self.laserData.from = from
        self.laserData.to = to

        --self.Log(methodName, "sending from = " .. tostring(self.laserData.from) .. " to " .. tostring(self.laserData.to)) --CAREFUL WHEN ENABLING THIS - SPAM
        self.syncLaserData()
    else --onClient()
        --self.Log(methodName, "Called on client.") --CAREFUL WHEN ENABLING THIS - SPAM
        if not laser or not valid(laser) or not self.laserData.from or not self.laserData.to then
            return
        end

        --self.Log(methodName, "Setting laser from / to / aliveTime") --CAREFUL WHEN ENABLING THIS - SPAM
        laser.from = self.laserData.from
        laser.to = self.laserData.to
        laser.aliveTime = 0
    end
end

function Oppressor.deleteCurrentLasers()
    local methodName = "Delete Current Lasers"
    if onServer() then
        self.Log(methodName, "Calling on Server => Invoking on Client")
        broadcastInvokeClientFunction("deleteCurrentLasers")
        return
    else
        self.Log(methodName, "Calling on Client")
    end

    if valid(laser) then 
        Sector():removeLaser(laser) 
    end
end

function Oppressor.syncLaserData(dataIn)
    if onServer() then
        broadcastInvokeClientFunction("syncLaserData", self.laserData)
    else
        if dataIn then
            self.laserData = dataIn
        else
            invokeServerFunction("syncLaserData")
        end
    end
end
callable(Oppressor, "syncLaserData")

--endregion

--endregion

--region #LOG / SECURE / RESTORE

function Oppressor.Log(methodName, msg)
    if self._Debug == 1 then
        print("[Oppressor] - [" .. tostring(methodName) .. "] - " .. tostring(msg))
    end
end

function Oppressor.secure()
    local _MethodName = "Secure"
    self.Log(_MethodName, "Securing self.data")
    return self.data
end

function Oppressor.restore(_Values)
    local _MethodName = "Restore"
    self.Log(_MethodName, "Restoring self.data")
    self.data = _Values
end

--endregion