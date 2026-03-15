package.path = package.path .. ";data/scripts/lib/?.lua"
package.path = package.path .. ";data/scripts/?.lua"

include("structuredmission")
include("player") --needed to use MissionUT.dockedDialogSelector

local Balancing = include ("galaxy")
local SectorTurretGenerator = include ("sectorturretgenerator")

mission._Debug = 0
mission._Name = "Минеральное безумие"

--region #INIT

--Standard mission data.
mission.data.brief = mission._Name
mission.data.title = mission._Name
mission.data.autoTrackMission = true
mission.data.description = {
    { text = "Вы получили следующий запрос от ${giverTitle} из сектора ${sectorName}:" }, --Placeholder
    { text = "" }, --Placeholder
    { text = "Доставьте руду в сектор (${_X}:${_Y}) - Доставлено на данный момент:", bulletPoint = true, fulfilled = false },
    { text = "${_OREAMT} ${_ORETYPE}", bulletPoint = true, fulfilled = false }, --placeholder
    { text = "${_OREAMT} ${_ORETYPE}", bulletPoint = true, fulfilled = false }, --placeholder
    { text = "${_OREAMT} ${_ORETYPE}", bulletPoint = true, fulfilled = false }, --placeholder
    { text = "${_OREAMT} ${_ORETYPE}", bulletPoint = true, fulfilled = false }, --placeholder
    { text = "${_OREAMT} ${_ORETYPE}", bulletPoint = true, fulfilled = false }, --placeholder
    { text = "${_OREAMT} ${_ORETYPE}", bulletPoint = true, fulfilled = false }, --placeholder
    { text = "${_OREAMT} ${_ORETYPE}", bulletPoint = true, fulfilled = false } --placeholder
}
mission.data.timeLimit = 30 * 60 --У игрока есть 30 минут.
mission.data.timeLimitInDescription = true --Показать игроку, сколько времени осталось.
--Нельзя установить mission.data.reward.paymentMessage здесь, так как мы используем необычную настройку для получения наград.
mission.data.custom.accomplishMessage = "Спасибо за руду! Мы перевели награду на ваш счет."
mission.data.custom.failMessage = "Мы видим, что вы не смогли доставить руду. Очень жаль. Повезет в следующий раз!"
mission.data.custom.oreTypes = {
    { name = "Iron Ore", amount = 0 },
    { name = "Titanium Ore", amount = 0 },
    { name = "Naonite Ore", amount = 0 },
    { name = "Trinium Ore", amount = 0 },
    { name = "Xanion Ore", amount = 0 },
    { name = "Ogonite Ore", amount = 0 },
    { name = "Avorion Ore", amount = 0 }
}

local MineralMadness_init = initialize
function initialize(_Data_in, bulletin)
    local methodName = "initialize"
    mission.Log(methodName, "Beginning...")

    if onServer() and not _restoring then
        local _X, _Y = _Data_in.location.x, _Data_in.location.y

        local _sector = Sector()
        local giver = Entity(_Data_in.giver)

        mission.Log(methodName, "Sector name is " .. tostring(_sector.name) .. " Giver title is " .. tostring(giver.translatedTitle))

        --[[=====================================================
            CUSTOM MISSION DATA SETUP:
        =========================================================]]
        mission.data.accomplishMessage = mission.data.custom.failMessage
        mission.data.custom.droppedOre = false
        mission.data.custom.inBarrier = MissionUT.checkSectorInsideBarrier(_X, _Y)
        mission.data.custom.totalOreDelivered = 0

        --[[=====================================================
            MISSION DESCRIPTION SETUP:
        =========================================================]]
        mission.data.description[1].arguments = { sectorName = _sector.name, giverTitle = giver.translatedTitle }
        mission.data.description[2].text = _Data_in.initialDesc
        mission.data.description[3].arguments = { _X = _X, _Y = _Y }
    end

    --Run vanilla init. Managers _restoring on its own.
    MineralMadness_init(_Data_in, bulletin)
end

--endregion

--region #PHASE CALLS

mission.globalPhase.getRewardedItems = function()
    local methodName = "Global Phase Get Rewarded Items"
    mission.Log(methodName, "Getting reward items...")
    
    local xrand = random()
    local items = {}
    local totalOre = mission.data.custom.totalOreDelivered

    local possibleRarities = {RarityType.Common, RarityType.Common, RarityType.Uncommon, RarityType.Uncommon, RarityType.Rare}
    if mission.data.custom.inBarrier then
        possibleRarities = {RarityType.Uncommon, RarityType.Uncommon, RarityType.Rare, RarityType.Rare, RarityType.Exceptional, RarityType.Exotic}
    end

    --25% chance of getting a random rarity cargo upgrade.
    if xrand:test(0.25) and totalOre >= 500 then
        mission.Log(methodName, "Getting cargo upgrade")

        local _SeedInt = xrand:getInt(1, 20000)
        local upgradeRarity = getRandomEntry(possibleRarities)
        table.insert(items, SystemUpgradeTemplate("data/scripts/systems/cargoextension.lua", Rarity(upgradeRarity), Seed(_SeedInt)))
    end

    --12.5% chance of getting a r-mining turret. Need to have delivered at least 1000 ore.
    if xrand:test(0.125) and totalOre >= 1000 then
        mission.Log(methodName, "Getting mining turret")

        local x, y = mission.data.location.x, mission.data.location.y
        local generator = SectorTurretGenerator()

        local turretRarity = getRandomEntry(possibleRarities)
        table.insert(items, InventoryTurret(generator:generate(x, y, 0, Rarity(turretRarity), WeaponType.RawMiningLaser, nil)))
    end

    return table.unpack(items)
end

mission.phases[1] = {}
mission.phases[1].onBegin = function()
    local methodName = "Phase 1 On Begin"
    mission.Log(methodName, "Setting arguments for ores.")

    --Can't set this up until the init call on line 72
    mission.data.custom.stationId = mission.data.giver.id.string

    local descidx = 4
    for _, oreType in pairs(mission.data.custom.oreTypes) do
        mission.data.description[descidx].arguments = { _OREAMT = oreType.amount, _ORETYPE = oreType.name }
        descidx = descidx + 1
    end
end

mission.phases[1].onBeginServer = function()
    mission.internals.fulfilled = true --This mission will succeed at the end, and not fail. The only question is how much money the player gets.
end

mission.phases[1].onStartDialog = function(entityId)
    local methodName = "On Start Dialog"

    if not atTargetLocation() then
        return
    end

    mission.Log(methodName, "Checking to see if " .. tostring(entityId) .. " matches " .. tostring(mission.data.custom.stationId))

    if entityId == Uuid(mission.data.custom.stationId) then
        local scriptUI = ScriptUI(entityId)
        if not scriptUI then
            return
        end

        scriptUI:addDialogOption("Deliver ores", "mineralMadness_onDeliverOre")
    end
end

mission.phases[1].onAccomplish = function()
    local methodName = "Phase 1 On Accomplish"

    if mission.data.custom.droppedOre then
        mission.Log(methodName, "Player accomplished mission - rewarding.")

        local x, y = mission.data.location.x, mission.data.location.y
        local thousands = 0

        --Calculate reward
        for matlIdx, oreData in pairs(mission.data.custom.oreTypes) do
            local matl = Material(matlIdx - 1)
            local matlCredits = (matl.costFactor * oreData.amount * 10)

            mission.Log(methodName, "Material name is " .. tostring(matl.name) .. " turned in " .. tostring(oreData.amount) .. " for " .. tostring(math.ceil(matlCredits)) .. " credits.")

            mission.data.reward.credits = mission.data.reward.credits + math.ceil(matlCredits)
            thousands = math.floor(oreData.amount / 1000)
        end

        mission.data.reward.paymentMessage = "Заработано %1% кредитов за доставку " .. tostring(mission.data.custom.totalOreDelivered) .. " единиц руды."
        --Can't use the normal reward factor progression here - selling resources is already fairly profitable and I don't want to make things TOO easy for the player :P
        --The payout is shockingly high for doing The Dig and just letting your ship fly around and gather resources. You can get 40 million off of this easily.
        mission.data.reward.credits = mission.data.reward.credits * (Balancing.GetSectorRewardFactor(x, y) * 0.25)
        mission.data.reward.relations = thousands * 100

        reward()
    else
        punish()
    end
end

--endregion

--region #SERVER CALLS

function mineralMadness_incrementOreDelivery()
    local methodName = "Increment Ore Delivery"
    if onClient() then
        mission.Log(methodName, "Calling on Client => Invoking on server")
        invokeServerFunction("mineralMadness_incrementOreDelivery")
        return
    end
    mission.Log(methodName, "Called on server.")

    mission.data.accomplishMessage = mission.data.custom.accomplishMessage

    local _player = Player()
    local ship = _player.craft

    local oreDepotId = Uuid(mission.data.custom.stationId)
    local oreDepot = Entity(oreDepotId)

    local descidx = 4
    for matlIdx, oreType in pairs(mission.data.custom.oreTypes) do
        --Get amount in ship's hold
        local holdAmount = ship:getCargoAmount(oreType.name)

        --Add that to oreType.amount
        oreType.amount = oreType.amount + holdAmount
        mission.data.custom.totalOreDelivered = mission.data.custom.totalOreDelivered + holdAmount

        --Remove from hold
        ship:removeCargo(oreType.name, holdAmount)

        --Give to resource depot
        mission.Log(methodName, "Invoking addResource on oreDepot")
        oreDepot:invokeFunction("resourcetrader.lua", "addResource", matlIdx, holdAmount)

        --Update description & increment index
        mission.data.description[descidx].arguments = { _OREAMT = oreType.amount, _ORETYPE = oreType.name }
        descidx = descidx + 1
    end

    mission.data.custom.droppedOre = true
    
    --sync w/ client.
    sync()
end
callable(nil, "mineralMadness_incrementOreDelivery")

--endregion

--region #CLIENT CALLS

function mineralMadness_onDeliverOre(entityId)
    local methodName = "On Deliver Ore"
    mission.Log(methodName, "Beginning. Entity ID is " .. tostring(entityId))

    local conditionFunc = function()
        --print("Entering condition func")
        local _player = Player()
        local ship = _player.craft

        if not _player or not ship then
            return false
        end
        
        --Check to make sure player has any scrap to deliver.
        local conditionOK = false

        for _, oreType in pairs(mission.data.custom.oreTypes) do
            local holdAmount = ship:getCargoAmount(oreType.name)
            if holdAmount > 0 then
                conditionOK = true
                break
            end
        end

        return conditionOK
    end
    
    local dockedFunc = function()
        local dockedDialog = {}
        dockedDialog.text = "Спасибо за доставку руды! Мы добавим это на ваш счет."
        dockedDialog.onEnd = "mineralMadness_incrementOreDelivery"

        return dockedDialog
    end

    local undockedFunc = function()
        local undockedDialog = {}
        undockedDialog.text = "Пожалуйста, пристыкуйтесь к станции, чтобы сдать руду!"

        return undockedDialog
    end

    local failedFunc = function()
        local failedDialog = {}
        failedDialog.text = "У вас нет руды в трюме! Пожалуйста, убедитесь, что у вас есть что доставить."

        return failedDialog
    end

    mission.Log(methodName, "Getting docked dialog selector.")
    MissionUT.dockedDialogSelector(entityId, conditionFunc(), failedFunc, undockedFunc, dockedFunc)
end

--endregion

--region #MAKEBULLETIN CALLS

function mineralMadness_formatDescription()
    local descriptionTable = {
        "Привет! Некоторые из наших шахтеров вышли из строя, но потребность в ресурсах никогда не заканчивается! Всегда есть что построить или отремонтировать. Мы были бы признательны, если бы вы могли добыть немного, пока мы ремонтируем наши корабли. Принесите как можно больше сырой руды! Мы заплатим вам за это.",
        "Мы работаем изо всех сил, чтобы добывать ресурсы, но этого недостаточно! Нам нужна помощь. Если бы вы могли пойти и зачистить несколько минеральных полей, мы были бы признательны за помощь! Не стесняйтесь сбрасывать любую собранную вами сырую руду, мы заплатим вам повышенную цену за единицу!",
        "О боже. Я только что закончил горнодобывающую экспедицию, и один из моих инженеров вывалил половину содержимого моего грузового отсека! Я его отчитал, но меня уволят, если босс это заметит! Помогите! Если вы сможете сбросить немного сырой руды, возможно, он не узнает... Я заплачу вам! Много!!!"
    }

    if random():test(0.05) then
        descriptionTable = {
            "Привет, друг! Если у вас есть возможность, не могли бы вы приобрести несколько интересных руд для моей коллекции? Минералы этой галактики просто очаровательны! Принесите немного на этот склад, и я позабочусь о том, чтобы вам заплатили за ваше время! ouo7"
        }
    end

    return getRandomEntry(descriptionTable)
end

mission.makeBulletin = function(_Station)
    local methodName = "Make Bulletin"
    mission.Log(methodName, "Making Bulletin.")
    --This mission happens in the same sector you accept it in.
    local target = {}
    target.x, target.y = Sector():getCoordinates()

    if not target.x or not target.y then
        mission.Log(methodName, "Target.x or Target.y not set - returning nil.")
        return 
    end
    
    local _Description = mineralMadness_formatDescription()

    reward = 0

    local bulletin =
    {
        -- data for the bulletin board
        brief = mission.data.brief,
        title = mission.data.title,
        description = _Description,
        difficulty = "Variable", --Depends on how you get the ore.
        reward = "Variable",
        script = "missions/mineralmadness.lua",
        formatArguments = {x = target.x, y = target.y, reward = createMonetaryString(reward)},
        msg = "Спасибо за ваше покровительство! Мы заплатим вам в зависимости от того, сколько руды вы нам доставите!",
        giverTitle = _Station.title,
        giverTitleArgs = _Station:getTitleArguments(),
        checkAccept = [[
            local self, player = ...
            if player:hasScript("missions/mineralmadness.lua") then
                player:sendChatMessage(Entity(self.arguments[1].giver), 1, "You cannot accept additional ore delivery contracts! Abandon your current one or complete it.")
                return 0
            end
            return 1
        ]],
        onAccept = [[
            local self, player = ...
            player:sendChatMessage(Entity(self.arguments[1].giver), 0, self.msg, self.formatArguments.x, self.formatArguments.y)
        ]],

        -- data that's important for our own mission
        arguments = {{
            giver = _Station.index,
            location = target,
            reward = {credits = reward, relations = 0},
            punishment = { relations = 1000 }, --Nothing too bad. Just a little sting.
            initialDesc = _Description
        }},
    }

    return bulletin
end

--endregion
