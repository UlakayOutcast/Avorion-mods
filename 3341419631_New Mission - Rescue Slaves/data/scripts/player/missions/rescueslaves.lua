--[[
    Rescue Slaves
    NOTES:
        - Different take on the Free Slaves mission from Boxelware.
]]
package.path = package.path .. ";data/scripts/lib/?.lua"
package.path = package.path .. ";data/scripts/?.lua"

include("callable")
include("randomext")
include ("goods")
include("structuredmission")
include("stringutility")

ESCCUtil = include("esccutil")

local SectorSpecifics = include ("sectorspecifics")
local AsyncPirateGenerator = include ("asyncpirategenerator")
local AsyncFactionShipGenerator = include("asyncshipgenerator")
local Placer = include ("placer")
local ShipUtility = include("shiputility")
local SpawnUtility = include ("spawnutility")
local EventUT = include("eventutility")
mission._Debug = 0
mission._Name = "Спасение рабов"

--region #INIT

--Стандартные данные миссии.
mission.data.autoTrackMission = true

mission.data.brief = mission._Name
mission.data.title = mission._Name
mission.data.autoTrackMission = true
mission.data.description = {
    { text = "Вы получили следующий запрос от ${giverTitle} из сектора ${sectorName}:" }, --Заполнитель
    { text = "..." }, --Заполнитель
    { text = "Отправляйтесь в сектор (${x}:${y})", bulletPoint = true, fulfilled = false },
    { text = "Найдите рабов на местных грузовых кораблях. Будьте осторожны с тем, какие корабли вы активно сканируете!", bulletPoint = true, fulfilled = false, visible = false },
    { text = "Верните рабов ${giverTitle} ${name} в сектор (${x}:${y})", bulletPoint = true, fulfilled = false, visible = false }
}
mission.data.timeLimit = 60 * 60 --У игрока есть 60 минут.
mission.data.timeLimitInDescription = true --Показать игроку, сколько времени осталось.

mission.data.accomplishMessage = "Огромное спасибо за возвращение наших семей. Мы очень, очень благодарны за вашу помощь."
mission.data.failMessage = "Мы потеряли след наших семей и друзей. Кто знает, где они сейчас..."

--Константы. Нет необходимости иметь это в init
mission.data.custom.amountSlaves = 10
mission.data.custom.spawnedDangerTenThreat = false
mission.data.custom.controlScriptPath = "player/missions/rescueslaves/rescueslavescontrol.lua"

local RescueSlaves_init = initialize
function initialize(_Data_in, bulletin)
    local methodName = "initialize"
    mission.Log(methodName, "Beginning...")

    if onServer() and not _restoring then
        local _X, _Y = _Data_in.location.x, _Data_in.location.y --получить рабов отсюда.

        local _sector = Sector()
        local _Giver = Entity(_Data_in.giver)

        mission.Log(methodName, "Sector name is " .. tostring(_sector.name) .. " Giver title is " .. tostring(_Giver.translatedTitle))

        local _rX, _rY = _sector:getCoordinates() --вернуться сюда с рабами.

        --[[=====================================================
            НАСТРОЙКА ПОЛЬЗОВАТЕЛЬСКИХ ДАННЫХ МИССИИ:
        =========================================================]]
        mission.data.custom.dangerLevel = _Data_in.dangerLevel
        mission.data.custom.missionFaction = _Giver.factionIndex
        mission.data.custom.transportNumber = 1
        mission.data.custom.firstTransport = random():getInt(2, 3)
        mission.data.custom.secondTransport = random():getInt(4, 5)
        mission.data.custom.thirdTransport = random():getInt(6, 8)
        mission.data.custom.fourthTransport = random():getInt(9, 11)
        mission.data.custom.fifthTransport = random():getInt(12, 14)
        mission.data.custom.sixthTransport = random():getInt(15, 18)
        mission.data.custom.seventhTransport = random():getInt(19, 22)
        mission.data.custom.eigthTransport = random():getInt(23, 26)
        mission.data.custom.ninthTransport = random():getInt(27, 30)
        mission.data.custom.spawnedDangerTenThreat = false
        mission.data.custom.spawnThreatCycle = 0
        mission.data.custom.shownPhase1MissionUpdate = false

        --[[=====================================================
            НАСТРОЙКА ОПИСАНИЯ МИССИИ:
        =========================================================]]
        mission.data.description[1].arguments = { sectorName = _sector.name, giverTitle = _Giver.translatedTitle }
        mission.data.description[2].text = _Data_in.initialDesc
        mission.data.description[2].arguments = { x = _X, y = _Y }
        mission.data.description[3].arguments = { x = _X, y = _Y }
        mission.data.description[5].arguments = { giverTitle = _Giver.translatedTitle, name = _Giver.name, x = _rX, y = _rY }
    end

    --Запустить ванильную инициализацию. Управляет _restoring самостоятельно.
    RescueSlaves_init(_Data_in, bulletin)
end

--endregion

--region #PHASE CALLS

mission.globalPhase.timers = {}
mission.globalPhase.onAbandon = function()
    rescueSlaves_failAndPunish() --Мы не хотим очищать сектор, так как это обычный сгенерированный сектор в сетке, но игрок не может отказаться от этой миссии бесплатно.
end

mission.globalPhase.updateServer = function(_TimeStep)
    --Получить текущий корабль игрока и снять статус украденного со всех освобожденных рабов на нем.
    local _Player = Player()

    if _Player.craft then
        local _PlayerShip = Entity(_Player.craft.id)
        for _Good, _Amount in pairs(_PlayerShip:getCargos()) do
            if (string.find(_Good.name, "Rescued") or string.find(_Good.name, "Rescued")) and _Good.stolen then
                local _Unstolen = copy(_Good)
                _Unstolen.stolen = false
                _PlayerShip:removeCargo(_Good, _Amount)
                _PlayerShip:addCargo(_Unstolen, _Amount)
            end
        end

        local _craftFaction = _Player.craftFaction
        if _craftFaction then
            --Если фракция объявляет войну игроку из-за того, что игрок принимает плохие решения, просто провалите миссию.
            local relation = _craftFaction:getRelation(mission.data.custom.missionFaction)
            if relation.status == RelationStatus.War then
                rescueSlaves_failAndPunish()
             end
            if relation.level <= -80000 then 
                rescueSlaves_failAndPunish()
            end
        end
    end
end

mission.phases[1] = {}
mission.phases[1].timers = {}
mission.phases[1].showUpdateOnEnd = true
mission.phases[1].onBegin = function()
    local methodName = "Phase 1 On Begin"
    mission.Log(methodName, "Setting stationId.")
    
    --Нельзя настроить это до вызова init, и это нужно, потому что иначе вы не сможете выйти из игры в середине миссии и ожидать, что диалог будет работать правильно после возвращения.
    mission.data.custom.stationId = mission.data.giver.id.string
end

local onPhase1DialogEnd = makeDialogServerCallback("onPhase1DialogEnd", 1, function()
    --Обнулить это, чтобы игрок мог увидеть это снова.
    --Мне все равно, если это станет неприятным. Игрокам требуется неприятное количество помощи.
    Player():setValue("_rescueslaves_tutorial_shown", nil) 
end)

mission.phases[1].onTargetLocationEntered = function(x, y)
    if not mission.data.custom.shownPhase1MissionUpdate then
        showMissionUpdated(mission._Name)
        mission.data.custom.shownPhase1MissionUpdate = true
    end

    mission.data.description[3].fulfilled = true
    mission.data.description[4].visible = true
end

mission.phases[1].updateTargetLocationServer = function(_TimeStep)
    local methodName = "Phase 1 Update Target Location Server"

    local _Player = Player()
    local _sector = Sector()

    if _Player.craft then
        local _PlayerShip = Entity(_Player.craft.id)
        local _MoveToNextPhase = false
    
        --Проверить, можем ли мы перейти к следующей фазе.
        local _RescuedSlaveAmount = _PlayerShip:getCargoAmount(rescueSlaves_RescuedSlavesGood())
        --mission.Log(methodName, "Player has " .. tostring(_RescuedSlaveAmount) .. " freed slaves.")
        if _RescuedSlaveAmount >= mission.data.custom.amountSlaves then
            _MoveToNextPhase = true
        end
    
        if _MoveToNextPhase then
            nextPhase()
        end
    end

    --Получить все сущности типа корабль в секторе. Если "is_civil" истинно, добавить управляющий скрипт.
    local _CivilShips = { _sector:getEntitiesByScriptValue("is_civil")}
    for _, _Ship in pairs(_CivilShips) do
        if _Ship.type == EntityType.Ship and not _Ship.playerOrAllianceOwned then
            _Ship:setValue("rescueslaves_mission_player", Player().index)
            _Ship:addScriptOnce(mission.data.custom.controlScriptPath)
        end
    end

    --Проверить, нужно ли нам выделить каких-либо рабов.
    invokeClientFunction(Player(), "rescueSlaves_highlightRescuedSlaves")
end

mission.phases[1].onStartDialog = function(entityId)
    local methodName = "Phase 1 On Start Dialog"
    mission.Log(methodName, "Beginning...")

    --Как куча гражданских это знают? Я, блин, не знаю. Я вечно расстроен тем, сколько помощи требуется этому сообществу.
    --Я прекрасно знаю, что игра не объясняет всю эту штуку со сканированием грузового отсека, но люди действительно должны быть в состоянии разобраться в этом самостоятельно. Это не так уж и сложно.
    if entityId == Uuid(mission.data.custom.stationId) then

        local td0 = { text = "Подлетите близко к кораблю, чтобы отсканировать содержимое его грузовых отсеков. Нормальная дальность сканирования составляет полкилометра, но вы можете установить усилитель сканера, чтобы увеличить ее." }

        local td1 = { text = "Приветствуйте корабли, перевозящие нелегальных рабов, и сканируйте их. Неизвестно, как отреагируют пиратские капитаны - вам придется разбираться с этим самостоятельно." }

        local td2 = { text = "Ну, мы слышали слухи..." }

        local td3 = { text = "Если пираты настолько сильны, как мы слышали, они могут захватить некоторые корабли защитников. Если вы приблизитесь и отсканируете их, это должно раскрыть их истинную принадлежность." }

        local td4 = { text = "Мы также слышали, что они используют некоторые новые тактики для борьбы с капитанами в пространстве фракций. Конечно, они всегда могут прибегнуть к своим обычным методам и нанять охотников за головами. Будьте начеку." }

        local td5 = { text = "Еще раз спасибо и удачи."}

        td0.followUp = td1
        td1.answers = {
            { answer = "Понял.", followUp = td5 },
            { answer = "Это все?", followUp = td2 }
        }
        td2.answers = {
            { answer = "Какие слухи?", followUp = td3 }
        }
        td3.followUp = td4
        td4.followUp = td5
        td5.onEnd = onPhase1DialogEnd

        addDialogInteraction("Как я могу найти ваших людей?", td0)
    end
end

--region #PHASE 1 TIMERS

if onServer() then

--Каждые 5 минут, возможно, порождать угрозу. Угрозы выбираются случайным образом между ударом подпространственной торпеды, волной охотников за головами и захваченными кораблями фракций.
mission.phases[1].timers[1] = {
    time = 300, 
    callback = function() 
        local methodName = "Phase 1 Timer 1 Callback"
        mission.Log(methodName, "Running threat timer.")
        if atTargetLocation() then
            local threatChance = 1.0 - (0.25 - (mission.data.custom.dangerLevel * 0.015)) --25% шанс не порождать угрозу. Падает до 10% при опасности 10.

            if random():test(threatChance) or mission.data.custom.spawnThreatCycle == 2 then
                mission.Log(methodName, tostring(threatChance) .. " test passed - spawning threat.")
                rescueSlaves_spawnThreat()
                mission.data.custom.spawnThreatCycle = 0
            else
                mission.Log(methodName, "Threat test not passed. Player is safe. For now...")
                mission.data.custom.spawnThreatCycle = mission.data.custom.spawnThreatCycle + 1
            end
        end
    end,
    repeating = true
}

--Порождает одноразовую угрозу через 4 минуты. 10% шанс порождать каждые 4 минуты после этого. Применяется только при опасности 10.
mission.phases[1].timers[2] = {
    time = 240,
    callback = function()
        local methodName = "Phase 1 Timer 2 Callback"
        mission.Log(methodName, "Running danger 10 threat timer.")
        if mission.data.custom.dangerLevel == 10 and atTargetLocation() then

            local spawnThreat = false
            if not mission.data.custom.spawnedDangerTenThreat then
                spawnThreat = true
            else
                if random():test(0.1) then
                    spawnThreat = true
                end
            end

            if spawnThreat then
                mission.Log(methodName, "Danger 10 - spawning threat.")
                rescueSlaves_spawnThreat()
                mission.data.custom.spawnedDangerTenThreat = true
            end
        end
    end,
    repeating = true
}

mission.phases[1].timers[3] = {
    time = 360,
    callback = function()
        if atTargetLocation() then
            rescueSlaves_spawnLocalTransport()
        end
    end,
    repeating = true
}

mission.phases[1].timers[4] = {
    time = 540,
    callback = function()
        --Порождать дополнительные транспорты при уровне опасности 10 - игроку нужно быстрее проверять наличие рабов.
        if mission.data.custom.dangerLevel == 10 and atTargetLocation() then
            rescueSlaves_spawnLocalTransport()
        end
    end,
    repeating = true
}

end

--Ух ты. Таймер на клиенте. Нужно выделить первый гражданский корабль, который запрыгивает, и показать подсказку.
mission.phases[1].timers[5] = {
    time = 10,
    callback = function()
        if onClient() and atTargetLocation() then
            if not Player():getValue("_rescueslaves_tutorial_shown") then
                local _CivilShips = { Sector():getEntitiesByScriptValue("is_civil") }

                if #_CivilShips > 0 then
                    Hud():displayHint("Вы можете подлететь близко к кораблю, чтобы определить, какой груз он перевозит, прежде чем активно сканировать его.\nЭтот диапазон пассивного сканирования можно увеличить с помощью улучшения Scanner Booster.", _CivilShips[1])
                    invokeServerFunction("rescueSlaves_playerDoneTutorial")
                end
            end
        end
    end,
    repeating = true
}

--endregion

--На этапе 2 мы возвращаем их на исходную станцию.
mission.phases[2] = {}
mission.phases[2].onBegin = function()
    mission.data.description[4].fulfilled = true
    mission.data.description[5].visible = true
    
    --рабы свободны - таймер не нужен.
    mission.data.timeLimitInDescription = false
    mission.data.timeLimit = nil

    --giver инициализируется к этому моменту, поэтому мы можем использовать его здесь. Нельзя использовать его в функции init, потому что наша запускается раньше, чем у boxel
    mission.data.location = mission.data.giver.coordinates
end

mission.phases[2].onBeginServer = function()
    --Удалить управляющий скрипт со всех присутствующих кораблей - он нам больше не нужен.
    local _Ships = {Sector():getEntitiesByScriptValue("rescueslaves_mission_player")}
    for _, _Ship in pairs(_Ships) do
        _Ship:removeScript(mission.data.custom.controlScriptPath)
    end
end

local rescueSlaves_onBroughtHomeEnd = makeDialogServerCallback("rescueSlaves_onBroughtHomeEnd", 2, function()
    -- мы счастливы и забираем их
    local ship = Player().craft
    -- если игрок не возвращает как минимум 10 рабов (каким-то образом), награда должна быть скорректирована в соответствии с фактическим количеством освобожденных рабов
    -- в любом случае, мы удаляем всех освобожденных рабов из грузового отсека, даже если игрок получает больше 10.
    local slaveAmount = ship:getCargoAmount(rescueSlaves_RescuedSlavesGood())
    local repNumerator = slaveAmount
    if repNumerator > mission.data.custom.amountSlaves then
        repNumerator = mission.data.custom.amountSlaves
    end

    mission.data.reward.relations = mission.data.reward.relations * (repNumerator / mission.data.custom.amountSlaves)
    ship:removeCargo(rescueSlaves_RescuedSlavesGood(), slaveAmount)
    rescueSlaves_finishAndReward()
end)

mission.phases[2].onTargetLocationArrivalConfirmed = function()
    -- сначала проверьте, действительно ли у игрока есть рабы
    if onServer() then
        local player = Player()
        local ship = player.craft
        if not ship then return end

        local playerHas = ship:getCargoAmount(rescueSlaves_RescuedSlavesGood())
        local station = Entity(mission.data.giver.id)
        if station and playerHas > 0 then
            invokeClientFunction(Player(), "rescueSlaves_showBroughtHomeDialog", station.id, playerHas, false)
        end
    end
end

mission.phases[2].onRestore = function()
    mission.phases[2].onTargetLocationArrivalConfirmed()
end

--endregion

--region #SERVER CALLS

function rescueSlaves_RescuedSlavesGood()
    local good = TradingGood("Спасенный раб"%_T, plural_t("Спасенный раб", "Спасенные рабы", 1), "Теперь освобожденная форма жизни, которая была вынуждена работать почти без еды."%_T, "data/textures/icons/slave.png", 0, 1)
    good.tags = {mission_relevant = true}
    return good
end

--Породить угрозу
function rescueSlaves_spawnThreat()
    local _xFuncs = {
        { _func = function() rescueSlaves_spawnTorpedoStrike() end },
        { _func = function() rescueSlaves_spawnBountyHunterAttack() end },
        { _func = function() rescueSlaves_spawnHijackedFactionShip() end }
    }
    shuffle(random(), _xFuncs)
    _xFuncs[1]._func()
end

--Удар торпедой
function rescueSlaves_spawnTorpedoStrike()
    local methodName = "Spawning Torpedo Strike"

    local waveTable = ESCCUtil.getStandardWave(mission.data.custom.dangerLevel, 3, "High", false) --Они находятся там всего 8-9 секунд. Сделайте их более крупными кораблями.

    local generator = AsyncPirateGenerator(nil, rescueSlaves_onTorpStrikePirateSpawned)

    generator:startBatch()

    for _, p in pairs(waveTable) do
        mission.Log(methodName, "Spawning torp strike pirate " .. tostring(_) .. " of 3")
        generator:createScaledPirateByName(p, generator.getGenericPosition())
    end

    generator:endBatch()
end

function rescueSlaves_onTorpStrikePirateSpawned(_Generated)
    local _dmgFactor = 2
    local _duraFactor = 2
    if mission.data.custom.dangerLevel >= 6 then
        _dmgFactor = 4
    end
    if mission.data.custom.dangerLevel == 10 then
        _dmgFactor = 8
        _duraFactor = 4
    end

    for _, _Ship in pairs(_Generated) do
        local _Dura = Durability(_Ship)
        if _Dura then
            _Dura.maxDurabilityFactor = (_Dura.maxDurabilityFactor or 1) * 2
        end

        local _TorpSlamValues = {
            _ROF = 2,
            _DurabilityFactor = _duraFactor,
            _TimeToActive = 0,
            _DamageFactor = _dmgFactor,
            _UseEntityDamageMult = true,
            _TargetPriority = 5,
            _pindex = Player().index
        }

        _Ship:addScriptOnce("torpedoslammer.lua", _TorpSlamValues)
        _Ship:addScriptOnce("utility/delayeddelete.lua", random():getFloat(8, 9)) --Должно дать достаточно времени, чтобы выстрелить 3 раза и уйти.
        ESCCUtil.setBombardier(_Ship)
    end

    Placer.resolveIntersections(_Generated)

    SpawnUtility.addEnemyBuffs(_Generated)
end
--Охотники за головами
function rescueSlaves_spawnBountyHunterAttack()
    local methodName = "Spawn Bounty Hunter Attack"

    mission.Log(methodName, "Вызов охотников за головами")

    local _Rgen = ESCCUtil.getRand()
    --Охотники за головами.
    local _HeadHunterFaction = rescueSlaves_getHeadHunterFaction()

    local _HunterGenerator = AsyncFactionShipGenerator(nil, rescueSlaves_onHuntersFinished)
    _HunterGenerator:startBatch()
    
    local x, y = Sector():getCoordinates()
    local _Volume = Balancing_GetSectorShipVolume(x, y)
    local _HunterPositions = _HunterGenerator:getStandardPositions(250, 4)
    local _RandomExtraVolume = _Rgen:getInt(1, 3) - 1

    _HunterGenerator:createPersecutorShip(_HeadHunterFaction, _HunterPositions[1], _Volume * 4)
    _HunterGenerator:createPersecutorShip(_HeadHunterFaction, _HunterPositions[2], _Volume * 4)
    _HunterGenerator:createPersecutorShip(_HeadHunterFaction, _HunterPositions[3], _Volume * (4 + _RandomExtraVolume))
    if mission.data.custom.dangerLevel == 10 then
        _HunterGenerator:createPersecutorShip(_HeadHunterFaction, _HunterPositions[4], _Volume * (4 + _RandomExtraVolume))
    end

    _HunterGenerator:endBatch()
end

function rescueSlaves_getHeadHunterFaction()
    local _X, _Y = Sector():getCoordinates()

    return EventUT.getHeadhunterFaction(_X, _Y)
end

function rescueSlaves_onHuntersFinished(_Generated)
    local methodName = "On Hunters Finished"
    mission.Log(methodName, "Выполняется.")
    local _Player = Player()

    for _, _Ship in pairs(_Generated) do
        local _AI = ShipAI(_Ship)
        _AI:setAggressive()
        _AI:registerEnemyFaction(_Player.index)
        _AI:registerFriendFaction(mission.data.giver.factionIndex)
        if _Player.allianceIndex then
            _AI:registerEnemyFaction(_Player.allianceIndex)
        end

        local x, y = Sector():getCoordinates()
        local _pLevel = Balancing_GetPirateLevel(x, y)
        local _pFaction = Galaxy():getPirateFaction(_pLevel)

        _Ship:setValue("secret_contractor", _pFaction.index)
        MissionUT.deleteOnPlayersLeft(_Ship)
        _Ship:setValue("is_persecutor", true)

        mission.Log(methodName, "Название корабля " .. _Ship.title)

        if string.match(_Ship.title, "Persecutor") then
            _Ship.title = "Охотник за головами"%_T
        end
    end

    Placer.resolveIntersections(_Generated)

    SpawnUtility.addEnemyBuffs(_Generated)

    local headhunterMessages =
    {
        "Это ${player}! Именно он нужен нашему клиенту!"%_T,
        "Нашли тебя, ${player}. Давай собьем их и получим наши деньги. Быстро."%_T,
        "Вот они. Ладно, ${player}, ничего личного, это просто работа."%_T,
        "Вы думали, что они облегчат вам задачу?",
        "Время умирать, ${player}."
    }

    _Player:sendChatMessage(_Generated[1], ChatMessageType.Chatter, getRandomEntry(headhunterMessages) % {player = _Player.name})
end

--Угнанные корабли
function rescueSlaves_spawnHijackedFactionShip()
    local methodName = "Spawn Hijacked Faction Ship"

    mission.Log(methodName, "Вызов угнанных кораблей фракции")

    local _Faction = Faction(mission.data.giver.factionIndex)

    local _FactionWave = ESCCUtil.getStandardWave(mission.data.custom.dangerLevel, 2, "High", true)
    local _FactionGenerator = AsyncShipGenerator(nil, rescueSlaves_onHijackedShipsFinished)

    _FactionGenerator:startBatch()

    for _, _Ship in pairs(_FactionWave) do
        _FactionGenerator:createDefenderByName(_Faction, _FactionGenerator:getGenericPosition(), _Ship)
    end

    _FactionGenerator:endBatch()
end

function rescueSlaves_onHijackedShipsFinished(_Generated)
    for _, _Ship in pairs(_Generated) do
        _Ship:addScriptOnce("entity/ai/hijackedfactionship.lua")
        --Наносит на 25% больше урона на уровне опасности 10.
        if mission.data.custom.dangerLevel == 10 then
            _Ship.damageMultiplier = (_Ship.damageMultiplier or 1) * 1.25
        end
    end

    Placer.resolveIntersections(_Generated)

    SpawnUtility.addEnemyBuffs(_Generated)
end

--Транспорты
function rescueSlaves_spawnLocalTransport()
    local methodName = "Spawn Local Transport"

    mission.Log(methodName, "Выполняется.")

    -- это позиция, где появляется торговец
    local dir = random():getDirection()
    local pos = dir * 1500

    -- это позиция, куда торговец прыгнет в гиперпространство
    local destination = -pos + vec3(math.random(), math.random(), math.random()) * 1000
    destination = normalize(destination) * 1500

    --использовать это для onfinished.
    local onTransportFinished = function(ships)
        local methodName = "On Transport Finished"
        local _Transport = ships[1]
        local _AddSlaves = false
        local _tportNo = mission.data.custom.transportNumber

        mission.Log(methodName, "Транспорт " .. tostring(_tportNo) .. " вызван. Добавление груза и установка пункта назначения.")
        if _tportNo == mission.data.custom.firstTransport then
            mission.Log(methodName, "Вызван первый транспорт рабов")
            _AddSlaves = true
        end
        if _tportNo == mission.data.custom.secondTransport then
            mission.Log(methodName, "Вызван второй транспорт рабов")
            _AddSlaves = true
        end
        if _tportNo == mission.data.custom.thirdTransport then
            mission.Log(methodName, "Вызван третий транспорт рабов")
            _AddSlaves = true
        end
        if _tportNo == mission.data.custom.fourthTransport then
            mission.Log(methodName, "Вызван четвертый транспорт рабов")
            _AddSlaves = true
        end
        if _tportNo == mission.data.custom.fifthTransport then
            mission.Log(methodName, "Вызван пятый транспорт рабов")
            _AddSlaves = true
        end
        if _tportNo == mission.data.custom.sixthTransport then
            mission.Log(methodName, "Вызван шестой транспорт рабов")
            _AddSlaves = true
        end
        if _tportNo == mission.data.custom.seventhTransport then
            mission.Log(methodName, "Вызван седьмой транспорт рабов")
            _AddSlaves = true
        end
        if _tportNo == mission.data.custom.eigthTransport then
            mission.Log(methodName, "Вызван восьмой транспорт рабов")
            _AddSlaves = true
        end
        if _tportNo == mission.data.custom.ninthTransport then
            mission.Log(methodName, "Вызван девятый (и последний) транспорт рабов")
            _AddSlaves = true
        end

        local _SlavesInHold = 12 --Почти всегда 1 корабль.
        if mission.data.custom.dangerLevel >= 6 then
            _SlavesInHold = 10 --Как минимум 1 корабль - возможно, 2.
        end
        if mission.data.custom.dangerLevel == 10 then
            _SlavesInHold = 5 --Как минимум 2 корабля - возможно, 3.
        end

        if _AddSlaves then
            mission.Log(methodName, "Добавление рабов - название транспорта " .. tostring(_Transport.name))

            _Transport:addCargo(goods["Slave"]:good(), _SlavesInHold)
            _Transport:setValue("rescueslaves_has_slaves", true)
            _Transport:setValue("rescueslaves_slave_qty", _SlavesInHold)
            _Transport:setValue("rescueslaves_mission_player", Player().index)
        else
            ShipUtility.addCargoToCraft(_Transport)
        end
        
        _Transport:addScriptOnce("ai/passsector.lua", destination)
        _Transport:setValue("passing_ship", true)

        Placer.resolveIntersections(ships)

        mission.data.custom.transportNumber = _tportNo + 1
    end

    local _Faction = Faction(mission.data.giver.factionIndex)

    local generator = AsyncFactionShipGenerator(nil, onTransportFinished)
    generator:startBatch()

    pos = pos + dir * 200
    local matrix = MatrixLookUpPosition(-dir, vec3(0, 1, 0), pos)

    generator:createFreighterShip(_Faction, matrix)

    generator:endBatch()
end

--другое
function rescueSlaves_playerDoneTutorial()
    Player():setValue("_rescueslaves_tutorial_shown", true)
end
callable(nil, "rescueSlaves_playerDoneTutorial")

function rescueSlaves_finishAndReward()
    local methodName = "Finish and Reward"
    mission.Log(methodName, "Выполнение условия победы.")

    reward()
    accomplish()
end

function rescueSlaves_failAndPunish()
    local methodName = "Fail and Punish"
    mission.Log(methodName, "Выполнение условия проигрыша.")

    punish()
    fail()
end

--endregion

--region #CLIENT CALLS

function rescueSlaves_showBroughtHomeDialog(stationId, amount, closeable)
    local ui = ScriptUI(stationId)
    ui:interactShowDialog(rescueSlaves_broughtHomeDialog(amount), closeable)
end

function rescueSlaves_broughtHomeDialog(amount)
    amount = amount or 0

    local xrandom = random() --небольшая оптимизация, чтобы не инициализировать это раз 5.
    local dialog = {}
    local d1_End = {}
    local d2_Reimburse = {}

    if amount < mission.data.custom.amountSlaves then
        --В теории не должно быть возможно. На практике кто-нибудь придумает, как это сделать.
        dialog.text = "А. Это не... все. Спасибо за тех, кого вы вернули... нам придется подготовить траурные церемонии."
        dialog.onEnd = rescueSlaves_onBroughtHomeEnd
    else
        local _initialGreetingLines = {
            "Большое спасибо за то, что вернули наших людей домой! Все прошло гладко, надеюсь?",
            "О, слава богу. Вам удалось вернуть их домой в целости и сохранности. Спасибо - большое спасибо!"
        }
        shuffle(xrandom, _initialGreetingLines)
    
        dialog.text = _initialGreetingLines[1]
        dialog.answers = {
            {answer = "Не стоит благодарности. Серьезно, не стоит.", followUp = d1_End},
            {answer = "Это было мое удовольствие.", followUp = d1_End},
            {answer = "Конечно, конечно. Но мне пришлось заплатить немало кредитов, чтобы вернуть их...", followUp = d2_Reimburse}
        }
        
        local _thankYouLines = {
            "Мы никогда этого не забудем - и, пожалуйста, берегите себя. Бог знает, нам нужно больше таких людей, как вы, здесь.",
            "Большое спасибо, капитан. Галактике нужно больше таких людей, как вы."
        }
        shuffle(xrandom, _thankYouLines)
    
        d1_End.text = _thankYouLines[1]
        d1_End.onEnd = rescueSlaves_onBroughtHomeEnd
    
        local _noMoneyLines = {
            "Вам пришлось за них заплатить? Мне очень жаль это слышать, но мы не можем вам вернуть деньги. Если бы у нас были такие деньги, мы бы выкупили их немедленно.",
            "...а. У нас нет... У нас нет никаких денег - если бы они были, мы бы просто выкупили их сами, не так ли? Мне жаль..."
        }
        shuffle(xrandom, _noMoneyLines)
        
        d2_Reimburse.text = _noMoneyLines[1]
        d2_Reimburse.onEnd = rescueSlaves_onBroughtHomeEnd
    end

    return dialog
end

function rescueSlaves_highlightRescuedSlaves()
    local methodName = "Highlight Rescued Slaves"

    for _, entity in pairs({Sector():getEntitiesByComponent(ComponentType.CargoLoot)}) do
        local loot = CargoLoot(entity)

        if loot:matches("Rescued Slave") then
            Hud():displayHint("Подберите этих спасенных рабов! Не забудьте включить 'Подбирать краденые товары'!", entity)
        end
    end
end

--endregion

--region #MAKEBULLETIN CALL

function rescueSlaves_formatDescription(_Station)
    local descriptionTable = {
        "Торговцы людьми похитили часть наших людей. Это были обычные мужчины, женщины и дети. Мы знаем, через какой сектор их будут перевозить, но торговцы глубоко укоренились в местной фракции. Мы никак не сможем их найти. Если вы поможете, мы будем вам бесконечно благодарны.",
        "Некоторых из наших людей похитили! Мы знаем, через какой сектор их будут перевозить, но у нас нет ресурсов, чтобы расследовать это самостоятельно. Пожалуйста, помогите нам! Если мы не сможем найти их до того, как их переведут, они исчезнут, и мы больше не сможем их найти!",
        "Наших родных похитили! У нас нет каких-то особых навыков... или долгой карьеры... но, возможно, они есть у вас. Возможно, вы сможете стать кошмаром для таких людей, как они. Пожалуйста, капитан. Помогите нам - спасите наши семьи и верните их. Мы знаем, куда их увезли, но у нас нет средств, чтобы найти их самостоятельно.",
        "Если вы это видите, пожалуйста - нам нужна ваша помощь. Вчера ночью на нашу станцию напали, и многих наших людей - среди них женщины и дети - похитили и увезли на продажу. Мы знаем, где они находятся, но нападение сделало нас слишком слабыми, чтобы преследовать их. Мы это окупим, только, пожалуйста, помогите нам!!!"
    }

    return getRandomEntry(descriptionTable)
end

mission.makeBulletin = function(_Station)
    local methodName = "Make Bulletin"
    mission.Log(methodName, "Выполняется.")
    --Нам нужно:
    --1 - обычный или внесетковый контентный сектор
    --2 - сектор, принадлежащий текущей фракции.
    --3 - сектор, в котором не менее 4-5 станций.
    --Это немного сложно - нам нужно инициализировать много всего, чтобы это сделать. Очень жаль, что нет более простого способа это сделать. Есть желающие, Boxelware?
    local _sector = Sector()
    local seed = Server().seed
    local specs = SectorSpecifics()

    local _Rgen = ESCCUtil.getRand()
    local target = {}
    local x, y = _sector:getCoordinates()
    local insideBarrier = MissionUT.checkSectorInsideBarrier(x, y)
    --Затем мы пытаемся найти сектор, соответствующий пунктам 1, 2 и 3 выше.
    local _ExcludedSectors = {}
    for _ = 1, 30 do
        --Не стоит пытаться слишком много раз.
        target.x, target.y = MissionUT.getSectorWithStations(x, y, 3, 22, true, nil, nil, nil, insideBarrier, _ExcludedSectors)
        --Будьте осторожны с включением слишком большого количества этих логов. Они несколько неприятны.
        mission.Log(methodName, "Проверка " .. tostring(target.x) .. " : " .. tostring(target.y))

        local _, _, _, _, _, specsFactionIndex = specs:determineContent(target.x, target.y, seed)

        if specsFactionIndex and specsFactionIndex == _Station.factionIndex then
            --mission.Log(methodName, "индекс фракции specs " .. tostring(specsFactionIndex) .. " соответствует индексу фракции станции " .. tostring(_Station.factionIndex))
            
            specs:initialize(target.x, target.y, seed)
            if specs.generationTemplate then
                --mission.Log(methodName, "Проверка шаблона генерации")
                local contents = specs.generationTemplate.contents(target.x, target.y)
                if contents and contents["stations"] and contents["stations"] > 3 then
                    --mission.Log(methodName, "Найден целевой объект с не менее чем 3 станциями. Прерывание и продолжение.")
                    break
                end
            end
        end

        --Мы должны выйти из цикла, если цель найдена, а это значит, что если мы все еще здесь, мы не нашли подходящую цель.
        --Добавьте его в черный список, чтобы мы не пытались снова и снова один и тот же сектор и продолжали идти.
        table.insert(_ExcludedSectors, { x = target.x, y = target.y })
        target = {}
    end

    if not target.x or not target.y then
        mission.Log(methodName, "Target.x или Target.y не установлены - возвращается nil.")
        return 
    end

    local _DangerLevel = _Rgen:getInt(1, 10)

    local _Difficulty = "Сложно"
    if _DangerLevel == 10 then
        _Difficulty = "Экстремально"
    end

    local _Description = rescueSlaves_formatDescription(_Station)

    reward = 0 --УСТАНОВИТЬ НАГРАДУ ЗДЕСЬ
    reputation = 16000 --На самом деле мы получаем больше, чем это, из-за потенциального убийства некоторых пиратов и т. д.
    if _DangerLevel == 10 then
       reputation = reputation + 2000 --Добавить еще 2k при опасности 10.
    end

    _MissionReward = { credits = reward, relations = reputation }

    local distToCenter = math.sqrt(x * x + y * y)
    local _MatlMin = 0 --7000
    local _MatlMax = 0 --8000
    if distToCenter > 400 then
        --Всегда давайте примерно на 50% больше, чем свободных рабов.
        _MatlMin = 10000
        _MatlMax = 12000
    elseif distToCenter < 400 and distToCenter > 300 then
        _MatlMin = 20000
        _MatlMax = 24000
    else
        _MatlMin = 40000
        _MatlMax = 48000
    end
    
    mission.Log(methodName, "matlmin is ${MIN} and matlmax is ${MAX}" % { MIN = _MatlMin, MAX = _MatlMax }) 

    local materialAmount = round(random():getInt(_MatlMin, _MatlMax) / 100) * 100
    MissionUT.addSectorRewardMaterial(x, y, _MissionReward, materialAmount)

    _MissionPunishment = { relations = baseRep }

    local bulletin =
    {
        -- данные для доски объявлений
        brief = mission.data.brief,
        title = mission.data.title,
        description = _Description,
        difficulty = _Difficulty,
        reward = "¢${reward}"%_T,
        script = "missions/rescueslaves.lua",
        formatArguments = {x = target.x, y = target.y, reward = createMonetaryString(reward)},
        msg = "Пожалуйста, перейдите в сектор \\s(%1%:%2%) и спасите членов нашей семьи."%_T,
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
            reward = _MissionReward,
            punishment = _MissionPunishment,
            dangerLevel = _DangerLevel,
            initialDesc = _Description
        }},
    }

    return bulletin
end

--endregion