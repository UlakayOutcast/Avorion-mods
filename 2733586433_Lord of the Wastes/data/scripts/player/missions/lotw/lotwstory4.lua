--[[
    Защита секретного аванпоста
    ЗАМЕТКИ:
        - Отслеживайте две группы пиратов: одна постоянно атакует базу, другая ведёт себя агрессивно.
        - Увеличивайте HP военного аванпоста на 20% каждый раз, когда игрок проваливает миссию.
    ДОПОЛНИТЕЛЬНЫЕ ТРЕБОВАНИЯ:
        - Завершить третью миссию LOTW.
    ПРИМЕРНЫЙ ПЛАН:
        - Прибыть в сектор, защитить аванпост.
        - Уничтожить 20 пиратов для победы.
    УРОВЕНЬ ОПАСНОСТИ:
        5 - Две постоянные группы: 1 бандит и 2 пирата будут появляться на заднем плане.
        5 - Начать спавн мародёра + дополнительного бандита после уничтожения 5 пиратов.
        5 - Одна группа будет специально атаковать аванпост.
        5 - Другая группа будет вести себя агрессивно.
        5 - Спавнить 2 защитника после уничтожения 10 пиратов.
]]
package.path = package.path .. ";data/scripts/lib/?.lua"
package.path = package.path .. ";data/scripts/?.lua"

include("callable")
include("structuredmission")

ESCCUtil = include("esccutil")

local SectorGenerator = include("SectorGenerator")
local AsyncPirateGenerator = include("asyncpirategenerator")
local Balancing = include("galaxy")
local SpawnUtility = include("spawnutility")
local Placer = include("placer")
local TorpedoUtility = include("torpedoutility")

mission._Debug = 0
mission._Name = "Защита секретного аванпоста"

-- Настройка данных миссии
mission.data.brief = mission._Name
mission.data.title = mission._Name
mission.data.autoTrackMission = true
mission.data.icon = "data/textures/icons/silicium.png"
mission.data.description = {
    { text = "Вы получили следующий экстренный запрос от ${factionName}:" },
    { text = "Это экстренный запрос. Несмотря на ваш успех в подрыве цепочки поставок пиратов, им удалось найти резервный склад материалов и теперь они атакуют одно из наших сооружений в полную силу. Мы думали, что оно скрыто, поэтому оставили его уязвимым для контратаки. У вас должно быть достаточно денег и оборудования, чтобы задействовать второй корабль. Аванпост находится в секторе (${_X}:${_Y}). Нам нужна ваша помощь для его защиты." },
    { text = "Постройте и оснастите второй корабль", bulletPoint = true, fulfilled = false },
    { text = "Направляйтесь в сектор (${location.x}:${location.y})", bulletPoint = true, fulfilled = false, visible = false },
    { text = "Защитите военный аванпост от пиратов", bulletPoint = true, fulfilled = false, visible = false },
    { text = "Приоритетно уничтожайте отмеченных торпедоносцев", bulletPoint = true, fulfilled = false, visible = false }
}
mission.data.accomplishMessage = "Спасибо. Вознаграждение переведено на ваш счёт. Мы свяжемся с вами."

local LOTW_Mission_init = initialize
function initialize()
    local methodName = "Инициализация"
    mission.Log(methodName, "Начало...")

    if onServer() then
        local _Sector = Sector()
        local _X, _Y = _Sector:getCoordinates()

        if not _restoring then
            local _Player = Player()
            local _FailureCt = _Player:getValue("_lotw_mission4_failures") or 0

            mission.data.custom.dangerLevel = 5
            mission.data.custom.destroyed = 0
            mission.data.custom.friendlyFaction = _Player:getValue("_lotw_faction")
            mission.data.custom.missionsFailed = _FailureCt
            mission.data.custom.failureCounter = 0

            mission.data.custom.outpostLocation = lotwStory4_getNextLocation()

            local missionReward = ESCCUtil.clampToNearest(150000 + (50000 * Balancing.GetSectorRewardFactor(_Sector:getCoordinates())), 5000, "Up")

            missionData_in = {location = nil, reward = {credits = missionReward, relations = 12000, paymentMessage = "Получено %1% кредитов за защиту аванпоста."}}

            LOTW_Mission_init(missionData_in)

            lotwStory4_setMissionFactionData(_X, _Y)
        else
            LOTW_Mission_init()
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

mission.globalPhase.onFail = function()
    local _Player = Player()
    local _FailureCt = _Player:getValue("_lotw_mission4_failures") or 0
    _FailureCt = _FailureCt + 1
    _Player:setValue("_lotw_mission4_failures", _FailureCt)
end

mission.phases[1] = {}
mission.phases[1].timers = {}
mission.phases[1].onBeginServer = function()
    local methodName = "Фаза 1: Начало на сервере"
    mission.Log(methodName, "Начало...")

    local _Faction = Faction(mission.data.custom.friendlyFaction)
    local _Player = Player()

    mission.data.description[1].arguments = { factionName = _Faction.name }
    mission.data.description[2].arguments = { _X = mission.data.custom.outpostLocation.x, _Y = mission.data.custom.outpostLocation.y }

    if _Player.numShips > 1 then
        nextPhase()
    else
        mission.phases[1].showUpdateOnEnd = true
    end
end

mission.phases[1].timers[1] = {
    time = 10,
    callback = function()
        local _Player = Player()
        if _Player.numShips > 1 then
            nextPhase()
        end
    end,
    repeating = true
}

mission.phases[2] = {}
mission.phases[2].noBossEncountersTargetSector = true
mission.phases[2].noPlayerEventsTargetSector = true
mission.phases[2].noLocalPlayerEventsTargetSector = true
mission.phases[2].showUpdateOnEnd = true
mission.phases[2].onBeginServer = function()
    local methodName = "Фаза 2: Начало на сервере"
    mission.Log(methodName, "Начало...")

    mission.data.location = mission.data.custom.outpostLocation

    mission.data.description[3].fulfilled = true
    mission.data.description[4].arguments = { x = mission.data.location.x, y = mission.data.location.y }
    mission.data.description[4].visible = true
end

mission.phases[2].onTargetLocationEntered = function(x, y)
    local methodName = "Фаза 2: Вход в целевой сектор"
    mission.Log(methodName, "Начало...")

    mission.data.description[4].fulfilled = true
    mission.data.description[5].visible = true
    mission.data.description[6].visible = true

    lotwStory4_buildSector(x, y)
end

mission.phases[2].onTargetLocationArrivalConfirmed = function(x, y)
    local _Sector = Sector()
    local _DefendObjective = {_Sector:getEntitiesByScriptValue("_lotw_mission4_defendobjective")}

    _Sector:broadcastChatMessage(_DefendObjective[1], ChatMessageType.Chatter, "Приоритетно уничтожайте врагов с торпедами! Мы отметили их специальной иконкой.")

    nextPhase()
end

mission.phases[3] = {}
mission.phases[3].timers = {}
mission.phases[3].noBossEncountersTargetSector = true
mission.phases[3].noPlayerEventsTargetSector = true
mission.phases[3].noLocalPlayerEventsTargetSector = true
mission.phases[3].onBeginServer = function()
    lotwStory4_spawnBackgroundPirates()
end

mission.phases[3].onEntityDestroyed = function(_ID, _LastDamageInflictor)
    local methodName = "Фаза 3: Уничтожение объекта"
    mission.Log(methodName, "Начало...")

    local _Entity = Entity(_ID)

    if _Entity:getValue("_lotw_mission4_objective") then
        mission.Log(methodName, "Это цель.")
        mission.data.custom.destroyed = mission.data.custom.destroyed + 1
    end

    if _Entity:getValue("_lotw_mission4_defendobjective") then
        ESCCUtil.allPiratesDepart()
        fail()
    end
end

mission.phases[3].onTargetLocationLeft = function(x, y)
    mission.data.custom.destroyed = 0
end

if onServer() then
    mission.phases[3].timers[1] = {
        time = 45,
        callback = function()
            if atTargetLocation() then
                lotwStory4_spawnBackgroundPirates()
            end
        end,
        repeating = true
    }

    mission.phases[3].timers[2] = {
        time = 60,
        callback = function()
            if not atTargetLocation() then
                mission.data.custom.failureCounter = mission.data.custom.failureCounter + 1
            end
        end,
        repeating = true
    }

    mission.phases[3].timers[3] = {
        time = 10,
        callback = function()
            local methodName = "Фаза 3: Обратный вызов таймера 3"
            mission.Log(methodName, "Начало...")
            mission.Log(methodName, "Количество уничтоженных пиратов: " .. tostring(mission.data.custom.destroyed))
            if mission.data.custom.destroyed >= 20 then
                ESCCUtil.allPiratesDepart()
                lotwStory4_finishAndReward()
            end
            if mission.data.custom.failureCounter >= 3 then
                fail()
            end
        end,
        repeating = true
    }
end

function lotwStory4_setMissionFactionData(_X, _Y)
    local methodName = "Установка данных фракции миссии"
    mission.Log(methodName, "Начало...")
    local _Faction = Faction(Player():getValue("_lotw_faction"))
    mission.data.giver = {}
    mission.data.giver.id = _Faction.index
    mission.data.giver.factionIndex = _Faction.index
    mission.data.giver.coordinates = { x = _X, y = _Y }
    mission.data.giver.baseTitle = _Faction.name
end

function lotwStory4_getNextLocation()
    local methodName = "Получение следующего сектора"
    mission.Log(methodName, "Поиск сектора...")
    local x, y = Sector():getCoordinates()
    local target = {}

    target.x, target.y = MissionUT.getEmptySector(x, y, 4, 10, false)

    mission.Log(methodName, "Координата X следующего сектора: " .. tostring(target.x) .. ", координата Y следующего сектора: " .. tostring(target.y))
    if not target or not target.x or not target.y then
        mission.Log(methodName, "Не удалось найти подходящий сектор для миссии. Завершение скрипта.")
        terminate()
        return
    end

    return target
end

function lotwStory4_buildSector(_X, _Y)
    local methodName = "Создание сектора"
    local _Faction = Faction(mission.data.custom.friendlyFaction)

    if not _Faction or _Faction.isPlayer or _Faction.isAlliance then
        print("ОШИБКА: НЕ УДАЛОСЬ НАЙТИ ФРАКЦИЮ МИССИИ")
        terminate()
        return
    end

    local _sector = Sector()
    local _Rgen = ESCCUtil.getRand()
    local generator = SectorGenerator(_X, _Y)

    for _ = 1, _Rgen:getInt(3, 5) do
        generator:createSmallAsteroidField()
    end
    generator:createAsteroidField()

    local _Station = generator:createMilitaryBase(_Faction)
    _Station.position = Matrix()
    _Station:setValue("no_chatter", true)
    _Station:setValue("_lotw_mission4_defendobjective", true)
    local _StationSphere = _Station:getBoundingSphere()
    local _AsteroidRemovalSphere = Sphere(_StationSphere.center, _StationSphere.radius * 15)
    local _RemovalCandidates = {_sector:getEntitiesByLocation(_AsteroidRemovalSphere)}
    mission.Log(methodName, "Найдено " .. #_RemovalCandidates .. " кандидатов для удаления. Все астероиды в этом списке будут удалены.")
    for _, _En in pairs(_RemovalCandidates) do
        if _En.isAsteroid then
            _sector:deleteEntity(_En)
        end
    end

    _Station:removeScript("consumer.lua")
    _Station:removeScript("backup.lua")
    _Station:removeScript("missionbulletins.lua")
    _sector:removeScript("traders.lua")

    local _ShipAI = ShipAI(_Station)
    _ShipAI:setAggressive()

    _Station:addCrew(60, CrewMan(CrewProfessionType.Pilot))

    Boarding(_Station).boardable = false

    local _StationBay = CargoBay(_Station)
    _StationBay:clear()
    _Station:setDropsLoot(false)

    mission.data.custom.stationId = _Station.index.string

    local _DuraFactor = 1.0
    if mission.data.custom.missionsFailed > 0 then
        local _Factor1 = 0.2 * mission.data.custom.missionsFailed
        local _Factor2 = 0

        if mission.data.custom.missionsFailed > 5 then
            local _ExpFactor = math.max(1, mission.data.custom.missionsFailed - 5)
            _Factor2 = 0.2 * (_ExpFactor * _ExpFactor)
        end

        _DuraFactor = _DuraFactor + _Factor1 + _Factor2
    end

    local _Dura = Durability(_Station)
    if _Dura then
        _Dura.maxDurabilityFactor = _Dura.maxDurabilityFactor * _DuraFactor
    end

    local _Shield = Shield(_Station)
    if _Shield then
        _Shield.maxDurabilityFactor = _Shield.maxDurabilityFactor * _DuraFactor
    end

    Placer.resolveIntersections()

    local _EntityTypes = ESCCUtil.allEntityTypes()
    _sector:addScript("sector/deleteentitiesonplayersleft.lua", _EntityTypes)
end

function lotwStory4_getWingSpawnTables(_WingScriptValue)
    local methodName = "Получение таблицы спавна группы"
    mission.Log(methodName, "Начало...")

    local _Destroyed = mission.data.custom.destroyed

    local _BanditMaxCt = 1
    local _PirateMaxCt = 2
    local _MarauderMaxCt = 0
    if _Destroyed >= 5 then
        _BanditMaxCt = 2
        _MarauderMaxCt = 1
    end

    local _BanditCt = 0
    local _PirateCt = 0
    local _MarauderCt = 0

    local _Pirates = {Sector():getEntitiesByScriptValue(_WingScriptValue)}
    mission.Log(methodName, "Подсчёт пиратов: " .. tostring(#_Pirates) .. " найдено")
    for _, _Pirate in pairs(_Pirates) do
        local _TArgs = _Pirate:getTitleArguments()
        for _, _TArg in pairs(_TArgs) do
            local _Title = _TArg
            if _Title == "Bandit" then
                mission.Log(methodName, "Бандит")
                _BanditCt = _BanditCt + 1
            end
            if _Title == "Pirate" then
                mission.Log(methodName, "Пират")
                _PirateCt = _PirateCt + 1
            end
            if _Title == "Marauder" then
                mission.Log(methodName, "Марадер")
                _MarauderCt = _MarauderCt + 1
            end
        end
    end

    local _SpawnTable = {}
    if _BanditCt < _BanditMaxCt then
        local _SpawnCt = _BanditMaxCt - _BanditCt
        for _ = 1, _SpawnCt, 1 do
            table.insert(_SpawnTable, "Bandit")
        end
    end
    if _PirateCt < _PirateMaxCt then
        local _SpawnCt = _PirateMaxCt - _PirateCt
        for _ = 1, _SpawnCt, 1 do
            table.insert(_SpawnTable, "Pirate")
        end
    end
    if _MarauderCt < _MarauderMaxCt then
        local _SpawnCt = _MarauderMaxCt - _MarauderCt
        for _ = 1, _SpawnCt, 1 do
            table.insert(_SpawnTable, "Marauder")
        end
    end

    return _SpawnTable
end

function lotwStory4_spawnBackgroundPirates()
    local methodName = "Спавн фоновых пиратов"
    mission.Log(methodName, "Начало...")

    local distance = 100

    local spawnFunc = function(wingScriptValue, wingOnSpawnFunc)
        local wingSpawnTable = lotwStory4_getWingSpawnTables(wingScriptValue)
        local wingGenerator = AsyncPirateGenerator(nil, wingOnSpawnFunc)

        local posCtr = 1
        local wingPositions = wingGenerator:getStandardPositions(#wingSpawnTable, distance)

        wingGenerator:startBatch()

        for _, p in pairs(wingSpawnTable) do
            wingGenerator:createScaledPirateByName(p, wingPositions[posCtr])
            posCtr = posCtr + 1
        end

        wingGenerator:endBatch()
    end

    spawnFunc("_lotw_alpha_wing", lotwStory4_onAlphaBackgroundPiratesFinished)
    spawnFunc("_lotw_beta_wing", lotwStory4_onBetaBackgroundPiratesFinished)
end

function lotwStory4_onAlphaBackgroundPiratesFinished(_Generated)
    local _Invincible = false
    local _DefenseObjective = nil
    if not mission.data.custom.firstAlphaInvincible then
        local _DefenseObjectives = {Sector():getEntitiesByScriptValue("_lotw_mission4_defendobjective")}
        _DefenseObjective = _DefenseObjectives[1]
        _Invincible = true
        mission.data.custom.firstAlphaInvincible = true
    end

    for _, _Pirate in pairs(_Generated) do
        _Pirate:setValue("_lotw_mission4_objective", true)
        _Pirate:setValue("_lotw_alpha_wing", true)

        if _Invincible then
            local _Dura = Durability(_Pirate)
            if _Dura then
                _Dura:addFactionImmunity(_DefenseObjective.factionIndex)
            end
        end
    end

    SpawnUtility.addEnemyBuffs(_Generated)
end

function lotwStory4_onBetaBackgroundPiratesFinished(_Generated)
    local _sector = Sector()

    local _SlamCtMax = 2
    local _Slammers = {_sector:getEntitiesByScript("torpedoslammer.lua")}
    local _SlamCt = #_Slammers
    local _SlamAdded = 0

    local _TorpSlammerValues = {
        _TimeToActive = 35,
        _ROF = 10,
        _UpAdjust = false,
        _DamageFactor = 0.33,
        _TorpOffset = -750,
        _DurabilityFactor = 8,
        _ForwardAdjustFactor = 2,
        _PreferWarheadType = TorpedoUtility.WarheadType.Nuclear,
        _TargetPriority = 2,
        _TargetTag = "_lotw_mission4_defendobjective",
        _ShockwaveFactor = 2
    }

    local _DefenseObjectives = {_sector:getEntitiesByScriptValue("_lotw_mission4_defendobjective")}
    local _DefenseObjective = _DefenseObjectives[1]

    local _Invincible = false
    if not mission.data.custom.firstBetaInvincible then
        _Invincible = true
        mission.data.custom.firstBetaInvincible = true
    end

    for _, _Pirate in pairs(_Generated) do
        local _Xinvincible = _Invincible
        _Pirate:setValue("_lotw_mission4_objective", true)
        _Pirate:setValue("_lotw_beta_wing", true)

        if _SlamCt + _SlamAdded < _SlamCtMax then
            local _TitleArguments = _Pirate:getTitleArguments()
            local _OldTitle = _TitleArguments.title
            _TitleArguments.title = "Бомбардировщик " .. _OldTitle

            _Pirate:setTitleArguments(_TitleArguments)

            _Pirate:removeScript("icon.lua")
            _Pirate:addScript("icon.lua", "data/textures/icons/pixel/torpedoboatex.png")
            _Pirate:addScript("torpedoslammer.lua", _TorpSlammerValues)

            _Xinvincible = true
            _SlamAdded = _SlamAdded + 1
        end

        if _Xinvincible then
            local _Dura = Durability(_Pirate)
            if _Dura then
                _Dura:addFactionImmunity(_DefenseObjective.factionIndex)
            end
        end

        local _ShipAI = ShipAI(_Pirate)
        _ShipAI:setAttack(_DefenseObjective)
    end
    SpawnUtility.addEnemyBuffs(_Generated)
end

function lotwStory4_finishAndReward()
    local methodName = "Завершение и награждение"
    mission.Log(methodName, "Выполнение условия победы.")

    local _Player = Player()
    _Player:setValue("_lotw_story_stage", 5)

    local station = Entity(Uuid(mission.data.custom.stationId))
    station:setValue("no_chatter", nil)

    local failedAttempts = _Player:getValue("_lotw_mission4_failures") or 0
    if failedAttempts < 3 then
        local hpRatio = station.durability / station.maxDurability

        if hpRatio >= 0.75 then
            mission.data.reward.paymentMessage = mission.data.reward.paymentMessage .. " Включая бонус за отличную работу."
            mission.data.reward.credits = mission.data.reward.credits * 1.25
        end
    end

    reward()
    accomplish()
end
