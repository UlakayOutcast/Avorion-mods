package.path = package.path .. ";data/scripts/lib/?.lua"

include ("randomext")

ESCCWeaponScriptUtil = include("esccweaponscriptutil")

-- Don't remove or alter the following comment, it tells the game the namespace this script lives in. If you remove it, the script will break. YES, YOU NEED THIS. MAKE SURE TO COPY IT.
-- namespace Distributor
Distributor = {}
local self = Distributor

self._Debug = 0
self._DebugLevel = 1
self._Target_Invincible_Debug = 0

self.data = {}
self.clientData = {} --Exclusively stored clientside. Does not get secured / restored.

local mainLaser = nil

--This one is a bit confusing. What does it do, exactly? Basically, the ship with this script will tether itself to a chosen target. When the chosen target takes damage,
--the ship will inflict (damagePool * blastDamageMultiplier) damage on all of the target's allies within (blastRadius / 100) km. The target does *not* take less damage, so
--any damage dealt by this script is in addition to the damage the target is already taking.
function Distributor.initialize(values)
    local methodName = "initialize"
    self.Log(methodName, "Adding v16 of distributor.lua to entity.")

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
            self.data.blastRadius = self.data.blastRadius or 2000
            self.data.blastDamageMultiplier = self.data.blastMultiplier or 0.5 --The multiplier for the amount of damage that is passed on to the target's allies.
            self.data.targetPriority = self.data.targetPriority or defaultTargetPriority
            self.data.damagePrimaryTarget = self.data.damagePrimaryTarget or false
            self.data.damagePrimaryTargetMultiplier = self.data.damagePrimaryTargetMultiplier or 0.1
            self.data.pickNewTargetCycle = self.data.pickNewTargetCycle or 20
            self.data.timeToActive = self.data.timeToActive or 10
            --TARGET PRIORITIES:
            -- 1 - Random enemy - must be ship or station.
            -- 2 - Any non-Xsotan ship or station.
            -- 3 - Any entity with a specified scriptvalue - chosen by self.data.targetTag - for example, is_pirate would target any enemies with is_pirate set.
            self.data.currentTarget = nil
            self.data.damagePool = 0 --The base amount of damage that is passed on to the target's allies.

            --Adjust target priority as needed.
            if self.data.targetPriority == 2 and not self_is_xsotan then
                self.data.targetPriority = 1 --Just use 1 - it is functionally equivalent.
            end

            --Finally, register ondamaged / onshield damaged callbacks.
            if _sector:registerCallback("onDamaged", "onDamagedSector") == 1 then
                self.Log(methodName, "WARNING - Could not register onDamaged callback.")
            end
            if _sector:registerCallback("onShieldDamaged", "onShieldDamagedSector") == 1 then
                self.Log(methodName, "WARNING - Could not register onShieldDamaged callback.")
            end
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

function Distributor.getUpdateInterval()
    if onClient() then
        return 0 --Update every frame.
    else --onServer()
        return 2
    end
end

function Distributor.onSelfDestroyed()
    self.deleteCurrentLasers()
end

--region #SERVER / CLIENT FUNCTIONS

function Distributor.update(timeStep)
    local methodName = "Update"

    if self.data.timeToActive >= 0 then
        self.data.timeToActive = self.data.timeToActive - timeStep
        return
    end

    if onClient() then
        self.updateLaser()
    else --onServer()
        --if there are no enemies, abort.
        if Entity():getValue("is_xsotan") then
            local myAI = ShipAI()
            if not myAI:isEnemyPresent(true) then
                return
            end
        end

        if not self.data.currentTarget or not valid(self.data.currentTarget) then
            self.Log(methodName, "Current target is nil or no longer valid - picking new target.")
            self.data.currentTarget = self.pickNewTarget()
            broadcastInvokeClientFunction("setTargetID", self.data.currentTarget.index.string)
        end

        if self.data.damagePool > 0 then
            self.dischargeDamagePool()
        end
    end
end

function Distributor.deleteCurrentLasers()
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

--endregion

--region #SERVER FUNCTIONS

function Distributor.pickNewTarget()
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

function Distributor.onDamagedSector(objectIndex, amount, inflictor, damageSource, damageType)
    local methodName = "On Damaged"
    self.Log(methodName, "Running on Damaged...", 3)

    for _, distributor in pairs({ Sector():getEntitiesByScript("distributor.lua") }) do
        distributor:invokeFunction("distributor.lua", "addToDamagePool", objectIndex, amount)
    end
end

function Distributor.onShieldDamagedSector(entityId, amount, damageType, inflictorID)
    local methodName = "On Shield Damaged"
    self.Log(methodName, "Running on Shield Damaged...", 3)

    for _, distributor in pairs ({ Sector():getEntitiesByScript("distributor.lua") }) do
        distributor:invokeFunction("distributor.lua", "addToDamagePool", entityId, amount)
    end
end

function Distributor.onDestroyedSector(idx, lastDamageInflictor)
    for _, distributor in pairs ({ Sector():getEntitiesByScript("distributor.lua") }) do
        distributor:invokeFunction("distributor.lua", "reportDestroyedTarget", idx)
    end
end

function Distributor.addToDamagePool(targetIdx, amount)
    local methodName = "Adding To Damage Pool"

    if self.data.currentTarget and valid(self.data.currentTarget) and targetIdx == self.data.currentTarget.index then
        self.Log(methodName, "Index match detected - adding " .. tostring(amount) .. " to damage pool.", 2)
        self.data.damagePool = self.data.damagePool + amount
    end
end

function Distributor.dischargeDamagePool()
    local methodName = "Discharge Damage Pool"

    if self.data.currentTarget and valid(self.data.currentTarget) then
        local factionIdx = self.data.currentTarget.factionIndex
        local _entity = Entity()

        local alliedEntities = { Sector():getEntitiesByFaction(factionIdx) }

        for _, entity in pairs(alliedEntities) do
            if (entity.type == EntityType.Ship or entity.type == EntityType.Station) then
                if entity.index ~= self.data.currentTarget.index then
                    local dist = self.data.currentTarget:getNearestDistance(entity)
                    self.Log(methodName, "Dist betweeen " .. self.data.currentTarget.name .. " and " .. entity.name .. " is " .. tostring(dist))
                    if dist <= self.data.blastRadius then
                        self.Log(methodName, "Dealing " .. tostring(self.data.damagePool * self.data.blastDamageMultiplier) .. " damage to " .. entity.name)
                        ESCCWeaponScriptUtil.inflictDamageToTarget(entity, self.data.damagePool * self.data.blastDamageMultiplier, DamageType.Energy, _entity.index)
                        broadcastInvokeClientFunction("drawSmallLaser", self.data.currentTarget.translationf, entity.translationf)
                    end
                else
                    if self.data.damagePrimaryTarget then
                        self.Log(methodName, "Damage primary target enabled. Dealing " .. tostring(self.data.damagePool * self.data.primaryTargetDamageMultiplier) .. " damage to " .. entity.name)
                        ESCCWeaponScriptUtil.inflictDamageToTarget(entity, self.data.damagePool * self.data.primaryTargetDamageMultiplier, DamageType.Energy, _entity.index)
                    end
                end
            end
        end

        self.data.damagePool = 0
    end
end

function Distributor.reportDestroyedTarget(index)
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

function Distributor.setTargetID(targetID)
    self.clientData.currentTargetId = targetID
end

function Distributor.clearTargetID()
    self.clientData.currentTargetId = nil
end

function Distributor.updateLaser()
    local _sector = Sector()
    local _entity = Entity()

    local laserColor = ColorRGB(1.0, 0.33, 0.0)
    local removeLaser = false

    local sCurrentTargetId = self.clientData.currentTargetId

    if sCurrentTargetId then
        local currentTargetId = Uuid(sCurrentTargetId)
        local target = Entity(currentTargetId)
    
        if target and valid(target) then
            if not mainLaser or not valid(mainLaser) then
                mainLaser = _sector:createLaser(vec3(), vec3(), laserColor, 10)
            end
    
            if mainLaser and valid(mainLaser) then
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

    if removeLaser then
        if valid(mainLaser) then 
            _sector:removeLaser(mainLaser)
        end
    end
end

function Distributor.drawSmallLaser(position1, position2)
    local methodName = "Draw Small Laser"
    self.Log(methodName, "Drawing small laser.")

    local _sector = Sector()

    local smallLaser = _sector:createLaser(position1, position2, ColorRGB(1.0, 0.33, 0.0), 2.5)
    smallLaser.collision = false
    smallLaser.maxAliveTime = 0.5
end

--TODO

--endregion

--region #SECURE / LOG / RESTORE

function Distributor.Log(methodName, msg, logLevel)
    logLevel = logLevel or 1
    if self._Debug == 1 and self._DebugLevel >= logLevel then
        print("[Distributor] - [" .. methodName .. "] - " .. msg)
    end
end

function Distributor.secure()
    local methodName = "Secure"
    self.Log(methodName, "Securing self.data")
    return self.data
end

function Distributor.restore(values)
    local methodName = "Restore"
    self.Log(methodName, "Restoring self.data")
    self.data = values

    if self.data.currentTarget then
        broadcastInvokeClientFunction("setTargetID", self.data.currentTarget.index.string)
    end
end

--endregion