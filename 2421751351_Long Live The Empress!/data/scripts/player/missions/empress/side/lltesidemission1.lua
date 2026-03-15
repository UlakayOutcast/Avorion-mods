--[[
    Побочная миссия ранга 1.
    Засада на пиратских рейдеров
    [ПЕРЕВЕДЕНО]
    ДОПОЛНИТЕЛЬНЫЕ ТРЕБОВАНИЯ:
        - Нет
    ПРИМЕРНЫЙ ПЛАН:
        - Игрок направляется в указанное место.
        - Игрок ждёт короткое время.
        - Через некоторое время начинают прыгать пираты.
        - Игрок уничтожает всех пиратов. Это очень простая миссия.
    УРОВЕНЬ ОПАСНОСТИ:
        1+ - [Эти условия действуют независимо от уровня опасности]
            - Пираты будут использовать стандартные корабли угрозы из соответствующей таблицы опасности.
            - Будет как минимум 3 волны пиратов.
        6 - [Эти условия действуют при уровне опасности 6 и выше]
            - +1 волна пиратов (всего 4 волны)
        10 - [Эти условия действуют при уровне опасности 10]
            - +1 волна пиратов (всего 5 волн)
]]
package.path = package.path .. ";data/scripts/lib/?.lua"
package.path = package.path .. ";data/scripts/?.lua"

-- Запуск остальных подключений.
include("callable")
include("structuredmission")

ESCCUtil = include("esccutil")

local AsyncPirateGenerator = include("asyncpirategenerator")
local SectorSpecifics = include("sectorspecifics")
local Balancing = include("galaxy")
local SpawnUtility = include("spawnutility")

mission._Debug = 0
mission._Name = "Засада на пиратских рейдеров"

-- Настройка данных миссии
local llte_sidemission_init = initialize
function initialize()
    local _MethodName = "Инициализация"
    mission.Log(_MethodName, "Засада на пиратских рейдеров: начало...")

    if onServer() then
        if not _restoring then
            -- У нас нет доступа к данным миссии из объявления, поэтому определяем здесь.
            local specs = SectorSpecifics()
            local rgen = ESCCUtil.getRand()
            local templateBlacklist = ESCCUtil.getStandardTemplateBlacklist()
            local x, y = Sector():getCoordinates()
            local insideBarrier = MissionUT.checkSectorInsideBarrier(x, y)
            local _OtherLocations = MissionUT.getMissionLocations() or {}
            local coords = specs.getShuffledCoordinates(rgen, x, y, 5, 12)
            local serverSeed = Server().seed
            local target = nil

            -- Поиск сектора, который не в чёрном списке.
            for _, coord in pairs(coords) do
                mission.Log(_MethodName, "Оценка координат X: " .. tostring(coord.x) .. " - Y: " .. tostring(coord.y))
                local regular, offgrid, blocked, home = specs:determineContent(coord.x, coord.y, serverSeed)

                if insideBarrier == MissionUT.checkSectorInsideBarrier(coord.x, coord.y) and not _OtherLocations:contains(coord.x, coord.y) then
                    if not regular and not offgrid and not blocked and not home then
                        if not Galaxy():sectorExists(coord.x, coord.y) then
                            target = coord
                            break
                        end
                    end

                    if offgrid and not blocked then
                        local coordSpecs = SectorSpecifics(coord.x, coord.y, serverSeed)

                        local avoid = false
                        for _, bt in pairs(templateBlacklist) do
                            if coordSpecs.generationTemplate.path and coordSpecs.generationTemplate.path == bt then
                                mission.Log(_MethodName, "Сектор имеет шаблон из чёрного списка: " .. coordSpecs.generationTemplate.path)
                                avoid = true
                                break
                            end
                        end
                        if not avoid and not Galaxy():sectorExists(coord.x, coord.y) then
                            target = coord
                            break
                        end
                    end
                end
            end

            if not target then
                mission.Log(_MethodName, "Не удалось найти подходящий сектор для миссии. Завершение скрипта.")
                terminate()
                return
            end

            -- Стандартные данные миссии.
            mission.data.brief = "Засада на пиратских рейдеров"
            mission.data.title = "Засада на пиратских рейдеров"
            mission.data.icon = "data/textures/icons/cavaliers.png"
            mission.data.description = {
                "Вам поручено уничтожить группу пиратов, которые собираются для рейда на соседний сектор.",
                { text = "Направляйтесь в (${location.x}:${location.y})", bulletPoint = true, fulfilled = false }
            }

            local _RewardBase = 50000
            --[[=====================================================
                ПОЛЬЗОВАТЕЛЬСКИЕ ДАННЫЕ МИССИИ:
                .dangerLevel
                .maxwaves
                .waves
                .startSpawningPirates
                .piratesFound
                .firstWaveTaunt
            =========================================================]]
            mission.data.custom.dangerLevel = rgen:getInt(1, 10)
            mission.data.custom.maxwaves = 3
            mission.data.custom.waves = 0
            -- 4 волны.
            if mission.data.custom.dangerLevel >= 6 then
                _RewardBase = _RewardBase + 3000
            end
            -- 4 волны, возможно по 5 кораблей в каждой.
            if mission.data.custom.dangerLevel == 10 then
                mission.data.custom.maxwaves = mission.data.custom.maxwaves + 1
                _RewardBase = _RewardBase + 5500
            end

            if insideBarrier then
                _RewardBase = _RewardBase * 2
            end

            local missionReward = ESCCUtil.clampToNearest(_RewardBase * Balancing.GetSectorRewardFactor(Sector():getCoordinates()), 5000, "Up")

            missionData_in = {location = target, reward = {credits = missionReward}}

            llte_sidemission_init(missionData_in)
            Player():sendChatMessage("Кавалеры", 0, "Они собираются в \\s(%1%:%2%).", target.x, target.y)
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
mission.phases[1].noBossEncountersTargetSector = true
mission.phases[1].onTargetLocationEntered = function(x, y)
    local _MethodName = "Фаза 1: Вход в целевой сектор"
    mission.Log(_MethodName, "Начало...")

    mission.data.description[2].fulfilled = true
    mission.data.description[3] = {text = "Уничтожьте прибывающих пиратов", bulletPoint = true, fulfilled = false}

    mission.phases[1].timers[1] = {time = 12, callback = function() mission.data.custom.startSpawningPirates = true end, repeating = false}
end

mission.phases[1].updateTargetLocationServer = function(timeStep)
    local _MethodName = "Фаза 1: Обновление целевого сектора"

    local count = ESCCUtil.countEntitiesByValue("is_pirate")
    mission.data.custom.piratesFound = mission.data.custom.piratesFound or count > 0

    -- Если остался 1 пират или меньше, спавним следующую волну.
    if count <= 1 and mission.data.custom.waves < mission.data.custom.maxwaves and mission.data.custom.startSpawningPirates then
        mission.Log(_MethodName, "Спавн волны пиратов.")
        mission.data.custom.waves = mission.data.custom.waves + 1
        llteSide1_spawnPirateWave()
    end

    -- Если пиратов не осталось и игрок нашёл пиратов, победа.
    if mission.data.custom.piratesFound and count == 0 then
        llteSide1_finishAndReward()
    end
end

mission.phases[1].onAbandon = function()
    local _X, _Y = Sector():getCoordinates()
    if _X == mission.data.location.x and _Y == mission.data.location.y then
        -- Покинуто в секторе.
        local _EntityTypes = ESCCUtil.allEntityTypes()
        Sector():addScript("sector/deleteentitiesonplayersleft.lua", _EntityTypes)
    else
        -- Покинуто вне сектора.
        local _MX, _MY = mission.data.location.x, mission.data.location.y
        Galaxy():loadSector(_MX, _MY)
        invokeSectorFunction(_MX, _MY, true, "lltesectormonitor.lua", "clearMissionAssets", _MX, _MY)
    end
end

-- Вызов серверных функций
function llteSide1_spawnPirateWave()
    local _MethodName = "Спавн волны пиратов"
    mission.Log(_MethodName, "Начало...")

    local waveShips = 3
    local rgen = ESCCUtil.getRand()
    if mission.data.custom.dangerLevel == 10 then
        waveShips = waveShips + rgen:getInt(1, 2)
    else
        waveShips = waveShips + 1
    end

    local waveTable = ESCCUtil.getStandardWave(mission.data.custom.dangerLevel, waveShips, "Standard")
    local generator = AsyncPirateGenerator(nil, onPiratesFinished)

    generator:startBatch()

    local posCounter = 1
    local distance = 100
    -- Расстояние 200 позволяет Devastator'ам двигаться комфортно.
    if mission.data.custom.dangerLevel == 10 then
        distance = 250 --_#DistAdj
    end
    local pirate_positions = generator:getStandardPositions(#waveTable, distance)
    for _, p in pairs(waveTable) do
        generator:createScaledPirateByName(p, pirate_positions[posCounter])
        posCounter = posCounter + 1
    end

    generator:endBatch()
end

function onPiratesFinished(_Generated)
    local _MethodName = "Пираты сгенерированы (Сервер)"
    mission.Log(_MethodName, "Начало...")

    SpawnUtility.addEnemyBuffs(_Generated)

    if not mission.data.custom.firstWaveTaunt then
        mission.Log(_MethodName, "Трансляция угроз пиратов в сектор")
        mission.Log(_MethodName, "Объект: " .. tostring(_Generated[1].id))

        local _Lines = {
            "Кто нас сдал? Мы разберёмся с тобой после того, как закончим здесь!",
            "... Кто ты? Как ты смеешь вмешиваться!",
            "Ну что ж, думаю, ты будешь первым, кого мы убьём.",
            "Как ты нас нашёл? Неважно, мы убьём тебя и перейдём к более важным целям.",
            "Ты далеко от дома, не так ли?",
            "Здесь не должно было быть никого.",
            "Говорили, что свидетелей не будет — и не будет.",
            "... Кто ты, чёрт возьми?",
            "Кажется, мы нашли заблудшую овцу."
        }

        Sector():broadcastChatMessage(_Generated[1], ChatMessageType.Chatter, getRandomEntry(_Lines))
        mission.data.custom.firstWaveTaunt = true
    end
end

function llteSide1_finishAndReward()
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
        "Спасибо за уничтожение тех пиратов!",
        "Спасибо, что разобрались с теми пиратами!",
        "Благодарим за помощь с теми пиратами!"
    }

    local _RepReward = 1
    if mission.data.custom.dangerLevel == 10 then
        _RepReward = _RepReward + 1
    end

    -- Увеличение репутации на 1 (2 при уровне опасности 10)
    mission.data.reward.paymentMessage = "Получено %1% кредитов за уничтожение пиратских рейдеров."
    _Player:setValue("_llte_cavaliers_rep", _Player:getValue("_llte_cavaliers_rep") + _RepReward)
    _Player:sendChatMessage("Кавалеры", 0, _WinMsgTable[_Rgen:getInt(1, #_WinMsgTable)] .. " Мы перевели вознаграждение на ваш счёт.")
    reward()
    accomplish()
end

--endregion