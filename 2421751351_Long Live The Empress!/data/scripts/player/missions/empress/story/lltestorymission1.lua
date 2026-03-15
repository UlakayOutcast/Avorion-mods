--[[
    ЗАМЕТКИ:
    1b - Сталь в сумерках
        i - Сбор разведданных
        ii - Предательство
            a - Предательство — это пиратская засада из 10 кораблей из стандартной таблицы угроз.
            b - После того, как игрок уничтожит 5 кораблей, появляется вторая группа из 5 кораблей из таблицы высокой угрозы.
        iii - Столкновение с предателем
        iv - Уничтожение пиратского груза I
            a - Если игрок не успеет уничтожить грузовые корабли за X секунд, они перепрыгнут в случайный соседний сектор, и игроку придётся их преследовать.
            b - Каждый раз будет появляться новая группа сопровождения.
            c - Уровень опасности будет увеличиваться на 1 каждый раз при прыжке.
        v - Уничтожение пиратского груза II
            a - То же, что и выше, но +1 корабль сопровождения.
        vi - Подбор материалов
            a - Просто подбор нескольких контейнеров. Здесь нет неожиданностей. Замедление перед кульминацией этой миссии.
        vii - Доставка Кавалерам
            a - Доставка Кавалерам. Показать большой кастомный корабль Кавалеров перед тем, как они уйдут в варп. Использовать шаблон Грандмастера, пока не найдётся лучший.
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
local AsyncPirateGenerator = include("asyncpirategenerator")
local ShipGenerator = include("shipgenerator")
local AsyncShipGenerator = include("asyncshipgenerator")
local Balancing = include("galaxy")
local ShipUtility = include("shiputility")
local SpawnUtility = include("spawnutility")
local Placer = include("placer")

mission._Debug = 0
mission.tracing = false
mission._Name = "Сталь в сумерках"

mission.data.custom.containerIds = {}

-- Инициализация
local llte_storymission_init = initialize
function initialize()
    local _MethodName = "Инициализация"
    mission.Log(_MethodName, "Начало миссии 'Сталь в сумерках'...")

    if onServer() then
        if not _restoring then
            -- Стандартные данные миссии.
            mission.data.brief = mission._Name
            mission.data.title = mission._Name
            mission.data.autoTrackMission = true
            mission.data.icon = "data/textures/icons/cavaliers.png"
            mission.data.priority = 9
            mission.data.description = {
                "После поражения Семьи и Коммуны Кавалеры готовятся к следующему шагу.",
                { text = "Прочитайте письмо от Адрианы", bulletPoint = true, fulfilled = false },
                -- Если в каком-либо из этих пунктов есть координаты X/Y, они будут обновлены с правильным местоположением при начале соответствующей фазы.
                { text = "Свяжитесь с информаторами в секторе (${_X}:${_Y})", bulletPoint = true, fulfilled = false, visible = false },
                { text = "Уничтожьте пиратов в секторе (${_X}:${_Y})", bulletPoint = true, fulfilled = false, visible = false },
                { text = "Вернитесь в (${_X}:${_Y}) и свяжитесь с предателем", bulletPoint = true, fulfilled = false, visible = false },
                { text = "Согласно информатору, первый груз находится в секторе (${_X}:${_Y}). Перехватите и уничтожьте его", bulletPoint = true, fulfilled = false, visible = false },
                { text = "Перехватите и уничтожьте второй груз в секторе (${_X}:${_Y})", bulletPoint = true, fulfilled = false, visible = false },
                { text = "Прочитайте письмо от Адрианы", bulletPoint = true, fulfilled = false, visible = false },
                { text = "Подберите материалы в секторе (${_X}:${_Y})", bulletPoint = true, fulfilled = false, visible = false },
                { text = "Встретьтесь с Кавалерами в секторе (${_X}:${_Y}) с материалами", bulletPoint = true, fulfilled = false, visible = false }
            }

            -- Пользовательские данные миссии:
            -- .dangerLevel
            -- .informantSector
            -- .ambushSector
            -- .shipment1Sector
            -- .containerSector
            -- .containerDropoffSector
            -- .builtInformantSector
            -- .pirateLevel
            -- .smugglerOutpostid
            -- .ambushSpawned
            -- .ambushWave2Spawned
            -- .ambushWave2Taunted
            -- .shipmentSpawned
            -- .shipmentJumps
            -- .shipmentEscortsSpawned
            -- .containerIds
            -- .spawnedCavaliers
            mission.data.custom.dangerLevel = 5 -- Это сюжетная миссия, поэтому мы держим всё предсказуемым. Однако здесь я делаю кое-что интересное.
            mission.data.custom.shipmentJumps = 0

            local missionReward = 400000

            missionData_in = {location = nil, reward = {credits = missionReward}}

            llte_storymission_init(missionData_in)
        else
            -- Восстановление
            llte_storymission_init()
            if mission.currentPhase == mission.phases[8] then
                registerMarkContainers(true) -- Повторная регистрация обратного вызова клиента.
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
mission.globalPhase.updateServer = function(_TimeStep)
    local _MethodName = "Глобальная фаза: обновление сервера"
    if (mission.currentPhase == mission.phases[5] or mission.currentPhase == mission.phases[6]) and mission.data.custom.shipmentJumps > 5 then
        mission.Log(_MethodName, "Провал миссии")
        Player():sendChatMessage("Навигационный компьютер", 0, "Гиперпространственный след целевых грузовых кораблей потерян.")
        fail()
    end
end

mission.globalPhase.onAbandon = function()
    local _X, _Y = Sector():getCoordinates()
    registerMarkContainers(false)
    if _X == mission.data.location.x and _Y == mission.data.location.y then
        -- Покинуто в секторе.
        local _EntityTypes = ESCCUtil.allEntityTypes()
        Sector():addScript("sector/deleteentitiesonplayersleft.lua", _EntityTypes)
    else
        -- Сектор с контейнерами удаляется и пересоздаётся каждый раз, когда игрок приходит и уходит, поэтому здесь не нужно ничего с ним делать.
        if mission.data.custom.informantSector then
            local _MX, _MY = mission.data.custom.informantSector.x, mission.data.custom.informantSector.y
            Galaxy():loadSector(_MX, _MY)
            invokeSectorFunction(_MX, _MY, true, "lltesectormonitor.lua", "clearMissionAssets", _MX, _MY, true, true)
        end
    end
end

mission.phases[1] = {}
mission.phases[1].showUpdateOnEnd = true
mission.phases[1].noBossEncountersTargetSector = true
mission.phases[1].onBeginServer = function()
    local _MethodName = "Фаза 1: начало на сервере"
    mission.Log(_MethodName, "Начало...")
    mission.data.custom.informantSector = getNextLocation(true)
    local _X, _Y = mission.data.custom.informantSector.x, mission.data.custom.informantSector.y
    mission.data.custom.pirateLevel = Balancing_GetPirateLevel(_X, _Y)
    local _Player = Player()
    local _Mail = Mail()
    _Mail.text = Format("Привет, сквайр!\n\nТеперь, когда мы разобрались с Семьёй и Коммуной, мы можем обратить наше внимание на нашу миссию. Мы очистим галактику от пиратов и Ксотан, принеся безопасность и справедливость.\nМы услышали слухи о особенно мощной группе пиратов, собирающейся у барьера. Это недопустимо. С Ксотан мы разберёмся в своё время, но эти пираты представляют непосредственную угрозу.\n\nЯ организую нападение на них, но мы должны действовать осторожно. Наши дни бездумного расточительства жизней ради дела закончились вместе с императором.\nНаправляйтесь в (%1%:%2%). У нас там есть контакты, которые могут рассказать больше об этих пиратах.\n\nИмператрица Адриана Сталь", _X, _Y)
    _Mail.header = "Следующий шаг"
    _Mail.sender = "Императрица Адриана Сталь @Кавалеры"
    _Mail.id = "_llte_story1_mail1"
    _Player:addMail(_Mail)
end

mission.phases[1].playerCallbacks = {
    {
        name = "onMailRead",
        func = function(_PlayerIndex, _MailIndex)
            if onServer() then
                local _Player = Player()
                local _Mail = _Player:getMail(_MailIndex)
                if _Mail.id == "_llte_story1_mail1" then
                    nextPhase()
                end
            end
        end
    }
}

mission.phases[2] = {}
mission.phases[2].showUpdateOnEnd = true
mission.phases[2].noBossEncountersTargetSector = true
mission.phases[2].onBeginServer = function()
    local _MethodName = "Фаза 2: начало на сервере"
    mission.Log(_MethodName, "Начало...")
    mission.data.location = mission.data.custom.informantSector
    mission.data.description[2].fulfilled = true
    mission.data.description[3].arguments = { _X = mission.data.location.x, _Y = mission.data.location.y }
    mission.data.description[3].visible = true
end

mission.phases[2].onTargetLocationEntered = function(_X, _Y)
    local _MethodName = "Фаза 2: вход в целевой сектор"
    mission.Log(_MethodName, "Начало...")
    -- Имитация поста контрабандистов. Всё это можно удалить после того, как игрок уйдёт во второй раз.
    mission.data.custom.ambushSector = getNextLocation(false)
    buildSmugglerSector(_X, _Y)
end

mission.phases[3] = {}
mission.phases[3].showUpdateOnEnd = true
mission.phases[3].noBossEncountersTargetSector = true
mission.phases[3].onBeginServer = function()
    local _MethodName = "Фаза 3: начало на сервере"
    mission.Log(_MethodName, "Начало...")
    mission.data.location = mission.data.custom.ambushSector
    mission.data.description[3].fulfilled = true
    mission.data.description[4].arguments = { _X = mission.data.location.x, _Y = mission.data.location.y }
    mission.data.description[4].visible = true
end

mission.phases[3].onTargetLocationEntered = function(_X, _Y)
    local _MethodName = "Фаза 3: вход в целевой сектор"
    mission.Log(_MethodName, "Начало...")

    -- Спавн пиратской засады.
    if not mission.data.custom.ambushSpawned then
        local _PirateTable = ESCCUtil.getStandardWave(mission.data.custom.dangerLevel, 10, "Standard")
        local _CreatedPirateTable = {}

        for _, _Pirate in pairs(_PirateTable) do
            table.insert(_CreatedPirateTable, PirateGenerator.createPirateByName(_Pirate, PirateGenerator.getGenericPosition()))
        end
        _CreatedPirateTable[1]:addScript("player/missions/empress/story/story1/lltestory1ambushleader.lua")

        SpawnUtility.addEnemyBuffs(_CreatedPirateTable)

        mission.data.custom.ambushSpawned = true
    end
end

mission.phases[3].updateTargetLocationServer = function(_TimeStep)
    local _MethodName = "Фаза 3: обновление сервера"
    local _PirateCount = ESCCUtil.countEntitiesByValue("is_pirate")

    if not mission.data.custom.ambushWave2Spawned and _PirateCount <= 5 then
        local _Generator = AsyncPirateGenerator(nil, onAmbush2PiratesGenerated)
        local _WaveTable = ESCCUtil.getStandardWave(mission.data.custom.dangerLevel, 5, "High")

        _Generator:startBatch()

        local posCounter = 1
        local distance = 250

        local pirate_positions = _Generator:getStandardPositions(#_WaveTable, distance)
        for _, p in pairs(_WaveTable) do
            _Generator:createScaledPirateByName(p, pirate_positions[posCounter])
            posCounter = posCounter + 1
        end

        _Generator:endBatch()

        mission.data.custom.ambushWave2Spawned = true
    end

    if _PirateCount == 0 then
        nextPhase()
    end
end

mission.phases[4] = {}
mission.phases[4].showUpdateOnEnd = true
mission.phases[4].noBossEncountersTargetSector = true
mission.phases[4].onBeginServer = function()
    local _MethodName = "Фаза 4: начало на сервере"
    mission.Log(_MethodName, "Начало...")
    mission.data.location = mission.data.custom.informantSector
    mission.data.description[4].fulfilled = true
    mission.data.description[5].arguments = { _X = mission.data.location.x, _Y = mission.data.location.y }
    mission.data.description[5].visible = true
end

mission.phases[4].onTargetLocationEntered = function(_X, _Y)
    local _MethodName = "Фаза 4: вход в целевой сектор"
    mission.Log(_MethodName, "Начало...")
    -- Имитация поста контрабандистов. Всё это можно удалить после того, как игрок уйдёт во второй раз.
    mission.data.custom.shipment1Sector = getNextLocation(false)
    local _Station = Entity(mission.data.custom.smugglerOutpostid)
    _Station:removeScript("lltestory1dialogue1.lua")
    _Station:addScript("player/missions/empress/story/story1/lltestory1dialogue2.lua")
end

mission.phases[5] = {}
mission.phases[5].timers = {}
mission.phases[5].showUpdateOnEnd = true
mission.phases[5].noBossEncountersTargetSector = true
mission.phases[5].onBeginServer = function()
    local _MethodName = "Фаза 5: начало на сервере"
    mission.Log(_MethodName, "Начало...")
    mission.data.location = mission.data.custom.shipment1Sector
    mission.data.description[5].fulfilled = true
    mission.data.description[6].arguments = { _X = mission.data.location.x, _Y = mission.data.location.y }
    mission.data.description[6].visible = true
    -- Мы всё ещё должны быть в том же секторе, что и станция.
    local _Station = Entity(mission.data.custom.smugglerOutpostid)
    if _Station and valid(_Station) then
        _Station:removeScript("lltestory1dialogue2.lua")
    end
end

mission.phases[5].onTargetLocationEntered = function(_X, _Y)
    local _MethodName = "Фаза 5: вход в целевой сектор"
    mission.Log(_MethodName, "Начало...")

    -- Спавн пиратских грузовых кораблей.
    if not mission.data.custom.shipmentSpawned then
        -- Нам нужно установить спавн в обратном вызове, иначе фаза перейдёт мгновенно, прежде чем асинхронный генератор сможет создать корабли.
        -- См. onFreightersFinished
        spawnFreighters(_X, _Y)
    end

    if not mission.data.custom.shipmentEscortsSpawned then
        spawnFreighterEscort()
        mission.data.custom.shipmentEscortsSpawned = true
    end

    local _TimeToJump = 35 + (mission.data.custom.shipmentJumps * 18)
    mission.Log(_MethodName, "Грузовые корабли прыгают через " .. tostring(_TimeToJump))
    mission.phases[5].timers[1] = { time = _TimeToJump, callback = function() jumpFreighters() end, repeating = false}
end

mission.phases[5].updateTargetLocationServer = function(_TimeStep)
    local _MethodName = "Фаза 5: обновление сервера"
    local _FreighterCount = ESCCUtil.countEntitiesByValue("_llte_story1_freighter")

    if _FreighterCount == 0 and mission.data.custom.shipmentSpawned then
        nextPhase()
    end
end

mission.phases[6] = {}
mission.phases[6].timers = {}
mission.phases[6].showUpdateOnEnd = true
mission.phases[6].noBossEncountersTargetSector = true
mission.phases[6].onBeginServer = function()
    local _MethodName = "Фаза 6: начало на сервере"
    mission.Log(_MethodName, "Начало...")
    mission.data.location = getNextLocation(false)
    mission.data.description[6].fulfilled = true
    mission.data.description[7].arguments = { _X = mission.data.location.x, _Y = mission.data.location.y }
    mission.data.description[7].visible = true
    -- Сброс спавна грузовых кораблей/сопровождения/прыжков. Уровень опасности НЕ сбрасывается. Лучше уничтожить их быстро ;)
    mission.data.custom.shipmentSpawned = false
    mission.data.custom.shipmentEscortsSpawned = false
    mission.data.custom.shipmentJumps = 0
end

mission.phases[6].onTargetLocationEntered = function(_X, _Y)
    local _MethodName = "Фаза 6: вход в целевой сектор"
    mission.Log(_MethodName, "Начало...")

    -- Спавн пиратских грузовых кораблей.
    if not mission.data.custom.shipmentSpawned then
        spawnFreighters(_X, _Y)
    end

    if not mission.data.custom.shipmentEscortsSpawned then
        spawnFreighterEscort()
        mission.data.custom.shipmentEscortsSpawned = true
    end

    local _TimeToJump = 35 + (mission.data.custom.shipmentJumps * 18)
    mission.Log(_MethodName, "Грузовые корабли прыгают через " .. tostring(_TimeToJump))
    mission.phases[6].timers[1] = { time = _TimeToJump, callback = function() jumpFreighters() end, repeating = false}
end

mission.phases[6].updateTargetLocationServer = function(_TimeStep)
    local _MethodName = "Фаза 6: обновление сервера"
    local _FreighterCount = ESCCUtil.countEntitiesByValue("_llte_story1_freighter")

    if _FreighterCount == 0 and mission.data.custom.shipmentSpawned then
        nextPhase()
    end
end

mission.phases[7] = {}
mission.phases[7].showUpdateOnEnd = true
mission.phases[7].noBossEncountersTargetSector = true
mission.phases[7].onBeginServer = function()
    local _MethodName = "Фаза 7: начало на сервере"
    mission.Log(_MethodName, "Начало...")
    mission.data.location = nil
    mission.data.custom.containerSector = getNextLocation(false)
    local _X, _Y = mission.data.custom.containerSector.x, mission.data.custom.containerSector.y
    -- Найдите второе местоположение для выгрузки контейнеров. Убедитесь, что оно отличается от containerSector
    local _FoundDropoff = false
    local _TempLocation
    while not _FoundDropoff do
        _TempLocation = getNextLocation(false)
        if _TempLocation.x ~= _X or _TempLocation.y ~= _Y then
            _FoundDropoff = true
        end
    end
    mission.data.custom.containerDropoffSector = _TempLocation
    local _DX, _DY = mission.data.custom.containerDropoffSector.x, mission.data.custom.containerDropoffSector.y
    mission.data.description[7].fulfilled = true
    mission.data.description[8].visible = true
    local _Player = Player()
    local _Mail = Mail()
    -- Это последний раз, когда она говорит "Привет, сквайр!" в стиле Boxelware.
    _Mail.text = Format("Привет, сквайр!\n\nНаш информатор говорит, что вы были очень заняты! Спасибо за помощь до сих пор. Мы отследили пиратов и готовим финальное нападение.\nОднако, мы немного растянулись, и нам нужна ваша помощь с последним заданием.\nУ нас есть пара контейнеров в секторе (%1%:%2%) с материалами, которые нам понадобятся для этого.\nКак только вы их подберёте, направляйтесь в (%3%:%4%). Мы встретим вас там. Убедитесь, что на вашем корабле есть несколько док-портов, чтобы захватить контейнеры!\n\nИмператрица Адриана Сталь", _X, _Y, _DX, _DY)
    _Mail.header = "Подбор контейнеров"
    _Mail.sender = "Императрица Адриана Сталь @Кавалеры"
    _Mail.id = "_llte_story1_mail2"
    _Player:addMail(_Mail)
end

mission.phases[7].playerCallbacks = {
    {
        name = "onMailRead",
        func = function(_PlayerIndex, _MailIndex)
            if onServer() then
                local _Player = Player()
                local _Mail = _Player:getMail(_MailIndex)
                if _Mail.id == "_llte_story1_mail2" then
                    nextPhase()
                end
            end
        end
    }
}

mission.phases[8] = {}
mission.phases[8].showUpdateOnEnd = true
mission.phases[8].noBossEncountersTargetSector = true
mission.phases[8].onBeginServer = function()
    local _MethodName = "Фаза 8: начало на сервере"
    mission.Log(_MethodName, "Начало...")
    mission.data.location = mission.data.custom.containerSector
    mission.data.description[8].fulfilled = true
    mission.data.description[9].arguments = { _X = mission.data.location.x, _Y = mission.data.location.y }
    mission.data.description[9].visible = true
end

mission.phases[8].onTargetLocationEntered = function(_X, _Y)
    local _MethodName = "Фаза 8: вход в целевой сектор"
    mission.Log(_MethodName, "Начало...")

    buildContainerSector(_X, _Y)
    registerMarkContainers(true) -- Мы не отменяем регистрацию до начала следующей фазы.
end

mission.phases[8].updateTargetLocationServer = function(_TimeStep)
    local _MethodName = "Фаза 8: обновление целевого сектора"

    -- Получаем корабль игрока.
    local _PlayerShip = Player().craft
    local _PlayerClamps = DockingClamps(_PlayerShip)
    -- Получаем все пристыкованные объекты.
    if _PlayerClamps then
        local _DockedStoryContainers = 0
        local _DockedEntityids = {_PlayerClamps:getDockedEntities()} -- НЕ ВОЗВРАЩАЕТ ОБЪЕКТЫ - ВОЗВРАЩАЕТ ID
        for _, _Docked in pairs(_DockedEntityids) do
            local _DockedEntity = Entity(_Docked)
            if _DockedEntity:getValue("_llte_story1_markcontainer") then
                _DockedStoryContainers = _DockedStoryContainers + 1
            end
        end
        -- Если у игрока есть 2 пристыкованных объекта со значением _llte_story1_markcontainer, переходим к следующей фазе.
        if _DockedStoryContainers >= 2 then
            nextPhase()
        end
    end
end

mission.phases[9] = {}
mission.phases[9].timers = {}
mission.phases[9].noBossEncountersTargetSector = true
mission.phases[9].onBeginServer = function()
    local _MethodName = "Фаза 9: начало на сервере"
    mission.Log(_MethodName, "Начало...")
    registerMarkContainers(false)
    mission.data.location = mission.data.custom.containerDropoffSector
    mission.data.description[9].fulfilled = true
    mission.data.description[10].arguments = { _X = mission.data.location.x, _Y = mission.data.location.y }
    mission.data.description[10].visible = true
end

mission.phases[9].onTargetLocationEntered = function(_X, _Y)
    local _MethodName = "Фаза 9: вход в целевой сектор"
    -- Запуск таймера для спавна Кавалеров, если у игрока есть оба контейнера. Если нет, просто возвращаемся к фазе 8.
    mission.Log(_MethodName, "Запуск таймера.")
    if ESCCUtil.countEntitiesByValue("_llte_story1_markcontainer") >= 2 then
        mission.phases[9].timers[1] = { time = 5, callback = function()
            local _Xloc, _Yloc = Sector():getCoordinates()
            spawnCavaliersShips(_Xloc, _Yloc)
         end, repeating = false}
    else
        mission.phases[9].timers[1] = { time = 2, callback = function()
            -- Если игрок не привёз контейнеры, возвращаемся на фазу назад.
            mission.data.description[9].fulfilled = false
            mission.data.description[10].visible = false
            setPhase(8)
            showMissionUpdated(mission._Name)
         end, repeating = false}
    end
end

-- Вызов серверных функций
function buildSmugglerSector(_X, _Y)
    local _MethodName = "Построение сектора контрабандистов"
    if not mission.data.custom.builtInformantSector then
        mission.Log(_MethodName, "Сектор ещё не построен. Начало...")

        -- В секторе всегда должно быть 2-3 небольших поля астероидов, 1 большое поле астероидов и пост контрабандистов.
        local _Generator = SectorGenerator(_X, _Y)
        local _Rgen = ESCCUtil.getRand()

        -- Получаем фракцию контрабандистов.
        mission.Log(_MethodName, "Строим укрытие контрабандистов.")
        local _SmugglerFaction = MissionUT.getMissionSmugglerFaction()

        local _SmugglerOutpost = _Generator:createStation(_SmugglerFaction, "merchants/smugglersmarket.lua")
        _SmugglerOutpost.title = "Укрытие контрабандистов"%_t
        _SmugglerOutpost:addScript("merchants/tradingpost.lua")
        _SmugglerOutpost:addScript("player/missions/empress/story/story1/lltestory1dialogue1.lua", mission.data.custom.ambushSector.x, mission.data.custom.ambushSector.y)
        mission.data.custom.smugglerOutpostid = _SmugglerOutpost.id

        for _ = 1, _Rgen:getInt(1, 2) do
            local ship = ShipGenerator.createDefender(_SmugglerFaction, _Generator:getPositionInSector())
            ship:removeScript("antismuggle.lua")
        end

        for _ = 1, _Rgen:getInt(2, 3) do
            _Generator:createSmallAsteroidField()
        end

        _Generator:addOffgridAmbientEvents()
        Placer.resolveIntersections()

        mission.data.custom.builtInformantSector = true
        sync()
    end
end

function buildContainerSector(_X, _Y)
    local _MethodName = "Построение сектора с контейнерами"
    local _Generator = SectorGenerator(_X, _Y)
    local _Rgen = ESCCUtil.getRand()

    mission.Log(_MethodName, "Очистка идентификаторов контейнеров")
    mission.data.custom.containerIds = {}

    -- Добавление скриптов удаления перед всем остальным, на случай, если здесь что-то пойдёт не так.
    local _EntityTypes = { EntityType.None, EntityType.Container, EntityType.Ship, EntityType.Station, EntityType.Torpedo, EntityType.Fighter, EntityType.Asteroid, EntityType.Wreckage, EntityType.Unknown, EntityType.Other, EntityType.Loot }
    Sector():addScript("sector/deleteentitiesonplayersleft.lua", _EntityTypes)

    for _ = 1, 2 do
        _Generator:createSmallAsteroidField()
    end
    _Generator:createContainerField()
    -- Пометка двух случайно выбранных контейнеров.
    local _PossibleContainers = {Sector():getEntities()}
    local _DefinitelyContainers = {}
    for _, _En in pairs(_PossibleContainers) do
        if _En.title == "Контейнер" then
            table.insert(_DefinitelyContainers, _En)
        end
    end
    mission.Log(_MethodName, #_DefinitelyContainers .. " контейнеров найдено. Выбираем два случайных для пометки.")

    shuffle(_Rgen, _DefinitelyContainers)
    for cidx = 1, 2 do
        local _Ctr = _DefinitelyContainers[cidx]
        mission.Log(_MethodName, "Помечен контейнер. " .. tostring(_Ctr.id))
        _Ctr:setValue("_llte_story1_markcontainer", true)
        table.insert(mission.data.custom.containerIds, _Ctr.id)
    end

    -- Необходимо синхронизировать идентификаторы контейнеров с клиентом, чтобы правильно их пометить.
    mission.Log(_MethodName, "Синхронизация.")
    sync()
end

function spawnCavaliersShips(_X, _Y)
    local _MethodName = "Спавн кораблей Кавалеров"
    local _Faction = Galaxy():findFaction("Кавалеры")
    local _Plan = LoadPlanFromFile("data/plans/cavaliersboss.xml")
    local _Scale = 3.0

    _Plan:scale(vec3(_Scale, _Scale, _Scale))

    local _EmpressBlade = Sector():createShip(_Faction, "", _Plan, PirateGenerator.getGenericPosition())
    _EmpressBlade.name = "Клинок Императрицы"
    _EmpressBlade.title = "Флагман Адрианы"

    ShipUtility.addBossAntiTorpedoEquipment(_EmpressBlade)
    ShipUtility.addScalableArtilleryEquipment(_EmpressBlade, 5, 1, false)
    ShipUtility.addScalableArtilleryEquipment(_EmpressBlade, 5, 1, false)

    _EmpressBlade.crew = _EmpressBlade.idealCrew
    _EmpressBlade:addScript("icon.lua", "data/textures/icons/pixel/cavaliers.png")
    _EmpressBlade:setValue("_llte_empressblade", true)
    _EmpressBlade:setValue("is_cavaliers", true)
    _EmpressBlade.damageMultiplier = (_EmpressBlade.damageMultiplier or 1) * 5

    Boarding(_EmpressBlade).boardable = false
    _EmpressBlade.dockable = false

    mission.Log(_MethodName, "Добавление скрипта на флагман.")
    local _Player = Player()
    local _Rank = _Player:getValue("_llte_cavaliers_rank")

    _EmpressBlade:addScript("player/missions/empress/story/story1/lltestory1empressblade.lua", _Player.name, _Rank)

    local _Generator = AsyncShipGenerator(nil, onCavaliersFinished)
    _Generator:startBatch()

    for _ = 1, 3 do
        _Generator:createDefender(_Faction, PirateGenerator.getGenericPosition())
    end
    for _ = 1, 2 do
        _Generator:createHeavyDefender(_Faction, PirateGenerator.getGenericPosition())
    end

    _Generator:endBatch()
end

function getNextLocation(_FirstLocation)
    local _MethodName = "Получение следующего местоположения"

    mission.Log(_MethodName, "Получение местоположения.")
    local x, y = Sector():getCoordinates()
    local target = {}

    if _FirstLocation then
        -- Получаем сектор, который находится недалеко от внешнего края барьера.
        mission.Log(_MethodName, "BlockRingMax равен " .. tostring(Balancing.BlockRingMax))
        local _Nx, _Ny = ESCCUtil.getPosOnRing(x, y, Balancing.BlockRingMax + 2)
        target.x, target.y = MissionUT.getEmptySector(_Nx, _Ny, 3, 6, false)
        local _safetyBreakout = 0
        while target.x == x and target.y == y and _safetyBreakout <= 100 do
            target.x, target.y = MissionUT.getEmptySector(_Nx, _Ny, 3, 6, false)
            _safetyBreakout = _safetyBreakout + 1
        end
    else
        target.x, target.y = MissionUT.getEmptySector(x, y, 5, 12, false)
    end

    mission.Log(_MethodName, "Координата X следующего местоположения: " .. tostring(target.x) .. ", координата Y следующего местоположения: " .. tostring(target.y))
    if not target or not target.x or not target.y then
        mission.Log(_MethodName, "Не удалось найти подходящий сектор для миссии. Завершение скрипта.")
        terminate()
        return
    end

    return target
end

function onAmbush2PiratesGenerated(_Generated)
    local _MethodName = "Вторая волна пиратской засады создана"
    mission.Log(_MethodName, "Начало...")

    SpawnUtility.addEnemyBuffs(_Generated)

    if not mission.data.custom.ambushWave2Taunted then
        mission.Log(_MethodName, "Трансляция угроз пиратов в сектор")
        mission.Log(_MethodName, "Объект: " .. tostring(_Generated[1].id))

        local _Lines = {
            "Вы далеко от дома, не так ли?",
            "Мы разорвём вас на части!",
            "Все корабли, оружие на полную! Атакуйте! Атакуйте! Атакуйте!",
            "Убейте их всех! Ха-ха-ха!"
        }

        Sector():broadcastChatMessage(_Generated[1], ChatMessageType.Chatter, getRandomEntry(_Lines))
        mission.data.custom.ambushWave2Taunted = true
    end
end

function spawnFreighters(_X, _Y)
    -- Спавн 5 больших грузовых кораблей и 6 сопровождения. Запуск таймера прыжка, равного количеству прыжков груза 1 * 15 секунд.
    local _ShipGenerator = AsyncShipGenerator(nil, onFreightersFinished)
    local _Vol1 = Balancing_GetSectorShipVolume(_X, _Y) * 8
    local _Vol2 = Balancing_GetSectorShipVolume(_X, _Y) * 11
    local _Faction = Galaxy():getPirateFaction(mission.data.custom.pirateLevel)

    local look = vec3(1, 0, 0)
    local up = vec3(0, 1, 0)

    _ShipGenerator:startBatch()

    _ShipGenerator:createFreighterShip(_Faction, MatrixLookUpPosition(look, up, vec3(100, 50, 50)), _Vol1)
    _ShipGenerator:createFreighterShip(_Faction, MatrixLookUpPosition(look, up, vec3(0, -50, 0)), _Vol1)
    _ShipGenerator:createTradingShip(_Faction, MatrixLookUpPosition(look, up, vec3(-100, -50, -50)), _Vol1)
    _ShipGenerator:createFreighterShip(_Faction, MatrixLookUpPosition(look, up, vec3(-200, 50, -50)), _Vol2)
    _ShipGenerator:createFreighterShip(_Faction, MatrixLookUpPosition(look, up, vec3(-300, -50, 50)), _Vol2)

    _ShipGenerator:endBatch()
end

function onFreightersFinished(_Generated)
    local _MethodName = "Пиратские грузовые корабли созданы"

    for _, _F in pairs(_Generated) do
        _F:setValue("_llte_story1_freighter", true)
        _F:setValue("is_pirate", true)
        _F:removeScript("civilship.lua")
        _F:removeScript("dialogs/storyhints.lua")
        _F:setValue("is_civil", nil)
        _F:setValue("is_freighter", nil)
        _F:setValue("npc_chatter", nil)
        Boarding(_F).boardable = false
    end

    mission.data.custom.shipmentSpawned = true
end

function jumpFreighters()
    local _Freighters = {Sector():getEntitiesByScriptValue("_llte_story1_freighter")}
    -- Это не рассчитано на провал из-за объёма работы, которую должен проделать игрок, чтобы добраться сюда. Представьте провал после прохождения фаз 1-4.
    -- Это было бы ужасно. Поскольку у нас нет ограничения по времени, нам не особенно важно получить маршрут прыжка без блокировок. У игрока будет более чем достаточно времени, чтобы обойти разломы.
    local _JumpTo = getNextLocation(false)

    mission.data.location = _JumpTo
    if mission.data.custom.dangerLevel < 10 then
        -- Максимум 10.
        mission.data.custom.dangerLevel = mission.data.custom.dangerLevel + 1
    end
    mission.data.custom.shipmentJumps = mission.data.custom.shipmentJumps + 1
    -- Разрешить сопровождению снова появиться при входе в новый сектор.
    mission.data.custom.shipmentEscortsSpawned = false
    local _DescriptonIndex = 6
    if mission.currentPhase == mission.phases[6] then
        _DescriptonIndex = 7
    end
    mission.data.description[_DescriptonIndex].text = "Грузовые корабли, доставляющие груз, сбежали в (${_X}:${_Y}). Найдите и уничтожьте их"
    mission.data.description[_DescriptonIndex].arguments = { _X = mission.data.location.x, _Y = mission.data.location.y }

    -- Это должно быть одним из последних действий перед синхронизацией, чтобы предотвратить преждевременное завершение миссии из-за оставшихся грузовых кораблей.
    for _, _F in pairs(_Freighters) do
        Sector():transferEntity(_F, _JumpTo.x, _JumpTo.y, SectorChangeType.Jump)
    end

    sync()
    Player():sendChatMessage("Навигационный компьютер", 0, "Грузовые корабли перепрыгнули в \\s(%1%,%2%).", _JumpTo.x, _JumpTo.y)
    showMissionUpdated(mission._Name)
end

function spawnFreighterEscort()
    local _MethodName = "Спавн сопровождения грузовых кораблей"
    mission.Log(_MethodName, "Спавн сопровождения на уровне опасности " .. tostring(mission.data.custom.dangerLevel))
    local _PirateGenerator = AsyncPirateGenerator(nil, onFreighterEscortFinished)
    local _PirateTable = ESCCUtil.getStandardWave(mission.data.custom.dangerLevel, 6, "Standard")

    _PirateGenerator:startBatch()
    _PirateGenerator.pirateLevel = mission.data.custom.pirateLevel

    for _, _Pirate in pairs(_PirateTable) do
        _PirateGenerator:createPirateByName(_Pirate, _PirateGenerator.getGenericPosition())
    end

    _PirateGenerator:endBatch()
end

function onFreighterEscortFinished(_Generated)
    local _MethodName = "Сопровождение грузовых кораблей создано"
    SpawnUtility.addEnemyBuffs(_Generated)
end

function onCavaliersFinished(_Generated)
    local _MethodName = "Кавалеры созданы"
    for _, _S in pairs(_Generated) do
        _S.title = "Кавалеры: " .. _S.title
        _S:removeScript("antismuggle.lua")
        _S:setValue("npc_chatter", nil)
        _S:setValue("is_cavaliers", true)
        LLTEUtil.rebuildShipWeapons(_S, Player():getValue("_llte_cavaliers_strength"))
    end
end

function llteStory1_finishAndReward()
    local _MethodName = "Завершение и награждение"
    mission.Log(_MethodName, "Выполнение условия победы.")

    local _Player = Player()
    local _Rank = _Player:getValue("_llte_cavaliers_rank")
    local _Rgen = ESCCUtil.getRand()
    _Player:setValue("_llte_story_1_accomplished", true)

    local _WinMsgTable = {
        "Отличная работа, " .. _Rank .. "!"
    }

    -- Увеличение репутации на 1
    _Player:setValue("_llte_cavaliers_rep", _Player:getValue("_llte_cavaliers_rep") + 3)
    _Player:sendChatMessage("Адриана Сталь", 0, _WinMsgTable[_Rgen:getInt(1, #_WinMsgTable)] .. " Вот ваше вознаграждение, как и обещали.")
    reward()
    accomplish()
end

-- Вызов клиентских функций
function onMarkContainers()
    local _MethodName = "Пометка контейнеров"

    local player = Player()
    if not player then return end
    if player.state == PlayerStateType.BuildCraft or player.state == PlayerStateType.BuildTurret then return end

    local renderer = UIRenderer()

    for _, _ContainerID in pairs(mission.data.custom.containerIds) do
        local entity = Entity(_ContainerID)
        if not entity then return end

        local _ContainerMarkOrange = ESCCUtil.getSaneColor(255, 173, 0)

        renderer:renderEntityTargeter(entity, _ContainerMarkOrange)
        renderer:renderEntityArrow(entity, 30, 10, 250, _ContainerMarkOrange)
    end

    renderer:display()
end

-- Вызов клиентских/серверных функций
function registerMarkContainers(_Register)
    local _MethodName = "Регистрация пометки контейнеров"
    if onClient() then
        _MethodName = _MethodName .. " КЛИЕНТ"
        local _Msg = "обратный вызов onPreRenderHud."
        if _Register then
            _Msg = "Регистрация " .. _Msg
        else
            _Msg = "Отмена регистрации " .. _Msg
        end
        mission.Log(_MethodName, _Msg)

        local _Player = Player()
        if _Register then
            if _Player:registerCallback("onPreRenderHud", "onMarkContainers") == 1 then
                mission.Log(_MethodName, "ПРЕДУПРЕЖДЕНИЕ: не удалось добавить обратный вызов prerender к скрипту.")
            end
        else
            if _Player:unregisterCallback("onPreRenderHud", "onMarkContainers") == 1 then
                mission.Log(_MethodName, "ПРЕДУПРЕЖДЕНИЕ: не удалось отменить регистрацию обратного вызова prerender для скрипта.")
            end
        end
    else
        _MethodName = _MethodName .. " СЕРВЕР"
        mission.Log(_MethodName, "Вызов на клиенте")

        invokeClientFunction(Player(), "registerMarkContainers", _Register)
    end
end

function contactedInformant()
    local _MethodName = "Связь с информатором"

    if onClient() then
        mission.Log(_MethodName, "Вызов на клиенте")
        mission.Log(_MethodName, "Вызов на сервере.")

        invokeServerFunction("contactedInformant")
    else
        mission.Log(_MethodName, "Вызов на сервере")
        nextPhase()
    end
end
callable(nil, "contactedInformant")

function contactedTraitor()
    local _MethodName = "Связь с предателем"

    if onClient() then
        mission.Log(_MethodName, "Вызов на клиенте")
        mission.Log(_MethodName, "Вызов на сервере.")

        invokeServerFunction("contactedTraitor")
    else
        mission.Log(_MethodName, "Вызов на сервере")
        nextPhase()
    end
end
callable(nil, "contactedTraitor")

function contactedAdriana()
    local _MethodName = "Связь с Адрианой"

    if onClient() then
        mission.Log(_MethodName, "Вызов на клиенте")
        mission.Log(_MethodName, "Вызов на сервере.")

        invokeServerFunction("contactedAdriana")
    else
        mission.Log(_MethodName, "Вызов на сервере")
        -- Мы побеждаем. Все корабли Кавалеров, кроме Клинка Императрицы, уходят в варп, и мы завершаем миссию.
        local _Rgen = ESCCUtil.getRand()
        local _Cavaliers = {Sector():getEntitiesByScriptValue("is_cavaliers")}
        for _, _Cav in pairs(_Cavaliers) do
            if not _Cav:getValue("_llte_empressblade") then
                _Cav:addScriptOnce("entity/utility/delayeddelete.lua", _Rgen:getFloat(4, 8))
            end
        end
        -- Очистка сектора информатора. Сектор с контейнерами самоочищается.
        local _MX, _MY = mission.data.custom.informantSector.x, mission.data.custom.informantSector.y
        Galaxy():loadSector(_MX, _MY)
        invokeSectorFunction(_MX, _MY, true, "lltesectormonitor.lua", "clearMissionAssets", _MX, _MY, true, true)
        -- Удаление всего при покидании игрока.
        local _EntityTypes = { EntityType.None, EntityType.Container, EntityType.Ship, EntityType.Station, EntityType.Torpedo, EntityType.Fighter, EntityType.Asteroid, EntityType.Wreckage, EntityType.Unknown, EntityType.Other, EntityType.Loot }
        Sector():addScript("sector/deleteentitiesonplayersleft.lua", _EntityTypes)
        llteStory1_finishAndReward()
    end
end
callable(nil, "contactedAdriana")

--endregion