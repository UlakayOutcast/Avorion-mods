
--====================================================================================================--
 
local blueprintPriceMultiplier = 1.5
local exceptionalRelationLevel  = 80000
local exoticRelationLevel  = 90000
local legendaryRelationLevel = 95000
local blueprintButton = nil

local easyBlueprintsIncluded = true

--====================================================================================================--

function TurretFactory.initBuildTurretsUI(tab)

    tab.onSelectedFunction = "refreshBuildTurretsUI"
    tab.onShowFunction = "refreshBuildTurretsUI"

    local size = tab.size

    local vsplit = UIVerticalSplitter(Rect(vec2(0, 0), size), 10, 0, 0.4)

    local left = vsplit.left
    local right = vsplit.right

    tab:createFrame(right);

    --- LEFT SIDE
    local hsplit = UIHorizontalSplitter(left, 10, 0, 0.25)
    tab:createFrame(hsplit.top);

    local rect = hsplit.top
    rect.size = vec2(75)
    selectedBlueprintSelection = tab:createSelection(rect, 1)
    selectedBlueprintSelection.dropIntoEnabled = 1
    selectedBlueprintSelection.entriesSelectable = 0
    selectedBlueprintSelection.onReceivedFunction = "onBlueprintReceived"

    local hsplit2 = UIHorizontalSplitter(hsplit.bottom, 10, 0, 0.5)
    hsplit2.topSize = 25

    local comboSplit = UIVerticalSplitter(hsplit2.top, 5, 0, 0.5)
    comboSplit:setRightQuadratic()

    blueprintTypeCombo = tab:createComboBox(comboSplit.left, "onBlueprintTypeSelected")
    blueprintTypeCombo:addEntry("Factory Blueprints"%_t)
    blueprintTypeCombo:addEntry("Inventory Blueprints"%_t)

    rerollButton = tab:createButton(comboSplit.right, "", "onRerollPressed")
    rerollButton.icon = "data/textures/icons/refresh.png"

    inventoryBlueprintSelection = tab:createInventorySelection(hsplit2.bottom, 5)
    inventoryBlueprintSelection.dragFromEnabled = 1
    inventoryBlueprintSelection.onClickedFunction = "onBlueprintSelectionClicked"
    inventoryBlueprintSelection:hide()

    predefinedBlueprintSelection = tab:createInventorySelection(hsplit2.bottom, 5)
    predefinedBlueprintSelection.dragFromEnabled = 1
    predefinedBlueprintSelection.onClickedFunction = "onBlueprintSelectionClicked"

    --- RIGHT SIDE
    local lister = UIVerticalLister(right, 10, 10)

    local vsplit = UIArbitraryVerticalSplitter(lister:placeCenter(vec2(lister.inner.width, 30)), 10, 5, 320, 370)

    tab:createLabel(vsplit:partition(0).lower, "Parts"%_t, 14)
    tab:createLabel(vsplit:partition(1).lower, "Req"%_t, 14)
    tab:createLabel(vsplit:partition(2).lower, "You"%_t, 14)

    for i = 1, 15 do
        local rect = lister:placeCenter(vec2(lister.inner.width, 30))
        local vsplit = UIArbitraryVerticalSplitter(rect, 10, 7, 20, 250, 280, 310, 320, 370)

        local frame = tab:createFrame(rect)

        local i = 0

        local iconRect = vsplit:partition(i); iconRect.size = vec2(iconRect.size.x + 10)

        local icon = tab:createPicture(iconRect, ""); i = i + 1
        local materialLabel = tab:createLabel(vsplit:partition(i).lower, "", 14); i = i + 1
        local plus = tab:createButton(vsplit:partition(i), "+", "onPlus"); i = i + 1
        local minus = tab:createButton(vsplit:partition(i), "-", "onMinus"); i = i + 2
        local requiredLabel = tab:createLabel(vsplit:partition(i).lower, "", 14); i = i + 1
        local youLabel = tab:createLabel(vsplit:partition(i).lower, "", 14); i = i + 1

        icon.isIcon = 1
        minus.textSize = 12
        plus.textSize = 12

        local hide = function(self)
            self.icon:hide()
            self.frame:hide()
            self.material:hide()
            self.plus:hide()
            self.minus:hide()
            self.required:hide()
            self.you:hide()
        end

        local show = function(self)
            self.icon:show()
            self.frame:show()
            self.material:show()
            self.plus:show()
            self.minus:show()
            self.required:show()
            self.you:show()
        end

        local line =  {frame = frame, icon = icon, plus = plus, minus = minus, material = materialLabel, required = requiredLabel, you = youLabel, hide = hide, show = show}
        line:hide()

        table.insert(lines, line)
    end


    local organizer = UIOrganizer(right)
    local rect = organizer:getBottomRect(Rect(vec2(right.width, 60)))


    -- added new button
    local splitterQuest= UIVerticalSplitter(rect, 10, 10, 0.9)
    local splitterBuild= UIVerticalSplitter(splitterQuest.left, 10, 10, 0.5)
    
    
    buildButton = tab:createButton(splitterBuild.left, "Build /*Turret Factory Button*/"%_t, "onBuildTurretPressed")
    newblueprintButton = tab:createButton(splitterBuild.right, "Blueprint /*Turret Factory Button*/"%_t, "onNewBlueprintPressed")
    
    saveButton = tab:createButton(splitterQuest.right, "", "onTrackIngredientsButtonPressed")
    saveButton.icon = "data/textures/icons/checklist.png"
    saveButton.tooltip = "Track ingredients in mission log"%_t

    priceLabel = tab:createLabel(vec2(right.lower.x, right.upper.y) + vec2(12, -75), "Manufacturing Price: Too Much"%_t, 16)

    TurretFactory.onBlueprintTypeSelected(blueprintTypeCombo, 0)
end

--====================================================================================================--

function TurretFactory.onBlueprintTypeSelected(combo, selectedIndex)
    predefinedBlueprintSelection.visible = (selectedIndex == 0)
    inventoryBlueprintSelection.visible = (selectedIndex == 1)

    --Ameey--
    newblueprintButton.active = (selectedIndex == 0)
    ------
    
    if selectedIndex == 1 then
        TurretFactory.refreshMakeBlueprintsUI()
    end
    
    local factionIndex = Faction().index
    rerollButton.active = (selectedIndex == 0) and (factionIndex == Player().index or factionIndex == Player().allianceIndex)

    TurretFactory.refreshRerollButtonTooltip()
end

--====================================================================================================--
  
function TurretFactory.onBlueprintSelected()
    local buyer = Galaxy():getPlayerCraftFaction()

    if configurationMode == ConfigurationMode.InventoryTurret then
        configuredIngredients, manufacturingPrice = TurretFactory.getDuplicatedTurretIngredientsAndTax(TurretFactory.getUIBlueprint(), buyer)
    else
        configuredIngredients, manufacturingPrice = TurretFactory.getNewTurretIngredientsAndTax(TurretFactory.getUIWeaponType(), TurretFactory.getUIRarity(), TurretFactory.getMaterial(), buyer)
    end

    TurretFactory.refreshIngredientsUI()
end

--====================================================================================================--

function TurretFactory.onNewBlueprintPressed(button)
    if configurationMode == ConfigurationMode.FactoryTurret then
        invokeServerFunction("makeNewTurretBlueprint", TurretFactory.getUIWeaponType(), TurretFactory.getUIRarity(), TurretFactory.getUIIngredients())
    end 
end

--====================================================================================================--

function TurretFactory.onMakeBlueprintPressed(itemIndex)

    if onClient() then
        local item = inputSelection:getItem(ivec2(0, 0))
        if not item then return end

        invokeServerFunction("onMakeBlueprintPressed", item.index)
        return
    end

    local buyer, ship, player = getInteractingFaction(callingPlayer, AlliancePrivilege.SpendItems)
    if not buyer then return end

    local inventory = buyer:getInventory()
    local turret = inventory:find(itemIndex)
    if turret.itemType ~= InventoryItemType.Turret then
        return
    end

    if easyBlueprintsIncluded then
        if TurretFactory.getTechLevel() < 50 then
            if turret.averageTech > TurretFactory.getTechLevel() then
                TurretFactory.sendError(player, "Tech level of this factory (%s) is not high enough for this turret."%_t, TurretFactory.getTechLevel())
                return
            end
        end
    else
        if turret.averageTech > TurretFactory.getTechLevel() then
            TurretFactory.sendError(player, "Tech level of this factory (%s) is not high enough for this turret."%_t, TurretFactory.getTechLevel())
            return
        end
    end

    if not ancientBlueprintsIncluded then
        if turret.ancient then
            TurretFactory.sendError(player, "This turret can't be turned into a blueprint."%_T)
            return 0
        end
    end
    
    local price = TurretFactory.getCreateBlueprintPrice(turret)
    local canPay, msg, args = buyer:canPay(price)
    if not canPay then
        TurretFactory.sendError(player, msg, unpack(args))
        return
    end

    local station = Entity()
    local errors = {}
    errors[EntityType.Station] = "You must be docked to the station to create blueprints."%_T
    errors[EntityType.Ship] = "You must be closer to the ship to create blueprints."%_T
    if not CheckPlayerDocked(player, station, errors) then
        return
    end

    local turret = inventory:take(itemIndex)
    if not turret then return end

    buyer:pay(price)
    inventory:addOrDrop(TurretTemplate(turret))

    invokeClientFunction(player, "refreshMakeBlueprintsUI")
end
callable(TurretFactory, "onMakeBlueprintPressed")

--====================================================================================================--

function TurretFactory.buildTurretDuplicate(inventoryIndex)
    if not CheckFactionInteraction(callingPlayer, TurretFactory.interactionThreshold) then return end

    local buyer, ship, player = getInteractingFaction(callingPlayer, AlliancePrivilege.SpendResources)
    if not buyer then return end
    if not inventoryIndex then return end

    local turret = buyer:getInventory():find(inventoryIndex)
    if not turret or turret.itemType ~= InventoryItemType.TurretTemplate then
        TurretFactory.sendError(player, "Turret blueprint not found."%_t)
        return
    end

    local rarity = turret.rarity
    
    local faction = Faction()
    if faction then
        if not CheckPlayerRelationsForTurret(player, buyer, faction, rarity.value) then
            return
        end
    end
           
    -- can the weapon be built here?
    if TurretFactory.getTechLevel() < 50 then
        if turret.averageTech > TurretFactory.getTechLevel() then
            TurretFactory.sendError(player, "Tech level of this factory (%s) is not high enough for this turret."%_t, TurretFactory.getTechLevel())
            return
        end             
    end

    -- don't take ingredients from clients blindly, they might want to cheat
    local ingredients, price, tax = TurretFactory.getDuplicatedTurretIngredientsAndTax(turret, buyer)

    -- make sure all required goods are there
    local missing
    for i, ingredient in pairs(ingredients) do
        local good = goods[ingredient.name]:good()
        local amount = ship:getCargoAmount(good)

        if not amount or amount < ingredient.amount then
            missing = goods[ingredient.name]:good()
            break;
        end
    end

    if missing then
        TurretFactory.sendError(player, "You need more %1%."%_t, missing:pluralForm(10))
        return
    end

    local canPay, msg, args = buyer:canPay(price)
    if not canPay then
        TurretFactory.sendError(player, msg, unpack(args))
        return
    end

    local station = Entity()

    local errors = {}
    errors[EntityType.Station] = "You must be docked to the station to build turrets."%_T
    errors[EntityType.Ship] = "You must be closer to the ship to build turrets."%_T
    if not CheckPlayerDocked(player, station, errors) then
        return
    end

    local inventoryTurret = InventoryTurret(turret)
    local inventory = buyer:getInventory()
    if not inventory:hasSlot(inventoryTurret) then
        player:sendChatMessage(Entity(), ChatMessageType.Error, "Your inventory is full (%1%/%2%)."%_T, inventory.occupiedSlots, inventory.maxSlots)
        return
    end

    -- pay
    receiveTransactionTax(station, tax)

    buyer:pay("Paid %1% Credits to build a turret."%_T, price)

    for i, ingredient in pairs(ingredients) do
        local g = goods[ingredient.name]:good()
        ship:removeCargo(g, ingredient.amount)
    end

    inventory:addOrDrop(inventoryTurret)

    invokeClientFunction(player, "refreshIngredientsUI")
end
callable(TurretFactory, "buildTurretDuplicate")

--====================================================================================================--

function TurretFactory.buildNewTurret(weaponType, rarity, clientIngredients)
    if not CheckFactionInteraction(callingPlayer, TurretFactory.interactionThreshold) then return end
 
    if anynils(weaponType, rarity, clientIngredients) then return end
    if not is_type(rarity, "Rarity") then return end
    if not (rarity.value >= RarityType.Common and rarity.value <= RarityType.Legendary) then return end

    local buyer, ship, player = getInteractingFaction(callingPlayer, AlliancePrivilege.SpendResources)
    if not buyer then return end

    local faction = Faction()
    if faction then
    
        if not CheckPlayerRelationsForTurret(player, buyer, faction, rarity.value) then
            return
        end

    end

    local material = TurretFactory.getMaterial()
    local station = Entity()

    -- can the weapon be built in this sector?
    local weaponProbabilities = Balancing_GetWeaponProbability(data.x, data.y)
    if not weaponProbabilities[weaponType] then
        TurretFactory.sendError(player, "This turret cannot be built here."%_t)
        return
    end

    -- don't take ingredients from clients blindly, they might want to cheat
    local ingredients, price, taxAmount = TurretFactory.getNewTurretIngredientsAndTax(weaponType, rarity, material, buyer)

    for i, ingredient in pairs(ingredients) do
        local other = clientIngredients[i]
        if other and other.amount then
            ingredient.amount = other.amount
        end
        
        if ingredient.minimum and ingredient.amount < ingredient.minimum then return end
        if ingredient.maximum and ingredient.amount > ingredient.maximum then return end
    end

    -- make sure all required goods are there
    local missing
    for i, ingredient in pairs(ingredients) do
        local good = goods[ingredient.name]:good()
        local amount = ship:getCargoAmount(good)

        if not amount or amount < ingredient.amount then
            missing = goods[ingredient.name]:good()
            break;
        end
    end

    if missing then
        TurretFactory.sendError(player, "You need more %1%."%_t, missing:pluralForm(10))
        return
    end

    local canPay, msg, args = buyer:canPay(price)
    if not canPay then
        TurretFactory.sendError(player, msg, unpack(args))
        return
    end

    local errors = {}
    errors[EntityType.Station] = "You must be docked to the station to build turrets."%_T
    errors[EntityType.Ship] = "You must be closer to the ship to build turrets."%_T
    if not CheckPlayerDocked(player, station, errors) then
        return
    end

    local turret = TurretFactory.makeTurret(weaponType, rarity, material, ingredients)
    local inventory = buyer:getInventory()
    if not inventory:hasSlot(turret) then
        player:sendChatMessage(Entity(), ChatMessageType.Error, "Your inventory is full (%1%/%2%)."%_T, inventory.occupiedSlots, inventory.maxSlots)
        return
    end

    -- pay
    receiveTransactionTax(station, taxAmount)

    buyer:pay("Paid %1% Credits to build a turret."%_T, price)

    for i, ingredient in pairs(ingredients) do
        local g = goods[ingredient.name]:good()
        ship:removeCargo(g, ingredient.amount)
    end

    inventory:addOrDrop(InventoryTurret(turret))

    invokeClientFunction(player, "refreshIngredientsUI")
end
callable(TurretFactory, "buildNewTurret")

--====================================================================================================--

function TurretFactory.makeNewTurretBlueprint(weaponType, rarity, clientIngredients) 
    if not CheckFactionInteraction(callingPlayer, TurretFactory.interactionThreshold) then return end

    if anynils(weaponType, rarity, clientIngredients) then return end
    if not is_type(rarity, "Rarity") then return end
    if not (rarity.value >= RarityType.Common and rarity.value <= RarityType.Legendary) then return end

    local buyer, ship, player = getInteractingFaction(callingPlayer, AlliancePrivilege.SpendResources)
    if not buyer then return end

    --Ameey-
    local faction = Faction()
    if faction then
    
        if not CheckPlayerRelationsForTurret(player, buyer, faction, rarity.value) then
            return
        end

    end
    ------

    local material = TurretFactory.getMaterial()
    local station = Entity()

    -- can the weapon be built in this sector?
    local weaponProbabilities = Balancing_GetWeaponProbability(data.x, data.y)
    if not weaponProbabilities[weaponType] then
        TurretFactory.sendError(player, "This turret cannot be built here."%_t)
        return
    end

    -- don't take ingredients from clients blindly, they might want to cheat
    local ingredients, price, taxAmount = TurretFactory.getNewTurretIngredientsAndTax(weaponType, rarity, material, buyer)

    price = price * blueprintPriceMultiplier
    
    for i, ingredient in pairs(ingredients) do
        local other = clientIngredients[i]
        if other and other.amount then
            ingredient.amount = other.amount
        end

        if ingredient.minimum and ingredient.amount < ingredient.minimum then return end
        if ingredient.maximum and ingredient.amount > ingredient.maximum then return end
    end

    local canPay, msg, args = buyer:canPay(price)
    if not canPay then
        TurretFactory.sendError(player, msg, unpack(args))
        return
    end

    local turret = TurretFactory.makeTurret(weaponType, rarity, material, ingredients)
    local inventory = buyer:getInventory()
    if not inventory:hasSlot(turret) then
        player:sendChatMessage(Entity(), ChatMessageType.Error, "Your inventory is full (%1%/%2%)."%_T, inventory.occupiedSlots, inventory.maxSlots)
        return
    end

    -- pay
    receiveTransactionTax(station, taxAmount)

    buyer:pay("Paid %1% Credits for a turret blueprint."%_T, price)

    -- drop blueprint instead of turret
    inventory:addOrDrop(TurretTemplate(turret))

    invokeClientFunction(player, "refreshIngredientsUI")
    
    invokeClientFunction(player, "refreshMakeBlueprintsUI")

end
callable(TurretFactory, "makeNewTurretBlueprint")

--====================================================================================================--

function CheckPlayerRelationsForTurret(player, buyer, faction, rarity)

    if rarity < RarityType.Exceptional then
        return true
    end
         
    if faction.index == player.index or faction.index == player.allianceIndex then
        return true
    end        
        
    if rarity == RarityType.Exceptional then
        if buyer:getRelations(faction.index) >= exceptionalRelationLevel then
            --ok Exceptional
            return true
        else
            TurretFactory.sendError(player, "You need at least 'Excellent' relations to build 'Exceptional' or better turrets."%_t)
            return false
        end   
    end
     
    if rarity == RarityType.Exotic then
        if buyer:getRelations(faction.index) >= exoticRelationLevel and buyer:getRelationStatus(faction.index) == RelationStatus.Allies then
            --ok Exotic
            return true
        else
            TurretFactory.sendError(player, "You need to be allies with this faction with over %1% relations to build 'Exotic' or better turrets."%_t, exoticRelationLevel)
            return false
        end
    end

    if rarity == RarityType.Legendary then
        if buyer:getRelations(faction.index) >= legendaryRelationLevel and buyer:getRelationStatus(faction.index) == RelationStatus.Allies then
            --ok Legendary
            return true
        else
            TurretFactory.sendError(player, "You need to be allies with this faction with over %1% relations to build 'Legendary' turrets."%_t, legendaryRelationLevel)
            return false
        end
    end

end

--====================================================================================================--
 
function TurretFactory.refreshBuildTurretsUI()
    local buyer = Galaxy():getPlayerCraftFaction()
    inventoryBlueprintSelection:fill(buyer.index, InventoryItemType.TurretTemplate)

    --Ameey--
    local rarities = {Rarity(RarityType.Common), Rarity(RarityType.Uncommon), Rarity(RarityType.Rare)}
    if buyer:getRelations(Faction().index) >= exceptionalRelationLevel then
        table.insert(rarities, Rarity(RarityType.Exceptional))    
    end

    if buyer:getRelations(Faction().index) >= exceptionalRelationLevel then
        table.insert(rarities, Rarity(RarityType.Exotic))
    end
    
    if buyer:getRelationStatus(Faction().index) == RelationStatus.Allies then
        if buyer:getRelations(Faction().index) >= exoticRelationLevel then
            table.insert(rarities, Rarity(RarityType.Legendary))    
        end
    end
    ----

    local random = Random(Seed(data.seed or ""))

    local first = nil
    predefinedBlueprintSelection:clear()
    for _, weaponType in pairs(TurretFactory.getPossibleWeaponTypes()) do
        for _, rarity in pairs(rarities) do
            local item = InventorySelectionItem()
            item.item = TurretFactory.makeTurretBase(weaponType, rarity, TurretFactory.getMaterial())
            predefinedBlueprintSelection:add(item)

            if not first then first = item end
        end
            
        local isOwnFactory = false
        
        if ((factionIndex == Player().index) or (factionIndex == Player().allianceIndex)) then
            isOwnFactory = true
        end

    end

    TurretFactory.refreshRerollButtonTooltip()

    selectedBlueprintSelection:clear()
    selectedBlueprintSelection:addEmpty()

    TurretFactory.placeBlueprint(first, ConfigurationMode.FactoryTurret)
end

--====================================================================================================--
 
function TurretFactory.refreshIngredientsUI()
    local ingredients = TurretFactory.getUIIngredients()
    local rarity = TurretFactory.getUIRarity()

    for i, line in pairs(lines) do
        line:hide()
    end

    local ship = Entity(Player().craftIndex)
    if not ship then return end

    for i, ingredient in pairs(ingredients) do
        local line = lines[i]
        line:show()

        local good = goods[ingredient.name]:good()

        local needed = ingredient.amount
        local have = ship:getCargoAmount(good)

        line.icon.picture = good.icon
        line.material.caption = good:displayName(needed)
        line.required.caption = needed
        line.you.caption = have

        line.plus.visible = (configurationMode == ConfigurationMode.FactoryTurret) and (ingredient.amount < ingredient.maximum)
        line.minus.visible = (configurationMode == ConfigurationMode.FactoryTurret) and (ingredient.amount > ingredient.minimum)

        if have < needed then
            line.you.color = ColorRGB(1, 0, 0)
        else
            line.you.color = ColorRGB(1, 1, 1)
        end
    end

    if configurationMode == ConfigurationMode.InventoryTurret then
       priceLabel.caption = "Manufacturing: ¢${money} / Blueprint: N/A"%_t % {money = createMonetaryString(manufacturingPrice)}
    else
       priceLabel.caption = "Manufacturing: ¢${money} / Blueprint: ¢${blue}"%_t % {money = createMonetaryString(manufacturingPrice), blue = createMonetaryString(manufacturingPrice * blueprintPriceMultiplier)}
    end
    

    
    
end

--====================================================================================================--
 
function TurretFactory.getDuplicatedTurretIngredientsAndTax(turret, buyer)

    local ingredients, goodsPrice = TurretFactory.calculateTurretIngredients(turret)
    local item = SellableInventoryItem(turret)

    -- remaining price is the difference between the goods price sum and the actual turret sum
    local price = math.max(item.price * 0.15, item.price - goodsPrice)
    price = math.ceil(price / 1000) * 1000

    local tax = round(price * TurretFactory.creationTax)

    if Faction().index == buyer.index then
        -- simply remove tax from price for easier use
        price = price - tax
        tax = 0
    end

    if (turret.averageTech > 50) then  
        local techMultiplier = GetTurretTechMultiplier(turret)
    
        for i, ingredient in pairs(ingredients) do
            ingredient.amount = ingredient.amount * techMultiplier 
        end
        price = price * techMultiplier
    end

    return ingredients, price, tax
end

--====================================================================================================--

function TurretFactory.getCreateBlueprintPrice(turret)
    local item = SellableInventoryItem(turret)

    local price = 1000 + math.ceil(item.price * 0.3 / 1000) * 1000
    
    if (turret.averageTech > 50) then
        local techMultiplier = GetTurretTechMultiplier(turret)
        price = price * techMultiplier
    end
    return price
    
end
 
--====================================================================================================--

function GetTurretTechMultiplier(turret)
    
    local techMultiplier = 1
    
    if (turret.averageTech > 50) then
        techMultiplier = 1.5 + ((turret.averageTech - 50) * 0.5)
    end
    
    return techMultiplier
    
end

--====================================================================================================--
 
--====================================================================================================--
 
 
