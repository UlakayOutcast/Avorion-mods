function getBonuses(seed, rarity, permanent)
    math.randomseed(seed)

    -- ### PERCENT BONUS ###
    local perc = 0.04 + ((rarity.value + 1) * (rarity.value + 1) * 0.02) -- base + % per rarity (72% total)
    perc = perc + math.random() * ((4 + (rarity.value + 1) * (rarity.value + 1)) * 0.006) -- Random % between 0-24%, span increases per rarity
    -- if permanent then perc = math.min(perc * 1.5, 0.9) end -- ensures % doesn't go over 90%

    -- ### FLAT BONUS ###
    local flat = 40 + ((rarity.value + 1) * (rarity.value + 1) * 20) -- base value 40 +20 (worst rarity) to +720 (best rarity)
    flat = flat + math.random() * ((4 + (rarity.value + 1) * (rarity.value + 1)) * 6) -- add random value between +0 (worst rarity) and +240 (best rarity)
    flatB = round(flat)
    if not permanent then flat = 0 end -- обнуляем, если не permanent
    flat = round(flat)

    return perc, flat, flatB
end
function getEnergy(seed, rarity, permanent)
    local perc, flat = getBonuses(seed, rarity, permanent)
	return perc * 2 * 1000 * 1000 * 1000 + flat * 0.002 * 1000 * 1000 * 1000
end
function getTooltipLines(seed, rarity, permanent)

    local texts = {}
    local bonuses = {}
    local perc, flat, flatB = getBonuses(seed, rarity, permanent)
    local basePerc, baseFlat = getBonuses(seed, rarity, false)

    if perc ~= 0 then
        table.insert(texts, {ltext = "Cargo Hold (relative)"%_t, rtext = string.format("%+i%%", round(perc * 100)), icon = "data/textures/icons/crate.png", boosted = permanent})
        -- table.insert(bonuses, {ltext = "Cargo Hold (relative)"%_t, rtext = string.format("%+i%%", round(basePerc * 0.5 * 100)), icon = "data/textures/icons/crate.png", boosted = permanent})
    end

    if permanent then
        table.insert(texts, {ltext = "Cargo Hold"%_t, rtext = string.format("%+i", round(flat)), icon = "data/textures/icons/crate.png", boosted = permanent})-- table.insert(bonuses, {ltext = "Cargo Hold"%_t, rtext = string.format("%+i", round(baseFlat * 0.5)), icon = "data/textures/icons/crate.png", boosted = permanent})
    else
        table.insert(bonuses, {ltext = "Cargo Hold"%_t, rtext = string.format("%+i", round(flatB)), icon = "data/textures/icons/crate.png", boosted = permanent})
    end

    return texts, bonuses
end
function getComparableValues(seed, rarity)
    local perc, flat, flatB = getBonuses(seed, rarity, false)

    local base = {}
    local bonus = {}
    if perc ~= 0 then
        table.insert(base, {name = "Cargo Hold (relative)"%_t, key = "cargo_hold_relative", value = round(perc * 100), comp = UpgradeComparison.MoreIsBetter})
        table.insert(bonus, {name = "Cargo Hold (relative)"%_t, key = "cargo_hold_relative", value = round(perc * 0.5 * 100), comp = UpgradeComparison.MoreIsBetter})
    end

    if permanent then
        table.insert(base, {ltext = "Cargo Hold"%_t, rtext = string.format("%+i", round(flat)), icon = "data/textures/icons/crate.png", boosted = permanent})-- table.insert(bonuses, {ltext = "Cargo Hold"%_t, rtext = string.format("%+i", round(baseFlat * 0.5)), icon = "data/textures/icons/crate.png", boosted = permanent})
    else
        table.insert(bonus, {ltext = "Cargo Hold"%_t, rtext = string.format("%+i", round(flatB)), icon = "data/textures/icons/crate.png", boosted = permanent})
    end

    return base, bonus
end