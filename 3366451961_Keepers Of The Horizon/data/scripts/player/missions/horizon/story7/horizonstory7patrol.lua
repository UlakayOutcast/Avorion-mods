package.path = package.path .. ";data/scripts/lib/?.lua"
include ("stringutility")
include ("randomext")

local waypoints
local current = 1
local stationPoint = 99
local waypointSpread = 2500 -- fly up to 25 km from station.
local cooldown = 0

-- Don't remove or alter the following comment, it tells the game the namespace this script lives in. If you remove it, the script will break.
-- namespace HorizonStory7Patrol
HorizonStory7Patrol = {}

if onServer() then

function HorizonStory7Patrol.getUpdateInterval()
    return math.random() + 1.0
end

function HorizonStory7Patrol.initialize(...)
    if onServer() then
        if not _restoring then
            -- ensure ai state change
            ShipAI():setPassive()
        end
        HorizonStory7Patrol.setWaypoints({...})
    end
end

-- this function will be executed every frame on the server only
function HorizonStory7Patrol.updateServer(timeStep)
    local ai = ShipAI()
    cooldown = cooldown - timeStep

    -- no setting of AI message if auto pilot is active as it would lead to conflicts in ship list
    if not ControlUnit().autoPilotEnabled then
        ai:setStatusMessage("Patrolling Sector /* ship AI status*/"%_T, {})
    end

    -- check if there are enemies
    -- don't attack civil ships
    if ai:isEnemyPresent(false) then
        HorizonStory7Patrol.updateAttacking(timeStep)
    else
        HorizonStory7Patrol.updateFlying(timeStep)
    end

    local _sector = Sector()
    local _entity = Entity()

    -- check if within 10 km of a player ship - if so, send a callback to the sector.
    
    local entities = {_sector:getEntitiesByType(EntityType.Ship)}
    for _, ship in pairs(entities) do
        -- skip controls if the controlled object doesn't belong to a faction
        if not ship.factionIndex then 
            goto continue 
        end
        if ship.factionIndex == 0 then 
            goto continue 
        end

        -- don't control the faction that controls the current sector
        if ship.factionIndex == sectorController then 
            goto continue 
        end

        -- controls only make sense when the target has a cargo bay to control
        if not ship:hasComponent(ComponentType.CargoBay) then 
            goto continue 
        end

        -- don't control self
        if ship.index == _entity.index then 
            goto continue 
        end

        local baseScannerDistance = 1000
        local ownSphere = _entity:getBoundingSphere()

        --If the player's ship has a chameleon, increase this distance
        local chameleonScannerDistance = baseScannerDistance
        local ret, detectionRangeFactor = ship:invokeFunction("internal/dlc/blackmarket/systems/badcargowarningsystem.lua", "getDetectionRangeFactor")
        if ret == 0 then
            chameleonScannerDistance = baseScannerDistance * detectionRangeFactor
        end

        -- make sure the other ship is close enough
        -- reminder: _entity is the current ship, ship is the player ship.
        local testDistance = chameleonScannerDistance + ownSphere.radius + ship.radius
        local d2 = distance2(_entity.translationf, ship.translationf)
        if d2 > testDistance * testDistance then 
            goto continue 
        end

        -- only control ships that belong to a player faction
        local faction = Faction(ship.factionIndex)
        if not valid(faction) or faction.isAIFaction then 
            goto continue 
        end

        if cooldown <= 0 then
            _sector:sendCallback("startHorizon7StealthTimer", _entity.index, ship.index)
            cooldown = 15 --Don't send this callback from this ship for another 15 seconds.
        end

        ::continue::
    end
end

function HorizonStory7Patrol.updateFlying(timeStep)

    if not waypoints or #waypoints == 0 then
        waypoints = {}
        local rnd = Random(Seed(tostring(Entity().id) .. tostring(Server().unpausedRuntime)))

        local maxPoints = rnd:getInt(5, 8)
        stationPoint = rnd:getInt(5, maxPoints)

        local syStations = {Sector():getEntitiesByScriptValue("is_horizon_shipyard")}
        local syStation = nil
        if #syStations > 0 then
            syStation = syStations[1]
        end

        for i = 1, maxPoints do
            if i == stationPoint and syStation then
                table.insert(waypoints, syStation.translationf)
            else
                local v3x = syStation.translationf.x + (rnd:getFloat(-1, 1) * waypointSpread)
                local v3y = syStation.translationf.y + (rnd:getFloat(-1, 1) * waypointSpread)
                local v3z = syStation.translationf.z + (rnd:getFloat(-1, 1) * waypointSpread)

                table.insert(waypoints, vec3(v3x, v3y, v3z))
            end
        end

        current = 1
    end

    local ship = Entity()
    local ai = ShipAI()

    local r = ship:getBoundingSphere().radius
    local d = (r * 2)
    if current == stationPoint then
        d = (r * 8) --4x distance so they don't cluster up around the station.
    end
    local d2 = d * d

    if distance2(ship.translationf, waypoints[current]) < d2 then
        current = current + 1
        if current > #waypoints then
            current = 1
        end
    end

    ai:setFly(waypoints[current], ship:getBoundingSphere().radius)
end

function HorizonStory7Patrol.updateAttacking(timeStep)
    local ai = ShipAI()
    if ai.state ~= AIState.Aggressive then
        if Entity().aiOwned then
            ai:setAggressive()
        else
            ai:setAggressive(false, true)
        end
    end
end

function HorizonStory7Patrol.setWaypoints(waypointsIn)
    waypoints = waypointsIn
    current = 1
end

end
