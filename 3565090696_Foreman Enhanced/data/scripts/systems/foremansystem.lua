package.path = package.path .. ";data/scripts/systems/?.lua"
package.path = package.path .. ";data/scripts/lib/?.lua"
include ("basesystem")
include ("utility")
include ("randomext")
FixedEnergyRequirement = true
PermanentInstallationOnly = true
Unique = true
function getBonuses(inSeed, inRarity, inPermanent)
    math.randomseed(inSeed)
    local squads = getNumSquads(inSeed, inRarity, inPermanent)
    local maxSquads = 10
    if inRarity.value <= 3 then
        maxSquads = maxSquads - inRarity.value * 2
    end
    local scanRarity = inRarity.value
    local sectorScanningSpeed = 0
    if scanRarity == RarityType.Petty then sectorScanningSpeed = 120
    elseif scanRarity == RarityType.Common then sectorScanningSpeed = 60
    elseif scanRarity == RarityType.Uncommon then sectorScanningSpeed = 45
    elseif scanRarity == RarityType.Rare then sectorScanningSpeed = 30
    elseif scanRarity == RarityType.Exceptional then sectorScanningSpeed = 20
    elseif scanRarity == RarityType.Exotic then sectorScanningSpeed = 15
    elseif scanRarity == RarityType.Legendary then sectorScanningSpeed = 10
    end
    local r = math.random()
    local scanAccuracy = inRarity.value-1
    if ((inRarity.value == 1 or inRarity.value == 2) and r < 0.25) or (inRarity.value == 3 and r < 0.5) then
        scanAccuracy = scanAccuracy + 1
    end
    scanAccuracy = math.min(4, scanAccuracy)
    local miningMaterial = inRarity.value + 2
    r = math.random()
    if inRarity.value < 1 then
        miningMaterial = miningMaterial - 1
    elseif inRarity.value >= 1 and r < 0.2 then
        miningMaterial = miningMaterial + 1
    end
    local fighterCargoPickup = 0
    local fighterPickUpLoot = false
    r = math.random()
    if inRarity.value == RarityType.Rare then fighterCargoPickup = (r < 0.5 and 1 or 0)
    elseif inRarity.value == RarityType.Exceptional then fighterCargoPickup =  1
    elseif inRarity.value == RarityType.Exotic then fighterCargoPickup =  1
    elseif inRarity.value == RarityType.Legendary then fighterCargoPickup = 1
    end
    r = math.random()
    if inRarity.value == RarityType.Rare and not fighterCargoPickup then fighterPickUpLoot = r < 0.5
    elseif inRarity.value == RarityType.Exceptional then fighterPickUpLoot =  r < 0.75
    elseif inRarity.value == RarityType.Exotic then fighterPickUpLoot =  true
    elseif inRarity.value == RarityType.Legendary then fighterPickUpLoot = true
    end
    return squads, maxSquads, miningMaterial, fighterCargoPickup, fighterPickUpLoot, sectorScanningSpeed, scanAccuracy
end
function getNumSquads(inSeed, inRarity, inPermanent)
    if inRarity.value > 2 then
        return math.max(1, math.ceil((inRarity.value + 1.5) / 2))
    end
    return 0
end
function onInstalled(inSeed, inRarity, inPermanent)
    local squads, maxSquads, miningMaterial, fighterCargoPickup, fighterPickUpLoot, sectorScanningSpeed, scanAccuracy = getBonuses(inSeed, inRarity, inPermanent)
    addAbsoluteBias(StatsBonuses.FighterSquads, squads)
    if fighterCargoPickup then
        addAbsoluteBias(StatsBonuses.FighterCargoPickup, fighterCargoPickup)
    end
end
function onUninstalled(inSeed, inRarity, inPermanent)
end
function getName(inSeed, inRarity)
    local squads, maxSquads, miningMaterialLevel, fighterCargoPickup, fighterPickUpLoot, sectorScanningSpeed, scanAccuracy = getBonuses(inSeed, inRarity, true)
    local classes = {}
    classes[RarityType.Legendary] = "Класс S"%_t
    classes[RarityType.Exotic] = "Класс A"%_t
    classes[RarityType.Exceptional] = "Класс B"%_t
    classes[RarityType.Rare] = "Класс C"%_t
    classes[RarityType.Uncommon] = "Класс D"%_t
    classes[RarityType.Common] = "Класс E"%_t
    classes[RarityType.Petty] = "Класс F"%_t
    miningMaterialLevel = miningMaterialLevel
    local name
    if miningMaterialLevel == inRarity.value + 3 then
        name = "Вспомогательная подсистема мастера"%_t
    else
        name = "Подсистема мастера"%_t
    end
    local matStr = "000"
    if miningMaterialLevel > 0 then
        matStr = tostring(miningMaterialLevel * 100)
    end
    return "${class}-${material} ${name} /* ex: Подсистема вспомогательного мастера класса C-600 */"%_t % {class = classes[inRarity.value], name = name, material = matStr}
end
function getIcon(inSeed, inRarity)
    return "data/textures/icons/foreman_subsystem.png"
end
function getEnergy(inSeed, inRarity, inPermanent)
    local squads, maxSquads, materialLevel, cargo, loot, speed, accuracy = getBonuses(inSeed, inRarity, true)
    if not inPermanent then return 0 end
    return (squads +  3 * materialLevel + 6 * cargo + 6 * (loot == true and 1 or 0) + (30-math.min(25,speed)) * 1 + accuracy * 2) * 75 * 1000 * 1000 / (0.8 ^ inRarity.value)
end
function getPrice(inSeed, inRarity)
    local squads, maxSquads, miningMaterialLevel, fighterCargoPickup, fighterPickUpLoot, sectorScanningSpeed, scanAccuracy = getBonuses(inSeed, inRarity, true)
    local price = 25000 * (squads) + 50000 * miningMaterialLevel + 170000 * fighterCargoPickup + 170000 * (fighterPickUpLoot == true and 1 or 0) + (30-math.min(25,sectorScanningSpeed)) * 500 + (scanAccuracy + 2) * 50000
    return price * 1.4 ^ inRarity.value
end
function getTooltipLines(inSeed, inRarity, inPermanent)
    local squads, maxSquads, miningMaterialLevel, fighterCargoPickup, fighterPickUpLoot, sectorScanningSpeed, scanAccuracy = getBonuses(inSeed, inRarity, inPermanent)
    local texts = {}
    local bonuses = {}
    local material = Material(miningMaterialLevel)
    table.insert(texts, {ltext = "Модуль мастера"%_t, rtext = "", icon = ""})
    local accuracyTable = {}
    accuracyTable[0] = {l = "В секторе есть астероиды для сбора (Командование)"%_t, r ="Да/Нет"%_t}
    accuracyTable[1] = {l = "Точность количества добычи (Командование)"%_t, r ="Количество астероидов"%_t}
    accuracyTable[2] = {l = "Точность количества добычи (Командование)"%_t, r ="Оценка"%_t}
    accuracyTable[3] = {l = "Точность количества добычи (Командование)"%_t, r ="Всего"%_t}
    accuracyTable[4] = {l = "Точность количества добычи (Командование)"%_t, r ="Всего + точно по руде"%_t}
    if inPermanent then
        table.insert(texts, {ltext = "Уровень сканирования астероидов"%_t, rtext = material.name%_t, rcolor = material.color, icon = "data/textures/icons/asteroid-scan-level.png", boosted = inPermanent})
        if scanAccuracy >= 0 then
            table.insert(texts, {ltext = accuracyTable[scanAccuracy].l, rtext = accuracyTable[scanAccuracy].r, icon = "data/textures/icons/asteroid.png", boosted = inPermanent})
        end
        table.insert(texts, {ltext = "Скорость сканирования сектора"%_t, rtext = sectorScanningSpeed.."s", icon = "data/textures/icons/signal-range.png", boosted = inPermanent})
        if fighterPickUpLoot == true  then
            table.insert(texts, {ltext = "Подбор добычи истребителями"%_t, rtext = (fighterPickUpLoot and "Да" or "Нет"), icon = "data/textures/icons/fighter.png", boosted = inPermanent})
        end
        if fighterCargoPickup == 1  then
            table.insert(texts, {ltext = "Подбор груза истребителями"%_t, rtext = (fighterCargoPickup and "Да" or "Нет"), icon = "data/textures/icons/fighter.png", boosted = inPermanent})
        end
        if squads > 0 then
            table.insert(texts, {ltext = "Эскадрильи истребителей"%_t, rtext = "+" .. squads, icon = "data/textures/icons/fighter.png", boosted = inPermanent})
        end
    end
    table.insert(bonuses, {ltext = "Уровень сканирования астероидов"%_t, rtext = material.name%_t, rcolor = material.color, icon = "data/textures/icons/asteroid-scan-level.png"})
    if scanAccuracy >= 0 then
        table.insert(bonuses, {ltext = accuracyTable[scanAccuracy].l, rtext = accuracyTable[scanAccuracy].r, icon = "data/textures/icons/asteroid.png"})
    end
    table.insert(bonuses, {ltext = "Скорость сканирования сектора"%_t, rtext = sectorScanningSpeed.."s", icon = "data/textures/icons/signal-range.png"})
    table.insert(bonuses, {ltext = "Подбор добычи истребителями"%_t, rtext = (fighterPickUpLoot and "Да" or "Нет"), icon = "data/textures/icons/fighter.png"})
    table.insert(bonuses, {ltext = "Подбор груза истребителями"%_t, rtext = (fighterCargoPickup and "Да" or "Нет"), icon = "data/textures/icons/fighter.png"})
    if squads > 0 then
        table.insert(bonuses, {ltext = "Эскадрильи истребителей"%_t, rtext = "+" .. squads, icon = "data/textures/icons/fighter.png"})
    end
    return texts, bonuses
end
function getDescriptionLines(inSeed, inRarity, inPermanent)
    local squads, maxSquads, miningMaterialLevel, fighterCargoPickup, fighterPickUpLoot, sectorScanningSpeed, scanAccuracy = getBonuses(inSeed, inRarity, inPermanent)
    local texts = {}
    if miningMaterialLevel > 0 then
        table.insert(texts, {ltext = "Сканирует и управляет истребителями до материала"%_t, rtext = "", icon = ""})
    end
    if squads > 0 then
        table.insert(texts, {ltext = "Управляет дополнительными эскадрильями истребителей"%_t, rtext = "", icon = ""})
        table.insert(texts, {ltext = "Макс. эскадрилий: 10"%_t, rtext = "", icon = ""})
    end
    if fighterPickUpLoot == true then
        table.insert(texts, {ltext = "Истребители подбирают ценную добычу"%_t, rtext = "", icon = ""})
    end
    if fighterCargoPickup == 1 then
        table.insert(texts, {ltext = "Позволяет истребителям подбирать груз"%_t, rtext = "", icon = ""})
        table.insert(texts, {ltext = "Для работы требуется транспортный блок на вашем корабле"%_t, rtext = "", icon = ""})
    end
    return texts
end
function getComparableValues(inSeed, inRarity)
    local squads, maxSquads, miningMaterialLevel, fighterCargoPickup, fighterPickUpLoot, sectorScanningSpeed, scanAccuracy = getBonuses(inSeed, inRarity, inPermanent)
    local base, bonus = {}, {}
    if squads > 0 then
        table.insert(bonus, {name = "Эскадрильи истребителей"%_t, key = "fighter_squads", value = squads, comp = UpgradeComparison.MoreIsBetter})
    end
    table.insert(bonus, {name = "Макс. эскадрилий"%_t, key = "max_fighter_squads", value = maxSquads, comp = UpgradeComparison.MoreIsBetter})
    table.insert(bonus, {name = "Уровень материала сканирования астероидов"%_t, key = "asteroid_scan_material_level", value = miningMaterialLevel, comp = UpgradeComparison.MoreIsBetter})
    table.insert(bonus, {name = "Подбор груза истребителями"%_t, key = "fighter_cargo", value = (fighterCargoPickup == 1) and 1 or 0, comp = UpgradeComparison.MoreIsBetter})
    table.insert(bonus, {name = "Истребители подбирают ценную добычу"%_t, key = "fighter_pickup_loot", value = (fighterPickUpLoot == true) and 1 or 0, comp = UpgradeComparison.MoreIsBetter})
    table.insert(bonus, {name = "Скорость сканирования сектора"%_t, key = "sector_scan_speed", value = sectorScanningSpeed, comp = UpgradeComparison.LessIsBetter})
    if scanAccuracy > -1 then
        table.insert(bonus, {name = "Точность количества добычи"%_t, key = "mining_amount_accuracy", value = scanAccuracy, comp = UpgradeComparison.MoreIsBetter})
    end
    return base, bonus
end

