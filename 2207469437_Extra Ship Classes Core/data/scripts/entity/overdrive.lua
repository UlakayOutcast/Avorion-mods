package.path = package.path .. ";data/scripts/lib/?.lua"

include ("randomext")

-- Don't remove or alter the following comment, it tells the game the namespace this script lives in. If you remove it, the script will break.
-- namespace Overdrive
Overdrive = {}
local self = Overdrive

self._Debug = 0

self.data = {}

function Overdrive.initialize(values)
    local methodName = "Initialize"
    self.Log(methodName, "Adding v2 of Overdrive script to enemy.")

    if not _restoring then
        self.Log(methodName, "Not restoring - running normal init.")

        self.data = values or {}

        self.data.overdriveMultiplier = self.data.overdriveMultiplier or 2
        if self.data.incrementOnPhaseOut == nil then
            self.data.incrementOnPhaseOut = false
        end
        self.data.incrementOnPhaseOutValue = self.data.incrementOnPhaseOutValue or 1

        self.data.timeInPhase = 0
        self.data.attackMode = false
        self.data.lowDamageMultiplier = nil
        self.data.highDamageMultiplier = nil
    else
        self.Log(methodName, "Values will be restored")
    end
end

function Overdrive.getUpdateInterval()
    return 2 --Update every 2 seconds.
end

function Overdrive.updateServer(_TimeStep)
    local methodName = "Update Server"
    self.data.timeInPhase = self.data.timeInPhase + _TimeStep
    local _Entity = Entity()
    local _ShowAnimation = false
    
    if not self.data.lowDamageMultiplier then
        --Get the multiplier on the first update of the server.
        local _Multiplier = (_Entity.damageMultiplier or 1)
        self.Log(methodName, "Entity damage multplier is " .. tostring(_Entity.damageMultiplier))
        self.data.lowDamageMultiplier = _Multiplier
        self.data.highDamageMultiplier = _Multiplier * self.data.overdriveMultiplier
    end

    --30 seconds out, 20 seconds in.
    if self.data.attackMode then
        if self.data.timeInPhase >= 20 then
            --20 seconds have passed. Flip us to being OUT of the mode
            self.data.attackMode = false
            self.data.timeInPhase = 0

            if self.data.incrementOnPhaseOut and self.data.incrementOnPhaseOutValue then --Need both to work.
                self.data.overdriveMultiplier = self.data.overdriveMultiplier + self.data.incrementOnPhaseOutValue
                local newHighMultiplier = self.data.lowDamageMultiplier * self.data.overdriveMultiplier
                self.data.highDamageMultiplier = math.max(newHighMultiplier, self.data.highDamageMultiplier)

                self.Log(methodName, "Incrementing on phase out - new high damage multiplier is now " .. tostring(self.data.highDamageMultiplier))
            end

            _Entity.damageMultiplier = self.data.lowDamageMultiplier
            self.Log(methodName, "Swapping modes. Entity damage multiplier is now " .. tostring(_Entity.damageMultiplier))
        else
            --blink to give a visual indication of the ship being in MAXIMUM OVERDRIVE
            _ShowAnimation = true
        end
    else
        if self.data.timeInPhase >= 30 then
            --30 seconds have passed. Flip us to being IN the mode.
            self.data.attackMode = true
            self.data.timeInPhase = 0

            _Entity.damageMultiplier = self.data.highDamageMultiplier
            _ShowAnimation = true
            self.Log(methodName, "Swapping modes. Entity damage multiplier is now " .. tostring(_Entity.damageMultiplier))
        end
    end

    if _ShowAnimation then
        broadcastInvokeClientFunction("animation")
    end
end

function Overdrive.avengerBuff(_Multiplier)
    self.data.lowDamageMultiplier = self.data.lowDamageMultiplier * _Multiplier
    self.data.highDamageMultiplier = self.data.highDamageMultiplier * _Multiplier
end

function Overdrive.frenzyBuff(_Adder)
    self.data.lowDamageMultiplier = self.data.lowDamageMultiplier + _Adder
    self.data.highDamageMultiplier = self.data.highDamageMultiplier + (_Adder * self.data.overdriveMultiplier)
end

function Overdrive.animation()
    local _sector = Sector()
    local _random = random()
    local _entity = Entity()
    local _plan = Plan(_entity)

    local blocks = _plan.numBlocks
    local sparks = math.min(200, blocks)

    local animColor = ColorRGB(1.0, 0.0, 0.0)

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

--region #CLIENT / SERVER functions

function Overdrive.Log(methodName, _Msg)
    if self._Debug == 1 then
        print("[Overdrive] - [" .. tostring(methodName) .. "] - " .. tostring(_Msg))
    end
end

--endregion

--region #SECURE / RESTORE

function Overdrive.secure()
    local methodName = "Secure"
    self.Log(methodName, "Securing self.data")
    return self.data
end

function Overdrive.restore(values)
    local methodName = "Restore"
    self.Log(methodName, "Restoring self.data")
    self.data = values
end

--endregion