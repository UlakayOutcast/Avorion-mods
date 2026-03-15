package.path = package.path .. ";data/scripts/systems/?.lua"
package.path = package.path .. ";data/scripts/lib/?.lua"
include ("basesystem")
include ("utility")
include ("relations")
include ("randomext")
include ("goods")
local UpgradeGenerator = include ("upgradegenerator")
local SectorTurretGenerator = include ("sectorturretgenerator")
-- optimization so that energy requirement doesn't have to be read every frame
FixedEnergyRequirement = true
Unique = true
-- Initial Cooldowns
local bonuscool = 12
local lootcool = 12
local stealcool = 1
--Probably a better way to do the regular variables but im bad at coding
local gstealchancemin, gstealchancemax, gstealamount, gstealbonus, gstealloot, gclearstolen = 0, 0, 0, false, false, 0
function getBonuses(seed, rarity, permanent)
    math.randomseed(seed)
	local stealchancemin = (rarity.value + 2) * 2
	local stealchancemax = (rarity.value + 2) * 6
	local stealamount = (rarity.value + 2) * 6
	local stealbonus = false
	local stealloot = false
	local clearstolen = 0
	local bonus = math.random()
	-- if exceptional or higher give one extra bonus
	if rarity.value >= 2 and permanent then
		if bonus < 0.5 then
			stealbonus = true
		else stealloot = true
		end
	end
	-- leggys get both bonuses :)
	if rarity.value == 5 and permanent then
		stealbonus = true
		stealloot = true
	end
	if permanent then
		stealchancemin = stealchancemin * 1.5
		stealchancemax = stealchancemax * 1.5
		stealamount = stealamount * 2
		clearstolen = (rarity.value + 2) * 5
	end
	stealchancemin = stealchancemin / 100
	stealchancemax = stealchancemax / 100
	stealamount = stealamount / 100
	clearstolen = clearstolen / 100
	return stealchancemin, stealchancemax, stealamount, stealbonus, stealloot, clearstolen
end

function getUpdateInterval()
	return 1
end

function updateServer(timePassed)
	bonuscool = bonuscool - 1
	lootcool = lootcool - 1
	stealcool = stealcool - 1
	--print(bonuscool, lootcool)
end

function onInstalled(seed, rarity, permanent)
	local entity = Entity()
	entity:registerCallback("onCollision", "onCollision")
	gstealchancemin, gstealchancemax, gstealamount, gstealbonus, gstealloot, gclearstolen = getBonuses(seed, rarity, permanent)
end

function onUninstalled(seed, rarity, permanent)
end

--The collision thing is here, I suck at coding so things might suck
function onCollision(entityA, entityB, damageToA, damageToB, steererA, steererB)
	--print("Collision detected")
	if stealcool > 0 then return end --So that grinding against a ship doesn't cause lag
	stealcool = 1
	--print("steal chance loaded")
	local shipA = Entity(entityA)
	local shipB = Entity(entityB)
	local damageB = damageToB
	math.randomseed(os.time())
	if not shipB.durability then return end
	--Dont want players stealing from each other
	if not shipB.aiOwned then return end
	local stealchancemin, stealchancemax, stealamount, stealbonus, stealloot, clearstolen = gstealchancemin, gstealchancemax, gstealamount, gstealbonus, gstealloot, gclearstolen
	--print(stealchancemin, stealchancemax, stealamount, stealbonus, stealloot, clearstolen)
	if damageB > -1 then
		local victimdurabilityper = shipB.durability / shipB.maxDurability
		if victimdurabilityper < 0.3 then victimdurabilityper = 0.3 end
		--print(victimdurabilityper)
		local stealchance = lerp(victimdurabilityper, 0.3, 1, stealchancemax, stealchancemin)
		--print(stealchance, math.random())
		if math.random() < stealchance then
			--print("steal successful")
			steal(shipB, shipA, stealamount, clearstolen)
			if stealbonus and math.random() < 0.04 then
				stealhidden(shipB, shipA)
			end
			if stealloot and math.random() < 0.02 then
				getloot()
			end
		end
	end
end
function steal(evic, estealer, tosteal, purechance)
	-- Start variables
	local shipB = evic
	local shipA = estealer
	local cargoA = CargoBay(shipA)
	local clearstolen = purechance
	local Afaction = Faction()
	local Bfaction = Faction(shipB.factionIndex)
	local tstealamount = tosteal * (shipB.maxCargoSpace - shipB.freeCargoSpace)
	--print(shipB.freeCargoSpace, shipB.maxCargoSpace - shipB.freeCargoSpace, "=", shipB.numCargos)
	if tstealamount > shipA.freeCargoSpace then stealamount = shipA.freeCargoSpace end
	if not cargoA.pickUpStolen then return end
	repeat
		for good, amount in pairs(shipB:getCargos()) do
			local sacked = copy(good)
			local amounttosteal = amount * 0.2
			if purechance == 0 or purechance < math.random() then --check if clear stolen check failed
				sacked.stolen = true
			end
			if (sacked.size * amounttosteal) > (tstealamount * sacked.size) then
				amounttosteal = tstealamount * sacked.size
				tstealamount = -1
			end
			shipA:addCargo(sacked, amounttosteal)
			shipB:removeCargo(good, amounttosteal)
			changeRelations(Afaction, Bfaction, -(amounttosteal * sacked.price * 0.005), RelationChangeType.GeneralIllegal, true, true, shipB)
			tstealamount = tstealamount - math.ceil(amount * 0.2 * sacked.size)
			if tstealamount < 0 then return end
		end
	until (tstealamount < 1)
end

function stealhidden(evic, estealer)
	if bonuscool > 0 then return end
	bonuscool = 6
	local shipA = estealer
	local shipB = evic
	local cargo = CargoBay(shipA)
	local goodtogive = ""
	local amounttogive = 0
	local randhidden = math.random()
	if randhidden < 0.1 then randhidden, goodtogive = "Display", 1
	elseif randhidden >= 0.1 and randhidden < 0.2 then goodtogive, amounttogive = "Ammunition", 3
	elseif randhidden >= 0.2 and randhidden < 0.3 then goodtogive, amounttogive = "Energy Tube", 4
	elseif randhidden >= 0.3 and randhidden < 0.4 then goodtogive, amounttogive = "Servo", 10
	elseif randhidden >= 0.4 and randhidden < 0.5 then goodtogive, amounttogive = "Diamond", 15
	elseif randhidden >= 0.5 and randhidden < 0.6 then goodtogive, amounttogive = "Energy Container", 3
	elseif randhidden >= 0.6 and randhidden < 0.7 then goodtogive, amounttogive = "Targeting Card", 1
	elseif randhidden >= 0.7 and randhidden < 0.8 then goodtogive, amounttogive = "Processor", 1
	elseif randhidden >= 0.8 and randhidden < 0.9 then goodtogive, amounttogive = "Gem", 25
	else goodtogive, amounttogive = "Platinum",  15 end
	--print(goodtogive, amounttogive)
	shipA:addCargo(goods[goodtogive]:good(), amounttogive)
end

function getloot()
	if lootcool > 0 then return end
	lootcool = 12
	--copied from entitydbg.lua
	local x, y = Sector():getCoordinates()
	local generator = UpgradeGenerator()
	local player = Player()
	if math.random() > 0.5 then
		local upgrade = generator:generateSectorSystem(x, y)
		player:getInventory():add(upgrade)
	else
		local turret = SectorTurretGenerator():generate(x, y)
		player:getInventory():addOrDrop(InventoryTurret(turret))
	end
end

function getName(seed, rarity)
	math.randomseed(seed)

    local serial = ""
	if rarity.value < 2 then serial = "Базовый"
	elseif rarity.value >= 2 and rarity.value < 5 then serial = "Передовой"
	else serial = "Превосходный" end

    local name = "Система дронов-грузоломов"


    return "${serial} ${name} Con-${rarity} /* ex: Усовершенствованная Подсистема Крушитель Con-X */"%_t % {serial = serial, name = name, rarity = toRomanLiterals((rarity.value+2) * 10)}
end

function getEnergy(seed, rarity, permanent)
	local ecost = 0 --You can use getBonuses to make returned stats effect the energy
    if rarity.value == 5 then ecost = 3150 --Legendary
	elseif rarity.value == 4 then ecost = 1800 --Exotic
	elseif rarity.value == 3 then ecost = 1500 --Exceptional
	elseif rarity.value == 2 then ecost = 1230 --Rare
	elseif rarity.value == 1 then ecost = 950 --Uncommon
	elseif rarity.value == 0 then ecost = 600 --Common
	else ecost = 400 end --Junk
    return ecost * 1000 * 1000 -- Megawatts, add another "* 1000" to get Gigawatts.
end

function getBasicName()
    return "Система дронов-грузоломов"%_t
end

function getIcon(seed, rarity)
    return "data/textures/icons/snatch.png"
end


function getPrice(seed, rarity)
    local base = getBonuses(seed, rarity)
    local price = (base + 4) * 70 * 40
    return price ^ (1 + (rarity.value / 8))
end

function getTooltipLines(seed, rarity, permanent)

    local texts = {}
    local bonuses = {}
    local stealchancemin, stealchancemax, stealamount, stealbonus, stealloot, clearstolen = getBonuses(seed, rarity, permanent)
    local basemin, basemax, basesteal = getBonuses(seed, rarity, false)
	local bonusmin, bonusmax, bonussteal, bonusstealbonus, bonusloot, bonusclear = getBonuses(seed, rarity, true)

	table.insert(texts, {ltext = "Шанс украсть (зависит от корпуса жертвы)"%_t, rtext = string.format("%i%% - %i%%", round(stealchancemin * 100), round(stealchancemax * 100)) , icon = "data/textures/icons/snatch.png", boosted = permanent})
	table.insert(bonuses, {ltext = "Шанс украсть (зависит от корпуса жертвы)"%_t, rtext = string.format("%i%% - %i%%", round(basemin * 100 * 1.5), round(basemax * 100 * 1.5)), icon = "data/textures/icons/snatch.png"})

	table.insert(texts, {ltext = "Количество украденного груза жертвы"%_t, rtext = string.format("%i%%", round(stealamount * 100)), icon = "data/textures/icons/procure-command.png", boosted = permanent})
	table.insert(bonuses, {ltext = "Количество украденного груза жертвы"%_t, rtext = string.format("%i%%", round(bonussteal * 100)), icon = "data/textures/icons/procure-command.png"})

	table.insert(texts, {ltext = "Шанс, что украденный груз не будет помечен как украденный"%_t, rtext = string.format("%i%%", round(clearstolen * 100)), icon = "data/textures/icons/spray-can.png", boosted = permanent})
	table.insert(bonuses, {ltext = "Шанс, что украденный груз не будет помечен как украденный"%_t, rtext = string.format("%i%%", round(bonusclear * 100)), icon = "data/textures/icons/spray-can.png"})
	local toYesNo = function(line, value)
        if value then
            line.rtext = "Да"%_t
            line.rcolor = ColorRGB(0.3, 1.0, 0.3)
        else
            line.rtext = "Нет"%_t
            line.rcolor = ColorRGB(1.0, 0.3, 0.3)
        end
    end

	table.insert(texts, {ltext = "Может украсть бонусный скрытый груз"%_t, icon = "data/textures/icons/integrity.png"})
    toYesNo(texts[#texts], stealbonus)
	table.insert(bonuses, {ltext = "Может украсть бонусный скрытый груз"%_t, icon = "data/textures/icons/integrity.png"})
    toYesNo(bonuses[#bonuses], bonusstealbonus)

	table.insert(texts, {ltext = "Может получить турели и подсистемы"%_t, icon = "data/textures/icons/circuitry.png"})
    toYesNo(texts[#texts], stealloot)
	table.insert(bonuses, {ltext = "Может получить турели и подсистемы"%_t, icon = "data/textures/icons/circuitry.png"})
    toYesNo(bonuses[#bonuses], bonusloot)
    return texts, bonuses
end

function getDescriptionLines(seed, rarity, permanent)
    local ramdamage = getBonuses(seed, rarity, permanent)

    local texts = {}
	table.insert(texts, {ltext = "Крадет груз при столкновении с кораблями или станциями, управляемыми не игроками, шанс увеличивается по мере уменьшения корпуса жертвы"%_t})
	table.insert(texts, {ltext = "Системы более высокой редкости могут даже украсть бонусный ценный груз и получить некоторые турели и подсистемы"%_t})
	table.insert(texts, {ltext = "Требуется, чтобы грузовой отсек был настроен на подбор украденных предметов"%_t})
    return texts
end

function getComparableValues(seed, rarity)
    local stealchancemin, stealchancemax, stealamount, stealbonus, stealloot, clearstolen = getBonuses(seed, rarity, true)
	local intstealbonus, intstealloot = 0, 0
	if stealbonus then intstealbonus = 1 end
	if stealloot then intstealloot = 1 end
	local base = {}
	local bonus = {}
	table.insert(bonus, {name = "Может украсть бонусную добычу"%_t, key = "canstealbonus", value = intstealbonus, comp = UpgradeComparison.MoreIsBetter})
    table.insert(bonus, {name = "Может получить подсистемы и турели"%_t, key = "canstealloot", value = intstealloot, comp = UpgradeComparison.MoreIsBetter})    local base = {}
    return base, bonus
end


function getTooltipLines(seed, rarity, permanent)

    local texts = {}
    local bonuses = {}
    local stealchancemin, stealchancemax, stealamount, stealbonus, stealloot, clearstolen = getBonuses(seed, rarity, permanent)
    local basemin, basemax, basesteal = getBonuses(seed, rarity, false)
	local bonusmin, bonusmax, bonussteal, bonusstealbonus, bonusloot, bonusclear = getBonuses(seed, rarity, true)

	table.insert(texts, {ltext = "Шанс украсть (зависит от корпуса жертвы)"%_t, rtext = string.format("%i%% - %i%%", round(stealchancemin * 100), round(stealchancemax * 100)) , icon = "data/textures/icons/snatch.png", boosted = permanent})
	table.insert(bonuses, {ltext = "Шанс украсть (зависит от корпуса жертвы)"%_t, rtext = string.format("%i%% - %i%%", round(basemin * 100 * 1.5), round(basemax * 100 * 1.5)), icon = "data/textures/icons/snatch.png"})

	table.insert(texts, {ltext = "Количество украденного груза жертвы"%_t, rtext = string.format("%i%%", round(stealamount * 100)), icon = "data/textures/icons/procure-command.png", boosted = permanent})
	table.insert(bonuses, {ltext = "Количество украденного груза жертвы"%_t, rtext = string.format("%i%%", round(bonussteal * 100)), icon = "data/textures/icons/procure-command.png"})

	table.insert(texts, {ltext = "Шанс, что украденный груз не будет помечен как украденный"%_t, rtext = string.format("%i%%", round(clearstolen * 100)), icon = "data/textures/icons/spray-can.png", boosted = permanent})
	table.insert(bonuses, {ltext = "Шанс, что украденный груз не будет помечен как украденный"%_t, rtext = string.format("%i%%", round(bonusclear * 100)), icon = "data/textures/icons/spray-can.png"})
	local toYesNo = function(line, value)
        if value then
            line.rtext = "Да"%_t
            line.rcolor = ColorRGB(0.3, 1.0, 0.3)
        else
            line.rtext = "Нет"%_t
            line.rcolor = ColorRGB(1.0, 0.3, 0.3)
        end
    end

	table.insert(texts, {ltext = "Может украсть бонусный скрытый груз"%_t, icon = "data/textures/icons/integrity.png"})
    toYesNo(texts[#texts], stealbonus)
	table.insert(bonuses, {ltext = "Может украсть бонусный скрытый груз"%_t, icon = "data/textures/icons/integrity.png"})
    toYesNo(bonuses[#bonuses], bonusstealbonus)

	table.insert(texts, {ltext = "Может получить турели и подсистемы"%_t, icon = "data/textures/icons/circuitry.png"})
    toYesNo(texts[#texts], stealloot)
	table.insert(bonuses, {ltext = "Может получить турели и подсистемы"%_t, icon = "data/textures/icons/circuitry.png"})
    toYesNo(bonuses[#bonuses], bonusloot)
    return texts, bonuses
end

function getDescriptionLines(seed, rarity, permanent)
    local ramdamage = getBonuses(seed, rarity, permanent)

    local texts = {}
	table.insert(texts, {ltext = "Крадет груз при столкновении с кораблями или станциями, управляемыми не игроками, шанс увеличивается по мере уменьшения корпуса жертвы"%_t})
	table.insert(texts, {ltext = "Системы более высокой редкости могут даже украсть бонусный ценный груз и получить некоторые турели и подсистемы"%_t})
	table.insert(texts, {ltext = "Требуется, чтобы грузовой отсек был настроен на подбор украденных предметов"%_t})
    return texts
end

function getComparableValues(seed, rarity)
    local stealchancemin, stealchancemax, stealamount, stealbonus, stealloot, clearstolen = getBonuses(seed, rarity, true)
	local intstealbonus, intstealloot = 0, 0
	if stealbonus then intstealbonus = 1 end
	if stealloot then intstealloot = 1 end
	local base = {}
	local bonus = {}
	table.insert(bonus, {name = "Может украсть бонусную добычу"%_t, key = "canstealbonus", value = intstealbonus, comp = UpgradeComparison.MoreIsBetter})
    table.insert(bonus, {name = "Может получить подсистемы и турели"%_t, key = "canstealloot", value = intstealloot, comp = UpgradeComparison.MoreIsBetter})    local base = {}
    return base, bonus
end