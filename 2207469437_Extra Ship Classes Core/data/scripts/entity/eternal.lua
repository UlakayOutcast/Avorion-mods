package.path = package.path .. ";data/scripts/lib/?.lua"

include ("randomext")

-- Don't remove or alter the following comment, it tells the game the namespace this script lives in. If you remove it, the script will break.
-- namespace Eternal
Eternal = {}

Eternal._Debug = 0

Eternal._Data = {}
Eternal._Data._RegenFactor = nil
Eternal._Data._DelayRegenWhenHit = nil
Eternal._Data._TimeSinceLastHit = 0
Eternal._Data._HealCharges = 0

function Eternal.initialize(_RegenFactor, _DelayWhenHit)
    local _MethodName = "Initialize"
    Eternal.Log(_MethodName, "Initializing... _RegenFactor is : " .. tostring(_RegenFactor) .. "  _DelayWhenHit is : " .. tostring(_DelayWhenHit))
    _RegenFactor = _RegenFactor or 0.0075
    _DelayWhenHit = _DelayWhenHit or 0

    Eternal._Data._RegenFactor = _RegenFactor
    Eternal._Data._DelayRegenWhenHit = _DelayWhenHit
    Eternal._Data._TimeSinceLastHit = 0
    Eternal._Data._HealCharges = 0

    if onServer() then
        local _Entity = Entity()
        _Entity:registerCallback("onDamaged", "onDamaged")
    end
end

function Eternal.getUpdateInterval()
    return 2 --Update every 2 seconds.
end

function Eternal.updateServer(_TimeStep)
    local _MethodName = "Update Server"
    --Restore percentage of hull determined by _RegenFactor
    Eternal._Data._TimeSinceLastHit = Eternal._Data._TimeSinceLastHit + _TimeStep

    if Eternal._Data._TimeSinceLastHit > Eternal._Data._DelayRegenWhenHit then
        --Build up healing charges. If the entity is not invincible, consume them immediately to heal. Otherwise, stash them for later use.
        Eternal._Data._HealCharges = Eternal._Data._HealCharges + 1

        local entity = Entity()
        if not entity.invincible then
            local entityHull = entity.durability
            local entityMaxHull = entity.maxDurability
    
            if entityHull < entityMaxHull and Eternal._Data._HealCharges > 0 then
                local restoreHull = entityMaxHull * Eternal._Data._RegenFactor * Eternal._Data._HealCharges
                Eternal.Log(_MethodName, "Entity hull of " .. tostring(entityHull) .. " is less than max of " .. tostring(entityMaxHull) .. " & healcharges present - healing for " .. tostring(restoreHull))
                
                entity.durability = math.min(entity.durability + restoreHull, entityMaxHull)
                Eternal._Data._HealCharges = 0
            end
        else
            Eternal.Log(_MethodName, "Entity is invincible - have built up " .. tostring(Eternal._Data._HealCharges) .. " healing charges.")
        end

        --Show animation if we either built up charges OR healed.
        broadcastInvokeClientFunction("animation")
    end
end

function Eternal.onDamaged()
    Eternal._Data._TimeSinceLastHit = 0
end

function Eternal.animation()
    Sector():createHyperspaceJumpAnimation(Entity(), random():getDirection(), ColorRGB(0.0, 1.0, 0.6), 0.2)
end

function Eternal.Log(_MethodName, _Msg)
    if Eternal._Debug == 1 then
        print("[Eternal] - [" .. tostring(_MethodName) .. "] - " .. tostring(_Msg))
    end
end

function Eternal.secure()
    return Eternal._Data
end

function Eternal.restore(_Values)
    Eternal._Data = _Values
end