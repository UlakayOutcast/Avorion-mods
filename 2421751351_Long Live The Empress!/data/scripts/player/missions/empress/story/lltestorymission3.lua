--[[
    Сюжетная миссия 3.
    Порядок из хаоса
    ДОПОЛНИТЕЛЬНЫЕ ТРЕБОВАНИЯ ДЛЯ ЭТОЙ МИССИИ:
        - Сюжетная миссия 2 выполнена
        - Ранг у Кавалеров 3
        - Получить миссию от разведчика (не выдаётся игроку автоматически)
    ПРИМЕРНЫЙ ПЛАН:
        - Игрок читает письмо от Адрианы
        - Игрок направляется в место, указанное в письме (это сектор пиратов)
        - В секторе пиратов есть верфь.
            - Удаляем груз со всех станций.
        - Игрок уничтожает все станции. Механика похожа на миссию "Неумолимый клинок", но игрок не получает поддержки от Кавалеров.
            - Это потому, что игрок является отвлекающей атакой, пока Кавалеры атакуют другой сектор.
        - После очистки сектора пиратов игрок читает второе письмо от Адрианы.
        - Игрок направляется к месту встречи с Адрианой.
        - Игрок может поговорить с Адрианой — довольно обширное диалоговое дерево.
            - Игрок должен сказать Адриане, что нашёл Аворион + способ пройти через барьер, а также предложить дать Кавалерам Аворион.
            - Варианты диалога даже не доступны, если у игрока нет Авориона, что вынудит его повторять миссию, пока не найдёт.
            - Хороший исход разблокирует миссию 4 на 4 ранге (и удаляет эту конкретную миссию из списков разведчиков)
            - Плохой исход ничего не меняет.
        - Используем механику снабжения.
        - Ограничение по времени: 60 минут.
    УРОВЕНЬ ОПАСНОСТИ:
        - 5+ Миссия начинается с уровня опасности 5. Это фиксированное значение, так как это неповторяемая* сюжетная миссия.
            - Начинаем с 12 стандартных защитников в секторе.
            - Пираты появляются группами по 4 каждую минуту. (максимум 7)
            - Уровень опасности не увеличивается (в отличие от прошлой миссии), но на этот раз действует механика снабжения, поэтому если игрок игнорирует грузовые корабли, у него будут проблемы.
]]
package.path = package.path .. ";data/scripts/lib/?.lua"
package.path = package.path .. ";data/scripts/?.lua"

-- Запуск остальных подключений.
include("callable")
include("randomext")
include("structuredmission")

ESCCUtil = include("esccutil")
LLTEUtil = include("llteutil")

local SectorGenerator = include("SectorGenerator")
local PirateGenerator = include("pirategenerator")
local SpawnUtility = include("spawnutility")
local ShipUtility = include("shiputility")

mission._Debug = 0
mission._Name = "Порядок из хаоса"

-- Инициализация
local llte_storymission_init = initialize
function initialize()
    local _MethodName = "Инициализация"
    mission.Log(_MethodName, "Начало миссии 'Порядок из хаоса'...")

    if onServer() then
        if not _restoring then
            -- Стандартные данные миссии.
            mission.data.brief = mission._Name
            mission.data.title = mission._Name
            mission.data.autoTrackMission = true
            mission.data.icon = "data/textures/icons/cavaliers.png"
            mission.data.priority = 9
            mission.data.description = {
                "Кавалеры связались с вами, чтобы попросить помощи в очередном штурме группы пиратов.",
                { text = "Прочитайте письмо от Адрианы", bulletPoint = true, fulfilled = false },
                -- Если в каком-либо из этих пунктов есть координаты X/Y, они будут обновлены с правильным местоположением при начале соответствующей фазы.
                { text = "Уничтожьте пиратскую базу в секторе (${_X}:${_Y})", bulletPoint = true, fulfilled = false, visible = false },
                { text = "Прочитайте второе письмо от Адрианы", bulletPoint = true, fulfilled = false, visible = false },
                { text = "Встретьтесь с Адрианой в секторе (${_X}:${_Y})", bulletPoint = true, fulfilled = false, visible = false }
            }

            -- Пользовательские данные миссии:
            -- .dangerLevel
            -- .pirateLevel
            -- .pirateBaseLocation
            -- .meetingLocation
            -- .builtMainSector
            -- .playerArrivedPhase2
            -- .shipyardid
            -- .goodEndAchieved
            mission.data.custom.dangerLevel = 5 -- Это сюжетная миссия, поэтому мы держим всё предсказуемым.

            local missionReward = 750000

            missionData_in = {location = nil, reward = {credits = missionReward}}

            llte_storymission_init(missionData_in)
        else
            -- Восстановление
            llte_storymission_init()
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
    if mission.data.location then
        runFullSectorCleanup_llte()
    end
end

mission.globalPhase.onFail = function()
    -- Если есть корабли Кавалеров, они уходят в варп.
    local _MethodName = "При провале"
    mission.Log(_MethodName, "Начало...")

    -- Добавление скрипта в местоположение миссии для уничтожения, если мы там, или удалённое уничтожение в противном случае.
    runFullSectorCleanup_llte()
    -- Отправка письма о провале.
    local _Player = Player()
    local _Rank = _Player:getValue("_llte_cavaliers_rank")

    local _Mail = Mail()
    local _PirateFaction = Galaxy():getPirateFaction(mission.data.custom.pirateLevel)
    _Mail.text = Format("%1% %2%,\n\nНесмотря на изменение тактики, пираты отправили подавляющую силу для защиты своей базы. Нам пришлось отступить из-за потерь, которые мы понесли.\nВооружитесь более мощным оружием и щитами, и я приступлю к реорганизации флота для нового штурма. Мы продолжим бороться за сохранение мира, который мы построили!\n\nИмператрица Адриана Сталь", _Rank, _Player.name, _PirateFaction.name)
    _Mail.header = "Вынуждены отступить"
    _Mail.sender = "Императрица Адриана Сталь @Кавалеры"
    _Mail.id = "_llte_story3_mailfail"
    _Player:addMail(_Mail)
end

mission.globalPhase.onAccomplish = function()
    if mission.data.custom.goodEndAchieved then
        -- Отправка письма, если игрок получил хороший конец. Не отправлять ничего в противном случае.
        local _Player = Player()
        local _Rank = _Player:getValue("_llte_cavaliers_rank")

        local _Mail = Mail()
        _Mail.text = Format("%1% %2%,\n\nЕщё раз спасибо за согласие дать нам немного Авориона! Мы обязательно найдём ему хорошее применение. Как я говорила ранее, следите за нашими разведчиками! Они свяжутся с вами с инструкциями по организации доставки. С нетерпением ждём вашего ответа, %1%!\n\nИмператрица Адриана Сталь", _Rank, _Player.name)
        _Mail.header = "Доставка материалов"
        _Mail.sender = "Императрица Адриана Сталь @Кавалеры"
        _Mail.id = "_llte_story3_mailwin"
        _Player:addMail(_Mail)
    end
end

mission.phases[1] = {}
mission.phases[1].showUpdateOnEnd = true
mission.phases[1].onBeginServer = function()
    local _MethodName = "Фаза 1: начало на сервере"
    mission.Log(_MethodName, "Начало...")
    mission.data.custom.pirateBaseLocation = getNextLocation(true)
    local _X, _Y = mission.data.custom.pirateBaseLocation.x, mission.data.custom.pirateBaseLocation.y
    -- Используем это для включения последовательных пиратов.
    mission.data.custom.pirateLevel = Balancing_GetPirateLevel(_X, _Y)
    local _Player = Player()
    local _Rank = _Player:getValue("_llte_cavaliers_rank")
    local _Mail = Mail()
    local _PirateLevel = Player():getValue("_llte_pirate_faction_vengeance")
    local _Faction = Galaxy():getPirateFaction(_PirateLevel)

    _Mail.text = Format("%1% %2%,\n\nНесмотря на наш успех против %3%, другая группа пиратов собирается с силами. Видимо, они ничему не научились после первой попытки. Мы уничтожим и их. Однако я хотела бы изменить наш тактический подход. Вместо одной всеобъемлющей атаки, я хочу, чтобы вы начали отвлекающую атаку против меньшей базы, которую они построили в (%4%:%5%). Как только вы начнете, я поведу атакующую группу против их главной базы.\n\nМежду нашими двумя атаками мы должны раздавить их! Это будет ещё одним посланием тем, кто хочет разрушить мир, который мы построили.\n\nИмператрица Адриана Сталь", _Rank, _Player.name, _Faction.name, _X, _Y)
    _Mail.header = "Наведение порядка"
    _Mail.sender = "Императрица Адриана Сталь @Кавалеры"
    _Mail.id = "_llte_story3_mail1"
    _Player:addMail(_Mail)
end

mission.phases[1].playerCallbacks = {
    {
        name = "onMailRead",
        func = function(_PlayerIndex, _MailIndex)
            if onServer() then
                local _Player = Player()
                local _Mail = _Player:getMail(_MailIndex)
                if _Mail.id == "_llte_story3_mail1" then
                    nextPhase()
                end
            end
        end
    }
}

mission.phases[2] = {}
mission.phases[2].triggers = {}
mission.phases[2].triggers[1] = {
    condition = function()
        if onClient() then
            return true
        end
        return mission.data.custom.playerArrivedPhase2
    end,
    callback = function()
        if onServer() then
            local _Station = Entity(mission.data.custom.shipyardid)
            Sector():broadcastChatMessage(_Station, ChatMessageType.Chatter, "Кавалеры, здесь?! Убейте их! Убейте их!!!")
        end
    end,
    repeating = false
}
mission.phases[2].triggers[2] = {
    condition = function()
        local _MethodName = "Фаза 2: триггер 2"
        local _X, _Y = Sector():getCoordinates()
        if _X ~= mission.data.location.x or _Y ~= mission.data.location.y then
            mission.Log(_MethodName, "Не в зоне миссии — не выполняем триггер.")
            return
        end

        local _Stations = ESCCUtil.countEntitiesByValue("_llte_story3_mainobjective")
        return mission.data.custom.builtMainSector and _Stations == 0
    end,
    callback = function()
        -- Пираты убегают и следующая фаза.
        ESCCUtil.allPiratesDepart()
        mission.data.location = nil
        nextPhase()
    end,
    repeating = false
}
mission.phases[2].showUpdateOnEnd = true
mission.phases[2].onBeginServer = function()
    local _MethodName = "Фаза 2: начало на сервере"
    mission.data.location = mission.data.custom.pirateBaseLocation
    mission.data.description[2].fulfilled = true
    mission.data.description[3].arguments = { _X = mission.data.location.x, _Y = mission.data.location.y }
    mission.data.description[3].visible = true
end

mission.phases[2].onTargetLocationEntered = function(_X, _Y)
    local _MethodName = "Фаза 2: вход в целевой сектор"
    -- Построение основного сектора
    buildPirateSector(_X, _Y)
end

mission.phases[2].onTargetLocationArrivalConfirmed = function(_X, _Y)
    local _MethodName = "Фаза 2: прибытие в целевой сектор подтверждено"
    mission.Log(_MethodName, "Начало...")
    mission.data.custom.playerArrivedPhase2 = true
    mission.data.timeLimit = 1800
    mission.data.timeLimitInDescription = true
    sync()
end

mission.phases[3] = {}
mission.phases[3].timers = {}
mission.phases[3].showUpdateOnEnd = true
mission.phases[3].onBeginServer = function()
    local _MethodName = "Фаза 3: начало на сервере"
    mission.data.custom.meetingLocation = getNextLocation(false)
    local _X, _Y = mission.data.custom.meetingLocation.x, mission.data.custom.meetingLocation.y
    local _Player = Player()
    local _Rank = _Player:getValue("_llte_cavaliers_rank")

    mission.data.description[3].fulfilled = true
    mission.data.description[4].visible = true

    mission.data.timeLimit = nil
    mission.data.timeLimitInDescription = false

    local _Mail = Mail()
    _Mail.text = Format("%1% %2%,\n\nБлагодаря вашему отвлечению наша атака увенчалась успехом! Нам удалось раздавить пиратов. Отличная работа, удерживая их занятыми!\nЯ хотела бы поговорить с вами по некоторым вопросам. Приходите в (%3%:%4%), и я встречу вас там!\n\nИмператрица Адриана Сталь", _Rank, _Player.name, _X, _Y)
    _Mail.header = "Давайте поговорим!"
    _Mail.sender = "Императрица Адриана Сталь @Кавалеры"
    _Mail.id = "_llte_story3_mail2"
    _Player:addMail(_Mail)
end
mission.phases[3].onBeginClient = function()
    mission.data.timeLimit = nil
    mission.data.timeLimitInDescription = false
end

mission.phases[3].playerCallbacks = {
    {
        name = "onMailRead",
        func = function(_PlayerIndex, _MailIndex)
            if onServer() then
                local _Player = Player()
                local _Mail = _Player:getMail(_MailIndex)
                if _Mail.id == "_llte_story3_mail2" then
                    nextPhase()
                end
            end
        end
    }
}

mission.phases[4] = {}
mission.phases[4].timers = {}
mission.phases[4].showUpdateOnEnd = true
mission.phases[4].onBeginServer = function()
    local _MethodName = "Фаза 4: начало на сервере"
    mission.data.location = mission.data.custom.meetingLocation
    mission.data.description[4].fulfilled = true
    mission.data.description[5].arguments = { _X = mission.data.location.x, _Y = mission.data.location.y }
    mission.data.description[5].visible = true
end

mission.phases[4].onTargetLocationArrivalConfirmed = function(_X, _Y)
    local _MethodName = "Фаза 4: прибытие в целевой сектор подтверждено"
    local _EmpressBlade = LLTEUtil.spawnBladeOfEmpress()
    _EmpressBlade:addScript("player/missions/empress/story/story3/lltestory3empressblade.lua")
end

-- Вызов серверных функций
function buildPirateSector(_X, _Y)
    local _MethodName = "Построение основного сектора"

    if not mission.data.custom.builtMainSector then
        mission.Log(_MethodName, "Основной сектор ещё не построен — строим его сейчас.")
        local _Generator = SectorGenerator(_X, _Y)
        local _Rgen = ESCCUtil.getRand()
        -- Добавление: военного аванпоста, исследовательской станции, верфи и ремонтного дока.
        local _Faction = Galaxy():getPirateFaction(mission.data.custom.pirateLevel)
        mission.Log(_MethodName, "Построение сектора для фракции пиратов: " .. tostring(_Faction.name))
        local _Shipyard = _Generator:createShipyard(_Faction)
        _Shipyard.position = Matrix()
        mission.data.custom.shipyardid = _Shipyard.index
        local _Stations = { _Shipyard }
        for _, _Station in pairs(_Stations) do
            _Station:removeScript("consumer.lua")
            _Station:removeScript("backup.lua") -- Задержка обратного вызова здесь глупая, а непредсказуемая опасная зона в сюжетной миссии — нехорошо.
            _Station:setValue("is_pirate", true)
            _Station:setValue("_llte_story3_mainobjective", true)
            ShipUtility.addScalableArtilleryEquipment(_Station, 3.0, 1.0, false)
            local _StationBay = CargoBay(_Station)
            _StationBay:clear()

            local _StationAI = ShipAI(_Station)
            _StationAI:setAggressive()

            Boarding(_Station).boardable = false
        end
        Sector():removeScript("traders.lua")
        -- Добавление: 1 большого астероидного поля и 2 небольших астероидных поля.
        for _ = 1, 2 do
            _Generator:createSmallAsteroidField()
        end
        _Generator:createAsteroidField()
        -- Добавление: 12 стандартных защитников пиратов
        local _PirateTable = ESCCUtil.getStandardWave(mission.data.custom.dangerLevel, 12, "Standard")
        local _CreatedPirateTable = {}

        for _, _Pirate in pairs(_PirateTable) do
            table.insert(_CreatedPirateTable, PirateGenerator.createPirateByName(_Pirate, PirateGenerator.getGenericPosition()))
        end

        SpawnUtility.addEnemyBuffs(_CreatedPirateTable)
        local _PirateLevel = Balancing_GetPirateLevel(_X, _Y)

        -- Добавление: скрипта контроллера защиты.
        local _DCD = {}
        _DCD._DefenseLeader = mission.data.custom.shipyardid
        _DCD._DefenderCycleTime = 90
        _DCD._DangerLevel = mission.data.custom.dangerLevel
        _DCD._MaxDefenders = 7
        _DCD._MaxDefendersSpawn = 4
        _DCD._DefenderHPThreshold = 0.5
        _DCD._DefenderOmicronThreshold = 0.5
        _DCD._ForceWaveAtThreshold = 0.8
        _DCD._ForcedDefenderDamageScale = 5
        _DCD._IsPirate = true
        _DCD._Factionid = _Shipyard.factionIndex
        _DCD._PirateLevel = _PirateLevel
        _DCD._UseLeaderSupply = true
        _DCD._SupplyPerLevel = 500
        _DCD._SupplyFactor = 0.1
        _DCD._LowTable = "High"

        Sector():addScript("sector/background/defensecontroller.lua", _DCD)

        local _SCD = {}
        _SCD._ShipmentLeader = mission.data.custom.shipyardid
        _SCD._ShipmentCycleTime = 120
        _SCD._DangerLevel = mission.data.custom.dangerLevel
        _SCD._IsPirate = true
        _SCD._Factionid = _Shipyard.factionIndex
        _SCD._PirateLevel = _PirateLevel
        _SCD._SupplyTransferPerCycle = 100
        _SCD._SupplyPerShip = 500
        _SCD._SupplierExtraScale = 8
        _SCD._SupplierHealthScale = 0.2

        Sector():addScript("sector/background/shipmentcontroller.lua", _SCD)

        mission.data.custom.builtMainSector = true
    end
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

function getNextLocation(_FirstLocation)
    local _MethodName = "Получение следующего местоположения"

    mission.Log(_MethodName, "Получение местоположения.")
    local x, y = Sector():getCoordinates()
    local target = {}

    if _FirstLocation then
        -- Получаем относительно близкий сектор. Нет необходимости идти слишком близко к барьеру для этой миссии.
        local _Nx, _Ny = ESCCUtil.getPosOnRing(x, y, 165)
        target.x, target.y = MissionUT.getEmptySector(_Nx, _Ny, 5, 10, false)
    else
        target.x, target.y = MissionUT.getEmptySector(x, y, 3, 5, false)
    end

    return target
end

function llteStory3_finishAndReward(_GoodEnd)
    local _MethodName = "Завершение и награждение"
    mission.Log(_MethodName, "Выполнение условия победы.")

    local _Player = Player()
    local _Rank = _Player:getValue("_llte_cavaliers_rank")
    local _Rgen = ESCCUtil.getRand()

    local _WinMsgTable = {
        "Отличная работа, " .. _Rank .. "!"
    }

    if _GoodEnd then
        mission.Log(_MethodName, "Хороший конец достигнут — установка значения.")
        mission.data.custom.goodEndAchieved = true
        _Player:setValue("_llte_story_3_accomplished", true)
    end

    -- Увеличение репутации на 3
    _Player:setValue("_llte_cavaliers_rep", _Player:getValue("_llte_cavaliers_rep") + 3)
    _Player:sendChatMessage("Адриана Сталь", 0, _WinMsgTable[_Rgen:getInt(1, #_WinMsgTable)] .. " Вот ваше вознаграждение, как и обещали.")
    reward()
    accomplish()
end

-- Вызов клиентских/серверных функций
function goodEnd()
    local _MethodName = "Хороший конец"

    if onClient() then
        mission.Log(_MethodName, "Вызов на клиенте")
        mission.Log(_MethodName, "Вызов на сервере.")

        invokeServerFunction("goodEnd")
    else
        mission.Log(_MethodName, "Вызов на сервере")

        LLTEUtil.allCavaliersDepart()

        llteStory3_finishAndReward(true)
    end
end
callable(nil, "goodEnd")

function normalEnd()
    local _MethodName = "Обычный конец"

    if onClient() then
        mission.Log(_MethodName, "Вызов на клиенте")
        mission.Log(_MethodName, "Вызов на сервере.")

        invokeServerFunction("normalEnd")
    else
        mission.Log(_MethodName, "Вызов на сервере")

        LLTEUtil.allCavaliersDepart()

        llteStory3_finishAndReward(false)
    end
end
callable(nil, "normalEnd")

--endregion