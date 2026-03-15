--[[
    Побочная миссия ранга 1.
    Сопротивление бесполезно
    Это "Да здравствует ИМПЕРАТРИЦА", а не "Да здравствует ИМПЕРАТОР". Вы должны быть благодарны, что я вообще даю вам это задание.
    ДОПОЛНИТЕЛЬНЫЕ ТРЕБОВАНИЯ:
        - Игрок должен быть на стороне императора.
    ПРИМЕРНЫЙ ПЛАН:
        - Игрок направляется в указанное место.
        - Игрок встречает местную фракцию (выбирается случайно: 50% пираты, 50% местная фракция).
        - Если местная фракция ещё не воюет с игроком, она объявляет войну и устанавливает максимально отрицательную репутацию.
        - Игрок должен уничтожить все станции в секторе.
        - Фракция будет постоянно отправлять подкрепления, пока хотя бы одна станция остаётся.
    УРОВЕНЬ ОПАСНОСТИ:
        1+ - [Эти условия действуют независимо от уровня опасности]
            - Пираты будут использовать корабли высокой угрозы из соответствующей таблицы уровня опасности.
            - Фракции будут использовать стандартные корабли защиты с обычным спавном/уровнем опасности.
            - До 5 защитников могут присутствовать в любой момент времени.
            - Защитники будут возрождаться каждые 2 минуты, чтобы у игрока было время передохнуть, если он убьёт всех.
            - Если защитник слишком повреждён, он уйдёт в варп и позволит новому занять его место.
            - Всегда присутствует 1 станция, выбранная случайно между военным аванпостом, верфью и ремонтным доком.
            - 50% шанс получить вторую станцию, 50% шанс получить третью станцию (броски независимые).
        6 - [Эти условия действуют при уровне опасности 6 и выше]
            - Максимальное количество защитников увеличено на +1 (всего 6).
            - Шанс появления второй/третьей станции увеличен до 60%.
            - 7% шанс на каждый уровень опасности выше 5 включить авианосец в каждую волну (до максимума 35% на уровне 10).
        8 - [Эти условия действуют при уровне опасности 8 и выше]
            - Максимальное количество защитников увеличено на +1 (всего 7).
            - Шанс появления второй/третьей станции увеличен до 70%.
        10 - [Эти условия действуют при уровне опасности 10]
            - Максимальное количество защитников увеличено на +1 (всего 8).
            - Шанс появления второй/третьей станции увеличен до 80%.
            - Первая станция всегда будет военным аванпостом, и военный аванпост получает бонус урона турелей.
            - ЕСЛИ ФРАКЦИЯ: 3 тяжёлых защитника + корабль-блокатор появятся после уничтожения первой станции.
            - ЕСЛИ ПИРАТЫ: Палач появится после уничтожения первой станции.
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
local AsyncPirateGenerator = include("asyncpirategenerator")
local AsyncShipGenerator = include("asyncshipgenerator")
local Balancing = include("galaxy")
local SpawnUtility = include("spawnutility")
local ShipUtility = include("shiputility")
local Placer = include("placer")

mission._Debug = 0
mission._Name = "Сопротивление бесполезно"

-- Настройка данных миссии
local llte_sidemission_init = initialize
function initialize()
    local _MethodName = "Инициализация"
    if onServer() then
        if not _restoring then
            -- У нас нет доступа к данным объявления миссии, поэтому определяем здесь.
            local _Rgen = ESCCUtil.getRand()
            local x, y = Sector():getCoordinates()
            local insideBarrier = MissionUT.checkSectorInsideBarrier(x, y)
            local target = {}
            target.x, target.y = MissionUT.getSector(x, y, 6, 18, false, false, false, false, insideBarrier)

            if not target then
                mission.Log(_MethodName, "Не удалось найти подходящий сектор для миссии. Завершение скрипта.")
                terminate()
                return
            end

            local _Name = "Кавалеры"
            local _Faction = Galaxy():findFaction(_Name)

            -- Стандартные данные миссии.
            mission.data.brief = "Сопротивление бесполезно"
            mission.data.title = "Сопротивление бесполезно"
            mission.data.icon = "data/textures/icons/cavaliers.png"
            mission.data.description = {
                "Император Кавалеров попросил вас атаковать фракцию, которая отказывается подчиняться его правлению.",
                "Если вы решите выполнить это задание, это может иметь серьёзные последствия.",
                { text = "Уничтожьте аванпост фракции в секторе (${xLoc}:${yLoc})", arguments = {xLoc = target.x, yLoc = target.y}, bulletPoint = true, fulfilled = false }
            }

            local _RewardBase = 280000
            -- Пользовательские данные миссии:
            -- .dangerLevel
            -- .pirates
            -- .pirateLevel
            -- .maxDefenders
            -- .secondStation
            -- .thirdStation
            -- .builtMainSector
            -- .firstStationid
            -- .localFactionIndex
            -- .hunterWaveSpawned
            mission.data.custom.dangerLevel = _Rgen:getInt(1, 10)
            mission.data.custom.maxDefenders = 5
            if mission.data.custom.dangerLevel >= 8 then
                _RewardBase = _RewardBase + 30000
            end
            if mission.data.custom.dangerLevel == 10 then
                _RewardBase = _RewardBase + 55000
            end

            local _Rgen = ESCCUtil.getRand()
            local _StationChance = 5
            mission.data.custom.pirates = _Rgen:getInt(1, 2) == 1
            if mission.data.custom.dangerLevel >= 6 then
                mission.data.custom.maxDefenders = mission.data.custom.maxDefenders + 1
                mission.data.custom.carrierChance = 0.07 * (mission.data.custom.dangerLevel - 5)
                _StationChance = _StationChance + 1
            end
            if mission.data.custom.dangerLevel >= 8 then
                mission.data.custom.maxDefenders = mission.data.custom.maxDefenders + 1
                _StationChance = _StationChance + 1
            end
            if mission.data.custom.dangerLevel == 10 then
                mission.data.custom.maxDefenders = mission.data.custom.maxDefenders + 1
                _StationChance = _StationChance + 1
            end
            mission.data.custom.secondStation = (_Rgen:getInt(1, 10) <= _StationChance)
            mission.data.custom.thirdStation = (_Rgen:getInt(1, 10) <= _StationChance)

            mission.Log(_MethodName, "Уровень опасности: " .. tostring(mission.data.custom.dangerLevel) ..
                ", пираты: " .. tostring(mission.data.custom.pirates) ..
                ", максимальное количество защитников: " .. tostring(mission.data.custom.maxDefenders) ..
                ", вторая станция: " .. tostring(mission.data.custom.secondStation) ..
                ", третья станция: " .. tostring(mission.data.custom.thirdStation))

            if insideBarrier then
                _RewardBase = _RewardBase * 2
            end

            local missionReward = ESCCUtil.clampToNearest(_RewardBase * Balancing.GetSectorRewardFactor(Sector():getCoordinates()), 5000, "Up")

            missionData_in = {location = target, reward = {credits = missionReward}}

            llte_sidemission_init(missionData_in)
            Player():sendChatMessage("Кавалеры", 0, "Цель находится в секторе \\s(%1%:%2%). Идите и раздавите их! Да здравствует император!", target.x, target.y)
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
mission.phases[1] = {}
mission.phases[1].timers = {}
mission.phases[1].triggers = {}
mission.phases[1].noBossEncountersTargetSector = true
mission.phases[1].onTargetLocationEntered = function(_X, _Y)
    local _MethodName = "Фаза 1: вход в целевой сектор"
    mission.Log(_MethodName, "Начало...")

    if not mission.data.custom.builtMainSector then
        -- Генерация сектора.
        local _Faction = nil
        local _Rgen = ESCCUtil.getRand()
        local _Generator = SectorGenerator(_X, _Y)

        for _ = 1, _Rgen:getInt(3, 5) do
            _Generator:createSmallAsteroidField()
        end
        _Generator:createAsteroidField()

        if not mission.data.custom.pirates then
            _Faction = Galaxy():getNearestFaction(_X, _Y)
        end
        if mission.data.custom.pirates or not _Faction then
            mission.Log(_MethodName, "Пираты: " .. tostring(mission.data.custom.pirates) .. " или фракция отсутствует. Используем пиратов.")
            local _PirateLevel = Balancing_GetPirateLevel(_X, _Y)

            _Faction = Galaxy():getPirateFaction(_PirateLevel)
            mission.data.custom.pirateLevel = _PirateLevel
            -- На всякий случай, если _Faction = nil
            mission.data.custom.pirates = true
        end

        mission.data.custom.localFactionIndex = _Faction.index
        mission.Log(_MethodName, "Индекс фракции: " .. tostring(mission.data.custom.localFactionIndex) .. ", имя фракции: " .. tostring(_Faction.name))

        local _StationTable = { "Верфь", "Ремонтный Док", "Аванпост" }

        -- Спавн станций.
        if mission.data.custom.dangerLevel == 10 then
            local _FirstStation = "Аванпост"
            _StationTable = { "Верфь", "Ремонтный Док" }
            local _Station = spawnStationByName(_Generator, _Faction, _FirstStation)
            mission.data.custom.firstStationid = _Station.id
        else
            local _Index = _Rgen:getInt(1, #_StationTable)
            local _FirstStation = _StationTable[_Index]
            table.remove(_StationTable, _Index)
            local _Station = spawnStationByName(_Generator, _Faction, _FirstStation)
            mission.data.custom.firstStationid = _Station.id
        end
        if mission.data.custom.secondStation then
            local _Index = _Rgen:getInt(1, #_StationTable)
            local _XStation = _StationTable[_Index]
            table.remove(_StationTable, _Index)
            spawnStationByName(_Generator, _Faction, _XStation)
        end
        if mission.data.custom.thirdStation then
            local _Index = _Rgen:getInt(1, #_StationTable)
            local _XStation = _StationTable[_Index]
            table.remove(_StationTable, _Index)
            spawnStationByName(_Generator, _Faction, _XStation)
        end

        local _Entities = {Sector():getEntitiesByFaction(_Faction.index)}
        for _, _En in pairs(_Entities) do
            if _En.type == EntityType.Station then
                Boarding(_En).boardable = false
            end
        end

        local _InitialDefenders = 5
        if mission.data.custom.dangerLevel >= 6 then
            _InitialDefenders = _InitialDefenders + math.ceil((mission.data.custom.dangerLevel - 5) / 2)
        end

        local _SpawnTable = ESCCUtil.getStandardTable(mission.data.custom.dangerLevel, "Standard", not mission.data.custom.pirates)
        if mission.data.custom.pirates then
            local _SpawnTable = ESCCUtil.getStandardWave(mission.data.custom.dangerLevel, _InitialDefenders, "Standard")

            local generator = AsyncPirateGenerator(nil, onDefendersFinished)
            generator.pirateLevel = mission.data.custom.pirateLevel

            generator:startBatch()

            for _, _Ship in pairs(_SpawnTable) do
                generator:createScaledPirateByName(_Ship, generator.getGenericPosition())
            end

            generator:endBatch()
        else
            local _SpawnTable = ESCCUtil.getStandardWave(mission.data.custom.dangerLevel, _InitialDefenders, "Standard", true)

            local generator = AsyncShipGenerator(nil, onDefendersFinished)

            generator:startBatch()

            for _, _Ship in pairs(_SpawnTable) do
                generator:createDefenderByName(_Faction, generator.getGenericPosition(), _Ship)
            end

            generator:endBatch()
        end

        local _DCD = {}
        _DCD._DefenseLeader = mission.data.custom.firstStationid
        _DCD._DefenderCycleTime = 120
        _DCD._DangerLevel = mission.data.custom.dangerLevel
        _DCD._MaxDefenders = mission.data.custom.maxDefenders
        _DCD._DefenderHPThreshold = 0.5
        _DCD._DefenderOmicronThreshold = 0.5
        _DCD._ForceWaveAtThreshold = 0.5
        _DCD._ForcedDefenderDamageScale = 3
        _DCD._IsPirate = mission.data.custom.pirates
        _DCD._Factionid = mission.data.custom.localFactionIndex
        _DCD._PirateLevel = _PirateLevel
        _DCD._UseLeaderSupply = false
        _DCD._LowTable = "High"
        if not mission.data.custom.pirates and mission.data.custom.dangerLevel >= 6 then
            _DCD._AddPctToEachWave = { { pct = mission.data.custom.carrierChance, name = "C" } }
        end

        Sector():addScript("sector/background/defensecontroller.lua", _DCD)

        Placer.resolveIntersections()

        mission.data.custom.builtMainSector = true
    end
end

mission.phases[1].onTargetLocationArrivalConfirmed = function(_X, _Y)
    local _MethodName = "Фаза 1: подтверждение прибытия в целевой сектор"
    mission.Log(_MethodName, "Начало...")

    mission.Log(_MethodName, "Установка триггера фазы 1")
    mission.phases[1].triggers[1] = {
        condition = function()
            local _MethodName = "Условие триггера фазы 1"
            local _Faction = Faction(mission.data.custom.localFactionIndex)
            local _Entities = {Sector():getEntitiesByFaction(_Faction.index)}
            mission.Log(_MethodName, "_Faction: " .. tostring(_Faction.name) .. ", количество объектов: " .. tostring(#_Entities), 0)
            if _Entities and #_Entities == 0 then
                return true
            end
            return false
        end,
        callback = function()
            local _MethodName = "Обратный вызов триггера фазы 1"
            mission.Log(_MethodName, "Миссия завершена — награждение игрока.")
            llteSide3_finishAndReward()
        end,
        repeating = false
    }

    local _Faction = Faction(mission.data.custom.localFactionIndex)
    -- Если игрок ещё не воюет с фракцией, добавляем скрипт взаимодействия и объявляем войну.
    local _Relation = Player():getRelation(_Faction.index)
    if _Relation.status ~= RelationStatus.War then
        mission.Log(_MethodName, "Местная фракция ещё не воюет с игроком. Объявляем войну.")
        local _Entities = {Sector():getEntitiesByFaction(_Faction.index)}
        for _, _E in pairs(_Entities) do
            if _E.type == EntityType.Ship or _E.type == EntityType.Station then
                _E:addScriptOnce("player/missions/empress/side/side3/llteside3dialogue1.lua")
            end
        end
    end
end

mission.phases[1].onEntityDestroyed = function(_ID, _LastDamageInflictor)
    local _MethodName = "Фаза 1: объект уничтожен"
    mission.Log(_MethodName, "Начало...", 0)

    if mission.data.custom.dangerLevel == 10 and Entity(_ID):getValue("_llte_side3_station") and not mission.data.custom.hunterWaveSpawned then
        mission.Log(_MethodName, "Спавн волны Охотников.")
        local _Stations = {Sector():getEntitiesByType(EntityType.Station)}
        local _Rgen = ESCCUtil.getRand()
        local _BroadcastStation = _Stations[_Rgen:getInt(1, #_Stations)]
        Sector():broadcastChatMessage(_BroadcastStation, ChatMessageType.Chatter, "Вы думали, мы сделаем это легко для вас? Готовьтесь умереть!")

        if mission.data.custom.pirates then
            mission.phases[1].timers[1] = {
                time = 10,
                callback = function()
                    local _HunterWaveGenerator = AsyncPirateGenerator(nil, onHunterWaveFinished)
                    _HunterWaveGenerator.pirateLevel = mission.data.custom.pirateLevel

                    _HunterWaveGenerator:startBatch()

                    _HunterWaveGenerator:createScaledExecutioner(_HunterWaveGenerator:getGenericPosition(), 2000)
                    _HunterWaveGenerator:createScaledExecutioner(_HunterWaveGenerator:getGenericPosition(), 2000)

                    _HunterWaveGenerator:endBatch()
               end,
               repeating = false
            }
        else
            mission.phases[1].timers[1] = {
                time = 10,
                callback = function()
                    local _Faction = Faction(mission.data.custom.localFactionIndex)
                    local _HunterWaveGenerator = AsyncShipGenerator(nil, onHunterWaveFinished)

                    local _HunterPositions = _HunterWaveGenerator:getStandardPositions(350, 4)

                    _HunterWaveGenerator:startBatch()

                    _HunterWaveGenerator:createDefenderByName(_Faction, _HunterPositions[1], "H")
                    _HunterWaveGenerator:createDefenderByName(_Faction, _HunterPositions[2], "H")
                    _HunterWaveGenerator:createDefenderByName(_Faction, _HunterPositions[3], "BLOCKER")
                    _HunterWaveGenerator:createDefenderByName(_Faction, _HunterPositions[4], "H")

                    _HunterWaveGenerator:endBatch()
                end,
                repeating = false
            }
        end

        mission.data.custom.hunterWaveSpawned = true
    end
end

-- Вызов серверных функций
function spawnStationByName(_Generator, _Faction, _Name)
    local _MethodName = "Спавн станции по имени"
    local _Station = nil
    if _Name == "Аванпост" then
        _Station = _Generator:createMilitaryBase(_Faction)
        _Station:addCrew(60, CrewMan(CrewProfessionType.Pilot))
        if mission.data.custom.dangerLevel == 10 then
            ShipUtility.addScalableArtilleryEquipment(_Station, 3.0, 1.0, false)
        end
    elseif _Name == "Верфь" then
        _Station = _Generator:createShipyard(_Faction)
    elseif _Name == "Ремонтный Док" then
        _Station = _Generator:createRepairDock(_Faction)
    end

    if _Station then
        _Station:setValue("_llte_side3_station", true)
        mission.Log(_MethodName, "Установлено значение станции side3. Подтверждение значения: " .. tostring(_Station:getValue("_llte_side3_station")))

        local _ShipAI = ShipAI(_Station)
        _ShipAI:setAggressive()
    end

    return _Station
end

function onDefendersFinished(_Generated)
    SpawnUtility.addEnemyBuffs(_Generated)
end

function onHunterWaveFinished(_Generated)
    onDefendersFinished(_Generated)

    local _Rgen = ESCCUtil.getRand()

    local _HunterLines = {}
    -- Немного разнообразия на случай покидания/повторного выполнения.
    if mission.data.custom.pirates then
        _HunterLines = {
            "Цели подтверждены. Начинаем боевые действия.",
            "Кавалеры обнаружены. Ликвидация.",
            "Это конец дороги для вас.",
            "Пришло время отрубить голову зверю."
        }
    else
        -- Эти ребята особенно опасны.
        for _, _S in pairs(_Generated) do
            _S.damageMultiplier = (_S.damageMultiplier or 1) * 2
        end

        _HunterLines = {
            "Группа Охотников на месте! Двигаемся на перехват!",
            "Не могу поверить, что вы начали веселье без нас.",
            "Это группа Охотников. Мы здесь и сжимаем челюсти.",
            "Двигатели на полную, оружие готово! Атакуем цели!",
            "Расходовать все боеприпасы! Огонь! Огонь! Огонь!"
        }
    end

    Sector():broadcastChatMessage(_Generated[_Rgen:getInt(1, #_Generated)], ChatMessageType.Chatter, getRandomEntry(_HunterLines))
end

function llteSide3_finishAndReward()
    local _MethodName = "Завершение и награждение"
    mission.Log(_MethodName, "Выполнение условия победы.")

    local _Player = Player()
    local _Rank = _Player:getValue("_llte_cavaliers_rank")
    local _Rgen = ESCCUtil.getRand()

    local _WinMsgTable = {
        "Они действительно думали, что смогут сопротивляться нашей мощи?",
        "Отличная работа, Генерал. Галактика скоро будет нашей...",
        "Все будут преклоняться передо мной, или понесут последствия!",
        "Мы уничтожим всех, кто противится нам!",
        "Кавалеры будут править галактикой!",
        "Мы принесём закон и порядок в эту галактику!",
        "Мы раздавим пиратов! Мы раздавим Ксотан! И мы раздавим самодовольных дураков, которые их терпят!"
    }

    mission.data.reward.paymentMessage = "Получено %1% кредитов за уничтожение сопротивления."
    _Player:sendChatMessage("Император", 0, _WinMsgTable[_Rgen:getInt(1, #_WinMsgTable)])
    reward()
    accomplish()
end

-- Объявление войны фракцией
function factionDeclareWar()
    local _MethodName = "Объявление войны фракцией"
    if onClient() then
        mission.Log(_MethodName, "Вызов на клиенте — вызов на сервере.")
        invokeServerFunction("factionDeclareWar")
        return
    else
        mission.Log(_MethodName, "Вызов на сервере")
    end

    local _Faction = Faction(mission.data.custom.localFactionIndex)
    local _Galaxy = Galaxy()
    local _Player = Player()
    _Galaxy:setFactionRelations(_Faction, _Player, -100000)
    _Galaxy:setFactionRelationStatus(_Faction, _Player, RelationStatus.War)
end
callable(nil, "factionDeclareWar")

--endregion