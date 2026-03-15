--[[
    Побочная миссия ранга 4.
    Уничтожение укреплённых пиратов
    Эта миссия оправдывает своё название. Когда Hello There тестировал её, он сказал: "(предупредите игрока через разведчика, что эта миссия — зверь по сравнению с остальными)".
    ДОПОЛНИТЕЛЬНЫЕ ТРЕБОВАНИЯ:
        - Ранг 3
    ПРИМЕРНЫЙ ПЛАН:
        - [НЕОБЯЗАТЕЛЬНО] Игрок направляется в сектор и сражается с группой из 12 пиратов, чтобы забрать ключи дешифровки.
            - Необязательные пираты дают подсказки о том, как работает эта миссия.
            - Также у них есть полезные данные.
        - Игрок направляется в сектор.
        - Игрок сражается с бесконечно возрождающимися волнами пиратов, пытаясь уничтожить аванпост.
        - После уничтожения аванпоста волны больше не появляются (очевидно) — пираты покинут сектор, когда игрок уйдёт.
        - Время от времени появляются корабли снабжения, которые пытаются пристыковаться к аванпосту. Если корабль снабжения успешно пристыкуется, он увеличивает уровень снабжения аванпоста.
        - По мере увеличения уровня снабжения аванпост будет время от времени стрелять крупным зарядом по игроку (можно уклониться).
            - Если игрок выполнил необязательную задачу, транслируются сообщения в чат с подсказками о выстреле, появлении грузов и защитников.
        - Аванпост имеет истребители. Уровень снабжения увеличивает количество истребителей.
        - Многие вещи здесь обрабатываются скриптом на самом аванпосте. Это сделано для того, чтобы игрок не мог просто покинуть миссию и легко уничтожить станцию.
        - См. defensecontroller.lua, shipmentcontroller.lua и stationsiegegun.lua для получения дополнительной информации о том, как эти скрипты взаимодействуют.
    УРОВЕНЬ ОПАСНОСТИ:
        1+ - [Эти условия действуют независимо от уровня опасности]
            - Изначально 12 защитников аванпоста, взятых из таблицы низкой угрозы.
            - Альтернативное местоположение имеет 12 кораблей из стандартной таблицы.
            - Защитники возрождаются каждые 4 минуты.
            - Корабли снабжения появляются каждые 2 минуты. Добавляем 5 секунд, чтобы они не совпадали с появлением защитников.
            - Корабли снабжения со временем становятся более прочными (+10% HP/щита за корабль снабжения, без верхнего предела).
            - Уровень снабжения военного аванпоста даёт бонус защитникам при появлении (+10% щита/HP/урона, без верхнего предела).
            - Сильно повреждённые защитники уйдут в варп и будут заменены в следующей волне защитников.
            - Лимит в 4 защитника. Устанавливаем конкретное значение для защитников, чтобы 10 изначальных защитников не учитывались.
            - Аванпост имеет главную пушку, которая наносит больше урона в зависимости от уровня аванпоста, уровня опасности миссии и уровня снабжения аванпоста.
            - Аванпост вынуждает волну защитников появиться почти сразу, если игроку удаётся снизить корпус аванпоста ниже 80% до появления первой волны защитников.
            - Если аванпост вынуждает появление защитников, защитники получают бонус урона ×2.5.
            - У аванпоста +30% к щитам и HP.
        5 - [Эти условия действуют при уровне опасности 5 и выше]
            - Вынужденные волны защитников получают ×3.5 урона.
        6 - [Эти условия действуют при уровне опасности 6 и выше]
            - Корабли снабжения появляются чаще.
        8 - [Эти условия действуют при уровне опасности 8 и выше]
            - Аванпост чередует стандартные/высокоугрожающие таблицы для волн кораблей каждые 3 волны.
            - Снабжение передаётся быстрее.
            - Аванпост сохраняет свой груз, поэтому игрок получает значительное вознаграждение за эту миссию с небольшими дополнительными усилиями.
                - Груз сохраняется только если игрок находится на расстоянии менее 175 от ядра, чтобы предотвратить лёгкое фарминг в низкотехнологичных секторах.
            - Вынужденные волны защитников получают ×5 урона.
        10 - [Эти условия действуют при уровне опасности 10]
            - Волны защитников появляются чаще (каждые 3,5 минуты).
            - +1 к максимальному количеству защитников (всего 5).
            - Корабли снабжения появляются ещё чаще и имеют больше снабжения.
            - В каждую волну пиратов добавляется дополнительный глушильщик.
            - Военный аванпост называется "Крепость вооружений" и имеет +50% HP/щитов и больше орудий. Ничего особенного, просто крутое название.
            - Вынужденные волны защитников получают ×10 урона.
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
local Balancing = include("galaxy")
local SpawnUtility = include("spawnutility")
local ShipUtility = include("shiputility")
local Placer = include("placer")
local UpgradeGenerator = include("upgradegenerator")

mission._Debug = 0
mission._Name = "Уничтожение укреплённых пиратов"

mission.data.custom.locations = {}
mission.data.custom.wreckagePieceIds = {}

-- Настройка данных миссии
local llte_sidemission_init = initialize
function initialize()
    local _MethodName = "Инициализация"
    mission.Log(_MethodName, "Начало миссии 'Уничтожение укреплённых пиратов'...")

    if onServer() then
        if not _restoring then
            -- У нас нет доступа к данным объявления миссии, поэтому определяем здесь.
            local _Rgen = ESCCUtil.getRand()
            local x, y = Sector():getCoordinates()
            local insideBarrier = MissionUT.checkSectorInsideBarrier(x, y)
            local _Target = {}
            local _OptTarget = {}
            _Target.x, _Target.y = MissionUT.getSector(x, y, 5, 12, false, false, false, false, insideBarrier)
            local _OptLocationOK = false
            while not _OptLocationOK do
                _OptTarget.x, _OptTarget.y = MissionUT.getSector(x, y, 4, 10, false, false, false, false, insideBarrier)
                if _OptTarget.x ~= _Target.x or _OptTarget.y ~= _Target.y then
                    _OptLocationOK = true
                end
            end

            if not _Target then
                mission.Log(_MethodName, "ОШИБКА: не удалось определить местоположение миссии. Завершение скрипта.")
                terminate()
                return
            end
            if not _OptTarget then
                mission.Log(_MethodName, "ОШИБКА: не удалось определить местоположение необязательной задачи. Завершение скрипта.")
                terminate()
                return
            end

            -- Стандартные данные миссии.
            mission.data.brief = "Уничтожение укреплённых пиратов"
            mission.data.title = "Уничтожение укреплённых пиратов"
            mission.data.icon = "data/textures/icons/cavaliers.png"
            mission.data.description = {
                "Кавалеры связались с вами и попросили уничтожить хорошо укреплённый пиратский аванпост.",
                { text = "Уничтожьте аванпост в секторе (${xLoc}:${yLoc})", arguments = {xLoc = _Target.x, yLoc = _Target.y}, bulletPoint = true, fulfilled = false },
                { text = "(Необязательно) Группа защитников собирается в секторе (${xLoc}:${yLoc}). Уничтожьте их", arguments = { xLoc = _OptTarget.x, yLoc = _OptTarget.y }, bulletPoint = true, fulfilled = false },
                { text = "Ищите обломки на предмет чего-нибудь интересного", bulletPoint = true, fulfilled = false, visible = false }
            }

            local _RewardBase = 190000
            -- Пользовательские данные миссии:
            -- .dangerLevel
            -- .locations
            -- .optlocation
            -- .pirateLevel
            -- .maxDefenders
            -- .defenderRespawnTime
            -- .freighterRespawnTime
            -- .freighterSupply
            -- .freighterSupplyTransfer
            -- .freighterScale
            -- .optionalPiratesGenerated
            -- .optionalPiratesTaunted
            -- .optionalPiratesAllDestroyed
            -- .wreckagePieceIds
            -- .optionalObjectiveCompleted
            -- .builtMainSector
            -- .militaryStationid
            -- .forcedDefenderScale
            mission.data.custom.dangerLevel = _Rgen:getInt(1, 10)
            mission.data.custom.locations = {}
            table.insert(mission.data.custom.locations, _Target)
            table.insert(mission.data.custom.locations, _OptTarget)
            mission.data.custom.optlocation = _OptTarget
            mission.data.custom.optionalObjectiveCompleted = false
            mission.data.custom.optionalObjectiveInvoked = false
            mission.data.custom.pirateLevel = Balancing_GetPirateLevel(_Target.x, _Target.y)
            mission.data.custom.maxDefenders = 4
            mission.data.custom.defenderRespawnTime = 150
            mission.data.custom.forcedDefenderScale = 2.5
            mission.data.custom.freighterRespawnTime = 125
            mission.data.custom.freighterSupply = 500
            mission.data.custom.freighterSupplyTransfer = 50
            mission.data.custom.freighterScale = 8
            -- Корректировка для уровня опасности. Такие вещи, как более быстрое снабжение и т.д., обрабатываются проверкой самого уровня опасности.
            if mission.data.custom.dangerLevel >= 5 then
                mission.data.custom.forcedDefenderScale = 3.5
            end
            if mission.data.custom.dangerLevel >= 6 then
                mission.data.custom.freighterRespawnTime = mission.data.custom.freighterRespawnTime - 30
                mission.data.custom.freighterScale = mission.data.custom.freighterScale + 2
                _RewardBase = _RewardBase + 8000
                mission.data.description[1] = mission.data.description[1] .. " Ожидается сильное сопротивление."
            end
            if mission.data.custom.dangerLevel >= 8 then
                mission.data.custom.freighterSupplyTransfer = 75
                mission.data.custom.freighterScale = mission.data.custom.freighterScale + 2
                mission.data.custom.forcedDefenderScale = 5
                _RewardBase = _RewardBase + 12000
            end
            if mission.data.custom.dangerLevel == 10 then
                mission.data.custom.maxDefenders = mission.data.custom.maxDefenders + 1
                mission.data.custom.defenderRespawnTime = mission.data.custom.defenderRespawnTime - 30
                mission.data.custom.freighterSupply = mission.data.custom.freighterSupply + 500
                mission.data.custom.freighterSupplyTransfer = 90
                mission.data.custom.freighterScale = mission.data.custom.freighterScale + 2
                mission.data.custom.forcedDefenderScale = 10
                _RewardBase = _RewardBase + 16000
            end
            PirateGenerator.pirateLevel = mission.data.custom.pirateLevel

            if insideBarrier then
                _RewardBase = _RewardBase * 2
            end

            local missionReward = ESCCUtil.clampToNearest(_RewardBase * Balancing.GetSectorRewardFactor(Sector():getCoordinates()), 5000, "Up")

            missionData_in = {location = _Target, reward = {credits = missionReward}}

            llte_sidemission_init(missionData_in)
            Player():sendChatMessage("Кавалеры", 0, "Аванпост находится в секторе \\s(%1%:%2%). Идите и разгромите их!", _Target.x, _Target.y)
            if mission.data.custom.dangerLevel >= 8 then
                Player():sendChatMessage("Кавалеры", 0, "Они хорошо укрепили свою позицию. Возможно, стоит выяснить, какую информацию вы сможете обнаружить перед атакой.")
            end
        else
            -- Восстановление
            llte_sidemission_init()
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
mission.globalPhase.timers = {}
mission.globalPhase.onSectorEntered = function(_X, _Y)
    local _MethodName = "Глобальная фаза: вход в сектор"
    mission.Log(_MethodName, "Начало...")

    local _OptX, _OptY = mission.data.custom.optlocation.x, mission.data.custom.optlocation.y
    if _OptX and _OptY then
        if _X == _OptX and _Y == _OptY then
            mission.Log(_MethodName, "Вход в сектор необязательной задачи — запуск обратных вызовов onOptionalLocationEntered.")

            if mission.currentPhase.onOptionalLocationEntered then mission.currentPhase.onOptionalLocationEntered(_X, _Y) end
            if mission.globalPhase.onOptionalLocationEntered then mission.globalPhase.onOptionalLocationEntered(_X, _Y) end
        end
    end
end

mission.globalPhase.onSectorArrivalConfirmed = function(_X, _Y)
    local _MethodName = "Глобальная фаза: прибытие в сектор подтверждено"
    mission.Log(_MethodName, "Начало...")

    local _OptX, _OptY = mission.data.custom.optlocation.x, mission.data.custom.optlocation.y
    if _OptX and _OptY then
        if _X == _OptX and _Y == _OptY then
            mission.Log(_MethodName, "Прибытие в сектор необязательной задачи подтверждено — запуск обратных вызовов onOptionalLocationArrivalConfirmed.")

            if mission.currentPhase.onOptionalLocationArrivalConfirmed then mission.currentPhase.onOptionalLocationArrivalConfirmed(_X, _Y) end
            if mission.globalPhase.onOptionalLocationArrivalConfirmed then mission.globalPhase.onOptionalLocationArrivalConfirmed(_X, _Y) end
        end
    end
end

mission.globalPhase.updateServer = function(_TimeStep)
    local _MethodName = "Глобальная фаза: обновление сервера"

    local _LX, _LY = mission.data.custom.optlocation.x, mission.data.custom.optlocation.y
    if _LX and _LY then
        local _X, _Y = Sector():getCoordinates()
        if _LX == _X and _LY == _Y then
            if mission.currentPhase.optionalUpdateServer then mission.currentPhase.optionalUpdateServer(_TimeStep) end
        end
    else
        mission.Log(_MethodName, "ПРЕДУПРЕЖДЕНИЕ: не удалось получить текущие координаты X/Y миссии.")
    end
end

mission.phases[1] = {}
mission.phases[1].timers = {}
mission.phases[1].noBossEncountersTargetSector = true
mission.phases[1].onTargetLocationEntered = function(_X, _Y)
    local _MethodName = "Фаза 1: вход в целевой сектор"
    mission.Log(_MethodName, "Начало...")

    -- Построение сектора, затем запуск скриптов подкреплений и снабжения.
    llteSide5_buildObjectiveSector(_X, _Y)
    mission.Log(_MethodName, "Запуск скриптов.")

    local _Sector = Sector()

    local _MilitaryStation = Entity(mission.data.custom.militaryStationid)
    local _SetOptionalObjectiveInvoked = false
    -- ДОБАВЛЕНИЕ СКРИПТОВ КОНТРОЛЛЕРА ЗАЩИТЫ И СНАБЖЕНИЯ
    if not _Sector:hasScript("sector/background/defensecontroller.lua") then
        -- Данные контроллера защиты
        local _defCycleTime = mission.data.custom.defenderRespawnTime
        if mission.data.custom.optionalObjectiveCompleted then
            mission.Log(_MethodName, "Необязательная задача выполнена при входе — увеличение времени цикла защитников.")
            _defCycleTime = _defCycleTime + 30
            _SetOptionalObjectiveInvoked = true
        end

        local _DCD = {}
        _DCD._DefenseLeader = mission.data.custom.militaryStationid
        _DCD._CodesCracked = mission.data.custom.optionalObjectiveCompleted
        _DCD._DefenderCycleTime = _defCycleTime
        _DCD._DangerLevel = mission.data.custom.dangerLevel
        _DCD._MaxDefenders = mission.data.custom.maxDefenders
        _DCD._DefenderHPThreshold = 0.5
        _DCD._DefenderOmicronThreshold = 0.5
        _DCD._ForceWaveAtThreshold = 0.8
        _DCD._ForcedDefenderDamageScale = mission.data.custom.forcedDefenderScale
        _DCD._IsPirate = true
        _DCD._Factionid = _MilitaryStation.factionIndex
        _DCD._PirateLevel = mission.data.custom.pirateLevel
        _DCD._UseLeaderSupply = true
        _DCD._LowTable = "Standard"
        _DCD._HighTable = "High"
        _DCD._SupplyPerLevel = 500
        _DCD._SupplyFactor = 0.1 -- +10% бонус за уровень.
        if mission.data.custom.dangerLevel >= 8 then
            _DCD._SwapTables = true
            _DCD._SwapOnModulo = 3
        end
        if mission.data.custom.dangerLevel == 10 then
            _DCD._AddToEachWave = { "Jammer" }
        end

        _Sector:addScript("sector/background/defensecontroller.lua", _DCD)
        mission.Log(_MethodName, "Скрипт контроллера защиты успешно добавлен.")
    else
        if mission.data.custom.optionalObjectiveCompleted and not mission.data.custom.optionalObjectiveInvoked then
            mission.Log(_MethodName, "Необязательная задача выполнена — установка скрипта контроллера защиты сектора на взломанные коды и увеличение цикла.")
            _Sector:invokeFunction("sector/background/defensecontroller.lua", "setCodesCracked", true)
            _Sector:invokeFunction("sector/background/defensecontroller.lua", "incrementCycleTime", 30)
            _SetOptionalObjectiveInvoked = true
        end
    end

    if not _Sector:hasScript("sector/background/shipmentcontroller.lua") then
        -- Данные контроллера снабжения
        local _shipCycleTime = mission.data.custom.freighterRespawnTime
        if mission.data.custom.optionalObjectiveCompleted then
            mission.Log(_MethodName, "Необязательная задача выполнена при входе — увеличение времени цикла снабжения.")
            _shipCycleTime = _shipCycleTime + 30
            _SetOptionalObjectiveInvoked = true
        end

        local _SCD = {}
        _SCD._ShipmentLeader = mission.data.custom.militaryStationid
        _SCD._CodesCracked = mission.data.custom.optionalObjectiveCompleted
        _SCD._ShipmentCycleTime = _shipCycleTime
        _SCD._DangerLevel = mission.data.custom.dangerLevel
        _SCD._IsPirate = true
        _SCD._Factionid = _MilitaryStation.factionIndex
        _SCD._PirateLevel = mission.data.custom.pirateLevel
        _SCD._SupplyTransferPerCycle = mission.data.custom.freighterSupplyTransfer
        _SCD._SupplyPerShip = mission.data.custom.freighterSupply
        _SCD._SupplierExtraScale = mission.data.custom.freighterScale
        _SCD._SupplierHealthScale = 0.1

        _Sector:addScript("sector/background/shipmentcontroller.lua", _SCD)
        mission.Log(_MethodName, "Скрипт контроллера снабжения успешно добавлен.")
    else
        if mission.data.custom.optionalObjectiveCompleted and not mission.data.custom.optionalObjectiveInvoked then
            mission.Log(_MethodName, "Необязательная задача выполнена — установка скрипта контроллера снабжения сектора на взломанные коды и увеличение цикла.")
            _Sector:invokeFunction("sector/background/shipmentcontroller.lua", "setCodesCracked", true)
            _Sector:invokeFunction("sector/background/shipmentcontroller.lua", "incrementCycleTime", 15)
            _SetOptionalObjectiveInvoked = true
        end
    end

    if not _MilitaryStation:hasScript("entity/stationsiegegun.lua") then
        -- Данные осадной пушки
        local _SGD = {}
        _SGD._CodesCracked = mission.data.custom.optionalObjectiveCompleted
        _SGD._Velocity = 150
        _SGD._ShotCycle = 30
        _SGD._ShotCycleSupply = 1000
        _SGD._ShotCycleTimer = 30
        _SGD._SupplyPerLevel = 4000 -- Это слишком быстро увеличивает урон — к второму выстрелу он уже будет наносить на 40% больше урона.
        _SGD._SupplyFactor = 0.1
        _SGD._FragileShots = false

        local _Dist = ESCCUtil.getDistanceToCenter(_X, _Y)
        -- Ограничение минимального урона до 10к
        local _Damage = math.max((500 - _Dist) * 10000, 10000)
        if _Dist < 80 then
            _Damage = _Damage + ((80 - _Dist) * 125000)
        end
        _Damage = _Damage * (1 + (mission.data.custom.dangerLevel / 20))
        _SGD._BaseDamagePerShot = _Damage

        _MilitaryStation:addScript("entity/stationsiegegun.lua", _SGD)
        mission.Log(_MethodName, "Скрипт осадной пушки добавлен к военному аванпосту.")
    else
        if mission.data.custom.optionalObjectiveCompleted and not mission.data.custom.optionalObjectiveInvoked then
            mission.Log(_MethodName, "Необязательная задача выполнена — установка скрипта военной станции на взломанные коды.")
            _MilitaryStation:invokeFunction("entity/stationsiegegun.lua", "setCodesCracked", true)
            _SetOptionalObjectiveInvoked = true
        end
    end

    if _SetOptionalObjectiveInvoked then
        mission.data.custom.optionalObjectiveInvoked = true
    end
end

mission.phases[1].updateTargetLocationServer = function(timeStep)
    local _MethodName = "Фаза 1: обновление целевого сектора"

    if ESCCUtil.countEntitiesByValue("_llte_side5_mainobjective") == 0 and mission.data.custom.builtMainSector then
        mission.Log(_MethodName, "Аванпост уничтожен. Выполнение условия победы.")

        -- Добавление скриптов удаления ко всем пиратским объектам в секторе.
        local _Pirates = {Sector():getEntitiesByScriptValue("is_pirate")}
        for _, _P in pairs(_Pirates) do
            MissionUT.deleteOnPlayersLeft(_P)
        end

        llteSide5_finishAndReward()
    end
end

-- Вызовы необязательного сектора.
mission.phases[1].onOptionalLocationEntered = function(_X, _Y)
    local _MethodName = "Фаза 1: вход в необязательный сектор"
    mission.Log(_MethodName, "Начало...")

    if not mission.data.custom.optionalPiratesGenerated then
        mission.Log(_MethodName, "Генерация необязательных пиратов.")

        local _PirateTable = ESCCUtil.getStandardWave(mission.data.custom.dangerLevel, 10)
        local _CreatedPirateTable = {}

        for _, _Pirate in pairs(_PirateTable) do
            table.insert(_CreatedPirateTable, PirateGenerator.createPirateByName(_Pirate, PirateGenerator.getGenericPosition()))
        end

        SpawnUtility.addEnemyBuffs(_CreatedPirateTable)

        mission.data.custom.optionalPiratesGenerated = true
    end
end

mission.phases[1].onOptionalLocationArrivalConfirmed = function(_X, _Y)
    local _MethodName = "Фаза 1: прибытие в необязательный сектор подтверждено"
    mission.Log(_MethodName, "Начало...")

    if not mission.data.custom.optionalPiratesTaunted then
        mission.Log(_MethodName, "Необязательные пираты не издевались. Трансляция издевательств.")

        local _Pirates = {Sector():getEntitiesByScriptValue("is_pirate")}
        if _Pirates then
            mission.Log(_MethodName, "Отправка издевательств пиратов")
            local _Lines = {
                "Кто нас сдал? Мы разберёмся с тобой после того, как закончим здесь!",
                "Как они узнали о кодах? Быстро убейте их!",
                "Убийство вас будет адекватной формой безопасности.",
                "Как вы нас нашли? Неважно, мы убьём вас!",
                "Думаю, нам не придётся беспокоиться о кодах, если вы будете мёртвы.",
                "Они, должно быть, за кодом! Убейте их всех!",
                "Что это? Мы убьём вас!"
            }

            Sector():broadcastChatMessage(_Pirates[1], ChatMessageType.Chatter, getRandomEntry(_Lines))
        end

        mission.data.custom.optionalPiratesTaunted = true
    end
end

mission.phases[1].optionalUpdateServer = function(_TimeStep)
    local _MethodName = "Обновление необязательного сектора на сервере"

    -- Мы не можем использовать onDestroyed для этого, потому что он всё равно будет думать, что один остался, когда последний будет уничтожен.
    if ESCCUtil.countEntitiesByValue("is_pirate") == 0 and not mission.data.custom.optionalPiratesAllDestroyed then
        mission.Log(_MethodName, "Все необязательные пираты уничтожены. Добавление скриптов поиска обломков к обломкам.")

        local _WreckSizes = { 1000, 900, 800, 700, 600, 500, 400, 300, 200, 150, 100, 50, 40, 30, 20, 10 }
        local _TargetWreckSize = 1000
        local _Rgen = ESCCUtil.getRand()

        -- Пытаемся найти самый большой размер обломков (по количеству блоков), которых не менее 5.
        local _Wreckages = {Sector():getEntitiesByType(EntityType.Wreckage)}
        for _, _Wsize in pairs(_WreckSizes) do
            local _Count = 0
            for _, _Wr in pairs(_Wreckages) do
                local _Pl = Plan(_Wr.id)
                if _Pl.numBlocks >= _Wsize then _Count = _Count + 1 end
            end
            if _Count >= 5 then
                _TargetWreckSize = _Wsize
                break
            end
        end

        -- Получаем 5 случайных обломков из таблицы.
        shuffle(random(), _Wreckages)
        local _CandidateWrecks = {}
        for _, _Wreck in pairs(_Wreckages) do
            local _Pl = Plan(_Wreck.id)
            if _Pl.numBlocks >= _TargetWreckSize then
                table.insert(_CandidateWrecks, _Wreck)
                if #_CandidateWrecks >= 5 then
                    break
                end
            end
        end

        -- Добавляем скрипт ко всем подходящим обломкам, позволяющий их обыскивать, и отмечаем их на интерфейсе игрока.
        for _, _Wreck in pairs(_CandidateWrecks) do
            table.insert(mission.data.custom.wreckagePieceIds, _Wreck.id)
            _Wreck:addScriptOnce("player/missions/empress/side/side5/llteside5search.lua")
            _Wreck:setValue("_llte_optionalwreck_targetplayer", Player().index)
        end
        local _TargetWreck = Entity(mission.data.custom.wreckagePieceIds[_Rgen:getInt(1, #mission.data.custom.wreckagePieceIds)])
        _TargetWreck:setValue("_llte_optionalwreck_hascode", true)

        registerMarkWreckages()
        showMissionUpdated("Уничтожение укреплённых пиратов")
        mission.data.description[3].fulfilled = true
        mission.data.description[4].visible = true

        sync()
        mission.data.custom.optionalPiratesAllDestroyed = true
    end
end

-- Покидание всегда должно быть последним вызовом в фазе
mission.phases[1].onAbandon = function()
    local _X, _Y = Sector():getCoordinates()
    if _X == mission.data.location.x and _Y == mission.data.location.y then
        -- Покинуто в секторе.
        -- Выгружаем весь груз с военной базы на случай, если игрок попытается убить её после покидания, чтобы облегчить задачу.
        -- Но шутка на них — контроллер защиты не исчезнет при удалении этого.
        local _Station = Entity(mission.data.custom.militaryStationid)
        local _StationBay = CargoBay(_Station)
        _StationBay:clear()

        local _EntityTypes = ESCCUtil.allEntityTypes()
        Sector():addScript("sector/deleteentitiesonplayersleft.lua", _EntityTypes)
    else
        -- Покинуто вне сектора.
        local _MX, _MY = mission.data.location.x, mission.data.location.y
        Galaxy():loadSector(_MX, _MY)
        invokeSectorFunction(_MX, _MY, true, "lltesectormonitor.lua", "clearMissionAssets", _MX, _MY, true, true)
    end
end

-- Вызов серверных функций
-- Построение основного сектора
function llteSide5_buildObjectiveSector(_X, _Y)
    local _MethodName = "Построение сектора"

    if not mission.data.custom.builtMainSector then
        mission.Log(_MethodName, "Построение основного сектора.")

        -- В секторе всегда должно быть 3-5 небольших полей астероидов, 1 большое поле астероидов и военный аванпост + 12 стандартных защитников.
        local generator = SectorGenerator(_X, _Y)
        local _Rgen = ESCCUtil.getRand()
        for _ = 1, _Rgen:getInt(3, 5) do
            generator:createSmallAsteroidField()
        end
        generator:createAsteroidField()

        -- Военный аванпост — удаляем весь груз и различные скрипты и т.д.
        local _Faction = Galaxy():getPirateFaction(mission.data.custom.pirateLevel)
        local _Station = generator:createMilitaryBase(_Faction)
        _Station.position = Matrix()
        _Station:setValue("is_pirate", true)
        _Station:setValue("_llte_side5_mainobjective", true)
        local _StationSphere = _Station:getBoundingSphere()
        local _AsteroidRemovalSphere = Sphere(_StationSphere.center, _StationSphere.radius * 15)
        local _RemovalCandidates = {Sector():getEntitiesByLocation(_AsteroidRemovalSphere)}
        mission.Log(_MethodName, "Найдено " .. #_RemovalCandidates .. " кандидатов на удаление. Все астероиды в этом списке будут удалены.")
        for _, _En in pairs(_RemovalCandidates) do
            if _En.isAsteroid then
                -- Не мешаем ИИ.
                Sector():deleteEntity(_En)
            end
        end
        -- Добавление турелей.
        ShipUtility.addScalableArtilleryEquipment(_Station, 4.0, 1.0, false)
        ShipUtility.addScalableArtilleryEquipment(_Station, 2.0, 1.0, false)
        ShipUtility.addScalableArtilleryEquipment(_Station, 2.0, 1.0, false)
        -- Удаление скриптов.
        _Station:removeScript("icon.lua")
        _Station:removeScript("consumer.lua")
        _Station:removeScript("backup.lua")
        Sector():removeScript("traders.lua")
        -- Установка ИИ в агрессивный режим.
        local _ShipAI = ShipAI(_Station)
        _ShipAI:setAggressive()
        -- Добавление пилотов, чтобы станция могла использовать истребители.
        _Station:addCrew(60, CrewMan(CrewProfessionType.Pilot))
        -- Без возможности абордажа.
        Boarding(_Station).boardable = false
        -- Удаление груза, если уровень опасности меньше 8 или если слишком далеко от центра.
        local _Dist = ESCCUtil.getDistanceToCenter(_X, _Y)
        if mission.data.custom.dangerLevel < 8 or _Dist > 175 then
            local _StationBay = CargoBay(_Station)
            _StationBay:clear()
        end
        -- Изменение на "Крепость вооружений" и усиление щитов/HP. Эффективно +50% урона за счёт дополнительных орудий.
        local _DuraFactor = 1.3
        if mission.data.custom.dangerLevel == 10 then
            ShipUtility.addScalableArtilleryEquipment(_Station, 4.0, 1.0, false)
            _DuraFactor = 1.5

            _Station.title = "Крепость вооружений"
            _Station:addScript("icon.lua", "data/textures/icons/pixel/skull_big.png")
            _Station:addScriptOnce("internal/common/entity/background/legendaryloot.lua")
        else
            _Station.title = "Военный аванпост"
            _Station:addScript("icon.lua", "data/textures/icons/pixel/military.png")
        end
        -- Увеличение HP/щитов станции.
        local _Dura = Durability(_Station)
        if _Dura then
            _Dura.maxDurabilityFactor = _Dura.maxDurabilityFactor * _DuraFactor
        end

        local _Shield = Shield(_Station)
        if _Shield then
            _Shield.maxDurabilityFactor = _Shield.maxDurabilityFactor * _DuraFactor
        end

        -- Наконец, (возможно) добавляем военную систему управления огнём в таблицу лута станции.
        if _Rgen:test(math.max(0.25, mission.data.custom.dangerLevel * 0.05)) then
            local _upgradeGenerator = UpgradeGenerator()
            local _upgradeRarities = getSectorRarityTables(_X, _Y, _upgradeGenerator)
            local _seedInt = _Rgen:getInt(1, 20000)
            Loot(_Station):insert(SystemUpgradeTemplate("data/scripts/systems/militarytcs.lua", Rarity(getValueFromDistribution(_upgradeRarities)), Seed(_seedInt)))
        end

        mission.data.custom.militaryStationid = _Station.id

        Placer.resolveIntersections()

        -- 8 изначальных защитников из стандартной таблицы угроз.
        local _InitialDefenders = 8
        -- На уровне опасности 10 получаем двух дополнительных.
        if mission.data.custom.dangerLevel == 10 then
            _InitialDefenders = _InitialDefenders + 2
        end
        local _PirateTable = ESCCUtil.getStandardWave(mission.data.custom.dangerLevel, _InitialDefenders, "Standard")
        local _CreatedPirateTable = {}

        for _, _Pirate in pairs(_PirateTable) do
            table.insert(_CreatedPirateTable, PirateGenerator.createPirateByName(_Pirate, PirateGenerator.getGenericPosition()))
        end

        SpawnUtility.addEnemyBuffs(_CreatedPirateTable)
        mission.data.custom.builtMainSector = true
    end
end

function getSectorRarityTables(_X, _Y, _upgradeGenerator)
    local _dangerLevel = mission.data.custom.dangerLevel
    local _rarities = _upgradeGenerator:getSectorRarityDistribution(_X, _Y)
    _rarities[-1] = 0 -- нет обычных
    _rarities[0] = 0 -- нет обычных
    _rarities[1] = 0 -- нет необычных
    _rarities[2] = 0 -- нет редких

    local _dangerFactors = {
        { _exceptional = 1, _exotic = 1}, -- 1
        { _exceptional = 1, _exotic = 1}, -- 2
        { _exceptional = 1, _exotic = 1}, -- 3
        { _exceptional = 1, _exotic = 1}, -- 4
        { _exceptional = 0.5, _exotic = 1}, -- 5
        { _exceptional = 0.5, _exotic = 1}, -- 6
        { _exceptional = 0.5, _exotic = 0.75}, -- 7
        { _exceptional = 0.25, _exotic = 0.75}, -- 8
        { _exceptional = 0.25, _exotic = 0.5}, -- 9
        { _exceptional = 0.12, _exotic = 0.5} -- 10
    }

    _rarities[3] = _rarities[3] * _dangerFactors[_dangerLevel]._exceptional
    _rarities[4] = _rarities[4] * _dangerFactors[_dangerLevel]._exotic

    return _rarities
end

function llteSide5_finishAndReward()
    local _MethodName = "Завершение и награждение"
    mission.Log(_MethodName, "Выполнение условия победы.")

    local _Player = Player()
    local _Rank = _Player:getValue("_llte_cavaliers_rank")
    local _Rgen = ESCCUtil.getRand()

    local _WinMsgTable = {
        "Императрица будет рада услышать об этом.",
        "Спасибо за то, что сделали галактику безопаснее.",
        "Ваша поддержка, как всегда, ценна.",
        "Потрясающая работа, " .. _Player.name .. "!",
        "Отличная работа, " .. _Rank .. "!",
        "Телеметрия того боя выглядела невероятно!",
        "Мы ожидали не меньше от " .. _Rank .. "!"
    }

    local _RepReward = 4
    if mission.data.custom.dangerLevel == 10 then
        _RepReward = _RepReward + 1
    end

    -- Увеличение репутации на 4 (5 при уровне опасности 10)
    mission.data.reward.paymentMessage = "Получено %1% кредитов за уничтожение пиратской крепости."
    _Player:setValue("_llte_cavaliers_rep", _Player:getValue("_llte_cavaliers_rep") + _RepReward)
    _Player:sendChatMessage("Кавалеры", 0, _WinMsgTable[_Rgen:getInt(1, #_WinMsgTable)] .. " Мы перевели вознаграждение на ваш счёт.")
    reward()
    accomplish()
end

-- Вызов клиентских функций
function onMarkWreckages()
    local _MethodName = "Пометить обломки"

    local player = Player()
    if not player then return end
    if player.state == PlayerStateType.BuildCraft or player.state == PlayerStateType.BuildTurret then return end

    local renderer = UIRenderer()

    if not mission.data.custom.wreckagePieceIds then
        mission.Log(_MethodName, "ПРЕДУПРЕЖДЕНИЕ: не удалось найти идентификаторы обломков")
        return
    end

    for _, wreckId in pairs(mission.data.custom.wreckagePieceIds) do
        local entity = Entity(wreckId)
        if not entity then return end

        if entity:hasScript("llteside5search.lua") then
            local _ContainerMarkOrange = ESCCUtil.getSaneColor(255, 173, 0)

            renderer:renderEntityTargeter(entity, _ContainerMarkOrange)
            renderer:renderEntityArrow(entity, 30, 10, 250, _ContainerMarkOrange)
        end
    end

    renderer:display()
end

-- Вызов клиентских/серверных функций
local llte_sidemission_getLoc = getMissionLocation
function getMissionLocation()
    local _Locations = {}
    if mission.data.custom.optionalObjectiveCompleted then
        table.insert(_Locations, ivec2(mission.data.location.x, mission.data.location.y))
    else
        for _, _Loc in pairs(mission.data.custom.locations) do
            table.insert(_Locations, ivec2(_Loc.x, _Loc.y))
        end
    end

    return unpack(_Locations)
end

function registerMarkWreckages()
    local _MethodName = "Регистрация пометки обломков"
    if onClient() then
        _MethodName = _MethodName .. " [КЛИЕНТ]"
        mission.Log(_MethodName, "Регистрация обратного вызова onPreRenderHud.")

        local _Player = Player()
        if _Player:registerCallback("onPreRenderHud", "onMarkWreckages") == 1 then
            mission.Log(_MethodName, "ПРЕДУПРЕЖДЕНИЕ: не удалось добавить обратный вызов prerender к скрипту.")
        end
    else
        _MethodName = _MethodName .. " [СЕРВЕР]"
        mission.Log(_MethodName, "Вызов на клиенте")

        invokeClientFunction(Player(), "registerMarkWreckages")
    end
end

function foundCodes()
    local _MethodName = "Коды найдены"

    if onClient() then
        mission.Log(_MethodName, "Вызов на клиенте")
        mission.Log(_MethodName, "Отмена регистрации обратного вызова и повторный вызов на сервере.")

        local _Player = Player()
        if _Player:unregisterCallback("onPreRenderHud", "onMarkWreckages") == 1 then
            mission.Log(_MethodName, "ПРЕДУПРЕЖДЕНИЕ: не удалось отменить регистрацию обратного вызова prerender для скрипта.")
        end

        showMissionUpdated("Уничтожение укреплённых пиратов")

        invokeServerFunction("foundCodes")
    else
        mission.Log(_MethodName, "Вызов на сервере")
    end

    mission.data.description[4].fulfilled = true
    mission.data.custom.optionalObjectiveCompleted = true
end
callable(nil, "foundCodes")

--endregion