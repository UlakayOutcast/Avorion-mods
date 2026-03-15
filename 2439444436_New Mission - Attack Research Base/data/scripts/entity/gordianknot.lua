package.path = package.path .. ";data/scripts/lib/?.lua"
package.path = package.path .. ";data/scripts/?.lua"

--namespace GordianKnot
GordianKnot = {}
local self = GordianKnot

self._Debug = 0

function GordianKnot.initialize()
    Entity():removeScript("entitydbg.lua")
    Entity():removeScript("esccdbg.lua")
end

function GordianKnot.getUpdateInterval()
    return 1
end

function GordianKnot.updateServer(_TimeStep)
    local _Sector = Sector()
    --AKA The "no devmode" script.
    Entity():removeScript("entitydbg.lua")
    Entity():removeScript("esccdbg.lua")
    if not Entity():hasScript("gordianknotbehavior.lua") then
        Entity():addScriptOnce("gordianknotbehavior.lua")
    end

    local _Ships = {_Sector:getEntitiesByType(EntityType.Ship)}
    for _, _Ship in pairs(_Ships) do
        if _Ship.playerOwned or _Ship.allianceOwned then
            _Ship.invincible = false
            local _Shield = Shield(_Ship)
            if _Shield then
                _Shield.invincible = false
            end
            local _Dura = Durability(_Ship)
            if _Dura then
                _Dura.invincible = false
                _Dura.invincibility = 0.0
            end
        end
    end
    local _Stations = {_Sector:getEntitiesByType(EntityType.Station)}
    for _, _Station in pairs(_Stations) do
        _Station.invincible = false
        local _Shield = Shield(_Station)
        if _Shield then
            _Shield.invincible = false
        end
        local _Dura = Durability(_Station)
        if _Dura then
            _Dura.invincible = false
            _Dura.invincibility = 0.0
        end
    end
end

function GordianKnot.Log(_MethodName, _Msg)
    if self._Debug == 1 then
        print("[GordianKnot] - [" .. tostring(_MethodName) .. "] - " .. tostring(_Msg))
    end
end
