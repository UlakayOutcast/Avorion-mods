package.path = package.path .. ";data/scripts/systems/?.lua"
package.path = package.path .. ";data/scripts/lib/?.lua"
include ("basesystem")
include ("utility")
include ("randomext")

-- Основные переменные
materialLevel = 0
range = 0
amount = 0
interestingEntities = {}
outlineRange = 0

-- Переменные для подсветки ценных элементов
local entityId
local highlightColor = ColorRGB(0.7, 0.3, 0.7)
local chatMessageDisplayed = false
local scanAll = false
local minVolume = 2
local maxTargets = 15
local indicators = {}
local currentTarget
local currentTargetID
local scannerLevel
local callbackRegistered = false

-- Оптимизация
FixedEnergyRequirement = true
Unique = true

-- Функция для получения бонусов
function getBonuses(seed, rarity, permanent)
    math.randomseed(seed)

    -- Радиус детектора обломков / макс 16 км
    local range = 400
    range = range + (rarity.value + 1) * 100-- добавить 0 (худшая редкость) к +600 (лучшая редкость)
    range = range + math.random() * ((rarity.value/2 + 1) * 150)-- добавить случайное значение от 0 (худшая редкость) до 600 (лучшая редкость)

    if permanent then
        range = range * 1.5
        if rarity.value > RarityType.Exotic then
            range = math.huge
        end
    end

    -- Уровень подсветки ценных элементов
    local level = rarity.value
    if permanent then
        level = level + 1
    end

    -- return range, math.max(rarity.value, 0)
    return range, level
end

-- Сортировка систем
local function sortSystems(a, b)
    return a.volume > b.volume
end

local function getCaptainBonuses()
    local ship = Entity()
    local captain = ship:getCaptain()
    if captain and captain:hasClass(CaptainUtility.ClassType.Scavenger) then
        return 400 + captain.tier * 300 + captain.level * 175, captain.tier + captain.level
    end
    return 0, 0
end

if onClient() then
    local inRange = false

	function onInstalled(seed, rarity, permanent)
		local player = Player()
		if valid(player) then
			player:registerCallback("onPreRenderHud", "onPreRenderHud")
			player:registerCallback("onShipChanged", "detectAndSignal")
			player:registerCallback("onSectorChanged", "onSectorChanged")
		end

		-- Получаем базовые значения из подсистемы
		outlineRange, scannerLevel = getBonuses(seed, rarity, permanent)

		-- Добавляем бонусы от капитана
		local captainRangeBonus, captainLevelBonus = getCaptainBonuses()
		outlineRange = outlineRange + captainRangeBonus
		scannerLevel = scannerLevel + captainLevelBonus

		detectAndSignal()
	end

    function onUninstalled(seed, rarity, permanent)
        if currentTarget then
            currentTarget:unregisterCallback("onBreak", "onBreak")
        end

        if onClient() then
            Player():unregisterCallback("onPreRenderHud", "onPreRenderHud")
            Player():unregisterCallback("onShipChanged", "detectAndSignal")
            Player():unregisterCallback("onSectorChanged", "onSectorChanged")

            if entityId then
                removeShipProblem("SystemScanner", entityId)
                entityId = nil
            end
        end
    end

    function onDelete()
        if entityId then
            removeShipProblem("ValuablesDetector", entityId)
        end
    end

    function detectAndSignal()
        interestingEntities = {}
        local player = Player()
        if not valid(player) then return end
        if player.craftIndex ~= Entity().index then return end
        detectWreckages()
    end

    function detectWreckages()
        local entities = {Sector():getEntitiesByType(EntityType.Wreckage)}
        for _, entity in pairs(entities) do
            local sphere = entity:getBoundingSphere()
            local size = sphere and sphere.radius * 2 or 0
            local material = entity:getLowestMineableMaterial()
            local resources = 0
            for a, value in pairs({entity:getMineableResources()}) do
                resources = resources + value
            end

            if size >= 20 or resources > 10 then
                table.insert(interestingEntities, entity)
            end
        end
    end

    function onSectorChanged()
        detectAndSignal()
    end

    function getUpdateInterval()
        return 10
    end

    function updateClient()
        detectAndSignal()
    end

	function onPreRenderHud()
		
		if not outlineRange or outlineRange == 0 then
			-- Если нет подсистемы, проверяем только капитана
			local captainRangeBonus, captainLevelBonus = getCaptainBonuses()
			outlineRange = captainRangeBonus
			scannerLevel = captainLevelBonus
			if outlineRange == 0 then return end
		end
		
    -- print("outlineRange:", tostring(outlineRange), "scannerLevel:", tostring(scannerLevel))

		local player = Player()
		if not player then return end
		if player.state == PlayerStateType.BuildCraft or player.state == PlayerStateType.BuildTurret then return end

		local shipPos = Entity().translationf
		local renderer = UIRenderer()

		for i, entity in pairs(interestingEntities) do
			if not valid(entity) then
				interestingEntities[i] = nil
			end
		end

		for i, entity in pairs(interestingEntities) do
			local d = distance2(entity.translationf, shipPos)
			if d <= outlineRange * outlineRange then
				renderer:renderEntityTargeter(entity, highlightColor)
				renderer:renderEntityArrow(entity, 30, 10, 250, highlightColor)
			end
		end

		-- Change scan target inside ship with scanner
		local playerCraft = Sector():getEntity(Player().craftIndex)
		if playerCraft and playerCraft:hasScript("WS.lua") then
			local selected = Player().craft.selectedObject
			if currentTarget ~= selected and (currentTarget == nil or selected == nil or currentTarget.id ~= selected.id) then
				if currentTarget and callbackRegistered then
					local oldEntity = Sector():getEntity(currentTargetID)
					if oldEntity then
						oldEntity:unregisterCallback("onBreak", "onBreak")
					end
					callbackRegistered = false
				end

				currentTarget = selected
				if selected then
					currentTargetID = selected.id
				else
					currentTargetID = nil
				end
				findSystems(selected)

				if currentTarget and (scanAll or currentTarget.type == EntityType.Wreckage) and #indicators > 0 then
					currentTarget:registerCallback("onBreak", "onBreak")
					callbackRegistered = true
				end
			end
		end

		local inRange = false
		if currentTarget then
			local ship = Player().craft
			if ship then
				local distance = distance2(currentTarget.translationf, ship.translationf)
				inRange = distance <= outlineRange * outlineRange
			end
		end

		if #indicators > 0 and inRange then
			if not entityId then
				if Player().craftIndex == Entity().index then
					entityId = Entity().id
					addShipProblem("SystemScanner", entityId, "Ценные системы обнаружены на цели!", "data/textures/icons/circuitry.png", ColorRGB(0, 1, 1))
				end
			end
		else
			if entityId then
				removeShipProblem("SystemScanner", entityId)
				entityId = nil
			end
		end

		-- check render indicator highlights
		local counter = {}
		if inRange and scannerLevel >= RarityType.Uncommon then
			for i, entry in pairs(indicators) do
				if entry.parent ~= nil then
					local block = entry.block
					if block ~= nil then
						if counter[block.blockIndex] == nil then
							counter[block.blockIndex] = 0
						end

						if maxTargets == nil or (counter[block.blockIndex] < maxTargets) then
							renderIndicator(entry.parent, entry.offset, block, entry.volume)
						end

						counter[block.blockIndex] = counter[block.blockIndex] + 1
					else
						table.remove(indicators, i)
						if counter[block.blockIndex] then
							counter[block.blockIndex] = counter[block.blockIndex] - 1
						end
					end
				else
					indicators = {}
					return
				end
			end
		end
		renderer:display()
	end

    function findSystems(entity)
        indicators = {}

        if entity and (scanAll or entity.type == EntityType.Wreckage) then
            local plan = entity:getFullPlanCopy()
            local blocks = {plan:getBlockIndices()}

            for i = 1, #blocks do
                local block = plan:getBlock(blocks[i])
                if block and 
				(  (scannerLevel >= RarityType.Uncommon and block.blockIndex == 5)
                or (scannerLevel >= RarityType.Rare and block.blockIndex == 52)
                or (scannerLevel >= RarityType.Exceptional and block.blockIndex == 50)
                or (scannerLevel >= RarityType.Exotic and block.blockIndex == 55)
				) then
                    local box = block.box
                    if box then
                        local volume = box.size.x * box.size.y * box.size.z
                        if volume >= minVolume then
                            local center = block.box.center
                            table.insert(indicators, {
                                block = block,
                                parent = entity,
                                offset = center,
                                volume = volume})
                        end
                    end
                end
            end
            table.sort(indicators, sortSystems)
        end

    end

    function renderIndicator(parentEntity, offset, block, volume)
	
        local parentPos = parentEntity.position
        local offsetRotVec = (parentPos.right * offset.x) + (parentPos.up * offset.y) + (parentPos.look * offset.z)
        local offsetMatrix = Matrix()
        offsetMatrix.pos = parentPos.pos + offsetRotVec
        offsetMatrix.position = parentPos.position + offsetRotVec
        offsetMatrix.translation = parentPos.translation + offsetRotVec

        local color = ColorRGB(1, 1, 1)
        if block.blockIndex == 50 then
            color = ColorRGB(1, 1, 0) -- Shield gen yellow
        elseif block.blockIndex == 52 then
            color = ColorRGB(0, 0, 1) -- Generator core blue
        elseif block.blockIndex == 55 then
            color = ColorRGB(1, 0, 0) -- Hyperspace core red
        elseif block.blockIndex == 5 then
            color = ColorRGB(0, 1, 0) -- Cargo green
        end

        local size = math.sqrt(volume) + 3
        Sector():createGlow(offsetMatrix.position, size, color)
    end

    function onBreak(objectIndex, ...)
        if currentTarget and currentTarget.id == objectIndex then
            findSystems(currentTarget)
        end
    end
end

function printVec(vec)
    if vec then
        return "X:"..vec.x.." Y:"..vec.y.." Z:"..vec.z
    else
        return "null"
    end
end

function getName(seed, rarity)
    return "Сканер обломков"
end

function getIcon(seed, rarity)
    return "data/textures/icons/scrap-metal.png"
end

function getEnergy(seed, rarity, permanent)
    local range, level = getBonuses(seed, rarity, permanent)
    range = math.min(range, 3000) * 0.0005 * (math.max(rarity.value, 0) / 2 + 1) * 1000 * 1000 * 1000
    if range < 0 then
        range = 0
    end
    return range
end

function getPrice(seed, rarity)
    local range, level = getBonuses(seed, rarity)
    range = math.min(range, 1500)
    -- local price = range * 2.5
    -- return price * 2.5 ^ rarity.value
    return ((level + 1) * 3000 + range * 1.5) * 2.5 ^ (rarity.value+1)
end

-- Подсказки
function getTooltipLines(seed, rarity, permanent)
    local texts = {}
    local bonuses = {}

    local range, level = getBonuses(seed, rarity, permanent)
    local rangeP, levelP = getBonuses(seed, rarity, true)

    local rangeText = "Сектор"
    local rangeTextP = "Сектор"

    if range < math.huge then
        rangeText = string.format("%g км", round(range / 100, 2))
    end
    if rangeP < math.huge then
        rangeTextP = string.format("%g км", round(rangeP / 3 / 100, 2))
    end

    table.insert(texts, {ltext = "Диапазон обнаружения", rtext = rangeText, icon = "data/textures/icons/rss.png", boosted = permanent})
    table.insert(bonuses, {ltext = "Диапазон обнаружения", rtext = rangeTextP, icon = "data/textures/icons/rss.png"})
	--1
    if level >= RarityType.Common then
        table.insert(bonuses, {ltext = "Подсвечивает грузовые отсеки зеленым цветом.", rtext = "", icon = "data/textures/icons/crate.png"})
    end
	--2
    if level >= RarityType.Uncommon then
        table.insert(texts, {ltext = "Подсвечивает грузовые отсеки зеленым цветом.", rtext = "", icon = "data/textures/icons/crate.png"})
        table.insert(bonuses, {ltext = "Подсвечивает генераторы синим цветом.", rtext = "", icon = "data/textures/icons/energy-generator.png"})
    end
	--3
    if level >= RarityType.Rare then
        table.insert(texts, {ltext = "Подсвечивает генераторы синим цветом.", rtext = "", icon = "data/textures/icons/energy-generator.png"})
        table.insert(bonuses, {ltext = "Подсвечивает генераторы щита желтым цветом.", rtext = "", icon = "data/textures/icons/energy-shield.png"})
    end
	--4
    if level >= RarityType.Exceptional then
        table.insert(texts, {ltext = "Подсвечивает генераторы щита желтым цветом.", rtext = "", icon = "data/textures/icons/energy-shield.png"})
        table.insert(bonuses, {ltext = "Подсвечивает гиперпространственные ядра красным цветом.", rtext = "", icon = "data/textures/icons/overdrive.png"})
    end

    if level >= RarityType.Exotic then
        table.insert(texts, {ltext = "Подсвечивает гиперпространственные ядра красным цветом.", rtext = "", icon = "data/textures/icons/overdrive.png"})
        table.insert(bonuses, {ltext = "Подсвечивает гиперпространственные ядра красным цветом.", rtext = "", icon = "data/textures/icons/overdrive.png"})
    end
	
	-- Petty (Gray in colour, the worst quality, strangely, this quality is more rare than common)
	-- Common (White in colour, and as the name suggest, this is the most common upgrade tier)
	-- Uncommon (Green in colour)
	-- Rare (Blue in colour)
	-- Exceptional (Orange/Yellow in colour)
	-- Exotic (Red in colour)
	-- Legendary (Purple in colour)
	
    return texts, bonuses
end

-- Описание системы
function getDescriptionLines(seed, rarity, permanent)
    local texts = {}
    local range, level = getBonuses(seed, rarity, permanent)

    if level < RarityType.Uncommon then
		table.insert(texts, {ltext = "Обнаруживает обломки."%_t, rtext = "", icon = ""})
    end
	
    if level >= RarityType.Uncommon then
        table.insert(texts, {ltext = "Обнаруживает обломки и ценные системы в обломках."%_t, rtext = "", icon = ""})
    end
	
    return texts
end

function getComparableValues(seed, rarity)
    local base = {}
    local bonus = {}

    local range, level = getBonuses(seed, rarity, false)
    table.insert(base, {name = "Range", key = "range", value = round(range / 100, 2), comp = UpgradeComparison.MoreIsBetter})

    local rangeP, levelP = getBonuses(seed, rarity, true)
    table.insert(bonus, {name = "Range", key = "range", value = round(rangeP / 3 / 100, 2), comp = UpgradeComparison.MoreIsBetter})
	
	table.insert(bonus, {name = "Range", key = "range", value = round(level, 2), comp = UpgradeComparison.MoreIsBetter})
	
	
    return base, bonus
end
