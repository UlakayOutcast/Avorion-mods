function getBonuses(seed, rarity, permanent)
    math.randomseed(seed)

    -- ### PERCENT BONUS ###
    local perc = 0.08 -- base 8% 
    perc = perc + (math.max(rarity.value, 0) * 0.1) -- 10% per rarity over petty (60% total)
    perc = perc + math.random() * ((rarity.value +2) * 0.04) -- Random % between 0-32%, span increases by 4 per rarity
    -- if permanent then perc = math.min(perc * 1.5, 0.9) end -- ensures % doesn't go over 90%

    -- ### FLAT BONUS ###
    local flat = 40 -- base value
    flat = flat + ((rarity.value*rarity.value + 1) * 20) -- add +0 (worst rarity) to +740 (best rarity)
    flat = flat + (math.max(rarity.value * rarity.value, 0) * 20) -- add +0 (worst rarity) to +720 (best rarity)
    flat = flat + math.random() * ((rarity.value * rarity.value / 2 +2) * 12) -- add random value between +15 (worst rarity) and +260 (best rarity)
    flatB = round(flat)
    if not permanent then flat = 0 end -- обнуляем, если не permanent
    flat = round(flat)

    return perc, flat, flatB
end
function getEnergy(seed, rarity, permanent)
    local perc, flat = getBonuses(seed, rarity, permanent)
	return perc * 1.5 * 1000 * 1000 * 1000 + flat * 0.0045 * 1000 * 1000 * 1000
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