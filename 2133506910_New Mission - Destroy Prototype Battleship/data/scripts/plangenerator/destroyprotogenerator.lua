package.path = package.path .. ";data/scripts/lib/?.lua"
package.path = package.path .. ";data/scripts/?.lua"

include ("galaxy")
include ("stringutility")
include ("randomext")
include("weapontype")

local PlanGenerator = include ("plangenerator")
local ShipUtility = include ("shiputility")
local SectorTurretGenerator = include ("sectorturretgenerator")
local SectorUpgradeGenerator = include ("upgradegenerator")

local DestroyProtoGenerator = {}

--Create the Prototype Battleship.
--We pass the faction to this in order to make sure that ships from two different pirate factions don't spawn.
function DestroyProtoGenerator.create(position, giverFaction, pirateFaction, dangerValue, scaleOverride)
	--Base scale is 40. 6+ = 50, 8+ = 60, 10 = 70
	local bshipScale = 40
	if dangerValue > 5 then
		bshipScale = bshipScale + 10
	end
	if dangerValue >= 8 then
		bshipScale = bshipScale + 10
	end
	if dangerValue == 10 then
		bshipScale = bshipScale + 10
	end

	if scaleOverride then
		bshipScale = scaleOverride
	end
	
	--I don't see this ever going above 1, but we'll see what happens.
	local playerScaleFactor = DestroyProtoGenerator.getPlayerScaleFactor()
	
	position = position or Matrix()
    local x, y = Sector():getCoordinates()

    local volume = Balancing_GetSectorShipVolume(x, y) * bshipScale * playerScaleFactor

	--Use highest available material level.
	local availableMaterials = Balancing_GetTechnologyMaterialProbability(x, y)
	local _m = 0
	for _k, _v in pairs(availableMaterials) do
		if _v > 0 and _k > _m then
			_m = _k
		end
	end

	--No Avorion outside of the core.
	local distFromCenter = length(vec2(x, y))
	if _m == 6 and distFromCenter > Balancing_GetBlockRingMin() then
		_m = 5
	end

    local plan = PlanGenerator.makeShipPlan(giverFaction, volume, nil, Material(_m))
    local ship = Sector():createShip(pirateFaction, "", plan, position)

    DestroyProtoGenerator.addBattleshipEquipment(ship, dangerValue)

    ship.crew = ship.idealCrew
    ship.shieldDurability = ship.shieldMaxDurability

    return ship
end

function DestroyProtoGenerator.addBattleshipEquipment(ship, dangerValue)
	local turretDrops = 0
	local systemDrops = 0

    local x, y = Sector():getCoordinates()
	local distFromCenter = length(vec2(x, y))
    local turretGenerator = SectorTurretGenerator()
    local rarities = turretGenerator:getSectorRarityDistribution(x, y)
	local upgradeGenerator = SectorUpgradeGenerator()
	local sysrarities = upgradeGenerator:getSectorRarityDistribution(x, y)
	
	local turretFactor = 3
	local damageFactor = 5
	local turretRange = 1000
	if dangerValue > 5 then
		turretFactor = turretFactor + 0.5
		turretRange = turretRange + 375
		damageFactor = damageFactor + ((dangerValue - 5) * 1) --should result in a smoother damage curve than +1.25 / +1.25 / +2.5
	end
	if dangerValue >= 8 then
		turretFactor = turretFactor + 0.5
		turretRange = turretRange + 375
	end
	if dangerValue == 10 then
		turretFactor = turretFactor + 1
		turretRange = turretRange + 750
	end

	--Add two different types of military weapons + disruptor weapons -- also add artillery so the player can't just stand off and hammer it to death.
	--Well, they still _can_, but at least it's a little more difficult this way.
	--Update 2/18/2025 - I've learned a little bit more about how the AI works. This should make things spicier :)
	ShipUtility.addSpecializedEquipment(ship, ShipUtility.LongRangeWeapons, ShipUtility.NormalTorpedoes, turretFactor, 0, turretRange)
	ShipUtility.addSpecializedEquipment(ship, ShipUtility.LongRangeWeapons, ShipUtility.NormalTorpedoes, turretFactor, 0, turretRange)
	ShipUtility.addSpecializedEquipment(ship, ShipUtility.LongRangeWeapons, ShipUtility.NormalTorpedoes, turretFactor, 1, turretRange)

	ship:setDropsAttachedTurrets(false) --We futz with the turrets after adding them, so we don't necessarily want to drop them.
	
	--Finally, increase the ship's damage multiplier by a random amount depending on the danger level of the mission.
	local forceMultiplier = 1 + (random():getInt(0, dangerValue) / 50)
	--print("forceMultiplier is " .. forceMultiplier)
	--print("turretFactor is " .. turretFactor)
	ship.damageMultiplier = damageFactor * forceMultiplier
	--Make it unboardable because I don't want to account for what happens if the player boards it.
	Boarding(ship).boardable = false

	turretDrops = 2
	systemDrops = 1
	if dangerValue > 5 then
		turretDrops = turretDrops + 2
		systemDrops = systemDrops + 1
	end
	if dangerValue == 10 then
		turretDrops = turretDrops + 3
		systemDrops = systemDrops + 2
	end

    rarities[-1] = 0 -- no petty turrets
    rarities[0] = 0 -- no common turrets
    rarities[1] = 0 -- no uncommon turrets
	if distFromCenter < 350 then
		rarities[2] = 0 -- no rare turrets - exceptional + only!
		rarities[3] = rarities[3] * 0.5 -- reduce rates for rare turrets to have higher chance for the others
	else
		rarities[2] = rarities[2] * 0.5
		--Don't mess with exceptional rarities @ > 350
	end
	
	sysrarities[-1] = 0
	sysrarities[0] = 0
	sysrarities[1] = 0
	if distFromCenter < 350 then
		sysrarities[2] = 0
		sysrarities[3] = sysrarities[3] * 0.5
	else
		sysrarities[2] = sysrarities[2] * 0.5
		--Don't mess with exceptional rarities @ > 350
	end
	
    turretGenerator.rarities = rarities
    for _ = 1, turretDrops do
        Loot(ship):insert(InventoryTurret(turretGenerator:generate(x, y)))
    end
	for _ = 1, systemDrops do
		Loot(ship):insert(upgradeGenerator:generateSectorSystem(x, y, getValueFromDistribution(sysrarities)))
	end

    ShipAI(ship.index):setAggressive()
    ship:setTitle("${toughness}Prototype Battleship"%_T, {toughness = ""})
	ship:removeScript("icon.lua")
	ship:addScript("icon.lua", "data/textures/icons/pixel/skull_big.png")
	if dangerValue > 5 then
		ship:addScript("internal/common/entity/background/legendaryloot.lua")
		ship:addScriptOnce("utility/buildingknowledgeloot.lua")
	end
    ship.shieldDurability = ship.shieldMaxDurability

    ship:setValue("is_pirate", true)
	ship:setValue("is_prototype", true)
	ship:setValue("IW_nuclear_m", 0.2) --Same as the Xsotan Dreadnought
end

function DestroyProtoGenerator.getPlayerScaleFactor()
	local scaling = Sector().numPlayers

    if scaling == 0 then scaling = 1 end
    return scaling
end

return DestroyProtoGenerator