package.path = package.path .. ";data/scripts/lib/?.lua"
package.path = package.path .. ";data/scripts/?.lua"

include("randomext")
include("structuredmission")

mission._Debug = 0
mission._StoryStageValue = "_lotw_story_stage"

--mission.tracing = true
mission.data.silent = true

--globalphase is set to {} in structuredmission so we don't actually need to reset it here! Neat!
mission.globalPhase.updateInterval = 30 --Update every 30 seconds. As long as we don't set an update interval in the subsequent phaess it should always update every 30 seconds.
mission.globalPhase.updateServer = function()
    local methodName = "Обновление глобальной фазы (сервер)"
    mission.Log(methodName, "Выполняется...")

    local _player = Player()

    --Port old version if needed
    lotwQuestUtil_portOldVersion(_player)

    --Set mission phase
    if not _player:getValue(mission._StoryStageValue) then
        _player:setValue(mission._StoryStageValue, 1)
    else
        local phaseID = _player:getValue(mission._StoryStageValue)
        setPhase(phaseID)
    end

    --Set Side mission values
    if not _player:getValue("_lotw_last_side1") then
        _player:setValue("_lotw_last_side1", 0)
    end
    if not _player:getValue("_lotw_last_side2") then
        _player:setValue("_lotw_last_side2", 0)
    end

    --Check faction OK
    --If the player somehow accepted the mission from their own station (or an ally's station... or another player's station, etc. just set it to the start ally)
    --Do this after other set values earlier in the script - that way it guarantees that the player has the value.
    local _StartFaction = _player:getValue("start_ally")
    if _player:getValue("_lotw_faction") then
        local _LOTWFaction = Faction(_player:getValue("_lotw_faction"))

        if _LOTWFaction.isPlayer or _LOTWFaction.isAlliance then
            _player:setValue("_lotw_faction", _StartFaction)
        end
    else
        local storyStage = _player:getValue(mission._StoryStageValue)
        if storyStage > 1 then
            _player:setValue("_lotw_faction", _StartFaction)
        end
    end
end

mission.globalPhase.onRestore = function()
    local _player = Player()

    --Port old version if needed
    lotwQuestUtil_portOldVersion(_player)

    if not _player:getValue(mission._StoryStageValue) then
        _player:setValue(mission._StoryStageValue, 1)
    end
end

mission.phases[1] = {}
mission.phases[1].onSectorEntered = function(x, y)
    local _MethodName = "Фаза 1: Вход в сектор"
    mission.Log(_MethodName, "Выполняется.")

    if onClient() then --We don't care about this on client.
        return
    end

    --Checks the distance already, so no need to run the other distance check.
    lotwQuestUtil_addMissionToStation(x, y, "data/scripts/player/missions/lotw/lotwstory1.lua")
end

mission.phases[1].onSectorArrivalConfirmed = function(x, y)
    local methodName = "Фаза 1: Подтверждение прибытия в сектор"
    mission.Log(methodName, "Выполняется.")
    --I've seen players running heavily modded games completely miss the campaign. So we're adding an obnoxious tutorial.
    local _player = Player()

    --Don't send the hint as the same time as the adventurer - it can distract the player from the hint.
    --I guess the player could potentially never see this, but if they just rocket out of the starting zone at the very start of the game? Fair enough.
    --We also apparently always meet the adventurer so there's no need to worry if the player has the storyline turned off.
    local metAdventurer = _player:getValue("single_interaction_interacted_adventurer1")

    if lotwQuestUtil_checkDistanceOK(x, y) and not _player:getValue("_lotw_obnoxious_tutorial_shown") and metAdventurer then
        mission.Log(methodName, "Дистанция подходит, авантюрист отсутствует, и игрок ещё не видел назойливое руководство — отправляем.")
        invokeClientFunction(_player, "lotwQuestUtil_sendObnoxiousTutorialClient")
    end
end

mission.phases[2] = {}
mission.phases[2].updateServer = function()
    local _player = Player()
    local scriptPath = "missions/lotw/lotwstory2.lua"
    local stageReq = 2
    local x, y = Sector():getCoordinates()

    local frameworkStoryStage = _player:getValue(mission._StoryStageValue)
    if frameworkStoryStage and frameworkStoryStage == stageReq and lotwQuestUtil_checkDistanceOK(x, y) then
        if not _player:hasScript(scriptPath) then
            _player:addScriptOnce(scriptPath)
        end
    end
end

mission.phases[3] = {}
mission.phases[3].updateServer = function()
    local _player = Player()
    local scriptPath = "missions/lotw/lotwstory3.lua"
    local stageReq = 3
    local x, y = Sector():getCoordinates()

    local frameworkStoryStage = _player:getValue(mission._StoryStageValue)
    if frameworkStoryStage and frameworkStoryStage == stageReq and lotwQuestUtil_checkDistanceOK(x, y) then
        if not _player:hasScript(scriptPath) then
            _player:addScriptOnce(scriptPath)
        end
    end
end

mission.phases[4] = {}
mission.phases[4].updateServer = function()
    local _player = Player()
    local scriptPath = "missions/lotw/lotwstory4.lua"
    local stageReq = 4
    local x, y = Sector():getCoordinates()

    local frameworkStoryStage = _player:getValue(mission._StoryStageValue)
    if frameworkStoryStage and frameworkStoryStage == stageReq and lotwQuestUtil_checkDistanceOK(x, y) then
        if not _player:hasScript(scriptPath) then
            _player:addScriptOnce(scriptPath)
        end
    end
end

mission.phases[5] = {}
mission.phases[5].updateServer = function()
    local _player = Player()
    local scriptPath = "missions/lotw/lotwstory5.lua"
    local stageReq = 5
    local x, y = Sector():getCoordinates()

    local frameworkStoryStage = _player:getValue(mission._StoryStageValue)
    if frameworkStoryStage and frameworkStoryStage == stageReq and lotwQuestUtil_checkDistanceOK(x, y) then
        if not _player:hasScript(scriptPath) then
            _player:addScriptOnce(scriptPath)
        end
    end
end

mission.phases[6] = {}
mission.phases[6].onSectorEntered = function(x, y)
    local methodName = "Фаза 6: Вход в сектор"
    mission.Log(methodName, "Выполняется.")

    if onClient() then --We don't care about this on client.
        return
    end

    local _player = Player()

    --Check to see if we even do this. We need to make sure that it has been at least 30 minutes since we last added the side mission.
    local nextValidSide1Time = (_player:getValue("_lotw_last_side1") or 0) + (30 * 60)
    local nextValidSide2Time = (_player:getValue("_lotw_last_side2") or 0) + (30 * 60)

    local currentTime = Server().unpausedRuntime
    local _random = random()

    mission.Log(methodName, "Текущее время: " .. tostring(currentTime) .. ", следующее время для побочной миссии 1: " .. tostring(nextValidSide1Time))
    mission.Log(methodName, "Текущее время: " .. tostring(currentTime) .. ", следующее время для побочной миссии 2: " .. tostring(nextValidSide2Time))

    if currentTime >= nextValidSide1Time and _random:test(0.5) then
        mission.Log(methodName, "Добавление побочной миссии 1 на доску.")
        lotwQuestUtil_addMissionToStation(x, y, "data/scripts/player/missions/lotw/lotwside1.lua")
    end
    if currentTime >= nextValidSide2Time and _random:test(0.5) then
        mission.Log(methodName, "Добавление побочной миссии 2 на доску.")
        lotwQuestUtil_addMissionToStation(x, y, "data/scripts/player/missions/lotw/lotwside2.lua")
    end
end

--region #SERVER CALLS

function lotwQuestUtil_portOldVersion(_player)
    if _player:getValue("_lotw_story_5_accomplished") then
        _player:setValue(mission._StoryStageValue, 6)
        _player:setValue("_lotw_story_complete", true)
        _player:setValue("_lotw_story_5_accomplished", nil)
    end
end

function lotwQuestUtil_checkDistanceOK(x, y)
    local _Dist = math.sqrt(x*x + y*y)
    local _MinDist = 430

    if _Dist < _MinDist then
        return false
    end

    return true
end

function lotwQuestUtil_addMissionToStation(x, y, missionScript)
    local methodName = "Добавление миссии на станцию"

    local dist = math.sqrt(x*x + y*y)
    local minDist = 430

    mission.Log(methodName, "Минимальная дистанция: " .. tostring(minDist))

    if dist >= minDist then
        local stationCandidates = {Sector():getEntitiesByType(EntityType.Station)}
        local stations = {}
        for _, _Station in pairs(stationCandidates) do
            if not _Station.playerOrAllianceOwned and checkCampaignStationOK(_Station.title) then
                table.insert(stations, _Station)
            end
        end

        mission.Log(methodName, "Итоговое количество кандидатов станций: " .. tostring(#stations))

        if #stations > 0 then
            for _, _Station in pairs(stations) do
                local _ok, _bulletin = run(missionScript, "getBulletin", _Station)
                _Station:invokeFunction("bulletinboard", "removeBulletin", _bulletin.brief)
            end

            shuffle(random(), stations)
            stations[1]:invokeFunction("bulletinboard", "addMission", missionScript)
        else
            mission.Log(methodName, "Нет подходящих станций из списка кандидатов.")
        end
    else
        mission.Log(methodName, "Дистанция: " .. tostring(dist) .. ", что не соответствует требованиям.")
    end
end

function lotwQuestUtil_sendObnoxiousTutorialServer()
    local methodName = "Отправка назойливого руководства (сервер)"

    mission.Log(methodName, "Помечаем назойливое руководство как отправленное.")

    local _player = Player(callingPlayer)
    _player:setValue("_lotw_obnoxious_tutorial_shown", true)
end
callable(nil, "lotwQuestUtil_sendObnoxiousTutorialServer")

--endregion

--region #CLIENT CALLS

function lotwQuestUtil_sendObnoxiousTutorialClient()
    local methodName = "Отправка назойливого руководства (клиент)"

    if not onClient() then
        print("ОШИБКА: эта функция работает только на стороне клиента.")
        return
    end

    mission.Log(methodName, "Поиск станции с руководством.")

    local stations = { Sector():getEntitiesByType(EntityType.Station) }
    for _, station in pairs(stations) do
        if station:hasScript("bulletinboard.lua") then
            mission.Log(methodName, "Станция " .. station.name .. " имеет доску объявлений — проверка объявлений.")
            local _, bulletins = station:invokeFunction("bulletinboard.lua", "getDisplayedBulletins")
            for _, bulletin in pairs(bulletins) do
                if string.find(bulletin.script, "lotwstory1.lua") then
                    mission.Log(methodName, "Объявление найдено — отображение назойливой подсказки.")
                    Hud():displayHint("На доске объявлений этой станции есть специальное задание! Вы можете определить, есть ли на станции особое задание, если знак \"!\" рядом с ней имеет цвет, отличный от зелёного.\nНапример, задания Чёрного рынка окрашивают \"!\" в фиолетовый цвет.", station)
                    invokeServerFunction("lotwQuestUtil_sendObnoxiousTutorialServer")
                    return
                end
            end
        end
    end
end

--endregion
