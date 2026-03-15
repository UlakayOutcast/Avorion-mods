--[[
    Срыв пиратской атаки
    ЗАМЕТКИ:
        - Первая, лёгкая миссия для LOTW.
    ДОПОЛНИТЕЛЬНЫЕ ТРЕБОВАНИЯ:
        - Взять миссию с доски объявлений. Она должна быть постоянной, как миссия чёрного рынка.
    ПРИМЕРНЫЙ ПЛАН:
        - Прибыть в сектор.
        - Там будут пираты.
        - Уничтожить их всех. Очень просто и понятно.
    УРОВЕНЬ ОПАСНОСТИ:
        5 - Уничтожить 3 волны по 4 пирата в каждой. Использовать слабые корабли и добавить 1 рейдера в последнюю волну.
]]
package.path = package.path .. ";data/scripts/lib/?.lua"
package.path = package.path .. ";data/scripts/?.lua"

include("callable")
include("structuredmission")

ESCCUtil = include("esccutil")

local AsyncPirateGenerator = include("asyncpirategenerator")
local AsyncShipGenerator = include("asyncshipgenerator")
local Balancing = include("galaxy")
local SpawnUtility = include("spawnutility")

mission._Debug = 0
mission._Name = "Срыв пиратской атаки"

--region #INIT

-- Стандартные данные миссии.
mission.data.brief = mission._Name
mission.data.title = mission._Name
mission.data.autoTrackMission = true
mission.data.icon = "data/textures/icons/silicium.png"
mission.data.description = {
    { text = "Вы получили следующий запрос от ${sectorName} ${giverTitle}:" },
    { text = "..." },
    { text = "Направляйтесь в сектор (${_X}:${_Y})", bulletPoint = true, fulfilled = false },
    { text = "Уничтожьте первую волну пиратов", bulletPoint = true, fulfilled = false, visible = false },
    { text = "Уничтожьте вторую волну пиратов", bulletPoint = true, fulfilled = false, visible = false },
    { text = "Уничтожьте третью волну пиратов", bulletPoint = true, fulfilled = false, visible = false },
    { text = "Встретьтесь с посредником в секторе (${_X}:${_Y})", bulletPoint = true, fulfilled = false, visible = false }
}
mission.data.accomplishMessage = "Хорошая работа. Мы перевели вознаграждение на ваш счёт. Будьте начеку — в будущем будут новые возможности."

local LOTW_Mission_init = initialize
function initialize(_Data_in)
    local _MethodName = "Инициализация"
    mission.Log(_MethodName, "Начало...")

    if onServer() then
        if not _restoring then
            mission.Log(_MethodName, "Вызов на сервере - уровень опасности: " .. tostring(_Data_in.dangerLevel))

            local _X, _Y = _Data_in.location.x, _Data_in.location.y

            local _Sector = Sector()
            local _Giver = Entity(_Data_in.giver)
            --[[=====================================================
                НАСТРОЙКА ПОЛЬЗОВАТЕЛЬСКИХ ДАННЫХ МИССИИ:
                .dangerLevel
                .friendlyFaction
                .firstWaveTaunt
                .waveCounter
                .firstTimerAdvance
                .secondTimerAdvance
                .thirdTimerAdvance
            =========================================================]]
            mission.data.custom.dangerLevel = _Data_in.dangerLevel
            mission.data.custom.friendlyFaction = _Giver.factionIndex

            mission.data.description[1].arguments = { sectorName = _Sector.name, giverTitle = _Giver.translatedTitle }
            mission.data.description[2].text = _Data_in.initialDesc
            mission.data.description[2].arguments = {x = _X, y = _Y, enemyName = mission.data.custom.enemyName }
            mission.data.description[3].arguments = { _X = _X, _Y = _Y }

            LOTW_Mission_init(_Data_in)
        else
            LOTW_Mission_init()
        end
    end

    if onClient() then
        if not _restoring then
            initialSync()
        else
            sync()
        end
    end
end

--endregion

--region #PHASE CALLS

mission.globalPhase.noBossEncountersTargetSector = true
mission.globalPhase.noPlayerEventsTargetSector = true
mission.globalPhase.noLocalPlayerEventsTargetSector = true

mission.phases[1] = {}
mission.phases[1].timers = {}
mission.phases[1].onTargetLocationEntered = function(x, y)
    local _MethodName = "Фаза 1: Вход в целевой сектор"
    mission.Log(_MethodName, "Начало...")
    mission.data.description[3].fulfilled = true
    mission.data.description[4].visible = true

    showMissionUpdated(mission._Name)
    lotwStory1_spawnPirateWave(false, 1)
end

mission.phases[1].onSectorArrivalConfirmed = function(x, y)
    lotwStory1_pirateTaunt()
end

--region #PHASE 1 TIMERS

if onServer() then

mission.phases[1].timers[1] = {
    time = 10,
    callback = function()
        local _MethodName = "Фаза 1: Обратный вызов таймера 1"
        local _Sector = Sector()
        local _X, _Y = _Sector:getCoordinates()
        local _Pirates = {_Sector:getEntitiesByScriptValue("is_pirate")}
        mission.Log(_MethodName, "Количество пиратов: " .. tostring(#_Pirates) .. ", таймер может продвинуться: " .. tostring(mission.data.custom.firstTimerAdvance))
        if _X == mission.data.location.x and _Y == mission.data.location.y and mission.data.custom.firstTimerAdvance and #_Pirates == 0 then
            nextPhase()
        end
    end,
    repeating = true
}

end

--endregion

mission.phases[2] = {}
mission.phases[2].timers = {}
mission.phases[2].showUpdateOnStart = true
mission.phases[2].onBeginServer = function()
    local _MethodName = "Фаза 2: Начало на сервере"
    mission.Log(_MethodName, "Начало...")
    mission.data.description[4].fulfilled = true
    mission.data.description[5].visible = true

    lotwStory1_spawnPirateWave(false, 2)
end

--region #PHASE 2 TIMERS

if onServer() then

mission.phases[2].timers[1] = {
    time = 10,
    callback = function()
        local _MethodName = "Фаза 2: Обратный вызов таймера 1"
        local _Sector = Sector()
        local _X, _Y = _Sector:getCoordinates()
        local _Pirates = {_Sector:getEntitiesByScriptValue("is_pirate")}
        mission.Log(_MethodName, "Количество пиратов: " .. tostring(#_Pirates) .. ", таймер может продвинуться: " .. tostring(mission.data.custom.secondTimerAdvance))
        if _X == mission.data.location.x and _Y == mission.data.location.y and mission.data.custom.secondTimerAdvance and #_Pirates == 0 then
            nextPhase()
        end
    end,
    repeating = true
}

end

--endregion

mission.phases[3] = {}
mission.phases[3].timers = {}
mission.phases[3].showUpdateOnStart = true
mission.phases[3].onBeginServer = function()
    local _MethodName = "Фаза 3: Начало на сервере"
    mission.Log(_MethodName, "Начало...")
    mission.data.description[5].fulfilled = true
    mission.data.description[6].visible = true

    lotwStory1_spawnPirateWave(true, 3)
end

--region #PHASE 3 TIMERS

if onServer() then

mission.phases[3].timers[1] = {
    time = 10,
    callback = function()
        local _MethodName = "Фаза 3: Обратный вызов таймера 1"
        local _Sector = Sector()
        local _X, _Y = _Sector:getCoordinates()
        local _Pirates = {_Sector:getEntitiesByScriptValue("is_pirate")}
        mission.Log(_MethodName, "Количество пиратов: " .. tostring(#_Pirates) .. ", таймер может продвинуться: " .. tostring(mission.data.custom.thirdTimerAdvance))
        if _X == mission.data.location.x and _Y == mission.data.location.y and mission.data.custom.thirdTimerAdvance and #_Pirates == 0 then
            nextPhase()
        end
    end,
    repeating = true
}

end

--endregion

mission.phases[4] = {}
mission.phases[4].showUpdateOnStart = true
mission.phases[4].onBeginServer = function()
    local _MethodName = "Фаза 4: Начало на сервере"
    mission.Log(_MethodName, "Начало...")
    mission.data.description[6].fulfilled = true

    mission.data.location = lotwStory1_getNextLocation()
    mission.data.description[7].arguments = { _X = mission.data.location.x, _Y = mission.data.location.y }

    mission.data.description[7].visible = true

    local _Faction = Faction(mission.data.custom.friendlyFaction)
    Player():sendChatMessage(_Faction.name, 0, "У нас есть посредник, ожидающий вас в секторе \\s(%1%:%2%). Пожалуйста, свяжитесь с ним там.", mission.data.location.x, mission.data.location.y)
end

mission.phases[4].onTargetLocationEntered = function(x, y)
    lotwStory1_spawnLiason()
end

--endregion

--region #SERVER CALLS

function lotwStory1_spawnPirateWave(_LastWave, _WaveNumber)
    local _MethodName = "Спавн волны пиратов"
    mission.Log(_MethodName, "Начало...")

    local rgen = ESCCUtil.getRand()

    local waveTable = { "Bandit", "Bandit" }
    if _LastWave then
        if rgen:getInt(1, 2) == 1 then
            table.insert(waveTable, "Pirate")
        else
            table.insert(waveTable, "Marauder")
        end
        table.insert(waveTable, "Raider")
    else
        if rgen:getInt(1, 2) == 1 then
            table.insert(waveTable, "Pirate")
            if rgen:getInt(1, 2) == 1 then
                table.insert(waveTable, "Marauder")
            else
                table.insert(waveTable, "Pirate")
            end
        else
            table.insert(waveTable, "Marauder")
            table.insert(waveTable, "Pirate")
        end
    end

    mission.data.custom.waveCounter = _WaveNumber

    local generator = AsyncPirateGenerator(nil, lotwStory1_onPiratesFinished)

    generator:startBatch()

    local posCounter = 1
    local distance = 100
    local pirate_positions = generator:getStandardPositions(#waveTable, distance)
    for _, p in pairs(waveTable) do
        generator:createScaledPirateByName(p, pirate_positions[posCounter])
        posCounter = posCounter + 1
    end

    generator:endBatch()
end

function lotwStory1_onPiratesFinished(_Generated)
    local _MethodName = "Пираты сгенерированы (сервер)"
    local _WaveNumber = mission.data.custom.waveCounter
    mission.Log(_MethodName, "Начало. Номер волны: " .. tostring(_WaveNumber))

    if _WaveNumber == 1 then
        mission.data.custom.firstTimerAdvance = true
    end

    if _WaveNumber == 2 then
        mission.data.custom.secondTimerAdvance = true
    end

    if _WaveNumber == 3 then
        mission.data.custom.thirdTimerAdvance = true
    end

    SpawnUtility.addEnemyBuffs(_Generated)
end

function lotwStory1_pirateTaunt()
    local _MethodName = "Насмешка пиратов"
    mission.Log(_MethodName, "Начало...")

    local _Pirates = {Sector():getEntitiesByScriptValue("is_pirate")}

    if not mission.data.custom.firstWaveTaunt and #_Pirates > 0 then
        mission.Log(_MethodName, "Трансляция насмешки пиратов в сектор")
        mission.Log(_MethodName, "Объект: " .. tostring(_Pirates[1].id))

        local _Lines = {
            "... Кто ты? Как ты смеешь вмешиваться!",
            "Ну что ж, думаю, ты будешь первым, кого мы убьём.",
            "Ты далеко от дома, не так ли?",
            "... Кто ты, чёрт возьми?",
            "Кажется, мы нашли заблудшую овцу."
        }

        Sector():broadcastChatMessage(_Pirates[1], ChatMessageType.Chatter, getRandomEntry(_Lines))
        mission.data.custom.firstWaveTaunt = true
    end
end

function lotwStory1_spawnLiason()
    local _MethodName = "Спавн кораблей поддержки"
    mission.Log(_MethodName, "Начало...")
    local shipGenerator = AsyncShipGenerator(nil, lotwStory1_onFactionShipsFinished)
    local faction = Faction(mission.data.custom.friendlyFaction)

    if not faction or faction.isPlayer or faction.isAlliance then
        print("ОШИБКА: НЕ УДАЛОСЬ НАЙТИ ФРАКЦИЮ МИССИИ")
        terminate()
        return
    end

    shipGenerator:startBatch()

    shipGenerator:createDefender(faction, shipGenerator:getGenericPosition())
    shipGenerator:createDefender(faction, shipGenerator:getGenericPosition())

    shipGenerator:endBatch()

    local liasonGenerator = AsyncShipGenerator(nil, lotwStory1_onLiasonShipFinished)

    liasonGenerator:startBatch()

    liasonGenerator:createDefender(faction, liasonGenerator:getGenericPosition())

    liasonGenerator:endBatch()
end

function lotwStory1_onLiasonShipFinished(_Generated)
    for _, _Ship in pairs(_Generated) do
        local _Faction = Faction(_Ship.factionIndex)
        local _ShipAI = ShipAI(_Ship)

        MissionUT.deleteOnPlayersLeft(_Ship)
        _Ship:removeScript("patrol.lua")
        _Ship:removeScript("antismuggle.lua")
        _Ship:addScriptOnce("player/missions/lotw/mission1/lotwliasonm1.lua")
        _ShipAI:setIdle()

        _Ship.title = tostring(_Faction.name) .. " Военный посредник"
    end
end

function lotwStory1_onFactionShipsFinished(_Generated)
    for _, _Ship in pairs(_Generated) do
        _Ship:removeScript("antismuggle.lua")
        MissionUT.deleteOnPlayersLeft(_Ship)
    end
end

function lotwStory1_getNextLocation()
    local _MethodName = "Получение следующего сектора"

    mission.Log(_MethodName, "Поиск сектора.")
    local x, y = Sector():getCoordinates()
    local target = {}

    target.x, target.y = MissionUT.getSector(x, y, 2, 6, false, false, false, false, false)

    mission.Log(_MethodName, "Координата X следующего сектора: " .. tostring(target.x) .. ", координата Y следующего сектора: " .. tostring(target.y))
    if not target or not target.x or not target.y then
        mission.Log(_MethodName, "Не удалось найти подходящий сектор для миссии. Завершение скрипта.")
        terminate()
        return
    end

    return target
end

function lotwStory1_finishAndReward()
    local _MethodName = "Завершение и награждение"
    mission.Log(_MethodName, "Выполнение условия победы.")

    local _Player = Player()
    local _Faction = Faction(mission.data.custom.friendlyFaction)
    _Player:setValue("_lotw_story_stage", 2)
    _Player:setValue("_lotw_faction", _Faction.index)

    reward()
    accomplish()
end

--endregion

--region #CLIENT / SERVER CALLS

function lotwStory1_contactedLiason()
    local _MethodName = "Связь с посредником"

    if onClient() then
        mission.Log(_MethodName, "Вызов на клиенте")
        mission.Log(_MethodName, "Вызов на сервере.")

        invokeServerFunction("lotwStory1_contactedLiason")
    else
        mission.Log(_MethodName, "Вызов на сервере")

        lotwStory1_finishAndReward()
    end
end
callable(nil, "lotwStory1_contactedLiason")

--endregion

--region #MAKEBULLETIN CALL

function lotwStory1_formatDescription(_Station)
    local _Faction = Faction(_Station.factionIndex)
    local _Aggressive = _Faction:getTrait("aggressive")

    local _DescriptionType = 1 -- Нейтральный
    if _Aggressive > 0.5 then
        _DescriptionType = 2 -- Агрессивный.
    elseif _Aggressive <= -0.5 then
        _DescriptionType = 3 -- Мирный.
    end

    local _FinalDescription = ""
    if _DescriptionType == 1 then -- Нейтральный.
        _FinalDescription = "Мы ищем опытного капитана, чтобы разобраться с пиратскими рейдерами, собирающимися в соседнем секторе. По нашим данным, они готовятся атаковать близлежащую систему, и мы хотели бы этого избежать по очевидным причинам. Не волнуйтесь, вы будете щедро вознаграждены за ваши усилия."
    elseif _DescriptionType == 2 then -- Агрессивный.
        _FinalDescription = "Группа рейдеров думает, что они остались незамеченными. Они ошибаются. Мы нашли их жалкий флот и готовы стереть его с лица галактики. Однако, в великодушном жесте, мы решили сначала предложить эту возможность внешним капитанам. Вы будете вознаграждены за ваше время и за уничтоженные корабли. Сделайте из них пример."
    elseif _DescriptionType == 3 then -- Мирный.
        _FinalDescription = "Группа пиратских рейдеров собирается поблизости, чтобы начать атаку на одну из наших систем. Мы не сможем перебросить достаточно защитных сил к целевой системе вовремя, чтобы отразить атаку. Поэтому мы ищем внешнюю помощь, чтобы восполнить недостаток. Пожалуйста, ваши действия спасут множество жизней."
    end

    return _FinalDescription
end

mission.makeBulletin = function(_Station)
    local _MethodName = "Создание объявления"
    mission.Log(_MethodName, "Создание объявления.")
    local _Sector = Sector()
    local target = {}
    local x, y = _Sector:getCoordinates()
    local insideBarrier = MissionUT.checkSectorInsideBarrier(x, y)
    target.x, target.y = MissionUT.getSector(x, y, 4, 10, false, false, false, false, insideBarrier)

    if not target.x or not target.y then
        mission.Log(_MethodName, "target.x или target.y не установлены — возвращаем nil.")
        return
    end

    local _DangerLevel = 5

    local _Description = lotwStory1_formatDescription(_Station)

    reward = ESCCUtil.clampToNearest(125000 + (50000 * Balancing.GetSectorRewardFactor(_Sector:getCoordinates())), 5000, "Up")

    local bulletin =
    {
        brief = mission.data.brief,
        title = mission.data.title,
        icon = mission.data.icon,
        description = _Description,
        difficulty = "Лёгкий",
        reward = "¢${reward}",
        script = "missions/lotw/lotwstory1.lua",
        formatArguments = {x = target.x, y = target.y, reward = createMonetaryString(reward)},
        msg = "Пираты собираются в секторе \\s(%1%:%2%). Пожалуйста, уничтожьте их.",
        giverTitle = _Station.title,
        giverTitleArgs = _Station:getTitleArguments(),
        checkAccept = [[
            local self, player = ...
            if player:hasScript("missions/lotw/lotwstory1.lua") or (player:getValue("_lotw_story_stage") or 0) > 1 then
                player:sendChatMessage(Entity(self.arguments[1].giver), 1, "Вы не можете принять эту миссию снова.")
                return 0
            end
            return 1
        ]],
        onAccept = [[
            local self, player = ...
            player:sendChatMessage(Entity(self.arguments[1].giver), 0, self.msg, self.formatArguments.x, self.formatArguments.y)
        ]],
        arguments = {{
            giver = _Station.index,
            location = target,
            reward = {credits = reward, relations = 12000, paymentMessage = "Получено %1% кредитов за уничтожение пиратского флота."},
            initialDesc = _Description,
            dangerLevel = _DangerLevel
        }},
    }

    return bulletin
end

--endregion
