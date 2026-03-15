package.path = package.path .. ";data/scripts/lib/?.lua"
package.path = package.path .. ";lib/entitydbg.lua"
package.path = package.path .. ";data/scripts/server/?.lua"
include("stringutility")
include("randomext")

-- Before submiting any requests for assistance with errors, please uncomment the print lines. Launch your single player world and try to use the scrip (i.e.shoot torpedoes) the errors messages will help figure out what's going wrong. I appreciate your feedback and suggestions as this is my first mod.

-- namespace SerinaAI
SerinaAI = {}

if onServer() then --enabled multiplayer support (i think? I've not tried it)...
--initialize all variables
local entity = {}
local firingShip = {}
local torpedoTargetingCPU = {}
local foxTwo = {}
local rockTargets = {}
local wreckTargets = {}
local hostileTargets = {}
local shipsInSector = {}
local isEnemy = {}
local player = Player()

-- Initialization: The initialize() function is called to set up the script. It registers a callback for when a torpedo is launched (onTorpedoLaunched).
function SerinaAI.initialize()
if player then
Server():registerCallback("onPlayerLogIn","yellowAlert")
Sector():registerCallback("onPlayerEntered","yellowAlert")
Entity():registerCallback("onTorpedoLaunched", "shotsFired")
end
end
-- Initialization logic and callback registration
function SerinaAI.yellowAlert()
	SerinaAI.sectorSweep()
end
-- Helper function to bridge the callback and multiple other function calls before retargeting
function SerinaAI.shotsFired(entityId, torpedoId)
    firingShip = Entity(entityId)
    torpedoTargetingCPU = TorpedoAI(torpedoId)
    foxTwo = Torpedo(torpedoId)
	if not firingShip.playerOrAllianceOwned then return print("SerinaAI: Fuck off AI scum!")end
	torpedoTargetingCPU.target = SerinaAI.nextHostile()
end

-- Sector Sweep: The sectorSweep() function populates lists of potential targets, including wreckage and asteroids. Separated all calls to unique functions to reduce overhead and improve efficiency of script.
function SerinaAI.sectorSweep()
	shipsInSector = {Sector():getEntitiesByType(EntityType.Ship)}
    SerinaAI.getRocks()
    if #rockTargets > 0 then
        print("SerinaAI: Asteroid solutions acquired")
    else
        print("SerinaAI: No asteroids found")
    end
    
    SerinaAI.getWrecks()
    if #wreckTargets > 0 then
        print("SerinaAI: Wreckage solutions plotted")
    else
        print("SerinaAI: No wreckage found")
    end
    
    SerinaAI.pingShips()
    if #hostileTargets > 0 then
        print("SerinaAI: Firing solutions locked in on all targets.")
    else
        print("SerinaAI: No hostile forces detected")
    end
	if #rockTargets == 0 and #wreckTargets == 0 and #hostileTargets == 0 then
        print("SerinaAI: We, who are about to die, salute you Captain o7 \n \n *Taps begins to play*")
    end
end


-- Hostile Targeting: The getRocks() function identifies Asteroids in the sector and adds them to the rockTargets list.  Only called in initial sectorSweep()
function SerinaAI.getRocks()
	 -- Populate asteroid list
    rockTargets = {Sector():getEntitiesByType(EntityType.Asteroid)}
    if not rockTargets then
        print("SerinaAI Error: Failed to retrieve asteroid entities.")
		rockTargets = {} -- Reset to an empty list to avoid potential issues
	end
end

-- Hostile Targeting: The getWrecks() function identifies Wrecks in the sector and adds them to the wreckTargets list. Called in initial sectorSweep() as well as in allOtherTargets() to account for recently destroyed hostiles
function SerinaAI.getWrecks()
	-- Populate wreckage list
    wreckTargets = {Sector():getEntitiesByType(EntityType.Wreckage)}
    if not wreckTargets then
        print("Error: Failed to retrieve wreckage entities.")
        wreckTargets = {} -- Reset to an empty list to avoid potential issues
	end
end

function SerinaAI.pingShips()
    -- Ensure firingShip is valid
    if not firingShip then
        print("SerinaAI Error: Firing ship not found.")
        return
    end

    -- Populate hostileTargets with all targets after initial scan
    local shipsInSector = {Sector():getEntitiesByType(EntityType.Ship)}
    for _, ship in pairs(shipsInSector) do
		table.insert(hostileTargets, {id = ship.id, distance = shipDistance})
    end
end


function SerinaAI.rePingHostile()
    -- Reset target list just in case
    hostileTargets = {}

    -- Ensure firingShip is valid
    if not firingShip then
        print("SerinaAI Error: Firing ship not found.")
        return
    end

    -- Populate primary targets: hostiles
    local shipsInSector = {Sector():getEntitiesByType(EntityType.Ship)}
    for _, ship in pairs(shipsInSector) do
        local shipAI = ShipAI(ship) --access targeting computer of other ship
        local shipDistance = ship:getNearestDistance(firingShip)
        isEnemy = shipAI:isEnemy(firingShip) --if ship sees player as hostile        
        -- Check if the ship is an enemy
        if isEnemy then
            table.insert(hostileTargets, {id = ship.id, distance = shipDistance})
        end
    end
end


-- Next Hostile Target: The nextHostile() function selects the next hostile target within firing range (75% of max range). It shuffles the list of hostile targets and selects the first one within range.
function SerinaAI.nextHostile()
    local torpedoTemplate = foxTwo:getTemplate()
    local firingRange = torpedoTemplate.reach * 0.75
    local randomIndex = math.random(1, #hostileTargets)
    local indices = {}

    -- Populate indices table
    for i = 1, #hostileTargets do
        table.insert(indices, i)
    end

    -- Shuffle the indices
    for i = #indices, 2, -1 do
        local j = randomext.createRandom():randi(1, i)
        indices[i], indices[j] = indices[j], indices[i]
    end

-- Iterate through shuffled indices
for _, index in ipairs(indices) do
    local targetCandidate = hostileTargets[index]

    -- Check if targetCandidate distance is within firing range
    if targetCandidate.distance <= firingRange then
        print("SerinaAI Target selected, distance :", targetCandidate.distance)
        print("SerinaAI Firing Range : ", firingRange, "   Max Range: ", torpedoTemplate.reach) 
        table.insert(shotFired, targetCandidate)
        table.remove(hostileTargets, index)
        print("SerinaAI Target:", targetCandidate, "         Target ID", targetCandidate.id) 
        return targetCandidate.id
    else
        table.insert(ineligible, targetCandidate)
        table.remove(hostileTargets, index)
    end
end

-- If no hostile targets within firing range, re-ping hostile targets and select all other targets
if not next(hostileTargets) then
    SerinaAI.rePingHostile()
	print("SerinaAI: reping hostiles ")
    return 
end

return TorpedoAI.target = Uuid()  -- Set target to an empty UUID
print("clear target data")
end
