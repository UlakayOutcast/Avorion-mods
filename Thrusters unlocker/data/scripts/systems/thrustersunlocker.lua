package.path = package.path .. ";data/scripts/systems/?.lua"
package.path = package.path .. ";data/scripts/lib/?.lua"
include ("basesystem")
include ("utility")
include ("randomext")

FixedEnergyRequirement = true
Unique = true

-- Таблица для хранения бонусов

function getBonuses(seed, rarity, permanent)
    math.randomseed(seed)

    -- % бонус к толкателям
    local thrustFactor = ((rarity.value + 2) * 15 + math.random() * 25) / 100

    -- % бонус к Отклонению(yaw)/Тангажу(Pitch)/Крену(roll)
    local pitchFactor = ((rarity.value + 2) * 5 + math.random() * 15) / 100
    local yawFactor = ((rarity.value + 2) * 5 + math.random() * 15) / 100
    local rollFactor = ((rarity.value + 2) * 5 + math.random() * 15) / 100

    if permanent then
        thrustFactor = thrustFactor * 1.5
        pitchFactor = pitchFactor * 1.5
        yawFactor = yawFactor * 1.5
        rollFactor = rollFactor * 1.5
    end

    return thrustFactor, pitchFactor, yawFactor, rollFactor
end

function onInstalled(seed, rarity, permanent)
    local thrusters = Thrusters()
    local shipId = Entity().id.value

    -- Получаем бонусы
    local thrustFactor, pitchFactor, yawFactor, rollFactor = getBonuses(seed, rarity, permanent)

    -- Применяем бонусы
    thrusters.thrust = thrusters.thrust + thrustFactor
    thrusters.basePitch = thrusters.basePitch + pitchFactor
    thrusters.baseYaw = thrusters.baseYaw + yawFactor
    thrusters.baseRoll = thrusters.baseRoll + rollFactor

    thrusters.fixedStats = true

    -- Регистрируем callback на изменения конструкции
    Entity():registerCallback("onBlockPlanChanged", "onBlockPlanChanged")
    -- Entity():registerCallback("onSystemsChanged", "onBlockPlanChanged")
end

function onBlockPlanChanged()
    local thrusters = Thrusters()
    local shipId = Entity().id.value
	thrusters.fixedStats = false

	local seed = getSeed()
	local rarity = getRarity()
	local permanent = getPermanent()
	local thrustFactor, pitchFactor, yawFactor, rollFactor = getBonuses(seed, rarity, permanent)
	-- Удаляем старые бонусы
	thrusters.thrust = thrusters.thrust * thrustFactor
	thrusters.basePitch = thrusters.basePitch + pitchFactor
	thrusters.baseYaw = thrusters.baseYaw + yawFactor
	thrusters.baseRoll = thrusters.baseRoll + rollFactor
	-- Применяем бонусы заново
	thrusters.thrust = thrusters.thrust + thrustFactor
	thrusters.basePitch = thrusters.basePitch + pitchFactor
	thrusters.baseYaw = thrusters.baseYaw + yawFactor
	thrusters.baseRoll = thrusters.baseRoll + rollFactor

	thrusters.fixedStats = true
end

function onUninstalled(seed, rarity, permanent)
    local thrusters = Thrusters()
    local shipId = Entity().id.value

	local thrustFactor, pitchFactor, yawFactor, rollFactor = getBonuses(seed, rarity, permanent)
	-- Удаляем бонусы
	thrusters.thrust = thrusters.thrust - thrustFactor
	thrusters.basePitch = thrusters.basePitch - pitchFactor
	thrusters.baseYaw = thrusters.baseYaw - yawFactor
	thrusters.baseRoll = thrusters.baseRoll - rollFactor

	thrusters.fixedStats = false

    -- Удаляем callback при удалении системы
    Entity():unregisterCallback("onBlockPlanChanged", "onBlockPlanChanged")
    -- Entity():unregisterCallback("onSystemsChanged", "onBlockPlanChanged")
end

function getName(seed, rarity)
    return "Система разгона толкателей"%_t
end

function getIcon(seed, rarity)
    return "data/textures/icons/thrusters.png"
end

function getEnergy(seed, rarity, permanent)
    local thrustFactor, pitchFactor, yawFactor, rollFactor = getBonuses(seed, rarity, permanent)
    return (thrustFactor + (pitchFactor + yawFactor + rollFactor) / 3) * 0.4 * 1000 * 1000 * 1000
end

function getPrice(seed, rarity)
    return 4500 * 3 ^ (rarity.value + 1)
end

function getTooltipLines(seed, rarity, permanent)
    local texts = {}
    local bonuses = {}
    local thrustFactor, pitchFactor, yawFactor, rollFactor = getBonuses(seed, rarity, permanent)
    local thrustFactorP, pitchFactorP, yawFactorP, rollFactorP = getBonuses(seed, rarity, true)

    table.insert(texts, {ltext = "Сила толкателей"%_t, rtext = string.format("%+i%%", round(thrustFactor * 100)), icon = "data/textures/icons/acceleration.png", boosted = permanent})
    table.insert(texts, {ltext = "Тангаж"%_t, rtext = string.format("%+i%%", round(pitchFactor * 100)), icon = "data/textures/icons/dodge.png", boosted = permanent})
    table.insert(texts, {ltext = "Рыскание"%_t, rtext = string.format("%+i%%", round(yawFactor * 100)), icon = "data/textures/icons/dodge.png", boosted = permanent})
    table.insert(texts, {ltext = "Крен"%_t, rtext = string.format("%+i%%", round(rollFactor * 100)), icon = "data/textures/icons/dodge.png", boosted = permanent})

    table.insert(bonuses, {ltext = "Сила толкателей"%_t, rtext = string.format("%+i%%", round(thrustFactorP * 100)), icon = "data/textures/icons/acceleration.png"})
    table.insert(bonuses, {ltext = "Тангаж"%_t, rtext = string.format("%+i%%", round(pitchFactorP * 100)), icon = "data/textures/icons/dodge.png"})
    table.insert(bonuses, {ltext = "Рыскание"%_t, rtext = string.format("%+i%%", round(yawFactorP * 100)), icon = "data/textures/icons/dodge.png"})
    table.insert(bonuses, {ltext = "Крен"%_t, rtext = string.format("%+i%%", round(rollFactorP * 100)), icon = "data/textures/icons/dodge.png"})

    return texts, bonuses
end

function getDescriptionLines(seed, rarity, permanent)
    local texts = {}

    table.insert(texts, {ltext = "Разгон толкателей"%_t})
    table.insert(texts, {ltext = "Усиливает толкатели, увеличивая их мощность"%_t, icon = "data/textures/icons/nothing.png", fontType = FontType.Normal, lcolor = ColorRGB(0.7, 0.7, 0.7)})

    return texts
end

function getComparableValues(seed, rarity)
    local thrustFactor, pitchFactor, yawFactor, rollFactor = getBonuses(seed, rarity, false)
    local thrustFactorP, pitchFactorP, yawFactorP, rollFactorP = getBonuses(seed, rarity, true)

    local base = {}
    local bonus = {}
    table.insert(base, {name = "Сила толкателей"%_t, key = "acceleration", value = round(thrustFactor * 100), comp = UpgradeComparison.MoreIsBetter})
    table.insert(base, {name = "Тангаж"%_t, key = "pitchyawroll", value = round(pitchFactor * 100), comp = UpgradeComparison.MoreIsBetter})
    table.insert(base, {name = "Рыскание"%_t, key = "pitchyawroll", value = round(yawFactor * 100), comp = UpgradeComparison.MoreIsBetter})
    table.insert(base, {name = "Крен"%_t, key = "pitchyawroll", value = round(rollFactor * 100), comp = UpgradeComparison.MoreIsBetter})

    table.insert(bonus, {name = "Сила толкателей"%_t, key = "acceleration", value = round(thrustFactorP * 100), comp = UpgradeComparison.MoreIsBetter})
    table.insert(bonus, {name = "Тангаж"%_t, key = "pitchyawroll", value = round(pitchFactorP * 100), comp = UpgradeComparison.MoreIsBetter})
    table.insert(bonus, {name = "Рыскание"%_t, key = "pitchyawroll", value = round(yawFactorP * 100), comp = UpgradeComparison.MoreIsBetter})
    table.insert(bonus, {name = "Крен"%_t, key = "pitchyawroll", value = round(rollFactorP * 100), comp = UpgradeComparison.MoreIsBetter})

    return base, bonus
end
