package.path = package.path .. ";data/scripts/lib/?.lua"
package.path = package.path .. ";data/scripts/?.lua"

--namespace HyperAggro
HyperAggro = {}
local self = HyperAggro

self._Debug = 0

function HyperAggro.initialize()
    local _MethodName = "Intialize"
    self.Log(_MethodName, "Running...")

    if onServer() then
        self.declareWar()
    end
end

function HyperAggro.getUpdateInterval()
    return 10
end

function HyperAggro.updateServer(_TimeStep)
    local _MethodName = "Update Server"
    self.Log(_MethodName, "Running...")
    self.declareWar()
end

function HyperAggro.declareWar()
    local _MethodName = "Declare War"
    self.Log(_MethodName, "Running...")
    --Declare war on every present player / alliance every 10 seconds.
    local _Entity = Entity()
    local _EntityFaction = Faction(_Entity.factionIndex)
    local _Galaxy = Galaxy()
    local _Factions = {Sector():getPresentFactions()}
    for _, _Factionidx in pairs(_Factions) do
        local _Faction = Faction(_Factionidx)
        if _Faction.index ~= _Entity.factionIndex and (_Faction.isPlayer or _Faction.isAlliance) then
            self.Log(_MethodName, "Checking relations between faction : " .. tostring(_EntityFaction.name) .. " and faction : " .. tostring(_Faction.name))
            local _Relations = _EntityFaction:getRelation(_Faction.index)
            if _Relations.status ~= RelationStatus.War then
                self.Log(_MethodName, "Relations not at war - declaring war.")
                _Galaxy:setFactionRelations(_EntityFaction, _Faction, -100000)
                _Galaxy:setFactionRelationStatus(_EntityFaction, _Faction, RelationStatus.War)
            end

            ShipAI(_Entity.id):registerEnemyFaction(_Faction.index)
        end
    end
end

function HyperAggro.Log(_MethodName, _Msg)
    if self._Debug == 1 then
        print("[HyperAggro] - [" .. tostring(_MethodName) .. "] - " .. tostring(_Msg))
    end
end
