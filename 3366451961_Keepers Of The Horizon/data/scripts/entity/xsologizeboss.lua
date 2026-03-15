package.path = package.path .. ";data/scripts/lib/?.lua"
package.path = package.path .. ";data/scripts/?.lua"

include ("randomext")
include("defaultscripts")
include("callable")

ESCCUtil = include("esccutil")

local pirateGenerator = include("pirategenerator")
local Xsotan = include("story/xsotan")
local shipUtility = include("shiputility")

--Blah blah, don't remove, blah blah, you'll break the script, etc.
-- namespace XsologizeBossHierophant
XsologizeBossHierophant = {}
local self = XsologizeBossHierophant

self._Debug = 0

self._Data = {}
self.lasers = {}

local lasers = self.lasers
local explosionCounter = 0 --Used clientside - we do not want this overwrriten on sync.

function XsologizeBossHierophant.initialize(_Values)
    local methodName = "Initialize"
    self.Log(methodName, "Adding v10 of XsologizeBoss.lua to entity.")

    self._Data = _Values or {}

    self._Data._Timer = 0
    self._Data._JumpTimer = 0
    self._Data._StunnedTimer = 0
    self._Data._IsStunned = false
    self._Data._SinnerMode = true

    self._Data._CanSpawnPirates = true
    self._Data._SinnerLimit = 10
    self._Data._RevenantLimit = 10
    self._Data._SinnerSpawnLimit = 6
    self._Data._RevenantSpawnLimit = 6
    self._Data._JumpInterval = 7
    self._Data._StunnedInterval = 5
    self._Data._PirateInterval = 55
    self._Data._SinnerInterval = 65
    self._Data._RevenantInterval = 30
    self._Data._MaximumVolumeFactorToRevive = 150

    if onServer() then
        Entity():registerCallback("onDamaged", "onDamaged")
        Entity():registerCallback("onShieldDamaged", "onShieldDamaged")
    end
end

--Client / Server - we can update every second on the server but we want to update every frame on client.
if onServer() then
    
function XsologizeBossHierophant.getUpdateInterval()
    return 1
end

else

function XsologizeBossHierophant.getUpdateInterval()
    return 0
end
    
end

--region #SERVER functions

function XsologizeBossHierophant.updateServer(timeStep)
    local methodName = "Update Server"
    self._Data._Timer = self._Data._Timer + timeStep --Count up to 65 / 30
    --Manage jump timer
    if self._Data._StunnedTimer <= 0 then
        self._Data._JumpTimer = self._Data._JumpTimer - timeStep --Count down to 0. Don't allow decrement if stunned.
    end
    --Manage stunned timer
    self._Data._StunnedTimer = self._Data._StunnedTimer - timeStep --Count down to 0
    if self._Data._StunnedTimer <= 0 and self._Data._IsStunned then
        self.Log(methodName, "No longer stunned - reporting to client")
        self._Data._IsStunned = false
        self.sync() --Need to let the client know we're not stunned anymore.
    end

    --Spawn sinners / revenants
    if self._Data._SinnerMode then
        if self._Data._Timer >= self._Data._PirateInterval and self._Data._CanSpawnPirates then
            local spawnableSinners = math.min(self.getSpawnableSinners(), self._Data._SinnerSpawnLimit)
            if spawnableSinners > 0 then
                self._Data._CanSpawnPirates = false
                self.spawnPirates(spawnableSinners)
            end
        end

        if self._Data._Timer >= self._Data._SinnerInterval then
            self.Log(methodName, "Creating sinners and setting to revenant mode")
            self.createSinners()
    
            self._Data._Timer = 0
            self._Data._CanSpawnPirates = true
            self._Data._SinnerMode = false
        end
    else
        if self._Data._Timer >= self._Data._RevenantInterval then
            self.Log(methodName, "Spawning revenants and setting to sinner mode")
            local spawnableRevenants = math.min(self.getSpawnableRevenants(), self._Data._RevenantSpawnLimit)
            if spawnableRevenants > 0 then
                self.spawnRevenants(spawnableRevenants)
            end
            self._Data._Timer = 0
            self._Data._SinnerMode = true
        end
    end
end

--region #SINNER MANAGEMENT

function XsologizeBossHierophant.getSpawnableSinners()
    return self._Data._SinnerLimit - ESCCUtil.countEntitiesByValue("is_sinner")
end

function XsologizeBossHierophant.spawnPirates(amount)
    local xsologize = Entity()
    local pos = xsologize.translationf
    local radius = xsologize.radius

    local piratesToSpawn = ESCCUtil.getStandardWave(10, amount, "Standard", false)

    for idx = 1, amount do
        local dir = random():getDirection()
        local piratePosition = pos + dir * radius * random():getFloat(5, 10)

        broadcastInvokeClientFunction("animation", piratePosition)

        local matrix = MatrixLookUpPosition(xsologize.look, xsologize.up, piratePosition)
        local pirate = pirateGenerator.createScaledPirateByName(piratesToSpawn[idx], matrix)

        self.createWormhole(pirate,piratePosition)
    end
end

function XsologizeBossHierophant.createWormhole(pirate, position)
    -- spawn a wormhole
    local desc = WormholeDescriptor()
    desc:removeComponent(ComponentType.EntityTransferrer)
    desc:addComponents(ComponentType.DeletionTimer)
    desc.position = MatrixLookUpPosition(vec3(0, 1, 0), vec3(1, 0, 0), position)

    local size = pirate.radius + random():getFloat(10, 15)
    local wormhole = desc:getComponent(ComponentType.WormHole)
    wormhole:setTargetCoordinates(random():getInt(-50, 50), random():getInt(-50, 50))
    wormhole.visible = true
    wormhole.visualSize = size
    wormhole.passageSize = math.huge
    wormhole.oneWay = true
    wormhole.simplifiedVisuals = true

    desc:addScriptOnce("data/scripts/entity/wormhole.lua")

    local wormhole = Sector():createEntity(desc)

    local timer = DeletionTimer(wormhole.index)
    timer.timeLeft = 3
end

function XsologizeBossHierophant.createSinners()
    local methodName = "Create Sinners"

    local _random = random()
    local _sector = Sector()
    local xsologize = Entity()

    local pirates = { _sector:getEntitiesByScriptValue("is_pirate") }
    local screamLines = {
        "Помогите нам! Помогите нам!",
        "АААААААААААААА!!",
        "Что происходит с нашим кораблем...?! ПОМОЩЬ!",
        "Нет! Нееееет!",
        "Боже мой! Нет! НЕЕЕЕТ-",
        "Наш корабль! Наш... что это? ЧТО-"
    }

    for idx = 1, #pirates do
        local pirate = pirates[idx]
        if not pirate:getValue("is_sinner") then
            pirate:setValue("is_sinner", true)
            broadcastInvokeClientFunction("infectAnimation", pirate.translationf)

            local piratePlan = pirate:getFullPlanCopy()
            Xsotan.infectPlan(piratePlan)
            pirate:setMovePlan(piratePlan)

            pirate:setValue("is_sinner", true)
            pirate:setValue("is_horizon", true)
            pirate.factionIndex = xsologize.factionIndex
            pirate.title = "Sinner"
            pirate:addScriptOnce("esccblinker.lua", { blinkLimit = 3 })
            pirate:setDropsLoot(false)
            
            local ai = ShipAI(pirate)
            ai:stop()
            ai:setAggressive()

            Boarding(pirate).boardable = false

            if _random:test(0.1) then
                shuffle(_random, screamLines)
                _sector:broadcastChatMessage(pirate, ChatMessageType.Chatter, screamLines[1])
            end
        end
    end
end

--endregion

--region #REVENANT MANAGEMENT

function XsologizeBossHierophant.getSpawnableRevenants()
    return self._Data._RevenantLimit - ESCCUtil.countEntitiesByValue("is_revenant")
end

function XsologizeBossHierophant.spawnRevenants(amount)
    for _ = 1, amount do
        local wreck = self.findSuitableWreck()
        if wreck then
            local revenant = self.createRevenant(wreck)
            broadcastInvokeClientFunction("infectAnimation", revenant.translationf)
        end
    end
end

function XsologizeBossHierophant.findSuitableWreck()
    --Get table of candidate wreckages
    local _sector = Sector()
    local x, y = _sector:getCoordinates()
    local _Wreckages = { _sector:getEntitiesByType(EntityType.Wreckage)}
    local maximumVolumeToRevive = Balancing_GetSectorShipVolume(x, y) * self._Data._MaximumVolumeFactorToRevive

    --Pick all candidate wrecks that are above 200 blocks.
    shuffle(random(), _Wreckages)
    local _CandidateWrecks = {}
    for _, _Wreck in pairs(_Wreckages) do
        local _Pl = Plan(_Wreck.id)
        if _Pl.numBlocks >= 200 and _Pl.volume <= maximumVolumeToRevive then
            table.insert(_CandidateWrecks, _Wreck)
        end
    end

    if #_CandidateWrecks > 0 then
        return randomEntry(_CandidateWrecks)
    else
        return
    end
end

function XsologizeBossHierophant.createRevenant(wreckage)
    local _Sector = Sector()
    --Get plan from wreckage.
    local plan = wreckage:getMovePlan()
    local _position = wreckage.position
    local faction = Faction(Entity().factionIndex)
    --Infect.
    Xsotan.infectPlan(plan)

    local ship = _Sector:createShip(faction, "", plan, _position, EntityArrivalType.Default)

    shipUtility.addRevenantArtillery(ship)

    ship.title = "Revenant"
    ship.crew = ship.idealCrew
    ship.shieldDurability = ship.shieldMaxDurability

    AddDefaultShipScripts(ship)

    ship:addScriptOnce("ai/patrol.lua")
    ship:addScriptOnce("utility/aiundockable.lua")
    ship:setValue("is_revenant", true)
    ship:setValue("is_horizon", true)

    Boarding(ship).boardable = false

    _Sector:deleteEntity(wreckage)

    return ship
end

--endregion

--region #JUMP MANAGEMENT

function XsologizeBossHierophant.onDamaged(objectIndex, amount, inflictor, damageSource, damageType)
    self.onXsologizeDamaged(damageType)
end

function XsologizeBossHierophant.onShieldDamaged(enityID, amount, damageType, inflictor)
    self.onXsologizeDamaged(damageType)
end

function XsologizeBossHierophant.onXsologizeDamaged(damageType)
    if damageType == DamageType.Electric then
        self._Data._StunnedTimer = self._Data._StunnedInterval
        self._Data._IsStunned = true
        self.sync()
    else
        if self._Data._StunnedTimer <= 0 and self._Data._JumpTimer <= 0 then
            self._Data._JumpTimer = self._Data._JumpInterval
            self.doJump()
        end
    end
end

function XsologizeBossHierophant.doJump()
    local methodName = "Do Jump"
    self.Log(methodName, "Jumping.")
    
    local entity = Entity()
    local rand = random()

    local dir = rand:getDirection()
    --if the nearest sinner is more than 15km away, jump towards the farthest sinner.
    local nearestSinner, distToNSinner = self.findNearestSinner()
    if nearestSinner then
        if distToNSinner > 1500 then
            self.Log(methodName, "Jumping towards farthest sinner.")
            local farthestSinner, distToFSinner = self.findFarthestSinner()
            dir = normalize(farthestSinner.translationf - entity.translationf)
        end
    end

    local magnitude = rand:getInt(750, 1500)

    local newPos = entity.translationf + (dir * magnitude)
    local newPosition = dvec3(newPos.x, newPos.y, newPos.z)

    broadcastInvokeClientFunction("jumpAnimation", dir, 0.6)
    entity.translation = newPosition    
end

function XsologizeBossHierophant.findNearestSinner()
    local _entity = Entity()
    local dist = math.huge
    local targetIdx = -1
    local sinners = {Sector():getEntitiesByScriptValue("is_sinner")}

    if #sinners > 0 then
        for idx, sinner in pairs(sinners) do
            local nDist = _entity:getNearestDistance(sinner)
            if nDist < dist then
                dist = nDist
                targetIdx = idx
            end
        end
    else
        return
    end

    return sinners[targetIdx], dist
end

function XsologizeBossHierophant.findFarthestSinner()
    local _entity = Entity()
    local dist = 0
    local targetIdx = -1
    local sinners = {Sector():getEntitiesByScriptValue("is_sinner")}

    if #sinners > 0 then
        for idx, sinner in pairs(sinners) do
            local nDist = _entity:getNearestDistance(sinner)
            if nDist > dist then
                dist = nDist
                targetIdx = idx
            end
        end
    else
        return
    end

    return sinners[targetIdx], dist
end

--endregion

--endregion

--region #CLIENT functions

function XsologizeBossHierophant.updateClient(timeStep)
    local entity = Entity()
    if self._Data._IsStunned then
        self.showGlowAndSparks()
    end

    for k, l in pairs(lasers) do
        if valid(l.laser) then
            l.laser.from = entity.translationf
            l.laser.to = l.to
        else
            lasers[k] = nil
        end
    end
end

--region #SINNER MANAGEMENT

function XsologizeBossHierophant.animation(minionPosition)
    local sector = Sector()

    local entity = Entity()

    local laser = sector:createLaser(entity.translationf, minionPosition, ColorRGB(0.8, 0.6, 0.1), 1.5)
    laser.maxAliveTime = 1.5
    laser.collision = false
    laser.animationSpeed = -500

    table.insert(lasers, {laser = laser, to = minionPosition})
end

--endregion

--region #REVENANT MANAGEMENT

function XsologizeBossHierophant.infectAnimation(infectionPosition)
    local _sector = Sector()
    local _entity = Entity()

    local laser = _sector:createLaser(_entity.translationf, infectionPosition, ColorRGB(0.8, 0.0, 0.8), 16)
    laser.maxAliveTime = 1.5
    laser.collision = false
    laser.animationSpeed = -500

    table.insert(lasers, {laser = laser, to = infectionPosition})
end

--endregion

--region #JUMP MANAGMENT

function XsologizeBossHierophant.showGlowAndSparks()
    --Only gets called via updateClient - no need to invoke from server => client.
    local sector = Sector()
    local entity = Entity()

    local glowColor = ColorRGB(0.2, 0.2, 0.5)

    sector:createGlow(entity.translationf, 80 + 50 * math.random(), glowColor)
    sector:createGlow(entity.translationf, 80 + 50 * math.random(), glowColor)
    sector:createGlow(entity.translationf, 80 + 50 * math.random(), glowColor)
    explosionCounter = explosionCounter + 1
    if explosionCounter == 1 then
        sector:createExplosion(entity.translationf, 8, true)
    elseif explosionCounter > 30 then
        explosionCounter = 0
    end
end

function XsologizeBossHierophant.jumpAnimation(direction, intensity)
    Sector():createHyperspaceJumpAnimation(Entity(), direction, ColorRGB(0.6, 0.5, 0.3), intensity)
end

--endregion

--endregion

--region #SERVER => EXTERNAL ADJ METHODS

function XsologizeBossHierophant.setInternalClock(time)
    self._Data._Timer = time
end

--endregion

--region #SECURE / RESTORE / LOG / SYNC CALLS

function XsologizeBossHierophant.Log(methodName, msg)
    if self._Debug == 1 then
        print("[XsologizeBossHierophant] - [" .. tostring(methodName) .. "] - " .. tostring(msg))
    end
end

function XsologizeBossHierophant.secure()
    local methodName = "Secure"
    self.Log(methodName, "Securing self._Data")
    return self._Data
end

function XsologizeBossHierophant.restore(values)
    local methodName = "Restore"
    self.Log(methodName, "Restoring self._Data")
    self._Data = values
end

function XsologizeBossHierophant.sync(dataIn)
    if onServer() then
        broadcastInvokeClientFunction("sync", self._Data)
    else
        if dataIn then
            self._Data = dataIn
        else
            invokeServerFunction("sync")
        end
    end
end
callable(XsologizeBossHierophant, "sync")

--endregion