package.path = package.path .. ";data/scripts/lib/?.lua"

include ("callable")

local ITUtil = include("increasingthreatutility")

-- Don't remove or alter the following comment, it tells the game the namespace this script lives in. If you remove it, the script will break.
-- namespace Informant
Informant = {}
Informant.interactionThreshold = -80000
Informant.targetLevel = nil
Informant.targetFaction = nil

function Informant.interactionPossible(playerIndex, option)
    return CheckFactionInteraction(playerIndex, Informant.interactionThreshold)
end

function Informant.initialize()
    if onServer() then
        local station = Entity()
        if station.title == "" then
            station.title = "Smuggler's Market"%_t
        end

        -- find a faction to Informant on
        local x, y = Sector():getCoordinates()
        local targetLevel = Balancing_GetPirateLevel(x, y)
        Informant.targetLevel = targetLevel
        local pirateFaction = Galaxy():getPirateFaction(targetLevel)
        Informant.targetFaction = pirateFaction.index
    end

    if onClient() then
        EntityIcon().icon = "data/textures/icons/pixel/crate.png"

        -- request target faction from server
        Informant.uiInitialized = false
        invokeServerFunction("sync")
    end
end

function Informant.sync(useAlliance)
    local player = Player(callingPlayer)
    if not player then return end

    local interactingFaction = player
    if useAlliance then
        interactingFaction = player.alliance
    end

    if not interactingFaction then return end

    local key = "informant_timestamp_" .. tostring(Informant.targetFaction)
    local timeStamp = interactingFaction:getValue(key)
    local timeSince = nil
    if timeStamp then
        timeSince = math.max(0, Server().unpausedRuntime - timeStamp)
    end

    invokeClientFunction(player, "receiveData", Informant.targetFaction, Informant.targetLevel, timeSince)
end
callable(Informant, "sync")

function Informant.receiveData(targetFaction, targetLevel, timeSince)
    Informant.targetFaction = targetFaction
    Informant.timeSince = timeSince
    Informant.targetLevel = targetLevel

    --if timeSince then print("setting time since to: " .. timeSince) end
    --    print("client: target faction: " .. tostring(Informant.targetFaction)
    Informant.refreshUI()
end

function Informant.initUI()
    local res = getResolution()
    local size = vec2(600, 275)

    local menu = ScriptUI()
    local window = menu:createWindow(Rect(res * 0.5 - size * 0.5, res * 0.5 + size * 0.5))

    window.caption = "Hire Informant"%_t
    window.showCloseButton = 1
    window.moveable = 1
    menu:registerWindow(window, "Hire Informant"%_t);

    local icon = window:createPicture(Rect(vec2(200, 200)), "data/textures/icons/domino-mask.png")
    icon.isIcon = true
    icon.color = ColorARGB(0.5, 0, 0, 0)

    local lister = UIVerticalLister(Rect(window.size), 5, 10)
    Informant.targetLabel = window:createLabel(lister:nextRect(20), "", 14)

    Informant.offerLines = {}

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

    local button = window:createButton(splitter:partition(2), "Hire"%_t, "onHirePressed")

    table.insert(Informant.offerLines, {description = descriptionLabel, price = priceLabel, button = button.index})

    local rect = lister:nextRect(90)
    Informant.remainingTimeLabel = window:createLabel(rect, "", 14)
    Informant.remainingTimeLabel:setCenterAligned()

    local center = Informant.remainingTimeLabel.rect.center
    local iconSize = vec2(100, 100)
    icon.rect = Rect(center - iconSize, center + iconSize)

    local label = window:createLabel(lister:nextRect(50), "Informants will infiltrate nearby pirate factions and give you any information they find about you."%_t, 14)
    label.wordBreak = true

    Informant.uiInitialized = true
end

function Informant.refreshUI()
    if not Informant.uiInitialized then return end

    local stationFaction = Faction()
    local customerFaction = Informant.getCustomerFaction()

    for i, line in pairs(Informant.offerLines) do
        line.description.caption = "Hire informants"%_t
        local price = Informant.getPriceAndTax(stationFaction, customerFaction, Informant.targetLevel)
        line.price.caption = "¢${price}"%_t % {price = createMonetaryString(price)}
    end

    local faction
    if Informant.targetFaction ~= nil then
        faction = Faction(Informant.targetFaction)
    end

    local factionName = "Unavailable"%_t
    if faction then factionName = faction.translatedName end

    Informant.targetLabel.caption = "Target faction: ${name}"%_t % {name = factionName}
    if Informant.timeSince == nil or Informant.timeSince == 0 then
        --print("have not infiltrated")
        Informant.remainingTimeLabel.caption = "You have not infiltrated this pirate faction."%_t
    else
        local since, tbl = createDigitalTimeString(Informant.timeSince)
        local timeUnit = "Seconds"%_t
        if tbl.hours > 0 then
            timeUnit = "Hours"%_t
        elseif tbl.minutes > 0 then
            timeUnit = "Minutes"%_t
        end

        Informant.remainingTimeLabel.caption = "Infiltrated this pirate faction ${since} ${unit} ago"%_t % {since = since, unit = timeUnit}
    end
end

function Informant.onShowWindow()
    local customer = Informant.getCustomerFaction()

    invokeServerFunction("sync", customer.isAlliance)
end

function Informant.getCustomerFaction()
    local customer = Player()
    local ship = customer.craft
    if ship.factionIndex == customer.allianceIndex then
        return customer.alliance
    end

    return customer
end

function Informant.onHirePressed()
    --print("hire pressed")
    local shipIndex = Player().craftIndex
    invokeServerFunction("hireInformant", shipIndex)
end

function Informant.hireInformant(shipIndex)
    local shipFaction, ship, player = getInteractingFactionByShip(shipIndex, callingPlayer, AlliancePrivilege.SpendResources)
    if not shipFaction then return end

    local station = Entity()
    local stationFaction = Faction()

    local targetPirates = Faction(Informant.targetFaction)
    if not targetPirates then
        player:sendChatMessage(station.title, ChatMessageType.Normal, "Sorry, we can't offer our services at the moment."%_T)
        return
    end

    local price, tax = Informant.getPriceAndTax(stationFaction, shipFaction, Informant.targetLevel)
    --    print("hire: ${duration} minutes, ${price} credits" % {duration = duration, price = price})
    --    print("faction to be spied on: " .. Informant.targetFaction)

    local canPay, msg, args = shipFaction:canPay(costs)
    if not canPay then
        player:sendChatMessage(station.title, 1, msg, unpack(args))
        return
    end

    receiveTransactionTax(station, tax)
    shipFaction:pay("Paid %1% Credits to hire an informant"%_T, price)

    --Set timestamp (for "hired since")
    local key = "informant_timestamp_" .. tostring(Informant.targetFaction)
    local unpausedRuntime = Server().unpausedRuntime
    --print("setting key " .. key .. " to " .. unpausedRuntime)

    shipFaction:setValue(key, unpausedRuntime)

    --Next, set pirate traits.
    ITUtil.setIncreasingThreatTraits(targetPirates)
    local _VisibleToidx = "_ITTraits_VisibleTo_" .. tostring(player.index)
    targetPirates:setValue(_VisibleToidx, true)

    player:invokeFunction("data/scripts/player/background/increasingthreatmails.lua", "onInformantHired", targetPirates.index)

    -- sync
    invokeClientFunction(player, "onShowWindow")
end
callable(Informant, "hireInformant")

function Informant.getPriceAndTax(stationFaction, buyerFaction, targetLevel)
    local price = math.ceil((12 + 30 / 60) * (1 + GetFee(stationFaction, buyerFaction))) * 4500 * (targetLevel / 10)
    local tax = round(price * 0.2)

    if stationFaction.index == buyerFaction.index then
        price = price - tax
        -- don't pay out for the second time
        tax = 0
    end

    return price, tax
end
