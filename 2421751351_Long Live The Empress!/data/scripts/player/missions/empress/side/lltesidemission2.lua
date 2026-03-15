--[[
    Побочная миссия ранга 1.
    Сопровождение груза с оружием
    ДОПОЛНИТЕЛЬНЫЕ ТРЕБОВАНИЯ:
        - Нет
    ПРИМЕРНЫЙ ПЛАН:
        - Игрок направляется в сектор, где изначально находятся грузовые корабли.
        - Игрок отбивает волну пиратов.
        - Грузовые корабли совершают прыжок.
        - Игрок следует за грузовыми кораблями.
        - Игрок отбивает ещё одну волну пиратов.
        - Повторяется.
    УРОВЕНЬ ОПАСНОСТИ:
        1+ - [Эти условия действуют независимо от уровня опасности]
            - В разработке
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

local AsyncPirateGenerator = include("asyncpirategenerator")
local AsyncShipGenerator = include("asyncshipgenerator")
local SectorSpecifics = include("sectorspecifics")
local Balancing = include("galaxy")
local SpawnUtility = include("spawnutility")

mission._Debug = 0
mission._Name = "Сопровождение груза с оружием"

-- Побочная миссия: сопровождение грузового корабля. Следуйте за грузовым кораблём от сектора к сектору. Количество прыжков и волн зависит от уровня опасности.
-- Настройка данных миссии
local llte_sidemission_init = initialize
function initialize()
    local _MethodName = "Инициализация"
    mission.Log(_MethodName, "Начало миссии 'Сопровождение груза с оружием'...")

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
            mission.data.brief = "Сопровождение груза с оружием"
            mission.data.title = "Сопровождение груза с оружием"
            mission.data.icon = "data/textures/icons/cavaliers.png"
            mission.data.description = {
                "Вам поручено защитить груз с оружием Кавалеров, потерявший сопровождение. Защитите его, пока не подойдёт подкрепление.",
                { text = "Встретьте грузовой корабль в секторе (${xLoc}:${yLoc})", arguments = {xLoc = target.x, yLoc = target.y}, bulletPoint = true, fulfilled = false }
            }

            local _RewardBase = 50000
            -- Пользовательские данные миссии:
            -- .dangerLevel
            -- .cavaliersindex
            -- .isInsideBarrier
            -- .firstLocation
            -- .checkphasepirates
            -- .freighterid
            -- .freightername
            -- .freighterSpawned
            -- .nextlocation
            -- .jumpindex
            mission.data.custom.cavaliersindex = _Faction.index
            mission.data.custom.isInsideBarrier = insideBarrier
            mission.data.custom.firstLocation = target
            mission.data.custom.checkphasepirates = {}

            mission.data.custom.dangerLevel = _Rgen:getInt(1, 10)
            if mission.data.custom.dangerLevel >= 8 then
                _RewardBase = _RewardBase + 3000
            end
            if mission.data.custom.dangerLevel == 10 then
                _RewardBase = _RewardBase + 5500
            end

            if insideBarrier then
                _RewardBase = _RewardBase * 2
            end

            local missionReward = ESCCUtil.clampToNearest(_RewardBase * Balancing.GetSectorRewardFactor(Sector():getCoordinates()), 5000, "Up")

            missionData_in = {location = target, reward = {credits = missionReward}}

            llte_sidemission_init(missionData_in)
            Player():sendChatMessage("Кавалеры", 0, "Наш грузовой корабль находится в \\s(%1%:%2%). Пожалуйста, встретьте его там.", target.x, target.y)
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
mission.globalPhase.onTargetLocationEntered = function(x, y)
    local _MethodName = "Глобальная фаза: вход в целевой сектор"
    mission.Log(_MethodName, "Удаление таймера провала.")

    mission.globalPhase.timers[1] = nil
end

mission.globalPhase.onTargetLocationLeft = function(x, y)
    local _MethodName = "Глобальная фаза: выход из целевого сектора"
    mission.Log(_MethodName, "Начало...")

    setFailTimer()
end

mission.globalPhase.onEntityDestroyed = function(_ID, _LastDamageInflictor)
    if Entity(_ID):getValue("_llte_escort_mission_freighter") then
        failMission(false)
    end
end

mission.globalPhase.onAbandon = function()
    local _X, _Y = Sector():getCoordinates()
    if _X == mission.data.location.x and _Y == mission.data.location.y then
        -- Покинуто в секторе.
        local _EntityTypes = ESCCUtil.allEntityTypes()
        Sector():addScript("sector/deleteentitiesonplayersleft.lua", _EntityTypes)
        if mission.data.custom.freighterid then
            local _Freighter = Entity(mission.data.custom.freighterid)

            local _WithdrawData = {
                _Threshold = 0.8,
                _MinTime = 1,
                _MaxTime = 1,
                _Invincibility = 0.02
            }

            _Freighter:addScript("ai/withdrawatlowhealth.lua", _WithdrawData)
        end
    else
        -- Покинуто вне сектора.
        local _MX, _MY = mission.data.location.x, mission.data.location.y
        Galaxy():loadSector(_MX, _MY)
        invokeSectorFunction(_MX, _MY, true, "lltesectormonitor.lua", "clearMissionAssets", _MX, _MY, true)
    end
end

mission.phases[1] = {}
mission.phases[1].timers = {}
mission.phases[1].showUpdateOnEnd = true
mission.phases[1].noBossEncountersTargetSector = true
mission.phases[1].onTargetLocationEntered = function(x, y)
    local _MethodName = "Фаза 1: вход в целевой сектор"
    mission.Log(_MethodName, "Начало...")

    -- На случай, если игрок покинул первый сектор и вернулся обратно.
    if not mission.data.custom.freighterSpawned then
        mission.Log(_MethodName, "Спавн грузового корабля Кавалеров...")
        -- Спавн грузового корабля Кавалеров.
        local shipGenerator = AsyncShipGenerator(nil, onFreighterFinished)
        -- Стандартные грузовые корабли слишком легко уничтожаются. Сделаем этот прочнее.
        local cavFreighterVolume = Balancing_GetSectorShipVolume(x, y) * 8
        local faction = Faction(mission.data.custom.cavaliersindex)

        local look = vec3(1, 0, 0)
        local up = vec3(0, 1, 0)

        shipGenerator:startBatch()
        shipGenerator:createFreighterShip(faction, MatrixLookUpPosition(look, up, vec3(0, -50, 0)), cavFreighterVolume)
        shipGenerator:endBatch()

        mission.data.custom.freighterSpawned = true
    end
end

mission.phases[1].onTargetLocationArrivalConfirmed = function(x, y)
    local _MethodName = "Фаза 1: подтверждение прибытия в целевой сектор"

    local ships = {Sector():getEntitiesByScriptValue("_llte_escort_mission_freighter")}
    if ships and #ships ~= 0 then
        mission.Log(_MethodName, "Найден грузовой корабль для сопровождения — сброс данных миссии.")

        local lines = {
            "Слава богу, вы здесь! Наше сопровождение было уничтожено, и нам едва удалось сбежать!"
        }

        local _Freighter = Entity(mission.data.custom.freighterid)
        Sector():broadcastChatMessage(_Freighter, ChatMessageType.Chatter, getRandomEntry(lines))

        -- Запуск двух таймеров: один для спавна первой волны пиратов, другой для предупреждения игрока.
        mission.Log(_MethodName, "Запуск таймера первой волны + таймера предупреждения")
        -- Спавн первой волны пиратов через 20 секунд после того, как грузовой корабль будет в безопасности.
        mission.phases[1].timers[1] = {time = 20, callback = function() spawnPirateWave() end, repeating = false}
        mission.phases[1].timers[2] = {time = 15, callback = function()
            local lines = {
                "Обнаружены сигнатуры прыжков! Похоже, они нас нашли!",
                "Нам следовало знать, что они не оставят нас так просто... готовьтесь!",
                "Они идут за нами! Готовьтесь к перехвату!",
                "Пираты приближаются! Мы прыгнем, как только сможем.",
                "Они здесь! Пожалуйста, удерживайте их, пока мы не сможем прыгнуть."
            }

            local _Freighter = Entity(mission.data.custom.freighterid)
            Sector():broadcastChatMessage(_Freighter, ChatMessageType.Chatter, getRandomEntry(lines))
        end, repeating = false}
    else
        mission.Log(_MethodName, "ОШИБКА: не удалось найти грузовой корабль для сопровождения. Миссия не будет работать корректно.")
    end
end

mission.phases[1].updateTargetLocationServer = function(timeStep)
    local _MethodName = "Фаза 1: обновление целевого сектора"

    if mission.data.custom.checkphasepirates[1] then
        local count = countPirates()
        if count == 0 and not mission.phases[1].timers[3] then
            -- Трансляция сообщения от грузового корабля.
            freighterReadyToJump()
            -- Запуск второго, более короткого таймера. В конце таймера прыгаем и переходим дальше.
            mission.Log(_MethodName, "Пиратов не осталось. Запуск второго таймера.")
            mission.phases[1].timers[3] = { time = 5, callback = function() prepForPhaseAdvance(1) end, repeating = false }
        end
    end
end

mission.phases[2] = {}
mission.phases[2].timers = {}
mission.phases[2].showUpdateOnEnd = true
mission.phases[2].noBossEncountersTargetSector = true
mission.phases[2].onTargetLocationEntered = function(x, y)
    local _MethodName = "Фаза 2: вход в целевой сектор"
    mission.Log(_MethodName, "Начало...")

    mission.phases[2].timers[1] = { time = 15, callback = function() spawnPirateWave() end, repeating = false}
end

mission.phases[2].updateTargetLocationServer = function(timeStep)
    local _MethodName = "Фаза 2: обновление целевого сектора"

    if mission.data.custom.checkphasepirates[2] then
        local count = countPirates()
        if count == 0 and not mission.phases[2].timers[2] then
            -- Трансляция сообщения от грузового корабля.
            freighterReadyToJump()
            -- Запуск второго, более короткого таймера.
            mission.Log(_MethodName, "Пиратов не осталось. Запуск второго таймера.")
            mission.phases[2].timers[2] = { time = 5, callback = function() prepForPhaseAdvance(2) end, repeating = false }
        end
    end
end

mission.phases[3] = {}
mission.phases[3].timers = {}
mission.phases[3].showUpdateOnEnd = true
mission.phases[3].noBossEncountersTargetSector = true
mission.phases[3].onTargetLocationEntered = function(x, y)
    local _MethodName = "Фаза 3: вход в целевой сектор"

    -- Здесь начинается самое интересное.
    if mission.data.custom.dangerLevel == 10 then
        -- Если уровень опасности 10, нужно сделать ещё один прыжок. Запуск таймера атаки пиратов.
        mission.Log(_MethodName, "Запуск последнего таймера пиратов")
        mission.phases[3].timers[1] = { time = 15, callback = function() spawnPirateWave() end, repeating = false}
    else
        -- Если уровень опасности не 10, завершаем здесь.
        mission.Log(_MethodName, "Завершение")
        mission.phases[3].timers[1] = {time = 20, callback = function() spawnReliefDefenders() end, repeating = false}
    end
end

mission.phases[3].updateTargetLocationServer = function(timeStep)
    local _MethodName = "Фаза 3: обновление целевого сектора"

    if mission.data.custom.checkphasepirates[3] then
        local count = countPirates()
        if count == 0 and not mission.phases[3].timers[2] then
            -- Трансляция сообщения от грузового корабля.
            freighterReadyToJump()
            -- Запуск второго, более короткого таймера.
            mission.Log(_MethodName, "Пиратов не осталось. Запуск второго таймера.")
            mission.phases[3].timers[2] = { time = 5, callback = function() prepForPhaseAdvance(3) end, repeating = false }
        end
    end
end

mission.phases[4] = {}
mission.phases[4].timers = {}
mission.phases[4].showUpdateOnEnd = true
mission.phases[4].noBossEncountersTargetSector = true
mission.phases[4].onTargetLocationEntered = function(x, y)
    local _MethodName = "Фаза 4: вход в целевой сектор"
    mission.Log(_MethodName, "Начало...")

    mission.phases[4].timers[1] = {time = 20, callback = function() spawnReliefDefenders() end, repeating = false}
end

-- Вызов серверных функций
function onFreighterFinished(generated)
    local _MethodName = "Обратный вызов: грузовой корабль создан"

    -- В этом пакете должен быть только один корабль.
    mission.Log(_MethodName, "Сброс имени грузового корабля")
    local freighter = generated[1]
    freighter.name = LLTEUtil.getFreighterName()
    freighter.title = "Кавалеры: " .. freighter.title
    freighter:removeScript("civilship.lua")
    freighter:removeScript("dialogs/storyhints.lua")
    freighter:setValue("_llte_escort_mission_freighter", true)
    freighter:setValue("is_civil", nil)
    freighter:setValue("npc_chatter", nil)
    freighter:setValue("is_freighter", nil)
    freighter:setValue("is_cavaliers", true)

    mission.data.custom.freighterid = freighter.id
    mission.data.custom.freightername = freighter.name

    mission.Log(_MethodName, "Обновление целей миссии")
    mission.data.description[2].fulfilled = true
    mission.data.description[3] = { text = "Защищайте " .. mission.data.custom.freightername .. ", пока он не совершит первый прыжок", bulletPoint = true, fulfilled = false }

    sync()
end

function onReliefFinished(generated)
    local _MethodName = "Подкрепление создано"
    mission.Log(_MethodName, "Начало...")

    local rgen = ESCCUtil.getRand()

    local ships = {Sector():getEntitiesByType(EntityType.Ship)}
    for _, ship in pairs(ships) do
        if ship.factionIndex == mission.data.custom.cavaliersindex then
            if ship:getValue("is_defender") then
                ship.title = "Кавалеры: " .. ship.title
                ship:removeScript("antismuggle.lua")
                ship:setValue("npc_chatter", nil)
                ship:setValue("is_cavaliers", true)
            end

            local _WithdrawData = {
                    _Threshold = 0.8,
                    _MinTime = 1,
                    _MaxTime = 1,
                    _Invincibility = 0.02
            }

            ship:addScript("ai/withdrawatlowhealth.lua", _WithdrawData)
            MissionUT.deleteOnPlayersLeft(ship)
            ship:addScriptOnce("utility/delayeddelete.lua", rgen:getFloat(20, 22))
        end
    end

    local lines = {
        "Спасибо за помощь. Теперь мы берём всё под контроль.",
        "Мы берём управление на себя.",
        "Группа поддержки на месте.",
        "Связь с грузовым кораблём установлена. Спасибо за помощь!"
    }

    Sector():broadcastChatMessage(generated[1], ChatMessageType.Chatter, getRandomEntry(lines))

    llteSide2_finishAndReward()
end

function onPiratesFinished(generated)
    local _MethodName = "Пираты созданы"
    mission.Log(_MethodName, "Начало...")

    SpawnUtility.addEnemyBuffs(generated)

    local phaseidx = mission.internals.phaseIndex
    mission.data.custom.checkphasepirates[phaseidx] = true
end

-- Вспомогательные функции
function countPirates()
    return ESCCUtil.countEntitiesByValue("is_pirate")
end

function spawnPirateWave()
    local _MethodName = "Спавн волны пиратов"
    mission.Log(_MethodName, "Начало...")

    local waveShips = 3
    local rgen = ESCCUtil.getRand()
    if mission.data.custom.dangerLevel == 10 then
        waveShips = waveShips + rgen:getInt(1, 2)
    else
        waveShips = waveShips + 1
    end

    local waveTable = ESCCUtil.getStandardWave(mission.data.custom.dangerLevel, waveShips, "Low")
    local generator = AsyncPirateGenerator(nil, onPiratesFinished)

    generator:startBatch()

    local posCounter = 1
    local pirate_positions = generator:getStandardPositions(#waveTable)
    for _, p in pairs(waveTable) do
        generator:createScaledPirateByName(p, pirate_positions[posCounter])
        posCounter = posCounter + 1
    end

    generator:endBatch()
end

function spawnReliefDefenders()
    local _MethodName = "Спавн защитников подкрепления"
    mission.Log(_MethodName, "Начало...")

    -- Спавн 2 защитных кораблей для Кавалеров.
    local shipGenerator = AsyncShipGenerator(nil, onReliefFinished)
    local faction = Faction(mission.data.custom.cavaliersindex)

    shipGenerator:startBatch()

    shipGenerator:createDefender(faction, shipGenerator:getGenericPosition())
    shipGenerator:createDefender(faction, shipGenerator:getGenericPosition())

    shipGenerator:endBatch()
end

function freighterReadyToJump()
    local _MethodName = "Грузовой корабль готов к прыжку"
    mission.Log(_MethodName, "Начало...")

    if not mission.data.custom.freighterid then
        mission.Log(_MethodName, "ОШИБКА: не найден ID грузового корабля. Скоро произойдёт ошибка.")
    end

    local lines = {
        "... И мы снова на связи! Готовимся к прыжку.",
        "Помехи исчезли! Готовимся к прыжку.",
        "Гипердвигатели заряжены и разогреваются!",
        "Спасибо, что расчистили путь! Мы скоро двинемся дальше.",
        "Отличная работа! Мы переместимся в следующий сектор через мгновение.",
        "Гипердвигатель готов! Сейчас рассчитываем маршрут.",
        "Мы отправимся, как только маршрут прыжка будет рассчитан.",
        "Вот и всё! Искажения исчезли!"
    }

    local _Freighter = Entity(mission.data.custom.freighterid)
    Sector():broadcastChatMessage(_Freighter, ChatMessageType.Chatter, getRandomEntry(lines))
end

function prepForPhaseAdvance(jumpidx)
    local _MethodName = "Подготовка к прыжку и переход к следующей фазе"
    mission.Log(_MethodName, "Подготовка к прыжку и переходу фазы...")

    -- Получение следующего местоположения для прыжка.
    local specs = SectorSpecifics()
    local _Rgen = ESCCUtil.getRand()
    local x, y = Sector():getCoordinates()
    local _OtherLocations = MissionUT.getMissionLocations() or {}
    local coords = specs.getShuffledCoordinates(_Rgen, x, y, 10, 18)
    local serverSeed = Server().seed
    local target = nil
    local _LastError = nil

    -- Поиск нового сектора. Все эти усилия только для того, чтобы найти пустой сектор для прыжка.
    for _, coord in pairs(coords) do
        mission.Log(_MethodName, "Оценка координат X: " .. tostring(coord.x) .. " - Y: " .. tostring(coord.y))
        local regular, offgrid, blocked, home = specs:determineContent(coord.x, coord.y, serverSeed)
        if mission.data.custom.isInsideBarrier == MissionUT.checkSectorInsideBarrier(coord.x, coord.y) and not _OtherLocations:contains(coord.y, coord.y) then
            local _PotentialTarget = false
            if not regular and not offgrid and not blocked and not home then
                _PotentialTarget = true
            end

            if _PotentialTarget then
                -- У нас есть потенциальная цель. Проверяем, допустим ли маршрут прыжка.
                mission.Log(_MethodName, "Установка дальности гиперпрыжка на 25")
                local _HyperspaceEngine = HyperspaceEngine(mission.data.custom.freighterid)
                _HyperspaceEngine.range = 25.0

                local _Freighter = Entity(mission.data.custom.freighterid)
                local _JumpValid, _Error = _Freighter:isJumpRouteValid(x, y, coord.x, coord.y)

                if _JumpValid then
                    if not Galaxy():sectorExists(coord.x, coord.y) then
                        target = coord
                        break
                    end
                else
                    mission.Log(_MethodName, "Маршрут прыжка в (" .. tostring(coord.x) .. ":" .. tostring(coord.y) .. ") недопустим из-за: " .. tostring(_Error) .. ". Переход к следующему сектору.")
                    _LastError = _Error
                end
            end
        end
    end

    -- Здесь мы ОБЯЗАНЫ продолжить. Активируем резервный план, если не удалось найти допустимый маршрут прыжка.
    if not target then
        mission.Log(_MethodName, "[ОШИБКА] Не удалось найти подходящий маршрут прыжка. Активируем резервный план. Последняя ошибка: " .. tostring(_LastError))
        target = {}
        target.x, target.y = MissionUT.getSector(x, y, 6, 12, false, false, false, false, mission.data.custom.isInsideBarrier)
    end

    mission.data.custom.nextlocation = target
    mission.data.custom.jumpindex = jumpidx

    mission.Log(_MethodName, "Вызов клиентской функции для открытия диалога.")
    invokeClientFunction(Player(), "onJumpingDialog", mission.data.custom.freighterid, tostring(target.x), tostring(target.y))
end

function jumpAndAdvancePhase()
    local _MethodName = "Прыжок и переход к следующей фазе"
    mission.Log(_MethodName, "Получение данных для перехода фазы.")

    -- Подготовка к прыжку
    local jumpidx = mission.data.custom.jumpindex
    local target = mission.data.custom.nextlocation

    mission.data.custom.nextlocation = nil
    mission.data.custom.jumpindex = nil

    mission.data.location = target

    -- Обновление описания.
    local fulfill = 2 + jumpidx
    local jumpobjective = 3 + jumpidx
    local whichjump
    if jumpidx == 1 then
        whichjump = "второй"
    elseif jumpidx == 2 then
        whichjump = "третий"
    elseif jumpidx == 3 then
        whichjump = "четвёртый"
    end
    mission.data.description[fulfill].fulfilled = true
    mission.data.description[jumpobjective] = {
        text = "Защищайте ${freighter} в секторе (${xLoc}:${yLoc}), пока он не совершит ${jump} прыжок",
        arguments = {freighter = mission.data.custom.freightername, xLoc = target.x, yLoc = target.y, jump = whichjump},
        bulletPoint = true,
        fulfilled = false
    }
    -- Установка таймера удаления, затем, наконец, прыжок.
    local _Freighter = Entity(mission.data.custom.freighterid)
    _Freighter:setValue("_escc_deletion_timestamp", Server().unpausedRuntime + 245)
    Sector():transferEntity(_Freighter, target.x, target.y, SectorChangeType.Jump)
    -- Отправка сообщения игроку.
    Player():sendChatMessage("Навигационный компьютер", 0, "Корабль " .. mission.data.custom.freightername .. " прыгнул в \\s(%1%,%2%).", target.x, target.y)
    -- Переход к следующей фазе. Миссия провалится, если игрок не прыгнет за грузовым кораблём достаточно быстро.
    setFailTimer()
    -- nextPhase автоматически синхронизирует, поэтому нет необходимости вызывать sync() отдельно.
    nextPhase()
end
callable(nil, "jumpAndAdvancePhase")

function setFailTimer()
    local _MethodName = "Установка таймера провала"
    mission.Log(_MethodName, "Установка таймера провала")
    -- 4 минуты может быть слишком щедрым временем, но у игроков могут быть огромные корабли с большим временем перезарядки гипердвигателя.
    mission.globalPhase.timers[1] = { time = 240, callback = function() failMission(true) end, repeating = false }
end

function failMission(remoteDelete)
    local _MethodName = "Миссия провалена"
    mission.Log(_MethodName, "Начало...")

    if remoteDelete then
        mission.Log(_MethodName, "Игрок провалил миссию из-за таймера. Нужно удалить грузовой корабль удалённо.")
    end

    local player = Player()
    player:sendChatMessage("Кавалеры", 0, "Связь с " .. mission.data.custom.freightername .. " потеряна. Что произошло?")
    fail()
end

function llteSide2_finishAndReward()
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
        "Спасибо за сопровождение нашего груза.",
        "Спасибо за защиту нашего грузового корабля."
    }

    local _RepReward = 1
    if mission.data.custom.dangerLevel == 10 then
        _RepReward = _RepReward + 1
    end

    -- Увеличение репутации на 1 (2 при уровне опасности 10)
    mission.data.reward.paymentMessage = "Получено %1% кредитов за сопровождение груза с оружием."
    _Player:setValue("_llte_cavaliers_rep", _Player:getValue("_llte_cavaliers_rep") + _RepReward)
    _Player:sendChatMessage("Кавалеры", 0, _WinMsgTable[_Rgen:getInt(1, #_WinMsgTable)] .. " Мы перевели вознаграждение на ваш счёт.")
    reward()
    accomplish()
end

-- Клиентские вызовы
function onJumpingDialog(id, xloc, yloc)
    local _MethodName = "Диалог прыжка"
    mission.Log(_MethodName, "Начало...")

    local dialog0 = {}
    dialog0.text = string.format("Мы направимся в (%s:%s). Пожалуйста, встретьте нас там!", xloc, yloc)
    dialog0.answers = { { answer = "Понял.", onSelect = "onJumpAcknowledged" } }

    ScriptUI(id):interactShowDialog(dialog0, false)
end

function onJumpAcknowledged()
    local _MethodName = "Прыжок подтверждён"
    mission.Log(_MethodName, "Вызов...")

    invokeServerFunction("jumpAndAdvancePhase")
end

--endregion