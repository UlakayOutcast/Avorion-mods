package.path = package.path .. ";data/scripts/lib/?.lua"

include ("randomext")

ESCCWeaponScriptUtil = include("esccweaponscriptutil")

-- Don't remove or alter the following comment, it tells the game the namespace this script lives in. If you remove it, the script will break. YES, YOU NEED THIS. MAKE SURE TO COPY IT.
-- namespace Thunderstrike
Thunderstrike = {}
local self = Thunderstrike

self._Debug = 0
self._DebugLevel = 1
self._Target_Invincible_Debug = 0

self.data = {}
self.clientData = {} --Exclusively stored clientside. Does not get secured / restored.

local mainLaser = nil

function Thunderstrike.initialize(values)
    local methodName = "initialize"
    self.Log(methodName, "Adding v6 of thunderstrike.lua to entity.")

    self.data = values or {}
    self.clientData = {}

    local _sector = Sector()
    local _entity = Entity()

    if onServer() then
        local self_is_xsotan = _entity:getValue("is_xsotan")
        local defaultTargetPriority = 1
        if self_is_xsotan then
            defaultTargetPriority = 2
        end

        Boarding(_entity).boardable = false

        if not _restoring then
            self.data.damageRange = self.data.damageRange or 2000
            self.data.damagePerStrike = self.data.damagePerStrike or 10000
            self.data.targetPriority = self.data.targetPriority or defaultTargetPriority
            self.data.pickNewTargetCycle = self.data.pickNewTargetCycle or 15
            self.data.timeToActive = self.data.timeToActive or 10
            self.data.useEntityDamageMult = self.data.useEntityDamageMult or false
            --TARGET PRIORITIES:
            -- 1 - Random enemy - must be ship or station.
            -- 2 - Any non-Xsotan ship or station.
            -- 3 - Any entity with a specified scriptvalue - chosen by self.data.targetTag - for example, is_pirate would target any enemies with is_pirate set.
            self.data.currentTarget = nil
            self.data.damagePool = 0

            --Adjust target priority as needed.
            if self.data.targetPriority == 2 and not self_is_xsotan then
                self.data.targetPriority = 1 --Just use 1 - it is functionally equivalent.
            end

            --Finally, register sector-level callbacks.
            if _sector:registerCallback("onDestroyed", "onDestroyedSector") == 1 then
                self.Log(methodName, "WARNING - could not register onDestroyed (Sector) callback.")
            end
        else
            self.Log(methodName, "Restoring data from self.restore()")
        end
    else --onClient()
        self.data.timeToActive = 0
    end

    _entity:registerCallback("onDestroyed", "onSelfDestroyed")
end

function Thunderstrike.getUpdateInterval()
    if onClient() then
        return 0 --Update every frame.
    else --onServer()
        return 1
    end
end

function Thunderstrike.onSelfDestroyed()
    self.deleteCurrentLasers()
end

--region #SERVER / CLIENT FUNCTIONS

function Thunderstrike.update(timeStep)
    local methodName = "Update"

    local _entity = Entity()
    local _random = random()

    if self.data.timeToActive >= 0 then
        self.data.timeToActive = self.data.timeToActive - timeStep
        return
    end

    if onClient() then
        self.updateLaser()
    else --onServer()
        --if there are no enemies, abort.
        if _entity:getValue("is_xsotan") then
            local myAI = ShipAI()
            if not myAI:isEnemyPresent(true) then
                return
            end
        end

        if not self.data.currentTarget or not valid(self.data.currentTarget) then
            self.Log(methodName, "Current target is nil or no longer valid - picking new target.")
            self.data.currentTarget = self.pickNewTarget()
            broadcastInvokeClientFunction("setTargetID", self.data.currentTarget.index.string, self.data.damageRange)
        end

        if self.data.currentTarget and valid(self.data.currentTarget) then
            --make sure the target is within range.
            local distToTarget = _entity:getNearestDistance(self.data.currentTarget)
            if distToTarget <= self.data.damageRange then
                local damageAmount = self.data.damagePerStrike
                if self.data.useEntityDamageMult then
                    damageAmount = damageAmount * _entity.damageMultiplier
                end

                self.Log(methodName, "Dealing " .. tostring(damageAmount) .. " to Entity " .. self.data.currentTarget.name)
                ESCCWeaponScriptUtil.inflictDamageToTarget(self.data.currentTarget, damageAmount, DamageType.Electric, _entity.index)
                self.drawSmallLaser()
                if _random:test(0.5) then
                    local delay = _random:getFloat(0, 0.25)
                    deferredCallback(delay, "drawSmallLaser")
                end
                if _random:test(0.25) then
                    local delay = _random:getFloat(0, 0.25)
                    deferredCallback(delay, "drawSmallLaser")
                end
            end
        end
    end
end

function Thunderstrike.deleteCurrentLasers()
    local methodName = "Delete Current Lasers"
    if onServer() then
        self.Log(methodName, "Calling on Server - invoking on Client", 1)
        broadcastInvokeClientFunction("deleteCurrentLasers")
        return
    else
        self.Log(methodName, "Calling on client", 1)
    end

    self.clearTargetID() --Need to do this because the update loop can happen several times before destruction and after sending clear command.

    --While clearTargetID will usually take care of running the cleanup, it's possible that the update loop doesn't run again, so we also need to clear the main laser manually.
    if valid(mainLaser) then Sector():removeLaser(mainLaser) end

    mainLaser = nil
end

function Thunderstrike.drawSmallLaser(endPoint)
    local methodName = "Draw Small Laser"

    if onServer() then
        self.Log(methodName, "Calling on server => invoking on client.")
        broadcastInvokeClientFunction("drawSmallLaser", self.data.currentTarget.translationf)
        return
    end

    self.Log(methodName, "Calling on client.")

    local _sector = Sector()
    local _random = random()
    
    local beamLength = _random:getInt(100, 300)
    local beamDirection = _random:getDirection()
    local beamStart = endPoint + (beamDirection * beamLength)

    local smallLaser = _sector:createLaser(beamStart, endPoint, ColorRGB(0.66, 0.66, 1.0), 2.5)
    smallLaser.collision = true
    smallLaser.maxAliveTime = 0.5
    smallLaser.shape = BeamShape.Lightning
    smallLaser.animationSpeed = 0
    smallLaser.animationAcceleration = 0
    smallLaser.shapeSize = 13
end

--endregion

--region #SERVER FUNCTIONS

function Thunderstrike.pickNewTarget()
    local methodName = "Pick New Target"

    local factionIdx = Entity().factionIndex
    local targetPriority = self.data.targetPriority

    local _sector = Sector()
    local enemies = ESCCWeaponScriptUtil.getEnemiesInSector(_sector, factionIdx)

    local targetCandidates = {}

    local targetPriorityFunctions = {
        function() --1 - pick an enemy at random.
            for _, candidate in pairs(enemies) do
                table.insert(targetCandidates, candidate)
            end
        end,
        function() --2 - pick a random non-Xostan.
            local sectorShips = { _sector:getEntitiesByType(EntityType.Ship) }
            local sectorStations = { _sector:getEntitiesByType(EntityType.Station) }

            for _, candidate in pairs(sectorShips) do
                if not ESCCWeaponScriptUtil.isTargetXsotanCheck(candidate) then
                    table.insert(targetCandidates, candidate)
                end
            end

            for _, candidate in pairs(sectorStations) do
                if not ESCCWeaponScriptUtil.isTargetXsotanCheck(candidate) then
                    table.insert(targetCandidates, candidate)
                end
            end
        end,
        function() --3 - pick enemies with a specific script value.
            local scriptValueEntities = { _sector:getEntitiesByScriptValue(self.data.targetTag) }
            for _, candidate in pairs(scriptValueEntities) do
                table.insert(targetCandidates, candidate)
            end
        end
    }

    targetPriorityFunctions[targetPriority]()

    if #targetCandidates > 0 then
        self.Log(methodName, tostring(#targetCandidates) .. " suitable candidates found. Picking one at random.")
        return ESCCWeaponScriptUtil.pickTargetFromTable(targetCandidates, self._Target_Invincible_Debug == 1)
    else
        self.Log(methodName, "WARNING - Could not find any target candidates.", 1)
        return nil
    end
end

function Thunderstrike.onDestroyedSector(idx, lastDamageInflictor)
    for _, thunderstriker in pairs ({ Sector():getEntitiesByScript("thunderstrike.lua") }) do
        thunderstriker:invokeFunction("thunderstrike.lua", "reportDestroyedTarget", idx)
    end
end

function Thunderstrike.reportDestroyedTarget(index)
    local methodName = "Report Destroyed Target"

    if self.data.currentTarget and self.data.currentTarget.index == index then
        self.Log(methodName, "Target no longer valid - clearing target and syncing.")
        self.data.currentTarget = nil
        self.data.timeToActive = self.data.pickNewTargetCycle
        broadcastInvokeClientFunction("clearTargetID")
    end
end

--endregion

--region #CLIENT FUNCTIONS

function Thunderstrike.setTargetID(targetID, maximumRange)
    self.clientData.currentTargetId = targetID
    self.clientData.laserRange = maximumRange
end

function Thunderstrike.clearTargetID()
    self.clientData.currentTargetId = nil
end

function Thunderstrike.updateLaser()
    local _sector = Sector()
    local _entity = Entity()

    local laserColor = ColorRGB(0.66, 0.66, 1.0)
    local removeLaser = false

    local sCurrentTargetId = self.clientData.currentTargetId
    local maxDistanceToTarget = self.clientData.laserRange

    if sCurrentTargetId then
        local currentTargetId = Uuid(sCurrentTargetId)
        local target = Entity(currentTargetId)

        if target and valid(target) then
            local distanceToTarget = _entity:getNearestDistance(target)
            if distanceToTarget <= maxDistanceToTarget then
                if not mainLaser or not valid(mainLaser) then
                    mainLaser = _sector:createLaser(vec3(), vec3(), laserColor, 10)
                end
    
                if mainLaser and valid(mainLaser) then
                    mainLaser.shape = BeamShape.Lightning
                    mainLaser.animationSpeed = 0.25
                    mainLaser.animationAcceleration = 0
                    mainLaser.shapeSize = 26
                    mainLaser.from = _entity.translationf
                    mainLaser.to = target.translationf
                    mainLaser.collision = false
                end
            else
                removeLaser = true
            end
        else
            removeLaser = true
        end
    else
        removeLaser = true
    end

    if removeLaser then
        if valid(mainLaser) then 
            _sector:removeLaser(mainLaser)
        end
    end
end

--endregion

--region #SECURE / LOG / RESTORE

function Thunderstrike.Log(methodName, msg, logLevel)
    logLevel = logLevel or 1
    if self._Debug == 1 and self._DebugLevel >= logLevel then
        print("[Thunderstrike] - [" .. methodName .. "] - " .. msg)
    end
end

function Thunderstrike.secure()
    local methodName = "Secure"
    self.Log(methodName, "Securing self.data")
    return self.data
end

function Thunderstrike.restore(values)
    local methodName = "Restore"
    self.Log(methodName, "Restoring self.data")
    self.data = values

    if self.data.currentTarget then
        broadcastInvokeClientFunction("setTargetID", self.data.currentTarget.index.string, self.data.damageRange)
    end
end

--endregion