-- Edited requiredTime to use custom function for shorter build time.
function Shipyard.getRequiredTime(plan)
    local base = 20 -- Base value for required time, > 0
    local multi = 2.85 -- Multiplies how fast the time increases, small increases will cause big changes to the formula below

    local requiredTime = math.floor(base + math.log(plan.durability / 200) ^ multi)

    -- Cap requiredTime at 900, we don't want to sit around for more than 15m waiting
    requiredTime = math.min(requiredTime, 900)

    -- Ensure requiredTime is always positive
    return math.max(requiredTime, 1)
end

function Shipyard.getShipCountCost(faction)
    local ships = 0
    for _, name in pairs({faction:getShipNames()}) do
        if faction:getShipType(name) == EntityType.Ship then
            ships = ships + 1
        end
    end

    -- Рассчитываем стоимость за количество кораблей
    local costInCredits = 1000 * math.pow(2, ships)  -- Начинаем с 1000 и удваиваем с каждым кораблём
    return costInCredits
end

function Shipyard.startServerJob(singleBlock, founder, withCrew, styleName, seed, volume, scale, material, name)
    if not CheckFactionInteraction(callingPlayer, Shipyard.interactionThreshold) then return end

    local buyer, ship, player = getInteractingFaction(callingPlayer, AlliancePrivilege.SpendResources)
    if not buyer then return end

    local stationFaction = Faction()
    local station = Entity()

    -- shipyard may only have x jobs
    if tablelength(runningJobs) >= 2 then
        player:sendChatMessage(station, 1, "The shipyard is already at maximum capacity."%_t)
        return 1
    end

    local limit
    if buyer.isPlayer or buyer.isAlliance then
        limit = buyer.maxNumShips
    end

    if limit and limit >= 0 and buyer.numShips >= limit then
        player:sendChatMessage("", 1, "Maximum ship limit for this faction (%s) of this server reached!"%_t, limit)
        return
    end

    -- create the plan
    local plan = BlockPlan()

    if singleBlock then
        if anynils(material) then
            return
        end

        plan:addBlock(vec3(0, 0, 0), vec3(2, 2, 2), -1, -1, ColorRGB(1, 1, 1), Material(material), Matrix(), BlockType.Hull, ColorNone())
    else
        if anynils(styleName, seed, volume) then return end

        local style = stationFaction:getPlanStyle(styleName)
        if not style then return end

        plan = GeneratePlanFromStyle(style, Seed(seed), volume, 2000, 1, Material(material))
    end

    if anynils(scale, name) then return end

    plan:scale(vec3(scale, scale, scale))

    -- get the money required for the plan
    local requiredMoney, fee = Shipyard.getRequiredMoney(plan, buyer)
    local requiredResources = Shipyard.getRequiredResources(plan, buyer)

    -- Получаем стоимость за количество кораблей
    local shipCountCost = Shipyard.getShipCountCost(buyer)

    -- Добавляем эту стоимость к общей стоимости корабля
    requiredMoney = requiredMoney + shipCountCost

    if withCrew then
        requiredMoney = requiredMoney + Shipyard.getCrewMoney(plan)
    end

    -- check if the player has enough money & resources
    local canPay, msg, args = buyer:canPay(requiredMoney, unpack(requiredResources))
    if not canPay then
        player:sendChatMessage(station, 1, msg, unpack(args))
        return
    end

    receiveTransactionTax(station, fee)

    -- let the player pay
    buyer:pay(requiredMoney, unpack(requiredResources))

    -- relations of the player to the faction owning the shipyard get better
    local relationsChange = GetRelationChangeFromMoney(requiredMoney)
    for i, v in pairs(requiredResources) do
        relationsChange = relationsChange + v / 4
    end

    changeRelations(buyer, stationFaction, relationsChange, RelationChangeType.ServiceUsage, nil, nil, station)

    -- start the job
    -- local requiredTime = math.floor(20.0 + plan.durability / 100.0)
    -- ### MODDED ###
    local requiredTime

    if singleBlock then
        requiredTime = 20
    else
        requiredTime = Shipyard.getRequiredTime(plan) -- ## MOD FUNCTION
    end
    -- ### MOD END ###

    if withCrew then
        requiredTime = requiredTime + 10
    end

    if GameSettings().instantShipyardBuilding then
        requiredTime = 1.0
    end

    local job = {}
    job.executed = 0
    job.duration = requiredTime
    job.shipOwner = buyer.index
    job.player = callingPlayer
    job.styleName = styleName
    job.seed = seed
    job.scale = scale
    job.volume = volume
    job.material = material
    job.shipName = name
    job.singleBlock = singleBlock
    job.founder = founder
    job.withCrew = withCrew

    table.insert(runningJobs, job)

    local args = createReadableTimeTable(requiredTime)
    if args.hours > 0 then
        if args.hours == 1 then
            player:sendChatMessage(station, 0, "Thank you for your purchase. Your ship will be ready in about an hour and %2% minutes."%_T, args.hours, args.minutes)
        else
            player:sendChatMessage(station, 0, "Thank you for your purchase. Your ship will be ready in about %1% hours and %2% minutes."%_T, args.hours, args.minutes)
        end
    elseif args.minutes > 0 then
        if args.minutes > 2 then
            player:sendChatMessage(station, 0, "Thank you for your purchase. Your ship will be ready in about %1% minutes."%_T, args.minutes, args.seconds)
        else
            player:sendChatMessage(station, 0, "Thank you for your purchase. Your ship will be ready in about two minutes."%_T, args.minutes, args.seconds)
        end
    end

    -- tell all clients in the sector that production begins
    broadcastInvokeClientFunction("startClientJob", 0, requiredTime)

    -- this sends an ack to the client and makes it close the window
    invokeClientFunction(player, "transactionComplete")
end

function Shipyard.renderUI()
    if not window.visible then return end

    local ship = Player().craft
    if not ship then return end

    local buyer = Faction(ship.factionIndex)
    if buyer.isAlliance then
        buyer = Alliance(buyer.index)
    elseif buyer.isPlayer then
        buyer = Player(buyer.index)
    end

    local fee = GetFee(Faction(), buyer) * 2

    local planMoney = preview:getMoneyValue()

    local planResources = {preview:getResourceValue()}
    local planResourcesFee = {}
    local planResourcesTotal = {}

    -- Получаем стоимость за количество кораблей
    local shipCountCost = Shipyard.getShipCountCost(buyer)

    local foundingResources = ShipFounding.getNextShipCosts(buyer)

    -- crew
    local crewMoney = 0
    if crewCombo.selectedIndex > 0 then
        crewMoney = Shipyard.getCrewMoney(preview)
    end

    -- plan resources
    for i, v in pairs(planResources) do
        table.insert(planResourcesTotal, v)
    end

    -- founding resources
    for i, amount in pairs(foundingResources) do
        planResourcesTotal[i] = planResourcesTotal[i] + amount
    end

    local offset = 10
    offset = offset + renderPrices(planDisplayer.lower + vec2(10, offset), "Founding Costs"%_t, 0, foundingResources)
    offset = offset + renderPrices(planDisplayer.lower + vec2(10, offset), "Ship Costs"%_t, planMoney, planResources)
    offset = offset + renderPrices(planDisplayer.lower + vec2(10, offset), "Стоимость подсчета кораблей"%_t, shipCountCost)
    offset = offset + renderPrices(planDisplayer.lower + vec2(10, offset), "Crew"%_t, crewMoney)
    offset = offset + renderPrices(planDisplayer.lower + vec2(10, offset), "Fee"%_t, planMoney * fee, planResourcesFee)

    offset = offset + 20
    offset = offset + renderPrices(planDisplayer.lower + vec2(10, offset), "Total"%_t, planMoney + shipCountCost + planMoney * fee + crewMoney, planResourcesTotal)
end

-- Used by ADV SHIPYARD ONLY, needs to be edited too or custom ships from the mod will still take hours.
function Shipyard.startServerDesignJob(founder, withCrew, scale, name, plan)
    if not name then
        print("Not a valid shipname", name)
        return
    end
    local buyer, ship, player = getInteractingFaction(callingPlayer, AlliancePrivilege.SpendResources, AlliancePrivilege.FoundShips)
    if not buyer then
        return
    end

    local stationFaction = Faction()
    local station = Entity()

    -- shipyard may only have x jobs
    if tablelength(runningJobs) >= config.maxParallelShips then
        player:sendChatMessage(station.title, 1, "The shipyard is already at maximum capacity." % _t)
        return
    end

    local limit
    if buyer.isPlayer or buyer.isAlliance then
        limit = buyer.maxNumShips
    end
    local aboveShiplimit =  limit and limit >= 0 and buyer.numShips >= limit
    if aboveShiplimit then
        player:sendChatMessage("", 1, "Maximum ship limit for this faction (%s) of this server reached!" % _t, limit)
        return
    end

    local settings = GameSettings()
    local exceedsVolume = settings.maximumVolumePerShip > 0 and settings.maximumVolumePerShip < plan.volume;
    if exceedsVolume then
        player:sendChatMessage("", 1, "Ship volume exceeds server limit (%s/%s)" % _t, math.ceil(plan.volume), settings.maximumVolumePerShip)
        return
    end

    local exceedsVolume = settings.maximumBlocksPerCraft > 0 and settings.maximumBlocksPerCraft < plan.numBlocks;
    if exceedsVolume then
        player:sendChatMessage("", 1, "Ship block count exceeds server limit (%s/%s)" % _t, math.ceil(plan.numBlocks), settings.maximumBlocksPerCraft)
        return
    end

    plan:scale(vec3(scale, scale, scale))

    local requiredMoney, fee = Shipyard.getRequiredMoney(plan, buyer)
    local requiredResources = Shipyard.getRequiredResources(plan, buyer)

    if withCrew then
        if captain == 2 and stationFaction:getRelations(buyer.index) < 30000 then
            local name = "Good" % _t
            player:sendChatMessage(station.title, ChatMessageType.Error, "You need relations of at least '%s' to this faction to include a captain with the ship." % _t, name)
            return
        end
        requiredMoney = requiredMoney + Shipyard.getCrewMoney(plan)
    end

    -- check if the player has enough money & resources
    local canPay, msg, args = buyer:canPay(requiredMoney, unpack(requiredResources))
    if not canPay then -- if there was an error, print it
        player:sendChatMessage(station, 1, msg, unpack(args))
        return
    end

    receiveTransactionTax(station, fee)

    -- let the player pay
    buyer:pay(requiredMoney, unpack(requiredResources))

    -- relations of the player to the faction owning the shipyard get better
    local relationsChange = GetRelationChangeFromMoney(requiredMoney)
    for _, v in pairs(requiredResources) do
        relationsChange = relationsChange + v / 4
    end

    local gameversion = GameVersion()
    if gameversion.major >= 2 and gameversion.minor >= 2 then
        changeRelations(buyer, stationFaction, relationsChange, RelationChangeType.ServiceUsage, nil, nil, station)
    else 
        changeRelations(buyer, stationFaction, relationsChange, RelationChangeType.ServiceUsage)
    end

    -- start the job
	local requiredTime = Shipyard.getRequiredTime(plan) -- ## MOD FUNCTION

    if withCrew then
        requiredTime = requiredTime + 10
    end

    if Scenario().isCreative then
        requiredTime = 1.0
    end

    -- create job
    local job = {}
    job.executed = 0
    job.duration = requiredTime
    job.shipOwner = buyer.index
    job.player = callingPlayer
    job.scale = scale
    job.shipName = name
    job.founder = founder
    job.withCrew = withCrew
    job.captain = withCrew
    -- job.plan = seriLib.serializeBlockPlan(planToBuild)  << If only someone had made a full serialzation lib. Hint @1694550170

    local position = Entity().orientation
    local sphere = Entity():getBoundingSphere()
    position.translation = sphere.center + random():getDirection() * (sphere.radius + plan.radius + 50)
    local ship = Sector():createShip(Faction(Entity().factionIndex), job.shipName, plan, position)
    ship.invincible = true

    local crew = nil
    crew = ship.idealCrew
    
    ship.crew = crew
    ship.factionIndex = -1

    -- add base scripts
    AddDefaultShipScripts(ship)
    SetBoardingDefenseLevel(ship)

    if founder then
        ship:addScript("data/scripts/entity/stationfounder.lua", stationFaction)
    end

    ship:removeScript("entity/claimalliance.lua")

    ship:addScriptOnce("data/scripts/entity/timedFactionTransferer.lua")
    ship:invokeFunction("data/scripts/entity/timedFactionTransferer.lua", "setVars", requiredTime, requiredTime, name, buyer.index, withCrew)
    job.uuid = ship.index.string

    table.insert(runningJobs, job)

    player:sendChatMessage(station.title, 0, "Thank you for your purchase. Your ship will be ready in about %s." % _t, createReadableTimeString(requiredTime))

    -- tell all clients in the sector that production begins
    broadcastInvokeClientFunction("startClientJob", 0, requiredTime, name, buyer.index)
end
callable(Shipyard, "startServerDesignJob")

