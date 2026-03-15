--[[
    Побочная миссия ранга 2.
    Истребление заражения Ксотан
    [ПЕРЕВЕДЕНО]
    ДОПОЛНИТЕЛЬНЫЕ ТРЕБОВАНИЯ:
        - Ранг 2
    ПРИМЕРНЫЙ ПЛАН:
        - Переместиться в целевой сектор.
        - Начать уничтожение Ксотан.
        - После уничтожения 25 Ксотан появится Заразитель.
        - Уничтожьте его, и миссия завершена. Это буквально всё.
    УРОВЕНЬ ОПАСНОСТИ:
        1+ - [Эти условия действуют независимо от уровня опасности]
            - Максимальное количество Ксотан в секторе: 10.
            - Размер Ксотан: от 1 до 3.
            - Размер Заразителя: 3 + максимальный размер + минимальный размер, и он имеет бонус урона +60%. Кроме того, он всегда является Призывателем.
        6 - [Эти условия действуют при уровне опасности 6 и выше]
            - Первый Ксотан в каждой волне имеет 50% шанс быть Квантовым.
        8 - [Эти условия действуют при уровне опасности 8 и выше]
            - Увеличивает максимальное количество Ксотан на 1 (до 11).
            - Увеличивает максимальный размер Ксотан на 1 (размер от 1 до 4).
        10 - [Эти условия действуют при уровне опасности 10]
            - Нужно убить 30 Ксотан вместо 25.
            - Первый Ксотан в каждой волне гарантированно будет Квантовым.
            - Второй Ксотан в каждой волне имеет 50% шанс быть Призывателем. Очевидно, это не имеет эффекта, если в волне только 1 Ксотан.
            - Увеличивает максимальное количество Ксотан на 1 (до 12).
            - Увеличивает минимальный и максимальный размер Ксотан на 1 (размер от 2 до 5).
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
local SectorUpgradeGenerator = include("upgradegenerator")
local SectorTurretGenerator = include("sectorturretgenerator")
local Xsotan = include("story/xsotan")
local SectorSpecifics = include("sectorspecifics")
local Balancing = include("galaxy")
local SpawnUtility = include("spawnutility")

mission._Debug = 0
mission._Name = "Истребление заражения Ксотан"

-- Настройка данных миссии
local llte_sidemission_init = initialize
function initialize()
    local _MethodName = "Инициализация"
    mission.Log(_MethodName, "Начало миссии 'Истребление заражения Ксотан'...")

    if onServer() then
        if not _restoring then
            -- У нас нет доступа к данным объявления миссии, поэтому определяем здесь.
            local specs = SectorSpecifics()
            local _Rgen = ESCCUtil.getRand()
            local x, y = Sector():getCoordinates()
            local insideBarrier = MissionUT.checkSectorInsideBarrier(x, y)
            local coords = specs.getShuffledCoordinates(random(), x, y, 5, 12)
            local serverSeed = Server().seed
            local target = nil

            -- Поиск сектора, который не в чёрном списке.
            for _, coord in pairs(coords) do
                mission.Log(_MethodName, "Оценка координат X: " .. tostring(coord.x) .. " - Y: " .. tostring(coord.y))
                local regular, offgrid, blocked, home = specs:determineContent(coord.x, coord.y, serverSeed)

                if insideBarrier == MissionUT.checkSectorInsideBarrier(coord.x, coord.y) then
                    if not regular and not offgrid and not blocked and not home then
                        if not Galaxy():sectorExists(coord.x, coord.y) then
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
            mission.data.brief = "Истребление заражения Ксотан"
            mission.data.title = "Истребление заражения Ксотан"
            mission.data.icon = "data/textures/icons/cavaliers.png"
            mission.data.description = {
                "Вам поручено уничтожить близлежащую область, заражённую Ксотан.",
                { text = "Направляйтесь в сектор (${xLoc}:${yLoc}) и уничтожьте всех присутствующих Ксотан", arguments = {xLoc = target.x, yLoc = target.y}, bulletPoint = true, fulfilled = false },
                { text = "Уничтожьте Заразителя Ксотан", bulletPoint = true, fulfilled = false, visible = false }
            }

            local _RewardBase = 80000
            -- Пользовательские данные миссии:
            -- .dangerLevel
            -- .maximumXsotan
            -- .xsotanKillreq
            -- .xsotanSizeBonus
            -- .xsotanKilled
            -- .infestorSpawned
            mission.data.custom.maximumXsotan = 10
            mission.data.custom.xsotanSizeBonus = { min = 0, max = 2 }
            mission.data.custom.xsotanKilled = 0
            mission.data.custom.xsotanKillreq = 25

            mission.data.custom.dangerLevel = _Rgen:getInt(1, 10)
            if mission.data.custom.dangerLevel >= 8 then
                _RewardBase = _RewardBase + 3000
                mission.data.custom.maximumXsotan = mission.data.custom.maximumXsotan + 1
                mission.data.custom.xsotanSizeBonus.max = mission.data.custom.xsotanSizeBonus.max + 1
            end
            if mission.data.custom.dangerLevel == 10 then
                _RewardBase = _RewardBase + 5500
                mission.data.custom.maximumXsotan = mission.data.custom.maximumXsotan + 1
                mission.data.custom.xsotanSizeBonus.min = mission.data.custom.xsotanSizeBonus.min + 1
                mission.data.custom.xsotanSizeBonus.max = mission.data.custom.xsotanSizeBonus.max + 1
                mission.data.custom.xsotanKillreq = mission.data.custom.xsotanKillreq + 5
            end

            if insideBarrier then
                _RewardBase = _RewardBase * 2
            end

            local missionReward = ESCCUtil.clampToNearest(_RewardBase * Balancing.GetSectorRewardFactor(Sector():getCoordinates()), 5000, "Up")

            missionData_in = {location = target, reward = {credits = missionReward}}

            llte_sidemission_init(missionData_in)
            Player():sendChatMessage("Кавалеры", 0, "Очаг заражения находится в секторе \\s(%1%:%2%). Пожалуйста, уничтожьте всех Ксотан.", target.x, target.y)
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

-- Таймеры фазы 1
if onServer() then
    mission.phases[1].timers[1] = {
        time = 60,
        callback = function()
            local _Sector = Sector()
            local _x, _y = _Sector:getCoordinates()
            if _x == mission.data.location.x and _y == mission.data.location.y then
                spawnXsotanWave()
            end
        end,
        repeating = true
    }
end

mission.phases[1].onTargetLocationEntered = function(x, y)
    local _MethodName = "Фаза 1: вход в целевой сектор"
    mission.Log(_MethodName, "Начало...")

    local rgen = ESCCUtil.getRand()
    mission.Log(_MethodName, "Генерация полей астероидов.")
    local generator = SectorGenerator(x, y)
    for _ = 1, rgen:getInt(2, 6) do
        generator:createSmallAsteroidField()
    end

    mission.Log(_MethodName, "Генерация Ксотан.")
    -- Спавн максимального количества Ксотан.
    spawnXsotanWave()
end

mission.phases[1].onTargetLocationLeft = function(x, y)
    local _MethodName = "Фаза 1: выход из целевого сектора"
    mission.Log(_MethodName, "Начало...")
    -- Сброс.
    mission.data.custom.xsotanKilled = 0
end

mission.phases[1].updateTargetLocationServer = function(timeStep)
    local _MethodName = "Фаза 1: обновление целевого сектора"

    local _XKR = mission.data.custom.xsotanKillreq
    if mission.data.custom.xsotanKilled >= _XKR and not mission.data.custom.infestorSpawned then
        mission.Log(_MethodName, tostring(_XKR) .. "+ Ксотан уничтожено. Спавн Заразителя.")
        spawnXsotanInfestor()

        mission.data.description[3].visible = true
        showMissionUpdated("Истребление заражения Ксотан")

        mission.data.custom.infestorSpawned = true
        sync()
    end
end

mission.phases[1].onEntityDestroyed = function(id, lastDamageInflictor)
    local _MethodName = "Фаза 1: объект уничтожен"
    local _Sector = Sector()

    local _X, _Y = _Sector:getCoordinates()

    if _X == mission.data.location.x and _Y == mission.data.location.y then
        local entity = Entity(id)
        if valid(entity) and entity:getValue("_llte_infestation_xsotan") then
            mission.data.custom.xsotanKilled = mission.data.custom.xsotanKilled + 1
        end

        if entity:getValue("_llte_is_infestor") then
            local rgen = ESCCUtil.getRand()
            local _Xsos = {Sector():getEntitiesByScriptValue("is_xsotan")}
            if _Xsos then
                for _, _Xso in pairs(_Xsos) do
                    _Xso:addScriptOnce("utility/delayeddelete.lua", rgen:getFloat(5, 9))
                end
            end

            llteSide4_finishAndReward()
        end

        mission.Log(_MethodName, tostring(mission.data.custom.xsotanKilled) .. " Ксотан уничтожено на данный момент.")
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
function spawnXsotanWave()
    local _MethodName = "Спавн Ксотан"

    local _SpawnCount = mission.data.custom.maximumXsotan - ESCCUtil.countEntitiesByValue("_llte_infestation_xsotan"
    local rgen = ESCCUtil.getRand()
    local _Generator = SectorGenerator(Sector():getCoordinates())
    local _Players = {Sector():getPlayers()}
    local _XsotanByNameTable = {}
    local _XsotanTable = {}

    mission.Log(_MethodName, "Спавн " .. tostring(_SpawnCount) .. " кораблей Ксотан.")
    -- Используем тот же метод для спавна фоновых Ксотан в событии роя.
    -- Если уровень опасности 6+, 50% шанс добавить квантового Ксотан в каждую волну.
    local _AddSmn = false
    local _AddQuantum = false
    if mission.data.custom.dangerLevel >= 6 and rgen:getInt(1, 2) - 1 == 1 then
        mission.Log(_MethodName, "Добавление квантового Ксотан в таблицу спавна (уровень опасности 6)")
        _AddQuantum = true
    end
    -- Если уровень опасности 10, 100% шанс добавить квантового и 50% шанс добавить призывателя в каждую волну.
    if mission.data.custom.dangerLevel == 10 then
        mission.Log(_MethodName, "Добавление квантового Ксотан в таблицу спавна (уровень опасности 10)")
        _AddQuantum = true
        if rgen:getInt(1, 2) - 1 == 1 then
            mission.Log(_MethodName, "Добавление призывателя в таблицу спавна")
            _AddSmn = true
        end
    end

    -- Формируем таблицу имён Ксотан.
    if _AddQuantum then table.insert(_XsotanByNameTable, "Квантовый") end
    if _SpawnCount > 1 and _AddSmn then table.insert(_XsotanByNameTable, "Призыватель") end
    if _SpawnCount - #_XsotanByNameTable > 0 then
        for _ = 1, _SpawnCount - #_XsotanByNameTable do
            table.insert(_XsotanByNameTable, "Корабль")
        end
    end

    mission.Log(_MethodName, "Спавн итогового количества " .. tostring(#_XsotanByNameTable) .. " кораблей Ксотан.")
    -- Спавн Ксотан на основе таблицы имён.
    for _ = 1, #_XsotanByNameTable do
        local xsoSize = 1.0 + rgen:getInt(mission.data.custom.xsotanSizeBonus.min, mission.data.custom.xsotanSizeBonus.max)
        local _Xsotan = nil
        local _Dist = 1500
        if _XsotanByNameTable[_] == "Призыватель" then
            _Xsotan = Xsotan.createSummoner(_Generator:getPositionInSector(_Dist), xsoSize)
        elseif _XsotanByNameTable[_] == "Квантовый" then
            _Xsotan = Xsotan.createQuantum(_Generator:getPositionInSector(_Dist), xsoSize)
        else
            _Xsotan = Xsotan.createShip(_Generator:getPositionInSector(_Dist), xsoSize)
        end

        if _Xsotan then
            if valid(_Xsotan) then
                for _, p in pairs(_Players) do
                    ShipAI(_Xsotan.id):registerEnemyFaction(p.index)
                end
                ShipAI(_Xsotan.id):setAggressive()
            end
            _Xsotan:setValue("_llte_infestation_xsotan", true)
            table.insert(_XsotanTable, _Xsotan)
        else
            mission.Log(_MethodName, "ОШИБКА: Ксотан не был создан")
        end
    end

    SpawnUtility.addEnemyBuffs(_XsotanTable)
end

function spawnXsotanInfestor()
    local _MethodName = "Спавн Заразителя Ксотан"
    mission.Log(_MethodName, "Начало...")

    local _InfestorSize = mission.data.custom.xsotanSizeBonus.min + mission.data.custom.xsotanSizeBonus.max + 3
    local _Players = {Sector():getPlayers()}
    local _X, _Y = Sector():getCoordinates()
    local _Generator = SectorGenerator(_X, _Y)
    -- Инициализация генераторов турелей и улучшений.
    local _TurretGenerator = SectorTurretGenerator()
    local _TurretRarities = _TurretGenerator:getSectorRarityDistribution(_X, _Y)
    local _UpgradeGenerator = SectorUpgradeGenerator()
    local _UpgradeRarities = _UpgradeGenerator:getSectorRarityDistribution(_X, _Y)

    local _XsotanInfestor = Xsotan.createSummoner(_Generator:getPositionInSector(2500), _InfestorSize)
    if valid(_XsotanInfestor) then
        for _, p in pairs(_Players) do
            ShipAI(_XsotanInfestor.id):registerEnemyFaction(p.index)
        end
        ShipAI(_XsotanInfestor.id):setAggressive()
    end
    _XsotanInfestor:setTitle("${toughness}Заразитель Ксотан", {toughness = ""})
    _XsotanInfestor:setValue("_llte_is_infestor", true)

    -- Добавление дополнительного лута. Гарантируем редкие+ предметы с меньшей вероятностью редких.
    local _DropCount = 2
    _TurretRarities[-1] = 0 -- Нет обычных
    _TurretRarities[0] = 0 -- Нет обычных
    _TurretRarities[1] = 0 -- Нет необычных
    _TurretRarities[2] = _TurretRarities[2] * 0.5 -- Уменьшаем шанс редких вдвое

    _UpgradeRarities[-1] = 0
    _UpgradeRarities[0] = 0
    _UpgradeRarities[1] = 0
    _UpgradeRarities[2] = _UpgradeRarities[2] * 0.5 -- См. выше.

    mission.Log(_MethodName, "Добавление дополнительных турелей и систем в лут Заразителя")
    _TurretGenerator.rarities = _TurretRarities
    for _ = 1, _DropCount do
        Loot(_XsotanInfestor):insert(InventoryTurret(_TurretGenerator:generate(_X, _Y)))
    end
    mission.Log(_MethodName, "Добавление дополнительных систем в лут.")
    for _ = 1, _DropCount do
        Loot(_XsotanInfestor):insert(_UpgradeGenerator:generateSectorSystem(_X, _Y, getValueFromDistribution(_UpgradeRarities)))
    end

    if mission.data.custom.dangerLevel == 10 then
        _TurretRarities[2] = 0
        _UpgradeRarities[2] = 0
        mission.Log(_MethodName, "Добавление дополнительной исключительной+ турели/системы в лут Заразителя")

        Loot(_XsotanInfestor):insert(InventoryTurret(_TurretGenerator:generate(_X, _Y)))
        Loot(_XsotanInfestor):insert(_UpgradeGenerator:generateSectorSystem(_X, _Y, getValueFromDistribution(_UpgradeRarities)))
    end

    local _XsotanInfestorTable = {}
    table.insert(_XsotanInfestorTable, _XsotanInfestor)
    SpawnUtility.addEnemyBuffs(_XsotanInfestorTable)

    _XsotanInfestor.damageMultiplier = (_XsotanInfestor.damageMultiplier or 1) * 1.6
end

function llteSide4_finishAndReward()
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
        "Спасибо за уничтожение этих Ксотан.",
        "Мы ценим, что вы справились с заражением."
    }

    local _RepReward = 2
    if mission.data.custom.dangerLevel == 10 then
        _RepReward = _RepReward + 1
    end

    -- Увеличение репутации на 2 (3 при уровне опасности 10)
    mission.data.reward.paymentMessage = "Получено %1% кредитов за уничтожение заражения Ксотан."
    _Player:setValue("_llte_cavaliers_rep", _Player:getValue("_llte_cavaliers_rep") + _RepReward)
    _Player:sendChatMessage("Кавалеры", 0, _WinMsgTable[_Rgen:getInt(1, #_WinMsgTable)] .. " Мы перевели вознаграждение на ваш счёт.")
    reward()
    accomplish()
end

--endregion