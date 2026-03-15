-- Этот файл предназначен для версии 2.0 Beta
package.path = package.path .. ";data/scripts/systems/?.lua"
package.path = package.path .. ";data/scripts/lib/?.lua"
include ("basesystem")
include ("utility")
include ("randomext")

-- Оптимизация, чтобы требование энергии не нужно было считывать каждый кадр
FixedEnergyRequirement = true


-- Бонусные турели используют коэффициент 2 для определения бонусных слотов для турелей
function getNumBonusTurrets(seed, rarity, permanent)
	if permanent then
		return math.max(2, (rarity.value * 2) + 2)
	end
	return 0
end

-- Теперь мы используем коэффициент 4 для расчета базовых значений турелей
function getNumTurrets(seed, rarity, permanent)
	math.randomseed(seed)
	
	local baseTurrets = math.max(4, rarity.value + 4)
	local turrets = baseTurrets + getNumBonusTurrets(seed, rarity, permanent)
	return turrets, 0, 0
end

function onInstalled(seed, rarity, permanent)
	local turrets, pdcs, autos = getNumTurrets(seed, rarity, permanent)
	
	addMultiplyableBias(StatsBonuses.PointDefenseTurrets, turrets)

end

function onUninstalled(seed, rarity, permanent)
end

function getName(seed, rarity)
	local turrets, pdcs, autos = getNumTurrets(seed, rarity, true)

	local ids = "PD"
	if autos > 0 then ids = ids .. "I" end	
	
	return "Подсистема управления оборонительными турелями ${ids}-TCS-${num}"%_t % {num = turrets + autos, ids = ids}

end

function getIcon(seed, rarity)
	return "data/textures/icons/turret.png"
end

function getEnergy(seed, rarity, permanent)
	local turrets, pdcs, autos = getNumTurrets(seed, rarity, permanent)
	return turrets * 200 * 1000 * 1000 / (1.05 ^ rarity.value)
end

function getPrice(seed, rarity)
	local turrets, _, _ = getNumTurrets(seed, rarity, false)
	local _, _, autos = getNumTurrets(seed, rarity, true)
	
	local price = 5000 * (turrets + autos * 0.5)
	return price * 2.8 ^ rarity.value
end

function getTooltipLines(seed, rarity, permanent)
	local turrets, _ = getNumTurrets(seed, rarity, permanent)
	local _, pdcs, autos = getNumTurrets(seed, rarity, true)
	
	local texts = {}
	local bonuses = {}

	table.insert(texts, {ltext = "Слоты оборонительных турелей"%_t, rtext = "+" .. turrets, icon = "data/textures/icons/turret.png", boosted = permanent})

	table.insert(bonuses, {ltext = "Слоты оборонительных турелей"%_t, rtext = "+" .. getNumBonusTurrets(seed, rarity, true), icon = "data/textures/icons/turret.png"})
	
	return texts, bonuses
end

function getDescriptionLines(seed, rarity, permanent)
	return
	{
		{ltext = "Система управления оборонительными турелями"%_t, rtext = "", icon = ""},
		{ltext = "Добавляет слоты для оборонительных турелей"%_t, rtext = "", icon = ""}
	}
end

function getComparableValues(seed, rarity)
	local turrets = getNumTurrets(seed, rarity, false)
	local bonusTurrets = getNumBonusTurrets(seed, rarity, true)
	local _, pdcs, autos = getNumTurrets(seed, rarity, true)

	return
	{
		{name = "Слоты оборонительных турелей"%_t, key = "pdc_slots", value = turrets, comp = UpgradeComparison.MoreIsBetter},
	},
	{
		{name = "Слоты оборонительных турелей"%_t, key = "pdc_slots", value = bonusTurrets, comp = UpgradeComparison.MoreIsBetter},
	}
end