package.path = package.path .. ";data/scripts/systems/?.lua"
package.path = package.path .. ";data/scripts/lib/?.lua"
include ("basesystem")
include ("utility")
include ("randomext")
include ("goods")
-- optimization so that energy requirement doesn't have to be read every frame
FixedEnergyRequirement = true
Unique = true

local salveffic = 0.0
--Copy and pasted from the energy Subsystem script lol
function getBonuses(seed, rarity, permanent)
    math.randomseed(seed)

    local salveff = 5 -- base value, in percent
    -- add flat percentage based on rarity
    local salveff = salveff + (rarity.value + 2) * 4
	--add a slight variation, increasing based on rarity, 5 possible values to not spam inventories
    if permanent then
        salveff = salveff * 1.5
    end
	salveff = salveff / 100
    return salveff
end

function onInstalled(seed, rarity, permanent)
    local salveff = getBonuses(seed, rarity, permanent)
	local entity = Entity()
	entity:registerCallback("onCollision", "onCollision")

	salveffic = salveff
end
function onUninstalled(seed, rarity, permanent)
end
--The collision damage thing is here, I suck at coding so things might suck
function onCollision(entityA, entityB, damageToA, damageToB, steererA, steererB)
	--print("Collision detected")
	local shipA = Entity(entityA)
	local shipB = Entity(entityB)
	shipB:registerCallback("onBlockDestroyed","onBlockDestroyed") --So we can do stuff when any block is destroyed
end

function onBlockDestroyed(objectIndex, index, block, lastDamageInflictor, damageSource)
	--print("Block destroyed")
	if damageSource ~= 1 then return end --1 is Collision Damage
	local ShipB = Entity(objectIndex)
	local F = Faction(ShipB.factionIndex)
	--print(block.harvestableResources * salveffic)
	goodtogive = "Scrap " .. tostring(block.material.name) --There's probably a better way to do this
	--Drop Item
	Sector():dropCargo(ShipB.translationf, nil, nil, goods[goodtogive]:good(), objectIndex, (block.harvestableResources * salveffic))
end
function getName(seed, rarity)
    local ramdamage = getBonuses(seed, rarity, permanent)
	math.randomseed(seed)

    local serial = toGreekNumber(rarity.value + 5)

    local name = "Утилизирующая подсистема шипов корпуса грабителя"


    return "${serial} ${name} GR-${rarity} /* ex: Theta Подсистема дробления GR-XX */"%_t % {serial = serial, name = name, rarity = toRomanLiterals((rarity.value+2) * 20)}
end

function getEnergy(seed, rarity, permanent)
	local ecost = 0 --You can use getBonuses to make returned stats effect the energy
    if rarity.value == 5 then ecost = 450 --Legendary
	elseif rarity.value == 4 then ecost = 300 --Exotic
	elseif rarity.value == 3 then ecost = 150 --Exceptional
	elseif rarity.value == 2 then ecost = 100 --Rare
	elseif rarity.value == 1 then ecost = 50 --Uncommon
	elseif rarity.value == 0 then ecost = 20 --Common
	else ecost = 10 end --Junk
    return ecost * 1000 * 1000 -- Megawatts, add another "* 1000" to get Gigawatts.
end

function getBasicName()
    return "Подсистема грабителя"%_t
end

function getIcon(seed, rarity)
    return "data/textures/icons/crowbar.png"
end


function getPrice(seed, rarity)
    local ramdamage = getBonuses(seed, rarity)
    local price = ramdamage * 100 * 450
    return price * 3 ^ rarity.value
end

function getTooltipLines(seed, rarity, permanent)

    local texts = {}
    local bonuses = {}
    local eff = getBonuses(seed, rarity, permanent)
    local baseeff = getBonuses(seed, rarity, false)
	local bonuseff = getBonuses(seed, rarity, true)

	table.insert(texts, {ltext = "Efficiency"%_t, rtext = string.format("%i%%", round(eff * 100)), icon = "data/textures/icons/crowbar.png", boosted = permanent})
	table.insert(bonuses, {ltext = "Efficiency"%_t, rtext = string.format("%+i%%", round((bonuseff - baseeff) * 100)), icon = "data/textures/icons/crowbar.png"})

    return texts, bonuses
end

function getDescriptionLines(seed, rarity, permanent)
    local ramdamage = getBonuses(seed, rarity, permanent)

    local texts = {}
	table.insert(texts, {ltext = "Увеличивает количество необработанного лома, полученного в результате тарана других кораблей и обломков."%_t})

    return texts
end

function getComparableValues(seed, rarity)
    local ramdamage = getBonuses(seed, rarity, false) --Just copied over the values from wreckersystem.lua, nothing really changed
	local bonusramdamage = getBonuses(seed, rarity, true)
    local base = {}
    local bonus = {}
    if ramdamage ~= 0 then
        table.insert(base, {name = "Efficiency"%_t, key = "saleff", value = round(ramdamage * 100), comp = UpgradeComparison.MoreIsBetter})
        table.insert(bonus, {name = "Efficiency"%_t, key = "saleff", value = round((bonusramdamage - ramdamage) * 100), comp = UpgradeComparison.MoreIsBetter})
    end

    return base, bonus
end
