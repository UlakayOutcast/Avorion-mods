--[[
    Расширение операций
        - Уровень разработки 1 - нормальный
        - Уровень 2 - +ремонтный док
        - Уровень 3 - +склад ресурсов
        - Уровень 4 - +док оборудования
        - Уровень 5 - +военный форпост
]]
package.path = package.path .. ";data/scripts/lib/?.lua"
package.path = package.path .. ";data/scripts/?.lua"

include("structuredmission")

ESCCUtil = include("esccutil")

local PlanGenerator = include("plangenerator")
local AsyncShipGenerator = include ("asyncshipgenerator")
local SectorGenerator = include ("SectorGenerator")
local AsyncPirateGenerator = include ("asyncpirategenerator")
local SpawnUtility = include ("spawnutility")
local Placer = include("placer")
local EventUT = include("eventutility")
local TorpedoUtility = include ("torpedoutility")
local Balancing = include("galaxy")

mission._Debug = 0
mission._Name = "Расширение контрабандистских операций"

--region #INIT

--Стандартные данные миссии
mission.data.brief = mission._Name
mission.data.title = mission._Name
mission.data.autoTrackMission = true
mission.data.description = {
    { text = "Вы получили следующий запрос от ${giverTitle} из сектора ${sectorName}:" }, --Заполнитель
    { text = "..." },
    { text = "Подготовьте свою оборону", bulletPoint = true, fulfilled = false },
    { text = "Защитите строительный корабль", bulletPoint = true, fulfilled = false, visible = false },
    { text = "Защитите каркас станции", bulletPoint = true, fulfilled = false, visible = false }
}

--Пользовательские данные, которые нам понадобятся.
mission.data.custom.constructionShipScriptValue = "expandoperations_construction_ship"
mission.data.custom.stationFrameScriptValue = "expandoperations_station_frame"
mission.data.custom.defenseObjectiveScriptValue = "expandoperations_defense_objective"

--Некоторые данные для ведения журнала
mission.data.custom.threatLogTbl = {
    "1 - фракция",
    "2 - пират",
    "3 - охотник за головами"
}

local expandOperations_init = initialize
function initialize(dataIn, bulletinIn)
    local methodName = "initialize"
    mission.Log(methodName, "Начинаем...")

    if onServer() and not _restoring then
        mission.Log(methodName, "Вызов на сервере - dangerLevel : " .. tostring(dataIn.dangerLevel) .. " threattype: " .. mission.data.custom.threatLogTbl[dataIn.threatType])

        local _sector = Sector()
        local giver = Entity(dataIn.giver)
        
        --Аварийный выход на случай, если игрок каким-то образом получил это от фракции игрока.
        if giver.playerOrAllianceOwned then
            print("ОШИБКА: Миссия от фракции игрока - прерывание.")
            terminate()
            return
        end
        --[[=====================================================
            НАСТРОЙКА ПОЛЬЗОВАТЕЛЬСКИХ ДАННЫХ МИССИИ:
        =========================================================]]
        mission.data.custom.dangerLevel = dataIn.dangerLevel
        mission.data.custom.threatType = dataIn.threatType
        mission.data.custom.friendlyFaction = giver.factionIndex
        if mission.data.custom.threatType == 1 then --1 = фракция / 2 = пираты / 3 = охотники за головами
            mission.data.custom.enemyFaction = dataIn.enemyFaction 

            local missionDoer = Player().craftFaction or Player()
            local relation = missionDoer:getRelation(mission.data.custom.enemyFaction)
            local enemyFaction = Faction(mission.data.custom.enemyFaction)
            local giverFaction = Faction(giver.factionIndex)
            local relation2Giver = giverFaction:getRelation(mission.data.custom.enemyFaction)

            mission.data.custom.enemyRelationLevel = relation.level
            mission.data.custom.enemyRelationStatus = relation.status
            mission.data.custom.enemyRelationLevel2Giver = relation2Giver.level
            mission.data.custom.enemyRelationStatus2Giver = relation2Giver.status

            mission.Log(methodName, "Вражеская фракция: " .. tostring(enemyFaction.name))
            mission.data.custom.enemyName = enemyFaction.name
        end
        mission.data.custom.developmentIndex = dataIn.developmentIndex
        mission.data.custom.inBarrier = dataIn.inBarrier
        mission.data.custom.phaseOneTimer = 0
        mission.data.custom.phaseOneMsgSent = false
        mission.data.custom.scaleStationFrameIndex = 0
        mission.data.custom.enemiesSpawned = 0
        mission.data.custom.noLootModulusFactor = 4
        mission.data.custom.bonusFactorFromHardWaves = 0
        mission.data.custom.stationFrameHealthBonus = true
        mission.data.custom.constructionShipHealthBonus = true
        mission.data.custom.enemyWavesSpawned = 0

        if not mission.data.custom.friendlyFaction then
            print("ОШИБКА: Дружественная фракция равна nil - прерывание.")
            terminate()
            return
        end

        --[[=====================================================
            НАСТРОЙКА ОПИСАНИЯ МИССИИ:
        =========================================================]]
        mission.data.description[1].arguments = { sectorName = _sector.name, giverTitle = giver.translatedTitle }
        mission.data.description[2].text = dataIn.initialDesc
        mission.data.description[2].arguments = { _FACTIONNAME = mission.data.custom.enemyName }
    end

    --Запустить ванильную инициализацию. Менеджеры _restoring самостоятельно.
    expandOperations_init(dataIn, bulletinIn)
end

--endregion

--region #ВЫЗОВЫ ФАЗ

mission.globalPhase.onAbandon = function()
    expandOperations_missionShipsDepart()

    if mission.internals.phaseIndex > 1 and mission.data.custom.threatType == 1 then --фракция
        --сбросить исходные отношения между двумя фракциями, но НЕ между игроком.
        local _Faction = Faction(mission.data.custom.enemyFaction)
        local _FriendlyFaction = Faction(mission.data.custom.friendlyFaction)
        local _Galaxy = Galaxy()

        _Galaxy:setFactionRelations(_Faction, _FriendlyFaction, mission.data.custom.enemyRelationLevel2Giver)
        _Galaxy:setFactionRelationStatus(_Faction, _FriendlyFaction, mission.data.custom.enemyRelationStatus2Giver)
    end
end

mission.globalPhase.onFail = function()
    expandOperations_missionShipsDepart()

    if mission.internals.phaseIndex > 1 then --Нет необходимости до завершения фазы 1
        expandOperations_doMissionEndCleanup() --Самостоятельно обрабатывает threatType == 1.
    end
end

mission.globalPhase.onAccomplish = function()
    expandOperations_missionShipsDepart()
    expandOperations_doMissionEndCleanup() --Самостоятельно обрабатывает threatType == 1.
end

mission.phases[1] = {}

mission.phases[1].updateTargetLocationServer = function(timeStep)
    local methodName = "Обновить целевое местоположение на сервере"
    mission.data.custom.phaseOneTimer = mission.data.custom.phaseOneTimer + timeStep

    local _sector = Sector()

    --Как оказалось, вы не можете не находиться в секторе для этого, так что...
    if mission.data.custom.phaseOneTimer >= 60 and not mission.data.custom.phaseOneMsgSent then
        mission.Log(methodName, "Осталась 1 минута. Отправляем уведомление.")

        local outpost = Entity(mission.data.giver.id)
        _sector:broadcastChatMessage(outpost, ChatMessageType.Chatter, "Мы скоро отправим корабль! Приготовьтесь защищать его!")

        mission.data.custom.phaseOneMsgSent = true
    end

    if mission.data.custom.phaseOneTimer >= 120 then
        local outpost = Entity(mission.data.giver.id)
        _sector:broadcastChatMessage(outpost, ChatMessageType.Chatter, "Развертываем строительный корабль! Пожалуйста, подождите.")

        nextPhase()
    end
end

mission.phases[1].onTargetLocationLeft = function(x, y)
    mission.data.timeLimit = mission.internals.timePassed + (10 * 60) --У игрока есть 10 минут, чтобы вернуться.
    mission.data.timeLimitInDescription = true --Показать игроку, сколько времени осталось.
end

mission.phases[1].onTargetLocationEntered = function(x, y)
    mission.data.timeLimit = nil 
    mission.data.timeLimitInDescription = false
end

mission.phases[2] = {}
mission.phases[2].timers = {}
mission.phases[2].onBegin = function()
    mission.data.description[3].fulfilled = true
    mission.data.description[4].visible = true
end

mission.phases[2].onBeginServer = function()
    local methodName = "Фаза 2 при запуске на сервере"
    --Создать строительный корабль и приказать ему улететь.
    expandOperations_createConstructionShip()

    --Объявить войну, если необходимо.
    if mission.data.custom.threatType == 1 then --вражеская фракция
        local _Galaxy = Galaxy()
        local _MissionDoer = Player().craftFaction or Player()
        local enemyFaction = Faction(mission.data.custom.enemyFaction)
        local friendlyFaction = Faction(mission.data.custom.friendlyFaction)

        if mission.data.custom.enemyRelationStatus ~= RelationStatus.War then
            mission.Log(methodName, "Вражеская фракция еще не воюет с игроком. Объявляем войну.")
            
            _Galaxy:setFactionRelations(enemyFaction, _MissionDoer, -100000)
            _Galaxy:setFactionRelationStatus(enemyFaction, _MissionDoer, RelationStatus.War)
        end

        if mission.data.custom.enemyRelationStatus2Giver ~= RelationStatus.War then
            mission.Log(methodName, "Вражеская фракция еще не воюет с фракцией миссии. Объявляем войну.")

            _Galaxy:setFactionRelations(enemyFaction, friendlyFaction, -100000)
            _Galaxy:setFactionRelationStatus(enemyFaction, friendlyFaction, RelationStatus.War)
        end

        Player():sendChatMessage(mission.data.custom.enemyName, 0, "Вы хотите помочь этой контрабандистской мрази? Давно пора было уничтожить эту заразу на нашей территории.")
    end

    sync() --Мы хотим синхронизировать mission.data.custom.scaleStationFrameIndex здесь.
end

mission.phases[2].onEntityDestroyed = function(id, lastDamageInflictor)
    if atTargetLocation() then
        local destroyedEntity = Entity(id)
        if destroyedEntity:getValue(mission.data.custom.defenseObjectiveScriptValue) then
            expandOperations_failAndPunish()
        end
    end
end

mission.phases[2].onTargetLocationLeft = function(x, y)
    mission.data.timeLimit = mission.internals.timePassed + (5 * 60) --У игрока есть 5 минут, чтобы вернуться.
    mission.data.timeLimitInDescription = true --Показать игроку, сколько времени осталось.
end

mission.phases[2].onTargetLocationEntered = function(x, y)
    mission.data.timeLimit = nil 
    mission.data.timeLimitInDescription = false
end

--region #ВЫЗОВЫ ТАЙМЕРОВ ФАЗЫ 2

if onServer() then

mission.phases[2].timers[1] = {
    time = 10,
    callback = function()
        local _sector = Sector()

        local constructionShip = expandOperations_getEntityByValue(_sector, mission.data.custom.constructionShipScriptValue)

        local stationTbl = { _sector:getEntitiesByType(EntityType.Station) }

        local shipAI = ShipAI(constructionShip)

        if expandOperations_isConstrcutionShipPositionGood(constructionShip, stationTbl) then
            shipAI:stop()
            nextPhase()
        else
            --Проверьте, чтобы убедиться, что корабль все еще летит. Если это не так, отправьте его в другом случайном направлении.
            if not shipAI.state == AIState.Fly then
                local endPoint = constructionShip.translationf + (random():getDirection() * 100000)
                shipAI:setFly(endPoint, 0, nil, nil, true)
            end
        end
    end,
    repeating = true
}

mission.phases[2].timers[2] = {
    time = 45,
    callback = function()
        local methodName = "Обратный вызов таймера 2 фазы 2"
        if atTargetLocation() then
            mission.Log(methodName, "Порождение волны атаки.")

            local threatFuncs = {
                function()
                    expandOperations_spawnFactionWave(false)
                end,
                function()
                    expandOperations_spawnPirateWave(false)
                end,
                function()
                    expandOperations_spawnHeadhunterWave(false)
                end
            }

            threatFuncs[mission.data.custom.threatType]()
        end
    end,
    repeating = true
}

end

--endregion

mission.phases[3] = {}
mission.phases[3].timers = {}
mission.phases[3].updateInterval = function()
    if onClient() then
        return 0
    else --onServer()
        return 1
    end
end

mission.phases[3].onBegin = function()
    mission.data.description[5].visible = true
end

mission.phases[3].onBeginServer = function()
    local _sector = Sector()
    --Создать каркас станции и начать строительство.
    local constructionShip = expandOperations_getEntityByValue(_sector, mission.data.custom.constructionShipScriptValue)

    local stationFramePosition = expandOperations_getPositionInFront(constructionShip, 750)
    expandOperations_createStationFrame(stationFramePosition)

    _sector:broadcastChatMessage(constructionShip, ChatMessageType.Chatter, "Развертываем каркас станции! Защитите нас, пока мы строим станцию.")
    constructionShip:setValue("no_chatter", true) --без болтовни, потому что...

    --мы добавляем свои собственные!
    local radioChatterLines = {
        "Я на работе.",
        "Вы прерываете мои вычисления!",
        "Я установлю ее в кратчайшие сроки.",
        "Два плюс три умножить на четыре... что вам нужно?!",
        "Нет, нет, нет! Не так! Дайте мне это сделать.",
        "Этого нет в чертежах.",
        "Как это было одобрено?",
        "Вы хотите, чтобы я сделал что?",
        "Сертифицированный инженер придумал бы что-нибудь получше.",
        "Да, да, я уже занимаюсь этим."
    }

    if random():test(0.05) then --Добавить раздраженные строки.
        local easterEggLines = { 
            "Послушайте, я инженер, мое время ценно.",
            "Почему бы вам не побеспокоить кого-нибудь другого своим непрекращающимся щелканьем?",
            "Если это действительно так срочно, почему бы вам не сделать это самому?",
            "Это просто. Просто возьмите эмулятор гидравлического фазового сдвига и прикрепите его к транспространственному излучателю фотонных частиц. Бац! Новая башня.",
            "'Я установлю ее в кратчайшие сроки.' является официальным термином Союза не вызывающих подозрений, совершенно законных инженеров. Это не следует интерпретировать как разумную оценку фактического времени, которое потребуется для выполнения задачи каким-либо образом, в какой-либо форме.",
            "Хм... защита башни... Нет, это глупая идея. Это никогда не сработает!"
        }

        table.insert(radioChatterLines, getRandomEntry(easterEggLines))
    end

    --Если кому-то интересно, откуда это взялось, то это инженер Кровавых Эльфов из WC3 - внес несколько небольших изменений, чтобы сделать их более подходящими для Avorion.
    constructionShip:addScriptOnce("data/scripts/entity/utility/radiochatter.lua", radioChatterLines, 90, 120, random():getInt(30, 60))
end

mission.phases[3].updateTargetLocationServer = function(timeStep)
    local constructionShip = expandOperations_getEntityByValue(_sector, mission.data.custom.constructionShipScriptValue)
    if constructionShip and valid(constructionShip) then
        local constructionShipHull = constructionShip.durability
        local constructionShipMaxHull = constructionShip.maxDurability

        local ratio = constructionShipHull / constructionShipMaxHull
        if ratio < 0.5 then
            mission.data.custom.constructionShipHealthBonus = false
        end
    end

    local stationFrame = expandOperations_getEntityByValue(_sector, mission.data.custom.stationFrameScriptValue)
    if stationFrame and valid(stationFrame) then
        local stationFrameHull = stationFrame.durability
        local stationFrameMaxHull = stationFrame.maxDurability

        local ratio = stationFrameHull / stationFrameMaxHull
        if ratio < 0.75 then
            mission.data.custom.stationFrameHealthBonus = false
        end
    end
end

mission.phases[3].onTargetLocationLeft = function(x, y)
    expandOperations_failAndPunish() --Просто предположим, что мы потерпели неудачу, чтобы нам не пришлось иметь дело с таймером.
end

mission.phases[3].onEntityDestroyed = function(id, lastDamageInflictor)
    if atTargetLocation() then
        local destroyedEntity = Entity(id)
        if destroyedEntity:getValue(mission.data.custom.defenseObjectiveScriptValue) then
            expandOperations_failAndPunish()
        end
    end
end

--region #ВЫЗОВЫ ТАЙМЕРОВ ФАЗЫ 3

if onClient() then --Ух ты! Еще один таймер onClient!

mission.phases[3].timers[1] = {
    time = 0.05,
    callback = function()
        if atTargetLocation() then
            expandOperations_drawConstructionLaser()
        end
    end,
    repeating = true
}

end

if onServer() then

mission.phases[3].timers[2] = {
    time = 150,
    callback = function()
        local methodName = "Обратный вызов таймера 2 фазы 3"
        if atTargetLocation() then
            local stationFrameScaleTbl = { vec3(2,2,2), vec3(1.5, 1.5, 1.5), vec3(1.33, 1.33, 1.33) }
            local scaleIndex = mission.data.custom.scaleStationFrameIndex + 1

            if scaleIndex > #stationFrameScaleTbl then
                mission.Log(methodName, "Индекс масштаба равен " .. tostring(scaleIndex) .. " это превышает размер таблицы - замена станции, затем завершение и вознаграждение.")
                nextPhase()
            else
                mission.Log(methodName, "Индекс масштаба равен " .. tostring(scaleIndex) .. " масштабирование каркаса станции.")
                expandOperations_scaleStationFramePlan(stationFrameScaleTbl[scaleIndex])
            end

            mission.data.custom.scaleStationFrameIndex = scaleIndex
            sync() --мы хотим это и на клиенте.
        else
            expandOperations_failAndPunish()
        end
    end,
    repeating = true
}

mission.phases[3].timers[3] = {
    time = 70,
    callback = function()
        local methodName = "Обратный вызов таймера 3 фазы 3"
        if atTargetLocation() then
            mission.data.custom.enemyWavesSpawned = mission.data.custom.enemyWavesSpawned + 1
            mission.Log(methodName, "Порождение волны атаки " .. tostring(mission.data.custom.enemyWavesSpawned) .. ".")

            local threatFuncs = {
                function()
                    expandOperations_spawnFactionWave(true)
                end,
                function()
                    expandOperations_spawnPirateWave(true)
                end,
                function()
                    expandOperations_spawnHeadhunterWave(true)
                end
            }

            threatFuncs[mission.data.custom.threatType]()
        end
    end,
    repeating = true
}
mission.phases[3].timers[4] = {
    time = 30,
    callback = function()
        if atTargetLocation() then
            local stationFrame = expandOperations_getEntityByValue(_sector, mission.data.custom.stationFrameScriptValue)

            if stationFrame and valid(stationFrame) then
                local stationFrameHull = stationFrame.durability
                local stationFrameMaxHull = stationFrame.maxDurability
        
                if stationFrameHull < stationFrameMaxHull then
                    local healAmount = stationFrameMaxHull * 0.025 --Heal 2.5% every 30 seconds.

                    stationFrame.durability = math.min(stationFrameMaxHull, stationFrame.durability + healAmount)
                    invokeClientFunction(Player(), "expandOperations_playHealingAnimation")
                end
            end
        end
    end,
    repeating = true
}

end

--endregion

mission.phases[4] = {}
mission.phases[4].timers = {}
mission.phases[4].onBeginServer = function()
    local methodName = "Phase 4 On Begin Server"

    local _sector = Sector()
    local _random = random()
    local x, y = _sector:getCoordinates()
    local sectorGenerator = SectorGenerator(x, y)

    --Have the construction ship go off somewhere and delete it after 20-30 seconds.
    local constructionShip = expandOperations_getEntityByValue(_sector, mission.data.custom.constructionShipScriptValue)
    local shipAI = ShipAI(constructionShip)

    local endPoint = constructionShip.translationf + (_random:getDirection() * 100000)
    shipAI:setFly(endPoint, 0, nil, nil, true)

    constructionShip:addScript("utility/delayeddelete.lua", _random:getFloat(4, 5))

    --Replace the station frame with an actual real station.
    local stationFrame = expandOperations_getEntityByValue(_sector, mission.data.custom.stationFrameScriptValue)
    local sFrameLook = vec3(stationFrame.position.look.x, stationFrame.position.look.y, stationFrame.position.look.z)
    local sFrameUp = vec3(stationFrame.position.up.x, stationFrame.position.up.y, stationFrame.position.up.z)
    local sFramePos = vec3(stationFrame.position.pos.x, stationFrame.position.pos.y, stationFrame.position.pos.z)

    local stationFrameMatrix = MatrixLookUpPosition(sFrameLook, sFrameUp, sFramePos)

    --First, delete all of the asteroids around the station frame.
    local stationFrameSphere = stationFrame:getBoundingSphere()
    local asteroidRemovalSphere = Sphere(stationFrameSphere.center, stationFrameSphere.radius * 15) 
    local removalCandidates = {_sector:getEntitiesByLocation(asteroidRemovalSphere)}
    mission.Log(methodName, "Found " .. tostring(#removalCandidates) .. " candidates for removal. Any asteroids in this list will be removed.")
    for _, _En in pairs(removalCandidates) do
        if _En.isAsteroid then
            --Don't stump the AI.
            _sector:deleteEntity(_En)
        end
    end

    local funcTbl = {
        nil, --we will never hit index 1
        function() --index 2 (repair dock)
            local newStation = sectorGenerator:createRepairDock(Faction(mission.data.custom.friendlyFaction))
            newStation.position = stationFrameMatrix
        end,
        function() --index 3 (resource depot)
            local newStation = sectorGenerator:createStation(Faction(mission.data.custom.friendlyFaction), "data/scripts/entity/merchants/resourcetrader.lua")
            newStation.position = stationFrameMatrix
        end,
        function() --index 4 (equipment dock)
            local newStation = sectorGenerator:createEquipmentDock(Faction(mission.data.custom.friendlyFaction))
            newStation.position = stationFrameMatrix
        end,
        function() --index 5 (military outpost)
            local newStation = sectorGenerator:createMilitaryBase(Faction(mission.data.custom.friendlyFaction))
            newStation.position = stationFrameMatrix
        end
    }

    _sector:deleteEntity(stationFrame)
    funcTbl[mission.data.custom.developmentIndex]()

    --Finally, we replace all the defenders
    local defenderCt = ESCCUtil.countEntitiesByValue("is_defender")
    local desiredDefenderCt = ESCCUtil.countEntitiesByType(EntityType.Station)
    
    local defendersToSpawn = desiredDefenderCt - defenderCt

    if defendersToSpawn > 0 then
        local defenderGenerator = AsyncShipGenerator(nil, expandOperations_replacementDefendersFinished)

        defenderGenerator:startBatch()
    
        for _ = 1, defendersToSpawn do
            defenderGenerator:createDefender(Faction(mission.data.custom.friendlyFaction), defenderGenerator:getGenericPosition())
        end
        
        defenderGenerator:endBatch()
    end

    Placer.resolveIntersections()
end

--region #PHASE 4 TIMER CALLS

if onServer() then

mission.phases[4].timers[1] = {
    time = 15,
    callback = function()
        local methodName = "Phase 4 Timer 1 Callback"
        mission.Log(methodName, "Running win condition timer.")

        expandOperations_finishAndReward()
    end,
    repeating = true --Not like it matters - this is the win condition.
}

end

--endregion

--endregion

--region #SERVER CALLS

function expandOperations_getPositionInFront(craft, distance)
    local methodName = "Get Position In Front"
    mission.Log(methodName, "Running...")

    local position = craft.position
    local right = position.right
    local dir = position.look
    local up = position.up
    local position = craft.translationf

    local pos = position + dir * (craft.radius + distance)

    return MatrixLookUpPosition(right, up, pos)
end

function expandOperations_createConstructionShip()
    local outpost = Entity(mission.data.giver.id)
    local x, y = Sector():getCoordinates()
    local shipGenerator = AsyncShipGenerator(nil, expandOperations_onConstructionShipFinished)

    local constructionShipVolume = Balancing_GetSectorShipVolume(x, y) * 6

    local pos = expandOperations_getPositionInFront(outpost, 250)

    shipGenerator:startBatch()

    shipGenerator:createMiningShip(Faction(mission.data.custom.friendlyFaction), pos, constructionShipVolume)

    shipGenerator:endBatch()
end

function expandOperations_onConstructionShipFinished(generated)
    local outpost = Entity(mission.data.giver.id)
    local constructionShip = generated[1]

    constructionShip.title = "Construction Ship"

    constructionShip:setValue(mission.data.custom.defenseObjectiveScriptValue, true)
    constructionShip:setValue(mission.data.custom.constructionShipScriptValue, true)

    local endPoint = outpost.translationf + (random():getDirection() * 100000)

    local constructionShipDurabilityFactor = 6
    local x, y = Sector():getCoordinates()

    local distToCenter = math.sqrt(x*x + y*y)
    if distToCenter > 360 then
        constructionShipDurabilityFactor = constructionShipDurabilityFactor * 1.5 --Increase it a bit becasue ships are much less tough, relatively speaking, in the outer regions.
    end

    ESCCUtil.multiplyOverallDurability(constructionShip, constructionShipDurabilityFactor)
    ESCCUtil.replaceIcon(constructionShip, "data/textures/icons/pixel/shipyard-repair.png")

    local constructionShipAI = ShipAI(constructionShip)
    constructionShipAI:setFly(endPoint, 0, nil, nil, true)

    Placer.resolveIntersections(generated)
end

function expandOperations_isConstrcutionShipPositionGood(constructionShip, stationTbl)
    local positionOK = true

    --is the construction ship at least 30 km from all stations?
    for _, station in pairs(stationTbl) do
        local dist = constructionShip:getNearestDistance(station)
        if dist < 3000 then
            positionOK = false
            break --no point in checking further
        end
    end

    return positionOK
end

function expandOperations_createStationFrame(framePosition)
    local methodName = "Create Station Frame"

    local _Faction = Faction(mission.data.custom.friendlyFaction)

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

    local stationFramePlan, stationFrameSeed, stationFrameVolume, stationFrameMaterial = PlanGenerator.makeStationPlan(_Faction)

    local planSize = stationFramePlan:getBoundingBox().size * 0.25
    local indices = {stationFramePlan:getBlockIndices()}
    local color = ColorRGB(0.4, 0.4, 0.4)
    for i, index in pairs(indices) do
        local blockPosition = stationFramePlan:getBlock(index).box.position
        if math.abs(blockPosition.x) > planSize.x or math.abs(blockPosition.y) > planSize.y or math.abs(blockPosition.z) > planSize.z then
            if i % 5 == 0 then
                stationFramePlan:setBlockType(index, BlockType.Framework)
                stationFramePlan:setBlockColor(index, color)
            end
        else
            if i % 14 == 0 then
                stationFramePlan:setBlockType(index, BlockType.Framework)
                stationFramePlan:setBlockColor(index, color)
            end
        end
    end

    for i, index in pairs(indices) do
        if i % 3 == 0 then
            local box = stationFramePlan:getBlock(index).box
            local size = box.size
            local minAxis = 0
            if size.y < size.x then minAxis = 1 end
            if size.z < size.y then minAxis = 2 end

            local thickness = 3
            local offset = vec3()

            if minAxis == 0 then
                offset.x = (size.x + thickness) * 0.5
                size.x = thickness
            else
                offset.x = random():getFloat(size.x * 0.1, size.x * 0.3)
                size.x = random():getFloat(size.x * 0.5, size.x)
            end

            if minAxis == 1 then
                offset.y = (size.y + thickness) * 0.5
                size.y = thickness
            else
                offset.y = random():getFloat(size.y * 0.1, size.y * 0.3)
                size.y = random():getFloat(size.y * 0.5, size.y)
            end

            if minAxis == 2 then
                offset.z = (size.z + thickness) * 0.5
                size.z = thickness
            else
                offset.z = random():getFloat(size.z * 0.1, size.z * 0.3)
                size.z = random():getFloat(size.z * 0.5, size.z)
            end

            stationFramePlan:addBlock(box.position + offset, size, index, -1, color, stationFrameMaterial, Matrix(), BlockType.Framework, ColorNone())
            stationFramePlan:addBlock(box.position - offset, size, index, -1, color, stationFrameMaterial, Matrix(), BlockType.Framework, ColorNone())
        end
    end

    local _ScaleFactor = 0.25
    stationFramePlan:scale(vec3(_ScaleFactor, _ScaleFactor, _ScaleFactor))
    stationFramePlan.accumulatingHealth = true

    desc.position = framePosition
    desc:setMovePlan(stationFramePlan)
    desc.factionIndex = _Faction.index

    local stationFrame = Sector():createEntity(desc)
    stationFrame:setValue(mission.data.custom.defenseObjectiveScriptValue, true)
    stationFrame:setValue(mission.data.custom.stationFrameScriptValue, true)
    stationFrame:setTitle("Construction Site", {})

    Physics(stationFrame).driftDecrease = 0.2

    ESCCUtil.multiplyOverallDurability(stationFrame, 1.5)

    mission.Log(methodName, "Station frame created - entity type is " .. tostring(stationFrame.type))

    Placer.resolveIntersections()
end

function expandOperations_scaleStationFramePlan(scaleFactor)
    local stationFrame = expandOperations_getEntityByValue(nil, mission.data.custom.stationFrameScriptValue)
    local stationFramePlan = stationFrame:getFullPlanCopy()

    stationFramePlan:scale(scaleFactor)
    stationFrame:setMovePlan(stationFramePlan)
end

function expandOperations_replacementDefendersFinished(generated)
    for _, defender in pairs(generated) do
        defender:removeScript("antismuggle.lua")
    end

    Placer.resolveIntersections(generated)
end

function expandOperations_spawnFactionWave(largeWave)
    local methodName = "Spawn Faction Wave"
    mission.Log(methodName, "Beginning...")

    local _random = random()

    local distance = 2500 --_#FACTDistAdj

    local spawnFunc = function(wingScriptValue, wingOnSpawnFunc)
        local maxCt = 4
        local spawnThreat = "Standard"
        if mission.data.custom.dangerLevel > 5 and _random:test(mission.data.custom.dangerLevel * 0.025) then
            mission.data.custom.bonusFactorFromHardWaves = mission.data.custom.bonusFactorFromHardWaves + 0.015
            spawnThreat = "High"
        end
        if mission.data.custom.dangerLevel == 10 and _random:test(0.25) then
            maxCt = maxCt + 1
        end

        local enemyCt = ESCCUtil.countEntitiesByValue(wingScriptValue)
        local spawnCt = maxCt - enemyCt

        local spawnTable = ESCCUtil.getStandardWave(mission.data.custom.dangerLevel, spawnCt, spawnThreat, true)

        local wingGenerator = AsyncShipGenerator(nil, wingOnSpawnFunc)
        local enemyFaction = Faction(mission.data.custom.enemyFaction)

        local wingPositions = wingGenerator:getStandardPositions(spawnCt, distance)

        wingGenerator:startBatch()

        for posIdx, es in pairs(spawnTable) do
            wingGenerator:createDefenderByName(enemyFaction, wingPositions[posIdx], es)
        end

        wingGenerator:endBatch()
    end

    spawnFunc("expandoperations_alpha_wing", expandOperations_onAlphaWingFinished)

    if largeWave then
        spawnFunc("expandoperations_beta_wing", expandOperations_onBetaWingFinished)

        if _random:test(0.05 * mission.data.custom.dangerLevel) then
            spawnFunc("expandoperations_gamma_wing", expandOperations_onGammaWingFinished)
        end
    end
end

function expandOperations_spawnPirateWave(largeWave)
    local methodName = "Spawn Pirate Wave"
    mission.Log(methodName, "Beginning...")

    local _random = random()

    local distance = 250 --_#DistAdj

    local spawnFunc = function(wingScriptValue, wingOnSpawnFunc)
        local maxCt = 4
        local spawnThreat = "Standard"
        if mission.data.custom.dangerLevel > 5 and _random:test(mission.data.custom.dangerLevel * 0.025) then
            mission.data.custom.bonusFactorFromHardWaves = mission.data.custom.bonusFactorFromHardWaves + 0.015
            spawnThreat = "High"
        end
        if mission.data.custom.dangerLevel == 10 and _random:test(0.5) then
            maxCt = maxCt + 1
        end
        
        local pirateCt = ESCCUtil.countEntitiesByValue(wingScriptValue)
        local spawnCt = maxCt - pirateCt

        local spawnTable = ESCCUtil.getStandardWave(mission.data.custom.dangerLevel, spawnCt, spawnThreat, false)
        local wingGenerator = AsyncPirateGenerator(nil, wingOnSpawnFunc)

        local wingPositions = wingGenerator:getStandardPositions(spawnCt, distance)

        wingGenerator:startBatch()

        for posCtr, p in pairs(spawnTable) do
            wingGenerator:createScaledPirateByName(p, wingPositions[posCtr])
        end

        wingGenerator:endBatch()
    end

    spawnFunc("expandoperations_alpha_wing", expandOperations_onAlphaWingFinished)

    if largeWave then
        spawnFunc("expandoperations_beta_wing", expandOperations_onBetaWingFinished)

        if _random:test(0.05 * mission.data.custom.dangerLevel) then
            spawnFunc("expandoperations_gamma_wing", expandOperations_onGammaWingFinished)
        end
    end
end

function expandOperations_spawnHeadhunterWave(largeWave)
    local methodName = "Spawn Headhunter Wave"
    mission.Log(methodName, "Beginning...")

    --We don't have fancy tech to spawn this like the factions / pirates, so we do this the old fashioned way.
    local _random = random()
    local hunterVolume = Balancing_GetSectorShipVolume(Sector():getCoordinates())

    mission.Log(methodName, "Hunter volume is " .. tostring(hunterVolume))

    local spawnFunc = function(wingScriptValue, wingOnSpawnFunc)
        local maxCt = 4
        local bonusHunterVolume = math.floor(mission.data.custom.dangerLevel / 2.5) --Caps out at x4 @ danger 10
        if mission.data.custom.dangerLevel >= 5 and _random:test(0.5) then
            mission.data.custom.bonusFactorFromHardWaves = mission.data.custom.bonusFactorFromHardWaves + 0.0075
            maxCt = maxCt + 1
        end
        if mission.data.custom.dangerLevel == 10 and _random:test(0.25) then
            mission.data.custom.bonusFactorFromHardWaves = mission.data.custom.bonusFactorFromHardWaves + 0.0075
            maxCt = maxCt + 1
        end
        if _random:test(mission.data.custom.dangerLevel * 0.025) then
            bonusHunterVolume = bonusHunterVolume + 1
        end
        if mission.data.custom.dangerLevel == 10 and _random:test(0.25) then
            bonusHunterVolume = bonusHunterVolume + 1
        end
        bonusHunterVolume = math.max(bonusHunterVolume, 1)

        local hunterFaction = expandOperations_getHeadhunterFaction()
        local hunterCt = ESCCUtil.countEntitiesByValue(wingScriptValue)
        local spawnCt = maxCt - hunterCt

        local hunterGenerator = AsyncShipGenerator(nil, wingOnSpawnFunc)

        local hunterPositions = hunterGenerator:getStandardPositions(200, spawnCt)

        local spawnBlocker = spawnCt == maxCt
        local blockerPosition = spawnCt --Always spawn in last position.

        hunterGenerator:startBatch()

        for idx, hunterPosition in pairs(hunterPositions) do --For once, we don't need position counter.
            if idx == blockerPosition and spawnBlocker then
                hunterGenerator:createBlockerShip(hunterFaction, hunterPosition, (hunterVolume * bonusHunterVolume) / 2)
            else
                hunterGenerator:createPersecutorShip(hunterFaction, hunterPosition, hunterVolume * bonusHunterVolume)
            end
        end

        hunterGenerator:endBatch()
    end

    spawnFunc("expandoperations_alpha_wing", expandOperations_onAlphaWingFinished)

    if largeWave then
        spawnFunc("expandoperations_beta_wing", expandOperations_onBetaWingFinished)

        if _random:test(0.05 * mission.data.custom.dangerLevel) then
            spawnFunc("expandoperations_gamma_wing", expandOperations_onGammaWingFinished)
        end
    end
end
function expandOperations_onAlphaWingFinished(generated)
    local methodName = "On Alpha Wing Finished"
    mission.Log(methodName, "Выполняется...")
    --Priorty attacker => construction 
    local wingScriptValue = "expandoperations_alpha_wing"
    local _random = random()

    expandOperations_onWingFinished(generated, wingScriptValue, 1, mission.data.custom.constructionShipScriptValue, false)

    --if there are no torp slammers in the group, 75-25% chance to add one - goes down as danger level goes up. torp slammer targets construction ship
    shuffle(random(), generated)
    local torpSlammerCount = ESCCUtil.countEntitiesByValueAndScript(wingScriptValue, "torpedoslammer.lua")
    local torpSlammerChance = 0.75 - (mission.data.custom.dangerLevel * 0.05)

    if torpSlammerCount == 0 and _random:test(torpSlammerChance) then
        local torpSlammerCandidate = generated[1]

        local torpSlammerValues = expandOperations_getTorpSlammerTable(mission.data.custom.constructionShipScriptValue)
        torpSlammerCandidate:addScriptOnce("torpedoslammer.lua", torpSlammerValues)
        if mission.data.custom.threatType == 2 then --Pirates
            ESCCUtil.setBombardier(torpSlammerCandidate)
        else
            ESCCUtil.setFusilier(torpSlammerCandidate)
        end

        --Finally, make it immune to the defenders.
        local slammerDurability = Durability(torpSlammerCandidate)
        if slammerDurability then
            slammerDurability:addFactionImmunity(mission.data.custom.friendlyFaction)
        end
    end
end

function expandOperations_onBetaWingFinished(generated)
    local methodName = "On Beta Wing Finished"
    mission.Log(methodName, "Выполняется...")
    --Priority attacker => defender / player OR priority attacker => station frame.
    local wingScriptValue = "expandoperations_beta_wing"
    local defenderCt = ESCCUtil.countEntitiesByValue("is_defender")
    local _random = random()

    if _random:test(0.5) then
        expandOperations_onWingFinished(generated, wingScriptValue, 1, mission.data.custom.stationFrameScriptValue, true)

        --if there are no torp slammers in the group, 75-25% chance to add one - goes down as danger level goes up. torp slammer targets station frame.
        local torpSlammerCount = ESCCUtil.countEntitiesByValueAndScript(wingScriptValue, "torpedoslammer.lua")
        local torpSlammerChance = 0.75 - (mission.data.custom.dangerLevel * 0.05)

        if torpSlammerCount == 0 and _random:test(torpSlammerChance) then
            local torpSlammerCandidate = generated[1]

            local torpSlammerValues = expandOperations_getTorpSlammerTable(mission.data.custom.stationFrameScriptValue)
            torpSlammerCandidate:addScriptOnce("torpedoslammer.lua", torpSlammerValues)
            if mission.data.custom.threatType == 2 then --Pirates
                ESCCUtil.setBombardier(torpSlammerCandidate)
            else
                ESCCUtil.setFusilier(torpSlammerCandidate)
            end

            --Finally, make it immune to the defenders.
            local slammerDurability = Durability(torpSlammerCandidate)
            if slammerDurability then
                slammerDurability:addFactionImmunity(mission.data.custom.friendlyFaction)
            end
        end
    else
        if defenderCt > 0 and _random:test(0.5) then
            expandOperations_onWingFinished(generated, wingScriptValue, 1, "is_defender", false)
        else
            expandOperations_onWingFinished(generated, wingScriptValue, 2, nil, false)
        end
    end
end

function expandOperations_onGammaWingFinished(generated)
    local methodName = "On Gamma Wing Finished"
    mission.Log(methodName, "Выполняется...")
    --50/50 - priority attacker => defender OR priority attacker => player - assign value to all ships in the wing.
    local wingScriptValue = "expandoperations_gamma_wing"
    local defenderCt = ESCCUtil.countEntitiesByValue("is_defender")

    if defenderCt > 0 and random():test(0.5) then
        expandOperations_onWingFinished(generated, wingScriptValue, 1, "is_defender", false)
    else
        expandOperations_onWingFinished(generated, wingScriptValue, 2, nil, false)
    end
end

function expandOperations_getTorpSlammerTable(targetTag)
    --Same idea as defend prototype. Lower difficulty torps need to be more dangerous to compensate for lack of difficulty.
    local _DmgFactor = 4
    local _tta = 30
    local _PrefType = TorpedoUtility.WarheadType.Tandem
    local rangeFactor = 6
    if mission.data.custom.dangerLevel >= 5 then
        _PrefType = TorpedoUtility.WarheadType.Nuclear
        _DmgFactor = 2
        _tta = 35
        rangeFactor = 3
    elseif mission.data.custom.dangerLevel == 10 then
        _PrefType = TorpedoUtility.WarheadType.Nuclear
        _DmgFactor = 1
        _tta = 40
        rangeFactor = 3
    end
    if mission.data.custom.threatType == 3 then --bounty hunters
        _tta = _tta + 15 --These guys have normal torpedoes so make the big torps take longer to activate.
    end

    if mission.data.custom.enemyWavesSpawned >= 8 then --Make them more dangerous on the last wave.
        _tta = math.floor(_tta / 2)
        rangeFactor = rangeFactor * 2
    end

    local torpSlammerTable = {
        _TimeToActive = _tta,
        _ROF = 8,
        _UpAdjust = false,
        _DamageFactor = _DmgFactor,
        _DurabilityFactor = 8,
        _ForwardAdjustFactor = 2,
        _PreferWarheadType = _PrefType,
        _TargetPriority = 2, --Target tag.
        _TargetTag = targetTag,
        _RangeFactor = rangeFactor
    }

    return torpSlammerTable
end

function expandOperations_onWingFinished(generated, wingScriptValue, targetPriorityValue, targetTagValue, allowNoneType)
    if mission.data.custom.threatType == 1 then --faction
        for _, enemy in pairs(generated) do
            enemy:removeScript("ai/patrol.lua") --Causes some annoying interactions with priorityAttacker.

            local enemyAI = ShipAI(enemy)
            enemyAI:setAggressive()
        end
    end

    if mission.data.custom.threatType == 3 then --bounty hunters
        local _player = Player()

        for _, enemy in pairs(generated) do
            local enemyAI = ShipAI(enemy)
            enemyAI:setAggressive()
            enemyAI:registerEnemyFaction(_player.index)
            enemyAI:registerEnemyFaction(mission.data.custom.friendlyFaction)
            if _player.allianceIndex then
                enemyAI:registerEnemyFaction(_player.allianceIndex)
            end

            enemy:setValue("is_persecutor", true)
            if string.match(enemy.title, "Persecutor") then
                enemy.title = "Bounty Hunter"
            end

            --The hunters need a little bit of extra help, since they don't have as good danger level scaling as faction / pirates.
            local hunterDangerBonus = 1 + (mission.data.custom.dangerLevel * 0.01) + random():getFloat(-0.01, 0.01)
            ESCCUtil.multiplyOverallDurability(enemy, hunterDangerBonus)

            enemy.damageMultiplier = (enemy.damageMultiplier or 1) * hunterDangerBonus
        end

        --TODO: Send chat messages.
    end

    for _, enemy in pairs(generated) do
        enemy:setValue(wingScriptValue, true)

        expandOperations_setNoLootIfApplicable(enemy)

        local priorityAttackerValues = {
            _TargetPriority = targetPriorityValue,
            _TargetTag = targetTagValue
        }

        if allowNoneType then
            priorityAttackerValues._AllowNoneType = true
        end

        if mission.data.custom.threatType == 3 then --Bounty hunters.
            priorityAttackerValues._UseShipAI = true
        end

        enemy:addScript("ai/priorityattacker.lua", priorityAttackerValues )
    end

    Placer.resolveIntersections(generated)

    SpawnUtility.addEnemyBuffs(generated)
end

function expandOperations_setNoLootIfApplicable(enemy)
    local enemiesSpawned = mission.data.custom.enemiesSpawned + 1

    local noLootFactor = 2
    if mission.data.custom.enemiesSpawned >= 20 then
        noLootFactor = mission.data.custom.noLootModulusFactor
    end
    if enemiesSpawned % noLootFactor ~= 0 then
        enemy:setDropsLoot(false)
    end

    mission.data.custom.enemiesSpawned = enemiesSpawned
end

function expandOperations_getHeadhunterFaction()
    local x, y = Sector():getCoordinates()

    return EventUT:getHeadhunterFaction(x, y)
end

function expandOperations_doMissionEndCleanup()
    local methodName = "Do Mission End Cleanup"
    mission.Log(methodName, "Выполняется...")

    if mission.data.custom.threatType == 1 then --enemy faction
        local _MissionDoer = Player().craftFaction or Player()
        local _Faction = Faction(mission.data.custom.enemyFaction)
        local _FriendlyFaction = Faction(mission.data.custom.friendlyFaction)
        local _Galaxy = Galaxy()

        _Galaxy:setFactionRelations(_Faction, _FriendlyFaction, mission.data.custom.enemyRelationLevel2Giver)
        _Galaxy:setFactionRelationStatus(_Faction, _FriendlyFaction, mission.data.custom.enemyRelationStatus2Giver)
        _Galaxy:setFactionRelations(_Faction, _MissionDoer, mission.data.custom.enemyRelationLevel - 12500)
        _Galaxy:setFactionRelationStatus(_Faction, _MissionDoer, mission.data.custom.enemyRelationStatus)
    end
end

function expandOperations_missionShipsDepart()
    local methodName = "Mission Ships Depart"
    
    mission.Log(methodName, "Все ресурсы миссии покидают сектор.")

    local scriptTbl = {
        "expandoperations_alpha_wing",
        "expandoperations_beta_wing",
        "expandoperations_gamma_wing",
        mission.data.custom.constructionShipScriptValue
    }

    local _sector = Sector()
    local _random = random()

    for _, script in pairs(scriptTbl) do
        local scriptEntities = { _sector:getEntitiesByScriptValue(script) }

        for _, entity in pairs(scriptEntities) do
            entity:addScriptOnce("entity/utility/delayeddelete.lua", _random:getFloat(3, 6))
        end
    end

    local stationFrame = expandOperations_getEntityByValue(_sector, mission.data.custom.stationFrameScriptValue)

    if stationFrame and valid(stationFrame) then
        MissionUT.deleteOnPlayersLeft(stationFrame)
    end
end

function expandOperations_finishAndReward()
    local methodName = "Finish and Reward"
    mission.Log(methodName, "Выполняется условие победы.")

    Sector():setValue("smuggler_development_index", mission.data.custom.developmentIndex)

    --3 possible bonuses
    local hasBonus = false
    local hardWaveBonusFactor = 1 --one for hard waves (player will almost always get this one) (anywhere from 0 to ~9%)
    local constructionShipBonusFactor = 1 --one for keeping the construction ship above 50% hp (+25%)
    local stationFrameBonusFactor = 1 --one for keeping the station frame above 75% hp (+10%)

    if mission.data.custom.bonusFactorFromHardWaves > 0 then
        hasBonus = true
        hardWaveBonusFactor = hardWaveBonusFactor + mission.data.custom.bonusFactorFromHardWaves
        mission.Log(methodName, "Бонус > 0, присуждается " .. tostring(hardWaveBonusFactor) .. " множитель бонуса кредитов.")
    end

    if mission.data.custom.stationFrameHealthBonus then
        hasBonus = true
        stationFrameBonusFactor = 1.1
        mission.Log(methodName, "Получен бонус здоровья станции (x1.1)")
    end

    if mission.data.custom.constructionShipHealthBonus then
        hasBonus = true
        constructionShipBonusFactor = 1.25
        mission.Log(methodName, "Получен бонус здоровья строительного корабля (x1.25)")
    end

    if hasBonus then
        mission.data.reward.credits = mission.data.reward.credits * hardWaveBonusFactor * stationFrameBonusFactor * constructionShipBonusFactor
        mission.data.reward.paymentMessage = mission.data.reward.paymentMessage .. " Это включает в себя бонус за отличную работу."
    end

    reward()
    accomplish()
end

function expandOperations_failAndPunish()
    local methodName = "Fail and Punish"
    mission.Log(methodName, "Выполняется условие проигрыша.")

    punish()
    fail()
end

--endregion

--region #CLIENT CALLS

function expandOperations_drawConstructionLaser()
    local _sector = Sector()

    local constructionShip = expandOperations_getEntityByValue(_sector, mission.data.custom.constructionShipScriptValue)
    local stationFrame = expandOperations_getEntityByValue(_sector, mission.data.custom.stationFrameScriptValue)

    if constructionShip and valid(constructionShip) and stationFrame and valid(stationFrame) then
        local _random = random()
        local dir = _random:getDirection()

        local magnitudeMultiplier = math.max((mission.data.custom.scaleStationFrameIndex or 1), 1) --Needs to be at least 1.

        local minMagnitude = 10 * magnitudeMultiplier
        local maxMagnitude = 25 * magnitudeMultiplier

        local magnitude = _random:getInt(minMagnitude, maxMagnitude)

        local lsr = _sector:createLaser(constructionShip.translationf, stationFrame.translationf + (dir * magnitude), ColorRGB(0, 0.1, 1.0), 1)
        lsr.collision = false
        lsr.maxAliveTime = 0.025
    end
end

function expandOperations_playHealingAnimation()
    local _sector = Sector()

    local constructionShip = expandOperations_getEntityByValue(_sector, mission.data.custom.constructionShipScriptValue)
    local stationFrame = expandOperations_getEntityByValue(_sector, mission.data.custom.stationFrameScriptValue)

    if constructionShip and valid(constructionShip) and stationFrame and valid(stationFrame) then
        local stationFrameHull = stationFrame.durability
        local stationFrameMaxHull = stationFrame.maxDurability

        if stationFrameHull < stationFrameMaxHull then
            local cShipPos = constructionShip.translationf
            local sFramePos = stationFrame.translationf
            local beamColor = ColorRGB(0.0, 0.8, 0.5)

            local repairLaser = _sector:createLaser(cShipPos, sFramePos, beamColor, 16)
            repairLaser.maxAliveTime = 1.5
            repairLaser.collision = false

            local direction = random():getDirection()
            _sector:createHyperspaceJumpAnimation(stationFrame, direction, ColorRGB(0.0, 1.0, 0.6), 0.2)
        end
    end
end

--endregion

--region #SERVER / CLIENT UTILITY CALLS

function expandOperations_getEntityByValue(_sector, scriptValue)
    _sector = _sector or Sector()

    local scriptTbl = { _sector:getEntitiesByScriptValue(scriptValue) }
    return scriptTbl[1]
end

--endregion

--region #MAKEBULLETINCALLS

function expandOperations_formatDescription(station, threatType)
    --Basically every mission has been on the peaceful <=> aggressive continuum. Let's do opportunistic <=> honorable this time.
    local stationFaction = Faction(station.factionIndex)
    local opportunistic = stationFaction:getTrait("opportunistic")

    local descriptionType = 1 --neutral
    if opportunistic > 0.5 then
        descriptionType = 2 --opportunistic
    elseif opportunistic < -0.5 then
        descriptionType = 3 --honorable
    end

    local descriptionTable = {
        "Мы хотели бы расширить свою деятельность в этом секторе. С этой целью мы отправим строительный корабль для установки новой станции. Мы хотели бы, чтобы вы защитили его во время работы - если вы сможете его защитить, мы компенсируем ваши усилия. Дайте нам знать, если вы заинтересованы.", --neutral
        "Кажется, что целую вечность назад мы начинали со контрабандистского форпоста и мечты. Со временем мы утвердились в этом секторе - и теперь у нас есть возможность стать больше. Было бы глупо не воспользоваться этим. Мы собираемся построить еще одну станцию в этом секторе. Защитите наш строительный корабль, пока он устанавливает нашу новую станцию, и мы вознаградим вас за ваши усилия.", --opportunistic
        "Мы давно заботимся о нуждах обездоленных людей в этом секторе, и мы хотели бы расширить свои возможности для этого. Для этого нам понадобится больше станций, и мы хотели бы, чтобы вы помогли нам ее установить. Мы собираемся отправить строительный корабль - пожалуйста, защитите его, пока он устанавливает новую станцию. Вы, конечно, получите оплату за свою работу." --honorable
    }

    local threatTable = {
        "В последние несколько недель мы были в ссоре с ${_FACTIONNAME} по этому поводу. Если мы продолжим это, они попытаются это остановить. Будьте готовы к бою. Эти корабли фракции опасны!", --factions
        "Местные пираты, вероятно, не оценят то, что мы это делаем, но когда кто-то позволял пиратам остановить их? Тем не менее, они определенно попытаются напасть на нас, если мы это сделаем.", --pirates
        "Близлежащие фракции настаивают на том, что у нас нет «надлежащих разрешений» на это, но, похоже, они не желают противостоять нам сами. Вероятно, они наймут охотников за головами, чтобы те сделали за них грязную работу." --headhunters
    }

    return descriptionTable[descriptionType] .. "\n\n" .. threatTable[threatType]
end

function expandOperations_getThreatType(rand, station)
    local methodName = "Get Threat Type"

    local threatType = rand:getInt(1, 3) --1 = faction / 2 = pirates / 3 = bounty hunters

    local giverFaction = station.factionIndex
    local enemyFaction = nil
    local enemyFactionName = nil
    if threatType == 1 then
        local factionNeighbors = MissionUT.getNeighboringFactions(giverFaction, 125)
        shuffle(random(), factionNeighbors)

        if #factionNeighbors > 0 then
            enemyFaction = factionNeighbors[1].index
            enemyFactionName = factionNeighbors[1].name
            mission.Log(methodName, "Вражеская фракция - " .. tostring(enemyFactionName))
        else
            threatType = rand:getInt(1, 2) + 1 --pirates or bounty hunters.
        end
        if giverFaction == enemyFaction then
            threatType = rand:getInt(1, 2) + 1 --pirates or bounty hunters.
        end
    end

    mission.Log(methodName, "Финальный тип угрозы - " .. mission.data.custom.threatLogTbl[threatType])

    return enemyFaction, enemyFactionName, threatType
end
mission.makeBulletin = function(station)
    local methodName = "Make Bulletin"

    local _random = random()
    local _sector = Sector()

    local target = {}
    local x, y = _sector:getCoordinates()
    local insideBarrier = MissionUT.checkSectorInsideBarrier(x, y)
    target.x, target.y = x, y --This mission happens in this sector, so we don't need to account for the possibility of not finding a target.

    if not _sector:getValue("smuggler_development_index") then
        _sector:setValue("smuggler_development_index", 1)
    end
    local smugglerDevelopmentIndex = _sector:getValue("smuggler_development_index") + 1
    if smugglerDevelopmentIndex > 5 then
        print("Smuggler development index too high - terminating and returning.")
        terminate()
        return
    end

    local dangerLevel = _random:getInt(1, 10)
    local enemyFaction, enemyFactionName, threatType = expandOperations_getThreatType(_random, station)

    local missionDescription = expandOperations_formatDescription(station, threatType)

    local missionDifficulty = "Средний"
    if dangerLevel >= 5 then
        missionDifficulty = "Сложный"
    end
    if dangerLevel == 10 then
        missionDifficulty = "Экстремальный"
    end

    mission.Log(methodName, "Danger level is " .. tostring(dangerLevel) .. " / " .. missionDifficulty)

    local baseReward = 50000
    local baseRep = 8000
    if dangerLevel >= 5 then
        baseReward = baseReward + 15000
    end
    if dangerLevel == 10 then
        baseReward = baseReward + 35000
        baseRep = baseRep + 2000
    end

    if threatType == 1 then --the faction version tends to be more difficult, even at danger 1.
        baseReward = baseReward * 1.5
    end

    if insideBarrier then
        baseReward = baseReward * 2
    end

    reward = baseReward * Balancing.GetSectorRewardFactor(_sector:getCoordinates()) * (1 + (smugglerDevelopmentIndex * 0.05))
    reputation = baseRep * 2

    local bulletin = {
        --data for the bulletin board
        brief = mission.data.brief,
        title = mission.data.title,
        description = missionDescription,
        difficulty = missionDifficulty,
        reward = "¢${reward}",
        script = "missions/expandoperations.lua",
        formatArguments = { _X = target.x , _Y = target.y, reward = createMonetaryString(reward), _FACTIONNAME = enemyFactionName },
        msg = "Thanks for your help. We'll be sending out the construction ship soon.",
        giverTitle = station.title,
        giverTitleArgs = station:getTitleArguments(),
        onAccept = [[
            local self, player = ...
            player:sendChatMessage(Entity(self.arguments[1].giver), 0, self.msg, self.formatArguments._X, self.formatArguments._Y)
        ]],

        --data that's important for our mission
        arguments = {{
            giver = station.index,
            location = target,
            reward = { credits = reward, relations = reputation, paymentMessage = "Earned %1% for helping the smugglers expand their base." },
            punishment = { relations = 8000 },
            dangerLevel = dangerLevel,
            inBarrier = insideBarrier,
            initialDesc = missionDescription,
            developmentIndex = smugglerDevelopmentIndex,
            threatType = threatType,
            enemyFaction = enemyFaction
        }},
    }

    return bulletin
end

--endregion
mission.makeBulletin = function(station)
    local methodName = "Создать бюллетень"

    local _random = random()
    local _sector = Sector()

    local target = {}
    local x, y = _sector:getCoordinates()
    local insideBarrier = MissionUT.checkSectorInsideBarrier(x, y)
    target.x, target.y = x, y --This mission happens in this sector, so we don't need to account for the possibility of not finding a target.

    if not _sector:getValue("smuggler_development_index") then
        _sector:setValue("smuggler_development_index", 1)
    end
    local smugglerDevelopmentIndex = _sector:getValue("smuggler_development_index") + 1
    if smugglerDevelopmentIndex > 5 then
        print("Smuggler development index too high - terminating and returning.")
        terminate()
        return
    end

    local dangerLevel = _random:getInt(1, 10)
    local enemyFaction, enemyFactionName, threatType = expandOperations_getThreatType(_random, station)

    local missionDescription = expandOperations_formatDescription(station, threatType)

    local missionDifficulty = "Средний"
    if dangerLevel >= 5 then
        missionDifficulty = "Сложный"
    end
    if dangerLevel == 10 then
        missionDifficulty = "Экстремальный"
    end

    mission.Log(methodName, "Danger level is " .. tostring(dangerLevel) .. " / " .. missionDifficulty)

    local baseReward = 50000
    local baseRep = 8000
    if dangerLevel >= 5 then
        baseReward = baseReward + 15000
    end
    if dangerLevel == 10 then
        baseReward = baseReward + 35000
        baseRep = baseRep + 2000
    end

    if threatType == 1 then --the faction version tends to be more difficult, even at danger 1.
        baseReward = baseReward * 1.5
    end

    if insideBarrier then
        baseReward = baseReward * 2
    end

    reward = baseReward * Balancing.GetSectorRewardFactor(_sector:getCoordinates()) * (1 + (smugglerDevelopmentIndex * 0.05))
    reputation = baseRep * 2

    local bulletin = {
        --data for the bulletin board
        brief = mission.data.brief,
        title = mission.data.title,
        description = missionDescription,
        difficulty = missionDifficulty,
        reward = "¢${reward}",
        script = "missions/expandoperations.lua",
        formatArguments = { _X = target.x , _Y = target.y, reward = createMonetaryString(reward), _FACTIONNAME = enemyFactionName },
        msg = "Спасибо за вашу помощь. Мы скоро отправим строительный корабль.",
        giverTitle = station.title,
        giverTitleArgs = station:getTitleArguments(),
        onAccept = [[
            local self, player = ...
            player:sendChatMessage(Entity(self.arguments[1].giver), 0, self.msg, self.formatArguments._X, self.formatArguments._Y)
        ]],

        --data that's important for our mission
        arguments = {{
            giver = station.index,
            location = target,
            reward = { credits = reward, relations = reputation, paymentMessage = "Earned %1% for helping the smugglers expand their base." },
            punishment = { relations = 8000 },
            dangerLevel = dangerLevel,
            inBarrier = insideBarrier,
            initialDesc = missionDescription,
            developmentIndex = smugglerDevelopmentIndex,
            threatType = threatType,
            enemyFaction = enemyFaction
        }},
    }

    return bulletin
end

--endregion
