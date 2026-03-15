package.path = package.path .. ";data/scripts/systems/?.lua"
package.path = package.path .. ";data/scripts/lib/?.lua"
include ("basesystem")
include ("utility")
include ("randomext")
-- optimization so that energy requirement doesn't have to be read every frame
FixedEnergyRequirement = true
local totram = 0.0
--Copy and pasted from the energy Subsystem script lol
function getBonuses(seed, rarity, permanent)
    math.randomseed(seed)

    local baseramdamage = 15 -- base value, in percent
    -- add flat percentage based on rarity
    local ramdamage = baseramdamage + (rarity.value + 2) * 6
	--add a slight variation, increasing based on rarity, 5 possible values to not spam inventories
    if permanent then
        ramdamage = ramdamage + ((math.ceil(math.random() * 5)/5) * (rarity.value + 2) * 3) + ((rarity.value + 2) * 4)
    end
	ramdamage = ramdamage / 100
    return ramdamage
end

function onInstalled(seed, rarity, permanent)
    local ramdamage = getBonuses(seed, rarity, permanent)
	local entity = Entity()
	entity:registerCallback("onCollision", "onCollision")
	--print(ramdamage)
	totram = ramdamage
end

function onUninstalled(seed, rarity, permanent)
end
--The collision damage thing is here, I suck at coding so things might suck
function onCollision(entityA, entityB, damageToA, damageToB, steererA, steererB)
	--print("Collision detected")
	local shipA = Entity(entityA)
	local shipB = Entity(entityB)
	local damageB = damageToB
	local ramdamage = totram
	local dealdamage = damageB * ramdamage
	-- print("did ",damageB," to ",shipB," add ", dealdamage,"")
	if not shipB.durability then return end
	--shipB.durability = shipB.durability - dealdamage
	shipB:inflictDamage(dealdamage, DamageSource.Collision , DamageType.Physical, 0, vec3(), shipA.id) --<- I have no idea how to make this work
end

function getName(seed, rarity)
    local ramdamage = getBonuses(seed, rarity, permanent)
	math.randomseed(seed)

    local serial = math.ceil(math.random() * 1000)

    local name = "Подсистема Крушитель"


    return "${name} GW-${rarity} ${serial}/* ex: 9028 Подсистема Крушитель GW-XXV */"%_t % {serial = serial, name = name, rarity = toRomanLiterals((rarity.value+2) * 25)}
end

function getEnergy(seed, rarity, permanent)
	local rdam = getBonuses(seed, rarity, permanent)
	local ecost = 0 --You can use getBonuses to make returned stats effect the energy
    if rarity.value == 5 then ecost = 1500 --Legendary
	elseif rarity.value == 4 then ecost = 900 --Exotic
	elseif rarity.value == 3 then ecost = 500 --Exceptional
	elseif rarity.value == 2 then ecost = 300 --Rare
	elseif rarity.value == 1 then ecost = 100 --Uncommon
	elseif rarity.value == 0 then ecost = 50 --Common
	else ecost = 10 end --Junk
	if permanent then
		rdam = rdam + 1
		ecost = ecost * rdam
	end
    return ecost * 1000 * 1000 -- Megawatts, add another "* 1000" to get Gigawatts.
end
--Not

function getBasicName()
    return "Подсистема Крушитель"%_t
end

function getIcon(seed, rarity)
    return "data/textures/icons/gavel.png"
end


function getPrice(seed, rarity)
    local ramdamage = getBonuses(seed, rarity)
    local price = ramdamage * 100 * 450
    return price * 2.5 ^ rarity.value
end

function getTooltipLines(seed, rarity, permanent)

    local texts = {}
    local bonuses = {}
    local ramdamage = getBonuses(seed, rarity, permanent)
    local baseramdamage = getBonuses(seed, rarity, false)
	local bonusramdamage = getBonuses(seed, rarity, true)

	table.insert(texts, {ltext = "Дополнительный урон от столкновения"%_t, rtext = string.format("%+i%%", round(ramdamage * 100)), icon = "data/textures/icons/gavel.png", boosted = permanent})
	table.insert(bonuses, {ltext = "Дополнительный урон от столкновения"%_t, rtext = string.format("%+i%%", round((bonusramdamage - baseramdamage) * 100)), icon = "data/textures/icons/gavel.png"})

    return texts, bonuses
end

function getDescriptionLines(seed, rarity, permanent)
    local ramdamage = getBonuses(seed, rarity, permanent)

    local texts = {}
	table.insert(texts, {ltext = "Наносит дополнительный урон кораблям и станциям при столкновении."%_t})
	table.insert(texts, {ltext = "Примечание. Бонусный урон является аддитивным и имеет свои собственные значения урона."%_t})

    return texts
end

function getComparableValues(seed, rarity)
    local ramdamage = getBonuses(seed, rarity, false)
	local bonusramdamage = getBonuses(seed, rarity, true)
    local base = {}
    local bonus = {}
    if ramdamage ~= 0 then
        table.insert(base, {name = "Дополнительный урон от столкновения"%_t, key = "bcollision_dam", value = round(ramdamage * 100), comp = UpgradeComparison.MoreIsBetter})
        table.insert(bonus, {name = "Дополнительный урон от столкновения"%_t, key = "bcollision_dam", value = round((bonusramdamage - ramdamage) * 100), comp = UpgradeComparison.MoreIsBetter})
    end

    return base, bonus
end
