--[[
    Собаки свалки
    ЗАМЕТКИ:
        - Отслеживайте, сколько транспортов уничтожил игрок. Дайте добычу только за первое уничтожение каждого транспорта.
        - Дайте хорошую добычу — много руды.
    ДОПОЛНИТЕЛЬНЫЕ ТРЕБОВАНИЯ:
        - Завершить первую миссию LOTW.
    ПРИМЕРНЫЙ ПЛАН:
        - Прибыть в сектор, уничтожить транспорты. Достаточно просто.
    УРОВЕНЬ ОПАСНОСТИ:
        5 - Уничтожить X пиратских транспортов до побега Y. Становится легче, если игрок проваливает миссию.
        5 - Постоянное крыло из 2 бандитов и 1 пирата будет появляться на заднем плане.
        5 - Начать спавн мародёра после уничтожения 2-го транспорта.
]]
package.path = package.path .. ";data/scripts/lib/?.lua"
package.path = package.path .. ";data/scripts/?.lua"

include("callable")
include("structuredmission")
include("goodsindex")

ESCCUtil = include("esccutil")

local AsyncPirateGenerator = include("asyncpirategenerator")
local AsyncShipGenerator = include("asyncshipgenerator")
local SpawnUtility = include("spawnutility")

mission._Debug = 0
mission._Name = "Собаки свалки"

-- Настройка данных миссии
mission.data.brief = mission._Name
mission.data.title = mission._Name
mission.data.autoTrackMission = true
mission.data.icon = "data/textures/icons/silicium.png"
mission.data.description = {
    { text = "Вы получили следующий запрос от ${factionName}:" },
    { text = "Предыдущая операция послужила достаточным предупреждением, но нам нужно пойти дальше. Удар по их цепочке поставок заставит их предпринять дальнейшие действия для покрытия убытков. Мы обнаружили конвой, движущийся через сектор (${location.x}:${location.y}), и хотели бы, чтобы вы его уничтожили. Вы можете оставить себе всё, что найдёте на грузовых кораблях. Не позволяйте слишком многим сбежать. В этом весь смысл операции." },
    { text = "Направляйтесь в сектор (${location.x}:${location.y})", bulletPoint = true, fulfilled = false },
    { text = "(Рекомендуется) Убедитесь, что на вашем корабле есть хотя бы 750 единиц грузового пространства", bulletPoint = true, fulfilled = false },
    { text = "Уничтожьте грузовые корабли - ${_DESTROYED}/3 уничтожено", bulletPoint = true, fulfilled = false, visible = false },
    { text = "Не позволяйте слишком многим грузовым кораблям сбежать - ${_ESCAPED}/${_MAXESCAPED} сбежало", bulletPoint = true, fulfilled = false, visible = false },
    { text = "Встретьтесь с посредником в секторе (${location.x}:${location.y})", bulletPoint = true, fulfilled = false, visible = false }
}
mission.data.accomplishMessage = "Хорошая работа. Мы перевели вознаграждение на ваш счёт. Будьте начеку — в будущем будут новые возможности."

local LOTW_Mission_init = initialize
function initialize()
    local _MethodName = "Инициализация"
    mission.Log(_MethodName, "Начало...")

    local _Sector = Sector()
    local _X, _Y = _Sector:getCoordinates()

    if onServer() and not _restoring then
        local _Player = Player()
        local _FailureCt = _Player:getValue("_lotw_mission2_failures") or 0

        mission.data.custom.dangerLevel = 5
        mission.data.custom.destroyed = 0
        mission.data.custom.escaped = 0
        mission.data.custom.maxEscaped = 3 + (_FailureCt * 2)
        mission.data.custom.friendlyFaction = _Player:getValue("_lotw_faction")
        mission.data.custom.piratesSpawned = 0
        mission.data.custom.fulfilledCargoObjective = false

        local missionReward = 100000

        missionData_in = {location = nil, reward = {credits = missionReward, relations = 12000, paymentMessage = "Получено %1% кредитов за уничтожение пиратских грузовых кораблей."}}
    end

    LOTW_Mission_init(missionData_in)

    if onServer() and not _restoring then
        lotwStory2_setMissionFactionData(_X, _Y)
    end
end

mission.globalPhase.noBossEncountersTargetSector = true
mission.globalPhase.noPlayerEventsTargetSector = true
mission.globalPhase.noLocalPlayerEventsTargetSector = true

mission.globalPhase.onFail = function()
    local _Player = Player()
    local _FailureCt = _Player:getValue("_lotw_mission2_failures") or 0
    _FailureCt = _FailureCt + 1
    _Player:setValue("_lotw_mission2_failures", _FailureCt)
end

mission.globalPhase.updateServer = function()
    local methodName = "Обновление глобальной фазы на сервере"

    if not mission.data.custom.fulfilledCargoObjective then
        mission.Log(methodName, "Проверка грузового объектива")

        local _player = Player()
        local craft = _player.craft
        if not craft then
            return
        end

        if craft.freeCargoSpace and craft.freeCargoSpace >= 750 then
            mission.data.description[4].fulfilled = true
            mission.data.custom.fulfilledCargoObjective = true
            sync()
        end
    end
end

mission.phases[1] = {}
mission.phases[1].timers = {}
mission.phases[1].showUpdateOnEnd = true
mission.phases[1].onBeginServer = function()
    local _MethodName = "Фаза 1: Начало на сервере"
    mission.Log(_MethodName, "Начало...")

    local _Faction = Faction(mission.data.custom.friendlyFaction)

    mission.data.location = lotwStory2_getNextLocation()

    mission.data.custom.prx = mission.data.location.x
    mission.data.custom.pry = mission.data.location.y

    mission.data.description[1].arguments = { factionName = _Faction.name }
    mission.data.description[2].arguments = { x = mission.data.location.x, y = mission.data.location.y }
    mission.data.description[3].arguments = { x = mission.data.location.x, y = mission.data.location.y }
end

mission.phases[1].onTargetLocationArrivalConfirmed = function(x, y)
    nextPhase()
end

mission.phases[2] = {}
mission.phases[2].timers = {}
mission.phases[2].showUpdateOnEnd = true
mission.phases[2].onBeginServer = function()
    mission.data.description[3].fulfilled = true
    mission.data.description[5].arguments = { _DESTROYED = mission.data.custom.destroyed }
    mission.data.description[6].arguments = { _ESCAPED = mission.data.custom.escaped, _MAXESCAPED = mission.data.custom.maxEscaped }
    mission.data.description[5].visible = true
    mission.data.description[6].visible = true

    lotwStory2_spawnBackgroundPirates()
end

mission.phases[2].onPreRenderHud = function()
    local x, y = Sector():getCoordinates()
    if x == mission.data.custom.prx and y == mission.data.custom.pry then
        lotwStory2_onMarkDroppedOres()
    end
end

mission.phases[2].onEntityDestroyed = function(_ID, _LastDamageInflictor)
    local _MethodName = "Фаза 2: Уничтожение объекта"
    mission.Log(_MethodName, "Начало...")
    if Entity(_ID):getValue("_lotw_mission2_objective") then
        mission.Log(_MethodName, "Это цель.")
        local _Player = Player()
        local _FreightersDestroyed = _Player:getValue("_lotw_mission2_freighterskilled") or 0
        _FreightersDestroyed = _FreightersDestroyed + 1
        _Player:setValue("_lotw_mission2_freighterskilled", _FreightersDestroyed)

        mission.data.custom.destroyed = mission.data.custom.destroyed + 1
        mission.data.description[5].arguments = { _DESTROYED = mission.data.custom.destroyed }

        mission.Log(_MethodName, "Количество уничтоженных грузовых кораблей: " .. tostring(mission.data.custom.destroyed))
        sync()
    end
end

if onServer() then
    mission.phases[2].timers[1] = {
        time = 45,
        callback = function()
            local _Sector = Sector()
            local _X, _Y = _Sector:getCoordinates()
            if _X == mission.data.location.x and _Y == mission.data.location.y then
                lotwStory2_spawnBackgroundPirates()
            end
        end,
        repeating = true
    }

    mission.phases[2].timers[2] = {
        time = 90,
        callback = function()
            local _Sector = Sector()
            local _X, _Y = _Sector:getCoordinates()
            if _X == mission.data.location.x and _Y == mission.data.location.y then
                lotwStory2_spawnPirateFreighter()
            end
        end,
        repeating = true
    }

    mission.phases[2].timers[3] = {
        time = 90,
        callback = function()
            local _Sector = Sector()
            local _X, _Y = _Sector:getCoordinates()
            if _X ~= mission.data.location.x or _Y ~= mission.data.location.y then
                mission.data.custom.escaped = mission.data.custom.escaped + 1
                mission.data.description[6].arguments = { _ESCAPED = mission.data.custom.escaped, _MAXESCAPED = mission.data.custom.maxEscaped }
                sync()
            end
        end,
        repeating = true
    }

    mission.phases[2].timers[4] = {
        time = 10,
        callback = function()
            local _MethodName = "Фаза 2: Обратный вызов таймера 4"
            mission.Log(_MethodName, "Начало...")
            mission.Log(_MethodName, "Количество уничтоженных грузовых кораблей: " .. tostring(mission.data.custom.destroyed))
            if mission.data.custom.destroyed >= 3 then
                ESCCUtil.allPiratesDepart()
                nextPhase()
            end
            if mission.data.custom.escaped >= mission.data.custom.maxEscaped then
                ESCCUtil.allPiratesDepart()
                fail()
            end
        end,
        repeating = true
    }
end

mission.phases[3] = {}
mission.phases[3].onBeginServer = function()
    local _MethodName = "Фаза 3: Начало на сервере"
    mission.Log(_MethodName, "Начало...")
    mission.data.description[4].fulfilled = true
    mission.data.description[5].fulfilled = true
    mission.data.description[6].fulfilled = true

    mission.data.location = lotwStory2_getNextLocation()
    mission.data.description[7].arguments = { x = mission.data.location.x, y = mission.data.location.y }
    mission.data.description[7].visible = true

    local _Faction = Faction(mission.data.custom.friendlyFaction)
    Player():sendChatMessage(_Faction.name, 0, "У нас есть посредник, ожидающий вас в секторе \\s(%1%:%2%). Пожалуйста, свяжитесь с ним там.", mission.data.location.x, mission.data.location.y)
end

mission.phases[3].onPreRenderHud = function()
    local x, y = Sector():getCoordinates()
    if x == mission.data.custom.prx and y == mission.data.custom.pry then
        lotwStory2_onMarkDroppedOres()
    end
end

mission.phases[3].onTargetLocationArrivalConfirmed = function(x, y)
    lotwStory2_spawnLiason()
end

function lotwStory2_setMissionFactionData(_X, _Y)
    local _MethodName = "Установка данных фракции миссии"
    mission.Log(_MethodName, "Начало...")
    local _Faction = Faction(Player():getValue("_lotw_faction"))
    mission.data.giver = {}
    mission.data.giver.id = _Faction.index
    mission.data.giver.factionIndex = _Faction.index
    mission.data.giver.coordinates = { x = _X, y = _Y }
    mission.data.giver.baseTitle = _Faction.name
end

function lotwStory2_getNextLocation()
    local _MethodName = "Получение следующего сектора"
    mission.Log(_MethodName, "Поиск сектора...")
    local x, y = Sector():getCoordinates()
    local target = {}

    target.x, target.y = MissionUT.getEmptySector(x, y, 4, 10, false)

    mission.Log(_MethodName, "Координата X следующего сектора: " .. tostring(target.x) .. ", координата Y следующего сектора: " .. tostring(target.y))
    if not target or not target.x or not target.y then
        mission.Log(_MethodName, "Не удалось найти подходящий сектор для миссии. Завершение скрипта.")
        terminate()
        return
    end

    return target
end

function lotwStory2_spawnBackgroundPirates()
    local _MethodName = "Спавн фоновых пиратов"
    mission.Log(_MethodName, "Начало...")

    local _Destroyed = mission.data.custom.destroyed

    local _BanditMaxCt = 2
    local _PirateMaxCt = 1
    local _MarauderMaxCt = 0
    if _Destroyed == 2 then
        _MarauderMaxCt = 1
    end

    local _BanditCt = 0
    local _PirateCt = 0
    local _MarauderCt = 0

    local _Pirates = {Sector():getEntitiesByScriptValue("is_pirate")}
    mission.Log(_MethodName, "Подсчёт пиратов: " .. tostring(#_Pirates) .. " найдено")
    for _, _Pirate in pairs(_Pirates) do
        local _TArgs = _Pirate:getTitleArguments()
        for _, _TArg in pairs(_TArgs) do
            local _Title = _TArg
            if _Title == "Bandit" then
                mission.Log(_MethodName, "Бандит")
                _BanditCt = _BanditCt + 1
            end
            if _Title == "Pirate" then
                mission.Log(_MethodName, "Пират")
                _PirateCt = _PirateCt + 1
            end
            if _Title == "Marauder" then
                mission.Log(_MethodName, "Марадер")
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

    local generator = AsyncPirateGenerator(nil, lotwStory2_onBackgroundPiratesFinished)

    generator:startBatch()

    local posCounter = 1
    local distance = 100
    local pirate_positions = generator:getStandardPositions(#_SpawnTable, distance)
    for _, p in pairs(_SpawnTable) do
        mission.data.custom.piratesSpawned = mission.data.custom.piratesSpawned + 1
        generator:createScaledPirateByName(p, pirate_positions[posCounter])
        posCounter = posCounter + 1
    end

    generator:endBatch()
end

function lotwStory2_onBackgroundPiratesFinished(_Generated)
    for _, _Pirate in pairs(_Generated) do
        if mission.data.custom.piratesSpawned > 10 then
            _Pirate:setDropsLoot(false)
        end
    end
    SpawnUtility.addEnemyBuffs(_Generated)
end

function lotwStory2_spawnPirateFreighter()
    local _Freighters = {Sector():getEntitiesByScriptValue("_lotw_mission2_objective")}
    if #_Freighters > 0 then
        for _, _F in pairs(_Freighters) do
            _F:addScriptOnce("deletejumped.lua", 2)
            lotwStory2_freighterEscaped()
        end
    end

    local _Sector = Sector()
    local _X, _Y = _Sector:getCoordinates()
    local _ShipGenerator = AsyncShipGenerator(nil, lotwStory2_onPirateFreighterFinished)
    local _PirateGenerator = AsyncPirateGenerator(nil, nil)
    local _Vol1 = Balancing_GetSectorShipVolume(_X, _Y) * 3
    local _Faction = _PirateGenerator:getPirateFaction()

    _ShipGenerator:startBatch()
    _ShipGenerator:createFreighterShip(_Faction, _ShipGenerator:getGenericPosition(), _Vol1)
    _ShipGenerator:endBatch()
end

function lotwStory2_onPirateFreighterFinished(_Generated)
    local _Player = Player()
    local _FreightersDestroyed = _Player:getValue("_lotw_mission2_freighterskilled") or 0

    for _, _Ship in pairs(_Generated) do
        _Ship:setValue("_lotw_mission2_objective", true)
        _Ship:setValue("is_pirate", true)
        _Ship:setValue("is_civil", nil)
        _Ship:setValue("is_freighter", nil)
        _Ship:setValue("npc_chatter", nil)

        _Ship:removeScript("civilship.lua")
        _Ship:removeScript("dialogs/storyhints.lua")

        _Ship:addScriptOnce("player/missions/lotw/mission2/lotwfreighterm2.lua")

        local _Good = goods["Titanium Ore"]
        if _FreightersDestroyed <= 2 then
            _Ship:addAbsoluteBias(StatsBonuses.CargoHold, 10000)
            _Ship:addCargo(_Good:good(), 10000)
        else
            _Ship:setValue("_lotw_no_loot_drop", true)
        end

        local _ShipAI = ShipAI(_Ship)
        local _Position = _Ship.position
        _ShipAI:setFlyLinear(_Position.look * 10000, 0)
        _ShipAI:setPassiveShooting(true)
    end
end

function lotwStory2_freighterEscaped()
    mission.data.custom.escaped = mission.data.custom.escaped + 1
    mission.data.description[6].arguments = { _ESCAPED = mission.data.custom.escaped, _MAXESCAPED = mission.data.custom.maxEscaped }
    sync()
end

function lotwStory2_spawnLiason()
    local _MethodName = "Спавн кораблей поддержки"
    mission.Log(_MethodName, "Начало...")
    local shipGenerator = AsyncShipGenerator(nil, lotwStory2_onFactionShipsFinished)
    local faction = Faction(mission.data.custom.friendlyFaction)

    if not faction or faction.isPlayer or faction.isAlliance then
        print("ОШИБКА: НЕ УДАЛОСЬ НАЙТИ ФРАКЦИЮ МИССИИ")
        terminate()
        return
    end

    shipGenerator:startBatch()
    shipGenerator:createDefender(faction, shipGenerator:getGenericPosition())
    shipGenerator:createDefender(faction, shipGenerator:getGenericPosition())
    shipGenerator:endBatch()

    local liasonGenerator = AsyncShipGenerator(nil, lotwStory2_onLiasonShipFinished)
    liasonGenerator:startBatch()
    liasonGenerator:createDefender(faction, liasonGenerator:getGenericPosition())
    liasonGenerator:endBatch()
end

function lotwStory2_onLiasonShipFinished(_Generated)
    for _, _Ship in pairs(_Generated) do
        local _Faction = Faction(_Ship.factionIndex)
        local _ShipAI = ShipAI(_Ship)

        MissionUT.deleteOnPlayersLeft(_Ship)
        _Ship:removeScript("patrol.lua")
        _Ship:removeScript("antismuggle.lua")
        _Ship:addScriptOnce("player/missions/lotw/mission2/lotwliasonm2.lua")
        _ShipAI:setIdle()

        _Ship.title = tostring(_Faction.name) .. " Военный посредник"
    end
end

function lotwStory2_onFactionShipsFinished(_Generated)
    for _, _Ship in pairs(_Generated) do
        _Ship:removeScript("antismuggle.lua")
        MissionUT.deleteOnPlayersLeft(_Ship)
    end
end

function lotwStory2_finishAndReward()
    local _MethodName = "Завершение и награждение"
    mission.Log(_MethodName, "Выполнение условия победы.")

    local _Player = Player()
    _Player:setValue("_lotw_story_stage", 3)

    reward()
    accomplish()
end

function lotwStory2_onMarkDroppedOres()
    local methodName = "Отметка выброшенной руды"

    local _player = Player()
    if not _player then
        return
    end
    if _player.state == PlayerStateType.BuildCraft or _player.state == PlayerStateType.BuildTurret or _player.state == PlayerStateType.PhotoMode then
        return
    end

    local _sector = Sector()
    local renderer = UIRenderer()
    local color = Material(MaterialType.Titanium).color

    for _, entity in pairs({_sector:getEntitiesByComponent(ComponentType.CargoLoot)}) do
        local loot = CargoLoot(entity)
        if valid(entity) and loot:matches("Titanium Ore") then
            local indicator = TargetIndicator(entity)
            indicator.visuals = TargetIndicatorVisuals.Tilted
            indicator.color = color
            renderer:renderTargetIndicator(indicator)
        end
    end

    renderer:display()
end

function lotwStory2_contactedLiason()
    local _MethodName = "Связь с посредником"

    if onClient() then
        mission.Log(_MethodName, "Вызов на клиенте")
        mission.Log(_MethodName, "Вызов на сервере.")

        invokeServerFunction("lotwStory2_contactedLiason")
    else
        mission.Log(_MethodName, "Вызов на сервере")

        local _PlayerShip = Entity(Player().craft.id)
        for _Good, _Amount in pairs(_PlayerShip:getCargos()) do
            if (string.find(_Good.name, "Ore") or string.find(_Good.name, "ore")) and _Good.stolen then
                local _Purified = copy(_Good)
                _Purified.stolen = false
                _PlayerShip:removeCargo(_Good, _Amount)
                _PlayerShip:addCargo(_Purified, _Amount)
            end
        end

        lotwStory2_finishAndReward()
    end
end
callable(nil, "lotwStory2_contactedLiason")
