package.path = package.path .. ";data/scripts/lib/?.lua"
package.path = package.path .. ";data/scripts/?.lua"

include("structuredmission")

local Balancing = include("galaxy")
local Xsotan = include("story/xsotan")

mission._Debug = 0
mission._Name = "Уничтожить Ксотанский дредноут"

--region #INIT

--Standard mission data.
mission.data.brief = mission._Name
mission.data.title = mission._Name
mission.data.autoTrackMission = true
mission.data.description = {
    { text = "Вы получили следующий запрос от ${giverTitle} из сектора ${sectorName}:" }, --Placeholder
    { text = "..." }, --Placeholder
    { text = "Направляйтесь в сектор (${_X}:${_Y})", bulletPoint = true, fulfilled = false },
    { text = "Уничтожьте дредноут Ксотан", bulletPoint = true, fulfilled = false, visible = false }
}

mission.data.accomplishMessage = "..."
mission.data.failMessage = "..." --Реалистично говоря, вы этого не увидите.

local DestroyXsoDread_init = initialize
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
        mission.data.custom.dangerLevel = _Data_in.dangerLevel
        mission.data.custom.dreadnoughtKilled = 0
        mission.data.custom.inBarrier = _Data_in.insideBarrier
        if mission.data.custom.inBarrier then
            local _KilledGuardian = Player():getValue("wormhole_guardian_destroyed")
            if _KilledGuardian then
                mission.Log(_MethodName, "Player killed guardian. Setting joker mode.")
                mission.data.custom.killedGuardian = true
                _Data_in.reward.credits = _Data_in.reward.credits * 3
                _Data_in.reward.relations = _Data_in.reward.relations + 2000
            end
        end

        --[[=====================================================
            MISSION DESCRIPTION SETUP:
        =========================================================]]
        mission.data.description[1].arguments = { sectorName = _sector.name, giverTitle = giver.translatedTitle }
        mission.data.description[2].text = _Data_in.initialDesc
        mission.data.description[2].arguments = { _X = _X, _Y = _Y }
        mission.data.description[3].arguments = { _X = _X, _Y = _Y }

        mission.data.accomplishMessage = _Data_in.winMsg
        mission.data.failMessage = _Data_in.loseMsg
    end

    --Run vanilla init. Managers _restoring on its own.
    DestroyXsoDread_init(_Data_in, bulletin)
end

--endregion

--region #PHASE CALLS

mission.globalPhase.noBossEncountersTargetSector = true
mission.globalPhase.noPlayerEventsTargetSector = true
mission.globalPhase.noLocalPlayerEventsTargetSector = true

mission.globalPhase.onAbandon = function()
    if mission.data.location then
        runFullSectorCleanup(true)
    end
end

mission.globalPhase.onFail = function()
    if mission.data.location then
        runFullSectorCleanup(true)
    end
end

mission.globalPhase.onAccomplish = function()
    if mission.data.location then
        runFullSectorCleanup(false)
    end
end

mission.phases[1] = {}
mission.phases[1].showUpdateOnEnd = true
mission.phases[1].onTargetLocationEntered = function(x, y)
    local methodName = "Phase 1 On Target Location Entered"
    mission.data.description[3].fulfilled = true
    mission.data.description[4].visible = true

    if onServer() then
        --We don't need to do much more than this - the dreadnought creation script itself handles the rest.
        local dreadnought = Xsotan.createDreadnought(nil, mission.data.custom.dangerLevel, mission.data.custom.killedGuardian)
        --Attach the boss script.
        if mission.data.custom.dangerLevel == 10 then
            dreadnought:addScriptOnce("esccbossdespair.lua")
        else
            dreadnought:addScriptOnce("esccbossblades.lua")
        end

        mission.data.custom.cleanUpSector = true
    end
end

mission.phases[1].onTargetLocationArrivalConfirmed = function(x, y)
    nextPhase()
end

mission.phases[2] = {}
mission.phases[2].timers = {}
mission.phases[2].onEntityDestroyed = function(_ID, _LastDamageInflictor)
    local destroyedEntity = Entity(_ID)

    if atTargetLocation() and destroyedEntity:getValue("xsotan_dreadnought") then
        mission.data.custom.dreadnoughtKilled = mission.data.custom.dreadnoughtKilled + 1
    end
end

mission.phases[2].onAbandon = function()
    destroyXsoDread_failAndPunish()
end

--region #PHASE 2 TIMER CALLS

if onServer() then

mission.phases[2].timers[1] = {
    time = 5, 
    callback = function() 
        local methodName = "Phase 2 Timer 1 Callback"
        mission.Log(methodName, "Running win condition")

        local dreadnoughts = {Sector():getEntitiesByScriptValue("xsotan_dreadnought")}

        if atTargetLocation() and mission.data.custom.dreadnoughtKilled >= 1 and #dreadnoughts == 0 then
            destroyXsoDread_finishAndReward()
        end
    end,
    repeating = true
}

mission.phases[2].timers[2] = {
    time = 5, 
    callback = function() 
        local methodName = "Phase 2 Timer 2 Callback"
        mission.Log(methodName, "Running fail condition")

        local dreadnoughts = {Sector():getEntitiesByScriptValue("xsotan_dreadnought")}

        if atTargetLocation() and mission.data.custom.dreadnoughtKilled == 0 and #dreadnoughts == 0 then
            --The dreadnought left the sector. Realistically speaking this will not happen due to the fact that it aggros instantly.
            destroyXsoDread_failAndPunish()
        end
    end,
    repeating = true
}

end

--endregion

--endregion

--region #SERVER CALLS

function destroyXsoDread_finishAndReward()
    local _MethodName = "Finish and Reward"
    mission.Log(_MethodName, "Running win condition.")

    reward()
    accomplish()
end

function destroyXsoDread_failAndPunish()
    local _MethodName = "Fail and Punish"
    mission.Log(_MethodName, "Running lose condition.")

    punish()
    fail()
end

--endregion

--region #MAKEBULLETIN CALLS

function destroyXsoDread_formatWinMessage(_Station)
    local _Faction = Faction(_Station.factionIndex)
    local _Aggressive = _Faction:getTrait("aggressive")
    local _MsgType = 1 --1 = Neutral / 2 = Aggressive / 3 = Peaceful

    if _Aggressive > 0.5 then
        _MsgType = 2
    elseif _Aggressive <= -0.5 then
        _MsgType = 3
    end

    local _Msgs = 
    { 
        "Спасибо за уничтожение Ксотана для нас. Вот ваша награда, как и было обещано.",
        "Спасибо за уничтожение дредноута. Одной угрозой меньше для нас. Мы перевели награду на ваш счет.",
        "Мы наблюдали за телеметрией боя и поняли, что мы бы не справились с угрозой такого масштаба. Спасибо вам. Вот ваша награда."
    }

    return _Msgs[_MsgType]
end

function destroyXsoDread_formatLoseMessage(_Station)
    local _Faction = Faction(_Station.factionIndex)
    local _Aggressive = _Faction:getTrait("aggressive")
    local _MsgType = 1 --1 = Neutral / 2 = Aggressive / 3 = Peaceful

    if _Aggressive > 0.5 then
        _MsgType = 2
    elseif _Aggressive <= -0.5 then
        _MsgType = 3
    end

    local _Msgs = {
        "Вы не смогли его уничтожить? Очень жаль. Мы найдем кого-нибудь другого, кто позаботится об этом.",
        "Мы видим, что вы не справились с задачей. Неприятно, но неудивительно. Нам следовало позаботиться об этом самим.",
        "Вы не смогли его уничтожить? Это плохо... у нас и так было мало вариантов..."
    }

    return _Msgs[_MsgType]
end

function destroyXsoDread_formatDescription(_Station)
    local _Faction = Faction(_Station.factionIndex)
    local _Aggressive = _Faction:getTrait("aggressive")

    local descriptionType = 1 --Neutral
    if _Aggressive > 0.5 then
        descriptionType = 2 --Aggressive.
    elseif _Aggressive <= -0.5 then
        descriptionType = 3 --Peaceful.
    end

    local descriptionTable = {
        "Наши разведчики засекли большой сигнал Ксотан в секторе (${_X}:${_Y}). Мы не можем рисковать тем, что этот корабль Ксотан будет угрожать нашим операциям. Мы предлагаем награду любому капитану, который сможет уничтожить его для нас. Будьте осторожны - мы понятия не имеем, на что он способен.", --Neutral
        "Мы обнаружили большой сигнал Ксотан в секторе (${_X}:${_Y}), но наши военные заняты несколькими другими обязательствами, и мы не можем выделить необходимые силы, чтобы справиться с ним. Уничтожьте его. Мы заплатим вам довольно щедрое вознаграждение за это. Будьте начеку - он довольно силен.", --Aggressive
        "Мир вам, капитан. Это экстренный запрос - недавно мы обнаружили крупного Ксотана, движущегося через сектор (${_X}:${_Y}). Мы попытались атаковать его, но он без труда уничтожил наши миротворческие силы. Нам нужна ваша помощь, чтобы остановить его - мы заплатим вам за ваши усилия." --Peaceful
    }

    return descriptionTable[descriptionType]
end

mission.makeBulletin = function(_Station)
    local _MethodName = "Make Bulletin"
    --We don't need a specific type of sector here. Just an empty one that's on the same side of the barrier as the questgiver.
    local _sector = Sector()

    local target = {}
    local x, y = _sector:getCoordinates()
    local insideBarrier = MissionUT.checkSectorInsideBarrier(x, y)
    target.x, target.y = MissionUT.getEmptySector(x, y, 2, 15, insideBarrier)

    if not target.x or not target.y then
        mission.Log(_MethodName, "Target.x or Target.y not set - returning nil.")
        return 
    end

    local _DangerLevel = random():getInt(1, 10)
    --_DangerLevel = 10

    local _IconIn = nil
    local _Difficulty = "Сложный"
    if _DangerLevel > 5 then
        _Difficulty = "Экстремальный"
    end
    if _DangerLevel == 10 then
        _IconIn = "data/textures/icons/hazard-sign.png"
        _Difficulty = "Смертный приговор"
    end
    
    local _Description = destroyXsoDread_formatDescription(_Station)
    local _WinMsg = destroyXsoDread_formatWinMessage(_Station)
    local _LoseMsg = destroyXsoDread_formatLoseMessage(_Station)

    local _BaseReward = 500000
    if _DangerLevel > 5 then
        _BaseReward = _BaseReward + 200000
    end
    if _DangerLevel == 10 then
        _BaseReward = _BaseReward + 300000
    end
    if insideBarrier then
        _BaseReward = _BaseReward * 2
    end

    local rewardFactor = Balancing.GetSectorRewardFactor(_sector:getCoordinates())
    reward = _BaseReward * rewardFactor --SET REWARD HERE
    reputation = 8000 + (8500 * (0.0175 * _DangerLevel) * rewardFactor) --Anywhere from 8000 to 67781
    punishRep = reputation / 2
    if reputation > 20000 then
        punishRep = reputation / 2.5
    end
    if _DangerLevel == 10 then
        reputation = reputation * 1.5
    end

    local bulletin =
    {
        -- data for the bulletin board
        brief = mission.data.brief,
        title = mission.data.title,
        icon = _IconIn,
        description = _Description,
        difficulty = _Difficulty,
        reward = "¢${reward}",
        script = "missions/destroyxsodread.lua",
        formatArguments = { _X = target.x, _Y = target.y, reward = createMonetaryString(reward)},
        msg = "Спасибо. Мы отследили дредноут до \\s(%i:%i). Пожалуйста, уничтожьте его.",
        giverTitle = _Station.title,
        giverTitleArgs = _Station:getTitleArguments(),
        onAccept = [[
            local self, player = ...
            player:sendChatMessage(Entity(self.arguments[1].giver), 0, self.msg, self.formatArguments._X, self.formatArguments._Y)
        ]],

        -- data that's important for our own mission
        arguments = {{
            giver = _Station.index,
            location = target,
            reward = { credits = reward, relations = reputation, paymentMessage = "Заработано %1% за уничтожение дредноута." },
            punishment = { relations = punishRep },
            dangerLevel = _DangerLevel,
            initialDesc = _Description,
            winMsg = _WinMsg,
            loseMsg = _LoseMsg,
            iconIn = _IconIn,
            insideBarrier = insideBarrier
        }},
    }

    return bulletin
end

--endregion
