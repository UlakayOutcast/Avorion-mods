package.path = package.path .. ";data/scripts/lib/?.lua"

include ("faction")
include ("callable")

-- Don't remove or alter the following comment, it tells the game the namespace this script lives in. If you remove it, the script will break.
-- namespace Briber
Briber = {}
Briber.interactionThreshold = -80000
Briber.targetLevel = nil
Briber.targetFaction = nil

function Briber.interactionPossible(playerIndex, option)
    return CheckFactionInteraction(playerIndex, Briber.interactionThreshold)
end

function Briber.initialize()
    if onServer() then
        local station = Entity()
        if station.title == "" then
            station.title = "Smuggler's Market"%_t
        end

        -- find a faction to Informant on
        local x, y = Sector():getCoordinates()
        local targetLevel = Balancing_GetPirateLevel(x, y)
        Briber.targetLevel = targetLevel
        local pirateFaction = Galaxy():getPirateFaction(targetLevel)
        Briber.targetFaction = pirateFaction.index
    end

    if onClient() then
        EntityIcon().icon = "data/textures/icons/pixel/crate.png"

        -- request target faction from server
        Briber.uiInitialized = false
        invokeServerFunction("sync")
    end
end

function Briber.sync(useAlliance)
    local player = Player(callingPlayer)
    if not player then return end

    local interactingFaction = player
    if useAlliance then
        interactingFaction = player.alliance
    end

    if not interactingFaction then return end

    invokeClientFunction(player, "receiveData", Briber.targetFaction, Briber.targetLevel)
end
callable(Briber, "sync")

function Briber.receiveData(targetFaction, targetLevel)
    Briber.targetFaction = targetFaction
    Briber.targetLevel = targetLevel

    --if timeSince then print("setting time since to: " .. timeSince) end
    --    print("client: target faction: " .. tostring(Briber.targetFaction)
    Briber.refreshUI()
end

function Briber.initUI()
    local res = getResolution()
    local size = vec2(600, 275)

    local menu = ScriptUI()
    local window = menu:createWindow(Rect(res * 0.5 - size * 0.5, res * 0.5 + size * 0.5))

    window.caption = "Bribe Pirates"%_t
    window.showCloseButton = 1
    window.moveable = 1
    menu:registerWindow(window, "Bribe Pirates"%_t);

    local icon = window:createPicture(Rect(vec2(200, 200)), "data/textures/icons/domino-mask.png")
    icon.isIcon = true
    icon.color = ColorARGB(0.5, 0, 0, 0)

    local lister = UIVerticalLister(Rect(window.size), 5, 10)
    Briber.targetLabel = window:createLabel(lister:nextRect(20), "", 14)

    Briber.offerLines = {}

    local splitter = UIArbitraryVerticalSplitter(lister:nextRect(30), 10, 0, 300, 450)

    local frameRect = splitter:partition(0)
    frameRect.upper = splitter:partition(1).upper
    window:createFrame(frameRect)

    local labelRect = splitter:partition(0)
    labelRect.lower = labelRect.lower + vec2(10, 0)
    local descriptionLabel = window:createLabel(labelRect, "", 14)
    descriptionLabel:setLeftAligned()

    local priceRect = splitter:partition(1)
    priceRect.upper = priceRect.upper - vec2(10, 0)
    local priceLabel = window:createLabel(priceRect, "", 14)
    priceLabel:setRightAligned()

    local button = window:createButton(splitter:partition(2), "Bribe"%_t, "onBribePressed")

    table.insert(Briber.offerLines, {description = descriptionLabel, price = priceLabel, button = button.index})

    local rect = lister:nextRect(90)
    Briber.remainingTimeLabel = window:createLabel(rect, "", 14)
    Briber.remainingTimeLabel:setCenterAligned()

    local center = Briber.remainingTimeLabel.rect.center
    local iconSize = vec2(100, 100)
    icon.rect = Rect(center - iconSize, center + iconSize)

    local label = window:createLabel(lister:nextRect(50), "Agents will infiltrate nearby pirate factions and bribe them to feel less hatred towards you."%_t, 14)
    label.wordBreak = true

    Briber.uiInitialized = true
end

function Briber.refreshUI()
    if not Briber.uiInitialized then return end

    local stationFaction = Faction()
    local customerFaction = Briber.getCustomerFaction()

    for i, line in pairs(Briber.offerLines) do
        line.description.caption = "Bribe Pirates"%_t
        local price = Briber.getPriceAndTax(stationFaction, customerFaction, Briber.targetLevel)
        line.price.caption = "¢${price}"%_t % {price = createMonetaryString(price)}
    end

    local faction
    if Briber.targetFaction ~= nil then
        faction = Faction(Briber.targetFaction)
    end

    local factionName = "Unavailable"%_t
    if faction then factionName = faction.translatedName end

    Briber.targetLabel.caption = "Target faction: ${name}"%_t % {name = factionName}
end

function Briber.onShowWindow()
    local customer = Briber.getCustomerFaction()

    invokeServerFunction("sync", customer.isAlliance)
end

function Briber.getCustomerFaction()
    local customer = Player()
    local ship = customer.craft
    if ship.factionIndex == customer.allianceIndex then
        return customer.alliance
    end

    return customer
end

function Briber.onBribePressed()
    --print("hire pressed")
    local shipIndex = Player().craftIndex
    invokeServerFunction("hireBriber", shipIndex)
end

function Briber.hireBriber(shipIndex)
    local shipFaction, ship, player = getInteractingFactionByShip(shipIndex, callingPlayer, AlliancePrivilege.SpendResources)
    if not shipFaction then return end

    local station = Entity()
    local stationFaction = Faction()

    local targetPirates = Faction(Briber.targetFaction)
    local _CanOfferServices = true
    if not targetPirates then
        _CanOfferServices = false
    end

    local _Tempered = targetPirates:getTrait("tempered")
    if _Tempered and _Tempered >= 0.25 then
        --Tempered pirates cannot be bribed.
        _CanOfferServices = false
    end

    if not _CanOfferServices then
        player:sendChatMessage(station.title, ChatMessageType.Normal, "Sorry, we can't offer our services at the moment."%_T)
        return
    end

    local price, tax = Briber.getPriceAndTax(stationFaction, shipFaction, Briber.targetLevel)
    --    print("hire: ${duration} minutes, ${price} credits" % {duration = duration, price = price})
    --    print("faction to be spied on: " .. Briber.targetFaction)

    local canPay, msg, args = shipFaction:canPay(costs)
    if not canPay then
        player:sendChatMessage(station.title, 1, msg, unpack(args))
        return
    end

    --No tax here.
    shipFaction:pay("Paid %1% Credits to bribe pirates"%_T, price)

    --Set timestamp (for "hired since")
    local key = "informant_timestamp_" .. tostring(Briber.targetFaction)
    local unpausedRuntime = Server().unpausedRuntime
    --print("setting key " .. key .. " to " .. unpausedRuntime)

    shipFaction:setValue(key, unpausedRuntime)

    --Next, set pirate traits.
    local pirateTraitsSet = targetPirates:getValue("_increasingthreat_traits2_set")
    if not pirateTraitsSet then
        local seed = Server().seed + targetPirates.index
        local random = Random(seed)
        local vengeful = random:getFloat(-1.0, 1.0) --Vengeful <==> Craven
        local tempered = random:getFloat(-1.0, 1.0) --Tempered <==> Covetous
        local brutish = random:getFloat(-1.0, 1.0) --Brutish <==> Wily

        SetFactionTrait(targetPirates, "vengeful", "craven", vengeful)
        SetFactionTrait(targetPirates, "tempered", "covetous", tempered)
        SetFactionTrait(targetPirates, "brutish", "wily", brutish)

        targetPirates:setValue("_increasingthreat_traits2_set", true)
    end

    player:invokeFunction("data/scripts/player/background/increasingthreatmails.lua", "onBriberHired", targetPirates.index)

    -- sync
    invokeClientFunction(player, "onShowWindow")
end
callable(Briber, "hireBriber")

function Briber.getPriceAndTax(stationFaction, buyerFaction, targetLevel)
    local price = math.max(math.min(buyerFaction.money * 0.1, 1000000000), 1000000) --10% of money or 1 million, whichever is higher. Cap of 1 billion.
    local tax = round(price * 0.2)

    if stationFaction.index == buyerFaction.index then
        price = price - tax
        -- don't pay out for the second time
        tax = 0
    end

    return price, tax
end
