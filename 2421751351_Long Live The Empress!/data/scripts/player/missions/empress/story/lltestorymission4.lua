--[[
    Сюжетная миссия 4.
    Поход Кавалеров
    Это самая длинная и сложная миссия, которую я когда-либо создавал. По сравнению с ней первая сюжетная миссия выглядит очень простой.
    ДОПОЛНИТЕЛЬНЫЕ ТРЕБОВАНИЯ ДЛЯ ЭТОЙ МИССИИ:
        - Сюжетная миссия 3 выполнена.
        - Ранг у Кавалеров 4.
        - Сила Кавалеров 2. (Выполнена миссия "Доставка передовых материалов" хотя бы 1 раз)
    ПРИМЕРНЫЙ ПЛАН:
        - Встреча с другими Кавалерами.
        - Встреча в стартовой точке.
        - Первый прыжок - незначительная атака пиратов.
        - Второй прыжок - бой с боссом "Враждебность".
        - Третий прыжок - пересечение барьера + крупная атака Ксотан.
        - Четвёртый прыжок - поиск артефакта + незначительная атака Ксотан.
    УРОВЕНЬ ОПАСНОСТИ:
        - 5+ Миссия начинается с уровня опасности 5. Это фиксированное значение, так как это неповторяемая* сюжетная миссия.
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
local AsyncShipGenerator = include("asyncshipgenerator")
local SpawnUtility = include("spawnutility")
local Xsotan = include("story/xsotan")

mission._Debug = 0
mission._Name = "Поход Кавалеров"

local _TransferMinTime = 118 -- 118 / 12
local _TransferMaxTime = 124 -- 124 / 14
local _TransferTimerTime = 125 -- 125 / 15
local _TransferTimerHalfTime = 60 -- 60 / 6

-- Инициализация
local llte_storymission_init = initialize
function initialize()
    local _MethodName = "Инициализация"
    mission.Log(_MethodName, "Начало миссии 'Поход Кавалеров'...")

    if onServer() then
        if not _restoring then
            -- Стандартные данные миссии.
            mission.data.brief = mission._Name
            mission.data.title = mission._Name
            mission.data.autoTrackMission = true
            mission.data.icon = "data/textures/icons/cavaliers.png"
            mission.data.priority = 9
            mission.data.description = {
                "Чтобы победить угрозу Ксотан, Кавалеры прорываются через барьер.",
                { text = "Прочитайте письмо от Адрианы", bulletPoint = true, fulfilled = false },
                -- Если в каком-либо из этих пунктов есть координаты X/Y, они будут обновлены с правильным местоположением при начале соответствующей фазы.
                { text = "Встретьтесь с Кавалерами в секторе (${_X}:${_Y})", bulletPoint = true, fulfilled = false, visible = false },
                { text = "Совершите прыжок в (${_X}:${_Y})", bulletPoint = true, fulfilled = false, visible = false },
                { text = "По крайней мере два из трёх капитальных кораблей '${_SHIP1}', '${_SHIP2}' и '${_SHIP3}' должны выжить", bulletPoint = true, fulfilled = false, visible = false },
                { text = "Отразите атаку пиратов", bulletPoint = true, fulfilled = false, visible = false },
                { text = "Совершите следующий прыжок в (${_X}:${_Y})", bulletPoint = true, fulfilled = false, visible = false },
                { text = "Победите 'Враждебность'", bulletPoint = true, fulfilled = false, visible = false },
                { text = "Совершите следующий прыжок в (${_X}:${_Y})", bulletPoint = true, fulfilled = false, visible = false },
                { text = "Отразите атаку Ксотан", bulletPoint = true, fulfilled = false, visible = false },
                { text = "Совершите следующий прыжок в (${_X}:${_Y})", bulletPoint = true, fulfilled = false, visible = false },
                { text = "Исследуйте сигналы в секторе (${_X}:${_Y})", bulletPoint = true, fulfilled = false, visible = false },
                { text = "Защитите спасательный корабль, пока он подбирает обломки Ксотан", bulletPoint = true, fulfilled = false, visible = false },
                { text = "Вернитесь к флоту Кавалеров в секторе (${_X}:${_Y})", bulletPoint = true, fulfilled = false, visible = false }
            }

            -- Пользовательские данные миссии:
            -- .dangerLevel
            -- .pirateLevel
            -- .capitalsSpawned
            -- .sector1
            -- .sector2
            -- .sector3
            -- .sector4
            -- .sector5
            -- .beaconsector
            -- .phase2DialogAdded
            -- .phase3TimerStarted
            -- .phase4TimerStarted
            -- .phase5TimerStarted
            -- .phase6TimerStarted
            -- .phase7TimerStarted
            -- .initialPhase7Startup
            -- .secondScoutWaveSpawned
            -- .empressBladeid
            -- .animosityid
            -- .capitalsLost
            -- .transferring
            -- .miniswarm
            -- .xsotankilled
            -- .tugs
            mission.data.custom.dangerLevel = 5 -- Это сюжетная миссия, поэтому мы держим всё предсказуемым.
            mission.data.custom.pirateLevel = Player():getValue("_llte_pirate_faction_vengeance")
            mission.data.custom.capitalsLost = 0
            mission.data.custom.xsotankilled = 0
            mission.data.custom.tugs = 0

            local missionReward = 1000000

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
mission.globalPhase.timers = {}
mission.globalPhase.triggers = {}

mission.globalPhase.noBossEncountersTargetSector = true

mission.globalPhase.timers[1] = {
    time = 60,
    callback = function()
        if onServer() then
            local _MethodName = "Глобальный таймер фазы 1"
            mission.Log(_MethodName, "Начало...")
            -- Не делать этого, пока не начнётся фаза 2, и не делать этого, если Клинок Императрицы не в секторе.
            if mission.data.custom.phase2DialogAdded and ESCCUtil.countEntitiesByValue("_llte_empressblade") > 0 then
                local _Defenders = 0
                local _HeavyDefenders = 0
                local _CavShips = {Sector():getEntitiesByScriptValue("is_cavaliers")}
                for _, _Cav in pairs(_CavShips) do
                    if _Cav:getValue("is_defender") then
                        if _Cav:getValue("is_heavy_defender") then
                            _HeavyDefenders = _HeavyDefenders + 1
                        else
                            _Defenders = _Defenders + 1
                        end
                    end
                end
                local _D2S = math.max(3 - _Defenders, 0)
                local _HD2S = math.max(3 - _HeavyDefenders, 0)
                mission.Log(_MethodName, "Спавн " .. tostring(_D2S) .. " защитников и " .. tostring(_HD2S) .. " тяжёлых защитников.")
                spawnCavalierShips(_D2S, _HD2S)
            end
        end
    end,
    repeating = true
}

mission.globalPhase.onAbandon = function()
    Player():unregisterCallback("onPreRenderHud", "onMarkArtifact")
    runFullSectorCleanup_llte()
end

mission.globalPhase.onFail = function()
    -- Если есть корабли Кавалеров, они уходят в варп.
    local _MethodName = "При провале"
    mission.Log(_MethodName, "Начало...")

    -- Пираты, Ксотан и Кавалеры отступают.
    LLTEUtil.allCavaliersDepart()

    local _AnimosityTable = {Sector():getEntitiesByScriptValue("is_animosity")}
    if #_AnimosityTable >= 1 then
        local _Animosity = _AnimosityTable[1]
        Player():sendChatMessage(_Animosity, 0, "Вот и всё с легендарной силой Кавалеров...")
    end

    ESCCUtil.allPiratesDepart()
    ESCCUtil.allXsotanDepart()

    -- Добавление скрипта в местоположение миссии для уничтожения, если мы там, или удалённое уничтожение в противном случае.
    runFullSectorCleanup_llte()
    -- Отправка письма о провале.
    local _Player = Player()
    local _Rank = _Player:getValue("_llte_cavaliers_rank")

    local _Mail = Mail()
    _Mail.text = Format("%1% %2%,\n\nНесмотря на наше новое оборудование и все наши усилия, мы потеряли слишком много кораблей при прорыве к центру галактики и вынуждены отступить на данный момент. Мы попробуем снова!\nВооружитесь более мощным оружием и щитами, и я реорганизую флот для нового прорыва к галактическому ядру. Мы должны разгадать тайну Ксотан, чтобы победить их раз и навсегда!\n\nИмператрица Адриана Сталь", _Rank, _Player.name)
    _Mail.header = "Вынуждены отступить"
    _Mail.sender = "Императрица Адриана Сталь @Кавалеры"
    _Mail.id = "_llte_story4_mailfail"
    _Player:addMail(_Mail)
end

mission.globalPhase.onAccomplish = function()
    local _Player = Player()
    local _Rank = _Player:getValue("_llte_cavaliers_rank")

    local _Mail = Mail()
    _Mail.text = Format("%1% %2%,\n\nЕщё раз спасибо за помощь в достижении центра. Несмотря на то, что мы новички, нам удалось утвердиться как одна из самых сильных военных сил в регионе. Закрепление остатков фракций здесь проходит гладко, и мы сдерживаем Ксотан так хорошо, как только можно. Здесь они намного сильнее!\n\nЧто касается артефакта, мы потратили значительное количество времени на его глубокое сканирование. Насколько мы можем судить, это своего рода маяк, способный входить в высокоэнергетическое состояние и излучать невероятно сильные сигналы через подпространство. Судя по их поведению, когда мы впервые прорвали барьер, эти сигналы будут привлекать Ксотан, как мотыльков к огню.\nМы думаем, что можем использовать это в качестве приманки, чтобы заманивать Ксотан для уничтожения, но пока не нашли способ активировать артефакт целенаправленно. Я свяжусь с вами снова с обновлением.\n\nИмператрица Адриана Сталь", _Rank, _Player.name)
    _Mail.header = "Наш анализ продолжается"
    _Mail.sender = "Императрица Адриана Сталь @Кавалеры"
    _Mail.id = "_llte_story4_mailwin"
    _Player:addMail(_Mail)
end

mission.globalPhase.onEntityDestroyed = function(id, lastDamageInflictor)
    local _MethodName = "Глобальная фаза: объект уничтожен"

    local _Entity = Entity(id)
    if valid(_Entity) then
        if _Entity:getValue("_llte_cav_supercap") then
            mission.data.custom.capitalsLost = mission.data.custom.capitalsLost + 1
            mission.Log(_MethodName, "Потерян капитальный корабль - увеличение счёта потерянных кораблей. Сейчас потеряно " .. tostring(mission.data.custom.capitalsLost) .. ".")
        end
        if _Entity:getValue("is_animosity") then
            Player():setValue("_llte_got_animosity_loot", true)
            Player():setValue("encyclopedia_llte_animosity_found", true)
            mission.data.description[8].fulfilled = true
            ESCCUtil.allPiratesDepart()
            sync()

            invokeClientFunction(Player(), "onPhase4Dialog2", mission.data.custom.empressBladeid)
        end
    end

    if mission.data.custom.capitalsLost > 1 then
        runFullSectorCleanup_llte()
        fail()
    end
end

mission.phases[1] = {}
mission.phases[1].showUpdateOnEnd = true
mission.phases[1].onBeginServer = function()
    local _MethodName = "Фаза 1: начало на сервере"
    mission.Log(_MethodName, "Начало...")
    mission.data.custom.sector1 = getNextLocation(1)
    local _X, _Y = mission.data.custom.sector1.x, mission.data.custom.sector1.y

    local _Player = Player()
    local _Rank = _Player:getValue("_llte_cavaliers_rank")
    local _Mail = Mail()
    _Mail.text = Format("%1% %2%,\n\nАворион, который вы доставили нам, предлагает невероятную возможность - прорваться в центр галактики и разобраться с угрозой Ксотан раз и навсегда. Я планирую операцию, чтобы сделать именно это!\nФлот собирается в секторе (%3%:%4%) - встретимся там, и я проинструктирую вас по плану атаки.\n\nИмператрица Адриана Сталь", _Rank, _Player.name, _X, _Y)
    _Mail.header = "Преодоление барьера"
    _Mail.sender = "Императрица Адриана Сталь @Кавалеры"
    _Mail.id = "_llte_story4_mail1"
    _Player:addMail(_Mail)
end

mission.phases[1].playerCallbacks = {
    {
        name = "onMailRead",
        func = function(_PlayerIndex, _MailIndex)
            if onServer() then
                local _Player = Player()
                local _Mail = _Player:getMail(_MailIndex)
                if _Mail.id == "_llte_story4_mail1" then
                    nextPhase()
                end
            end
        end
    }
}

mission.phases[2] = {}
mission.phases[2].timers = {}
mission.phases[2].showUpdateOnEnd = false
mission.phases[2].onBeginServer = function()
    local _MethodName = "Фаза 2: начало на сервере"
    mission.Log(_MethodName, "Начало...")
    mission.data.location = mission.data.custom.sector1
    mission.data.custom.sector2 = getNextLocation(2)
    mission.data.description[2].fulfilled = true
    mission.data.description[3].arguments = { _X = mission.data.location.x, _Y = mission.data.location.y }
    mission.data.description[4].arguments = { _X = mission.data.custom.sector2.x, _Y = mission.data.custom.sector2.y }
end

mission.phases[2].onTargetLocationEntered = function(_X, _Y)
    local _MethodName = "Фаза 2: вход в целевой сектор"
    mission.Log(_MethodName, "Начало...")

    if not mission.data.custom.capitalsSpawned then
        local _EmpressBlade = LLTEUtil.spawnBladeOfEmpress(false)
        _EmpressBlade:removeScript("ai/withdrawatlowhealth.lua") -- Нужно убедиться, что она не уйдёт в прыжок. Она останется на 2%, если будет слишком сильно повреждена.
        local _SuperCap1 = LLTEUtil.spawnCavalierSupercap(false)
        local _SuperCap2 = LLTEUtil.spawnCavalierSupercap(false)
        local _SuperCap3 = LLTEUtil.spawnCavalierSupercap(false)
        spawnCavalierShips(3, 3)
        mission.data.custom.empressBladeid = _EmpressBlade.id

        mission.data.description[5].arguments = { _SHIP1 = _SuperCap1.name, _SHIP2 = _SuperCap2.name, _SHIP3 = _SuperCap3.name }
        mission.data.custom.capitalsSpawned = true
    end
end

mission.phases[2].onTargetLocationArrivalConfirmed = function(_X, _Y)
    local _MethodName = "Фаза 2: прибытие в целевой сектор подтверждено"
    mission.Log(_MethodName, "Начало...")
    -- Добавление диалога к Клинку Императрицы. После этого установить transferring в true и заставить корабли совершить прыжок через 2 минуты.
    if not mission.data.custom.phase2DialogAdded then
        invokeClientFunction(Player(), "onPhase2Dialog", mission.data.custom.empressBladeid)
        mission.data.custom.phase2DialogAdded = true
    end
end

mission.phases[3] = {}
mission.phases[3].timers = {}
mission.phases[3].triggers = {}
mission.phases[3].showUpdateOnEnd = false
mission.phases[3].onBeginServer = function()
    local _MethodName = "Фаза 3: начало на сервере"
    mission.Log(_MethodName, "Начало...")
    mission.data.custom.sector3 = getNextLocation(3)
end

mission.phases[3].onEntityDestroyed = function(id, lastDamageInflictor)
    local _MethodName = "Фаза 3: объект уничтожен"

    local _Entity = Entity(id)
    if valid(_Entity) and _Entity:getValue("is_pirate") and not mission.data.custom.secondScoutWaveSpawned then
        spawnPirateWave(1)
        -- Установка триггера для добавления скрипта, когда пираты будут уничтожены. По какой-то причине проверка на уничтожение не работает.
        mission.phases[3].triggers[1] = {
            condition = function()
                if onServer() then
                    return ESCCUtil.countEntitiesByValue("is_pirate") == 0
                else
                    -- Мы не делаем этого на клиенте.
                    return true
                end
            end,
            callback = function()
                if onServer() then
                    local _MethodName = "Фаза 3: триггер уничтожения пиратов"
                    invokeClientFunction(Player(), "onPhase3Dialog", mission.data.custom.empressBladeid)
                end
            end,
            repeating = false
        }
        mission.data.custom.secondScoutWaveSpawned = true
    end
end

mission.phases[3].updateTargetLocationServer = function(_TimeStep)
    local _MethodName = "Фаза 3: обновление целевого сектора на сервере"
    -- Возможно, что игрок прыгнул вперёд Кавалеров, поэтому мы запускаем этот таймер только после того, как игрок окажется на месте.
    if not mission.data.custom.phase3TimerStarted then
        mission.Log(_MethodName, "Запуск таймера первой атаки пиратов.")
        mission.data.description[4].fulfilled = true -- Поскольку это эффективно служит нашим "по прибытии", мы можем установить цель/синхронизировать здесь.
        showMissionUpdated(mission._Name)

        mission.phases[3].timers[1] = { time = 11, callback = function()
            broadcastEmpressBladeMsg("Обнаружены сигналы в подпространстве! Готовьтесь к бою!")
        end, repeating = false}
        mission.phases[3].timers[2] = { time = 14, callback = function()
            spawnPirateWave(1)
            mission.data.description[6].visible = true
            showMissionUpdated(mission._Name)
            sync()
        end, repeating = false}

        sync()
        mission.data.custom.phase3TimerStarted = true
    end
end

mission.phases[4] = {}
mission.phases[4].timers = {}
mission.phases[4].showUpdateOnEnd = false
mission.phases[4].noBossEncountersTargetSector = true
mission.phases[4].noPlayerEventsTargetSector = true
mission.phases[4].onBeginServer = function()
    local _MethodName = "Фаза 4: начало на сервере"
    mission.Log(_MethodName, "Начало...")
    mission.data.custom.sector4 = getNextLocation(4)
end

mission.phases[4].updateTargetLocationServer = function(_TimeStep)
    local _MethodName = "Фаза 4: обновление целевого сектора на сервере"
    -- Возможно, что игрок прыгнул вперёд Кавалеров, поэтому мы запускаем этот таймер только после того, как игрок окажется на месте.
    if not mission.data.custom.phase4TimerStarted then
        mission.Log(_MethodName, "Запуск таймера атаки 'Враждебность'.")
        mission.data.description[7].fulfilled = true -- Поскольку это эффективно служит нашим "по прибытии", мы можем установить цель/синхронизировать здесь.
        showMissionUpdated(mission._Name)

        mission.phases[4].timers[1] = { time = 11, callback = function()
            broadcastEmpressBladeMsg("Обнаружено больше сигналов в подпространстве...")
        end, repeating = false}
        mission.phases[4].timers[2] = { time = 14, callback = function()
            -- Спавн "Враждебности"
            local _GotLoot = Player():getValue("_llte_got_animosity_loot")
            local _AddLoot = true
            if _GotLoot then _AddLoot = false end
            local _Animosity = LLTEUtil.spawnAnimosity(mission.data.custom.pirateLevel, _AddLoot)
            mission.data.custom.animosityid = _Animosity.id
            -- Делаем ВСЕ КОРАБЛИ КАВАЛЕРОВ пассивными.
            local _CavShips = {Sector():getEntitiesByScriptValue("is_cavaliers")}
            for _, _Cav in pairs(_CavShips) do
                local _AI = ShipAI(_Cav.index)
                _AI:setPassive()
                _AI:stop()
            end
            ShipAI(_Animosity.index):setPassive()
            -- Добавление скрипта диалога к "Враждебности".
            _Animosity:addScriptOnce("player/missions/empress/story/story4/lltestory4animosity.lua")
            Shield(_Animosity.id).invincible = true
            mission.data.description[8].visible = true
            showMissionUpdated(mission._Name)
            sync()
        end, repeating = false}

        sync()
        mission.data.custom.phase4TimerStarted = true
    end
end

mission.phases[5] = {}
mission.phases[5].timers = {}
mission.phases[5].triggers = {}
mission.phases[5].triggers[1] = {
    condition = function()
        if onServer() then
            return true
        else
            local _ScriptUI = ScriptUI(mission.data.custom.empressBladeid)
            return _ScriptUI ~= nil
        end
    end,
    callback = function()
        if onClient() then
            onPhase5Dialog1(mission.data.custom.empressBladeid)
        end
    end,
    repeating = false
}
mission.phases[5].showUpdateOnEnd = false
mission.phases[5].onBeginServer = function()
    local _MethodName = "Фаза 5: начало на сервере"
    mission.Log(_MethodName, "Начало...")
    mission.data.custom.sector5 = getNextLocation(5) -- Это последнее местоположение прыжка.
end

mission.phases[5].onEntityDestroyed = function(id, lastDamageInflictor)
    local _MethodName = "Фаза 5: объект уничтожен"

    local _Entity = Entity(id)
    if valid(_Entity) and _Entity:getValue("_llte_miniswarm_xsotan") then
        if mission.data.custom.miniswarm then
            mission.data.custom.xsotankilled = mission.data.custom.xsotankilled + 1
        end
        if mission.data.custom.xsotankilled >= 40 then
            mission.data.custom.miniswarm = false
        end
    end
end

mission.phases[5].updateTargetLocationServer = function(_TimeStep)
    local _MethodName = "Фаза 5: обновление целевого сектора на сервере"
    -- Помните, что игрок мог прыгнуть вперёд, поэтому мы запускаем эту фазу здесь, а не в "on sector entered".
    local _EmpressBlade = Entity(mission.data.custom.empressBladeid)
    if valid(_EmpressBlade) then
        -- Мне пришлось разделить это на этот метод/триггер только для клиента из-за того, что диалог отображается немедленно, но это то, что есть.
        if not mission.data.custom.phase5TimerStarted then
            mission.Log(_MethodName, "Обновление миссии для фазы 5")
            mission.data.description[9].fulfilled = true -- Поскольку это эффективно служит нашим "по прибытии", мы можем установить цель/синхронизировать здесь.
            showMissionUpdated(mission._Name)
            sync()

            mission.data.custom.phase5TimerStarted = true
        end
    end
end

mission.phases[6] = {}
mission.phases[6].timers = {}
mission.phases[6].triggers = {}
mission.phases[6].triggers[1] = {
    condition = function()
        if onServer() then
            return true
        else
            local _ScriptUI = ScriptUI(mission.data.custom.empressBladeid)
            return _ScriptUI ~= nil
        end
    end,
    callback = function()
        if onClient() then
            onPhase6Dialog(mission.data.custom.empressBladeid, mission.data.custom.beaconsector.x, mission.data.custom.beaconsector.y)
        end
    end,
    repeating = false
}
mission.phases[6].showUpdateOnEnd = false
mission.phases[6].onBeginServer = function()
    local _MethodName = "Фаза 6: начало на сервере"
    mission.Log(_MethodName, "Начало...")
    mission.data.custom.beaconsector = getBeaconLocation()
end

mission.phases[6].updateTargetLocationServer = function(_TimeStep)
    local _MethodName = "Фаза 6: обновление целевого сектора на сервере"
    local _EmpressBlade = Entity(mission.data.custom.empressBladeid)
    local _Sector = Sector()
    local _X, _Y = _Sector:getCoordinates()

    if valid(_EmpressBlade) then
        if not mission.data.custom.phase6TimerStarted then
            mission.Log(_MethodName, "Обновление миссии для фазы 6")
            mission.data.description[11].fulfilled = true -- Поскольку это эффективно служит нашим "по прибытии", мы можем установить цель/синхронизировать здесь.
            showMissionUpdated(mission._Name)
            sync()

            mission.data.custom.phase6TimerStarted = true
        end
    end
end

mission.phases[7] = {}
mission.phases[7].timers = {}
mission.phases[7].triggers = {}
mission.phases[7].showUpdateOnStart = true
mission.phases[7].onBeginServer = function()
    local _MethodName = "Фаза 7: начало на сервере"
    mission.Log(_MethodName, "Начало...")
    mission.data.description[12].arguments = { _X = mission.data.custom.beaconsector.x, _Y = mission.data.custom.beaconsector.y }
    mission.data.description[12].visible = true
    mission.data.location = mission.data.custom.beaconsector
end

mission.phases[7].onTargetLocationEntered = function(_X, _Y)
    if not mission.data.custom.initialPhase7Startup then
        -- Создание довольно большого астероидного поля.
        local _Generator = SectorGenerator(_X, _Y)
        local _Sector = Sector()
        for _ = 1, 5 do
            _Generator:createAsteroidField()
        end

        for _ = 1, 7 do
            _Generator:createSmallAsteroidField()
        end

        -- Создание обломков Ксотан с маяком где-то.
        spawnXsotanWave(3)
        local _XsotanEntities = {_Sector:getEntitiesByScriptValue("is_xsotan")}
        for _, _X in pairs(_XsotanEntities) do
            _X:destroy(_X.id)
        end

        mission.data.custom.initialPhase7Startup = true
    end
end

mission.phases[7].onTargetLocationArrivalConfirmed = function(_X, _Y)
    if not mission.data.custom.phase7TimerStarted then
        local _Sector = Sector()
        local _Rgen = ESCCUtil.getRand()

        Player():sendChatMessage("Адриана Сталь", 0, "Что бы ни вызывало эти сигналы, похоже, исходит от одного из обломков в этом секторе. Мы отметили его на вашем HUD.")

        -- Удаление всего лута.
        for _, entity in pairs({_Sector:getEntities()}) do
            if entity.type == EntityType.Loot then
                _Sector:deleteEntity(entity)
            end
        end

        local _WreckageEntities = {_Sector:getEntitiesByType(EntityType.Wreckage)}
        local _TargetWreck
        shuffle(random(), _WreckageEntities)

        for idx = 1, #_WreckageEntities do
            local _XWreck = _WreckageEntities[idx]
            local _XPlan = Plan(_XWreck.id)
            if _XPlan.numBlocks >= 200 then
                _TargetWreck = _XWreck
                break
            end
        end

        -- Нечто вроде создания обломков из корабля, но мы просто создаём обломки из обломков. Согласно SDK, у этого не будет таймера исчезновения.
        local _Plan = _TargetWreck:getMovePlan()
        _TargetWreck:setPlan(BlockPlan())
        local _ActualWreck = _Sector:createWreckage(_Plan, _TargetWreck.position)
        _ActualWreck:setValue("_llte_story4_xsotan_artifact", true)

        -- Регистрация обратного вызова prerender.
        registerMarkArtifact()

        -- Таймеры - 1 => буксир + повреждение обломков, чтобы они оставались активными / 2 => фактический спавн буксира / 3 => таймер роя Ксотан
        -- Запуск таймера для буксира.
        mission.phases[7].timers[1] = {
            time = 60,
            callback = function()
                local _MethodName = "Фаза 7: Таймер 1"
                local _X, _Y = Sector():getCoordinates()
                if _X ~= mission.data.location.x or _Y ~= mission.data.location.y then
                    mission.Log(_MethodName, "Не в местоположении миссии. Отмена выполнения этого триггера.")
                    return
                end

                local _TugCount = ESCCUtil.countEntitiesByValue("_llte_story4_artifactsalvager")
                if _TugCount == 0 then
                    mission.data.custom.tugs = mission.data.custom.tugs + 1
                    if mission.data.custom.tugs == 1 then
                        Player():sendChatMessage("Адриана Сталь", 0, "Мы отправляем спасательный корабль. Защитите его, пока он подбирает то, что вызывает эти сигналы!")
                    else
                        Player():sendChatMessage("Адриана Сталь", 0, "Мы отправляем ещё один спасательный корабль. Постарайтесь не потерять и этот!")
                    end

                    -- Запуск таймера для спавна буксира.
                    mission.phases[7].timers[2] = {
                        time = 8,
                        callback = function()
                            spawnWreckageSalvager()
                        end,
                        repeating = false
                    }
                end
            end,
            repeating = true
        }

        -- Запуск таймеров для второго мини-роя.
        mission.phases[7].timers[3] = {
            time = 30,
            callback = function()
                spawnXsotanWave(1, 20)
            end,
            repeating = true
        }

        mission.data.custom.phase7TimerStarted = true
    end
end

mission.phases[8] = {}
mission.phases[8].timers = {}
mission.phases[8].triggers = {}
mission.phases[8].triggers[1] = {
    condition = function()
        if onServer() then
            return true
        else
            local _ScriptUI = ScriptUI(mission.data.custom.empressBladeid)
            return _ScriptUI ~= nil
        end
    end,
    callback = function()
        if onClient() then
            onPhase8Dialog(mission.data.custom.empressBladeid)
        end
    end,
    repeating = false
}
mission.phases[8].showUpdateOnEnd = false
mission.phases[8].onBeginServer = function()
    local _MissionName = "Фаза 8: начало на сервере"
    mission.data.description[14].arguments = { _X = mission.data.custom.sector5.x, _Y = mission.data.custom.sector5.y }
    mission.data.description[14].visible = true
    mission.data.description[13].fulfilled = true
    mission.data.location = mission.data.custom.sector5
end

-- Вызов серверных функций
function spawnCavalierShips(_Defenders, _HeavyDefenders)
    local _Faction = Galaxy():findFaction("Кавалеры")
    local _Generator = AsyncShipGenerator(nil, onCavaliersFinished)
    _Generator:startBatch()

    if _Defenders > 0 then
        for _ = 1, _Defenders do
            _Generator:createDefender(_Faction, PirateGenerator.getGenericPosition())
        end
    end

    if _HeavyDefenders > 0 then
        for _ = 1, _HeavyDefenders do
            _Generator:createHeavyDefender(_Faction, PirateGenerator.getGenericPosition())
        end
    end

    _Generator:endBatch()
end

function spawnPirateWave(_Type)
    local _PirateGenerator = AsyncPirateGenerator(nil, onPirateWaveFinished)
    _PirateGenerator.pirateLevel = mission.data.custom.pirateLevel -- Я считаю, что здесь есть встроенная защита от сбоев.
    local _WaveTable
    if _Type == 1 then
        _WaveTable = ESCCUtil.getStandardWave(mission.data.custom.dangerLevel, 5, "Low")
    elseif _Type == 2 then
        _WaveTable = ESCCUtil.getStandardWave(10, 5, "High")
    end

    local _PosCounter = 1
    local _PiratePositions = _PirateGenerator:getStandardPositions(#_WaveTable, 150)

    _PirateGenerator:startBatch()

    for _, _P in pairs(_WaveTable) do
        _PirateGenerator:createScaledPirateByName(_P, _PiratePositions[_PosCounter])
        _PosCounter = _PosCounter + 1
    end

    _PirateGenerator:endBatch()
end

function spawnXsotanWave(_Type, _XsotanMax)
    local _MethodName = "Спавн волны Ксотан"
    _Type = _Type or 1
    _XsotanMax = _XsotanMax or 25

    local _Sector = Sector()
    local _Generator = SectorGenerator(_Sector:getCoordinates())
    local _Players = {_Sector:getPlayers()}
    local _XsotanCount = ESCCUtil.countEntitiesByValue("is_xsotan")
    local _Rgen = ESCCUtil.getRand()

    local _XsotanToSpawn = _XsotanMax - _XsotanCount
    -- Не спавнить больше 5 за раз по соображениям производительности.
    if _XsotanToSpawn > 5 then
        _XsotanToSpawn = 5
    end

    local _XsoMinSize = 1
    local _XsoMaxSize = 3
    local _BigXsoChance = 1
    local _BigXsoFactor = 2
    local _FirepowerFactor = 1
    if _Type == 2 then -- Появляется во второй половине.
        _XsoMinSize = 4
        _XsoMaxSize = 7
        _BigXsoChance = 2
        _BigXsoFactor = 2.5
        _FirepowerFactor = 2
    elseif _Type == 3 then -- Эти волны появятся только в том случае, если игрок/Кавалеры уничтожают Ксотан слишком быстро.
        _XsoMinSize = 6
        _XsoMaxSize = 10
        _BigXsoChance = 2
        _BigXsoFactor = 3
        _FirepowerFactor = 4
    end

    mission.Log(_MethodName, "Спавн финального количества " .. tostring(_XsotanToSpawn) .. " кораблей Ксотан.")
    local _XsotanTable = {}
    -- Спавн Ксотан на основе того, что есть в таблице имён.
    for _ = 1, _XsotanToSpawn do
        local _Xsotan = nil
        local _Dist = 1500
        local _XsoSize = _Rgen:getInt(_XsoMinSize, _XsoMaxSize)
        if _Rgen:getInt(1, 4) <= _BigXsoChance then
            _XsoSize = _XsoSize * _BigXsoFactor -- % шанс создать более крупного Ксотан.
        end
        _Xsotan = Xsotan.createShip(_Generator:getPositionInSector(_Dist), _XsoSize)

        if _Xsotan then
            if valid(_Xsotan) then
                for _, p in pairs(_Players) do
                    ShipAI(_Xsotan.id):registerEnemyFaction(p.index)
                end
                ShipAI(_Xsotan.id):setAggressive()
            end
            _Xsotan:setValue("_llte_miniswarm_xsotan", true)
            table.insert(_XsotanTable, _Xsotan)
        else
            mission.Log(_MethodName, "ОШИБКА - Ксотан был nil")
        end
    end

    SpawnUtility.addEnemyBuffs(_XsotanTable)
    for _, _X in pairs(_XsotanTable) do
        _X.damageMultiplier = (_X.damageMultiplier or 1) * _FirepowerFactor
    end
end

function spawnWreckageSalvager()
    local _Faction = Galaxy():findFaction("Кавалеры")
    local _Generator = AsyncShipGenerator(nil, onWreckageSalvagerFinished)
    local _Sector = Sector()
    local _X, _Y = _Sector:getCoordinates()
    local _SalvagerVolume = Balancing_GetSectorShipVolume(_X, _Y) * 8

    _Generator:startBatch()

    _Generator:createMiningShip(_Faction, _Generator:getGenericPosition(), _SalvagerVolume)

    _Generator:endBatch()
end

function runFullSectorCleanup_llte()
    local _Sector = Sector()
    local _X, _Y = Sector():getCoordinates()
    local _EntityTypes = ESCCUtil.allEntityTypes()
    _Sector:addScriptOnce("sector/deleteentitiesonplayersleft.lua", _EntityTypes)

    if _X == mission.data.location.x and _Y == mission.data.location.y then
        _Sector:addScriptOnce("sector/deleteentitiesonplayersleft.lua", _EntityTypes)
    else
        local _MX, _MY = mission.data.location.x, mission.data.location.y
        Galaxy():loadSector(_MX, _MY)
        invokeSectorFunction(_MX, _MY, true, "lltesectormonitor.lua", "clearMissionAssets", _MX, _MY, true, true)
    end
end

function broadcastEmpressBladeMsg(_Msg, ...)
    local _Sector = Sector()
    local _EmpressBlade = {_Sector:getEntitiesByScriptValue("_llte_empressblade")}
    _Sector:broadcastChatMessage(_EmpressBlade[1], ChatMessageType.Normal, _Msg, ...)
end

function onCavaliersFinished(_Generated)
    local _MethodName = "Кавалеры созданы"
    for _, _S in pairs(_Generated) do
        _S.title = "Кавалеры: " .. _S.title
        _S:setValue("npc_chatter", nil)
        _S:setValue("is_cavaliers", true)

        local _WithdrawData = {
            _Threshold = 0.15
        }

        _S:addScript("ai/withdrawatlowhealth.lua", _WithdrawData)
        _S:removeScript("antismuggle.lua")
        LLTEUtil.rebuildShipWeapons(_S, Player():getValue("_llte_cavaliers_strength"))
    end
end

function onWreckageSalvagerFinished(_Generated)
    local _MethodName = "Спасательный корабль создан"
    local _Miner = _Generated[1]

    _Miner.title = "Спасательный корабль Кавалеров"

    _Miner:removeScript("civilship.lua")
    _Miner:removeScript("dialogs/storyhints.lua")
    _Miner:setValue("is_civil", nil)
    _Miner:setValue("is_miner", nil)
    _Miner:setValue("npc_chatter", nil)
    _Miner:setValue("is_cavaliers", true)
    _Miner:setValue("_llte_story4_artifactsalvager", true)

    local _StoryWrecks = {Sector():getEntitiesByScriptValue("_llte_story4_xsotan_artifact")}
    local _StoryWreck = _StoryWrecks[1]

    _Miner:addScript("player/missions/empress/story/story4/lltestory4artifactship.lua", _StoryWreck)

    mission.Log(_MethodName, "Обновление целей миссии")
    mission.data.description[12].fulfilled = true
    mission.data.description[13].visible = true

    sync()
end

function onPirateWaveFinished(_Generated)
    SpawnUtility.addEnemyBuffs(_Generated)
end

function returnToLastStop()
    local _MethodName = "Возвращение к последней остановке"
    mission.Log(_MethodName, "Начало...")
    local _Sector = Sector()

    local _X, _Y = mission.data.custom.sector5.x, mission.data.custom.sector5.y

    -- Прыжок корабля с артефактом в предыдущий сектор
    local _RecoveryShips = {_Sector:getEntitiesByScriptValue("_llte_story4_artifactsalvager")}
    Sector():transferEntity(_RecoveryShips[1], _X, _Y, SectorChangeType.Jump)

    -- Прыжок обломков в предыдущий сектор
    local _Wrecks = {_Sector:getEntitiesByScriptValue("_llte_story4_xsotan_artifact")}
    Sector():transferEntity(_Wrecks[1], _X, _Y, SectorChangeType.Jump)

    Player():sendChatMessage("Адриана Сталь", 0, "Артефакт извлечён! Вернитесь в \\s(%1%:%2%) для дебрифинга.", _X, _Y)
    Player():setValue("encyclopedia_llte_xsotan_artifact_found", true)

    -- Переход к финальной стадии миссии
    nextPhase()
end

function getNextLocation(_Location)
    local _MethodName = "Получение следующего местоположения"

    mission.Log(_MethodName, "Получение местоположения.")
    local x, y = Sector():getCoordinates()
    local target = {}

    local _NxTable = {
        { _RingPos = 187, _InBarrier = false },
        { _RingPos = 180, _InBarrier = false },
        { _RingPos = 160, _InBarrier = false },
        { _RingPos = 140, _InBarrier = true },
        { _RingPos = 120, _InBarrier = true }
    }

    local _Nx, _Ny = ESCCUtil.getPosOnRing(x, y, _NxTable[_Location]._RingPos)
    target.x, target.y = MissionUT.getSector(_Nx, _Ny, 1, 4, false, false, false, false, _NxTable[_Location]._InBarrier)

    if target == nil or target.x == nil or target.y == nil then
        print("Не удалось получить местоположение - активация резервного варианта")
        target.x, target.y = MissionUT.getSector(x, y, 1, 20, false, false, false, false, _NxTable[_Location]._InBarrier)
    end

    return target
end

function runTransfer(_FromLocation, _ToLocation)
    -- Если игрок находится в секторе миссии, переносим объекты по одному. В противном случае переносим их все сразу - когда последний будет перенесён, переходим к следующей фазе.
    local _Rgen = ESCCUtil.getRand()

    local _Cavaliers = {Sector():getEntitiesByScriptValue("is_cavaliers")}

    for _, _Cav in pairs(_Cavaliers) do
        _Cav:addScriptOnce("entity/utility/delayedjump.lua", _ToLocation.x, _ToLocation.y, _Rgen:getFloat(_TransferMinTime, _TransferMaxTime))
    end
end

function getBeaconLocation()
    local _MethodName = "Получение местоположения маяка"
    mission.Log(_MethodName, "Получение местоположения маяка.")

    local x, y = Sector():getCoordinates()
    local _Target = {}

    _Target.x, _Target.y = MissionUT.getSector(x, y, 3, 6, false, false, false, false)
    return _Target
end

function llteStory4_finishAndReward()
    local _MethodName = "Завершение и награждение"
    mission.Log(_MethodName, "Выполнение условия победы.")

    local _Player = Player()
    local _Rank = _Player:getValue("_llte_cavaliers_rank")
    local _Rgen = ESCCUtil.getRand()

    local _WinMsgTable = {
        "Отличная работа, " .. _Rank .. "!"
    }

    _Player:setValue("_llte_cavaliers_inbarrier", true)

    _Player:setValue("_llte_story_4_accomplished", true)

    -- Увеличение репутации на 8
    _Player:setValue("_llte_cavaliers_rep", _Player:getValue("_llte_cavaliers_rep") + 8)
    _Player:sendChatMessage("Адриана Сталь", 0, _WinMsgTable[_Rgen:getInt(1, #_WinMsgTable)] .. " Вот ваше вознаграждение, как и обещали.")
    reward()
    accomplish()
end

-- Вызов клиентских функций
function onMarkArtifact()
    local _MethodName = "Пометка артефакта"

    local player = Player()
    if not player then return end
    if player.state == PlayerStateType.BuildCraft or player.state == PlayerStateType.BuildTurret then return end

    local renderer = UIRenderer()

    local _Artifact = {Sector():getEntitiesByScriptValue("_llte_story4_xsotan_artifact")}
    for _, _A in pairs(_Artifact) do
        local _StandardOrange = ESCCUtil.getSaneColor(255, 173, 0)

        renderer:renderEntityTargeter(_A, _StandardOrange)
        renderer:renderEntityArrow(_A, 30, 10, 250, _StandardOrange)
    end

    renderer:display()
end

-- Поскольку у нас несколько взаимодействий, мы не можем использовать скрипты, производные от singleinteraction.
function onPhase2Dialog(_ID)
    -- В начале миссии.
    local _MethodName = "Диалог фазы 2"
    mission.Log(_MethodName, "Начало... ID: " .. tostring(_ID))

    local d0 = {}
    local d1 = {}
    local d2 = {}
    local d3 = {}
    local d4 = {}

    local _Player = Player()
    local _PlayerRank = _Player:getValue("_llte_cavaliers_rank")
    local _PlayerName = _Player.name

    -- d0
    d0.text = _PlayerRank .. " " .. _PlayerName .. "! Рада видеть вас здесь!"
    d0.answers = {
        { answer = "Итак, какой план?", followUp = d1 }
    }

    d1.text = "Мы использовали Аворион, который вы нам доставили, и оснастили им наши гипердвигатели. Начнём здесь, затем прорвёмся через барьер. Наконец, достаточно наших кораблей должны пройти через это, иначе всё было зря."
    d1.followUp = d4

    d4.text = "Как только мы достигнем барьера, мы... просто прыгаем через него? Странно это говорить. 200 лет изоляции, и всё закончилось вот так?"
    d4.answers = {
        { answer = "Это было много работы, знаете ли.", followUp = d2 }
    }

    d2.text = "Вы правы. Спасибо за ваши усилия!"
    d2.answers = {
        { answer = "Пожалуйста.", followUp = d3 }
    }

    d3.text = "Нам понадобится пара минут после каждого прыжка, чтобы наши корабли перезарядили гипердвигатели. Мы также будем передавать местоположение каждого прыжка, так что вы сможете не отставать от нас! Не то чтобы в этом были какие-то сомнения. Вы готовы?"
    d3.answers = {
        { answer = "Я готов. Давайте начнём.", onSelect = "onPhase2DialogEnd" }
    }

    ESCCUtil.setTalkerTextColors({d0, d1, d2, d3, d4}, "Адриана Сталь", MissionUT.getDialogTalkerColor1(), MissionUT.getDialogTextColor1())

    ScriptUI(_ID):interactShowDialog(d0, false)
end

function onPhase3Dialog(_ID)
    -- После атаки пиратов.
    local _MethodName = "Диалог фазы 3"
    mission.Log(_MethodName, "Начало... ID: " .. tostring(_ID))

    local d0 = {}
    local d1 = {}
    local d2 = {}

    -- d0
    d0.text = "Это было странно. Это даже не считалось атакой. Что происходит?"
    d0.answers = {
        { answer = "Разведчики, возможно?", followUp = d1 },
        { answer = "Вероятно, не о чём беспокоиться.", followUp = d2 }
    }
    -- d1
    d1.text = "Возможно. Мне это не нравится. Мы прыгнем в следующий сектор через две минуты. Будьте начеку."
    d1.onEnd = "onPhase3DialogEnd"
    -- d2
    d2.text = "... Возможно. Мне это не нравится. Это не имеет никакого смысла - они, должно быть, что-то замышляют. Мы прыгнем в следующий сектор через две минуты. Держите глаза открытыми."
    d2.onEnd = "onPhase3DialogEnd"

    ESCCUtil.setTalkerTextColors({d0, d1, d2}, "Адриана Сталь", MissionUT.getDialogTalkerColor1(), MissionUT.getDialogTextColor1())

    ScriptUI(_ID):interactShowDialog(d0, false)
end

function onPhase4Dialog2(_ID)
    -- После уничтожения "Враждебности".
    local _MethodName = "Диалог фазы 4, часть 2"
    mission.Log(_MethodName, "Начало... ID: " .. tostring(_ID))

    local d0 = {}
    local d1 = {}
    local d2 = {}
    local d3 = {}
    local d4 = {}

    local _Player = Player()
    local _PlayerRank = _Player:getValue("_llte_cavaliers_rank")

    -- d0
    d0.text = "Тот корабль был невероятно мощным. Я никогда не видела ничего подобного."
    d0.followUp = d1

    d1.text = "Жаль. Только представьте, что они могли бы сделать с ним. Вместо этого они отдали свои жизни, пытаясь убить нас."
    d1.followUp = d2

    d2.text = "Я продолжаю думать о том, что они говорили о галактическом порядке. Пока люди чувствуют, что их бросили, всегда будут пираты, не так ли?"
    d2.followUp = d3

    d3.text = "Возможно... Уничтожение пиратов - не единственный способ сохранить мир. Возможно, мы можем сделать больше."
    d3.followUp = d4

    d4.text = "Мне нужно об этом подумать. В любом случае, Ксотан всё ещё представляют угрозу. Давайте двигаться дальше, %1%." % { _PLAYERRANK = _PlayerRank }
    d4.onEnd = "onPhase4Dialog2End"

    ESCCUtil.setTalkerTextColors({d0, d1, d2, d3, d4}, "Адриана Сталь", MissionUT.getDialogTalkerColor1(), MissionUT.getDialogTextColor1())

    ScriptUI(_ID):interactShowDialog(d0, false)
end

function onPhase5Dialog1(_ID)
    -- Сразу после попадания в ядро.
    local _MethodName = "Диалог фазы 5, часть 1"
    mission.Log(_MethodName, "Начало...")

    local d0 = {}
    local d1 = {}
    local d2 = {}
    local d3 = {}

    -- d0
    d0.text = "Итак, это галактическое ядро..."
    d0.answers = {
        { answer = "Вы звучите разочарованно.", followUp = d1 }
    }

    -- d1
    d1.text = "О, я просто... ожидала, что оно будет другим, как-то?"
    d1.answers = {
        { answer = "Вы здесь не так давно. Дайте ему немного времени.", followUp = d2 },
        { answer = "Здесь намного больше Ксотан, и они агрессивны.", followUp = d3 }
    }

    -- d2
    d2.text = "Вы правы, конечно. Есть что-то, на что нам следует обратить внимание?"
    d2.answers = {
        { answer = "Здесь намного больше Ксотан, и они агрессивны.", followUp = d3 }
    }

    -- d3
    d3.text = "Это беспокоило бы кого угодно, но именно для этого мы здесь! Мы уничтожим их так же, как и пиратов."
    d3.onEnd = "onPhase5Dialog1End"

    ESCCUtil.setTalkerTextColors({d0, d1, d2, d3}, "Адриана Сталь", MissionUT.getDialogTalkerColor1(), MissionUT.getDialogTextColor1())

    local _Entities = {Sector():getEntitiesByScriptValue("_llte_empressblade")}

    ScriptUI(_Entities[1].id):interactShowDialog(d0, false)
end

function onPhase5Dialog2(_ID)
    -- После крупной атаки Ксотан.
    local _MethodName = "Диалог фазы 5, часть 2"
    mission.Log(_MethodName, "Начало...")

    local d0 = {}
    local d1 = {}
    local d2 = {}

    -- d0
    d0.text = "Это было интенсивно! Ксотан всегда так делают внутри барьера?"
    d0.answers = {
        { answer = "Не всегда. Это необычно.", followUp = d1 }
    }

    d1.text = "Интересно... Интересно, если..."
    d1.answers = {
        { answer = "Интересно что?", followUp = d2 }
    }

    d2.text = "Мы разберёмся с этим в ближайшее время! Я бы хотела уйти отсюда на случай, если Ксотан решат атаковать снова."
    d2.onEnd = "onPhase5Dialog2End"

    ESCCUtil.setTalkerTextColors({d0, d1, d2}, "Адриана Сталь", MissionUT.getDialogTalkerColor1(), MissionUT.getDialogTextColor1())

    ScriptUI(_ID):interactShowDialog(d0, false)
end

function onPhase6Dialog(_ID, _X, _Y)
    -- После прыжка после крупной атаки Ксотан - перед отправкой за артефактом.
    local _MethodName = "Диалог фазы 6"
    mission.Log(_MethodName, "Начало... ID: " .. tostring(_ID))

    local d0 = {}
    local d1 = {}
    local d2 = {}
    local d3 = {}

    -- d0
    d0.text = "Перед тем как мы прыгнули из сектора, где Ксотан атаковали нас, мы уловили странные сигналы в соседнем секторе. Интересно, не связано ли это с тем, почему нас атаковали?"
    d0.answers = {
        { answer = "Возможно. Что с того?", followUp = d1 }
    }

    d1.text = "Что бы ни вызывало эти сигналы... Я хотела бы исследовать это! Если бы мы смогли восстановить то, что их вызывает, мы, возможно, смогли бы понять, как использовать это против Ксотан."
    d1.answers = {
        { answer = "И вы хотите, чтобы я это восстановил, не так ли?", followUp = d2 }
    }

    d2.text = "Так было бы проще. Нам нужно отремонтироваться, перевооружиться и укрепить нашу базу операций здесь. Мы также смогли бы предоставить вам точку для отступления, если вы попадёте в беду."
    d2.answers = {
        { answer = "Это имеет смысл. Куда мне направляться?", followUp = d3 }
    }

    d3.text = "Что бы ни вызывало сигналы, должно быть в (" .. _X .. ":" .. _Y .. ")! Направляйтесь туда и исследуйте это. Убедитесь, что отправили нам телеметрию."
    d3.onEnd = "onPhase6DialogEnd"

    ESCCUtil.setTalkerTextColors({d0, d1, d2, d3}, "Адриана Сталь", MissionUT.getDialogTalkerColor1(), MissionUT.getDialogTextColor1())

    ScriptUI(_ID):interactShowDialog(d0, false)
end

function onPhase8Dialog(_ID)
    -- После восстановления артефакта.
    local _MethodName = "Диалог фазы 8"
    mission.Log(_MethodName, "Начало... ID: " .. tostring(_ID))

    local d0 = {}
    local d1 = {}
    local d2 = {}

    local _Player = Player()
    local _PlayerRank = _Player:getValue("_llte_cavaliers_rank")

    -- d0
    d0.text = "Привет, %1%! У нас было время, чтобы разобраться, что происходит с этими сигналами. Они исходили от странного артефакта, который мы нашли встроенным в корабль." % { _PLAYERRANK = _PlayerRank }
    d0.followUp = d1

    d1.text = "Я приказала команде спасателей вырезать артефакт из корпуса корабля, и мы переместили его на борт Клинка Императрицы. Я немедленно дам нашим исследовательским командам изучить его."
    d1.followUp = d2

    d2.text = "Как только мы узнаем больше об артефакте, я свяжусь с вами с подробностями. До тех пор берегите себя!"
    d2.onEnd = "onPhase8DialogEnd"

    ESCCUtil.setTalkerTextColors({d0, d1, d2}, "Адриана Сталь", MissionUT.getDialogTalkerColor1(), MissionUT.getDialogTextColor1())

    ScriptUI(_ID):interactShowDialog(d0, false)
end

-- Вызов клиентских/серверных функций
function registerMarkArtifact()
    local _MethodName = "Регистрация пометки артефакта"
    if onClient() then
        _MethodName = _MethodName .. " [КЛИЕНТ]"
        mission.Log(_MethodName, "Регистрация обратного вызова onPreRenderHud.")

        local _Player = Player()
        if _Player:registerCallback("onPreRenderHud", "onMarkArtifact") == 1 then
            mission.Log(_MethodName, "ПРЕДУПРЕЖДЕНИЕ: не удалось добавить обратный вызов prerender к скрипту.")
        end
    else
        _MethodName = _MethodName .. " [СЕРВЕР]"
        mission.Log(_MethodName, "Вызов на клиенте")

        invokeClientFunction(Player(), "registerMarkArtifact")
    end
end

function onPhase2DialogEnd()
    local _MethodName = "Конец диалога фазы 2"

    if onClient() then
        mission.Log(_MethodName, "Вызов на клиенте - вызов на сервере")

        invokeServerFunction("onPhase2DialogEnd")
        return
    else
        mission.Log(_MethodName, "Вызов на сервере")

        mission.data.description[3].fulfilled = true
        mission.data.description[4].visible = true
        mission.data.description[5].visible = true
        mission.data.location = mission.data.custom.sector2
        -- Запуск таймера переноса.
        runTransfer(mission.data.custom.sector1, mission.data.custom.sector2)
        mission.phases[2].timers[1] = { time = _TransferTimerTime, callback = function() nextPhase() end, repeating = false}
        mission.phases[2].timers[2] = { time = _TransferTimerHalfTime, callback = function()
            local _MethodName = "Фаза 2: обратный вызов таймера 2"
            mission.Log(_MethodName, "Начало...")
            local _X, _Y = mission.data.custom.sector2.x, mission.data.custom.sector2.y
            broadcastEmpressBladeMsg("Внимание всем кораблям! Мы прыгаем в \\s(%1%:%2%) через 60 секунд!", _X, _Y)
        end, repeating = false}

        sync()
    end
end
callable(nil, "onPhase2DialogEnd")

function onPhase3DialogEnd()
    local _MethodName = "Конец диалога фазы 3"

    if onClient() then
        mission.Log(_MethodName, "Вызов на клиенте - вызов на сервере")

        invokeServerFunction("onPhase3DialogEnd")
        return
    else
        mission.Log(_MethodName, "Вызов на сервере")

        mission.data.description[6].fulfilled = true
        mission.data.description[7].arguments = { _X = mission.data.custom.sector3.x, _Y = mission.data.custom.sector3.y }
        mission.data.description[7].visible = true
        mission.data.location = mission.data.custom.sector3
        -- Запуск таймера переноса
        runTransfer(mission.data.custom.sector2, mission.data.custom.sector3)
        mission.phases[3].timers[3] = { time = _TransferTimerTime, callback = function() nextPhase() end, repeating = false }
        mission.phases[3].timers[4] = { time = _TransferTimerHalfTime, callback = function()
            local _X, _Y = mission.data.custom.sector3.x, mission.data.custom.sector3.y
            broadcastEmpressBladeMsg("Внимание всем кораблям! Мы прыгаем в \\s(%1%:%2%) через 60 секунд!", _X, _Y)
        end, repeating = false}

        showMissionUpdated(mission._Name)
        sync()
    end
end
callable(nil, "onPhase3DialogEnd")

function onPhase4Dialog1End()
    local _MethodName = "Конец диалога фазы 4, часть 1"

    if onClient() then
        mission.Log(_MethodName, "Вызов на клиенте - вызов на сервере")

        invokeServerFunction("onPhase4Dialog1End")
        return
    else
        -- Добавление осадного орудия к "Враждебности".
        local _Sector = Sector()
        local _AnimosityTable = {_Sector:getEntitiesByScriptValue("is_animosity")}
        local _Animosity = _AnimosityTable[1]
        local _SGD = {}
        _SGD._CodesCracked = false
        _SGD._Velocity = 220
        _SGD._ShotCycle = 30
        _SGD._ShotCycleSupply = 0
        _SGD._ShotCycleTimer = 30
        _SGD._UseSupply = false
        _SGD._FragileShots = false
        _SGD._BaseDamagePerShot = 825000
        _SGD._TargetPriority = 6
        _SGD._TargetTag = "_llte_cav_supercap"

        _Animosity:addScript("entity/stationsiegegun.lua", _SGD)
        _Animosity:addScript("player/missions/empress/story/story4/lltestory4animositybehavior.lua")
        -- Спавн волны пиратов немедленно и добавление контроллера защиты пиратов в сектор.
        spawnPirateWave(2)

        local _DCD = {}
        _DCD._DefenseLeader = _Animosity.id
        _DCD._CanTransfer = false
        _DCD._CodesCracked = false
        _DCD._DefenderCycleTime = 65
        _DCD._DangerLevel = 10
        _DCD._MaxDefenders = 7
        _DCD._MaxDefendersSpawn = 5
        _DCD._DefenderHPThreshold = 0.25
        _DCD._DefenderOmicronThreshold = 0.25
        _DCD._ForceWaveAtThreshold = 0.7
        _DCD._ForcedDefenderDamageScale = 1.5
        _DCD._IsPirate = true
        _DCD._Factionid = _Animosity.factionIndex
        _DCD._PirateLevel = mission.data.custom.pirateLevel
        _DCD._UseLeaderSupply = false
        _DCD._LowTable = "High"

        _Sector:addScript("sector/background/defensecontroller.lua", _DCD)

        -- Установка всех кораблей Кавалеров в агрессивный режим.
        local _CavShips = {_Sector:getEntitiesByScriptValue("is_cavaliers")}
        for _, _Cav in pairs(_CavShips) do
            ShipAI(_Cav.index):setAggressive()
        end
        local _PirateShips = {_Sector:getEntitiesByScriptValue("is_pirate")}
        for _, _Pirate in pairs(_PirateShips) do
            ShipAI(_Pirate.index):setAggressive()
            if _Pirate:getValue("is_animosity") then -- сбросить неуязвимый щит.
                Shield(_Pirate.id).invincible = false
            end
        end
        -- Регистрация "Враждебности" как босса [обрабатывается на клиенте].
    end
end
callable(nil, "onPhase4Dialog1End")

function onPhase4Dialog2End()
    local _MethodName = "Конец диалога фазы 4, часть 2"

    if onClient() then
        mission.Log(_MethodName, "Вызов на клиенте - вызов на сервере")

        invokeServerFunction("onPhase4Dialog2End")
        return
    else
        mission.Log(_MethodName, "Вызов на сервере")

        mission.data.description[9].arguments = { _X = mission.data.custom.sector4.x, _Y = mission.data.custom.sector4.y }
        mission.data.description[9].visible = true
        mission.data.location = mission.data.custom.sector4
        -- Запуск таймера переноса
        runTransfer(mission.data.custom.sector3, mission.data.custom.sector4)
        mission.phases[4].timers[3] = { time = _TransferTimerTime, callback = function() nextPhase() end, repeating = false }
        mission.phases[4].timers[4] = { time = _TransferTimerHalfTime, callback = function()
            local _X, _Y = mission.data.custom.sector4.x, mission.data.custom.sector4.y
            broadcastEmpressBladeMsg("Внимание всем кораблям! Мы прыгаем в \\s(%1%:%2%) через 60 секунд! Это перенесёт нас через барьер!", _X, _Y)
        end, repeating = false}

        showMissionUpdated(mission._Name)
        sync()
    end
end
callable(nil, "onPhase4Dialog2End")

function onPhase5Dialog1End()
    local _MethodName = "Конец диалога фазы 5, часть 1"

    if onClient() then
        mission.Log(_MethodName, "Вызов на клиенте - вызов на сервере")

        invokeServerFunction("onPhase5Dialog1End")
        return
    else
        -- Установка первого таймера
        mission.Log(_MethodName, "Установка таймера предупреждения.")
        mission.phases[5].timers[1] = { time = 11, callback = function()
            broadcastEmpressBladeMsg("Эти сигналы в подпространстве слишком сильны для наших сканеров! Что это!?")
        end, repeating = false}
        -- Установка второго таймера.
        mission.Log(_MethodName, "Установка таймера роя.")
        mission.phases[5].timers[2] = { time = 14, callback = function()
            mission.data.custom.miniswarm = true
            mission.data.description[10].visible = true
            spawnXsotanWave(1)
            mission.phases[5].timers[3] = { time = 20, callback = function()
                local _MethodName = "Фаза 5: Таймер 3"
                if mission.data.custom.miniswarm and atTargetLocation() then
                    mission.Log(_MethodName, "Спавн следующей волны Ксотан.")
                    local _WaveType = 1
                    if mission.data.custom.xsotankilled >= 20 then
                        _WaveType = 2
                    end
                    spawnXsotanWave(_WaveType)
                end
            end, repeating = true }
            showMissionUpdated(mission._Name)
            sync()
        end, repeating = false}
        -- Установка первого триггера.
        mission.Log(_MethodName, "Установка триггера уничтожения роя Ксотан.")
        mission.phases[5].triggers[2] = {
            condition = function()
                if onServer() then
                    return ESCCUtil.countEntitiesByValue("is_xsotan") == 0 and not mission.data.custom.miniswarm and mission.data.custom.xsotankilled >= 40 and atTargetLocation()
                else
                    -- Мы не делаем этого на клиенте.
                    return true
                end
            end,
            callback = function()
                if onServer() then
                    local _MethodName = "Фаза 5: обратный вызов триггера уничтожения Ксотан"
                    mission.data.description[10].fulfilled = true
                    sync()

                    invokeClientFunction(Player(), "onPhase5Dialog2", mission.data.custom.empressBladeid)
                end
            end,
            repeating = false
        }
        -- Установка второго триггера.
        mission.Log(_MethodName, "Установка триггера продолжения роя.")
        mission.phases[5].triggers[3] = {
            condition = function()
                if onServer() then
                    return ESCCUtil.countEntitiesByValue("is_xsotan") <= 1 and mission.data.custom.miniswarm
                else
                    -- Триггер только на сервере.
                    return true
                end
            end,
            callback = function()
                if onServer() and atTargetLocation() then
                    spawnXsotanWave(3)
                end
            end,
            repeating = true
        }
    end
end
callable(nil, "onPhase5Dialog1End")

function onPhase5Dialog2End()
    local _MethodName = "Конец диалога фазы 5, часть 2"

    if onClient() then
        mission.Log(_MethodName, "Вызов на клиенте - вызов на сервере")

        invokeServerFunction("onPhase5Dialog2End")
        return
    else
        mission.Log(_MethodName, "Вызов на сервере")

        mission.data.description[11].arguments = { _X = mission.data.custom.sector5.x, _Y = mission.data.custom.sector5.y }
        mission.data.description[11].visible = true
        mission.data.location = mission.data.custom.sector5
        -- Запуск таймера переноса
        runTransfer(mission.data.custom.sector4, mission.data.custom.sector5)
        mission.phases[5].timers[4] = { time = _TransferTimerTime, callback = function() nextPhase() end, repeating = false }
        mission.phases[5].timers[5] = { time = _TransferTimerHalfTime, callback = function()
            local _X, _Y = mission.data.custom.sector5.x, mission.data.custom.sector5.y
            broadcastEmpressBladeMsg("Внимание всем кораблям! Мы прыгаем в \\s(%1%:%2%) через 60 секунд!", _X, _Y)
        end, repeating = false}

        showMissionUpdated(mission._Name)
        sync()
    end
end
callable(nil, "onPhase5Dialog2End")

function onPhase6DialogEnd()
    local _MethodName = "Конец диалога фазы 6"

    -- Это, слава богу, просто.
    if onClient() then
        mission.Log(_MethodName, "Вызов на клиенте - вызов на сервере")

        invokeServerFunction("onPhase6DialogEnd")
        return
    else
        mission.Log(_MethodName, "Вызов на сервере")
        nextPhase()
    end
end
callable(nil, "onPhase6DialogEnd")

function onPhase8DialogEnd()
    local _MethodName = "Конец диалога фазы 8"
    if onClient() then
        mission.Log(_MethodName, "Вызов на клиенте - вызов на сервере")

        invokeServerFunction("onPhase8DialogEnd")
        return
    else
        mission.Log(_MethodName, "Вызов на сервере")
        -- Мы наконец-то закончили эту миссию. Боже мой.
        runFullSectorCleanup_llte()
        llteStory4_finishAndReward()
    end
end
callable(nil, "onPhase8DialogEnd")

--endregion