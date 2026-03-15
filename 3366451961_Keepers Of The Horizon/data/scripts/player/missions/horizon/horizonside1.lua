--[[
    SIDE MISSION 1: Operation Witching Hour
]]
package.path = package.path .. ";data/scripts/lib/?.lua"
package.path = package.path .. ";data/scripts/?.lua"

include("callable")
include("structuredmission")

ESCCUtil = include("esccutil")
HorizonUtil = include("horizonutil")

local Placer = include("placer")

mission._Debug = 0
mission._Name = "Operation Witching Hour"

--region #INIT / DATA

--Standard mission data.
mission.data.brief = mission._Name
mission.data.title = mission._Name
mission.data.autoTrackMission = true
mission.data.icon = "data/textures/icons/snowflake-2.png"
mission.data.description = {
    { text = "Вы получили следующий запрос от ${sectorName} ${giverTitle}:" },
    { text = "..." }, --Placeholder
    { text = "Встретьтесь с Варлансом в (${_X}:${_Y})", bulletPoint = true, fulfilled = false },
    { text = "Направляйтесь в сектор (${_X}:${_Y})", bulletPoint = true, fulfilled = false, visible = false },
    { text = "Победите Гензель и Гретель Mk. II", bulletPoint = true, fulfilled = false, visible = false }
}

mission.data.accomplishMessage = "Компания Frostbite благодарит вас. Вот ваша компенсация."

--Custom data that we'll want.
mission.data.custom.dangerLevel = 10 --Key everything off of danger 10.
mission.data.custom.spawnedBoss = false
mission.data.custom.playedBossCinematic = false

--endregion

--region #PHASE CALLS

mission.globalPhase.noBossEncountersTargetSector = true

mission.globalPhase.onAbandon = function()
    kothSide1_setLastMissionTime()
    if mission.data.location then
        runFullSectorCleanup(true)
    end
end

mission.globalPhase.onFail = function()
    kothSide1_setLastMissionTime()
    if mission.data.location then
        runFullSectorCleanup(true)
    end
end

mission.globalPhase.onAccomplish = function()
    kothSide1_setLastMissionTime()
    if mission.data.location then
        runFullSectorCleanup(false)
    end
end

mission.globalPhase.onTargetLocationEntered = function(_X, _Y)
    mission.data.timeLimit = nil 
    mission.data.timeLimitInDescription = false
end

mission.globalPhase.onTargetLocationLeft = function(_X, _Y)
    mission.data.timeLimit = mission.internals.timePassed + (5 * 60) --Player has 5 minutes to head back to the sector.
    mission.data.timeLimitInDescription = true --Show the player how much time is left.
end

mission.phases[1] = {}
mission.phases[1].showUpdateOnEnd = true
mission.phases[1].onBegin = function()
    local _Giver = Entity(mission.data.giver.id)

    mission.data.description[1].arguments = { sectorName = Sector().name, giverTitle = _Giver.translatedTitle }
    mission.data.description[2].text = kothSide1_formatDescription()
    mission.data.description[3].arguments = { _X = mission.data.location.x, _Y = mission.data.location.y }
end

mission.phases[1].onTargetLocationEntered = function(x, y)
    local _MethodName = "Phase 1 On Target Location Entered"
    mission.Log(_MethodName, "Beginning...")
    mission.data.description[3].fulfilled = true

    if onServer() then
        kothSide1_spawnVarlance(true)
    end
end

mission.phases[1].onTargetLocationArrivalConfirmed = function(_X, _Y)
    mission.data.custom.secondLocation = kothSide1_getNextLocation()

    local sX = mission.data.custom.secondLocation.x
    local sY = mission.data.custom.secondLocation.y

    mission.data.description[4].arguments = { _X = sX, _Y = sY }

    sync()
    invokeClientFunction(Player(), "kothSide1_onPhase1Dialog", mission.data.custom.varlanceID, sX, sY)
end

local kothSide1_onPhase1DialogEnd = makeDialogServerCallback("kothSide1_onPhase1DialogEnd", 1, function()
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

    if onServer() then
        if not mission.data.custom.spawnedBoss then
            kothSide1_spawnVarlance(false)
            kothSide1_spawnBoss()
            mission.data.custom.spawnedBoss = true
        else
            if mission.data.custom.gretelID and Sector():exists(mission.data.custom.gretelID) then
                local gretel = Entity(mission.data.custom.gretelID)
                gretel:invokeFunction("lasersniper.lua", "resetTimeToActive", 15)
            end
        end
    end
end

mission.phases[2].onTargetLocationArrivalConfirmed = function(_X, _Y)
    if not mission.data.custom.playedBossCinematic then
        invokeClientFunction(Player(), "kothSide1_onBossAnimation")
        mission.data.custom.playedBossCinematic = true
    end
end

--region #PHASE 2 TIMER CALLS

if onServer() then

mission.phases[2].timers[1] = {
    time = 180, --He doesn't have the resources of Adriana, can't respawn as quickly.
    callback = function()
        local _MethodName = "Phase 2 Timer 1 Callback"

        if atTargetLocation() then
            mission.Log(_MethodName, "On Location - respawning Varlance if needed.")

            kothSide1_spawnVarlance(false)
        end
    end,
    repeating = true
}

mission.phases[2].timers[2] = {
    time = 10,
    callback = function()
        if atTargetLocation() then
            local hanselCt = ESCCUtil.countEntitiesByValue("is_alpha_hansel")
            local gretelCt = ESCCUtil.countEntitiesByValue("is_beta_gretel")

            if hanselCt == 0 then
                if gretelCt > 0 and not mission.data.custom.gretelOverdriveActive then
                    mission.data.custom.gretelOverdriveActive = true

                    local _sector = Sector()
                    local gretel = { _sector:getEntitiesByScriptValue("is_beta_gretel") }
                    _sector:broadcastChatMessage(gretel[1], ChatMessageType.Chatter, "НЕТ!!! Перегрузите реактор СЕЙЧАС! Мы утащим их в глубины ада вместе с собой!")
                    gretel[1]:addScriptOnce("frenzy.lua", { _IncreasePerUpdate = 0.1, _DamageThreshold = 1.01 })
                end
            end

            if gretelCt == 0 then
                --I don't anticipate players seeing this under most cirumstances, buuuuut...
                if hanselCt > 0 and not mission.data.custom.hanselOverdriveActive then
                    mission.data.custom.hanselOverdriveActive = true

                    local _sector = Sector()
                    local hansel = { _sector:getEntitiesByScriptValue("is_alpha_hansel") }
                    _sector:broadcastChatMessage(hansel[1], ChatMessageType.Chatter, "Как... как это возможно?! Убейте их! УБЕЙТЕ ИХ СЕЙЧАС!!!")
                    hansel[1]:addScriptOnce("frenzy.lua", { _IncreasePerUpdate = 0.25, _DamageThreshold = 1.01 })
                end
            end
    
            if hanselCt == 0 and gretelCt == 0 then
                mission.data.custom.allowPayment = true
                nextPhase()
            end
        end
    end,
    repeating = true
}

mission.phases[2].timers[3] = {
    time = 180,
    callback = function()
        local _MethodName = "Phase 4 Timer 1 Callback"
        mission.Log(_MethodName, "Beginning...")

        local _sector = Sector()

        if atTargetLocation() then
            mission.Log(_MethodName, "Spawning torpedo loader.")

            if not mission.data.custom.varlanceP4ChatterSent and _sector:exists(mission.data.custom.varlanceID) then
                mission.data.custom.varlanceP4ChatterSent = true
                HorizonUtil.varlanceChatter("Торпедный погрузчик на месте. Сблизьтесь с ними, и они смогут предоставить вам диверсионные торпеды.")
            end

            --spawn a torp loader and order it to follow the player ship.
            local torpLoader = HorizonUtil.spawnFrostbiteTorpedoLoader(true, true)
            local torpLoaderAI = ShipAI(torpLoader)

            --Get player ship
            local ship = Player().craft
            if ship then 
                torpLoaderAI:setFollow(ship, false)
            else
                torpLoaderAI:setFlyLinear(torpLoader.look * 20000, 0, false)
            end

            --Let's be real - these will almost always get destroyed by the Gretel before they hit the 2 minute mark.
            torpLoader:addScriptOnce("entity/utility/delayeddelete.lua", random():getFloat(120, 130))
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
end

mission.phases[3].onBeginServer = function()
    kothSide1_spawnVarlance()

    invokeClientFunction(Player(), "kothSide1_onPhase3Dialog", mission.data.custom.varlanceID)
end

local kothSide1_onPhase3DialogEnd = makeDialogServerCallback("kothSide1_onPhase3DialogEnd", 3, function()
    local methodName = "On Phase 3 Dialog End"

    local _Varlance = Entity(mission.data.custom.varlanceID)
    _Varlance:addScriptOnce("entity/utility/delayeddelete.lua", random():getFloat(4, 7))

    if mission.data.custom.allowPayment then
        mission.Log(methodName, "Rewarding and accomplishing.")
        kothSide1_finishAndReward()
    else
        mission.Log(methodName, "accomplishing only.")
        accomplish()
    end
end)

--endregion

--region #SERVER CALLS

function kothSide1_getNextLocation()
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

function kothSide1_spawnVarlance(_DeleteOnLeft)
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

function kothSide1_spawnBoss()
    local methodName = "Spawn Boss"
    
    local _random = random()

    --Get player position first.
    local look = _random:getVector(-100, 100)
    local up = _random:getVector(-100, 100)
    local pos = vec3(0, 0, 0)
    local _Player = Player()
    local _Ship = Entity(_Player.craftIndex)

    if _Ship then
        pos = _Ship.translationf
    end

    local hanselPos = ESCCUtil.getVectorAtDistance(pos, 3500, true)
    local hanselMatrix = MatrixLookUpPosition(look, up, hanselPos)

    local gretelPos = ESCCUtil.getVectorAtDistance(hanselPos, 900, false)
    local gretelMatrix = MatrixLookUpPosition(look, up, gretelPos)

    local hansel = HorizonUtil.spawnAlphaHansel(false, hanselMatrix, false, true)
    local gretel = HorizonUtil.spawnBetaGretel(false, gretelMatrix, false, true)

    mission.data.custom.hanselID = hansel.index
    mission.data.custom.gretelID = gretel.index

    Placer.resolveIntersections()

    mission.data.custom.cleanUpSector = true
end

function kothSide1_setLastMissionTime()
    local _player = Player()
    local runTime = Server().unpausedRuntime

    _player:setValue("_horizonkeepers_last_side1", runTime)
end

function kothSide1_finishAndReward()
    local _MethodName = "Finish and Reward"
    mission.Log(_MethodName, "Running win condition.")

    Player():setValue("_horizonkeepers_side1_complete", true)

    reward()
    accomplish()
end

--endregion

--region #CLIENT CALLS

function kothSide1_onBossAnimation()
    startBossCameraAnimation(mission.data.custom.hanselID)
end

--endregion

--region #CLIENT DIALOG CALLS

function kothSide1_onPhase1Dialog(varlanceID, sX, sY)
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
    d5.onEnd = kothSide1_onPhase1DialogEnd

    ESCCUtil.setTalkerTextColors({d0, d1, d2, d3, d4}, "Varlance", HorizonUtil.getDialogVarlanceTalkerColor(), HorizonUtil.getDialogVarlanceTextColor())

    ESCCUtil.setTalkerTextColors({d5}, "Sophie", HorizonUtil.getDialogSophieTalkerColor(), HorizonUtil.getDialogSophieTextColor())

    ScriptUI(varlanceID):interactShowDialog(d0, false)
end

function kothSide1_onPhase3Dialog(varlanceID)
    local d0 = {}
    local d1 = {}
    local d2 = {}
    local d3 = {}

    d0.text = "Хорошая работа сегодня."
    d0.followUp = d1

    d1.text = "Мы не можем позволить Horizon возродить их мечты о завоевании."
    d1.followUp = d2

    d2.text =  "Я продолжу следить. Не умри там, приятель."
    d2.followUp = d3

    d3.text = "Как всегда, это было приятно! До следующего раза, капитан!"
    d3.onEnd = kothSide1_onPhase3DialogEnd

    ESCCUtil.setTalkerTextColors({d0, d1, d2}, "Varlance", HorizonUtil.getDialogVarlanceTalkerColor(), HorizonUtil.getDialogVarlanceTextColor())

    ESCCUtil.setTalkerTextColors({d3}, "Sophie", HorizonUtil.getDialogSophieTalkerColor(), HorizonUtil.getDialogSophieTextColor())

    ScriptUI(varlanceID):interactShowDialog(d0, false)
end

--endregion

--region #MAKEBULLETIN CALLS

function kothSide1_formatDescription()
    return "Всем независимым капитанам, это капитан Варланс из наемной группы Frostbite Company. Некоторое время назад компания под названием Horizon Keepers, LTD. попыталась выпустить пару прототипов оружия на галактику. Если бы им позволили беспрепятственно буйствовать, они могли бы нанести неисчислимый ущерб. Я получил известие, что они собрали новый набор аналогичного оружия - я ищу кого-нибудь, кто поможет мне выследить и уничтожить их, прежде чем они будут выпущены."
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

    reward = 25000000

    local bulletin =
    {
        -- data for the bulletin board
        brief = mission.data.brief,
        title = mission.data.title,
        icon = mission.data.icon,
        description = kothSide1_formatDescription(),
        difficulty = "Экстремальный",
        reward = "¢${reward}",
        script = "missions/horizon/horizonside1.lua",
        formatArguments = {x = target.x, y = target.y, reward = createMonetaryString(reward)},
        msg = "Мы выследили оружие раньше. Встретьтесь со мной в \\s(%1%:%2%), и мы обсудим план.",
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
            reward = {credits = reward, paymentMessage = "Заработал %1% кредитов за уничтожение прототипов оружия."}
        }},
    }

    return bulletin
end

--endregion
