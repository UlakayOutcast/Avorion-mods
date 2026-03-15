--[[
    Грабеж и побег (Редакция)
    ЗАМЕТКИ:
        - Только последний транспорт даёт добычу.
    ДОПОЛНИТЕЛЬНЫЕ ТРЕБОВАНИЯ:
        - Завершить 5-ю миссию LOTW и снять её с доски объявлений.
    ПРИМЕРНЫЙ ПЛАН:
        - Прибыть в сектор, уничтожить ещё больше транспортов. Достаточно просто.
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

ESCCUtil = include("esccutil")

local AsyncPirateGenerator = include("asyncpirategenerator")
local AsyncShipGenerator = include("asyncshipgenerator")
local Balancing = include("galaxy")
local SpawnUtility = include("spawnutility")

mission._Debug = 0
mission._Name = "Грабеж и побег (Редакция)"

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
    { text = "Уничтожьте транспорты с добычей - ${_DESTROYED}/3 уничтожено", bulletPoint = true, fulfilled = false, visible = false },
    { text = "Не позволяйте слишком многим транспортам с добычей сбежать - ${_ESCAPED}/${_MAXESCAPED} сбежало", bulletPoint = true, fulfilled = false, visible = false }
}
mission.data.accomplishMessage = "Отличная работа. Мы перевели вознаграждение на ваш счёт."

local LOTW_Mission_init = initialize
function initialize(_Data_in)
    local _MethodName = "initialize"
    mission.Log(_MethodName, "Начало...")

    if onServer() then
        if not _restoring then
            local _Sector = Sector()
            local _Giver = Entity(_Data_in.giver)

            mission.data.location = _Data_in.location
            --[[=====================================================
                НАСТРОЙКА ПОЛЬЗОВАТЕЛЬСКИХ ДАННЫХ МИССИИ:
                .dangerLevel
                .destroyed
                .escaped
                .maxEscaped
                .pirateSpawnTimer
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
            mission.data.custom.pirateSpawnTimer = _SpawnTimer

            mission.data.description[1].arguments = { sectorName = _Sector.name, giverTitle = _Giver.translatedTitle }
            mission.data.description[2].text = _Data_in.initialDesc
            mission.data.description[2].arguments = {x = mission.data.location.x, y = mission.data.location.y }
            mission.data.description[3].arguments = {x = mission.data.location.x, y = mission.data.location.y }

            LOTW_Mission_init(_Data_in)
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

--endregion

--region #PHASE CALLS

mission.globalPhase.noBossEncountersTargetSector = true
mission.globalPhase.noPlayerEventsTargetSector = true
mission.globalPhase.noLocalPlayerEventsTargetSector = true

mission.globalPhase.onAbandon = function()
    lotwSide2_setLastMissionTime()
end

mission.phases[1] = {}
mission.phases[1].showUpdateOnEnd = true
mission.phases[1].onTargetLocationEntered = function(x, y)
    nextPhase()
end

mission.phases[2] = {}
mission.phases[2].timers = {}
mission.phases[2].onBeginServer = function()
    mission.data.description[3].fulfilled = true
    mission.data.description[4].arguments = { _DESTROYED = mission.data.custom.destroyed }
    mission.data.description[5].arguments = { _ESCAPED = mission.data.custom.escaped, _MAXESCAPED = mission.data.custom.maxEscaped }
    mission.data.description[4].visible = true
    mission.data.description[5].visible = true

    lotwSide2_spawnBackgroundPirates()
end

mission.phases[2].onEntityDestroyed = function(_ID, _LastDamageInflictor)
    local _MethodName = "Фаза 2: Уничтожение объекта"
    mission.Log(_MethodName, "Начало...")
    if Entity(_ID):getValue("_lotw_side2_objective") then
        mission.Log(_MethodName, "Это цель.")
        mission.data.custom.destroyed = mission.data.custom.destroyed + 1
        mission.data.description[4].arguments = { _DESTROYED = mission.data.custom.destroyed }

        mission.Log(_MethodName, "Количество уничтоженных транспортов: " .. tostring(mission.data.custom.destroyed))
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
            lotwSide2_spawnBackgroundPirates()
        end
    end,
    repeating = true
}
-- Таймер 2: спавн транспортов с добычей
mission.phases[2].timers[2] = {
    time = 90,
    callback = function()
        local _Sector = Sector()
        local _X, _Y = _Sector:getCoordinates()
        if _X == mission.data.location.x and _Y == mission.data.location.y then
            lotwSide2_spawnPirateFreighter()
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
        mission.Log(_MethodName, "Количество уничтоженных транспортов: " .. tostring(mission.data.custom.destroyed))
        if mission.data.custom.destroyed >= 3 then
            ESCCUtil.allPiratesDepart()
            lotwSide2_finishAndReward()
        end
        if mission.data.custom.escaped >= mission.data.custom.maxEscaped then
            ESCCUtil.allPiratesDepart()
            lotwSide2_setLastMissionTime()
            fail()
        end
    end,
    repeating = true
}

end

--endregion

--endregion

--region #SERVER CALLS

function lotwSide2_spawnBackgroundPirates()
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

        local generator = AsyncPirateGenerator(nil, lotwSide2_onBackgroundPiratesFinished)

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

function lotwSide2_onBackgroundPiratesFinished(_Generated)
    SpawnUtility.addEnemyBuffs(_Generated)
end

function lotwSide2_spawnPirateFreighter()
    local _Freighters = {Sector():getEntitiesByScriptValue("_lotw_side2_objective")}
    if #_Freighters > 0 then
        for _, _F in pairs(_Freighters) do
            _F:addScriptOnce("deletejumped.lua", 2)
            lotwSide2_freighterEscaped()
        end
    end
    local _Sector = Sector()
    local _X, _Y = _Sector:getCoordinates()
    local _ShipGenerator = AsyncShipGenerator(nil, lotwSide2_onPirateFreighterFinished)
    local _PirateGenerator = AsyncPirateGenerator(nil, nil)
    local _Vol1 = Balancing_GetSectorShipVolume(_X, _Y) * 3
    local _Faction = _PirateGenerator:getPirateFaction()

    _ShipGenerator:startBatch()

    _ShipGenerator:createFreighterShip(_Faction, _ShipGenerator:getGenericPosition(), _Vol1)

    _ShipGenerator:endBatch()
end

function lotwSide2_onPirateFreighterFinished(_Generated)
    for _, _Ship in pairs(_Generated) do
        _Ship:setTitle("${toughness}${title}", {toughness = "", title = "Пиратский транспорт с добычей"})

        _Ship:setValue("_lotw_side2_objective", true)
        _Ship:setValue("is_pirate", true)
        _Ship:setValue("is_civil", nil)
        _Ship:setValue("is_freighter", nil)
        _Ship:setValue("npc_chatter", nil)

        _Ship:removeScript("civilship.lua")
        _Ship:removeScript("dialogs/storyhints.lua")

        local _AddLoot = true

        if mission.data.custom.destroyed < 2 then
            _Ship:setValue("_lotw_no_loot_drop", true)
            _AddLoot = false
        end

        _Ship:addScriptOnce("player/missions/lotw/mission3/lotwfreighterm3.lua", _AddLoot, false, true, mission.data.custom.dangerLevel)

        local _ShipAI = ShipAI(_Ship)
        local _Position = _Ship.position
        _ShipAI:setFlyLinear(_Position.look * 20000, 0)
        _ShipAI:setPassiveShooting(true)
    end
end

function lotwSide2_freighterEscaped()
    mission.data.custom.escaped = mission.data.custom.escaped + 1
    mission.data.description[5].arguments = { _ESCAPED = mission.data.custom.escaped, _MAXESCAPED = mission.data.custom.maxEscaped }
    sync()
end

function lotwSide2_setLastMissionTime()
    local runTime = Server().unpausedRuntime
    Player():setValue("_lotw_last_side2", runTime)
end

function lotwSide2_finishAndReward()
    local _MethodName = "Завершение и награждение"
    mission.Log(_MethodName, "Выполнение условия победы.")

    lotwSide2_setLastMissionTime()

    reward()
    accomplish()
end

--endregion

--region #MAKEBULLETIN CALL

function lotwSide2_formatDescription(_Station)
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
        _FinalDescription = "Мы заметили увеличение активности пиратов в местных секторах. Обычно это означает, что они перемещают системы и оружие. Мы хотели бы нанять вас для их уничтожения. Они находятся в секторе (${x}:${y}). Очевидно, вы будете хорошо оплачены за свои усилия, и вы можете оставить себе оборудование — нам просто не нужно, чтобы они использовали его против нас."
    elseif _DescriptionType == 2 then -- Агрессивный.
        _FinalDescription = "Пираты стали чаще перемещать оружие и системы через нашу территорию. Это, в лучшем случае, неудобство, но мы предпочли бы не терпеть этого. Здесь вы и пригодитесь. Они действуют в секторе (${x}:${y}). Уничтожьте их. Добыча ваша."
    elseif _DescriptionType == 3 then -- Мирный.
        _FinalDescription = "Наши шпионы обнаружили группу транспортов с добычей, движущихся через близлежащие секторы. У нас ограниченные военные возможности, и мы не можем позволить себе тратить их на эту угрозу. Пожалуйста, помогите нам справиться с вторжением в секторе (${x}:${y}). Вы можете оставить себе всё, что найдёте во время операции."
    end

    return _FinalDescription
end

mission.makeBulletin = function(_Station)
    local _MethodName = "Создание объявления"
    mission.Log(_MethodName, "Создание объявления.")
    local _Rgen = ESCCUtil.getRand()
    local _Sector = Sector()
    local target = {}
    local x, y = _Sector:getCoordinates()
    local insideBarrier = MissionUT.checkSectorInsideBarrier(x, y)
    target.x, target.y = MissionUT.getSector(x, y, 6, 12, false, false, false, false, insideBarrier)

    if not target.x or not target.y then
        mission.Log(_MethodName, "target.x или target.y не установлены — возвращаем nil.")
        return
    end

    local _DangerLevel = _Rgen:getInt(1, 10)

    local _Difficulty = "Лёгкий"
    if _DangerLevel >= 6 then
        _Difficulty = "Средний"
    end
    if _DangerLevel >= 9 then
        _Difficulty = "Сложная"
    end

    local _Description = lotwSide2_formatDescription(_Station)

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
        script = "missions/lotw/lotwside2.lua",
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
            if player:hasScript("lotwside2.lua") then
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
            reward = {credits = reward, relations = 6000, paymentMessage = "Получено %1% кредитов за уничтожение пиратских транспортов."},
            initialDesc = _Description,
            dangerLevel = _DangerLevel
        }},
    }

    return bulletin
end

--endregion
