package.path = package.path .. ";data/scripts/lib/?.lua"

include ("randomext")

-- Don't remove or alter the following comment, it tells the game the namespace this script lives in. If you remove it, the script will break. YES, YOU NEED THIS. MAKE SURE TO COPY IT.
-- namespace Rampage
Rampage = {}
local self = Rampage

self._Debug = 0
self._DebugLevel = 1

self.data = {}

function Rampage.initialize(values)
    local methodName = "initialize"
    self.Log(methodName, "Adding v1 of rampage.lua to entity.")

    self.data = values or {}

    if onServer() then
        local _entity = Entity()

        Boarding(_entity).boardable = false

        if not _restoring then
            self.data.multiplier = self.data.multiplier or 1.5
        else
            self.Log(methodName, "Restoring data from self.restore()")
        end

        if Sector():registerCallback("onDestroyed", "onDestroyed") == 1 then
            self.Log(methodName, "Could not register onEntityDestroyed callback.")
        end
    end
end

--region #SERVER FUNCTIONS

function Rampage.rampageBuff()
    local methodName = "RampageBuff"

    local _entity = Entity()

    self.Log(methodName, "Entity damage multiplier is currently " .. tostring(_entity.damageMultiplier))

    _entity.damageMultiplier = (_entity.damageMultiplier or 1) * self.data.multiplier

    self.Log(methodName, "Entity damage multiplier is now " .. tostring(_entity.damageMultiplier))

    broadcastInvokeClientFunction("animation")
end

--Called in the sector context - we do not have access to Entity() here.
function Rampage.onDestroyed(idx, lastDamageInflictor)
    local methodName = "OnDestroyed"
    self.Log(methodName, "Entity was destroyed. Invoking.")

    local destroyedEntity = Entity(idx)
    if destroyedEntity.type ~= EntityType.Ship and destroyedEntityType ~= EntityType.Station then
        self.Log(methodName, "Destroyed entity type was not a ship or station - returning.")
        return
    end

    local entityDestroyer = Entity(lastDamageInflictor)
    if entityDestroyer:hasScript("rampage.lua") then
        entityDestroyer:invokeFunction("rampage.lua", "rampageBuff")
        if entityDestroyer:hasScript("overdrive.lua") then
            entityDestroyer:invokeFunction("overdrive.lua", "avengerBuff", self.data.multiplier)
        end
    end
end

--endregion

--region #CLIENT FUNCTIONS

function Rampage.animation()
    local _sector = Sector()
    local _entity = Entity()
    local _random = random()

    local dirs = { _random:getDirection(),  _random:getDirection(),  _random:getDirection()}

    for _, dir in pairs(dirs) do
        _sector:createHyperspaceJumpAnimation(_entity, dir, ColorRGB(1.0, 0.0, 0.0), 0.3)
    end
end

-- TODO

--endregion

--region #SECURE / LOG / RESTORE

function Rampage.Log(methodName, msg, logLevel)
    logLevel = logLevel or 1
    if self._Debug == 1 and self._DebugLevel >= logLevel  then
        print("[Rampge] - [" .. methodName .. "] -" .. msg)
    end
end

function Rampage.secure()
    local methodName = "Secure"
    self.Log(methodName, "Securing self.data")
    return self.data
end

function Rampage.restore()
    local methodName = "Restore"
    self.Log(methodName, "Restoring self.data")
    self.data = values
end

--endregion