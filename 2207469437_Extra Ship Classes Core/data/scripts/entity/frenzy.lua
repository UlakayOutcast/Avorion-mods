package.path = package.path .. ";data/scripts/lib/?.lua"

include ("randomext")

--namespace Frenzy
Frenzy = {}
local self = Frenzy

self._Data = {}
--[[
self._Data._Active              True/false value that specifies whether or not the script has activated.
self._Data._DamageThreshold     The % health threshold at which this script activates - set this to a decimal value - default is 45% HP (or 0.45)
self._Data._IncreasePerUpdate   The % damage buff given every time this script updates - this buff is ADDIIVE, not multiplicative. Set this to a decimal value Defaults to 5% (0.05)
self._Data._UpdateCycle         How often the damage buff is applied. Default is 10 seconds. Script updates every 5 seconds so this effectively cannot be less than a multiple of 5.
self._Data._EnableUpperLimit    Enables an upper limit to how much this script can buff the damage multiplier of a ship. Defaults to false.
self._Data._UpperLimit          The upper limit of the DAMAGE MULTIPLIER - NOT THE TOTAL FIREPOWER OF THE SHIP - THE DAMAGE MULTIPLIER. Defaults to a meaninglessly high value.
]]

self._Debug = 0

function Frenzy.initialize(_Values)
    self._Data = _Values or {}

    self._Data._Active = false
    self._Data._Timer = 0

    self._Data._DamageThreshold = self._Data._DamageThreshold or 0.5
    self._Data._IncreasePerUpdate = self._Data._IncreasePerUpdate or 0.075
    self._Data._UpdateCycle = self._Data._UpdateCycle or 10
    self._Data._EnableUpperLimit = self._Data._EnableUpperLimit or false
    self._Data._UpperLimit = self._Data._UpperLimit or math.huge

    if onServer() then
        Entity():registerCallback("onDamaged", "onDamaged")
    end
end

function Frenzy.getUpdateInterval()
    return 5
end

function Frenzy.updateServer(_TimeStep)
    local _MethodName = "On Update Server"
    if self._Data._Active then
        self._Data._Timer = self._Data._Timer + _TimeStep
        if self._Data._Timer >= self._Data._UpdateCycle then
            local _Entity = Entity()
            local _DmgFactor = (_Entity.damageMultiplier or 1) + self._Data._IncreasePerUpdate
            local damageLimited = false

            --If the upper limit is enabled, prevent _DmgFactor from going past the factor specified in upper limit.
            if self._Data._EnableUpperLimit then
                _DmgFactor = math.min(_DmgFactor, self._Data._UpperLimit)
                damageLimited = true
            end

            _Entity.damageMultiplier = _DmgFactor
            self._Data._Timer = 0

            self.Log(_MethodName, "Running update cycle - new damage multiplier is : " .. tostring(_DmgFactor))

            broadcastInvokeClientFunction("animation", self._Data._UpdateCycle)

            if not damageLimited and _Entity:hasScript("frenzy.lua") then
                --buff the overdrive script as well.
                _Entity:invokeFunction("data/scripts/entity/frenzy.lua", "frenzyBuff", self._Data._IncreasePerUpdate)
            end
        end
    end
end

function Frenzy.onDamaged(_OwnID, _Amount, _InflictorID)
    local _MethodName = "On Damaged"
    if not self._Data._Active then
        local _Entity = Entity()
        local _Ratio = _Entity.durability / _Entity.maxDurability
    
        if _Ratio < self._Data._DamageThreshold then
            self.Log(_MethodName, "Activating frenzy script.")
            self._Data._Active = true
        end
    end
end

--region #CLIENT functions

function Frenzy.animation(updateCycle)
    local _sector = Sector()
    local _random = random()
    local _entity = Entity()
    local _plan = Plan(_entity)

    local blocks = _plan.numBlocks
    local sparks = math.min(200, blocks)

    local animColor = ColorRGB(1.0, 0.0, 0.0)

    local shortSparkTime = updateCycle * 0.7
    local longSparkTime = updateCycle * 0.9

    for i = 1, sparks do
        local block = _plan:getNthBlock(_random:getInt(0, blocks - 1))

        local center = block.box.center
        local dir = _random:getDirection()
        local factor = 0.5 + _random:getFloat(-0.3, 0.3)
        local size = _entity.radius * 0.1

        _sector:createSpark(center, dir * 4 * factor, size, shortSparkTime, animColor, 0, _entity)

        local factor2 = 0.1
        _sector:createSpark(center, dir * 4 * factor2, size, longSparkTime, animColor, 0, _entity)
    end

    local direction = _random:getDirection()

    _sector:createHyperspaceJumpAnimation(_entity, direction, animColor, 0.2)
end

--endregion

--region #CLIENT / SERVER functions

function Frenzy.Log(_MethodName, _Msg)
    if self._Debug >= 1 then
        print("[Frenzy] - [" .. tostring(_MethodName) .. "] - " .. tostring(_Msg))
    end
end

--endregion

--region #SECURE / RESTORE

function Frenzy.secure()
    local _MethodName = "Secure"
    self.Log(_MethodName, "Securing self._Data")
    return self._Data
end

function Frenzy.restore(_Values)
    local _MethodName = "Restore"
    self.Log(_MethodName, "Restoring self._Data")
    self._Data = _Values
end

--endregion