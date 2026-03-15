function ResearchStation.onClickResearch() -- Override

    local reqItemIndices = {}
    local optItemIndices = {}
	local items = 0

    for _, item in pairs(required:getItems()) do
        if item.item then
            local amount = reqItemIndices[item.index] or 0
            amount = amount + 1
            reqItemIndices[item.index] = amount
			
			items = items + 1
        end
    end
	
    for _, item in pairs(optional:getItems()) do
        if item.item then
            local amount = optItemIndices[item.index] or 0
            amount = amount + 1
            optItemIndices[item.index] = amount
        end
    end

    if items == 3 then
        invokeServerFunction("research", reqItemIndices, optItemIndices)
    end
end


function ResearchStation.research(reqItemIndices, optItemIndices) -- Override
    if not reqItemIndices then return end

    if not CheckFactionInteraction(callingPlayer, ResearchStation.interactionThreshold) then return end

    local buyer, ship, player = getInteractingFaction(callingPlayer, AlliancePrivilege.SpendResources)
    if not buyer then return end

    -- check if the player has enough of the items
    local allItems = {}
    local reqItems = {}
    local optItems = {}

    for index, amount in pairs(reqItemIndices) do
        local item = buyer:getInventory():find(index)
        local has = buyer:getInventory():amount(index)

        if not item or has < amount then
            player:sendChatMessage(Entity(), 1, "You don't have enough items!"%_t)
            return
        end

        for i = 1, amount do
            table.insert(allItems, item)
            table.insert(reqItems, item)
        end
    end
	
	for index, amount in pairs(optItemIndices) do
        local item = buyer:getInventory():find(index)
        local has = buyer:getInventory():amount(index)

        if not item or has < amount then
            player:sendChatMessage(Entity(), 1, "You don't have enough items!"%_t)
            return
        end

        for i = 1, amount do
            table.insert(allItems, item)
            table.insert(optItems, item)
        end
    end

    if #reqItems < 3 then
        player:sendChatMessage(Entity(), 1, "You need at least 3 items to do research!"%_t)
        return
    end

    local station = Entity()

    local errors = {}
    errors[EntityType.Station] = "You must be docked to the station to research items."%_T
    errors[EntityType.Ship] = "You must be closer to the ship to research items."%_T
    if not CheckPlayerDocked(player, station, errors) then
        return
    end

    local result = ResearchStation.transform(allItems, reqItems, optItems)

    if result then
        for index, amount in pairs(reqItemIndices) do
            for i = 1, amount do
                buyer:getInventory():take(index)
            end
        end
		
		for index, amount in pairs(optItemIndices) do
            for i = 1, amount do
                buyer:getInventory():take(index)
            end
        end

        local inventory = buyer:getInventory()
        if not inventory:hasSlot(result) then
            buyer:sendChatMessage(station, ChatMessageType.Warning, "Your inventory is full (%1%/%2%). Your researched item was dropped."%_T, inventory.occupiedSlots, inventory.maxSlots)
        end

        inventory:addOrDrop(result)

        invokeClientFunction(player, "receiveResult", result)

        local senderInfo = makeCallbackSenderInfo(station)
        player:sendCallback("onItemResearched", senderInfo, ship.id, result)
        if buyer ~= player then
            buyer:sendCallback("onItemResearched", senderInfo, ship.id, result)
        end
        ship:sendCallback("onItemResearched", senderInfo, result)
        station:sendCallback("onItemResearched", senderInfo, ship.id, buyer.index, result)

    else
        buyer:sendChatMessage(station, ChatMessageType.Error, "Incapable of transforming these items."%_T)
    end
end


function ResearchStation.transform(allItems, reqItems, optItems) -- Override

    -- protect players from themselves
    if ResearchStation.cancelWithTooManyKeys(allItems) then return end

    -- check if there is a predetermined pattern
    local patternResult = ResearchStation.transformPatterns(allItems)
    if patternResult then
        return patternResult
    end

    if not ResearchStation.checkRarities(allItems) then
        if callingPlayer then
            local player = Player(callingPlayer)
            player:sendChatMessage(Entity(), 1, "Your items cannot be more than one rarity apart!"%_t)
        end
        return
    end

    local result
    local rarities = ResearchStation.getRarityProbabilities(allItems)
	
    local types = ResearchStation.getTypeProbabilities(reqItems, "type")

    local itemType = selectByWeight(random(), types)
    local rarity = Rarity(selectByWeight(random(), rarities))

    if itemType == InventoryItemType.Turret
        or itemType == InventoryItemType.TurretTemplate then

        local weaponTypes = ResearchStation.getWeaponProbabilities(reqItems)
        local materials = ResearchStation.getWeaponMaterials(reqItems)
        local weaponTech = ResearchStation.getWeaponTech(reqItems)

        local weaponType = selectByWeight(random(), weaponTypes)
        local material = Material(selectByWeight(random(), materials))

        local x, y = Sector():getCoordinates()
        local selfTech = Balancing_GetTechLevel(x, y)

        local tech = math.min(selfTech, weaponTech + 10)
        tech = math.min(tech, 52)

        local x, y = Balancing_GetSectorByTechLevel(tech)

        local generator = SectorTurretGenerator()
        generator.maxVariations = 10
        result = generator:generate(x, y, 0, rarity, weaponType, material)

        if itemType == InventoryItemType.Turret then
            result = InventoryTurret(result)
        end

    elseif itemType == InventoryItemType.SystemUpgrade then
        local scripts = ResearchStation.getSystemProbabilities(reqItems)

        local script = selectByWeight(random(), scripts)

        result = SystemUpgradeTemplate(script, rarity, random():createSeed())
    end

    return result
end