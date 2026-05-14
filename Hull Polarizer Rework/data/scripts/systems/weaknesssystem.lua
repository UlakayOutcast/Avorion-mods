package.path = package.path .. ";data/scripts/systems/?.lua"
package.path = package.path .. ";data/scripts/lib/?.lua"
include ("basesystem")
include ("utility")
local SpawnUtility = include ("spawnutility")
include ("randomext")
include ("damagetypeutility")


local weaknessTypes =
{
    DamageType.Energy,
    DamageType.Plasma,
    DamageType.Electric,
    DamageType.AntiMatter
}

-- dynamic stats
local weaknessType = nil
local hpBonus = nil
local dmgFactor = nil

-- optimization so that energy requirement doesn't have to be read every frame
FixedEnergyRequirement = true
Unique = true

function getBonuses(seed, rarity, permanent)
    math.randomseed(seed)

    local rarityLevel = rarity.value + 2 -- rarity levels start at -1

    local randomEntry = math.random(1, 4)
    weaknessType = weaknessTypes[randomEntry]
    hpBonus = 0
    dmgFactor = 0

    if permanent then
        hpBonus = 0.00 -- base %
        hpBonus = hpBonus + ((rarity.value + 2) * 0.10) -- Добавляет 10% за редкость, чтобы гарантировать, что обычные предметы не лучше необычных и т. д.
        hpBonus = round(hpBonus + math.random() * ((rarity.value + 2) * 0.0428571428571429), 2) -- Добавляет дополнительно случайное из 4% за редкость.
		
        dmgFactor = hpBonus * 1.5 -- базовый коэффициент 1.5x зависимо от того, с каким бонусом hpBonus выпадает
        dmgFactor = dmgFactor + ((rarity.value + 2) * 0.42 / 7) -- Удаляет урон на 4% за каждую редкость, чтобы обычные предметы не были лучше необычных и т. д.
        dmgFactor = round(dmgFactor - math.random() * ((rarity.value + 2) * 0.1142857142857143), 2) -- Убирает урон дополнительно случайное из 1% за редкость.
    end

    return weaknessType, hpBonus, dmgFactor
end

function onInstalled(seed, rarity, permanent)
    if onClient() then return end

    local entity = Entity()
    if not entity then return end

    local weaknessType, hpBonus, dmgFactor = getBonuses(seed, rarity, permanent)

    -- the upgrades are unique, so we can just reset the weakness
    local durability = Durability()
    if not durability then return end
    durability:resetWeakness()
    durability.maxDurabilityFactor = 1

    if permanent then
        SpawnUtility.addWeakness(entity, weaknessType, dmgFactor, hpBonus)
    end
end

function onUninstalled(seed, rarity, permanent)
    if onClient() then return end

    local entity = Entity()
    if not entity then return end

    local weaknessType, hpBonus, dmgFactor = getBonuses(seed, rarity, permanent)

    local durability = Durability()
    if not durability then return end

    durability:resetWeakness()
    durability.maxDurabilityFactor = 1
end

function getName(seed, rarity)
    local weaknessType, hpBonus, dmgFactor = getBonuses(seed, rarity, true)
    local designation = getDamageTypeName(weaknessType)

    return "W-${designation}-Hull Polarizer ${rarity}"%_t % {designation = designation, rarity = tostring((rarity.value + 2) * 1000 + seed % 750)}
end

function getBasicName()
    return "Hull Polarizer /* generic name for 'W-${designation}-Hull Polarizer ${rarity}' */"%_t
end

function getIcon(seed, rarity)
    return "data/textures/icons/metal-scales-plus.png"
end

function getEnergy(seed, rarity, permanent)
    local weaknessType, hpBonus, dmgFactor = getBonuses(seed, rarity, true)
    -- return ((hpBonus + 1) ^ 4 - dmgFactor ^ 2) * 1000 * 537 
    if permanent then
		return (hpBonus * 6000 - dmgFactor * 2000) * 1000 * 537
		else
		return 0
	end
end

function getPrice(seed, rarity)
    local weaknessType, hpBonus, dmgFactor = getBonuses(seed, rarity, true)
    -- local price =  (hpBonus + 1) * 100 * 25 - dmgFactor * 100 * 50
    -- return ((hpBonus + 1) * 600 - dmgFactor * 600/1.5) * 10000 ^ rarity.value
    local price = (hpBonus * 6000 + dmgFactor * 2000)
    -- local price = dmgFactor * 100 * 50 + (hpBonus + 1) * 100 * 25
    return price * 4.5 ^ (rarity.value+1)
end

function getTooltipLines(seed, rarity, permanent)

    local texts = {}
    local bonuses = {}
    local weaknessType, hpBonus, dmgFactor = getBonuses(seed, rarity, true)

    if permanent then
        table.insert(texts, {ltext = "Hull Durability"%_t, rtext = string.format("%+i%%", round((hpBonus) * 100)), icon = "data/textures/icons/health-normal.png", boosted = permanent})
        table.insert(texts, {ltext = ""})
        table.insert(texts, {ltext = "Weakness against"%_t, rtext = string.format("%s", getDamageTypeName(weaknessType)), rcolor = getDamageTypeColor(weaknessType), icon = "data/textures/icons/metal-scale.png"})
        table.insert(texts, {ltext = string.format("%s damage received"%_t, getDamageTypeName(weaknessType)), rtext = string.format("+%i%%", round(dmgFactor * 100)), rcolor = getDamageTypeColor(weaknessType), icon = "data/textures/icons/metal-scale.png", rcolor = ColorRGB(1, 0, 0)})
    end

    table.insert(bonuses, {ltext = "Hull Durability"%_t, rtext = string.format("%+i%%", round((hpBonus) * 100)), icon = "data/textures/icons/health-normal.png", boosted = permanent})
    table.insert(bonuses, {ltext = ""})
    table.insert(bonuses, {ltext = "Weakness against"%_t, rtext = string.format("%s", getDamageTypeName(weaknessType)), rcolor = getDamageTypeColor(weaknessType), icon = "data/textures/icons/metal-scale.png"})
    table.insert(bonuses, {ltext = string.format("%s damage received"%_t, getDamageTypeName(weaknessType)), rtext = string.format("+%i%%", round(dmgFactor * 100)), icon = "data/textures/icons/metal-scale.png", rcolor = ColorRGB(1, 0, 0)})

    return texts, bonuses
end

function getDescriptionLines(seed, rarity, permanent)
    local weaknessType, hpBonus, dmgFactor = getBonuses(seed, rarity, true)

    local texts = {}

    table.insert(texts, {ltext = "Polarizes hull to greatly increase durability."%_t})
    table.insert(texts, {ltext = "A side effect causes the hull to take"%_t})
    table.insert(texts, {ltext = string.format("more damage from %s weapons."%_t, getDamageTypeName(weaknessType))})

    return texts
end

function getComparableValues(seed, rarity)
    local base = {}
    local bonus = {}

    local weaknessType, hpBonus, dmgFactor = getBonuses(seed, rarity, true)

    table.insert(bonus, {name = "Hull Durability"%_t, key = "hp_bonus", value = round((hpBonus) * 100), comp = UpgradeComparison.MoreIsBetter})
    table.insert(bonus, {name = string.format("%s damage received"%_t, getDamageTypeName(weaknessType)), key = "dmg_factor", value = dmgFactor, comp = UpgradeComparison.LessIsBetter})
    table.insert(base, {name = "Weakness against"%_T, key = "weakness_type", value = weaknessType})

    return base, bonus
end
