package.path = package.path .. ";data/scripts/lib/?.lua"

include ("randomext")

-- Don't remove or alter the following comment, it tells the game the namespace this script lives in. If you remove it, the script will break.
-- namespace Avenger
Avenger = {}
local self = Avenger

self._Debug = 0

self._Data = {}

function Avenger.initialize(_Values)
    local methodName = "Initialize"
    self.Log(methodName, "Adding v9 of avenger.lua to entity.")

    self._Data = _Values or {}

    if not _restoring then
        self._Data._Multiplier = self._Data._Multiplier or 1.2
        self._Data._AllowMultiProc = self._Data._AllowMultiProc or false
        self._Data._EnableUpperLimit = self._Data._EnableUpperLimit or false
        self._Data._UpperLimit = self._Data._UpperLimit or math.huge
        --Cannot be set by the player.
        self._Data._Invoked = false
    else
        self.Log(methodName, "Data will be restored.")
    end

    if onServer() then
        if Sector():registerCallback("onDestroyed", "onDestroyed") == 1 then
            self.Log(methodName, "Could not register onEntityDestroyed callback.")
        end
    end
end

--region #SERVER functions

function Avenger.getUpdateInterval()
    return 1
end

function Avenger.updateServer(_TimeStamp)
    self._Data._Invoked = false
end

function Avenger.avengerBuff()
    local methodName = "AvengerBuff"
    if not self._Data._Invoked then
        --If multiple procs in a second are allowed, don't set this to true so it can keep going off.
        if not self._Data._AllowMultiProc then
            self._Data._Invoked = true
        end

        local _entity = Entity()

        self.Log(methodName, "Current damage multiplier is " .. tostring(_entity.damageMultiplier))
    
        local _DamageMultiplier = (_entity.damageMultiplier or 1) * self._Data._Multiplier
        local damageLimited = false

        --If the upper limit is enabled, prevent _DamageMultiplier from going past the factor specified in upper limit.
        if self._Data._EnableUpperLimit then
            _DamageMultiplier = math.min(_DamageMultiplier, self._Data._UpperLimit)
            damageLimited = true
        end

        _entity.damageMultiplier = _DamageMultiplier
    
        self.Log(methodName, "Damage multiplier is now " .. tostring(_DamageMultiplier))

        if not damageLimited and _entity:hasScript("overdrive.lua") then
            self.Log(methodName, "Damage limit is not yet reached - invoking overdrive buff.")
            --buff the overdrive script as well.
            _entity:invokeFunction("data/scripts/entity/overdrive.lua", "avengerBuff", self._Data._Multiplier)
        end
    
        broadcastInvokeClientFunction("animation")
    else
        self.Log(methodName, "Avenger has been invoked recently - waiting 1 second to clear.")
    end
end

--Called in the Sector context.
function Avenger.onDestroyed(_Entityidx, _LastDamageInflictor)
    local methodName = "OnDestroyed"
    self.Log(methodName, "Calling...")

    local _DestroyedEntity = Entity(_Entityidx)
    if _DestroyedEntity.type ~= EntityType.Ship and _DestroyedEntity.type ~= EntityType.Station then
        self.Log(methodName, "Destroyed entity type was not a ship or station - returning.")
        return
    end
    local _TargetFaction = _DestroyedEntity.factionIndex

    local _Ships = {Sector():getEntitiesByFaction(_TargetFaction)}
    for _, _Ship in pairs(_Ships) do
        if _Ship:hasScript("avenger.lua") then
            _Ship:invokeFunction("data/scripts/entity/avenger.lua", "avengerBuff")
        end
    end
end

--endregion

--region #CLIENT functions

function Avenger.animation()
    local _sector = Sector()
    local _entity = Entity()
    local _random = random()

    _sector:createHyperspaceJumpAnimation(_entity, _random:getDirection(), ColorRGB(1.0, 0.4, 0.0), 0.3)
    _sector:createHyperspaceJumpAnimation(_entity, _random:getDirection(), ColorRGB(1.0, 0.6, 0.0), 0.3)
    _sector:createHyperspaceJumpAnimation(_entity, _random:getDirection(), ColorRGB(1.0, 0.6, 0.0), 0.3)
end

--endregion

--region #LOG / SECURE / RESTORE

function Avenger.Log(methodName, _Msg)
    if self._Debug == 1 then
        print("[Avenger] - [" .. tostring(methodName) .. "] - " .. tostring(_Msg))
    end
end

function Avenger.secure()
    local methodName = "Secure"
    self.Log(methodName, "Securing self._Data")
    return self._Data
end

function Avenger.restore(_Values)
    local methodName = "Restore"
    self.Log(methodName, "Restoring self._Data")
    self._Data = _Values
end

--endregion