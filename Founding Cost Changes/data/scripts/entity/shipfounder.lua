function ShipFounder.refreshUI()
    local resources, ships, costInCredits
    local alliance = Player().alliance

    if allianceCheckBox.checked and alliance then
        resources, ships, costInCredits = ShipFounding.getNextShipCosts(alliance)
    else
        resources, ships, costInCredits = ShipFounding.getNextShipCosts(Player())
    end

    -- Отображаем стоимость в кредитах
    feeLabel.caption = "${amount} Кредитов"%_t % {amount = costInCredits}
    feeLabel.color = ColorRGB(255, 255, 255)  -- Желтый цвет для кредитов

    -- Полностью заменяем подсказку
    -- feeLabel.tooltip = "Чтобы заложить этот корабль, требуется ${amount} Кредитов."%_t % {amount = costInCredits}

    -- Обновляем заголовок окна
    window.caption = "Founding Ship #${number}"%_t % {number = ships + 1}

    -- Показываем предупреждение, если кораблей больше 24
    if ships + 1 >= 25 then
        warningPicture:show()
    else
        warningPicture:hide()
    end

    -- Обновляем подсказку для экипажа
    if Hud().tutorialActive then
        includedCrewAmountLabel.tooltip = "While in tutorial, you don't get crewmembers for free.\nDepending on the difficulty you're playing on, you will get a certain number of crew members whenever you found a ship."%_t
    else
        includedCrewAmountLabel.tooltip = "Depending on the difficulty you're playing on, you will get a certain number of crew members whenever you found a ship."%_t
    end
end


function ShipFounder.foundShip(faction, player, name, tutorialActive)
    local limit = faction.maxNumShips

    if limit and limit >= 0 and faction.numShips >= limit then
        player:sendChatMessage("", 1, "Maximum ship limit for this faction (%s) of this server reached!"%_t, limit)
        return
    end

    if faction:ownsShip(name) then
        player:sendChatMessage("", 1, "You already have a ship called '%s'."%_t, name)
        return
    end

    local resources, ships, costInCredits = ShipFounding.getNextShipCosts(faction)

    -- Проверяем, может ли фракция заплатить кредитами
    local ok, msg, args = faction:canPay(costInCredits, unpack(resources))
    if not ok then
        player:sendChatMessage("", 1, msg, unpack(args))
        return
    end

    -- Списываем кредиты
    faction:pay("Заплачено кредитов в размере ${amount}, чтобы заложить корабль."%_t % {amount = costInCredits}, costInCredits)

    -- Создаем корабль
    local self = Entity()
    local plan = BlockPlan()
    plan:addBlock(vec3(0, 0, 0), vec3(2, 2, 2), -1, -1, ColorRGB(1, 1, 1), Material(MaterialType.Iron), Matrix(), BlockType.Hull, ColorNone())

    local ship = Sector():createShip(faction, name, plan, self.position)

    -- Добавляем базовые скрипты
    AddDefaultShipScripts(ship)
    SetBoardingDefenseLevel(ship)

    -- Добавляем базовый экипаж
    if tutorialActive ~= true then
        local baseCrewAmount = ShipFounder.getBaseCrewAmount()
        ship:addCrew(baseCrewAmount, CrewMan(CrewProfession(CrewProfessionType.None), false, 1))
    end

    player.craft = ship

    -- Добавляем комплект для реконструкции, если разрешено
    local settings = GameSettings()
    if settings.difficulty <= Difficulty.Veteran and GameSettings().reconstructionAllowed then
        local kit = createReconstructionKit(ship)
        faction:getInventory():addOrDrop(kit, true)
    end

    return ship
end

-- create all required UI elements for the client side
function ShipFounder.initUI()

    local res = getResolution()
    local size = vec2(400, 300)

    local menu = ScriptUI()
    window = menu:createWindow(Rect(res * 0.5 - size * 0.5, res * 0.5 + size * 0.5))
    window.caption = "Founding Ship"%_t
    window.showCloseButton = 1
    window.moveable = 1
    menu:registerWindow(window, "Found Ship"%_t);

    local hsplit = UIHorizontalSplitter(Rect(size), 10, 10, 0.5)
    hsplit.bottomSize = 40

    -- button at the bottom
    local button = window:createButton(hsplit.bottom, "OK"%_t, "onFoundButtonPress");
    button.textSize = 14

    -- name & type
    local hsplit2 = UIHorizontalSplitter(hsplit.top, 10, 0, 0.6)
    local lister = UIVerticalLister(hsplit2.top, 10, 0)

    local label = window:createLabel(Rect(), "Enter the name of the ship:"%_t, 14);
    label.centered = true
    label.wordBreak = true

    lister:placeElementTop(label)

    nameTextBox = window:createTextBox(Rect(), "")
    nameTextBox.maxCharacters = 35
    nameTextBox:forbidInvalidFilenameChars()
    lister:placeElementTop(nameTextBox)

    local rect = lister.rect
    local vsplit = UIVerticalSplitter(lister.rect, 10, 10, 0.85)

    warningPicture = window:createPicture(vsplit.right, "data/textures/icons/hazard-sign.png")
    warningPicture.isIcon = true
    warningPicture.color = ColorRGB(1, 0, 0)
    warningPicture.tooltip = "WARNING: Having many ships in many different sectors can cause lags, FPS drops and overall bad game performance.\nThis is highly dependent on your system."%_t

    allianceCheckBox = window:createCheckBox(Rect(), "Alliance Ship"%_t, "onAllianceCheckBoxChecked")
    allianceCheckBox.active = false
    allianceCheckBox.captionLeft = false
    lister:placeElementTop(allianceCheckBox)

    -- costs
    local lister = UIVerticalLister(hsplit2.bottom, 10, 0)
    local rect = lister:nextRect(20)
    local label = window:createLabel(rect, "Founding Fee: (?)"%_t, 14);
    label:setLeftAligned()
    label.tooltip = "За создание каждого корабля взимается плата. Чем больше у вас кораблей, тем выше стоимость."%_t

    feeLabel = window:createLabel(rect, "", 14);
    feeLabel:setRightAligned()

    local rect = lister:nextRect(16)
    includedCrewLabel = window:createLabel(rect, "Included Crew: (?)"%_t, 14);

    includedCrewAmountLabel = window:createLabel(rect, "", 14);
    includedCrewAmountLabel:setRightAligned()

    window:createLine(hsplit2.top.bottomLeft, hsplit2.top.bottomRight)
end