package.path = package.path .. ";data/scripts/lib/?.lua"
package.path = package.path .. ";data/scripts/?.lua"

--Don't remove the namespace comment!!! The script could break.
--namespace Schismatic
Schismatic = {}
local self = Schismatic

self._Data = {}

local _DamageTaken = 0
local _DamageTakenTable = {}

local explosionCounter = 0 --Used clientside - we do not want this overwrriten on sync.

self._Debug = 0

function Schismatic.initialize(_Values)
    local methodName = "Initialize"
    local _Entity = Entity()
    self.Log(methodName, "Attaching Schismatic v2 script to enemy.")

    self._Data = _Values or {}
    self._Data._Resistance = 0.55
    self._Data._HullResistance = 0.75

    --Teleport values
    self._Data._Timer = 0
    self._Data._JumpTimer = 0
    self._Data._StunnedTimer = 0
    self._Data._IsStunned = false

    self._Data._JumpInterval = 7
    self._Data._StunnedInterval = 5

    --Damage values - we use these to secure / restore values.
    self._Data._PhysDamageTaken = 0
    self._Data._AntiDamageTaken = 0
    self._Data._PlasDamageTaken = 0
    self._Data._EnRGDamageTaken = 0
    self._Data._ElecDamageTaken = 0
    self._Data._OverallDamageTaken = 0
    self._Data._FirstUpdateRun = false --Updates once per second until this is run, then once per 20s afterwards.

    if onServer() then
        --Pulse cannon gang sit down.
        _Entity:addAbsoluteBias(StatsBonuses.ShieldImpenetrable, 1)

        if _Entity:registerCallback("onShieldDamaged", "onShieldDamaged") == 1 then
            self.Log(methodName, "Could not attach onShieldDamaged callback.")
        end
        if _Entity:registerCallback("onDamaged", "onDamaged") == 1 then
            self.Log(methodName, "Could not attach onDamaged callback.")
        end
    end
end

--Client / Server - we can update every second on the server but we want to update every frame on client.
if onServer() then
    
function Schismatic.getUpdateInterval()
    return 1
end

else

function Schismatic.getUpdateInterval()
    return 0
end
    
end

--region #SERVER FUNCTIONS

function Schismatic.updateServer(timeStep)
    local methodName = "Update Server"
    
    --Manage damage taken
    self.Log(methodName, "Amount of damage taken: " .. tostring(_DamageTaken))
    if _DamageTaken > 0 then
        self.Log(methodName, "Adapting defenses to offensive pressure...")

        self.adaptShield()

        self.adaptHull()

        self._Data._FirstUpdateRun = true
    else
        self.Log(methodName, "Have not taken damage yet - nothing to adapt to. Setting table entires to 0.")

        _DamageTakenTable[DamageType.Physical] =    0
        _DamageTakenTable[DamageType.AntiMatter] =  0
        _DamageTakenTable[DamageType.Plasma] =      0
        _DamageTakenTable[DamageType.Energy] =      0
        _DamageTakenTable[DamageType.Electric] =    0
    end

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
end

function Schismatic.onShieldDamaged(_ObjectIndex, _Amount, _DamageType, _InflictorID)
    local methodName = "On Shield Damaged"
    self.Log(methodName, "Running On Shield Damage callback - damage amount is " .. tostring(_Amount) .. " and damage type is " .. tostring(_DamageType))
    if not _DamageType or not _Amount then
        return
    else
        self.adaptDefense(_DamageType, _Amount)
        self.checkDamageTypeTeleport(_DamageType)
    end
end

function Schismatic.onDamaged(_ObjectIndex, _Amount, _Inflictor, _DamageSource, _DamageType)
    local methodName = "On Damaged"
    self.Log(methodName, "Running on Damaged callback - damage amount is " .. tostring(_Amount) .. " and damage type is " .. tostring(_DamageType))
    if not _DamageType or not _Amount then
        return
    else
        self.adaptDefense(_DamageType, _Amount)
        self.checkDamageTypeTeleport(_DamageType)
    end
end

function Schismatic.adaptDefense(_DamageType, _Amount)
    if _DamageType ~= DamageType.Fragments then
        _DamageTaken = (_DamageTaken or 0) + _Amount
        _DamageTakenTable[_DamageType] = (_DamageTakenTable[_DamageType] or 0) + _Amount
    end
end

--region #DAMAGE TAKEN MANAGEMENT

function Schismatic.adaptShield()
    local methodName = "Adapt Shield"
    local _AdaptToDamage = 0
    local _AdaptToType = DamageType.Physical
    for _DmgType, _DmgTaken in pairs(_DamageTakenTable) do
        if _DmgTaken > _AdaptToDamage then
            _AdaptToDamage = _DmgTaken
            _AdaptToType = _DmgType
        end
    end

    self.Log(methodName, "Setting shield resistance to " .. tostring(_AdaptToType))

    local _Shield = Shield()
    if _Shield then
        self.Log(methodName, "Shield exists - setting resistance amount.")
        _Shield:setResistance(_AdaptToType, self._Data._Resistance)
    end
end

function Schismatic.adaptHull()
    local methodName = "Adapt Hull"
    local _AdaptToDamage = 0
    local _AdaptToType = DamageType.Physical
    for _DmgType, _DmgTaken in pairs(_DamageTakenTable) do
        if _DmgTaken > _AdaptToDamage then
            _AdaptToDamage = _DmgTaken
            _AdaptToType = _DmgType
        end
    end

    self.Log(methodName, "Setting hull resistance to " .. tostring(_AdaptToType))

    local _Durability = Durability()
    if _Durability then
        self.Log(methodName, "Durability exists - setting resistance amount.")
        _Durability:setWeakness(_AdaptToType, self._Data._HullResistance * -1)
    end
end

--endregion

--region #JUMP MANAGEMENT

function Schismatic.checkDamageTypeTeleport(damageType)
    local methodName = "Check Damage Teleport"

    if damageType ~= DamageType.Fragments then
        --Stun if it takes the damage type it has taken the LEAST of. Teleport otherwise.
        local stunFromDamage = math.huge
        local stunFromType = DamageType.Physical
        for dmgType, dmgTaken in pairs(_DamageTakenTable) do
            if dmgTaken < stunFromDamage then
                stunFromDamage = dmgTaken
                stunFromType = dmgType
            end
            if dmgTaken == stunFromDamage then --In theory, there are multiple types it could have taken 0 damage from.
                if random():test(0.5) then
                    stunFromDamage = dmgTaken
                    stunFromType = dmgType
                end
            end
        end

        if damageType == stunFromType then
            self._Data._StunnedTimer = self._Data._StunnedInterval
            self._Data._IsStunned = true
            self.sync() --Need to let the client know we're stunned.
        else
            if self._Data._StunnedTimer <= 0 and self._Data._JumpTimer <= 0 then
                self._Data._JumpTimer = self._Data._JumpInterval
                self.doJump()
            end
        end
    end
end

function Schismatic.doJump()
    local methodName = "Do Jump"
    self.Log(methodName, "Jumping.")
    
    local entity = Entity()
    local rand = random()

    local dir = rand:getDirection()
    --if the nearest xsotan is more than 15km away, jump towards the farthest xsotan.
    local nearestXsotan, distToNXsotan = self.findXsotan(true)
    if nearestXsotan then
        if distToNXsotan > 1500 then
            self.Log(methodName, "Jumping towards farthest Xsotan.")
            local farthestXsotan, distToFXsotan = self.findXsotan(false)
            dir = normalize(farthestXsotan.translationf - entity.translationf)
        end
    end

    local magnitude = rand:getInt(750, 1500)

    local newPos = entity.translationf + (dir * magnitude)
    local newPosition = dvec3(newPos.x, newPos.y, newPos.z)

    broadcastInvokeClientFunction("jumpAnimation", dir, 0.6)
    entity.translation = newPosition
end

function Schismatic.findXsotan(findNearest)
    local _entity = Entity()
    local dist = 0
    if findNearest then
        dist = math.huge
    end
    local targetIdx = -1
    local xsotans = {Sector():getEntitiesByScriptValue("is_xsotan")}

    if #xsotans > 0 then
        for idx, xso in pairs(xsotans) do
            local nDist = _entity:getNearestDistance(xso)
            if findNearest then
                if nDist < dist then
                    dist = nDist
                    targetIdx = idx
                end
            else
                if nDist > dist then
                    dist = nDist
                    targetIdx = idx
                end
            end
        end
    else
        return
    end

    return xsotans[targetIdx], dist
end

--endregion

--endregion

--region #CLIENT FUNCTIONS

function Schismatic.updateClient(timeStep)
    if self._Data._IsStunned then
        self.showGlowAndSparks()
    end
end

function Schismatic.showGlowAndSparks()
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

--endregion

--region #LOG / SECURE / RESTORE / SYNC

function Schismatic.Log(methodName, _Msg)
    if self._Debug == 1 then
        print("[Schismatic] - [" .. tostring(methodName) .. "] - " .. tostring(_Msg))
    end
end

function Schismatic.secure()
    local methodName = "Secure"
    self.Log(methodName, "Securing Schismatic._Data")

    self._Data._OverallDamageTaken = _DamageTaken
    self._Data._PhysDamageTaken = _DamageTakenTable[DamageType.Physical]
    self._Data._AntiDamageTaken = _DamageTakenTable[DamageType.AntiMatter]
    self._Data._PlasDamageTaken = _DamageTakenTable[DamageType.Plasma]
    self._Data._EnRGDamageTaken = _DamageTakenTable[DamageType.Energy]
    self._Data._ElecDamageTaken = _DamageTakenTable[DamageType.Electric]

    return self._Data
end

function Schismatic.restore(_Values)
    local methodName = "Restore"
    self.Log(methodName, "Restoring Schismatic._Data")
    self._Data = _Values

    _DamageTaken = Schismatic._Data._OverallDamageTaken
    _DamageTakenTable[DamageType.Physical] =    self._Data._PhysDamageTaken
    _DamageTakenTable[DamageType.AntiMatter] =  self._Data._AntiDamageTaken
    _DamageTakenTable[DamageType.Plasma] =      self._Data._PlasDamageTaken
    _DamageTakenTable[DamageType.Energy] =      self._Data._EnRGDamageTaken
    _DamageTakenTable[DamageType.Electric] =    self._Data._ElecDamageTaken
end

function Schismatic.sync(dataIn)
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