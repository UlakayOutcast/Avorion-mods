--[[
    ПОБОЧНАЯ МИССИЯ 2: Операция "Ксосология"
]]
package.path = package.path .. ";data/scripts/lib/?.lua"
package.path = package.path .. ";data/scripts/?.lua"

include("callable")
include("structuredmission")

ESCCUtil = include("esccutil")
HorizonUtil = include("horizonutil")

local Placer = include("placer")

mission._Debug = 0
mission._Name = "Операция \"Ксосология\""

--region #INIT / DATA

--Стандартные данные миссии.
mission.data.brief = mission._Name
mission.data.title = mission._Name
mission.data.autoTrackMission = true
mission.data.icon = "data/textures/icons/snowflake-2.png"
mission.data.description = {
    { text = "Вы получили следующий запрос от ${giverTitle} из сектора ${sectorName}:" },
    { text = "" }, --Заполнитель
    { text = "Встретьтесь с Варлансом в (${_X}:${_Y})", bulletPoint = true, fulfilled = false },
    { text = "Отправляйтесь в сектор (${_X}:${_Y})", bulletPoint = true, fulfilled = false, visible = false },
    { text = "Победите XSOLOGIZE Mk II", bulletPoint = true, fulfilled = false, visible = false },
    { text = "Уберите остатки Horizon", bulletPoint = true, fulfilled = false, visible = false }
}

mission.data.accomplishMessage = "Компания Frostbite благодарит вас. Вот ваша компенсация."

--Пользовательские данные, которые нам понадобятся.
mission.data.custom.dangerLevel = 10 --Все основано на уровне опасности 10.
mission.data.custom.spawnedBoss = false
mission.data.custom.playedBossCinematic = false

--endregion

--region #PHASE CALLS

mission.globalPhase.noBossEncountersTargetSector = true

mission.globalPhase.onAbandon = function()
    kothSide2_setLastMissionTime()
    if mission.data.location then
        runFullSectorCleanup(true)
    end
end

mission.globalPhase.onFail = function()
    kothSide2_setLastMissionTime()
    if mission.data.location then
        runFullSectorCleanup(true)
    end
end

mission.globalPhase.onAccomplish = function()
    kothSide2_setLastMissionTime()
    if mission.data.location then
        runFullSectorCleanup(false)
    end
end

mission.globalPhase.onTargetLocationEntered = function(_X, _Y)
    mission.data.timeLimit = nil 
    mission.data.timeLimitInDescription = false
end

mission.globalPhase.onTargetLocationLeft = function(_X, _Y)
    mission.data.timeLimit = mission.internals.timePassed + (5 * 60) --У игрока есть 5 минут, чтобы вернуться в сектор.
    mission.data.timeLimitInDescription = true --Показать игроку, сколько времени осталось.
end

mission.phases[1] = {}
mission.phases[1].showUpdateOnEnd = true
mission.phases[1].onBegin = function()
    local _Giver = Entity(mission.data.giver.id)

    mission.data.description[1].arguments = { sectorName = Sector().name, giverTitle = _Giver.translatedTitle }
    mission.data.description[2].text = kothSide2_formatDescription()
    mission.data.description[3].arguments = { _X = mission.data.location.x, _Y = mission.data.location.y }
end

mission.phases[1].onTargetLocationEntered = function(x, y)
    local _MethodName = "Phase 1 On Target Location Entered"
    mission.Log(_MethodName, "Beginning...")
    mission.data.description[3].fulfilled = true

    if onServer() then
        kothSide2_spawnVarlance(true)
    end
end

mission.phases[1].onTargetLocationArrivalConfirmed = function(_X, _Y)
    mission.data.custom.secondLocation = kothSide2_getNextLocation()

    local sX = mission.data.custom.secondLocation.x
    local sY = mission.data.custom.secondLocation.y

    mission.data.description[4].arguments = { _X = sX, _Y = sY }

    sync()
    invokeClientFunction(Player(), "kothSide2_onPhase1Dialog", mission.data.custom.varlanceID, sX, sY)
end

local kothSide2_onPhase1DialogEnd = makeDialogServerCallback("kothSide2_onPhase1DialogEnd", 1, function()
    local _Varlance = Entity(mission.data.custom.varlanceID)
    _Varlance:addScriptOnce("entity/utility/delayeddelete.lua", random():getFloat(4, 7))

    nextPhase()
end)

mission.phases[2] = {}
mission.phases[2].timers = {}
mission.phases[2].onBegin = function()
    mission.data.location = mission.data.custom.secondLocation
    
    mission.data.description[4].visible = true
end

mission.phases[2].onTargetLocationEntered = function(x, y)
    local _MethodName = "Phase 2 On Target Location Entered"
    mission.Log(_MethodName, "Beginning...")
    mission.data.description[4].fulfilled = true
    mission.data.description[5].visible = true

    if onServer() and not mission.data.custom.spawnedBoss then
        if not mission.data.custom.spawnedBoss then
            kothSide2_spawnVarlance(false)
            kothSide2_spawnBoss()
            mission.data.custom.spawnedBoss = true
        else
            if mission.data.custom.xsologizeID and Sector():exists(mission.data.custom.xsologizeID) then
                local xsologize = Entity(mission.data.custom.xsologizeID)
                xsologize:invokeFunction("lasersniper.lua", "resetTimeToActive", 15)
            end
        end

    end
end

mission.phases[2].onTargetLocationArrivalConfirmed = function(_X, _Y)
    if not mission.data.custom.playedBossCinematic then
        invokeClientFunction(Player(), "kothSide2_onBossAnimation")
        mission.data.custom.playedBossCinematic = true
    end
end

--region #PHASE 2 TIMER CALLS

if onServer() then

mission.phases[2].timers[1] = {
    time = 180, --У него нет ресурсов Адрианы, не может так быстро возродиться.
    callback = function()
        local _MethodName = "Phase 2 Timer 1 Callback"

        if atTargetLocation() then
            mission.Log(_MethodName, "On Location - respawning Varlance if needed.")

            kothSide2_spawnVarlance(false)
        end
    end,
    repeating = true
}

mission.phases[2].timers[2] = {
    time = 10,
    callback = function()
        local methodName = "Phase 2 Timer 2 Callback"
        --mission.Log(methodName, "Beginning...") --Будьте осторожны с включением этого - может вызвать много сообщений в журнале.

        local _sector = Sector()

        if atTargetLocation() then
            if not _sector:exists(mission.data.custom.xsologizeID) and not mission.data.custom.allowPayment then
                mission.data.custom.allowPayment = true
                mission.data.description[5].fulfilled = true
                mission.data.description[6].visible = true
                sync()
            end

            local horizonCt = ESCCUtil.countEntitiesByValue("is_horizon")
            if horizonCt == 0 and mission.data.custom.allowPayment then
                nextPhase()
            end
        end
    end,
    repeating = true
}
    
end

--endregion

mission.phases[3] = {}
mission.phases[3].onBegin = function()
    local _MethodName = "Phase 3 On Begin"
    mission.Log(_MethodName, "Beginning...")

    mission.data.description[5].fulfilled = true
    mission.data.description[6].fulfilled = true
end

mission.phases[3].onBeginServer = function()
    kothSide2_spawnVarlance()

    invokeClientFunction(Player(), "kothSide2_onPhase3Dialog", mission.data.custom.varlanceID)
end

local kothSide2_onPhase3DialogEnd = makeDialogServerCallback("kothSide2_onPhase3DialogEnd", 3, function()
    local methodName = "On Phase 3 Dialog End"

    local _Varlance = Entity(mission.data.custom.varlanceID)
    _Varlance:addScriptOnce("entity/utility/delayeddelete.lua", random():getFloat(4, 7))

    if mission.data.custom.allowPayment then
        mission.Log(methodName, "Rewarding and accomplishing.")
        kothSide2_finishAndReward()
    else
        mission.Log(methodName, "accomplishing only.")
        accomplish()
    end
end)

--endregion

--region #SERVER CALLS

function kothSide2_getNextLocation()
    local _MethodName = "Get Next Location"
    
    mission.Log(_MethodName, "Getting a location.")
    local x, y = Sector():getCoordinates()
    local target = {}

    target.x, target.y = MissionUT.getEmptySector(x, y, 4, 8, false)

    mission.Log(_MethodName, "X coordinate of next location is : " .. tostring(target.x) .. " Y coordinate of next location is : " .. tostring(target.y))
    if not target or not target.x or not target.y then
        mission.Log(_MethodName, "Could not find a suitable mission location. Terminating script.")
        terminate()
        return
    end

    return target
end

function kothSide2_spawnVarlance(_DeleteOnLeft)
    local _MethodName = "Spawn Varlance"
    
    local _spawnVarlance = true
    if mission.data.custom.varlanceID then
        local _Varlance = Entity(mission.data.custom.varlanceID)
        if _Varlance and valid(_Varlance) and not _Varlance:getValue("varlance_withdrawing") then
            _spawnVarlance = false
        end
    end

    if _spawnVarlance then
        mission.Log(_MethodName, "No Varlance in sector - spawning him in.")

        local _Varlance = HorizonUtil.spawnVarlanceBattleship(_DeleteOnLeft)

        local varlanceAI = ShipAI(_Varlance)
        varlanceAI:setAggressive()

        mission.data.custom.varlanceID = _Varlance.index
    end
end

function kothSide2_spawnBoss()
    local _MethodName = "Build Boss Sector"
    mission.Log(_MethodName, "Beginning.")

    local _random = random()
    --spawn xsologize - set faction to friendly for a short dialog
    local look = _random:getVector(-100, 100)
    local up = _random:getVector(-100, 100)
    local pos = vec3(0, 0, 0)
    local _Player = Player()
    local _Ship = Entity(_Player.craftIndex)

    if _Ship then
        pos = _Ship.translationf
    end

    local xsolopos = ESCCUtil.getVectorAtDistance(pos, 3500, true)
    local xsoloMatrix = MatrixLookUpPosition(look, up, xsolopos)

    local xsologize = HorizonUtil.spawnProjectXsologizev2(false, xsoloMatrix)

    mission.data.custom.xsologizeID = xsologize.index

    Placer.resolveIntersections()

    mission.data.custom.cleanUpSector = true
end

function kothSide2_setLastMissionTime()
    local _player = Player()
    local runTime = Server().unpausedRuntime

    _player:setValue("_horizonkeepers_last_side2", runTime)
end

function kothSide2_finishAndReward()
    local _MethodName = "Finish and Reward"
    mission.Log(_MethodName, "Running win condition.")

    Player():setValue("_horizonkeepers_side2_complete", true)

    reward()
    accomplish()
end

--endregion

--region #CLIENT CALLS

function kothSide2_onBossAnimation()
    startBossCameraAnimation(mission.data.custom.xsologizeID)
end

--endregion

--region #CLIENT DIALOG CALLS

function kothSide2_onPhase1Dialog(varlanceID, sX, sY)
    local d0 = {}
    local d1 = {}
    local d2 = {}
    local d3 = {}
    local d4 = {}
    local d5 = {}

    d0.text = "Хм."
    d0.followUp = d1

    d1.text = "Не думал, что снова тебя увижу, приятель."
    d1.followUp = d2

    d2.text = "... Но я рад, что ты со мной. Нет никого, кому я бы больше доверял прикрыть мою спину."
    d2.followUp = d3

    d3.text = "Ты видел мою листовку. Ты знаешь, что поставлено на карту."
    d3.followUp = d4

    d4.text = "Наша цель находится в (${_X}:${_Y})." % { _X = sX, _Y = sY }
    d4.followUp = d5

    d5.text = "Ледяная Нова готова к работе! С нетерпением жду возможности снова сразиться с тобой, капитан!"
    d5.onEnd = kothSide2_onPhase1DialogEnd

    ESCCUtil.setTalkerTextColors({d0, d1, d2, d3, d4}, "Varlance", HorizonUtil.getDialogVarlanceTalkerColor(), HorizonUtil.getDialogVarlanceTextColor())

    ESCCUtil.setTalkerTextColors({d5}, "Sophie", HorizonUtil.getDialogSophieTalkerColor(), HorizonUtil.getDialogSophieTextColor())

    ScriptUI(varlanceID):interactShowDialog(d0, false)
end

function kothSide2_onPhase3Dialog(varlanceID)
    local d0 = {}
    local d1 = {}
    local d2 = {}
    local d3 = {}

    d0.text = "Хорошая работа сегодня."
    d0.followUp = d1

    d1.text = "Мы не можем позволить Horizon возродить свои мечты о завоевании."
    d1.followUp = d2

    d2.text =  "Я продолжу следить. Не умри там, приятель."
    d2.followUp = d3

    d3.text = "Как всегда, это было приятно! До следующего раза, капитан!"
    d3.onEnd = kothSide2_onPhase3DialogEnd

    ESCCUtil.setTalkerTextColors({d0, d1, d2}, "Varlance", HorizonUtil.getDialogVarlanceTalkerColor(), HorizonUtil.getDialogVarlanceTextColor())

    ESCCUtil.setTalkerTextColors({d3}, "Sophie", HorizonUtil.getDialogSophieTalkerColor(), HorizonUtil.getDialogSophieTextColor())

    ScriptUI(varlanceID):interactShowDialog(d0, false)
end

--endregion

--region #MAKEBULLETIN CALLS

function kothSide2_formatDescription()
    return "Всем независимым капитанам: это капитан Варланс из наемной группы Frostbite Company. Некоторое время назад компания под названием Horizon Keepers, LTD. успешно сконструировала мерзость, собранную из экспериментальных технологий Xsotan. С этим оружием они могли бы принести в галактику страдания и смерть, невиданные со времен великой войны. Я получил известие, что они завершили улучшенную версию этого оружия и планируют использовать его для возрождения своих мечтаний о завоевании. Их нужно остановить. Я ищу кого-нибудь, кто поможет мне уничтожить его, прежде чем оно сможет послужить своей цели."
end

mission.makeBulletin = function(_Station)
    local _MethodName = "Make Bulletin"
    mission.Log(_MethodName, "Making Bulletin.")

    local target = {}
    --GET TARGET HERE:
    local x, y = Sector():getCoordinates()
    target.x, target.y = MissionUT.getEmptySector(x, y, 4, 8, false)

    if not target.x or not target.y then
        mission.Log(_MethodName, "Target.x or Target.y not set - returning nil.")
        return 
    end

    reward = 40000000

    local bulletin =
    {
        -- data for the bulletin board
        brief = mission.data.brief,
        title = mission.data.title,
        icon = mission.data.icon,
        description = kothSide2_formatDescription(),
        difficulty = "Экстремальный",
        reward = "¢${reward}",
        script = "missions/horizon/horizonside2.lua",
        formatArguments = {x = target.x, y = target.y, reward = createMonetaryString(reward)},
        msg = "Мы выследили XSOLOGIZE Mk II ранее. Встретьтесь со мной в \\s(%1%:%2%), и мы обсудим план.",
        giverTitle = _Station.title,
        giverTitleArgs = _Station:getTitleArguments(),
        checkAccept = [[
            local self, player = ...
            if not player:getValue("_horizonkeepers_story_complete") then
                player:sendChatMessage(Entity(self.arguments[1].giver), 1, "Вы не можете принять эту миссию.")
                return 0
            end
            if player:hasScript("horizonside1.lua") then
                player:sendChatMessage(Entity(self.arguments[1].giver), 1, "Вы не можете принять эту миссию снова!")
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
            reward = {credits = reward, paymentMessage = "Заработал %1% кредитов за уничтожение XSOLOGIZE Mk II."}
        }},
    }

    return bulletin
end

--endregion
