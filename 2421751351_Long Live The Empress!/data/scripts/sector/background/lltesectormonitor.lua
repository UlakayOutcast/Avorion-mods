package.path = package.path .. ";data/scripts/lib/?.lua"

--namespace LLTESectorMonitor
LLTESectorMonitor = {}
local self = LLTESectorMonitor

self._Debug = 0

function LLTESectorMonitor.initialize()
    local _MethodName = "Initailize"
    self.Log(_MethodName, "Beginning...")
end

function LLTESectorMonitor.clearMissionAssets(_X, _Y, _DeleteOtherAssets, _DeleteEverything)
    --We can't use sector/deleteentitiesonplayerleft.lua (Which is my new best friend.)
    local _MethodName = "Clear Pirates"
    _DeleteAsteroids = _DeleteAsteroids or false

    self.Log(_MethodName, "Invoked...")
    local _Pirates = {Sector():getEntitiesByScriptValue("is_pirate")}
    if not _Pirates then 
        self.Log(_MethodName, "WARNING - _Pirates is nil")
    end

    local _Xsotan = {Sector():getEntitiesByScriptValue("is_xsotan")}
    if not _Xsotan then 
        self.Log(_MethodName, "WARNING - _Xsotan is nil")
    end

    self.Log(_MethodName, "Iterating through and clearing out all pirates.")
    for _, _P in pairs(_Pirates) do
        Sector():deleteEntity(_P)
    end

    self.Log(_MethodName, "Iterating through and clearing out all xsotan.")
    for _, _X in pairs(_Xsotan) do
        Sector():deleteXsotan(_X)
    end

    self.Log(_MethodName, "Removing defense / shipment controller scripts.")
    if Sector():hasScript("sector/background/defensecontroller.lua") then
        Sector():removeScript("sector/background/defensecontroller.lua")
    end

    if Sector():hasScript("sector/background/shipmentcontroller.lua") then
        Sector():removeScript("sector/background/shipmentcontroller.lua")
    end

    if _DeleteOtherAssets then
        self.Log(_MethodName, "Deleting all other non player-owned assets")
        local _EntityTypes = { EntityType.Ship, EntityType.Station, EntityType.Torpedo, EntityType.Fighter }
        if _DeleteEverything then
            self.Log(_MethodName, "Adding all other permanent entities to deletion table.")
            table.insert(_EntityTypes, EntityType.Wreckage)
            table.insert(_EntityTypes, EntityType.Asteroid)
            table.insert(_EntityTypes, EntityType.Unknown)
            table.insert(_EntityTypes, EntityType.Other)
            table.insert(_EntityTypes, EntityType.Loot)
            table.insert(_EntityTypes, EntityType.Container)
            table.insert(_EntityTypes, EntityType.WormHole)
        end
        for _, _EntityType in pairs(_EntityTypes) do
            for _, _En in pairs({Sector():getEntitiesByType(_EntityType)}) do
                if _En.playerOwned or _En.allianceOwned then
                    self.Log(_MethodName, "Found player or alliance owned entity. This will not be auto-cleaned.")
                else
                    Sector():deleteEntity(_En)
                end
            end
        end
    end
end

--region #CLIENT / SERVER CALLS

function LLTESectorMonitor.Log(_MethodName, _Msg, _OverrideDebug)
    local _TempDebug = self._Debug
    if _OverrideDebug then self._Debug = _OverrideDebug end
    if self._Debug and self._Debug == 1 then
        print("[LLTE Sector Monitor] - [" .. _MethodName .. "] - " .. _Msg)
    end
    if _OverrideDebug then self._Debug = _TempDebug end
end

--endregion