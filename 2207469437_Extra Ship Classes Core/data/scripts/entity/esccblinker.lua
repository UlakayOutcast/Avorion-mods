package.path = package.path .. ";data/scripts/lib/?.lua"

include ("randomext")
include ("callable")

-- Don't remove or alter the following comment, it tells the game the namespace this script lives in. If you remove it, the script will break.
-- namespace ESCCBlinker
ESCCBlinker = {}
self = ESCCBlinker

self._Debug = 0

self.data = {}

function ESCCBlinker.initialize(values)
    local methodName = "Initizalize"
    self.Log(methodName, "Attaching v7 of ESCC Blinker to enemy.")

    self.data = values or {}

    self.data.blinkCooldown = self.data.binkCooldown or 0 
    self.data.blinkLimit = self.data.blinkLimit or math.huge

    self.data.blinks = 0
    self.data.glow = false

    self.Log(methodName, "Blink limit is " .. tostring(self.data.blinkLimit))

    if onServer() then
        local entity = Entity()
        entity:registerCallback("onHullHit", "onHit")
        entity:registerCallback("onShieldHit", "onHit")
    end
end

function ESCCBlinker.updateServer(timeStep)
    if self.data.blinkCooldown <= 0 then return end
    self.data.blinkCooldown = self.data.blinkCooldown - timeStep

    if self.data.blinks >= self.data.blinkLimit then
        terminate()
        return
    end
end

local glowSize = 0
function ESCCBlinker.updateClient(timeStep)
    -- Glow as indicator for charging the blink
    if self.data.glow == true then
        local _entity = Entity()
        glowSize = math.min(glowSize + timeStep * 1.6, 2.5)

        Sector():createGlow(_entity.translationf, _entity.radius * glowSize, ColorRGB(0.8, 0.5, 0.3))
    else
        glowSize = 0
    end
end

function ESCCBlinker.blink()
    local methodName = "Blink"
    self.Log(methodName, "Blinking")

    local entity = Entity()
    local distance = entity.radius * (2 + random():getFloat(0, 3))
    local direction = random():getDirection()

    self.data.glow = false
    ESCCBlinker.sync()

    broadcastInvokeClientFunction("animation", direction, 0.2)
    entity.translation = dvec3(entity.translationf + direction * distance)
    self.data.blinks = self.data.blinks + 1
end

function ESCCBlinker.animation(direction, intensity)
    Sector():createHyperspaceJumpAnimation(Entity(), direction, ColorRGB(0.6, 0.5, 0.3), intensity)
end

local successiveBlinks = 1
function ESCCBlinker.onHit()
    local methodName = "On Hit"
    self.Log(methodName, "Running onHit")
    -- Quantum Xsotan only blinks after a hit and with reasonable time intervals so it is fun to fight against it
    if self.data.blinkCooldown <= 0 then
        self.Log(methodName, "Blink available.")
        -- Quantum Xsotan can only cascade after a few executed normal blinks and should have the chance to cascade when hit for the first time
        if successiveBlinks > random():getInt(1, 3) then
            self.data.blinkCooldown = random():getFloat(4, 6)
            successiveBlinks = 0

            self.Log(methodName, "deferring cascade")
            -- The cascade has to be deferred because it charges before it gets executed
            deferredCallback(1.5, "cascade", random():getInt(3, 4))
        else
            self.data.blinkCooldown = random():getFloat(3, 5)
            successiveBlinks = successiveBlinks + 1

            self.Log(methodName, "deferring blink")
            -- The blink has to be deferred because it charges before it gets executed
            deferredCallback(1.5, "blink")
        end

        self.data.glow = true
        ESCCBlinker.sync()
    end
end

function ESCCBlinker.cascade(remainingCascades)
    if remainingCascades <= 0 then return end

    deferredCallback(0.4, "cascade", remainingCascades - 1)
    ESCCBlinker.blink()
end

function ESCCBlinker.Log(methodName, msg)
    if self._Debug == 1 then
        print("[ESCCBlinker] - [" .. tostring(methodName) .. "] - " .. tostring(msg))
    end
end

function ESCCBlinker.sync(dataIn)
    if onClient() then
        if not dataIn then
            invokeServerFunction("sync")
        else
            self.data = dataIn
        end
    else
        broadcastInvokeClientFunction("sync", self.data)
    end
end
callable(ESCCBlinker, "sync")
