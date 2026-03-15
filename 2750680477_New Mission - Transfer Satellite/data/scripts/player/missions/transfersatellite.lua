--[[
    Передача спутника
    ПРИМЕЧАНИЯ:
        - Вы перемещаете спутник, пристыковываясь к другому сектору. Легкотня.
    ДОПОЛНИТЕЛЬНЫЕ ТРЕБОВАНИЯ ДЛЯ ВЫПОЛНЕНИЯ ЭТОЙ МИССИИ:
        - Отсутствуют
    ПРИМЕРНЫЙ ПЛАН
        - Смотрите примечания. Это буквально все.
    УРОВЕНЬ ОПАСНОСТИ
        1+ - У игрока есть 10% шанс быть атакованным пиратами при высадке спутника.
        - Это всегда 4 корабля + 2 глушилки
        - Корабли будут масштабироваться в зависимости от уровня угрозы
]]
package.path = package.path .. ";data/scripts/lib/?.lua"
package.path = package.path .. ";data/scripts/?.lua"

include("structuredmission")

ESCCUtil = include("esccutil")

local PlanGenerator = include("plangenerator")
local AsyncPirateGenerator = include ("asyncpirategenerator")
local SpawnUtility = include ("spawnutility")
local Balancing = include ("galaxy")

mission._Debug = 0
mission._Name = "Передача спутника"

--region #INIT

--Стандартные данные миссии.
mission.data.brief = mission._Name
mission.data.title = mission._Name
mission.data.autoTrackMission = true
mission.data.description = {
    { text = "Вы получили следующий запрос от ${giverTitle} из сектора ${sectorName}:" }, --Заполнитель
    { text = "..." }, --Заполнитель
    { text = "Пристыкуйте спутник к своему кораблю", bulletPoint = true, fulfilled = false },
    { text = "Высадите спутник в секторе (${location.x}:${location.y})", bulletPoint = true, fulfilled = false, visible = false },
    { text = "Победите пиратскую засаду", bulletPoint = true, fulfilled = false, visible = false },
    { text = "Спутник должен выжить", bulletPoint = true, fulfilled = false, visible = false }
}
mission.data.timeLimit = 30 * 60 --У игрока есть 30 минут.
mission.data.timeLimitInDescription = true --Показать игроку, сколько времени осталось.

mission.data.accomplishMessage = "Спасибо за передачу нашего спутника. Награда была переведена на ваш счет."
mission.data.failMessage = "Вы потерпели неудачу. Это была простая задача. Как мы можем доверить вам что-то более важное?"

local TransferSatellite_init = initialize
function initialize(_Data_in)
    local _MethodName = "initialize"
    mission.Log(_MethodName, "Начинаем...")

    if onServer()then
        if not _restoring then
            mission.Log(_MethodName, "Вызов на сервере - dangerLevel : " .. tostring(_Data_in.dangerLevel))

            local _X, _Y = _Data_in.location.x, _Data_in.location.y

            local _Sector = Sector()
            local _Giver = Entity(_Data_in.giver)

            --[[=====================================================
                НАСТРОЙКА ПОЛЬЗОВАТЕЛЬСКИХ ДАННЫХ МИССИИ:
            =========================================================]]
            mission.data.custom.dangerLevel = _Data_in.dangerLevel
            mission.data.custom.playerAttacked =  false
            if _Data_in.playerAttacked == 10 then
                mission.Log(_MethodName, "Игрок подвергается нападению.")
                mission.data.custom.playerAttacked = true
            end
            mission.data.custom.inBarrier = _Data_in.inBarrier

            --[[=====================================================
                НАСТРОЙКА ОПИСАНИЯ МИССИИ:
            =========================================================]]
            mission.data.description[1].arguments = { sectorName = _Sector.name, giverTitle = _Giver.translatedTitle }
            mission.data.description[2].text = _Data_in.initialDesc
            mission.data.description[2].arguments = {x = _X, y = _Y }

            --Запустить стандартную инициализацию
            TransferSatellite_init(_Data_in)
        else
            --Восстановление
            TransferSatellite_init()
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

--region #ФАЗОВЫЕ ВЫЗОВЫ
--Постарайтесь держать вызовы таймера вне onBeginServer / onSectorEntered / onSectorArrivalConfirmed, если они не повторяются и длятся 30 секунд или меньше.

mission.globalPhase.getRewardedItems = function()
    --25% шанс получить случайное улучшение гиперпространства.
    if random():test(0.25) then
        local _SeedInt = random():getInt(1, 20000)
        local _Rarities = {RarityType.Common, RarityType.Common, RarityType.Uncommon, RarityType.Uncommon, RarityType.Rare}

        if mission.data.custom.inBarrier then
            _Rarities = {RarityType.Uncommon, RarityType.Uncommon, RarityType.Rare, RarityType.Rare, RarityType.Exceptional, RarityType.Exotic}
        end

        shuffle(random(), _Rarities)

        return SystemUpgradeTemplate("data/scripts/systems/hyperspacebooster.lua", Rarity(_Rarities[1]), Seed(_SeedInt))
    end
end

mission.globalPhase.onEntityDestroyed = function(id, lastDamageInflictor)
    local _DestroyedEntity = Entity(id)

    if _DestroyedEntity:getValue("_transfersatellite_objective") then
        transferSatellite_failAndPunish()
    end
end

mission.phases[1] = {}
mission.phases[1].sectorCallbacks = {}
mission.phases[1].showUpdateOnEnd = true
mission.phases[1].sectorCallbacks[1] = {
    name = "onEntityDocked",
    func = function(_DockerID, _DockeeID)
        local _DockedEntity = Entity(_DockeeID)

        if _DockedEntity:getValue("_transfersatellite_objective") then
            nextPhase()
        end
    end
}

mission.phases[1].onBeginServer = function()
    --Создать спутник
    local _Giver = Entity(mission.data.giver.id)
    local _Faction = Faction(mission.data.giver.factionIndex)

    local desc = EntityDescriptor()
    desc:addComponents(
       ComponentType.Plan,
       ComponentType.BspTree,
       ComponentType.Intersection,
       ComponentType.Asleep,
       ComponentType.DamageContributors,
       ComponentType.BoundingSphere,
       ComponentType.BoundingBox,
       ComponentType.Velocity,
       ComponentType.Physics,
       ComponentType.Scripts,
       ComponentType.ScriptCallback,
       ComponentType.Title,
       ComponentType.Owner,
       ComponentType.Durability,
       ComponentType.PlanMaxDurability,
       ComponentType.InteractionText,
       ComponentType.EnergySystem
       )

    local _SatellitePlan = PlanGenerator.makeStationPlan(_Faction)
    local _ScaleFactor = 15 / _SatellitePlan:getBoundingSphere().radius
    _SatellitePlan:scale(vec3(_ScaleFactor, _ScaleFactor, _ScaleFactor))
    _SatellitePlan.accumulatingHealth = true

    desc.position = transferSatellite_getPositionInFront(_Giver, 20)
    desc:setMovePlan(_SatellitePlan)
    desc.factionIndex = _Faction.index

    local _Satellite = Sector():createEntity(desc)
    _Satellite:setValue("_transfersatellite_objective", true)
    _Satellite:setTitle("Спутник", {})
end

mission.phases[2] = {}
mission.phases[2].sectorCallbacks = {}
mission.phases[2].sectorCallbacks[1] = {
    name = "onEntityUndocked",
    func = function(_DockerID, _DockeeID)
        local _UndockedEntity = Entity(_DockeeID)

        if atTargetLocation() then
            MissionUT.deleteOnPlayersLeft(_UndockedEntity)
            if _UndockedEntity:getValue("_transfersatellite_objective") then
                if mission.data.custom.playerAttacked then
                    nextPhase()
                else
                    transferSatellite_finishAndReward()
                end
            end
        end
    end
}

mission.phases[2].onBeginServer = function()
    mission.data.description[3].fulfilled = true
    mission.data.description[4].visible = true
end

mission.phases[3] = {}
mission.phases[3].showUpdateOnStart = true
mission.phases[3].timers = {}

--region #ФАЗА 3 ВЫЗОВЫ ТАЙМЕРА

if onServer() then

mission.phases[3].timers[2] = {
    time = 10, 
    callback = function() 
        local _MethodName = "Обратный вызов таймера 2 фазы 3"
        local _Sector = Sector()
        local _Pirates = {_Sector:getEntitiesByScriptValue("is_pirate")}
        mission.Log(_MethodName, "Количество пиратов : " .. tostring(#_Pirates) .. " таймеру разрешено продвигаться : " .. tostring(mission.data.custom.timerAdvance))
        if atTargetLocation() and mission.data.custom.timerAdvance and #_Pirates == 0 then
            transferSatellite_finishAndReward()
        end
    end,
    repeating = true
}

end

--endregion

mission.phases[3].onBeginServer = function()
    --Запустить 15-секундный таймер для создания пиратов и обновления целей миссии.
    mission.phases[3].timers[1] = {
        time = 15,
        callback = function()
            local _MethodName = "Обратный вызов таймера 1 фазы 3"
            mission.Log(_MethodName, "Начинаем.")

            transferSatellite_spawnPirateAmbush()
            mission.data.description[4].fulfilled = true
            mission.data.description[5].visible = true
            mission.data.description[6].visible = true
            sync()
        end,
        repeating = false
    }
end

--endregion

--region #СЕРВЕРНЫЕ ВЫЗОВЫ

function transferSatellite_getPositionInFront(craft, distance)

    local position = craft.position
    local right = position.right
    local dir = position.look
    local up = position.up
    local position = craft.translationf

    local pos = position + dir * (craft.radius + distance)

    return MatrixLookUpPosition(right, up, pos)
end

function transferSatellite_spawnPirateAmbush()
    local _MethodName = "Создать пиратскую засаду"
    mission.Log(_MethodName, "Начинаем.")

    local waveTable = ESCCUtil.getStandardWave(mission.data.custom.dangerLevel, 4, "Standard", false)

    table.insert(waveTable, 0, "Jammer")
    table.insert(waveTable, "Jammer")

    local generator = AsyncPirateGenerator(nil, transferSatellite_onPirateAmbushFinished)

    generator:startBatch()

    local posCounter = 1
    local distance = 250 --_#DistAdj
    local pirate_positions = generator:getStandardPositions(#waveTable, distance)
    for _, p in pairs(waveTable) do
        generator:createScaledPirateByName(p, pirate_positions[posCounter])
        posCounter = posCounter + 1
    end

    generator:endBatch()
end

function transferSatellite_onPirateAmbushFinished(_Generated)
    SpawnUtility.addEnemyBuffs(_Generated)

    mission.data.custom.timerAdvance = true
end

function transferSatellite_finishAndReward()
    local _MethodName = "Завершить и наградить"
    mission.Log(_MethodName, "Запускаем условие победы.")

    reward()
    accomplish()
end

function transferSatellite_failAndPunish()
    local _MethodName = "Провалить и наказать"
    mission.Log(_MethodName, "Запускаем условие проигрыша.")

    punish()
    fail()
end

--endregion

--region #MAKEBULLETIN ВЫЗОВ

function transferSatellite_formatDescription(_Station)
    local _Faction = Faction(_Station.factionIndex)
    local _Aggressive = _Faction:getTrait("aggressive")

    local descriptionType = 1 --Нейтральный
    if _Aggressive > 0.5 then
        descriptionType = 2 --Агрессивный.
    elseif _Aggressive <= -0.5 then
        descriptionType = 3 --Мирный.
    end

    local descriptionTable = {
        "Мы хотели бы расширить нашу сеть наблюдения. У нас есть спутник, готовый к развертыванию, но, к сожалению, мы не можем выделить корабли для его перемещения. Если вы сможете доставить его в сектор (${x}:${y}) и высадить, мы щедро заплатим вам за это. Это не самая гламурная работа, но это легкие деньги за легкую работу. Что скажете, капитан?", --Нейтральный
        "Нам нужна возможность лучше отслеживать фракцию пиратов, которая является особой занозой в заднице. С этой целью мы развертываем спутник-шпион в секторе (${x}:${y}). К сожалению, мы не можем выделить корабли для его перемещения. Вот тут-то и вступаете вы. Мы понимаем, что это может рассматриваться как унизительная работа, но это легкая работа. Мы, очевидно, заплатим вам за ваши усилия.", --Агрессивный
        "Мы разведываем новые сектора для создания поселения. Сектор (${x}:${y}) выглядит особенно многообещающим, но мы хотели бы собрать больше данных, прежде чем фактически обязуемся отправлять группу колонистов. Мы собрали спутник, который должен предоставить нам необходимые данные, но, к сожалению, у нас нет кораблей, чтобы его переместить. Если вы сможете переместить спутник для нас, мы заплатим вам за ваше время." --Мирный    
    }

    return descriptionTable[descriptionType]
end

mission.makeBulletin = function(_Station)
    local _MethodName = "Сделать бюллетень"
    --Нам не нужен здесь конкретный тип сектора. Просто пустой, который находится на той же стороне барьера, что и квестодатель.
    local _Rgen = ESCCUtil.getRand()
    local target = {}
    local x, y = Sector():getCoordinates()
    local insideBarrier = MissionUT.checkSectorInsideBarrier(x, y)
    target.x, target.y = MissionUT.getEmptySector(x, y, 12, 30, insideBarrier)

    if not target.x or not target.y then
        mission.Log(_MethodName, "Target.x или Target.y не установлены - возвращаем nil.")
        return 
    end

    local _DangerLevel = _Rgen:getInt(1, 10)
    local _PlayerAttacked = _Rgen:getInt(1, 10)

    local _Difficulty = "Легко"
    if _DangerLevel == 10 then
        _Difficulty = "Средне"
    end
    
    local _Description = transferSatellite_formatDescription(_Station)

    local _BaseReward = 37000
    --От 37000 до 40000
    for _ = 1, 3 do
        if _Rgen:getInt(1, 2) == 1 then
            _BaseReward = _BaseReward + 1000
        end
    end

    if insideBarrier then
        _BaseReward = _BaseReward * 2
    end

    reward = _BaseReward * Balancing.GetSectorRewardFactor(Sector():getCoordinates()) --УСТАНОВИТЬ НАГРАДУ ЗДЕСЬ

    local bulletin =
    {
        -- данные для доски объявлений
        brief = mission._Name,
        description = _Description,
        difficulty = "Легко",
        reward = "¢${reward}",
        script = "missions/transfersatellite.lua",
        formatArguments = {x = target.x, y = target.y, reward = createMonetaryString(reward)},
        msg = "Спасибо. Пожалуйста, высадите спутник в секторе \\s(%1%:%2%).",
        giverTitle = _Station.title,
        giverTitleArgs = _Station:getTitleArguments(),
        onAccept = [[
            local self, player = ...
            player:sendChatMessage(Entity(self.arguments[1].giver), 0, self.msg, self.formatArguments.x, self.formatArguments.y)
        ]],

        -- данные, важные для нашей собственной миссии
        arguments = {{
            giver = _Station.index,
            location = target,
            reward = {credits = reward, relations = 4000, paymentMessage = "Заработано %1% кредитов за передачу спутника."}, --Это очень легкая миссия, если вас не атакуют.
            punishment = {relations = 4000 },
            dangerLevel = _DangerLevel,
            initialDesc = _Description,
            playerAttacked = _PlayerAttacked,
            inBarrier = insideBarrier
        }},
    }

    return bulletin
end

--endregion
