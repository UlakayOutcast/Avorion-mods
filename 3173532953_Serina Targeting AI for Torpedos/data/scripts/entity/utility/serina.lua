package.path = package.path .. ";data/scripts/lib/?.lua"
package.path = package.path .. ";lib/entitydbg.lua"
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
local hostileTargets = {}
local shipsInSector = {}
local isEnemy = {}
local shipsInSector = {}

function SerinaAI.initialize()
Entity():registerCallback("onTorpedoLaunched", "shotsFired")
end

function SerinaAI.shotsFired(entityId, torpedoId)
	shipsInSector = {Sector():getEntitiesByType(EntityType.Ship)}
    firingShip = Entity(entityId)
    torpedoTargetingCPU = TorpedoAI(torpedoId)
    foxTwo = Torpedo(torpedoId)
	
	if not firingShip.playerOrAllianceOwned then return print("SerinaAI: Fuck off AI scum!")end
	
	--rain Hellfire on the poor bastard
    for _, ship in pairs(shipsInSector) do
        local shipAI = ShipAI(ship)
        local isEnemy = shipAI:isEnemy(firingShip)
	    local targetShip = Entity(torpedoTargetingCPU.target)
		if ShipAI(targetShip):isEnemy(firingShip) then
            print("SerinaAI: Targeting selected enemy ship")
			print("SerinaAI: Raining Hellfire on the poor bastard!")
            return
		else
			torpedoTargetingCPU.target = SerinaAI.nextHostile()
		end
	end
	
end


-- Next Hostile Target: The nextHostile() function selects the next hostile target within firing range (75% of max range). It shuffles the list of hostile targets and selects one after resuffle
function SerinaAI.nextHostile()
    local torpedoTemplate = foxTwo:getTemplate()
    local firingRange = torpedoTemplate.reach * 0.75
        
    -- Clear previous targets
    hostileTargets = {}

    -- Populate hostileTargets table with enemy ships within sector
    for _, ship in pairs(shipsInSector) do
        local shipAI = ShipAI(ship)
        local shipDistance = ship:getNearestDistance(firingShip)
        local isEnemy = shipAI:isEnemy(firingShip)
        
        if isEnemy then
            table.insert(hostileTargets, {id = ship.id, distance = shipDistance})
        end
    end
    print("Target table complete")

    -- Shuffle the hostileTargets table
    for i = #hostileTargets, 2, -1 do
        local j = math.random(1, i)
        hostileTargets[i], hostileTargets[j] = hostileTargets[j], hostileTargets[i]
    end

    -- Iterate through shuffled targets and select the first one within firing range
    for _, targetCandidate in ipairs(hostileTargets) do
        if targetCandidate.distance <= firingRange then
        print("SerinAI: Targets assigned, Firing")
            return targetCandidate.id
        end
    end

    -- If no suitable target found within firing range, set torpedo's target to an empty UUID
    torpedoTargetingCPU.target = Uuid()
     print("SerinaAI: No suitable target found, setting target to empty UUID")
    return torpedoTargetingCPU.target
end

end