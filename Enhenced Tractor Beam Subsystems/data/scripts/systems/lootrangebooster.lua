package.path = package.path .. ";data/scripts/systems/?.lua"
package.path = package.path .. ";data/scripts/lib/?.lua"
include ("basesystem")
include ("utility")
include ("randomext")

-- optimization so that energy requirement doesn't have to be read every frame
FixedEnergyRequirement = true

function getLootCollectionRange(seed, rarity, permanent)
    math.randomseed(seed)

    -- local range = (rarity.value + 2 + getFloat(0.0, 0.75)) * 2 * (1.3 ^ rarity.value) -- one unit is 10 meters
    local range = 20 + math.random() * (rarity.value + 2)  * 20 * (1.3 ^ rarity.value) -- one unit is 10 meters

    if permanent then
        range = range * 3
    end

    range = round(range)

    return range
end

function onInstalled(seed, rarity, permanent)
    addAbsoluteBias(StatsBonuses.LootCollectionRange, getLootCollectionRange(seed, rarity, permanent))
end

function onUninstalled(seed, rarity, permanent)
end

function getName(seed, rarity)
    local serial = makeSerialNumber(seed, 2, nil, nil, "0123456789")
    local mark = toRomanLiterals(rarity.value + 2)
    return "RCN-${serial} Tractor Beam Upgrade MK ${mark}"%_t % {mark = mark, serial = serial}
end

function getBasicName()
    return "Tractor Beam Upgrade /* generic name for 'RCN-${serial} Tractor Beam Upgrade MK ${mark}' */"%_t
end

function getIcon(seed, rarity)
    return "data/textures/icons/tractor.png"
end

function getEnergy(seed, rarity, permanent)
    local range = getLootCollectionRange(seed, rarity, permanent)
    -- return range * 20 * 1000 * 1000 / (1.1 ^ rarity.value)
    return range * 5 * 1000 * 1000 / (1.1 ^ rarity.value)
end

function getPrice(seed, rarity)
    return 500 * getLootCollectionRange(seed, rarity)
end

function getTooltipLines(seed, rarity, permanent)
    local range = getLootCollectionRange(seed, rarity, permanent)
    local baseRange = getLootCollectionRange(seed, rarity, false)

    return
    {
        {ltext = "Loot Collection Range"%_t, rtext = "+${distance} km"%_t % {distance = round(range / 100, 2)}, icon = "data/textures/icons/tractor.png", boosted = permanent}
    },
    {
        {ltext = "Loot Collection Range"%_t, rtext = "+${distance} km"%_t % {distance = round(baseRange * 2 / 100, 2)}, icon = "data/textures/icons/tractor.png"}
    }
end

function getDescriptionLines(seed, rarity, permanent)
    return
    {
        {ltext = "Gotta catch 'em all!"%_t, lcolor = ColorRGB(1, 0.5, 0.5)}
    }
end

function getComparableValues(seed, rarity)
    local range = getLootCollectionRange(seed, rarity, false)

    local base = {}
    local bonus = {}

    table.insert(base, {name = "Loot Collection Range"%_t, key = "range", value = round(range / 100, 2), comp = UpgradeComparison.MoreIsBetter})
    table.insert(bonus, {name = "Loot Collection Range"%_t, key = "range", value = round(range * 0.5 / 100, 2), comp = UpgradeComparison.MoreIsBetter})

    return base, bonus
end
