package.path = package.path .. ";data/scripts/lib/?.lua"
package.path = package.path .. ";data/scripts/?.lua"

include("randomext")
include ("stringutility")
include ("utility")
include ("callable")

-- namespace GordianLaserBoss
GordianLaserBoss = {}
local self = GordianLaserBoss

self._Debug = 0

local data = {}
data.targetEntityId = nil
data.targetingTimer = 0
data.shotTimer = 0
data.aggressive = true
data._TargetTimerMax = 0.5 -- Shoots somewhat faster than the standard laser boss.
data._ShotMaxTimer = 0.9 --Shoots somewhat faster.
data._ShotRestTimer = 0.25 --Rest timer.
data._LaserDistance = 60000
data._TimeToActive = 30

local laser = nil
local targetLaser = nil

data.targetLaserData = {}
data.targetLaserData.from = nil
data.targetLaserData.to = nil
data.bossLook = vec3()
data.bossRight = vec3()
data.bossUp = vec3()

laserActive = false
shootNow = false
shotJustNow = 5
glowColor = ColorRGB(1, 1, 0.5)

function GordianLaserBoss.interactionPossible(playerIndex)
    return false
end

function GordianLaserBoss.initialize(_AmpData)
    _AmpData = _AmpData or 1
    data.amped = _AmpData

    local _ShipAI = ShipAI()

    _ShipAI:setIdle()
    _ShipAI:setPassiveShooting(true)

    local _Boss = Entity()
    
    _Boss.addBaseMultiplier(_Boss, StatsBonuses.GeneratedEnergy, 20.0)
    _Boss.addBaseMultiplier(_Boss, StatsBonuses.BatteryRecharge, 20.0)
    if _Boss:getValue("autokill") then
        data._TimeToActive = 0
    end

    _Boss:registerCallback("onDestroyed", "onDestroyed")
end

function GordianLaserBoss.onDestroyed()
    GordianLaserBoss.deleteCurrentLasers()
end

function GordianLaserBoss.update(timeStep)
    local methodName = "Update"

    if data._TimeToActive >= 0 then
        data._TimeToActive = data._TimeToActive - timeStep
        return
    end

    if data.aggressive then

        if not laserActive then
            GordianLaserBoss.createTargetingLaser()
        end

        GordianLaserBoss.updateIntersection(timeStep)
        GordianLaserBoss.updateLaser()

        if shootNow then
            GordianLaserBoss.showChargeEffect()
        end

        local boss = Entity()

        if onServer() then
            --Be careful about enabling these, they can get spammy.
            if not data.targetEntityId or not Entity(data.targetedEntityId) then
                --self.Log(methodName, "Target does not exist. Picking new target.")
            else
                if not Entity(data.targetedEntityId).isShip then
                    --self.Log(methodName, "Target is not a ship. Picking new target.")
                end

                if Entity(data.targetEntityId).invincible then
                    --self.Log(methodName, "Target is invincible. Picking new target.")
                end
            end

            if not data.targetEntityId or not Entity(data.targetedEntityId) or not Entity(data.targetedEntityId).isShip or Entity(data.targetEntityId).invincible then
                -- set new target
                local players = {Sector():getPlayers()}
                shuffle(random(), players)
                local newTarget = nil
                for _, player in pairs(players) do
                    if not player.craft then goto continue end

                    newTarget = player.craft.id
                    break

                    ::continue::
                end
                data.targetEntityId = newTarget
                GordianLaserBoss.sync()
            end
        end

        shotJustNow = shotJustNow + timeStep
    end
end

function GordianLaserBoss.updateIntersection(timeStep)
    if onClient() then return end

    local ray = Ray()
    ray.origin = vec3(data.targetLaserData.from) or vec3()
    ray.direction = (vec3(data.targetLaserData.to) or vec3()) - ray.origin
    ray.planeIntersectionThickness = 6
    if not ray then return end

    local boss = Entity()
    result = Sector():intersectBeamRay(ray, boss, nil)

    if not shootNow then
        if shotJustNow > data._ShotRestTimer then
            -- reset laser after shot
            GordianLaserBoss.createTargetingLaser()
            GordianLaserBoss.updateTimer(result, timeStep)
        end
        -- have a little rest, so that the huge shot beam can dissipate
    else
        GordianLaserBoss.initializeShot(result, timeStep)
    end

end

function GordianLaserBoss.updateTimer(entity, timeStep)

    local gotEntity = false

    -- we have an enemy in sight.
    if entity and (self.entityIsEnemy(entity) or entity.type == EntityType.Wreckage or entity.type == EntityType.Asteroid) then
        gotEntity = true
        data.targetingTimer = (data.targetingTimer or 0) + timeStep

        if data.targetingTimer > data._TargetTimerMax then
            data.targetingTimer = 0
            data.shotTimer = 0
            GordianLaserBoss.createTargetLockedLaser()
            shootNow = true
        end
    end

    if not gotEntity then
        data.targetingTimer = 0 -- reset timer
        if not data.targetEntityId or not Entity(data.targetEntityId) then return end

        local shipAI = ShipAI()
        if not shipAI then return end

        shipAI:setPassiveTurning(Entity(data.targetEntityId).translationf) -- turn while we update timer
        return
    end

    if not data.targetEntityId then return end
    ShipAI():setPassiveTurning(Entity(data.targetntityId).translationf) -- turn while we update timer
end

function GordianLaserBoss.initializeShot(entity, timeStep)
    local _MethodName = "Initialize Shot"
    ShipAI():setPassive() -- don't turn while shooting
    data.shotTimer = data.shotTimer + timeStep

    local _ShotMaxTimer = data._ShotMaxTimer

    if entity and data.shotTimer > _ShotMaxTimer then
        -- remove old laser and create shot laser
        GordianLaserBoss.createShotLaser()
        data.shotTimer = 0
        shootNow = false
        shotJustNow = 0
        data.targetEntityId = nil -- find a new target

        if entity.type == EntityType.Asteroid or entity.type == EntityType.Wreckage then
            self.showExplosion(entity)
            entity:destroy(Entity().id, 1, DamageType.Energy)
            if entity then Sector():deleteEntity(entity) end
        else
            -- do damage to entity
            local _self = Entity()
            local shield = Shield(entity.id)
            local durability = Durability(entity.id)
            if not durability then return end
            self.Log(_MethodName, "Hit! inflicting a ton of damage.")
            
            local _dmg = 200000000 * data.amped

            if shield then
                local _shielddmg = _dmg
                local _hulldmg = 0
                if shield.durability < _dmg then
                    _shielddmg = shield.durability
                    _hulldmg = _dmg - shield.durability
                end
                shield:inflictDamage(_shielddmg, 1, DamageType.Energy, _self.translationf, _self.id)
                if _hulldmg > 0 then
                    durability:inflictDamage(_hulldmg, 1, DamageType.Energy, _self.id)
                end
            else
                durability:inflictDamage(_dmg, 1, DamageType.Energy, _self.id)
            end           
        end
    elseif not entity and data.shotTimer > _ShotMaxTimer then
        GordianLaserBoss.createShotLaser()
        data.shotTimer = 0
        shootNow = false
        shotJustNow = 0
    end
end

function GordianLaserBoss.entityIsEnemy(_Entity)
    local _EnemyEntities = {Sector():getEnemies(Entity().factionIndex)}
    for _, _Enemy in pairs(_EnemyEntities) do
        if (_Enemy.type == EntityType.Ship or _Enemy.type == EntityType.Station) and _Enemy.id == _Entity.id then
            return true
        end
    end

    return false
end

function GordianLaserBoss.resetTimeToActive(_Time)
    data._TimeToActive = _Time
end

--region #CLIENT ONLY

function GordianLaserBoss.updateLaser()
    if onClient() then
        if not laser then return end

        local bo = Entity()
        laser.from = bo.translationf - bo.look * 25
        laser.to = laser.from + bo.look * 145
        laser.aliveTime = 0

        targetLaser.from = laser.to
        targetLaser.to = laser.to + bo.look * data._LaserDistance
        targetLaser.aliveTime = 0

        data.targetLaserData.from = targetLaser.from
        data.targetLaserData.to = targetLaser.to

        data.bossLook = bo.look
        data.bossRight = bo.right
        data.bossUp = bo.up

        GordianLaserBoss.syncLaserData(data.targetLaserData)
    end
end

--endregion

--region #CLIENT / SERVER CALLS

--region #FX

function GordianLaserBoss.createTargetingLaser()
    laserActive = true

    if onServer() then
        broadcastInvokeClientFunction("createTargetingLaser")
        return
    end

    GordianLaserBoss.deleteCurrentLasers()
    GordianLaserBoss.createLaser(1, ColorRGB(1, 1, 0), true)
end

function GordianLaserBoss.createTargetLockedLaser()
    if onServer() then
        broadcastInvokeClientFunction("createTargetLockedLaser")
        return
    end

    GordianLaserBoss.deleteCurrentLasers()
    GordianLaserBoss.createLaser(8, ColorRGB(1.0, 0.4, 0), true)

    GordianLaserBoss.showChargeEffect()
end

function GordianLaserBoss.createShotLaser()
    if onServer() then
        broadcastInvokeClientFunction("createShotLaser")
        return
    end

    GordianLaserBoss.deleteCurrentLasers()

    GordianLaserBoss.createLaser(55, ColorRGB(1, 0, 0), false)
end

function GordianLaserBoss.deleteCurrentLasers()
    if onServer() then
        broadcastInvokeClientFunction("deleteCurrentLasers")
        return
    end

    if valid(laser) then Sector():removeLaser(laser) end
    if valid(targetLaser) then Sector():removeLaser(targetLaser) end
end

function GordianLaserBoss.createLaser(width, color, collision)
    if onServer() then
        broadcastInvokeClientFunction("createLaser")
        return
    end

    local color = color or ColorRGB(0.1, 0.1, 0.1)
    local targetColor = color or ColorRGB(0.1, 0.1, 0.1)

    local sector = Sector()
    local bo = sector:getEntitiesByScript("gordianlaserboss.lua")

    -- laser till bow of ship
    local from = bo.translationf - bo.look * 25
    local to = from + bo.look * 145
    laser = sector:createLaser(vec3(), vec3(), color, width or 1)
    laser.collision = false
    laser.from = from
    laser.to = to

    -- laser beyond ship used for targeting
    local targetFrom = to
    local targetTo = to + bo.look * data._LaserDistance
    targetLaser = sector:createLaser(vec3(), vec3(), targetColor, width or 1)
    targetLaser.collision = collision
    targetLaser.from = targetFrom
    targetLaser.to = targetTo

    -- write to extra data structure for easier intersection calc
    data.targetLaserData.from = targetLaser.from
    data.targetLaserData.to = targetLaser.to

    laser.maxAliveTime = 5
    targetLaser.maxAliveTime = 5
end

function GordianLaserBoss.showChargeEffect()
    if onServer() then
        broadcastInvokeClientFunction("showChargeEffect", entity)
        return
    end

    if not laser then return end
    local from = laser.from
    local look = laser.to
    local size = 75 + (75 * data.shotTimer)

    Sector():createGlow(from, size, ColorRGB(1,1,0.85))
    Sector():createGlow(from, size, ColorRGB(1,1,0.85))
    Sector():createGlow(from, size, ColorRGB(1,1,0.85))
end

function GordianLaserBoss.showExplosion(entity)
    if onServer() then
        broadcastInvokeClientFunction("showExplosion", entity)
        return
    end

    if not entity then return end
    local position = entity.translationf
    local _Bounds = entity:getBoundingSphere()
    Sector():createExplosion(position, math.max(_Bounds.radius, 200), false)
end

--endregion

function GordianLaserBoss.Log(_MethodName, _Msg)
    if self._Debug == 1 then
        print("[GordianLaserBoss] - [" .. tostring(_MethodName) .. "] - " .. tostring(_Msg))
    end
end

function GordianLaserBoss.sync(data_in)
    if onServer() then
        broadcastInvokeClientFunction("sync", data)
    else
        if data_in then
            data = data_in
        else
            invokeServerFunction("sync")
        end
    end
end
callable(GordianLaserBoss, "sync")

function GordianLaserBoss.syncLaserData(data_in)
    if onClient() then
        invokeServerFunction("syncLaserData", data.targetLaserData)
    else
        data.targetLaserData = data_in
    end
end
callable(GordianLaserBoss, "syncLaserData")

--endregion