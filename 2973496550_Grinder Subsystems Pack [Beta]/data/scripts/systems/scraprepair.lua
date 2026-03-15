package.path = package.path .. ";data/scripts/systems/?.lua"
package.path = package.path .. ";data/scripts/lib/?.lua"
include ("basesystem")
include ("utility")
include ("randomext")
-- optimization so that energy requirement doesn't have to be read every frame
FixedEnergyRequirement = true
local healpertick = 0.0
local healpercent = 0.0
local cooldown = 0.0
local maxcooldown = 0.0
local hpPerC = 0.0
local missinghp = 0.0
--Copy and pasted from the energy Subsystem script lol
function getBonuses(seed, rarity, permanent)
    math.randomseed(seed)
    local regen = 0.25 -- base value, in percent
	local effic = 0.25 -- hp/c
	local basecool = 40
    -- add flat percentage based on rarity
    local regen = regen + (rarity.value + 2) * 0.02
	local effic = effic + rarity.value * 0.1
	local basecool = basecool + (rarity.value + 1) * 8
	--Choose one stat to specialize
	local spec = math.ceil(math.random() * 3)
	if spec == 0 then spec = 1 end
	if spec == 1 then regen = regen + (rarity.value + 1) * 0.015 end
	if spec == 2 then effic = effic + (rarity.value + 1) * 0.06 end
	if spec == 3 then basecool = math.ceil(basecool * 0.66) end

	if permanent then
		regen = regen * 1.25
		effic = effic * 2
	end
	regen = regen / 100
    return regen, effic, basecool, spec
end

function onInstalled(seed, rarity, permanent)
	regen, effic, basecool, spec = getBonuses(seed, rarity, permanent)
	maxcooldown = basecool
	cooldown = maxcooldown
	hpPerC = effic
	healpercent = regen
	entity = Entity()
	entity:registerCallback("onHullHit", "onHullHit")
end

function getUpdateInterval()
	return 0.5
end

function updateServer(timePassed)
    cooldown = cooldown - timePassed
    if cooldown > 0 then return end
    local s = Entity()
    if not s.durability then return end
    if s.durability == s.maxDurability then return end

    healpertick = s.maxDurability * healpercent / 2
    local scrapcost = healpertick / hpPerC

    if consumeScrap(s, scrapcost) then
        s.durability = math.min(s.durability + healpertick, s.maxDurability)
    end
end

function consumeScrap(entity, cost)
    local cargos = entity:getCargos()
    local totalScrapValue = 0

    for good, amount in pairs(cargos) do
        if good.tags and good.tags.scrap then
            totalScrapValue = totalScrapValue + (good.price * amount)
        end
    end

    if totalScrapValue < cost then
        return false
    end

    local remainingCost = cost
    for good, amount in pairs(cargos) do
        if good.tags and good.tags.scrap then
            local price = good.price
            local amountToRemove = math.min(amount, remainingCost / price)
            if amountToRemove > 0 then
                entity:removeCargo(good, amountToRemove)
                remainingCost = remainingCost - (price * amountToRemove)
                if remainingCost <= 0 then
                    return true
                end
            end
        end
    end

    return remainingCost <= 0
end

function onHullHit(objectIndex, blockIndex, shooterIndex, damage, location)
	cooldown = maxcooldown
end

function onUninstalled(seed, rarity, permanent)
end

function getName(seed, rarity)
    local regen, effic, basecool, spec = getBonuses(seed, rarity, permanent)
	math.randomseed(seed)

    local serial = ""
    if spec == 1 then serial = "Высокоточная" end
    if spec == 2 then serial = "Эффективная" end
    if spec == 3 then serial = "Быстрооткликающаяся" end

    local name = "Ремонтная система сварочного типа"


    return "${serial} ${name} R-${rarity} /* ex: Система быстрого ремонта в бою GW-XXV */"%_t % {serial = serial, name = name, rarity = toRomanLiterals(rarity.value+2)}
end

function getEnergy(seed, rarity, permanent)
	local ecost = 0 --You can use getBonuses to make returned stats effect the energy
    if rarity.value == 5 then ecost = 3400 --Legendary
	elseif rarity.value == 4 then ecost = 2300 --Exotic
	elseif rarity.value == 3 then ecost = 1600 --Exceptional
	elseif rarity.value == 2 then ecost = 900 --Rare
	elseif rarity.value == 1 then ecost = 600 --Uncommon
	elseif rarity.value == 0 then ecost = 500 --Common
	else ecost = 700 end --Junk
	if permanent then ecost = ecost * 1.23 end
    return ecost * 1000 * 1000 -- Megawatts, add another "* 1000" to get Gigawatts.
end

function getBasicName()
    return "Самосварочная ремонтная система"%_t
end

function getIcon(seed, rarity)
    return "data/textures/icons/auto-repair.png"
end


function getPrice(seed, rarity)
    local price = 200 * 400
    return price * 2 ^ rarity.value
end

function getTooltipLines(seed, rarity, permanent)

    local texts = {}
    local bonuses = {}
    local regen, effic, basecool, spec = getBonuses(seed, rarity, permanent)
    local baseregen, baseeffic = getBonuses(seed, rarity, false)

	table.insert(texts, {ltext = "% от корпуса восстанавливается в секунду"%_t, rtext = string.format("%+.2f%%", regen * 100), icon = "data/textures/icons/auto-repair.png", boosted = permanent})
	table.insert(bonuses, {ltext = "% от корпуса восстанавливается в секунду"%_t, rtext = string.format("%+.2f%%", baseregen * 0.5 * 100), icon = "data/textures/icons/auto-repair.png"})

	table.insert(texts, {ltext = "HP восстанавливается за стоимость металлолома в кредитах"%_t, rtext = string.format("%.2f", effic), icon = "data/textures/icons/scrap-metal.png", boosted = permanent})
	table.insert(bonuses, {ltext = "HP восстанавливается за стоимость металлолома в кредитах"%_t, rtext = string.format("%+.2f", baseeffic), icon = "data/textures/icons/scrap-metal.png"})

	table.insert(texts, {ltext = "Перезарядка после получения урона"%_t, rtext = createReadableShortTimeString(basecool), icon = "data/textures/icons/anticlockwise-rotation.png", boosted = permanent})
    return texts, bonuses
end

function getDescriptionLines(seed, rarity, permanent)
    local ramdamage = getBonuses(seed, rarity, permanent)

    local texts = {}
	table.insert(texts, {ltext = "Ремонтирует корпус, используя необработанный ресурсный лом в грузовом отсеке"%_t})

    return texts
end

function getComparableValues(seed, rarity)
    local regen, effic, basecool = getBonuses(seed, rarity, false)
    local base = {}
    local bonus = {}
	table.insert(base, {name = "% от недостающего корпуса восстанавливается в секунду"%_t, key = "percregen", value = regen * 100, comp = UpgradeComparison.MoreIsBetter})
	table.insert(bonus, {name = "% от недостающего корпуса восстанавливается в секунду"%_t, key = "percregen", value = regen * 0.5 * 100, comp = UpgradeComparison.MoreIsBetter})

	table.insert(base, {name = "HP восстанавливается за стоимость металлолома в кредитах"%_t, key = "efficHP", value = round(effic), comp = UpgradeComparison.MoreIsBetter})
	table.insert(bonus, {name = "HP восстанавливается за стоимость металлолома в кредитах"%_t, key = "efficHP", value = round(effic * 100), comp = UpgradeComparison.MoreIsBetter})

	table.insert(base, {name = "Перезарядка после получения урона"%_t, key = "coold", value = basecool, comp = UpgradeComparison.LessIsBetter})
    return base, bonus
end

