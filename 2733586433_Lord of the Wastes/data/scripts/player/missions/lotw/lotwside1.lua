--[[
    Собаки свалки (Редакция)
    ЗАМЕТКИ:
        - Только последний транспорт даёт добычу. Сделай его немного больше, чем в сюжетной миссии.
    ДОПОЛНИТЕЛЬНЫЕ ТРЕБОВАНИЯ:
        - Завершить 5-ю миссию LOTW и снять её с доски объявлений.
    ПРИМЕРНЫЙ ПЛАН:
        - Прибыть в сектор, уничтожить транспорты. Достаточно просто.
    УРОВЕНЬ ОПАСНОСТИ:
        5 - Уничтожить 3 пиратских транспорта до побега Y. Y = 3/5, 2/8 и 1/10.
        5 - Только последний транспорт имеет добычу, чтобы предотвратить злоупотребления.
        ? - Постоянное крыло из 3 стандартных пиратов ESCC будет появляться на заднем плане.
        ? - Начать спавн 4-го пирата после уничтожения 2-го транспорта.
        10 - 4-й пират всегда будет появляться с самого начала, а пираты обновляются на 5 секунд быстрее.
]]
package.path = package.path .. ";data/scripts/lib/?.lua"
package.path = package.path .. ";data/scripts/?.lua"

include("callable")
include("structuredmission")
include("goodsindex")

ESCCUtil = include("esccutil")

local AsyncPirateGenerator = include ("asyncpirategenerator")
local AsyncShipGenerator = include("asyncshipgenerator")
local Balancing = include ("galaxy")
local SpawnUtility = include ("spawnutility")

mission._Debug = 0
mission._Name = "Собаки свалки (Редакция)"

--region #INIT

-- Стандартные данные миссии.
mission.data.brief = mission._Name
mission.data.title = mission._Name
mission.data.autoTrackMission = true
mission.data.icon = "data/textures/icons/silicium.png"
mission.data.description = {
    { text = "Вы получили следующий запрос от ${sectorName} ${giverTitle}:" },
    { text = "..." },
    { text = "Направляйтесь в сектор (${location.x}:${location.y})", bulletPoint = true, fulfilled = false },
    { text = "Уничтожьте грузовые корабли - ${_DESTROYED}/3 уничтожено", bulletPoint = true, fulfilled = false, visible = false },
    { text = "Не позволяйте слишком многим грузовым кораблям сбежать - ${_ESCAPED}/${_MAXESCAPED} сбежало", bulletPoint = true, fulfilled = false, visible = false },
    { text = "Встретьтесь с посредником в секторе (${location.x}:${location.y})", bulletPoint = true, fulfilled = false, visible = false }
}
mission.data.accomplishMessage = "Хорошая работа. Мы перевели вознаграждение на ваш счёт."

local LOTW_Mission_init = initialize
function initialize(_Data_in, bulletin)
    local _MethodName = "initialize"
    mission.Log(_MethodName, "Начало...")

    if onServer() and not _restoring then
        local _Sector = Sector()
        local _Giver = Entity(_Data_in.giver)

        mission.data.location = _Data_in.location

        --[[=====================================================
            НАСТРОЙКА ПОЛЬЗОВАТЕЛЬСКИХ ДАННЫХ МИССИИ:
        =========================================================]]
        mission.data.custom.dangerLevel = _Data_in.dangerLevel
        mission.data.custom.destroyed = 0
        mission.data.custom.escaped = 0
        local _MaxEscaped = 3
        if mission.data.custom.dangerLevel >= 8 then
            _MaxEscaped = 2
        elseif mission.data.custom.dangerLevel == 10 then
            _MaxEscaped = 1
        end
        mission.data.custom.maxEscaped = _MaxEscaped
        local _SpawnTimer = 45
        if mission.data.custom.dangerLevel == 10 then
            _SpawnTimer = 35
        end
        mission.data.custom.friendlyFaction = _Giver.factionIndex
        mission.data.custom.pirateSpawnTimer = _SpawnTimer
        mission.data.custom.prx = mission.data.location.x -- prx = prerender x
        mission.data.custom.pry = mission.data.location.y -- pry = prerender y

        --[[=====================================================
            НАСТРОЙКА ОПИСАНИЯ МИССИИ:
        =========================================================]]
        mission.data.description[1].arguments = { sectorName = _Sector.name, giverTitle = _Giver.translatedTitle }
        mission.data.description[2].text = _Data_in.initialDesc
        mission.data.description[2].arguments = { x = mission.data.location.x, y = mission.data.location.y }
        mission.data.description[3].arguments = { x = mission.data.location.x, y = mission.data.location.y }
    end

    LOTW_Mission_init(_Data_in, bulletin)
end

--endregion

--region #PHASE CALLS

mission.globalPhase.noBossEncountersTargetSector = true
mission.globalPhase.noPlayerEventsTargetSector = true
mission.globalPhase.noLocalPlayerEventsTargetSector = true

mission.globalPhase.onAbandon = function()
    lotwSide1_setLastMissionTime()
end

mission.phases[1] = {}
mission.phases[1].showUpdateOnEnd = true
mission.phases[1].onTargetLocationArrivalConfirmed = function(x, y)
    nextPhase()
end

mission.phases[2] = {}
mission.phases[2].timers = {}
mission.phases[2].showUpdateOnEnd = true

mission.phases[2].onBeginServer = function()
    mission.data.description[3].fulfilled = true
    mission.data.description[4].arguments = { _DESTROYED = mission.data.custom.destroyed }
    mission.data.description[5].arguments = { _ESCAPED = mission.data.custom.escaped, _MAXESCAPED = mission.data.custom.maxEscaped }
    mission.data.description[4].visible = true
    mission.data.description[5].visible = true

    lotwSide1_spawnBackgroundPirates()
end

mission.phases[2].onPreRenderHud = function()
    local x, y = Sector():getCoordinates()
    if x == mission.data.custom.prx and y == mission.data.custom.pry then
        lotwSide1_onMarkDroppedOres()
    end
end

mission.phases[2].onEntityDestroyed = function(_ID, _LastDamageInflictor)
    local _MethodName = "Фаза 2: Уничтожение объекта"
    mission.Log(_MethodName, "Начало...")
    if Entity(_ID):getValue("_lotw_side1_objective") then
        mission.Log(_MethodName, "Это цель.")
        mission.data.custom.destroyed = mission.data.custom.destroyed + 1
        mission.data.description[4].arguments = { _DESTROYED = mission.data.custom.destroyed }

        mission.Log(_MethodName, "Количество уничтоженных грузовых кораблей: " .. tostring(mission.data.custom.destroyed))
        sync()
    end
end

--region #PHASE 2 TIMERS

if onServer() then

-- Таймер 1: спавн фоновых пиратов
mission.phases[2].timers[1] = {
    time = mission.data.custom.pirateSpawnTimer or 45,
    callback = function()
        local _Sector = Sector()
        local _X, _Y = _Sector:getCoordinates()
        if _X == mission.data.location.x and _Y == mission.data.location.y then
            lotwSide1_spawnBackgroundPirates()
        end
    end,
    repeating = true
}
-- Таймер 2: спавн грузовых кораблей пиратов
mission.phases[2].timers[2] = {
    time = 90,
    callback = function()
        local _Sector = Sector()
        local _X, _Y = _Sector:getCoordinates()
        if _X == mission.data.location.x and _Y == mission.data.location.y then
            lotwSide1_spawnPirateFreighter()
        end
    end,
    repeating = true
}
-- Таймер 3: таймер мягкого провала
mission.phases[2].timers[3] = {
    time = 90,
    callback = function()
        local _Sector = Sector()
        local _X, _Y = _Sector:getCoordinates()
        if _X ~= mission.data.location.x or _Y ~= mission.data.location.y then
            mission.data.custom.escaped = mission.data.custom.escaped + 1
            mission.data.description[5].arguments = { _ESCAPED = mission.data.custom.escaped, _MAXESCAPED = mission.data.custom.maxEscaped }
            sync()
        end
    end,
    repeating = true
}
-- Таймер 4: таймер продвижения/цели
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
            lotwSide1_setLastMissionTime()
            fail()
        end
    end,
    repeating = true
}

end

--endregion

mission.phases[3] = {}
mission.phases[3].onBeginServer = function()
    local _MethodName = "Фаза 3: Начало на сервере"
    mission.Log(_MethodName, "Начало...")

    mission.data.description[4].fulfilled = true
    mission.data.description[5].fulfilled = true

    mission.data.location = lotwSide1_getNextLocation()
    mission.data.description[6].arguments = { x = mission.data.location.x, y = mission.data.location.y }

    mission.data.description[6].visible = true

    local _Faction = Faction(mission.data.custom.friendlyFaction)
    Player():sendChatMessage(_Faction.name, 0, "У нас есть посредник, ожидающий вас в секторе \\s(%1%:%2%). Пожалуйста, свяжитесь с ним там.", mission.data.location.x, mission.data.location.y)
end

mission.phases[3].onPreRenderHud = function()
    local x, y = Sector():getCoordinates()
    if x == mission.data.custom.prx and y == mission.data.custom.pry then
        lotwSide1_onMarkDroppedOres()
    end
end

mission.phases[3].onTargetLocationArrivalConfirmed = function(x, y)
    lotwSide1_spawnLiason()
end

--endregion

--region #SERVER CALLS

function lotwSide1_getNextLocation()
    local _MethodName = "Получить следующий сектор"

    mission.Log(_MethodName, "Поиск сектора.")
    local x, y = Sector():getCoordinates()
    local target = {}

    target.x, target.y = MissionUT.getSector(x, y, 4, 10, false, false, false, false, false)

    mission.Log(_MethodName, "Координата X следующего сектора: " .. tostring(target.x) .. ", координата Y следующего сектора: " .. tostring(target.y))
    if not target or not target.x or not target.y then
        mission.Log(_MethodName, "Не удалось найти подходящий сектор для миссии. Завершение скрипта.")
        terminate()
        return
    end

    return target
end

function lotwSide1_spawnBackgroundPirates()
    local _MethodName = "Спавн фоновых пиратов"
    mission.Log(_MethodName, "Начало...")

    local _Destroyed = mission.data.custom.destroyed
    local _DangerLevel = mission.data.custom.dangerLevel

    local _PirateMaxCt = 3
    if _DangerLevel == 10 or _Destroyed == 2 then
        _PirateMaxCt = 4
    end

    local _Pirates = {Sector():getEntitiesByScriptValue("is_pirate")}
    local _PirateCt = #_Pirates

    local _PiratesToSpawn = _PirateMaxCt - _PirateCt

    if _PiratesToSpawn > 0 then
        local _SpawnTable = ESCCUtil.getStandardWave(_DangerLevel, _PiratesToSpawn, "Standard")

        local generator = AsyncPirateGenerator(nil, lotwSide1_onBackgroundPiratesFinished)

        generator:startBatch()

        local posCounter = 1
        local distance = 100
        local pirate_positions = generator:getStandardPositions(#_SpawnTable, distance)
        for _, p in pairs(_SpawnTable) do
            generator:createScaledPirateByName(p, pirate_positions[posCounter])
            posCounter = posCounter + 1
        end

        generator:endBatch()
    end
end

function lotwSide1_onBackgroundPiratesFinished(_Generated)
    SpawnUtility.addEnemyBuffs(_Generated)
end

function lotwSide1_spawnPirateFreighter()
    local _Freighters = {Sector():getEntitiesByScriptValue("_lotw_side1_objective")}
    if #_Freighters > 0 then
        for _, _F in pairs(_Freighters) do
            _F:addScriptOnce("deletejumped.lua", 2)
            lotwSide1_freighterEscaped()
        end
    end
    local _Sector = Sector()
    local _X, _Y = _Sector:getCoordinates()
    local _ShipGenerator = AsyncShipGenerator(nil, lotwSide1_onPirateFreighterFinished)
    local _PirateGenerator = AsyncPirateGenerator(nil, nil)
    local _Vol1 = Balancing_GetSectorShipVolume(_X, _Y) * 3.5
    local _Faction = _PirateGenerator:getPirateFaction()

    _ShipGenerator:startBatch()

    _ShipGenerator:createFreighterShip(_Faction, _ShipGenerator:getGenericPosition(), _Vol1)

    _ShipGenerator:endBatch()
end

function lotwSide1_onPirateFreighterFinished(_Generated)
    for _, _Ship in pairs(_Generated) do
        _Ship:setValue("_lotw_side1_objective", true)
        _Ship:setValue("is_pirate", true)
        _Ship:setValue("is_civil", nil)
        _Ship:setValue("is_freighter", nil)
        _Ship:setValue("npc_chatter", nil)

        _Ship:removeScript("civilship.lua")
        _Ship:removeScript("dialogs/storyhints.lua")

        _Ship:addScriptOnce("player/missions/lotw/mission2/lotwfreighterm2.lua")

        local _Good = goods["Titanium Ore"]
        if mission.data.custom.destroyed < 2 then
            _Ship:setValue("_lotw_no_loot_drop", true)
        else
            local oreAmount = 5000 + (1000 * mission.data.custom.dangerLevel)

            _Ship:addAbsoluteBias(StatsBonuses.CargoHold, 10000)
            _Ship:addCargo(_Good:good(), oreAmount)
        end

        MissionUT.deleteOnPlayersLeft(_Ship)

        local _ShipAI = ShipAI(_Ship)
        local _Position = _Ship.position
        _ShipAI:setFlyLinear(_Position.look * 20000, 0)
        _ShipAI:setPassiveShooting(true)
    end
end

function lotwSide1_freighterEscaped()
    mission.data.custom.escaped = mission.data.custom.escaped + 1
    mission.data.description[5].arguments = { _ESCAPED = mission.data.custom.escaped, _MAXESCAPED = mission.data.custom.maxEscaped }
    sync()
end

function lotwSide1_spawnLiason()
    local _MethodName = "Спавн посредника"
    mission.Log(_MethodName, "Начало...")
    local shipGenerator = AsyncShipGenerator(nil, lotwSide1_onFactionShipsFinished)
    local faction = Faction(mission.data.custom.friendlyFaction)

    if not faction or faction.isPlayer or faction.isAlliance then
        print("ОШИБКА: не удалось найти фракцию миссии")
        terminate()
        return
    end

    shipGenerator:startBatch()

    shipGenerator:createDefender(faction, shipGenerator:getGenericPosition())
    shipGenerator:createDefender(faction, shipGenerator:getGenericPosition())

    shipGenerator:endBatch()

    local liasonGenerator = AsyncShipGenerator(nil, lotwSide1_onLiasonShipFinished)

    liasonGenerator:startBatch()

    liasonGenerator:createDefender(faction, liasonGenerator:getGenericPosition())

    liasonGenerator:endBatch()
end

function lotwSide1_onLiasonShipFinished(_Generated)
    for _, _Ship in pairs(_Generated) do
        local _Faction = Faction(_Ship.factionIndex)
        local _ShipAI = ShipAI(_Ship)

        MissionUT.deleteOnPlayersLeft(_Ship)
        _Ship:removeScript("patrol.lua")
        _Ship:removeScript("antismuggle.lua")
        _Ship:addScriptOnce("player/missions/lotw/mission6/lotwliasonm6.lua")
        _ShipAI:setIdle()

        _Ship.title = tostring(_Faction.name) .. " Военный посредник"
    end
end

function lotwSide1_onFactionShipsFinished(_Generated)
    for _, _Ship in pairs(_Generated) do
        _Ship:removeScript("antismuggle.lua")
        MissionUT.deleteOnPlayersLeft(_Ship)
    end
end

function lotwSide1_setLastMissionTime()
    local runTime = Server().unpausedRuntime
    Player():setValue("_lotw_last_side1", runTime)
end

function lotwSide1_finishAndReward()
    local _MethodName = "Завершение и награждение"
    mission.Log(_MethodName, "Выполнение условия победы.")

    lotwSide1_setLastMissionTime()

    reward()
    accomplish()
end

--endregion

--region #CLIENT CALLS

function lotwSide1_onMarkDroppedOres()
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
            renderer:renderTargetIndicator(indicator);
        end
    end

    renderer:display()
end

--endregion

--region #CLIENT / SERVER CALLS

function lotwSide1_contactedLiason()
    local _MethodName = "Связь с посредником"

    if onClient() then
        mission.Log(_MethodName, "Вызов на клиенте")
        mission.Log(_MethodName, "Вызов на сервере.")

        invokeServerFunction("lotwSide1_contactedLiason")
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

        lotwSide1_finishAndReward()
    end
end
callable(nil, "lotwSide1_contactedLiason")

--endregion

--region #MAKEBULLETIN CALL

function lotwSide1_formatDescription(_Station)
    local _Faction = Faction(_Station.factionIndex)
    local _Aggressive = _Faction:getTrait("aggressive")

    local _DescriptionType = 1 -- Нейтральный
    if _Aggressive > 0.5 then
        _DescriptionType = 2 -- Агрессивный.
    elseif _Aggressive <= -0.5 then
        _DescriptionType = 3 -- Мирный.
    end

    local _FinalDescription = ""
    if _DescriptionType == 1 then -- Нейтральный.
        _FinalDescription = "Наша разведка снова обнаружила отряд пиратских транспортов, движущихся через нашу территорию. Мы щедро заплатим за их уничтожение, как всегда. Дайте знать, если вас заинтересует это предложение. Вы найдёте их в секторе (${x}:${y})."
    elseif _DescriptionType == 2 then -- Агрессивный.
        _FinalDescription = "Какие-то пиратские отбросы решили, что могут безнаказанно перемещать транспорты через нашу территорию. Обычно мы сами разбираемся с такой наглостью, но наши военные заняты в другом месте, и уничтожение этих транспортов отвлечёт слишком много сил. Доберитесь до сектора (${x}:${y}) и уничтожьте их всех."
    elseif _DescriptionType == 3 then -- Мирный.
        _FinalDescription = "Мы слышали слухи о караване пиратских транспортов, движущихся через нашу территорию. Мы не можем собрать достаточно сил для адекватного ответа, поэтому обращаемся за помощью к независимым капитанам. Пожалуйста, нейтрализуйте конвой в секторе (${x}:${y}). Вы будете вознаграждены за это."
    end

    return _FinalDescription
end

mission.makeBulletin = function(_Station)
    local _MethodName = "Создание объявления"
    mission.Log(_MethodName, "Создание объявления.")
    local _Sector = Sector()
    local target = {}
    local x, y = _Sector:getCoordinates()
    local insideBarrier = MissionUT.checkSectorInsideBarrier(x, y)
    target.x, target.y = MissionUT.getSector(x, y, 6, 12, false, false, false, false, insideBarrier)

    if not target.x or not target.y then
        mission.Log(_MethodName, "target.x или target.y не установлены — возвращаем nil.")
        return
    end

    local _Rgen = ESCCUtil.getRand()
    local _DangerLevel = _Rgen:getInt(1, 10)

    local _Difficulty = "Лёгкий"
    if _DangerLevel >= 6 then
        _Difficulty = "Средний"
    end
    if _DangerLevel >= 9 then
        _Difficulty = "Сложный"
    end

    local _Description = lotwSide1_formatDescription(_Station)

    local _DangerCash = 25000
    if _DangerLevel >= 5 then
        _DangerCash = 27500
    elseif _DangerLevel == 10 then
        _DangerCash = 30000
    end

    reward = 100000 + (_DangerCash * Balancing.GetSectorRewardFactor(_Sector:getCoordinates()))

    local bulletin =
    {
        brief = mission.data.brief,
        title = mission.data.title,
        icon = mission.data.icon,
        description = _Description,
        difficulty = _Difficulty,
        reward = "¢${reward}",
        script = "missions/lotw/lotwside1.lua",
        formatArguments = {x = target.x, y = target.y, reward = createMonetaryString(reward)},
        msg = "Пираты действуют в секторе \\s(%1%:%2%). Пожалуйста, уничтожьте их.",
        giverTitle = _Station.title,
        giverTitleArgs = _Station:getTitleArguments(),
        checkAccept = [[
            local self, player = ...
            if not player:getValue("_lotw_story_complete") then
                player:sendChatMessage(Entity(self.arguments[1].giver), 1, "Вы не можете принять эту миссию.")
                return 0
            end
            if player:hasScript("lotwside1.lua") then
                player:sendChatMessage(Entity(self.arguments[1].giver), 1, "Вы не можете принять эту миссию снова!")
                return 0
            end
            return 1
        ]],
        onAccept = [[
            local self, player = ...
            player:sendChatMessage(Entity(self.arguments[1].giver), 0, self.msg, self.formatArguments.x, self.formatArguments.y)
        ]],
        arguments = {{
            giver = _Station.index,
            location = target,
            reward = {credits = reward, relations = 6000, paymentMessage = "Получено %1% кредитов за уничтожение пиратских грузовых кораблей."},
            initialDesc = _Description,
            dangerLevel = _DangerLevel
        }},
    }

    return bulletin
end

--endregion
