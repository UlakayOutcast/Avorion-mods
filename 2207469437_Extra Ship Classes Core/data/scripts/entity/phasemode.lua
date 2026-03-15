package.path = package.path .. ";data/scripts/lib/?.lua"

include ("randomext")

-- Don't remove or alter the following comment, it tells the game the namespace this script lives in. If you remove it, the script will break.
-- namespace PhaseMode
PhaseMode = {}
local self = PhaseMode

self.phaseMode = false
self.timeInPhase = 0

self._Debug = 0

function PhaseMode.initialize()
    local methodName = "Initialize"
    self.Log(methodName, "Initializing PhaseMode v1")

    if onServer() then
        Entity():setValue("SDKEDSDisabled", true) --Need to disable SDK extended docking shields.
    end
end

function PhaseMode.getUpdateInterval()
    return 2 --Update every 2 seconds.
end

function PhaseMode.updateServer(timeStep)
    local methodName = "Update Server"

    self.timeInPhase = self.timeInPhase + timeStep
    local entity = Entity()
    local shield = Shield(entity)
    local showAnimation = false
    local activeIronCurtain = entity:getValue("escc_active_ironcurtain")
    -- 30 seconds out, 10 seconds in.
    if self.phaseMode then
        if not activeIronCurtain then
            --In phasemode and no iron curtain active - set ship to invincible.
            entity.invincible = true
            shield.invincible = true
        end

        --blink to give a visual indication of the ship being phased out.
        showAnimation = true

        if self.timeInPhase >= 10 then
            --10 seconds have passed. Flip us to being OUT of the phaseMode.
            self.Log(methodName, "Exiting PhaseMode")
            self.phaseMode = false
            self.timeInPhase = 0
        end
    else
        if not activeIronCurtain then
            --Not in phasemode and no iron curtain active - ship is no longer invincible.
            entity.invincible = false
            shield.invincible = false
        end

        if self.timeInPhase >= 30 then
            --30 seconds have passed. Flip us to being IN the phaseMode.
            self.Log(methodName, "Entering PhaseMode")
            self.phaseMode = true
            self.timeInPhase = 0
        end
    end
    self.Log(methodName, "Enity invincibility is : " .. tostring(entity.invincible))

    if showAnimation then
        broadcastInvokeClientFunction("animation")
    end
end

function PhaseMode.animation()
    local _sector = Sector()
    local _random = random()
    local _entity = Entity()
    local _plan = Plan(_entity)

    local blocks = _plan.numBlocks
    local sparks = math.min(200, blocks)

    local animColor = ColorRGB(0.0, 0.75, 1.0)

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

function PhaseMode.Log(methodName, _Msg)
    if self._Debug == 1 then
        print("[PhaseMode] - [" .. tostring(methodName) .. "] - " .. tostring(_Msg))
    end
end