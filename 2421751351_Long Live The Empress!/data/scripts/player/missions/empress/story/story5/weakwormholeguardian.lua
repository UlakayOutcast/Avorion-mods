package.path = package.path .. ";data/scripts/lib/?.lua"

include ("randomext")
include ("stringutility")
include ("callable")
local SectorGenerator = include ("SectorGenerator")
local Xsotan = include ("story/xsotan")
local Placer = include ("placer");
local AsyncShipGenerator = include("asyncshipgenerator")
ESCCUtil = include("esccutil")

-- Don't remove or alter the following comment, it tells the game the namespace this script lives in. If you remove it, the script will break.
-- namespace WeakWormholeGuardian
WeakWormholeGuardian = {}
local self = WeakWormholeGuardian

self._SpawnTimer = 0

function WeakWormholeGuardian.initialize()
    if onClient() then
        Music():fadeOut(1.5)
        registerBoss(Entity().index, nil, nil, "data/music/special/guardian.ogg")
    end

    if onServer() then
        ShipAI():setAggressive()
    end
end

function WeakWormholeGuardian.getUpdateInterval()
    return 0.25
end

function WeakWormholeGuardian.spawnAllies()
    local _MaxXsotan = 20
    local _MaxSpawn = 5
    
    local _Spawned = {}
    local _LocalXsotan = ESCCUtil.countEntitiesByValue("is_xsotan")
    local _Generator = SectorGenerator(Sector():getCoordinates())
    local _Dist = 500

    if _LocalXsotan < _MaxXsotan then
        local _XsotanToSpawn = _MaxXsotan - _LocalXsotan
        _XsotanToSpawn = math.min(_XsotanToSpawn, _MaxSpawn)
        --print("Spawning " .. tostring(_XsotanToSpawn) .. " Xsotan")

        for _ = 1, _XsotanToSpawn do
            local _Xsotan = Xsotan.createShip(_Generator:getPositionInSector(_Dist), 1.0)
            table.insert(_Spawned, _Xsotan)
        end
    end

    Placer.resolveIntersections(_Spawned)
end

function WeakWormholeGuardian.aggroAllies()
    local ownIndex = Entity().factionIndex

    local sector = Sector()
    local allies = {sector:getEntitiesByFaction(ownIndex)}
    local factions = {sector:getPresentFactions()}

    for _, ally in pairs(allies) do
        if ally:hasComponent(ComponentType.Plan) and ally:hasComponent(ComponentType.ShipAI) then

            local ai = ShipAI(ally.index)
            for _, factionIndex in pairs(factions) do
                if factionIndex ~= ownIndex then
                    ai:registerEnemyFaction(factionIndex)
                end
            end
        end
    end

    return false
end

function WeakWormholeGuardian.updateServer(_TimeStep)
    self._SpawnTimer = self._SpawnTimer - _TimeStep

    if self._SpawnTimer <= 0 then
        --print("Spawning allies")
        self.spawnAllies()
        self._SpawnTimer = 60
    end

    self.aggroAllies()
end
