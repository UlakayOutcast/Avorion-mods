package.path = package.path .. ";data/scripts/lib/?.lua"

include ("randomext")

-- Don't remove or alter the following comment, it tells the game the namespace this script lives in. If you remove it, the script will break.
-- namespace Afterburn
Afterburn = {}
local self = Afterburn

self._Debug = 0

self.data = {}

function Afterburn.initialize(values)
    local methodName = "Initialize"
    self.Log(methodName, "Adding v3 of Afterburn script to enemy.")

    if not _restoring then
        self.Log(methodName, "Not restoring - running normal init.")

        self.data = values or {}

        self.data.accelFactor = self.data.accelFactor or 16
        self.data.velocityFactor = self.data.velocityFactor or 16
        if self.data.incrementOnPhaseOut == nil then
            self.data.incrementOnPhaseOut = false
        end
        self.data.incrementOnPhaseOutValue = self.data.incrementOnPhaseOutValue or 1
    
        self.data.timeInPhase = 0
        self.data.boostMode = false
    else
        self.Log(methodName, "Data will be restored.")
    end
end

function Afterburn.getUpdateInterval()
    return 2 --Update every 2 seconds.
end

function Afterburn.updateServer(_TimeStep)
    local _MethodName = "Update Server"
    self.data.timeInPhase = self.data.timeInPhase + _TimeStep
    local _entity = Entity()
    local _ShowAnimation = false

    --30 seconds out, 20 seconds in.
    if self.data.boostMode then
        if self.data.timeInPhase >= 20 then
            --20 seconds have passed. Flip us to being OUT of the mode
            self.data.boostMode = false
            self.data.timeInPhase = 0

            --If we scale on phase out, add values accordingly:
            if self.data.incrementOnPhaseOut and self.data.incrementOnPhaseOutValue then --Need both to work.
                self.data.accelFactor = self.data.accelFactor + self.data.incrementOnPhaseOutValue
                self.data.velocityFactor = self.data.velocityFactor + self.data.incrementOnPhaseOutValue
            end

            _entity:addKeyedMultiplier(StatsBonuses.Acceleration, 2207469437, 1)
            _entity:addKeyedMultiplier(StatsBonuses.Velocity, 2207469437, 1)

            if self._Debug == 1 then
                --Don't want to do all of this unless we're debugging.
                local _engine = Engine()
                self.Log(_MethodName, "Exiting boost mode. Velocity is " .. tostring(_engine.maxVelocity) .. " Acceleration is " .. tostring(_engine.acceleration))
            end
        else
            --blink to give a visual indication of the ship being in MAXIMUM Afterburn
            _ShowAnimation = true
        end
    else
        if self.data.timeInPhase >= 30 then
            --30 seconds have passed. Flip us to being IN the mode.
            self.data.boostMode = true
            self.data.timeInPhase = 0

            self.Log(_MethodName, "Setting bonus - final velocity is " .. tostring(self.data.velocityFactor) .. " Final accel is " .. tostring(self.data.accelFactor))

            _entity:addKeyedMultiplier(StatsBonuses.Acceleration, 2207469437, self.data.accelFactor)
            _entity:addKeyedMultiplier(StatsBonuses.Velocity, 2207469437, self.data.velocityFactor)

            if self._Debug == 1 then
                --Don't want to do all of this unless we're debugging.
                local _engine = Engine()
                self.Log(_MethodName, "Entering boost mode. Velocity is " .. tostring(_engine.maxVelocity) .. " Acceleration is " .. tostring(_engine.acceleration))
            end

            _ShowAnimation = true
        end
    end

    if _ShowAnimation then
        broadcastInvokeClientFunction("animation")
    end
end

function Afterburn.animation()
    local _sector = Sector()
    local _random = random()
    local _entity = Entity()
    local _plan = Plan(_entity)

    local blocks = _plan.numBlocks
    local sparks = math.min(200, blocks)

    local animColor = ColorRGB(1.0, 1.0, 0.0)

    for i = 1, sparks do
        local block = _plan:getNthBlock(_random:getInt(0, blocks - 1))

        local center = block.box.center
        local dir = _random:getDirection()
        local factor = 1 + _random:getFloat(-3, 3)
        local size = _entity.radius * 0.075

        _sector:createSpark(center, dir * 4 * factor, size, 2.25, animColor, 0, _entity)

        local factor2 = 0.5
        _sector:createSpark(center, dir * 4 * factor2, size, 2.5, animColor, 0, _entity)
    end

    local direction = _random:getDirection()

    _sector:createHyperspaceJumpAnimation(_entity, direction, animColor, 0.2)
end

--region #LOG / SECURE / RESTORE

function Afterburn.Log(_MethodName, _Msg)
    if self._Debug == 1 then
        print("[Afterburn] - [" .. tostring(_MethodName) .. "] - " .. tostring(_Msg))
    end
end

function Afterburn.secure()
    local _MethodName = "Secure"
    self.Log(_MethodName, "Securing self.data")
    return self.data
end

function Afterburn.restore(_Values)
    local _MethodName = "Restore"
    self.Log(_MethodName, "Restoring self.data")
    self.data = _Values
end

--endregion