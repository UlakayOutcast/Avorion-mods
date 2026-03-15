package.path = package.path .. ";data/scripts/lib/?.lua"
package.path = package.path .. ";data/scripts/?.lua"

include("structuredmission")
include("player") --needed to use MissionUT.dockedDialogSelector

local Balancing = include ("galaxy")

mission._Debug = 0
mission._Name = "Доставка лома"

--region #INIT

--Standard mission data.
mission.data.brief = mission._Name
mission.data.title = mission._Name
mission.data.autoTrackMission = true
mission.data.description = {
    { text = "Вы получили следующий запрос от ${giverTitle} из сектора ${sectorName}:" }, --Placeholder
    { text = "" }, --Placeholder
    { text = "Доставьте ${_SCRAPAMT} ${_SCRAPTYPE} на свалку в секторе (${_X}:${_Y})", bulletPoint = true, fulfilled = false },
    { text = "Доставлено ${_SCRAPDELIVERED} / ${_SCRAPAMT}", bulletPoint = true, fulfilled = false }
}
mission.data.accomplishMessage = "Спасибо за лом! Мы перевели награду на ваш счет."

mission.data.custom.scrapTypes = {
    { matlIdx = 0, name = "Железный лом" },
    { matlIdx = 1, name = "Титановый лом" },
    { matlIdx = 2, name = "Наонитовый лом" },
    { matlIdx = 3, name = "Триниумный лом" },
    { matlIdx = 4, name = "Ксанионный лом" },
    { matlIdx = 5, name = "Огонитовый лом" },
    { matlIdx = 6, name = "Аворионный лом" }
}

local ScrapDelivery_init = initialize
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
        mission.data.custom.scrapNeeded = _Data_in.scrapNeeded
        mission.data.custom.scrapTypeNeeded = _Data_in.scrapTypeNeeded

        local scrapTypeNeededName = mission.data.custom.scrapTypes[mission.data.custom.scrapTypeNeeded].name

        mission.data.custom.scrapTypeNeededName = scrapTypeNeededName --Shortcut for text formatting. Could technically do it like line 47 each time but that would be agony.
        mission.data.custom.scrapDelivered = 0 --Allows for partial deliveries.

        --[[=====================================================
            MISSION DESCRIPTION SETUP:
        =========================================================]]
        mission.data.description[1].arguments = { sectorName = _sector.name, giverTitle = giver.translatedTitle }
        mission.data.description[2].text = _Data_in.initialDesc
        mission.data.description[2].arguments = { _SCRAPAMT = mission.data.custom.scrapNeeded, _SCRAPTYPE = scrapTypeNeededName }
        mission.data.description[3].arguments = { _X = _X, _Y = _Y, _SCRAPAMT = mission.data.custom.scrapNeeded, _SCRAPTYPE = scrapTypeNeededName }
        mission.data.description[4].arguments = { _SCRAPDELIVERED = mission.data.custom.scrapDelivered,  _SCRAPAMT = mission.data.custom.scrapNeeded }
    end

    --Run vanilla init. Managers _restoring on its own.
    ScrapDelivery_init(_Data_in, bulletin)
end

--endregion

--region #PHASE CALLS

mission.phases[1] = {}
mission.phases[1].onBegin = function()
    --Can't set this up until the init call on line 70
    mission.data.custom.stationId = mission.data.giver.id.string
end

mission.phases[1].updateServer = function(timeStep)
    --We shouldn't be able to deliver more scrap than needed, but just in case.
    if mission.data.custom.scrapDelivered >= mission.data.custom.scrapNeeded then
        scrapDelivery_finishAndReward()
    end
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

        scriptUI:addDialogOption("Сдать металлолом", "scrapDelivery_onDeliverScrap")
    end
end

--endregion

--region #SERVER CALLS

function scrapDelivery_incrementScrapDelivery()
    local methodName = "Increment Scrap Count"
    if onClient() then
        mission.Log(methodName, "Calling on Client => Invoking on server")
        invokeServerFunction("scrapDelivery_incrementScrapDelivery")
        return
    end
    mission.Log(methodName, "Called on server.")

    local _player = Player()
    local ship = _player.craft

    local scrapAmountNeeded = mission.data.custom.scrapNeeded - mission.data.custom.scrapDelivered

    local holdAmount = ship:getCargoAmount(mission.data.custom.scrapTypeNeededName)

    local scrapToDeliver = holdAmount
    if scrapAmountNeeded < holdAmount then
        scrapToDeliver = scrapAmountNeeded
    end

    mission.Log(methodName, "Needed: " .. tostring(scrapAmountNeeded) .. " " .. mission.data.custom.scrapTypeNeededName .. " In hold: " .. tostring(holdAmount) .. " Delivering: " .. tostring(scrapToDeliver))

    --Remove from hold
    ship:removeCargo(mission.data.custom.scrapTypeNeededName, scrapToDeliver)

    --Increment delivered amount
    mission.data.custom.scrapDelivered = mission.data.custom.scrapDelivered + scrapToDeliver

    mission.data.description[4].arguments = { _SCRAPDELIVERED = mission.data.custom.scrapDelivered,  _SCRAPAMT = mission.data.custom.scrapNeeded }
    
    --sync w/ client.
    sync()
end
callable(nil, "scrapDelivery_incrementScrapDelivery")

function scrapDelivery_finishAndReward()
    local _MethodName = "Finish and Reward"
    mission.Log(_MethodName, "Running win condition.")

    reward()
    accomplish()
end

--endregion

--region #CLIENT CALLS

function scrapDelivery_onDeliverScrap(entityId)
    local methodName = "On Deliver Scrap"
    mission.Log(methodName, "Beginning. Entity ID is " .. tostring(entityId))

    local conditionFunc = function()
        --print("Entering condition func")
        local _player = Player()
        local ship = _player.craft

        if not _player or not ship then
            return false
        end

        local holdAmount = ship:getCargoAmount(mission.data.custom.scrapTypeNeededName)
        if holdAmount > 0 then
            return true
        end

        return false
    end
    
    local dockedFunc = function()
        local dockedDialog = {}
        dockedDialog.text = "Спасибо за доставку лома! Мы добавим это на ваш счет."
        dockedDialog.onEnd = "scrapDelivery_incrementScrapDelivery"

        return dockedDialog
    end

    local undockedFunc = function()
        local undockedDialog = {}
        undockedDialog.text = "Пожалуйста, пристыкуйтесь к станции, чтобы сдать лом!"

        return undockedDialog
    end

    local failedFunc = function()
        local failedDialog = {}
        failedDialog.text = "У вас нет ${_SCRAPTYPE}! Пожалуйста, убедитесь, что у вас есть что сдать." % {_SCRAPTYPE = mission.data.custom.scrapTypeNeededName }
        
        return failedDialog
    end

    mission.Log(methodName, "Getting docked dialog selector.")
    MissionUT.dockedDialogSelector(entityId, conditionFunc(), failedFunc, undockedFunc, dockedFunc)
end

--endregion

--region #MAKEBULLETIN CALLS

function scrapDelivery_formatDescription(_Station)
    local _Faction = Faction(_Station.factionIndex)
    local _Aggressive = _Faction:getTrait("aggressive")

    local descriptionType = 1 --Neutral
    if _Aggressive > 0.5 then
        descriptionType = 2 --Aggressive.
    elseif _Aggressive <= -0.5 then
        descriptionType = 3 --Peaceful.
    end

    local descriptionTable = {
        "Всем предприимчивым капитанам: у нас не хватает ресурсов. ${_SCRAPAMT} ${_SCRAPTYPE} должны покрыть дефицит. Пожалуйста, доставьте их нам - мы заплатим вам за ваше время и усилия. Нам все равно, как вы получите лом - главное, чтобы вы доставили его нам.", --Neutral
        "Способность наших военных уничтожать корабли превосходит нашу способность собирать их останки. Вот тут-то и появляетесь вы. Соберите останки пиратов или ксотан и принесите их нам. Нам нужно ${_SCRAPAMT} ${_SCRAPTYPE}. Вы, конечно, будете вознаграждены. Пусть никто не говорит, что мы не ценим наших миньонов.", --Aggressive
        "Мир вам. Нам нужны дополнительные ресурсы, но наши военные недостаточно сильны, чтобы справиться с местными пиратами и ксотанами. Возможно, если мы сможем приобрести еще ${_SCRAPAMT} ${_SCRAPTYPE}, мы сможем от них отбиться. Пожалуйста, доставьте этот лом нам. Мы заплатим вам за ваши усилия." --Peaceful
    }

    return descriptionTable[descriptionType]
end

mission.makeBulletin = function(_Station)
    local _MethodName = "Make Bulletin"
    mission.Log(_MethodName, "Making Bulletin.")
    --This mission happens in the same sector you accept it in.
    local x, y = Sector():getCoordinates()
    local insideBarrier = MissionUT.checkSectorInsideBarrier(x, y)    
    local target = { x = x, y = y }

    if not target.x or not target.y then
        mission.Log(_MethodName, "Target.x or Target.y not set - returning nil.")
        return 
    end
    
    local _Description = scrapDelivery_formatDescription(_Station)

    --pick a random payout value
    local payout = random():getInt(1, 10) * 10000 * Balancing.GetSectorRewardFactor(x, y)
    if insideBarrier then
        payout = payout * 2
    end

    --pick a random scrap type
    --First, we need to get the material probabilities in the area so the player isn't asked to turn avorion in outside the barrier.
    local matlProbabilities = Balancing_GetMaterialProbability(x, y)
    local availableMatlIndexes = {}
    for matlIdx, probability in pairs(matlProbabilities) do
        if probability > 0 then
            --This gets a bit spammy so uncomment with caution.
            --mission.Log(_MethodName, "Index " .. tostring(matlIdx) .. " is avaialble. Adding " .. tostring(matlIdx + 1) .. " to table.")
            table.insert(availableMatlIndexes, matlIdx + 1) --Iron is matl index 0, and LUA tables start at 1 :vomit:.
        end
    end
    local matlIndexNeeded = getRandomEntry(availableMatlIndexes)
    --mission.Log(_MethodName, "Chose matlIndex " .. tostring(matlIndexNeeded))
    local scrapData = mission.data.custom.scrapTypes[matlIndexNeeded]

    --calculate amount of scrap to turn in based on payout and some other values.
    local matl = Material(scrapData.matlIdx)
    local valuePerMatl = (matl.costFactor * 10)
    local matlAmountNeeded = math.floor((payout / valuePerMatl) / 3) --More efficient than Scrap Scramble, but max payout is capped rather than being "as much as you can bring in" - also, no reward items.
    local matlAmountUpperLimit = math.floor((payout / valuePerMatl) / 2) --Set a minimum efficiency.
    matlAmountNeeded = matlAmountNeeded + random():getInt(-5000, 5000) --Variety is the spice of life.
    matlAmountNeeded = math.min(matlAmountNeeded, matlAmountUpperLimit) 
    matlAmountNeeded = math.max(matlAmountNeeded, 1000) --1000 is the absolute lowest limit.

    reward = payout

    local bulletin =
    {
        -- data for the bulletin board
        brief = mission.data.brief,
        title = mission.data.title,
        description = _Description,
        difficulty = "Variable", --Depends on how you get the scrap.
        reward = "¢${reward}",
        script = "missions/scrapdelivery.lua",
        formatArguments = {x = target.x, y = target.y, reward = createMonetaryString(reward), _SCRAPAMT = matlAmountNeeded, _SCRAPTYPE = scrapData.name },
        msg = "Спасибо! Мы заплатим вам, как только вы доставите лом.",
        giverTitle = _Station.title,
        giverTitleArgs = _Station:getTitleArguments(),
        checkAccept = [[
            local self, player = ...
            if player:hasScript("missions/scrapscramble.lua") or player:hasScript("missions/scrapdelivery.lua") then
                player:sendChatMessage(Entity(self.arguments[1].giver), 1, "You cannot accept additional scrap delivery contracts! Abandon your current one or complete it.")
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
            reward = {credits = reward, relations = 1000, paymentMessage = "Earned %1% credits for delivering scrap." },
            initialDesc = _Description,
            scrapNeeded = matlAmountNeeded,
            scrapTypeNeeded = matlIndexNeeded
        }},
    }

    return bulletin
end

--endregion
