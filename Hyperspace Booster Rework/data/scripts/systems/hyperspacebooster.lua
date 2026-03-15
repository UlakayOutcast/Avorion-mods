package.path = package.path .. ";data/scripts/systems/?.lua"
package.path = package.path .. ";data/scripts/lib/?.lua"
include ("basesystem")
include ("utility")
include ("randomext")

																			  
FixedEnergyRequirement = true

function getBonuses(seed, rarity, permanent)
    math.randomseed(seed)

    local reach = 0
    local cdfactor = 0
    local efactor = 0
    local cdbias = 0

    -- Корректируем редкость для расчёта количества бонусов
    local adjustedRarity = rarity.value + 1

    -- Количество бонусов в зависимости от редкости
    local numBonuses = 1
    if adjustedRarity >= 2 and adjustedRarity <= 3 then
        numBonuses = 2
    elseif adjustedRarity >= 4 and adjustedRarity <= 5 then
        numBonuses = getInt(2, 3)
    elseif adjustedRarity >= 6 then
        numBonuses = 3
    end


    -- Определяем возможные бонусы
    local bonuses = {}
    bonuses[StatsBonuses.HyperspaceCooldown] = 1
    bonuses[StatsBonuses.HyperspaceChargeEnergy] = 1
    if adjustedRarity >= 1 then
        bonuses[StatsBonuses.HyperspaceReach] = 1
    end

    local enabled = {}

    -- Выбираем бонусы
    for i = 1, numBonuses do
        local bonus = selectByWeight(random(), bonuses)
        if bonus then
            enabled[bonus] = 1
            bonuses[bonus] = nil
        end
    end

    -- Hyperspace Cooldown
    if enabled[StatsBonuses.HyperspaceCooldown] then
        cdfactor = 4 + (adjustedRarity * 5) + math.random() * (adjustedRarity * 2)
        if permanent then
            cdfactor = cdfactor * 1.5
        end
        cdfactor = -cdfactor / 100
    end

    -- Hyperspace Charge Energy
    if enabled[StatsBonuses.HyperspaceChargeEnergy] then
        efactor = 4 + (adjustedRarity * 4) + math.random() * (adjustedRarity * 2)
        if permanent then
            efactor = efactor * 1.5
        end
        efactor = -efactor / 100
    end

    -- Hyperspace Reach (работает только при перманентной установке)
    if enabled[StatsBonuses.HyperspaceReach] then
        if permanent then
            if adjustedRarity == 1 then
                reach = 1
            else
                reach = 1.5 * adjustedRarity + math.random() * (0.5 * adjustedRarity)
            end
        end
    end

    return round(reach, 1), cdfactor, efactor, 0, cdbias
end



function onInstalled(seed, rarity, permanent)
    local reach, cooldown, energy, _, _ = getBonuses(seed, rarity, permanent)

    addMultiplyableBias(StatsBonuses.HyperspaceReach, reach)
    addBaseMultiplier(StatsBonuses.HyperspaceCooldown, cooldown)
    addBaseMultiplier(StatsBonuses.HyperspaceChargeEnergy, energy)
													   
															
end

											   

   

function getName(seed, rarity)
    local reach, cooldown, energy, _, _ = getBonuses(seed, rarity, true)

    local reachStr = ""
    if reach > 0 then
        reachStr = "R-" .. math.ceil(reach) .. " "
    end

    local mark = toRomanLiterals(rarity.value + 2)

    local type = "Hyperspace Subsystem"%_t
    if cooldown ~= 0 and energy ~= 0 then
        type = "Hyperspace Booster"%_t
    elseif cooldown ~= 0 then
        type = "Hyperspace Accelerator"%_t
    elseif energy ~= 0 then
        type = "Hyperspace Enhancer"%_t
    end

					 
					 
							   
	   

    return "${reach}${type} MK ${mark}"%_t % {reach = reachStr, type = type, mark = mark}
end

function getBasicName()
    return "Hyperspace Booster"%_t
end

function getIcon(seed, rarity)
    return "data/textures/icons/vortex.png"
end

function getEnergy(seed, rarity, permanent)
    local reach, cdfactor, efactor, _, _ = getBonuses(seed, rarity, permanent)
    return math.abs(cdfactor) * 2.5 * 1000 * 1000 * 1000 + math.abs(efactor) * 2.5 * 1000 * 1000 * 1000 + reach * 125 * 1000 * 1000
end

function getPrice(seed, rarity)
    local reach, cdfactor, efactor, _, _ = getBonuses(seed, rarity, true)
    local price = math.abs(cdfactor) * 100 * 350 + math.abs(efactor) * 100 * 250 + reach * 3000
    return price * 2.5 ^ rarity.value
end

function getTooltipLines(seed, rarity, permanent)
    local texts = {}
    local bonuses = {}
    local reach, cdfactor, efactor, _, _ = getBonuses(seed, rarity, permanent)
    local baseReach, baseCooldown, baseEnergy, _, _ = getBonuses(seed, rarity, false)

    -- Отображаем Jump Range, если он есть
    if reach ~= 0 then
        table.insert(texts, {ltext = "Jump Range"%_t, rtext = string.format("%+g", reach), icon = "data/textures/icons/star-cycle.png", boosted = permanent})
    end

    -- Отображаем Hyperspace Cooldown, если он есть
    if cdfactor ~= 0 then
        table.insert(texts, {ltext = "Hyperspace Cooldown"%_t, rtext = string.format("%+i%%", round(cdfactor * 100)), icon = "data/textures/icons/hourglass.png", boosted = permanent})
    end

    -- Отображаем Hyperspace Charge Energy, если он есть
    if efactor ~= 0 then
        table.insert(texts, {ltext = "Hyperspace Charge Energy"%_t, rtext = string.format("%+i%%", round(efactor * 100)), icon = "data/textures/icons/electric.png", boosted = permanent})
    end

    -- Проверяем бонусы для перманентной установки
    local betterReach, betterCooldown, betterEnergy, _, _ = getBonuses(seed, rarity, true)

    if betterReach ~= baseReach then
        table.insert(bonuses, {ltext = "Jump Range"%_t, rtext = string.format("%+g", betterReach - baseReach), icon = "data/textures/icons/star-cycle.png", boosted = permanent})
    end

    if betterCooldown ~= baseCooldown then
        table.insert(bonuses, {ltext = "Hyperspace Cooldown"%_t, rtext = string.format("%+i%%", round((betterCooldown - baseCooldown) * 100)), icon = "data/textures/icons/hourglass.png", boosted = permanent})
    end

    if betterEnergy ~= baseEnergy then
        table.insert(bonuses, {ltext = "Hyperspace Charge Energy"%_t, rtext = string.format("%+i%%", round((betterEnergy - baseEnergy) * 100)), icon = "data/textures/icons/electric.png", boosted = permanent})
    end

    if #bonuses == 0 then bonuses = nil end

    return texts, bonuses
end


function getComparableValues(seed, rarity)

    local base = {}
    local bonus = {}

    for _, p in pairs({{base, false}, {bonus, true}}) do
        local values = p[1]
        local permanent = p[2]

        local reach, cdfactor, efactor, _, _ = getBonuses(seed, rarity, permanent)

        if reach ~= 0 then
            table.insert(values, {name = "Jump Range"%_t, key = "jump_range", value = round(reach * 100), comp = UpgradeComparison.MoreIsBetter})
        end

						  
																																				   
		   

        if cdfactor ~= 0 then
            table.insert(values, {name = "Hyperspace Cooldown"%_t, key = "hs_cooldown", value = round(cdfactor * 100), comp = UpgradeComparison.LessIsBetter})
        end

        if efactor ~= 0 then
            table.insert(values, {name = "Hyperspace Charge Energy"%_t, key = "recharge_energy", value = round(efactor * 100), comp = UpgradeComparison.LessIsBetter})
        end

						   
																																					
		   
    end

    return base, bonus
end
