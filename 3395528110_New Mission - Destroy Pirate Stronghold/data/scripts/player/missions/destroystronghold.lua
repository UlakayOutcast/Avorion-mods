--[[
    Уничтожить пиратский форпост
    ПРИМЕЧАНИЯ:
        - Общая версия побочной миссии 5 из LLTE
]]
package.path = package.path .. ";data/scripts/lib/?.lua"
package.path = package.path .. ";data/scripts/?.lua"

include("callable")
include("randomext")
include("structuredmission")
include("stringutility")

ESCCUtil = include("esccutil")

local SectorGenerator = include ("SectorGenerator")
local PirateGenerator = include("pirategenerator")
local Balancing = include ("galaxy")
local SpawnUtility = include ("spawnutility")
local ShipUtility = include ("shiputility")
local Placer = include ("placer")
local UpgradeGenerator = include ("upgradegenerator")

mission._Debug = 0
mission._Name = "Уничтожить пиратский форпост"

--region #INIT

--Стандартные данные миссии.
mission.data.brief = mission._Name
mission.data.title = mission._Name
mission.data.autoTrackMission = true
mission.data.description = {
    { text = "Вы получили следующий запрос от ${giverTitle} из сектора ${sectorName}:" }, --Заполнитель
    { text = "..." }, --Заполнитель
    { text = "Уничтожьте аванпост в секторе (${x}:${y})", bulletPoint = true, fulfilled = false },
    { text = "(Необязательно) Группа защитников собирается в секторе (${xO}:${yO}). Уничтожьте их", bulletPoint = true, fulfilled = false },
    { text = "Обыщите обломки на предмет чего-нибудь интересного", bulletPoint = true, fulfilled = false, visible = false }
}
mission.data.accomplishMessage = "..."

--Некоторые другие пользовательские данные, которые необходимо инициализировать здесь, поскольку они нужны как на стороне клиента, так и на стороне сервера, иначе мы получим странные ошибки в другом месте скрипта.
mission.data.custom.locations = {}
mission.data.custom.wreckagePieceIds = {}
mission.data.custom.wreckageScriptPath = "player/missions/destroystronghold/searchwreckage.lua"

local DestroyStronghold_init = initialize
function initialize(_Data_in)
    local _MethodName = "initialize"
    mission.Log(_MethodName, "Начинаем...")

    if onServer()then
        if not _restoring then
            mission.Log(_MethodName, "Вызов на сервере - dangerLevel : " .. tostring(_Data_in.dangerLevel))

            local _X, _Y = _Data_in.location.x, _Data_in.location.y
            local _Xo, _Yo = _Data_in.optLocation.x, _Data_in.optLocation.y

            local _Sector = Sector()
            local _Giver = Entity(_Data_in.giver)
            --[[=====================================================
                ПОЛЬЗОВАТЕЛЬСКИЕ ДАННЫЕ МИССИИ:
                .dangerLevel
                .locations
                .optlocation
                .pirateLevel
                .maxDefenders
                .defenderRespawnTime
                .freighterRespawnTime
                .freighterSupply
                .freighterSupplyTransfer
                .freighterScale
                .optionalPiratesGenerated
                .optionalPiratesTaunted
                .optionalPiratesAllDestroyed
                .wreckagePieceIds
                .optionalObjectiveCompleted
                .builtMainSector
                .militaryStationid
                .forcedDefenderScale
            =========================================================]]
            mission.data.custom.dangerLevel = _Data_in.dangerLevel
            mission.data.custom.locations = {}
            table.insert(mission.data.custom.locations, _Data_in.location)
            table.insert(mission.data.custom.locations, _Data_in.optLocation)
            mission.data.custom.optlocation = _Data_in.optLocation
            mission.data.custom.optionalObjectiveCompleted = false
            mission.data.custom.optionalObjectiveInvoked = false
            mission.data.custom.pirateLevel = Balancing_GetPirateLevel(_Data_in.location.x, _Data_in.location.y)
            mission.data.custom.maxDefenders = 4
            mission.data.custom.defenderRespawnTime = 150
            mission.data.custom.forcedDefenderScale = 2.5
            mission.data.custom.freighterRespawnTime = 125
            mission.data.custom.freighterSupply = 500
            mission.data.custom.freighterSupplyTransfer = 50
            mission.data.custom.freighterScale = 8
            --Регулировка в зависимости от уровня опасности. Такие вещи, как более быстрая передача припасов и т. д., можно обрабатывать, проверяя сам уровень опасности.
            if mission.data.custom.dangerLevel >= 5 then
                mission.data.custom.forcedDefenderScale = 3.5
            end
            if mission.data.custom.dangerLevel >= 6 then
                mission.data.custom.freighterRespawnTime = mission.data.custom.freighterRespawnTime - 30
                mission.data.custom.freighterScale = mission.data.custom.freighterScale + 2
            end
            if mission.data.custom.dangerLevel >= 8 then
                mission.data.custom.freighterSupplyTransfer = 75
                mission.data.custom.freighterScale = mission.data.custom.freighterScale + 2
                mission.data.custom.forcedDefenderScale = 5
            end
            if mission.data.custom.dangerLevel == 10 then
                mission.data.custom.maxDefenders = mission.data.custom.maxDefenders + 1
                mission.data.custom.defenderRespawnTime = mission.data.custom.defenderRespawnTime - 30
                mission.data.custom.freighterSupply = mission.data.custom.freighterSupply + 500
                mission.data.custom.freighterSupplyTransfer = 150
                mission.data.custom.freighterScale = mission.data.custom.freighterScale + 2
                mission.data.custom.forcedDefenderScale = 10
            end
            PirateGenerator.pirateLevel = mission.data.custom.pirateLevel

            mission.data.description[1].arguments = { sectorName = _Sector.name, giverTitle = _Giver.translatedTitle }
            mission.data.description[2].text = _Data_in.initialDesc
            mission.data.description[2].arguments = { x = _X, y = _Y }
            mission.data.description[3].arguments = { x = _X, y = _Y }
            mission.data.description[4].arguments = { xO = _Xo, yO = _Yo }

            mission.data.accomplishMessage = _Data_in.winMsg

            --Запустить стандартную инициализацию
            DestroyStronghold_init(_Data_in)
        else
            --Восстановление
            DestroyStronghold_init()
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
--Постарайтесь держать вызовы таймера вне onBeginServer / onSectorEntered / onSectorArrivalConfirmed, если они не повторяются и не длятся 30 секунд или меньше.

mission.globalPhase.onAbandon = function()
    if mission.data.location then
        dumpMilitaryStationCargo()
        runFullSectorCleanup(true)
    end
end

mission.globalPhase.onFail = function()
    --Реального условия "провала" нет, но мы все равно оставим это на всякий случай.
    if mission.data.location then
        dumpMilitaryStationCargo()
        runFullSectorCleanup(true)
    end
end

mission.globalPhase.onAccomplish = function()
    if mission.data.location then
        if atTargetLocation() then
            ESCCUtil.allPiratesDepart()
        end
        runFullSectorCleanup(false)
    end
end

mission.globalPhase.onSectorEntered = function(_X, _Y)
    local _MethodName = "Глобальная фаза при входе в локацию"
    mission.Log(_MethodName, "Начинаем...")

    local _OptX, _OptY = mission.data.custom.optlocation.x, mission.data.custom.optlocation.y
    if _OptX and _OptY then
        if _X == _OptX and _Y == _OptY then
            mission.Log(_MethodName, "Вход в необязательную целевую локацию - запуск обратных вызовов onOptionalLocationEntered")

            if mission.currentPhase.onOptionalLocationEntered then mission.currentPhase.onOptionalLocationEntered(_X, _Y) end
            if mission.globalPhase.onOptionalLocationEntered then mission.globalPhase.onOptionalLocationEntered(_X, _Y) end
        end
    end
end

mission.globalPhase.onSectorArrivalConfirmed = function(_X, _Y)
    local _MethodName = "Глобальная фаза при подтверждении прибытия в локацию"
    mission.Log(_MethodName, "Начинаем...")

    local _OptX, _OptY = mission.data.custom.optlocation.x, mission.data.custom.optlocation.y
    if _OptX and _OptY then
        if _X == _OptX and _Y == _OptY then
            mission.Log(_MethodName, "Подтверждено прибытие в необязательную целевую локацию - запуск обратных вызовов onOptionalLocationArrivalConfirmed")

            if mission.currentPhase.onOptionalLocationArrivalConfirmed then mission.currentPhase.onOptionalLocationArrivalConfirmed(_X, _Y) end
            if mission.globalPhase.onOptionalLocationArrivalConfirmed then mission.globalPhase.onOptionalLocationArrivalConfirmed(_X, _Y) end
        end
    end
end

mission.globalPhase.updateServer = function(_TimeStep)
    local _MethodName = "Глобальная фаза обновления сервера"

    local _LX, _LY = mission.data.custom.optlocation.x, mission.data.custom.optlocation.y
    if _LX and _LY then
        local _X, _Y = Sector():getCoordinates()
        if _LX == _X and _LY == _Y then
            --mission.Log(_MethodName, "Запуск необязательного обновления сервера локации.")
            if mission.currentPhase.optionalUpdateServer then mission.currentPhase.optionalUpdateServer(_TimeStep) end
        else
            --mission.Log(_MethodName, "_LX: " .. tostring(_LX) .. " _LY: " .. tostring(_LY) .. " не соответствуют _X: " .. tostring(_X) .. " _Y: " .. tostring(_Y))
        end
    else
        mission.Log(_MethodName, "ПРЕДУПРЕЖДЕНИЕ - Не удалось получить текущие координаты x / y миссии.")
    end
end

mission.phases[1] = {}
mission.phases[1].timers = {}
mission.phases[1].noBossEncountersTargetSector = true
mission.phases[1].onTargetLocationEntered = function(_X, _Y) 
    local _MethodName = "Фаза 1 при входе в целевую локацию"
    mission.Log(_MethodName, "Начинаем...")

    --Построить сектор, затем запустить скрипты подкрепления и поставки.
    buildObjectiveSector(_X, _Y)
    mission.Log(_MethodName, "Запуск скриптов.")

    local _Sector = Sector()

    local _MilitaryStation = Entity(mission.data.custom.militaryStationid)
    local _SetOptionalObjectiveInvoked = false
    --ДОБАВИТЬ КОНТРОЛЛЕР ЗАЩИТЫ + СКРИПТ КОНТРОЛЛЕРА ПОСТАВКИ
    if not _Sector:hasScript("sector/background/defensecontroller.lua") then
        --Данные контроллера защиты
        local _defCycleTime = mission.data.custom.defenderRespawnTime
        if mission.data.custom.optionalObjectiveCompleted then
            mission.Log(_MethodName, "Необязательная цель выполнена при входе - увеличение времени цикла защитника.")
            _defCycleTime = _defCycleTime + 15
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
        _DCD._SupplyFactor = 0.1 --+10% усиление на уровень.
        if mission.data.custom.dangerLevel >= 8 then
            _DCD._SwapTables = true
            _DCD._SwapOnModulo = 3
        end
        if mission.data.custom.dangerLevel == 10 then
            _DCD._AddToEachWave = { "Jammer" }
        end

        _Sector:addScript("sector/background/defensecontroller.lua", _DCD)
        mission.Log(_MethodName, "Контроллер защиты успешно прикреплен.")
    else
        if mission.data.custom.optionalObjectiveCompleted and not mission.data.custom.optionalObjectiveInvoked then
            mission.Log(_MethodName, "вызвана необязательная цель - установка для скрипта контроллера защиты сектора взломанных кодов и увеличение цикла")
            _Sector:invokeFunction("sector/background/defensecontroller.lua", "setCodesCracked", true)
            _Sector:invokeFunction("sector/background/defensecontroller.lua", "incrementCycleTime", 15)
            _SetOptionalObjectiveInvoked = true
        end
    end

    if not _Sector:hasScript("sector/background/shipmentcontroller.lua") then
        --Данные контроллера поставки
        local _shipCycleTime = mission.data.custom.freighterRespawnTime
        if mission.data.custom.optionalObjectiveCompleted then
            mission.Log(_MethodName, "Необязательная цель выполнена при входе - увеличение времени цикла поставки.")
            _shipCycleTime = _shipCycleTime + 15
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
        mission.Log(_MethodName, "Контроллер поставки успешно прикреплен.")
    else
        if mission.data.custom.optionalObjectiveCompleted and not mission.data.custom.optionalObjectiveInvoked then
            mission.Log(_MethodName, "вызвана необязательная цель - установка для скрипта контроллера поставки сектора взломанных кодов и увеличение цикла")
            _Sector:invokeFunction("sector/background/shipmentcontroller.lua", "setCodesCracked", true)
            _Sector:invokeFunction("sector/background/shipmentcontroller.lua", "incrementCycleTime", 15)
            _SetOptionalObjectiveInvoked = true
        end
    end

    if not _MilitaryStation:hasScript("entity/stationsiegegun.lua") then
        --Данные осадного орудия
        local _SGD = {}
        _SGD._CodesCracked = mission.data.custom.optionalObjectiveCompleted
        _SGD._Velocity = 150
        _SGD._ShotCycle = 30
        _SGD._ShotCycleSupply = 1000
        _SGD._ShotCycleTimer = 30
        _SGD._SupplyPerLevel = 4000 --Это слишком быстро увеличивает урон при 500 за уровень - он уже будет наносить +40% урона к выстрелу №2.
        _SGD._SupplyFactor = 0.1
        _SGD._FragileShots = false

        local _Dist = ESCCUtil.getDistanceToCenter(_X, _Y)
        --Ограничить минимальный урон до 10 тыс.
        local _Damage = math.max((500 - _Dist) * 10000, 10000)
        if _Dist < 80 then
            _Damage = _Damage + ((80 - _Dist) * 125000)
        end
        _Damage = _Damage * (1 + (mission.data.custom.dangerLevel / 20))
        _SGD._BaseDamagePerShot = _Damage

        _MilitaryStation:addScript("entity/stationsiegegun.lua", _SGD)
        mission.Log(_MethodName, "Прикреплен скрипт осадного орудия к военному аванпосту.")
    else
        if mission.data.custom.optionalObjectiveCompleted and not mission.data.custom.optionalObjectiveInvoked then
            mission.Log(_MethodName, "вызвана необязательная цель - установка для скрипта военной станции взломанных кодов")
            _MilitaryStation:invokeFunction("entity/stationsiegegun.lua", "setCodesCracked", true)
            _SetOptionalObjectiveInvoked = true
        end
    end

    if _SetOptionalObjectiveInvoked then
        mission.data.custom.optionalObjectiveInvoked = true
    end
end

mission.phases[1].updateTargetLocationServer = function(timeStep)
    local _MethodName = "Фаза 1 Обновление целевой локации"

    if ESCCUtil.countEntitiesByValue("_destroystronghold_mainobjective") == 0 and mission.data.custom.builtMainSector then
        mission.Log(_MethodName, "Аванпост уничтожен. Запуск условия победы.")

        --Добавить скрипты удаления ко всем пиратским сущностям в секторе.
        local _Pirates = {Sector():getEntitiesByScriptValue("is_pirate")}
        for _, _P in pairs(_Pirates) do
            MissionUT.deleteOnPlayersLeft(_P)
        end

        finishAndReward()
    end
end

--Optional sector calls.
mission.phases[1].onOptionalLocationEntered = function(_X, _Y)
    local _MethodName = "Фаза 1. Вход в дополнительную локацию"
    mission.Log(_MethodName, "Начало...")

    if not mission.data.custom.optionalPiratesGenerated then
        mission.Log(_MethodName, "Генерация дополнительных пиратов.")

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
    local _MethodName = "Фаза 1. Подтверждено прибытие в дополнительную локацию"
    mission.Log(_MethodName, "Начало...")

    if not mission.data.custom.optionalPiratesTaunted then 
        mission.Log(_MethodName, "Дополнительные пираты не насмехались. Отправка насмешки.")

        local _Pirates = {Sector():getEntitiesByScriptValue("is_pirate")}
        if _Pirates then
            mission.Log(_MethodName, "Отправка пиратской насмешки")
            local _Lines = {
                "Кто нас продал? Мы убьем вас после того, как разберемся с этим!",
                "Откуда они узнали о кодах? Убейте их быстро!",
                "Ваше убийство будет адекватной формой безопасности.",
                "Как вы нас нашли? Неважно, мы убьем вас!",
                "Думаю, нам не нужно будет беспокоиться о кодах, если вы умрете.",
                "Они, должно быть, охотятся за кодами! Убейте их всех!",
                "Что это? Мы убьем вас!"
            }

            Sector():broadcastChatMessage(_Pirates[1], ChatMessageType.Chatter, getRandomEntry(_Lines))
        end

        mission.data.custom.optionalPiratesTaunted = true
    end
end

mission.phases[1].optionalUpdateServer = function(_TimeStep)
    local _MethodName = "Серверное обновление необязательного задания"

    --Мы не можем использовать onDestroyed для этого, потому что он все равно будет думать, что один остался, когда последний будет уничтожен.
    if ESCCUtil.countEntitiesByValue("is_pirate") == 0 and not mission.data.custom.optionalPiratesAllDestroyed then
        mission.Log(_MethodName, "Все дополнительные пираты уничтожены. Прикрепляем скрипты поиска обломков к обломкам.")

        local _WreckSizes = { 1000, 900, 800, 700, 600, 500, 400, 300, 200, 150, 100, 50, 40, 30, 20, 10 }
        local _TargetWreckSize = 1000
        local _Rgen = ESCCUtil:getRand()

        --Пытается найти самый большой размер обломков (по количеству блоков), которых не менее 5.
        local _Wreckages = {Sector():getEntitiesByType(EntityType.Wreckage)}
        mission.Log(_MethodName, "Найдено обломков: " .. tostring(#_Wreckages))
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

        --Получить 5 случайных обломков из таблицы.
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

        --Прикрепляет скрипт ко всем подходящим обломкам, который позволяет их обыскивать, и отмечает их в пользовательском интерфейсе игрока.
        for _, _Wreck in pairs(_CandidateWrecks) do
            table.insert(mission.data.custom.wreckagePieceIds, _Wreck.id)
            _Wreck:addScriptOnce(mission.data.custom.wreckageScriptPath)
            _Wreck:setValue("_destroystronghold_optionalwreck_targetplayer", Player().index)
        end
        local _TargetWreck = Entity(mission.data.custom.wreckagePieceIds[_Rgen:getInt(1, #mission.data.custom.wreckagePieceIds)])
        _TargetWreck:setValue("_destroystronghold_optionalwreck_hascode", true)

        registerMarkWreckages()
        showMissionUpdated(mission._Name)
        mission.data.description[4].fulfilled = true
        mission.data.description[5].visible = true

        sync()
        mission.data.custom.optionalPiratesAllDestroyed = true
    end
end

--endregion

--region #SERVER CALLS

function buildObjectiveSector(_X, _Y)
    local _MethodName = "Построить сектор"

    if not mission.data.custom.builtMainSector then
        mission.Log(_MethodName, "Строительство главного сектора.")

        --Сектор всегда должен иметь 3-5 небольших астероидных полей, 1 большое астероидное поле и военный аванпост + 12 стандартных защитников.
        local generator = SectorGenerator(_X, _Y)
        local _Rgen = ESCCUtil.getRand()
        for _ = 1, _Rgen:getInt(3, 5) do
            generator:createSmallAsteroidField()
        end
        generator:createAsteroidField()

        --Военный аванпост - избавляемся от всего груза и всех различных скриптов и т.д.
        local _Faction = Galaxy():getPirateFaction(mission.data.custom.pirateLevel)
        local _Station = generator:createMilitaryBase(_Faction)
        _Station.position = Matrix()
        _Station:setValue("is_pirate", true)
        _Station:setValue("_destroystronghold_mainobjective", true)
        local _StationSphere = _Station:getBoundingSphere()
        local _AsteroidRemovalSphere = Sphere(_StationSphere.center, _StationSphere.radius * 15) 
        local _RemovalCandidates = {Sector():getEntitiesByLocation(_AsteroidRemovalSphere)}
        mission.Log(_MethodName, "Найдено " .. #_RemovalCandidates .. " кандидатов на удаление. Любые астероиды в этом списке будут удалены.")
        for _, _En in pairs(_RemovalCandidates) do
            if _En.isAsteroid then
                --Не ставьте ИИ в тупик.
                Sector():deleteEntity(_En)
            end
        end
        --Добавить несколько турелей.
        ShipUtility.addScalableArtilleryEquipment(_Station, 4.0, 1.0, false)
        ShipUtility.addScalableArtilleryEquipment(_Station, 2.0, 1.0, false)
        ShipUtility.addScalableArtilleryEquipment(_Station, 2.0, 1.0, false)
        --Удалить скрипты.
        _Station:removeScript("icon.lua")
        _Station:removeScript("consumer.lua")
        _Station:removeScript("backup.lua")
        _Station:removeScript("bulletinboard.lua")
        _Station:removeScript("missionbulletins.lua")
        _Station:removeScript("story/bulletins.lua")
        Sector():removeScript("traders.lua")
        --Установить ИИ на агрессивный.
        local _ShipAI = ShipAI(_Station)
        _ShipAI:setAggressive()
        --Добавить пилотов, чтобы он мог использовать истребители.
        _Station:addCrew(60, CrewMan(CrewProfessionType.Pilot))
        --Никакого абордажа.
        Boarding(_Station).boardable = false
        --Удалить груз, если уровень опасности меньше 8 или если мы слишком далеко за пределами барьера.
        local _Dist = ESCCUtil.getDistanceToCenter(_X, _Y)
        if mission.data.custom.dangerLevel < 8 or _Dist > 175 then
            local _StationBay = CargoBay(_Station)
            _StationBay:clear()
        end
        --Изменить на "Крепость вооружений" и усилить щиты / hp. Фактически 50% усиление урона за счет большего количества орудий.
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
        --Увеличить HP / щит станции.
        local _Dura = Durability(_Station)
        if _Dura then
            _Dura.maxDurabilityFactor = _Dura.maxDurabilityFactor * _DuraFactor
        end

        local _Shield = Shield(_Station)
        if _Shield then
            _Shield.maxDurabilityFactor = _Shield.maxDurabilityFactor * _DuraFactor
        end

        --Наконец, (возможно) добавить военный TCS в таблицу добычи станции.
        if _Rgen:test(0.25) then
            local _upgradeGenerator = UpgradeGenerator()
            local _upgradeRarities = getSectorRarityTables(_X, _Y, _upgradeGenerator)
            local _seedInt = _Rgen:getInt(1, 20000)
            Loot(_Station):insert(SystemUpgradeTemplate("data/scripts/systems/militarytcs.lua", Rarity(getValueFromDistribution(_upgradeRarities)), Seed(_seedInt)))
        end

        mission.data.custom.militaryStationid = _Station.id

        --8 начальных защитников из стандартной таблицы угроз.
        local _InitialDefenders = 8
        --На 10 уровне опасности мы получаем два дополнительных.
        if mission.data.custom.dangerLevel == 10 then
            _InitialDefenders = _InitialDefenders + 2
        end
        local _PirateTable = ESCCUtil.getStandardWave(mission.data.custom.dangerLevel, _InitialDefenders, "Standard")
        local _CreatedPirateTable = {}

        for _, _Pirate in pairs(_PirateTable) do
            table.insert(_CreatedPirateTable, PirateGenerator.createPirateByName(_Pirate, PirateGenerator.getGenericPosition()))
        end

        SpawnUtility.addEnemyBuffs(_CreatedPirateTable)

        Placer.resolveIntersections()

        mission.data.custom.cleanUpSector = true

        showMissionUpdated(mission._Name)

        mission.data.custom.builtMainSector = true
    end
end

function dumpMilitaryStationCargo()
    if atTargetLocation() then
       --Заброшено в секторе.
        --Выгрузить весь груз на военной базе, если игрок попытается убить ее после отказа, чтобы облегчить задачу.
        --Шутка над ними, хотя. Контроллер защиты не исчезнет, когда это будет удалено :D
        local _Station = Entity(mission.data.custom.militaryStationid)

        if _Station and valid(_Station) then
            local _StationBay = CargoBay(_Station)
            _StationBay:clear()
        end
    end
end

function getSectorRarityTables(_X, _Y, _upgradeGenerator)
    local _dangerLevel = mission.data.custom.dangerLevel
    local _rarities = _upgradeGenerator:getSectorRarityDistribution(_X, _Y)
    _rarities[-1] = 0 --no petty
    _rarities[0] = 0 --no common
    _rarities[1] = 0 --no uncommon
    _rarities[2] = 0 --no rare

    local _dangerFactors = {
        { _exceptional = 1, _exotic = 1}, --1
        { _exceptional = 1, _exotic = 1}, --2
        { _exceptional = 1, _exotic = 1}, --3
        { _exceptional = 1, _exotic = 1}, --4
        { _exceptional = 0.5, _exotic = 1}, --5
        { _exceptional = 0.5, _exotic = 1}, --6
        { _exceptional = 0.5, _exotic = 0.75}, --7
        { _exceptional = 0.25, _exotic = 0.75}, --8
        { _exceptional = 0.25, _exotic = 0.5}, --9
        { _exceptional = 0.12, _exotic = 0.5} --10
    }
    
    _rarities[3] = _rarities[3] * _dangerFactors[_dangerLevel]._exceptional
    _rarities[4] = _rarities[4] * _dangerFactors[_dangerLevel]._exotic

    return _rarities
end

function finishAndReward()
    local _MethodName = "Завершение и награда"
    mission.Log(_MethodName, "Выполнение условия победы.")

    reward()
    accomplish()
end

--endregion

--region #CLIENT / SERVER CALLS

local DestroyStronghold_getLoc = getMissionLocation
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
    local _MethodName = "Регистрация отметок обломков"
    if onClient() then
        _MethodName = _MethodName .. " [КЛИЕНТ]"
        mission.Log(_MethodName, "Регистрация обратного вызова onPreRenderHud.")

        local _Player = Player()
        if _Player:registerCallback("onPreRenderHud", "onMarkWreckages") == 1 then
            mission.Log(_MethodName, "ПРЕДУПРЕЖДЕНИЕ - Не удалось прикрепить обратный вызов prerender к скрипту.")
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
            mission.Log(_MethodName, "ПРЕДУПРЕЖДЕНИЕ - Не удалось отсоединить обратный вызов prerender от скрипта.")
        end

        showMissionUpdated(mission._Name)

        invokeServerFunction("foundCodes")
    else
        mission.Log(_MethodName, "Вызов на сервере")
    end
    
    mission.data.description[5].fulfilled = true
    mission.data.custom.optionalObjectiveCompleted = true
end
callable(nil, "foundCodes")

--endregion

--region #CLIENT CALLS

function onMarkWreckages()
    local _MethodName = "Отметка обломков"

    local player = Player()
    if not player then return end
    if player.state == PlayerStateType.BuildCraft or player.state == PlayerStateType.BuildTurret then return end

    local renderer = UIRenderer()

    if not mission.data.custom.wreckagePieceIds then 
        mission.Log(_MethodName, "ПРЕДУПРЕЖДЕНИЕ - Не удалось найти идентификаторы обломков")
        return 
    end

    for _, wreckId in pairs(mission.data.custom.wreckagePieceIds) do
        local entity = Entity(wreckId)
        if not entity then return end
        
        if entity:hasScript(mission.data.custom.wreckageScriptPath) then
            local _ContainerMarkOrange = ESCCUtil.getSaneColor(255, 173, 0)

            renderer:renderEntityTargeter(entity, _ContainerMarkOrange)
            renderer:renderEntityArrow(entity, 30, 10, 250, _ContainerMarkOrange)
        end
    end

    renderer:display()
end

--endregion

--region #MAKEBULLETIN CALL

function formatWinMessage(_Station)
    local _Faction = Faction(_Station.factionIndex)
    local _Aggressive = _Faction:getTrait("aggressive")
    local _MsgType = 1 --1 = Нейтральный / 2 = Агрессивный / 3 = Мирный

    if _Aggressive > 0.5 then
        _MsgType = 2
    elseif _Aggressive <= -0.5 then
        _MsgType = 3
    end

    local _Msgs = 
    { 
        "Спасибо. Вот ваша награда, как и было обещано.",
        "Спасибо, что разобрались с этими отбросами. Мы перевели награду на ваш счет.",
        "Спасибо за ваши хлопоты. Мы перевели награду на ваш счет."
    }

    return _Msgs[_MsgType]
end

function formatDescription(_Station, _DangerLevel)
    local _Faction = Faction(_Station.factionIndex)
    local _Aggressive = _Faction:getTrait("aggressive")

    local _DescriptionType = 1 --Нейтральный
    if _Aggressive > 0.5 then
        _DescriptionType = 2 --Агрессивный.
    elseif _Aggressive <= -0.5 then
        _DescriptionType = 3 --Мирный.
    end

    local _DescLine1Options = { 
        "Есть пиратская база, которая мешает нашим ближайшим операциям. Мы хотели бы, чтобы вы ее уничтожили. Наша разведка говорит, что они довольно хорошо окопались, но мы заплатим вам так же хорошо за ваши усилия.",
        "Какие-то пиратские отбросы решили построить крепость в нашей юрисдикции! Мы могли бы легко их уничтожить, но наши силы заняты завоеванием соседнего выскочки, и нам просто некогда. Поэтому мы обращаемся к независимым капитанам за помощью.",
        "Недавно мы получили разведданные о том, что какие-то пираты создали опорный пункт на нашей территории. Наши силы самообороны предназначены только для этого - самообороны. Мы не можем выделить силы для наступления на них. Вот тут-то вы и пригодитесь."
    }
    local _DescLine2Options = { 
        "\n\nНесколько наших предыдущих попыток уничтожить их закончились неудачей. Действуйте с осторожностью.",
        "\n\nЭто на голову выше обычных пиратов. Ожидайте, что вам придется задействовать больше сил в операции.",
        "\n\nПираты особенно сильны. Убедитесь, что вы атакуете с достаточным количеством кораблей, чтобы справиться с ними."
    }
    local _DescLine3Options = { 
        "\n\nВы найдете базу по координатам (${x}:${y}).",
        "\n\nВы найдете базу по координатам (${x}:${y}). Не оставляйте в живых никого.",
        "\n\nВы найдете базу по координатам (${x}:${y}). Пожалуйста, разберитесь с этим."
    }

    local _DescLine1 = _DescLine1Options[_DescriptionType]
    local _DescLine2 = ""
    if _DangerLevel >= 7 then
        _DescLine2 = _DescLine2Options[_DescriptionType]
    end
    local _DescLine3 = _DescLine3Options[_DescriptionType]

    local _FinalDescription = _DescLine1 .. _DescLine2 .. _DescLine3

    return _FinalDescription
end

mission.makeBulletin = function(_Station)
    local _MethodName = "Make Bulletin"
    --We don't need a specific type of sector here. Just an empty one that's on the same side of the barrier as the questgiver.
    local _sector = Sector()
    local _Rgen = ESCCUtil.getRand()
    local target = {}
    local optTarget = {}
    local x, y = _sector:getCoordinates()
    local insideBarrier = MissionUT.checkSectorInsideBarrier(x, y)
    target.x, target.y = MissionUT.getSector(x, y, 5, 17, false, false, false, false, insideBarrier)
    local optTargetOK = false
    local breakout = 0 --safety breakout so we don't get locked in a while loop forever
    while not optTargetOK do
        optTarget.x, optTarget.y = MissionUT.getSector(x, y, 4, 10, false, false, false, false, insideBarrier)
        if optTarget.x ~= target.x or optTarget.y ~= target.y or breakout > 100 then
            optTargetOK = true
        end
        breakout = breakout + 1
    end

    if not target.x or not target.y or not optTarget.x or not optTarget.y then
        mission.Log(_MethodName, "Target.x or Target.y not set - returning nil.")
        return 
    end

    local _DangerLevel = _Rgen:getInt(1, 10)

    local _Difficulty = "Сложный"
    if _DangerLevel >=  7 then
        _Difficulty = "Экстремальный"
    end
    
    local _Description = formatDescription(_Station, _DangerLevel)
    local _WinMsg = formatWinMessage(_Station)

    local _BaseReward = 170000
    if _DangerLevel >= 6 then
        _BaseReward = _BaseReward + 6000
    end
    if _DangerLevel >= 8 then
        _BaseReward = _BaseReward + 9000
    end
    if _DangerLevel == 10 then
        _BaseReward = _BaseReward + 12000
    end
    if insideBarrier then
        _BaseReward = _BaseReward * 2
    end

    reward = _BaseReward * Balancing.GetSectorRewardFactor(_sector:getCoordinates()) --SET REWARD HERE
    reputation = 6000
    if _DangerLevel == 10 then
       reputation = reputation + 2000 
    end

    local bulletin =
    {
        -- data for the bulletin board
        brief = mission.data.brief,
        title = mission.data.title,
        icon = mission.data.icon,
        description = _Description,
        difficulty = _Difficulty,
        reward = "¢${reward}",
        script = "missions/destroystronghold.lua",
        formatArguments = {x = target.x, y = target.y, reward = createMonetaryString(reward)},
        msg = "Thank you. The pirate outpost is located at \\s(%1%:%2%).",
        giverTitle = _Station.title,
        giverTitleArgs = _Station:getTitleArguments(),
        onAccept = [[
            local self, player = ...
            player:sendChatMessage(Entity(self.arguments[1].giver), 0, self.msg, self.formatArguments.x, self.formatArguments.y)
        ]],

        -- data that's important for our own mission
        arguments = {{
            giver = _Station.index,
            location = target,
            optLocation = optTarget,
            reward = {credits = reward, relations = reputation, paymentMessage = "Earned %1% for destroying the stronghold."},
            punishment = {relations = 8000 },
            dangerLevel = _DangerLevel,
            initialDesc = _Description,
            winMsg = _WinMsg
        }},
    }

    return bulletin
end

--endregion
mission.makeBulletin = function(_Station)
    local _MethodName = "Make Bulletin"
    --Здесь нам не нужен конкретный тип сектора. Просто пустой, который находится на той же стороне барьера, что и квестодатель.
    local _sector = Sector()
    local _Rgen = ESCCUtil.getRand()
    local target = {}
    local optTarget = {}
    local x, y = _sector:getCoordinates()
    local insideBarrier = MissionUT.checkSectorInsideBarrier(x, y)
    target.x, target.y = MissionUT.getSector(x, y, 5, 17, false, false, false, false, insideBarrier)
    local optTargetOK = false
    local breakout = 0 --Предохранительный выход, чтобы мы не застряли в цикле навсегда
    while not optTargetOK do
        optTarget.x, optTarget.y = MissionUT.getSector(x, y, 4, 10, false, false, false, false, insideBarrier)
        if optTarget.x ~= target.x or optTarget.y ~= target.y or breakout > 100 then
            optTargetOK = true
        end
        breakout = breakout + 1
    end

    if not target.x or not target.y or not optTarget.x or not optTarget.y then
        mission.Log(_MethodName, "Target.x or Target.y not set - returning nil.")
        return 
    end

    local _DangerLevel = _Rgen:getInt(1, 10)

    local _Difficulty = "Сложный"
    if _DangerLevel >=  7 then
        _Difficulty = "Экстремальный"
    end
    
    local _Description = formatDescription(_Station, _DangerLevel)
    local _WinMsg = formatWinMessage(_Station)

    local _BaseReward = 170000
    if _DangerLevel >= 6 then
        _BaseReward = _BaseReward + 6000
    end
    if _DangerLevel >= 8 then
        _BaseReward = _BaseReward + 9000
    end
    if _DangerLevel == 10 then
        _BaseReward = _BaseReward + 12000
    end
    if insideBarrier then
        _BaseReward = _BaseReward * 2
    end

    reward = _BaseReward * Balancing.GetSectorRewardFactor(_sector:getCoordinates()) --УСТАНОВИТЬ НАГРАДУ ЗДЕСЬ
    reputation = 6000
    if _DangerLevel == 10 then
       reputation = reputation + 2000 
    end

    local bulletin =
    {
        -- data for the bulletin board
        brief = mission.data.brief,
        title = mission.data.title,
        icon = mission.data.icon,
        description = _Description,
        difficulty = _Difficulty,
        reward = "¢${reward}",
        script = "missions/destroystronghold.lua",
        formatArguments = {x = target.x, y = target.y, reward = createMonetaryString(reward)},
        msg = "Спасибо. Пиратский форпост находится в \\s(%1%:%2%).",
        giverTitle = _Station.title,
        giverTitleArgs = _Station:getTitleArguments(),
        onAccept = [[
            local self, player = ...
            player:sendChatMessage(Entity(self.arguments[1].giver), 0, self.msg, self.formatArguments.x, self.formatArguments.y)
        ]],

        -- data that's important for our own mission
        arguments = {{
            giver = _Station.index,
            location = target,
            optLocation = optTarget,
            reward = {credits = reward, relations = reputation, paymentMessage = "Earned %1% for destroying the stronghold."},
            punishment = {relations = 8000 },
            dangerLevel = _DangerLevel,
            initialDesc = _Description,
            winMsg = _WinMsg
        }},
    }

    return bulletin
end

--endregion
