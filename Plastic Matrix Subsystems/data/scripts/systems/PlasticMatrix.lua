package.path = package.path .. ";data/scripts/systems/?.lua"
package.path = package.path .. ";data/scripts/lib/?.lua"
include ("basesystem")
include ("utility")
include ("randomext")

-- Optimization
FixedEnergyRequirement = true
Unique = true

local _ModName = "Plastic matrix"

local _RechargeAmount = 0
local _RechargeLimit = 0
local _RechargeCap = 50000
local _RechargeDebuff = 0.5

function getUpdateInterval()
    return 1
end

function updateServer(timePassed)
    if _RechargeAmount == 0 or _RechargeLimit == 0 then return end
    local e = Entity()
    local Recharge = 0
    if e.durability < e.maxDurability * _RechargeLimit then
        Recharge = _RechargeAmount * e.maxDurability / 2000
        if Recharge > _RechargeCap then
            Recharge = _RechargeCap + ((Recharge - _RechargeCap) * _RechargeDebuff)
        end
        e.durability = e.durability + Recharge
    end
end

function getBonuses(seed, rarity, permanent)
    math.randomseed(seed + 10)

    _RechargeAmount = round((rarity.value + 2) + math.random() * (rarity.value + 2), 1)

    if rarity.value >= 5 then _RechargeLimit = 90
    elseif rarity.value == 4 then _RechargeLimit = 82
    elseif rarity.value == 3 then _RechargeLimit = 74
    elseif rarity.value == 2 then _RechargeLimit = 66
    elseif rarity.value == 1 then _RechargeLimit = 58
    elseif rarity.value == 0 then _RechargeLimit = 50
    elseif rarity.value == -1 then _RechargeLimit = 42
    end
	_RechargeLimit = _RechargeLimit + math.random() * (rarity.value + 3)
    _RechargeLimit = round(_RechargeLimit / 100, 1)

    if not permanent then
        _RechargeLimit = 0
        _RechargeAmount = 0
    end
end

function onInstalled(seed, rarity, permanent)
    getBonuses(seed, rarity, permanent)
end

function onUninstalled(seed, rarity, permanent)
    getBonuses(seed, rarity, true)
end

function getName(seed, rarity)
    return "Пластичная матрица MK " .. toRomanLiterals(rarity.value + 2)
end

function getIcon(seed, rarity)
    return "data/textures/icons/RegenScales.png"
end

function getEnergy(seed, rarity, permanent)
	getBonuses(seed, rarity, permanent)
    local _TotalEnergy = 0
    if permanent then
        _TotalEnergy = (_RechargeAmount * 100 * 1000 * 1000 + _RechargeLimit * 1000 * 1000) * (1 + (rarity.value+1)/10)
    end
    return _TotalEnergy
end

function getPrice(seed, rarity)
    getBonuses(seed, rarity, true)
    return _RechargeLimit * _RechargeAmount * 4000 * 2.5 ^ (rarity.value+1)
end

function getTooltipLines(seed, rarity, permanent)
    local texts = {}
    local bonuses = {}

    getBonuses(seed, rarity, true)
    local _Rate = _RechargeAmount / 20
    local _Limit = _RechargeLimit * 100

    if permanent then
        table.insert(texts, {ltext = "Скорость ремонта корпуса"%_t, rtext = "${rate} %/с"%_t % { rate = _Rate}, icon = "data/textures/icons/repair.png", boosted = permanent})
        table.insert(texts, {ltext = "Лимит ремонта корпуса"%_t, rtext = "${limit} %"%_t % { limit = _Limit}, icon = "data/textures/icons/health-normal.png", boosted = permanent})
    end

    table.insert(bonuses, {ltext = "Скорость ремонта корпуса"%_t, rtext = "${rate} %/с"%_t % { rate = _Rate}, icon = "data/textures/icons/repair.png"})
    table.insert(bonuses, {ltext = "Лимит ремонта корпуса"%_t, rtext = "${limit} %"%_t % { limit = _Limit}, icon = "data/textures/icons/health-normal.png"})

    if #bonuses == 0 then bonuses = nil end

    return texts, bonuses
end

function getDescriptionLines(seed, rarity, permanent)
    local texts = {}

    table.insert(texts, {ltext = "Cинтетические сплавы."%_t})
    table.insert(texts, {ltext = "Сплавы будут реструктуровать поврежденную обшивку при подаче энергии. "%_t, icon = "data/textures/icons/nothing.png"})
    table.insert(texts, {ltext = "Восстановительные эффекты не могут восстановить потерянную обшивку"%_t, icon = "data/textures/icons/nothing.png"})            
    table.insert(texts, {ltext = "и имеют максимальный предел восстановления " .. (_RechargeLimit * 100) .."% от корпуса."%_t, icon = "data/textures/icons/nothing.png"})        
    table.insert(texts, {ltext = "Должен быть установлен на постоянной основе."%_t, icon = "data/textures/icons/nothing.png"})        
    -- table.insert(texts, {ltext = " "%_t})

    return texts
end
