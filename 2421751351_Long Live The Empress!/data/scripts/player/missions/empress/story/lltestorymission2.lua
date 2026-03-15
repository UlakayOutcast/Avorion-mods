--[[
    Сюжетная миссия 2.
    Неумолимый клинок
    ДОПОЛНИТЕЛЬНЫЕ ТРЕБОВАНИЯ ДЛЯ ЭТОЙ МИССИИ:
        - Сюжетная миссия 1 выполнена
    ПРИМЕРНЫЙ ПЛАН:
        - Игрок читает письмо от Адрианы.
        - Игрок направляется в сектор Кавалеров. Краткий диалог, затем все корабли Кавалеров уходят в варп.
        - Игрок направляется в сектор пиратов.
        - В секторе пиратов есть военный аванпост, верфь, ремонтный док и исследовательская станция.
            - Удаляем груз со всех станций.
        - Игрок уничтожает все станции. Клинок Императрицы помогает ему вместе с постоянно появляющимися волнами кораблей Кавалеров.
        - Необходимо предотвратить уничтожение кораблей Кавалеров. Если будет уничтожено 10 кораблей Кавалеров, миссия провалится.
            - Это не так сложно, как кажется — корабли Кавалеров отступят через 4-8 секунд после снижения здоровья до 15%.
            - Вам просто нужно не допустить, чтобы они вступили в затяжной бой с Девастатором, Скорчером или Палачом.
            - Корабли Кавалеров не должны быть обузой — они должны быть необходимой поддержкой, за которой иногда нужно присматривать.
            - Помечайте те, у которых осталось 50% здоровья.
        - Роль игрока в основном заключается в уничтожении кораблей и поддержке Кавалеров, пока они уничтожают станции.
    УРОВЕНЬ ОПАСНОСТИ:
        5+ - Миссия начинается с уровня опасности 5. Это фиксированное значение, так как это неповторяемая* сюжетная миссия.
            - Начинаем с 6 защитников стандартной угрозы и 4 защитников высокой угрозы в секторе.
            - Появляются 3 защитника и 2 тяжёлых защитника.
            - Пираты появляются группами по 4 каждые 80 секунд.
            - Кавалеры появляются группами по 6 каждые 2:30.
            - Уровень опасности увеличивается каждые 3:30, до максимума 10.
            - Если Клинок Императрицы отступает, он возрождается через 2 минуты.

        * - Технически. Игрок всегда может покинуть миссию и начать заново.
]]
package.path = package.path .. ";data/scripts/lib/?.lua"
package.path = package.path .. ";data/scripts/?.lua"

-- Запуск остальных подключений.
include("callable")
include("randomext")
include("structuredmission")
include("stringutility")

ESCCUtil = include("esccutil")
LLTEUtil = include("llteutil")

local SectorGenerator = include("SectorGenerator")
local PirateGenerator = include("pirategenerator")
local AsyncPirateGenerator = include("asyncpirategenerator")
local AsyncShipGenerator = include("asyncshipgenerator")
local Balancing = include("galaxy")
local SpawnUtility = include("spawnutility")

mission._Debug = 0
mission._Name = "Неумолимый клинок"

-- Инициализация
local llte_storymission_init = initialize
function initialize()
    local methodName = "Инициализация"
    mission.Log(methodName, "Начало миссии 'Неумолимый клинок'...")

    if onServer() then
        if not _restoring then
            -- Стандартные данные миссии.
            mission.data.brief = mission._Name
            mission.data.title = mission._Name
            mission.data.autoTrackMission = true
            mission.data.icon = "data/textures/icons/cavaliers.png"
            mission.data.priority = 9
            mission.data.description = {
                "Планируемая атака на пиратскую крепость близка. Кавалеры связались с вами и попросили принять участие в штурме.",
                { text = "Прочитайте письмо от Адрианы", bulletPoint = true, fulfilled = false },
                -- Если в каком-либо из этих пунктов есть координаты X/Y, они будут обновлены с правильным местоположением при начале соответствующей фазы.
                { text = "Встретьтесь с разведчиками Кавалеров в секторе (${_X}:${_Y})", bulletPoint = true, fulfilled = false, visible = false },
                { text = "Уничтожьте пиратскую базу в секторе (${_X}:${_Y})", bulletPoint = true, fulfilled = false, visible = false },
                { text = "Предотвратите уничтожение кораблей Кавалеров - ${_LOST}/${_MAXLOST} потеряно", bulletPoint = true, fulfilled = false, visible = false }
            }

            -- Пользовательские данные миссии:
            -- .dangerLevel
            -- .destroyedCavaliers
            -- .maxDestroyedCavaliers
            -- .sendExtraCavaliers
            -- .pirateLevel
            -- .scoutSector
            -- .pirateSector
            -- .militaryStationid
            -- .builtMainSector
            -- .firstStationDestroyed
            -- .empressBladeRespawning
            -- .missionStarted
            -- .firstEmpressSpawnDone
            -- ._HETActive
            mission.data.custom.dangerLevel = 5 -- Это сюжетная миссия, поэтому мы держим всё предсказуемым.
            mission.data.custom.destroyedCavaliers = 0
            mission.data.custom.maxDestroyedCavaliers = 8
            mission.data.custom.sendExtraCavaliers = false
            mission.data.custom._HETActive = false

            local _ActiveMods = Mods()
            for _, _Xmod in pairs(_ActiveMods) do
                if _Xmod.id == "1821043731" then -- HET
                    mission.data.custom._HETActive = true
                    mission.data.custom.maxDestroyedCavaliers = mission.data.custom.maxDestroyedCavaliers + 6
                    break
                end
            end

            mission.Log(methodName, "Максимальное количество уничтоженных кораблей Кавалеров: " .. tostring(mission.data.custom.maxDestroyedCavaliers))

            local missionReward = 600000

            missionData_in = {location = nil, reward = {credits = missionReward}}

            llte_storymission_init(missionData_in)
        else
            -- Восстановление
            llte_storymission_init()
            if mission.currentPhase == mission.phases[3] then
                registermarkShips() -- Повторная регистрация обратного вызова клиента.
            end
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

-- Вызов фаз миссии
mission.globalPhase.onAbandon = function()
    local _X, _Y = Sector():getCoordinates()
    Player():unregisterCallback("onPreRenderHud", "onMarkShips")
    if mission.data.location then
        runFullSectorCleanup_llte()
    end
end

mission.globalPhase.updateServer = function(_TimeStep)
    if mission.data.custom.destroyedCavaliers >= mission.data.custom.maxDestroyedCavaliers then
        Player():setValue("_llte_failedstory2", true)
        fail()
    end
end

mission.globalPhase.onFail = function()
    -- Если есть корабли Кавалеров, они уходят в варп.
    local methodName = "При провале"
    mission.Log(methodName, "Начало...")

    local _Rgen = ESCCUtil.getRand()
    LLTEUtil.allCavaliersDepart()
    -- Добавление скрипта в местоположение миссии для уничтожения, если мы там, или удалённое уничтожение в противном случае.
    runFullSectorCleanup_llte()
    -- Отправка письма о провале.
    local _Player = Player()
    local _Rank = _Player:getValue("_llte_cavaliers_rank")
    _Player:unregisterCallback("onPreRenderHud", "onMarkShips")
    local _Mail = Mail()
    local _PirateFaction = Galaxy():getPirateFaction(mission.data.custom.pirateLevel)
    _Mail.text = Format("%1% %2%,\n\n%3% были слишком сильны, и нам пришлось отступить из-за потерь, которые мы понесли. Вооружитесь более мощным оружием и щитами, и я приступлю к реорганизации флота для нового штурма.\nМы покажем фракциям, что возможно принести мир в галактику, не жертвуя тысячами жизней!\n\nИмператрица Адриана Сталь", _Rank, _Player.name, _PirateFaction.name)
    _Mail.header = "Вынуждены отступить"
    _Mail.sender = "Императрица Адриана Сталь @Кавалеры"
    _Mail.id = "_llte_story2_mailfail"
    _Player:addMail(_Mail)
end

mission.globalPhase.onAccomplish = function()
    -- Отправка письма об успехе, предупреждающего игрока о разведчиках и будущих возможностях помочь.
    local _Player = Player()
    local _Rank = _Player:getValue("_llte_cavaliers_rank")
    _Player:setValue("_llte_pirate_faction_vengeance", mission.data.custom.pirateLevel)
    _Player:unregisterCallback("onPreRenderHud", "onMarkShips")
    local _Mail = Mail()
    local _PirateFaction = Galaxy():getPirateFaction(mission.data.custom.pirateLevel)
    _Mail.text = Format("%1% %2%,\n\nСегодня мы совершили нечто великое. %3% — невероятно мощная группа — были разбиты нашей мощью. С этим мы смогли послать сообщение другим пиратам: неважно, насколько вы сильны, мы УНИЧТОЖИМ вас, чтобы принести мир в галактику.\nСпасибо! Без вашей помощи это было бы невозможно. Мы снова в долгу перед вами.\n\nВ ближайшие дни мы будем работать над укреплением нашей базы операций и уничтожением других пиратских и ксотанских заражений. Ищите наших разведчиков — они иногда будут подходить к вам и предлагать работу.\nКонечно, в этом будет и ваша выгода. Мы с нетерпением ждём возможности снова сражаться рядом с вами, %1%!\n\nИмператрица Адриана Сталь", _Rank, _Player.name, _PirateFaction.name)
    _Mail.header = "Пираты уничтожены!"
    _Mail.sender = "Императрица Адриана Сталь @Кавалеры"
    _Mail.id = "_llte_story2_mailwin"
    _Player:addMail(_Mail)

    local _Mail2 = Mail()
    _Mail2.text = "Мы это запомним."
    _Mail2.header = "Уведомление"
    _Mail2.sender = _PirateFaction.name
    _Mail2.id = "_llte_story2_threat"
    _Player:addMail(_Mail2)
end

mission.phases[1] = {}
mission.phases[1].showUpdateOnEnd = true
mission.phases[1].noBossEncountersTargetSector = true
mission.phases[1].onBeginServer = function()
    local methodName = "Фаза 1: начало на сервере"
    mission.Log(methodName, "Начало...")
    mission.data.custom.scoutSector = llteStory2_getNextLocation(true)
    local _X, _Y = mission.data.custom.scoutSector.x, mission.data.custom.scoutSector.y
    mission.data.custom.pirateLevel = Balancing_GetPirateLevel(_X, _Y)
    local _Player = Player()
    local _Rank = _Player:getValue("_llte_cavaliers_rank")
    local _Mail = Mail()
    _Mail.text = Format("%1% %2%,\n\nЯ говорила, что свяжусь с вами, когда будем готовы начать атаку на пиратов. Вот и всё. Пришло время.\nНаши разведчики ждут вас в (%3%:%4%) — мы встретимся с вами там и проинструктируем по плану атаки.\n\nИмператрица Адриана Сталь", _Rank, _Player.name, _X, _Y)
    _Mail.header = "План атаки"
    _Mail.sender = "Императрица Адриана Сталь @Кавалеры"
    _Mail.id = "_llte_story2_mail1"
    _Player:addMail(_Mail)
end

mission.phases[1].playerCallbacks = {
    {
        name = "onMailRead",
        func = function(_PlayerIndex, _MailIndex)
            if onServer() then
                local _Player = Player()
                local _Mail = _Player:getMail(_MailIndex)
                if _Mail.id == "_llte_story2_mail1" then
                    nextPhase()
                end
            end
        end
    }
}

mission.phases[2] = {}
mission.phases[2].timers = {}
mission.phases[2].showUpdateOnEnd = true
mission.phases[2].noBossEncountersTargetSector = true
mission.phases[2].onBeginServer = function()
    local methodName = "Фаза 2: начало на сервере"
    mission.data.location = mission.data.custom.scoutSector
    mission.data.description[2].fulfilled = true
    mission.data.description[3].arguments = { _X = mission.data.location.x, _Y = mission.data.location.y }
    mission.data.description[3].visible = true
end

mission.phases[2].onTargetLocationEntered = function(_X, _Y)
    local methodName = "Фаза 2: вход в целевой сектор"
    -- Получаем следующее местоположение
    mission.data.custom.pirateSector = llteStory2_getNextLocation(false)
    -- Спавн 3 разведчиков
    llteStory2_spawnCavalierScouts(3)
end

mission.phases[2].onTargetLocationArrivalConfirmed = function(_X, _Y)
    local methodName = "Фаза 2: прибытие в целевой сектор подтверждено"
    -- Запуск таймера на 5 секунд для прыжка флота Кавалеров.
    mission.Log(methodName, "Начало...")
    mission.phases[2].timers[1] = { time = 5, callback = function()
        llteStory2_spawnEmpressBlade(true, true)
        llteStory2_spawnCavalierShips(2, 2, false)
    end, repeating = false}
    mission.phases[2].timers[2] = { time = 7, callback = function()
        llteStory2_spawnCavalierShips(2, 1, false)
    end, repeating = false}
    mission.phases[2].timers[3] = { time = 9, callback = function()
        llteStory2_spawnCavalierShips(2, 1, false)
    end, repeating = false}
    mission.phases[2].timers[4] = { time = 11, callback = function()
        llteStory2_spawnCavalierShips(2, 0, false)
    end, repeating = false}
    mission.phases[2].timers[5] = { time = 13, callback = function()
        llteStory2_spawnCavalierShips(1, 1, false)
    end, repeating = false}
end

mission.phases[3] = {}
mission.phases[3].timers = {}
mission.phases[3].showUpdateOnEnd = true
mission.phases[3].noBossEncountersTargetSector = true
mission.phases[3].onBeginServer = function()
    local methodName = "Фаза 3: начало на сервере"
    mission.data.location = mission.data.custom.pirateSector
    mission.data.description[3].fulfilled = true
    mission.data.description[4].arguments = { _X = mission.data.location.x, _Y = mission.data.location.y }
    mission.data.description[4].visible = true
    mission.data.description[5].arguments = { _LOST = 0, _MAXLOST = mission.data.custom.maxDestroyedCavaliers }
    mission.data.description[5].visible = true
end

mission.phases[3].onTargetLocationEntered = function(_X, _Y)
    local methodName = "Фаза 3: вход в целевой сектор"
    -- Построение основного сектора
    llteStory2_buildPirateSector(_X, _Y)
    registerMarkShips()
    mission.phases[3].timers[5] = nil
end

mission.phases[3].onTargetLocationArrivalConfirmed = function(_X, _Y)
    local methodName = "Фаза 3: прибытие в целевой сектор подтверждено"
    -- Спавн Кавалеров — они всегда исчезают при выходе, поэтому нам нужно их пересоздавать каждый раз.
    -- Добавление контроллера защиты для Кавалеров.
    mission.Log(methodName, "Начало...")
    if not mission.data.custom.missionStarted then
        mission.phases[3].timers[1] = { time = 2, callback = function()
            local methodName = "Фаза 3: обратный вызов таймера 1"
            mission.Log(methodName, "Начало...")
            llteStory2_spawnEmpressBlade(false, false)
            llteStory2_spawnCavalierShips(3, 1, true)
            Entity(mission.data.custom.militaryStationid):addScript("player/missions/empress/story/story2/lltestory2piratesector.lua")

            local _Faction = Galaxy():findFaction("Кавалеры")
            local _EmpressBlade = {Sector():getEntitiesByScriptValue("_llte_empressblade")}

            llteStory2_addCavaliersDefenseController(_Faction, _EmpressBlade[1])
            mission.data.custom.firstEmpressSpawnDone = true
        end, repeating = false}
        mission.data.custom.missionStarted = true
    end
end

mission.phases[3].updateTargetLocationServer = function(_TimeStep)
    local methodName = "Фаза 3: обновление сервера"
    -- Нужно проверить, уничтожены ли все 4 станции.
    if mission.data.custom.builtMainSector then
        local _EmpressBladeCt = ESCCUtil.countEntitiesByValue("_llte_empressblade")
        -- Если Клинок Императрицы был вынужден отступить из-за низкого здоровья (очень маловероятно, что он был уничтожен)
        -- Он возвращается в течение 2 минут.
        if _EmpressBladeCt == 0 and mission.data.custom.firstEmpressSpawnDone and not mission.data.custom.empressBladeRespawning then
            mission.Log("Количество Клинков Императрицы: " .. tostring(_EmpressBladeCt) .. " - значение возрождения Клинка Императрицы: " .. tostring(mission.data.custom.empressBladeRespawning))
            mission.phases[3].timers[2] = {
                time = 120,
                callback = function()
                    local methodName = "Фаза 3: обратный вызов таймера 2"
                    mission.Log(methodName, "Начало...")
                    -- Он возвращается через 2 минуты.
                    llteStory2_spawnEmpressBlade(false, false)
                    local _Faction = Galaxy():findFaction("Кавалеры")
                    local _EmpressBlade = {Sector():getEntitiesByScriptValue("_llte_empressblade")}

                    llteStory2_addCavaliersDefenseController(_Faction, _EmpressBlade[1])
                    mission.data.custom.empressBladeRespawning = false
                end,
                repeating = false}
            mission.data.custom.empressBladeRespawning = true
        end

        local _Stations = ESCCUtil.countEntitiesByValue("_llte_story2_mainobjective")
        if _Stations == 0 then
            ESCCUtil.allPiratesDepart()
            LLTEUtil.allCavaliersDepart()
            llteStory2_finishAndReward()
        end
    end
end

mission.phases[3].onEntityDestroyed = function(_ID, _LastDamageInflictor)
    local methodName = "Фаза 3: объект уничтожен"
    if Entity(_ID):getValue("is_cavaliers") then
        mission.data.custom.destroyedCavaliers = mission.data.custom.destroyedCavaliers + 1
        mission.data.description[5].arguments = { _LOST = mission.data.custom.destroyedCavaliers, _MAXLOST = mission.data.custom.maxDestroyedCavaliers }
        sync()
    end
    if Entity(_ID):getValue("_llte_story2_mainobjective") then
        local _ExtraReinforcements = 1
        mission.Log(methodName, "Добавление дополнительного допуска потерь.")

        if mission.data.custom.sendExtraCavaliers then
            _ExtraReinforcements = 3
            if mission.data.custom._HETActive then
                _ExtraReinforcements = 4
            end
        end

        mission.data.custom.maxDestroyedCavaliers = mission.data.custom.maxDestroyedCavaliers + _ExtraReinforcements
        mission.data.description[5].arguments = { _LOST = mission.data.custom.destroyedCavaliers, _MAXLOST = mission.data.custom.maxDestroyedCavaliers }
        sync()

        -- Спавн группы кораблей — не нужно усиление для этих ребят.
        local _MiniWaveGenerator = AsyncPirateGenerator(nil, nil)
        _MiniWaveGenerator.pirateLevel = mission.data.custom.pirateLevel

        _MiniWaveGenerator:startBatch()

        local _MiniWaveTable = ESCCUtil.getStandardWave(mission.data.custom.dangerLevel, 3, "Standard")
        local _MiniWavePositions = _MiniWaveGenerator:getStandardPositions(#_MiniWaveTable, 200)

        local _PosCounter = 1
        for _, _P in pairs(_MiniWaveTable) do
            _MiniWaveGenerator:createScaledPirateByName(_P, _MiniWavePositions[_PosCounter])
            _PosCounter = _PosCounter + 1
        end

        _MiniWaveGenerator:endBatch()

        if not mission.data.custom.firstStationDestroyed then
            -- Трансляция, затем установка таймера, затем установка "firstStationDestroyed = true"
            local _Stations = {Sector():getEntitiesByType(EntityType.Station)}
            local _Rgen = ESCCUtil.getRand()
            local _BroadcastStation = _Stations[_Rgen:getInt(1, #_Stations)]
            Sector():broadcastChatMessage(_BroadcastStation, ChatMessageType.Chatter, "Вы думали, мы просто ляжем и умрём для вас? Это место станет вашей могилой!")

            mission.phases[3].timers[2] = {time = 10, callback = function()
                local _Generator = AsyncPirateGenerator(nil, llteStory2_onExecutionersFinished)
                _Generator.pirateLevel = mission.data.custom.pirateLevel

                _Generator:startBatch()

                -- Да, если вы думали, что я просто использую этих ребят для декапов, вы ошибались.
                _Generator:createScaledExecutioner(_Generator:getGenericPosition(), 1000)

                _Generator:createScaledExecutioner(_Generator:getGenericPosition(), 1000)

                _Generator:endBatch()

            end, repeating = false}

            mission.data.custom.firstStationDestroyed = true
        end
    end
end

mission.phases[3].onTargetLocationLeft = function(_X, _Y)
    local methodName = "Фаза 3: покидание целевого сектора"
    -- Запуск таймера мягкого провала.
    -- Таймер 1 для первого прыжка Кавалеров.
    -- Таймер 2 происходит после уничтожения первой станции.
    -- Таймер 3 — таймер возрождения Клинка Императрицы.
    -- Таймер 4 — увеличение уровня опасности каждые 3 минуты.
    -- Таймер 5 — таймер мягкого провала.
    mission.phases[3].timers[5] = {time = 60, callback = function()
        mission.data.custom.destroyedCavaliers = mission.data.custom.destroyedCavaliers + 1
        mission.data.description[5].arguments = { _LOST = mission.data.custom.destroyedCavaliers, _MAXLOST = mission.data.custom.maxDestroyedCavaliers }
        sync()
    end, repeating = true}
end

-- Вызов серверных функций
function llteStory2_buildPirateSector(_X, _Y)
    local methodName = "Построение основного сектора"

    if not mission.data.custom.builtMainSector then
        mission.Log(methodName, "Основной сектор ещё не построен — строим его сейчас.")
        local _Generator = SectorGenerator(_X, _Y)
        local _Rgen = ESCCUtil.getRand()
        -- Добавление: военного аванпоста, исследовательской станции, верфи и ремонтного дока.
        local _Faction = Galaxy():getPirateFaction(mission.data.custom.pirateLevel)
        mission.Log(methodName, "Построение сектора для фракции пиратов: " .. tostring(_Faction.name) .. " уровень " .. tostring(mission.data.custom.pirateLevel) .. " пиратов")
        local _MilitaryOutpost = _Generator:createMilitaryBase(_Faction)
        mission.data.custom.militaryStationid = _MilitaryOutpost.index
        _MilitaryOutpost:setValue("_llte_story2_militaryoutpost", true)
        local _Shipyard = _Generator:createShipyard(_Faction)
        local _RepairDock = _Generator:createRepairDock(_Faction)
        local _ResearchOutpost = _Generator:createResearchStation(_Faction)
        local _Stations = { _MilitaryOutpost, _Shipyard, _RepairDock, _ResearchOutpost }
        for _, _Station in pairs(_Stations) do
            _Station:removeScript("consumer.lua")
            _Station:removeScript("backup.lua") -- Задержка обратного вызова здесь глупая. Мне нравится идея, что корабли реагируют при уничтожении объекта.
            _Station:setValue("is_pirate", true)
            _Station:setValue("no_chatter", true) -- Наконец-то способ избавиться от этих глупых сообщений, которые полностью портят атмосферу.
            _Station:setValue("_llte_story2_mainobjective", true)
            local _StationBay = CargoBay(_Station)
            _StationBay:clear()
            Boarding(_Station).boardable = false
        end
        Sector():removeScript("traders.lua")
        -- Добавление: 1 большого астероидного поля и 3 небольших астероидных поля.
        for _ = 1, 3 do
            _Generator:createSmallAsteroidField()
        end
        _Generator:createAsteroidField()
        -- Добавление: 6 защитников средней угрозы и 4 защитника высокой угрозы
        local _LowPirateTable = ESCCUtil.getStandardWave(mission.data.custom.dangerLevel, 6, "Standard")
        local _PirateTable = ESCCUtil.getStandardWave(mission.data.custom.dangerLevel, 4, "High")
        local _CreatedPirateTable = {}

        PirateGenerator.pirateLevel = mission.data.custom.pirateLevel
        for _, _Pirate in pairs(_LowPirateTable) do
            table.insert(_CreatedPirateTable, PirateGenerator.createPirateByName(_Pirate, PirateGenerator.getGenericPosition()))
        end
        for _, _Pirate in pairs(_PirateTable) do
            table.insert(_CreatedPirateTable, PirateGenerator.createPirateByName(_Pirate, PirateGenerator.getGenericPosition()))
        end
        -- Установка агрессивного поведения после диалога между Адрианой и военным аванпостом.
        for _, _Pirate in pairs(_CreatedPirateTable) do
            ShipAI(_Pirate.index):setPassive()
        end

        SpawnUtility.addEnemyBuffs(_CreatedPirateTable)
        -- Добавление: скрипта контроллера защиты.
        local _DCD = {}
        _DCD._DefenseLeader = mission.data.custom.militaryStationid
        _DCD._DefenderCycleTime = 80
        _DCD._DangerLevel = mission.data.custom.dangerLevel
        _DCD._MaxDefenders = 8
        _DCD._MaxDefendersSpawn = 4
        _DCD._DefenderDistance = 5000 -- Рассеиваем этих ребят немного больше, чем обычно.
        _DCD._DefenderHPThreshold = 0.5
        _DCD._DefenderOmicronThreshold = 0.5
        _DCD._ForceWaveAtThreshold = 0.8
        _DCD._ForcedDefenderDamageScale = 5
        _DCD._IsPirate = true
        _DCD._Factionid = _MilitaryOutpost.factionIndex
        _DCD._PirateLevel = mission.data.custom.pirateLevel
        _DCD._UseLeaderSupply = false
        _DCD._LowTable = "High"
        _DCD._ForceDebug = false

        Sector():addScript("sector/background/defensecontroller.lua", _DCD)

        mission.data.custom.builtMainSector = true
    end
end

function llteStory2_spawnEmpressBlade(_AddScript, deleteOnLeft)
    local methodName = "Спавн Клинка Императрицы"
    mission.Log(methodName, "Начало...")
    local _EmpressBlade = LLTEUtil.spawnBladeOfEmpress()

    if _AddScript then
        invokeClientFunction(Player(), "onPhase2SectorEnteredDialog", _EmpressBlade.id, mission.data.custom.pirateSector.x, mission.data.custom.pirateSector.y)
    end
    if deleteOnLeft then
        MissionUT.deleteOnPlayersLeft(_EmpressBlade)
    end
end

function llteStory2_spawnCavalierScouts(_Scouts)
    local _Faction = Galaxy():findFaction("Кавалеры")
    local _Generator = AsyncShipGenerator(nil, llteStory2_onCavalierScoutsFinished)
    _Generator:startBatch()

    for _ = 1, _Scouts do
        _Generator:createScout(_Faction, PirateGenerator.getGenericPosition())
    end

    _Generator:endBatch()
end

function llteStory2_spawnCavalierShips(_Defenders, _HeavyDefenders, _StartPassive)
    _StartPassive = _StartPassive or false
    local _Faction = Galaxy():findFaction("Кавалеры")
    local _Generator = AsyncShipGenerator(nil, llteStory2_onCavaliersFinished, _StartPassive)
    _Generator:startBatch()

    for _ = 1, _Defenders do
        _Generator:createDefender(_Faction, PirateGenerator.getGenericPosition())
    end
    for _ = 1, _HeavyDefenders do
        _Generator:createHeavyDefender(_Faction, PirateGenerator.getGenericPosition())
    end

    _Generator:endBatch()
end

function runFullSectorCleanup_llte()
    local _X, _Y = Sector():getCoordinates()
    if _X == mission.data.location.x and _Y == mission.data.location.y then
        local _EntityTypes = ESCCUtil.allEntityTypes()
        Sector():addScript("sector/deleteentitiesonplayersleft.lua", _EntityTypes)
    else
        local _MX, _MY = mission.data.location.x, mission.data.location.y
        Galaxy():loadSector(_MX, _MY)
        invokeSectorFunction(_MX, _MY, true, "lltesectormonitor.lua", "clearMissionAssets", _MX, _MY, true, true)
    end
end

function llteStory2_addCavaliersDefenseController(_CavFaction, _EmpressBlade)
    local methodName = "Добавление контроллера защиты Кавалеров"
    local _CavFactor = 0
    local _CavTimeFactor = 0
    local _CavEvacFactor = 0
    local _CavExtraWaveShips = 0

    if mission.data.custom._HETActive then
        _CavFactor = _CavFactor + 3
        _CavExtraWaveShips = _CavExtraWaveShips + 1
        _CavEvacFactor = _CavEvacFactor + 0.1
        _CavTimeFactor = _CavTimeFactor + 20
    end

    mission.Log(methodName, "Значение отправки дополнительных кораблей Кавалеров: " .. tostring(mission.data.custom.sendExtraCavaliers))
    if mission.data.custom.sendExtraCavaliers then
        _CavFactor = _CavFactor + 3
        _CavTimeFactor = _CavTimeFactor + 20
        _CavEvacFactor = _CavEvacFactor + 0.15
        _CavExtraWaveShips = _CavExtraWaveShips + 2
        if mission.data.custom._HETActive then
            _CavEvacFactor = _CavEvacFactor + 0.1
            _CavTimeFactor = _CavTimeFactor + 20
            _CavExtraWaveShips = _CavExtraWaveShips + 2
        end
    end

    local _CavDangerLevel = math.min(10, mission.data.custom.dangerLevel + _CavFactor) -- Максимум 10
    local _CavCycleTime = 120 - _CavTimeFactor
    local _CavWithdrawHealth = 0.30 + _CavEvacFactor
    local _CavMaxDefenders = 6 + _CavExtraWaveShips
    local _CavMaxSpawn = 5 + _CavExtraWaveShips

    mission.Log(methodName, "Контроллер защиты Кавалеров отправляет " .. tostring(_CavMaxSpawn) .. " защитников на уровне опасности " .. tostring(_CavDangerLevel) .. " каждые " .. tostring(_CavCycleTime) .. " секунд до максимума " .. tostring(_CavMaxDefenders) .. " - отступление при " .. tostring(_CavWithdrawHealth))

    local _CavDCD = {}
    _CavDCD._DefenseLeader = _EmpressBlade.index
    _CavDCD._CanTransfer = false
    _CavDCD._DefenderCycleTime = _CavCycleTime
    _CavDCD._DangerLevel = _CavDangerLevel
    _CavDCD._UseFixedDanger = true
    _CavDCD._MaxDefenders = _CavMaxDefenders
    _CavDCD._MaxDefendersSpawn = _CavMaxSpawn
    _CavDCD._AutoWithdrawDefenders = true
    _CavDCD._DefenderHPThreshold = _CavWithdrawHealth
    _CavDCD._DefenderOmicronThreshold = 0.5
    _CavDCD._PrependToDefenderTitle = "Кавалеры"
    _CavDCD._ForceWaveAtThreshold = -1
    _CavDCD._IsPirate = false
    _CavDCD._Factionid = _CavFaction.index
    _CavDCD._PirateLevel = -1
    _CavDCD._SupplyFactor = 0
    _CavDCD._UseLeaderSupply = false
    _CavDCD._ForceDebug = false

    _CavDCD._LowTable = "High"
    _CavDCD._KillWhenNoPlayers = true

    Sector():addScript("sector/background/defensecontroller.lua", _CavDCD)
end

function llteStory2_onCavalierScoutsFinished(_Generated)
    local methodName = "Разведчики Кавалеров созданы"
    for _, _S in pairs(_Generated) do
        _S.title = "Кавалеры: " .. _S.title
        _S:setValue("is_cavaliers", true)
        _S:addScript("ai/patrolpeacefully.lua")
        MissionUT.deleteOnPlayersLeft(_S)
    end
end

function llteStory2_onCavaliersFinished(_Generated, _StartPassive)
    local methodName = "Кавалеры созданы"
    for _, _S in pairs(_Generated) do
        _S.title = "Кавалеры: " .. _S.title
        _S:setValue("npc_chatter", nil)
        _S:setValue("is_cavaliers", true)

        local _WithdrawData = {
            _Threshold = 0.3
        }

        _S:addScript("ai/withdrawatlowhealth.lua", _WithdrawData)
        _S:removeScript("antismuggle.lua")
        LLTEUtil.rebuildShipWeapons(_S, Player():getValue("_llte_cavaliers_strength"))
        -- Иногда вы получаете плохой сид и получаете очень хрупких Кавалеров. Это должно помочь противодействовать этому.
        local _HPFactor = 2.5
        local _DamageFactor = 2
        if mission.data.custom.sendExtraCavaliers then
            _HPFactor = 4
            _DamageFactor = 4
        end
        local _Dura = Durability(_S)
        if _Dura then
            _Dura.maxDurabilityFactor = (_Dura.maxDurabilityFactor or 1) * _HPFactor
        end
        _S.damageMultiplier = (_S.damageMultiplier or 1) * _DamageFactor

        MissionUT.deleteOnPlayersLeft(_S)
        if _StartPassive then
            _S:removeScript("patrol.lua")
            local _AI = ShipAI(_S.index)
            _AI:stop()
            _AI:setIdle()
        end
    end
end

function llteStory2_onExecutionersFinished(_Generated)
    for _, _S in pairs(_Generated) do
        _S:removeScript("blocker.lua")
        _S:removeScript("megablocker.lua")
    end

    local _Rgen = ESCCUtil.getRand()

    -- Немного разнообразия на случай покидания/повторного выполнения.
    local _ExecutionerLines = {
        "Цели подтверждены. Начинаем боевые действия.",
        "Кавалеры обнаружены. Ликвидация.",
        "Это конец дороги для вас.",
        "Пришло время отрубить голову зверю."
    }

    Sector():broadcastChatMessage(_Generated[_Rgen:getInt(1, #_Generated)], ChatMessageType.Chatter, getRandomEntry(_ExecutionerLines))
end

function llteStory2_getNextLocation(_FirstLocation)
    local methodName = "Получение следующего местоположения"

    mission.Log(methodName, "Получение местоположения.")
    local x, y = Sector():getCoordinates()
    local target = {}

    if _FirstLocation then
        -- Получаем сектор, который находится очень близко к внешнему краю барьера.
        local _Nx, _Ny = ESCCUtil.getPosOnRing(x, y, Balancing.BlockRingMax + 2)
        target.x, target.y = MissionUT.getSector(_Nx, _Ny, 3, 6, false, false, false, false, false)
    else
        target.x, target.y = MissionUT.getSector(x, y, 5, 10, false, false, false, false, false)
    end

    if not target or not target.x or not target.y then
        mission.Log(methodName, "Не удалось найти подходящий сектор для миссии. Завершение скрипта.")
        terminate()
        return
    end

    return target
end

function llteStory2_finishAndReward()
    local methodName = "Завершение и награждение"
    mission.Log(methodName, "Выполнение условия победы.")

    local _Player = Player()
    local _Rank = _Player:getValue("_llte_cavaliers_rank")
    local _Rgen = ESCCUtil.getRand()
    _Player:setValue("_llte_story_2_accomplished", true)

    local _WinMsgTable = {
        "Отличная работа, " .. _Rank .. "!"
    }

    -- Увеличение репутации на 3
    _Player:setValue("_llte_cavaliers_rep", _Player:getValue("_llte_cavaliers_rep") + 3)
    _Player:sendChatMessage("Адриана Сталь", 0, _WinMsgTable[_Rgen:getInt(1, #_WinMsgTable)] .. " Вот ваше вознаграждение, как и обещали.")
    reward()
    accomplish()
end

-- Вызов клиентских функций
function onMarkShips()
    local methodName = "Пометка кораблей"

    local player = Player()
    if not player then return end
    if player.state == PlayerStateType.BuildCraft or player.state == PlayerStateType.BuildTurret then return end

    local renderer = UIRenderer()

    local _Ships = {Sector():getEntitiesByScriptValue("is_cavaliers")}
    for _, _S in pairs(_Ships) do
        local _HPRatio = _S.durability / _S.maxDurability
        -- Жёлтая пометка при 80%
        local _MarkColor = ESCCUtil.getSaneColor(255, 255, 0)

        if _HPRatio <= 0.8 then
            if _HPRatio <= 0.6 then
                -- Оранжевая при 60%
                _MarkColor = ESCCUtil.getSaneColor(255, 127, 0)
            end
            if _HPRatio <= 0.4 then
                -- Красная при 40%
                _MarkColor = ESCCUtil.getSaneColor(255, 0, 0)
            end

            local _, size = renderer:calculateEntityTargeter(_S)

            renderer:renderEntityTargeter(_S, _MarkColor, size * 1.25)
            renderer:renderEntityArrow(_S, 30, 10, 100, _MarkColor)
            renderer:renderEntityArrow(_S, 30, 10, 100, _MarkColor, 0.13)
            renderer:renderEntityArrow(_S, 30, 30, 100, _MarkColor, 0.13)
        end
    end

    renderer:display()
end

function onPhase2SectorEnteredDialog(_ID, _X, _Y)
    -- Нельзя сделать это с помощью скрипта Boxel's Single NPC interaction, потому что этот скрипт не синхронизирует значения правильно, поэтому мы просто делаем это здесь.
    local methodName = "Диалог при входе в сектор фазы 2"
    mission.Log(methodName, "Начало...")

    local d0 = {}
    local d1 = {}
    local d2 = {}
    local d3 = {}
    local d4 = {}
    local d5 = {}
    local d6 = {}

    local _Player = Player()
    local _PlayerRank = _Player:getValue("_llte_cavaliers_rank")
    local _PlayerName = _Player.name
    local _PlayerFailedStory2 = _Player:getValue("_llte_failedstory2")
    mission.Log(methodName, "Значение провала игрока в миссии 2: " .. tostring(_PlayerFailedStory2))

    local _Talker = "Адриана Сталь"
    local _TalkerColor = MissionUT.getDialogTalkerColor1()
    local _TextColor = MissionUT.getDialogTextColor1()

    -- d0
    d0.text = "Привет, " .. _PlayerRank .. "! Я так рада, что вы решили присоединиться к нам."
    d0.talker = _Talker
    d0.textColor = _TextColor
    d0.talkerColor = _TalkerColor
    d0.followUp = d4
    -- d4
    d4.text = "Наш план очень прост. Мы будем ждать, пока вы перепрыгнете в сектор, а затем последуем за вами, чтобы присоединиться к атаке. Я приказала нашим капитанам пытаться отступить, если их корабли повреждены."
    d4.talker = _Talker
    d4.textColor = _TextColor
    d4.talkerColor = _TalkerColor
    d4.followUp = d5
    -- d5
    d5.text = "Мы будем продолжать циклично отправлять волны атакующих, пока пираты не будут уничтожены! Я хочу, чтобы все вернулись домой живыми."
    d5.talker = _Talker
    d5.textColor = _TextColor
    d5.talkerColor = _TalkerColor
    d5.followUp = d1
    -- d1
    d1.text = "Мы можем выдвинуться в любой момент. Вы готовы?"
    d1.talker = _Talker
    d1.textColor = _TextColor
    d1.talkerColor = _TalkerColor
    d1.answers = {}
    table.insert(d1.answers, { answer = "Я готов.", followUp = d2 })
    if _PlayerFailedStory2 then
        mission.Log(methodName, "Добавление дополнительного варианта диалога.")
        table.insert(d1.answers, { answer = "Я готов... но не могли бы вы отправить дополнительные подкрепления на этот раз?", followUp = d6 })
    end
    table.insert(d1.answers, { answer = "Мне нужно больше времени.", followUp = d3 })
    -- d2
    d2.text = string.format("Отлично! Встретимся в (%s:%s). Пора положить этому конец.", _X, _Y)
    d2.talker = _Talker
    d2.textColor = _TextColor
    d2.talkerColor = _TalkerColor
    d2.onEnd = "saidReady"
    -- d3
    d3.text = "Без проблем — идите, убедитесь, что вы готовы. Мы не знаем, что они приготовили для нас."
    d3.talker = _Talker
    d3.textColor = _TextColor
    d3.talkerColor = _TalkerColor
    d3.onEnd = "saidNotReady"
    -- d6
    d6.text = string.format("Я уверена, что смогу что-нибудь организовать! Встретимся в (%s:%s). Пора положить этому конец.", _X, _Y)
    d6.talker = _Talker
    d6.textColor = _TextColor
    d6.talkerColor = _TalkerColor
    d6.onEnd = "saidReadyHelp"

    ScriptUI(_ID):interactShowDialog(d0, false)
end

-- Регистрация пометки кораблей
function registerMarkShips()
    local methodName = "Регистрация пометки кораблей"
    if onClient() then
        methodName = methodName .. " [КЛИЕНТ]"
        mission.Log(methodName, "Регистрация обратного вызова onPreRenderHud.")

        local _Player = Player()
        if _Player:registerCallback("onPreRenderHud", "onMarkShips") == 1 then
            mission.Log(methodName, "ПРЕДУПРЕЖДЕНИЕ: не удалось добавить обратный вызов prerender к скрипту.")
        end
    else
        methodName = methodName .. " [СЕРВЕР]"
        mission.Log(methodName, "Вызов на клиенте")

        invokeClientFunction(Player(), "registerMarkShips")
    end
end

function saidReady()
    local methodName = "Сказал 'Готов'"

    if onClient() then
        mission.Log(methodName, "Вызов на клиенте")
        mission.Log(methodName, "Вызов на сервере.")

        invokeServerFunction("saidReady")
    else
        mission.Log(methodName, "Вызов на сервере")

        LLTEUtil.allCavaliersDepart()

        nextPhase()
    end
end
callable(nil, "saidReady")

function saidReadyHelp()
    local methodName = "Сказал 'Готов' (с помощью)"

    if onClient() then
        mission.Log(methodName, "Вызов на клиенте")
        mission.Log(methodName, "Вызов на сервере.")

        invokeServerFunction("saidReadyHelp")
    else
        mission.Log(methodName, "Вызов на сервере")

        LLTEUtil.allCavaliersDepart()
        mission.data.custom.sendExtraCavaliers = true

        nextPhase()
    end
end
callable(nil, "saidReadyHelp")

function saidNotReady()
    local methodName = "Сказал 'Не готов'"

    if onClient() then
        mission.Log(methodName, "Вызов на клиенте")
        mission.Log(methodName, "Вызов на сервере.")

        invokeServerFunction("saidNotReady")
    else
        mission.Log(methodName, "Вызов на сервере")

        local _Blade = {Sector():getEntitiesByScriptValue("_llte_empressblade")}
        _Blade[1]:addScript("player/missions/empress/story/story2/lltestory2dialogue1.lua", mission.data.custom.pirateSector.x, mission.data.custom.pirateSector.y)
    end
end
callable(nil, "saidNotReady")

function startTheBattle()
    local methodName = "Начало битвы"

    if onClient() then
        mission.Log(methodName, "Вызов на клиенте")
        mission.Log(methodName, "Вызов на сервере.")

        invokeServerFunction("startTheBattle")
    else
        mission.Log(methodName, "Вызов на сервере")

        local _Cavaliers = {Sector():getEntitiesByScriptValue("is_cavaliers")}
        for _, _Cav in pairs(_Cavaliers) do
            ShipAI(_Cav.index):setAggressive()
        end

        local _Pirates = {Sector():getEntitiesByScriptValue("is_pirate")}
        for _, _Pirate in pairs(_Pirates) do
            ShipAI(_Pirate.index):setAggressive()
        end

        -- Таймер для увеличения уровня опасности со временем. +1 каждые 3.5 минуты.
        mission.phases[3].timers[4] = {time = 210, callback = function()
            if mission.data.custom.dangerLevel < 10 then
                local methodName = "Фаза 3: тик таймера 4"
                mission.Log(methodName, "Прошло 3 минуты. Увеличение уровня опасности.")
                mission.data.custom.dangerLevel = mission.data.custom.dangerLevel + 1
                Sector():invokeFunction("sector/background/defensecontroller.lua", "setDangerLevel", mission.data.custom.dangerLevel)
            end
        end, repeating = true}
    end
end
callable(nil, "startTheBattle")

--endregion