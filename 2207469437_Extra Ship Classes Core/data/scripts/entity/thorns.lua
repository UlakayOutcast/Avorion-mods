package.path = package.path .. ";data/scripts/lib/?.lua"

include ("randomext")

-- Don't remove or alter the following comment, it tells the game the namespace this script lives in. If you remove it, the script will break.
-- namespace Thorns
Thorns = {}
local self = Thorns

self._Debug = 0
self._DebugLevel = 1

self._Data = {}
--self._Data._MaxTimeInPhase        Sets the maximum amount of time the script can spend in the phase where it is calculating / reflecting damage. Defaults to 20 seconds.
--self._Data._MaxTimeOutOfPhase     Sets the maximum amount of time between the script being active. Defaults to 30 seconds.
--self._Data._DamageFrequency       Sets the interval where the thorns damage is bounced back at the target. Defaults to 10 seconds. Cannot be meaningfully set to less than 2 seconds.
--self._Data._TimeInPhase           Tracks the amount of time the script has been in the active phase.
--self._Data._DamageTimeTracker     Tracks the amount of time since the last time the script has bounced damage.
--self._Data._ThornsMode            Tracks whether thorns mode is currently active.
--self._Data._ThornsMultiplier      Sets the multiplier for how much damage is reflected. Defaults to 0.25 or 25%

self._ThornsDamage = {}

function Thorns.initialize(_Values)
    local methodName = "Initialize"
    local _Entity = Entity()
    self.Log(methodName, "Adding v10 of thorns.lua to entity.")

    self._Data = _Values or {}

    self._Data._MaxTimeInPhase = self._Data._MaxTimeInPhase or 20
    self._Data._MaxTimeOutOfPhase = self._Data._MaxTimeOutOfPhase or 30
    self._Data._ThornsMultiplier = self._Data._ThornsMultiplier or 0.25
    self._Data._DamageFrequency = self._Data._DamageFrequency or 10
    --Cannot be set by the player
    self._Data._TimeInPhase = 0
    self._Data._DamageTimeTracker = 0
    self._Data._ThornsMode = false

    self._ThornsDamage = {}

    --Need to register a callback for taking damage.
    if onServer() then
        if _Entity:registerCallback("onShieldDamaged", "onShieldDamaged") == 1 then
            self.Log(methodName, "Could not attach onShieldDamaged callback.")
        end
        if _Entity:registerCallback("onDamaged", "onDamaged") == 1 then
            self.Log(methodName, "Could not attach onDamaged callback.")
        end
    end

    if self._Debug == 1 then
        for _idx, _val in pairs(self._Data) do
            self.Log(methodName, "_idx : " .. tostring(_idx) .. " _val : " .. tostring(_val), 2)
        end
    end
end

function Thorns.getUpdateInterval()
    return 2 --Update every 2 seconds.
end

function Thorns.updateServer(_TimeStep)
    local methodName = "Update Server"
    self._Data._TimeInPhase = self._Data._TimeInPhase + _TimeStep
    self._Data._DamageTimeTracker = self._Data._DamageTimeTracker + _TimeStep
    local _ShowAnimation = false
    
    if self._Data._ThornsMode then
        --Discharge all stored damage. Should happen evey 10 seconds in the mode.
        if self._Data._DamageTimeTracker >= self._Data._DamageFrequency then
            self.bounceDamage()
            self._Data._DamageTimeTracker = 0
        end

        if self._Data._TimeInPhase >= self._Data._MaxTimeInPhase then
            self._Data._ThornsMode = false
            self._Data._TimeInPhase = 0
            self._Data._DamageTimeTracker = 0
            self.Log(methodName, "Swapping modes. Thorns mode is now off.")
        else
            --blink to give a visual indication of the ship being in MAXIMUM Thorns
            _ShowAnimation = true
        end
    else
        if self._Data._TimeInPhase >= self._Data._MaxTimeOutOfPhase then
            --Flip us to being IN the mode.
            self._Data._ThornsMode = true
            self._Data._TimeInPhase = 0
            self._Data._DamageTimeTracker = 0
            _ShowAnimation = true
            self.Log(methodName, "Swapping modes. Thorns mode is now on.")
        end
    end

    if _ShowAnimation then
        broadcastInvokeClientFunction("animation")
    end
end

function Thorns.animation(direction)
    local _sector = Sector()
    local _random = random()
    local _entity = Entity()
    local _plan = Plan(_entity)

    local blocks = _plan.numBlocks
    local sparks = math.min(200, blocks)

    local animColor = ColorRGB(0.0, 1.0, 0.25)

    for i = 1, sparks do
        local block = _plan:getNthBlock(_random:getInt(0, blocks - 1))

        local center = block.box.center
        local dir = _random:getDirection()
        local factor = 0.5 + _random:getFloat(-0.3, 0.3)
        local size = _entity.radius * 0.1

        _sector:createSpark(center, dir * 4 * factor, size, 2.25, animColor, 0, _entity)

        local factor2 = 0.1
        _sector:createSpark(center, dir * 4 * factor2, size, 2.5, animColor, 0, _entity)
    end

    local direction = _random:getDirection()

    _sector:createHyperspaceJumpAnimation(_entity, direction, animColor, 0.2)
end

--region #SERVER FUNCTIONS

function Thorns.onShieldDamaged(_ObjectIndex, _Amount, _DamageType, _InflictorID)
    local methodName = "On Shield Damaged"
    --Don't turn this on unless you're okay with a fckton of messages.
    --self.Log(methodName, "Running On Shield Damage callback - damage amount is " .. tostring(_Amount) .. " and damage type is " .. tostring(_DamageType))
    if not _Amount or not self._Data._ThornsMode then
        return
    else
        local _amt = _Amount * self._Data._ThornsMultiplier

        local _targetidx = -1

        for _idx, _val in pairs(self._ThornsDamage) do
            if _val._itemid == _InflictorID then
                _targetidx = _idx
            end
        end

        if _targetidx == -1 then
            table.insert(self._ThornsDamage, { _itemid = _InflictorID, _thornsfor = _amt})
        else
            self._ThornsDamage[_targetidx]._thornsfor = self._ThornsDamage[_targetidx]._thornsfor + _amt
        end
    end
end

function Thorns.onDamaged(_ObjectIndex, _Amount, _Inflictor, _DamageSource, _DamageType)
    local methodName = "On Damaged"
    --Don't turn this on unless you're okay with a fckton of messages.
    --self.Log(methodName, "Running on Damaged callback - damage amount is " .. tostring(_Amount) .. " and damage type is " .. tostring(_DamageType))

    local _InflictorID = _Inflictor
    
    if not _Amount or not self._Data._ThornsMode then
        return
    else
        local _amt = _Amount * self._Data._ThornsMultiplier

        local _targetidx = -1

        for _idx, _val in pairs(self._ThornsDamage) do
            if _val._itemid == _InflictorID then
                _targetidx = _idx
            end
        end

        if _targetidx == -1 then
            table.insert(self._ThornsDamage, { _itemid = _InflictorID, _thornsfor = _amt})
        else
            self._ThornsDamage[_targetidx]._thornsfor = self._ThornsDamage[_targetidx]._thornsfor + _amt
        end
    end
end

function Thorns.bounceDamage()
    local methodName = "Bounce Damage"
    self.Log(methodName, "Damaging " .. tostring(#self._ThornsDamage) .. " enemies.")

    local _Me = Entity()
    local _MyPosition = _Me.translationf
    local _MyID = _Me.id

    for _, _vals in pairs(self._ThornsDamage) do
        local _Entity = Entity(_vals._itemid)
        local _dmg = _vals._thornsfor

        if _Entity and valid(_Entity) and _dmg > 0 then

            local _Shield = Shield(_vals._itemid)
            local _Dura = Durability(_vals._itemid)
            local _TargetPosition = _Entity.translationf

            if _Shield then
                --Do as much damage as possible to the shield, then hit the hull for the remaining damage.
                self.Log(methodName, "Found target. Inflicting " .. tostring(_dmg) .. " damage to " .. tostring(_Entity.name))
                local _ShieldDamage = _dmg
                local _HullDamage = 0
                if _Shield.durability < _dmg then
                    _ShieldDamage = _Shield.durability
                    _HullDamage = _dmg - _ShieldDamage
                end
                self.Log(methodName, tostring(_ShieldDamage) .. " damage to " .. tostring(_Entity.name) .. " shield")
                _Shield:inflictDamage(_ShieldDamage, 1, DamageType.Energy, _MyPosition, _MyID)
                if _HullDamage > 0 then
                    self.Log(methodName, tostring(_HullDamage) .. " damage to " .. tostring(_Entity.name) .. " hull")
                    _Dura:inflictDamage(_HullDamage, 1, DamageType.Energy, _MyID)
                end
            else
                if _Dura then
                    --Do everything to the hull.
                    self.Log(methodName, "Found target. Inflicting " .. tostring(_dmg) .. " damage to " .. tostring(_Entity.name))
                    _Dura:inflictDamage(_dmg, 1, DamageType.Energy, _MyID)
                end
            end
    
            --Draw a laser
            self.createLaser(_MyPosition, _TargetPosition)
        end
    end

    self._ThornsDamage = {} --Dump the table and make a new one.
end

--endregion

--region #CLIENT / SERVER functions

function Thorns.createLaser(_From, _To)
    if onServer() then
        broadcastInvokeClientFunction("createLaser", _From, _To)
        return
    end

    local _Color = ColorRGB(0.0, 1.0, 0.25)

    local _Sector = Sector()
    local _Laser = _Sector:createLaser(_From, _To, _Color, 8)

    _Laser.maxAliveTime = 0.8
    _Laser.collision = false
end

--endregion

--region #LOG / SECURE / RESTORE

function Thorns.Log(methodName, _Msg, _RequireDebugLevel)
    _RequireDebugLevel = _RequireDebugLevel or 1

    if self._Debug == 1 and self._DebugLevel >= _RequireDebugLevel then
        print("[Thorns] - [" .. tostring(methodName) .. "] - " .. tostring(_Msg))
    end
end

function Thorns.secure()
    local methodName = "Secure"
    self.Log(methodName, "Securing self._Data")
    return self._Data
end

function Thorns.restore(_Values)
    local methodName = "Restore"
    self.Log(methodName, "Restoring self._Data")
    self._Data = _Values
end

--endregion