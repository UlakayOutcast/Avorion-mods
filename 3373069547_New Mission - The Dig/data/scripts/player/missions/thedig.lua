package.path = package.path .. ";data/scripts/lib/?.lua"
package.path = package.path .. ";data/scripts/?.lua"

include("structuredmission")

ESCCUtil = include("esccutil")

local Balancing = include ("galaxy")
local SectorGenerator = include ("SectorGenerator")
local AsyncPirateGenerator = include ("asyncpirategenerator")
local PirateGenerator = include("pirategenerator")
local CaptainGenerator = include("captaingenerator")
local AsyncShipGenerator = include("asyncshipgenerator")
local ShipGenerator = include("shipgenerator")
local SpawnUtility = include ("spawnutility")
local Xsotan = include("story/xsotan")
local Placer = include("placer")

mission._Debug = 0
mission._Name = "Раскопки"

--region #INIT

--Standard mission data.
mission.data.brief = mission._Name
mission.data.title = mission._Name
mission.data.autoTrackMission = true
mission.data.description = {
    { text = "Вы получили следующий запрос от ${giverTitle} из сектора ${sectorName}:" }, --Placeholder
    { text = "..." },
    { text = "Направляйтесь в сектор (${_X}:${_Y})", bulletPoint = true, fulfilled = false },
    { text = "Защитите шахтеров", bulletPoint = true, fulfilled = false, visible = false },
    { text = "Не дайте уничтожить слишком много шахтеров - ${_DESTROYED}/${_MAXDESTROYED} Потеряно", bulletPoint = true, fulfilled = false, visible = false },
    { text = "(Необязательно) Добывайте ресурсы", bulletPoint = true, fulfilled = false, visible = false }
}
mission.data.timeLimit = 10 * 60 --У игрока есть 10 минут, чтобы добраться до сектора. Уберите ограничение по времени, когда игрок прибудет.
mission.data.timeLimitInDescription = true --Показывать игроку, сколько времени осталось.

mission.data.accomplishMessage = "Мы получили необходимые ресурсы! Спасибо за защиту наших шахтеров."
mission.data.abandonMessage = "Мы разочарованы тем, что вы решили отказаться от этого контракта. Нам придется отменить нашу экспедицию."
mission.data.failMessage = "Наши шахтеры были уничтожены. Тысячи квалифицированных специалистов погибли из-за вашей неудачи."

local TheDig_init = initialize
function initialize(_Data_in, bulletin)
    local methodName = "initialize"
    mission.Log(methodName, "Начинаем...")

    if onServer() and not _restoring then
        mission.Log(methodName, "Вызов на сервере - dangerLevel : " .. tostring(_Data_in.dangerLevel) .. " threattype: " .. tostring(_Data_in.threatType))

        local _X, _Y = _Data_in.location.x, _Data_in.location.y

        local _Sector = Sector()
        local _Giver = Entity(_Data_in.giver)
        
        --Emergency breakout just in case the player somehow got this from a player faction.
        if _Giver.playerOrAllianceOwned then
            print("ОШИБКА: Миссия от фракции игрока - прерываем.")
            terminate()
            return
        end
        --[[=====================================================
            CUSTOM MISSION DATA SETUP:
        =========================================================]]
        mission.data.custom.dangerLevel = _Data_in.dangerLevel
        mission.data.custom.threatType = _Data_in.threatType
        mission.data.custom.friendlyFaction = _Giver.factionIndex
        mission.data.custom.timePassed = 0
        if mission.data.custom.threatType == 1 then --1 = faction / 2 = pirates / 3 = xsotan
            mission.data.custom.enemyFaction = _Data_in.enemyFaction 

            local _MissionDoer = Player().craftFaction or Player()
            local _Relation = _MissionDoer:getRelation(mission.data.custom.enemyFaction)
            local _EnemyFaction = Faction(mission.data.custom.enemyFaction)
            local _GiverFaction = Faction(_Giver.factionIndex)
            local _Relation2Giver = _GiverFaction:getRelation(mission.data.custom.enemyFaction)

            mission.data.custom.enemyRelationLevel = _Relation.level
            mission.data.custom.enemyRelationStatus = _Relation.status
            mission.data.custom.enemyRelationLevel2Giver = _Relation2Giver.level
            mission.data.custom.enemyRelationStatus2Giver = _Relation2Giver.status

            mission.Log(methodName, "Вражеская фракция: " .. tostring(_EnemyFaction.name))
            mission.data.custom.enemyName = _EnemyFaction.name
        end
        local minXsoSize = 0
        local maxXsoSize = 2
        local maxDestroyable = 6
        if mission.data.custom.dangerLevel > 5 then
            maxDestroyable = maxDestroyable - 1 --4 max
            minXsoSize = minXsoSize + 1
        end
        if mission.data.custom.dangerLevel == 10 then
            maxDestroyable = maxDestroyable - 1 --3 max
            minXsoSize = minXsoSize + 1
            maxXsoSize = maxXsoSize + 1
        end
        mission.data.custom.minXsotanSizeBonus = minXsoSize
        mission.data.custom.maxXsotanSizeBonus = maxXsoSize
        mission.data.custom.spawnXsotanWaveNext = false
        mission.data.custom.maxDestroyed = maxDestroyable
        mission.data.custom.enemyShipsSpawned = 0
        mission.data.custom.destroyed = 0
        mission.data.custom.inBarrier = _Data_in.inBarrier

        if not mission.data.custom.friendlyFaction then
            print("ОШИБКА: Дружественная фракция отсутствует - прерываем.")
            terminate()
            return
        end

        --[[=====================================================
            MISSION DESCRIPTION SETUP:
        =========================================================]]
        mission.data.description[1].arguments = { sectorName = _Sector.name, giverTitle = _Giver.translatedTitle }
        mission.data.description[2].text = _Data_in.initialDesc
        mission.data.description[2].arguments = { _X = _X, _Y = _Y, enemyName = mission.data.custom.enemyName }
        mission.data.description[3].arguments = { _X = _X, _Y = _Y }
        mission.data.description[5].arguments = { _DESTROYED = mission.data.custom.destroyed, _MAXDESTROYED = mission.data.custom.maxDestroyed }
    end

    --Run vanilla init. Managers _restoring on its own.
    TheDig_init(_Data_in, bulletin)
end

--endregion

--region #PHASE CALLS

mission.globalPhase.timers = {}

mission.globalPhase.noBossEncountersTargetSector = true

mission.globalPhase.getRewardedItems = function()
    --25% of getting a random rarity mining upgrade.
    if random():test(0.25) then
        local _SeedInt = random():getInt(1, 20000)
        local _Rarities = {RarityType.Common, RarityType.Common, RarityType.Uncommon, RarityType.Uncommon, RarityType.Rare}

        if mission.data.custom.inBarrier then
            _Rarities = {RarityType.Uncommon, RarityType.Uncommon, RarityType.Rare, RarityType.Rare, RarityType.Exceptional, RarityType.Exotic}
        end

        shuffle(random(), _Rarities)

        return SystemUpgradeTemplate("data/scripts/systems/miningsystem.lua", Rarity(_Rarities[1]), Seed(_SeedInt))
    end
end

mission.globalPhase.onAbandon = function()
    local methodName = "Глобальная фаза при отказе"

    if mission.data.custom.destroyed == 0 then
        mission.Log(methodName, "Шахтеры не уничтожены - уменьшаем штраф вдвое.")
        mission.data.punishment.relations = mission.data.punishment.relations / 2
        punish()
    else
        mission.Log(methodName, "Шахтеры уничтожены - полный штраф.")
        punish()
    end

    if mission.data.location then
        runFullSectorCleanup(true)
    end
end

mission.globalPhase.onFail = function()
    --miners departing is handled by theDig_doMissionEndCleanup in phase 2 onfail.
    if mission.data.location then
        runFullSectorCleanup(true)
    end
end

mission.globalPhase.onAccomplish = function()
    if mission.data.location then
        runFullSectorCleanup(true) --The solar winds blow everything away. Whooooosh.
    end
end

--region #GLOBALPHASE TIMERS

if onServer() then

mission.globalPhase.timers[1] = {
    time = 130, 
    callback = function() 
        local methodName = "Глобальный фазовый таймер 1"
        mission.Log(methodName, "Начинаем...")

        mission.data.custom.timePassed = (mission.data.custom.timePassed or 0) + 130

        mission.Log(methodName, "Прошло времени " .. tostring(mission.data.custom.timePassed))

        --Give the player a 5 minute grace period.
        if mission.data.custom.timePassed >= 300 and not atTargetLocation() then
            mission.data.custom.destroyed = mission.data.custom.destroyed + 1
            mission.Log(methodName, "Не на месте - увеличиваем уничтоженные до : " .. tostring(mission.data.custom.destroyed))

            if mission.data.custom.destroyed >= mission.data.custom.maxDestroyed then
                theDig_failAndPunish()
            end

            mission.data.description[5].arguments = { _DESTROYED = mission.data.custom.destroyed, _MAXDESTROYED = mission.data.custom.maxDestroyed }
            mission.data.abandonMessage = mission.data.failMessage

            sync()
        end
    end,
    repeating = true
}
    
end
    
--endregion

mission.phases[1] = {}
mission.phases[1].showUpdateOnEnd = true
mission.phases[1].onTargetLocationEntered = function(x, y)
    local _random = random()
    local missionTime = 20 * 60 --minimum 20 mins
    missionTime = missionTime + (_random:getInt(2, 7) * 60) --add 2-7 minutes.
    missionTime = missionTime + (_random:getInt(1, mission.data.custom.dangerLevel) * 60) --add up to dangerlevel minutes.

    mission.data.timeLimit = mission.internals.timePassed + missionTime --Defend the miners for X minutes.
    mission.internals.fulfilled = true --At this point, this mission will succeed at timeout, and not fail.

    mission.data.description[3].fulfilled = true
    mission.data.description[4].visible = true
    mission.data.description[5].visible = true
    mission.data.description[6].visible = true

    if onServer() then
        theDig_spawnMiningSector(x, y)
    end
end

mission.phases[1].onTargetLocationArrivalConfirmed = function(x, y)
    nextPhase()
end

mission.phases[2] = {}
mission.phases[2].timers = {}
mission.phases[2].onBeginServer = function()
    local methodName = "Фаза 2. При начале на сервере"
    mission.Log(methodName, "Запуск.")

    if mission.data.custom.threatType == 1 then --enemy faction
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
            mission.Log(methodName, "Вражеская фракция еще не воюет с фракцией, выдавшей миссию. Объявляем войну.")

            _Galaxy:setFactionRelations(enemyFaction, friendlyFaction, -100000)
            _Galaxy:setFactionRelationStatus(enemyFaction, friendlyFaction, RelationStatus.War)
        end

        Player():sendChatMessage(mission.data.custom.enemyName, 0, "Мы заявили права на это астероидное поле! Мы не оставим эту агрессию без ответа.")
    elseif mission.data.custom.threatType == 3 then --xsotan
        Player():sendChatMessage("", 3, "Ваши датчики засекли короткий импульс подпространственных сигналов."%_t)
    end
end

mission.phases[2].updateServer = function(timeStep)
    if mission.data.custom.destroyed >= mission.data.custom.maxDestroyed then
        theDig_failAndPunish()
    end
end

mission.phases[2].onEntityDestroyed = function(_ID, _LastDamageInflictor)
    local methodName = "Фаза 2. При уничтожении сущности"
    --mission.Log(methodName, "Начинаем...")
    if Entity(_ID):getValue("_thedig_defendobjective") then
        mission.Log(methodName, "Был целью.")
        mission.data.custom.destroyed = mission.data.custom.destroyed + 1
        mission.data.description[5].arguments = { _DESTROYED = mission.data.custom.destroyed, _MAXDESTROYED = mission.data.custom.maxDestroyed }
        mission.data.abandonMessage = mission.data.failMessage

        mission.Log(methodName, "Количество уничтоженных шахтеров " .. tostring(mission.data.custom.destroyed))
        sync()
    end
end

mission.phases[2].onAccomplish = function()
    theDig_doMissionEndCleanup()

    if mission.data.custom.destroyed == 0 then --give the player a bonus if no miners are lost.
        mission.data.reward.paymentMessage = mission.data.reward.paymentMessage .. " Включает бонус за отсутствие потерь."
        mission.data.reward.credits = mission.data.reward.credits * 1.25 
    end

    reward()
end

mission.phases[2].onFail = function()
    theDig_doMissionEndCleanup() --theDig_minersDepart
    if atTargetLocation() then
        theDig_spawnKickoutWave()
    end
end

mission.phases[2].onAbandon = function()
    if mission.data.custom.threatType == 1 then --faction
        --reset the original relation between the two factions but NOT the player.
        local _Faction = Faction(mission.data.custom.enemyFaction)
        local _FriendlyFaction = Faction(mission.data.custom.friendlyFaction)
        local _Galaxy = Galaxy()

        _Galaxy:setFactionRelations(_Faction, _FriendlyFaction, mission.data.custom.enemyRelationLevel2Giver)
        _Galaxy:setFactionRelationStatus(_Faction, _FriendlyFaction, mission.data.custom.enemyRelationStatus2Giver)
    end

    if atTargetLocation() then
        theDig_minersDepart()
        theDig_spawnKickoutWave()
    end
end

--region #PHASE 2 TIMERS

if onServer() then

mission.phases[2].timers[1] = {
    time = 60,
    callback = function()
        --Every minute the player isn't in the sector, lose a miner.
        if not atTargetLocation() then
            mission.data.custom.destroyed = mission.data.custom.destroyed + 1
            mission.data.description[5].arguments = { _DESTROYED = mission.data.custom.destroyed, _MAXDESTROYED = mission.data.custom.maxDestroyed }
            sync()
        end
    end,
    repeating = true
}

mission.phases[2].timers[2] = {
    time = 60,
    callback = function()
        if atTargetLocation() then
            theDig_spawnGiverFactionMiner()
        end
    end,
    repeating = false
}

mission.phases[2].timers[3] = {
    time = 120,
    callback = function()
        --Every 2 minutes, spawn miners until there are 4.
        if atTargetLocation() then
            theDig_spawnGiverFactionMiner()
        end
    end,
    repeating = true
}

mission.phases[2].timers[4] = {
    time = 150, 
    callback = function()
        --Every 2:30, spawn an attack wave.
        if atTargetLocation() then
            local threatFuncs = {
                function()
                    theDig_spawnFactionWave()
                end,
                function()
                    theDig_spawnPirateWave()
                end,
                function()
                    theDig_spawnXsotanWave()
                end,
            }

            threatFuncs[mission.data.custom.threatType]()
        end
    end,
    repeating = true
}

mission.phases[2].timers[5] = {
    time = 300,
    callback = function()
        --The xsotan aren't that dangerous compared to the high level pirates, so we give them a little extra help.
        if atTargetLocation() and mission.data.custom.threatType == 3 then
            local _random = random()
            local pctChance = 0.1 * mission.data.custom.dangerLevel

            if _random:test(pctChance) or mission.data.custom.spawnXsotanWaveNext then
                mission.data.custom.spawnXsotanWaveNext = false
                theDig_spawnXsotanWave()
            else
                local pctChance2 = math.min(pctChance * 2, 1.0) --caps @ danger 5.
                if _random:test(pctChance2) then
                    mission.data.custom.spawnXsotanWaveNext = true
                end
            end
        end
    end,
    repeating = true
}

end

--endregion

--endregion

--region #SERVER CALLS

function theDig_spawnMiningSector(x, y)
    local methodName = "Создать горнодобывающий сектор"

    local generator = SectorGenerator(x, y)
    local _random = random()

    local poiMaxCt = math.max(math.floor(mission.data.custom.dangerLevel / 3), 1)
    if mission.data.custom.dangerLevel == 10 then
        if _random:test(0.5) then
            poiMaxCt = poiMaxCt + 1
        end
        if _random:test(0.25) then
            poiMaxCt = poiMaxCt + 1
        end
    end

    local numFields = _random:getInt(2, 4)
    local bigAsteroidCt = 0

    for i = 1, numFields do
        local position = generator:createAsteroidField(0.075)
        if _random:test(0.5) and bigAsteroidCt < poiMaxCt then 
            generator:createBigAsteroid(position) 
            bigAsteroidCt = bigAsteroidCt + 1
        end
    end

    --Always do a very high yield one.
    generator:createAsteroidField(0.1 * mission.data.custom.dangerLevel)

    --Then do 4-6 that are rich depending on danger level
    local numRichFields = _random:getInt(5, 7)

    for _ = 1, numRichFields do
        generator:createAsteroidField(0.015 * mission.data.custom.dangerLevel)
    end

    local numSmallFields = _random:getInt(8, 15)
    local stashCt = 0
    local stashChance = 0.015 * mission.data.custom.dangerLevel
    for i = 1, numSmallFields do
        local position = generator:createSmallAsteroidField(0.1)
        if _random:test(stashChance) and stashCt < poiMaxCt then 
            generator:createStash(position) 
            stashCt = stashCt + 1
        end
    end

    Placer.resolveIntersections()

    mission.data.custom.cleanUpSector = true
end

function theDig_spawnGiverFactionMiner()
    local miners = {Sector():getEntitiesByScriptValue("_thedig_defendobjective")}

    if #miners < 4 then
        --spawn a new miner.
        local _Sector = Sector()
        local _X, _Y = _Sector:getCoordinates()
        local _ShipGenerator = AsyncShipGenerator(nil, theDig_onMinerFinished)
        local _Vol1 = Balancing_GetSectorShipVolume(_X, _Y) * random():getInt(2, 8)
        local _Faction = Faction(mission.data.custom.friendlyFaction)
    
        _ShipGenerator:startBatch()
        
        _ShipGenerator:createMiningShip(_Faction, _ShipGenerator:getGenericPosition(), _Vol1)
    
        _ShipGenerator:endBatch()
    end
end

function theDig_onMinerFinished(_Generated)
    local methodName = "On Miner Finished"
    mission.Log(methodName, "Starting.")

    local _Ship = _Generated[1]

    --Multiply durability so the ship isn't instakilled. The miner can still be killed fairly easily by say... a hardcore prowler. So bring good firepower!
    mission.Log(methodName, "Updating durability.")
    local _Dura = Durability(_Ship)

    local _DurabilityBonus = 3
    if mission.data.custom.inBarrier then
        _DurabilityBonus = 5
    end

    local _Shield = Shield(_Ship)
    if _Shield then
        _Shield.maxDurabilityFactor = _Shield.maxDurabilityFactor * _DurabilityBonus
    else
        _DurabilityBonus = _DurabilityBonus * 2
    end

    if _Dura then
        _Dura.maxDurabilityFactor = _Dura.maxDurabilityFactor * _DurabilityBonus
    end

    mission.Log(methodName, "Adding captain, setting script values, adding scripts.")
    --needs a captain before it will mine.
    local crewComponent = CrewComponent(_Ship)
    crewComponent:setCaptain(CaptainGenerator():generate())
    _Ship:addScript("ai/mine.lua")
    _Ship:addScript("ai/thedigminer.lua")
    _Ship:setValue("bDisableXAI", true)
    _Ship:setValue("_thedig_defendobjective", true)
    _Ship:setValue("_thedig_player", Player().index)
end

function theDig_minersDepart()
    local methodName = "Miners Depart"
    mission.Log(methodName, "Running.")

    local miners = {Sector():getEntitiesByScriptValue("_thedig_defendobjective")}

    for _, miner in pairs(miners) do
        miner:addScriptOnce("entity/utility/delayeddelete.lua", random():getFloat(3, 6))
    end
end

function theDig_getPirateWingTable(wingScriptValue)
    local methodName = "Get Pirate Wing Spawn Table"
    mission.Log(methodName, "Beginning...")

    local _MaxCt = 4
    if mission.data.custom.dangerLevel == 10 and random():test(0.5) then
        _MaxCt = _MaxCt + 1
    end

    local _Pirates = {Sector():getEntitiesByScriptValue(wingScriptValue)}

    local _SpawnCt = _MaxCt - #_Pirates

    local _SpawnTable = {}
    if _SpawnCt > 0 then
        _SpawnTable = ESCCUtil.getStandardWave(mission.data.custom.dangerLevel, _SpawnCt, "Standard", false)
    end

    return _SpawnTable
end

function theDig_spawnPirateWave()
    local methodName = "Spawn Pirate Wave"
    mission.Log(methodName, "Running.")

    --standard alpha / beta wing setup. 4/4 split.
    local distance = 250 --_#DistAdj

    local _spawnFunc = function(wingScriptValue, wingOnSpawnFunc)
        local _WingSpawnTable = theDig_getPirateWingTable(wingScriptValue)
        local wingGenerator = AsyncPirateGenerator(nil, wingOnSpawnFunc)

        local posCounter = 1
        local wingPositions = wingGenerator:getStandardPositions(#_WingSpawnTable, distance)
        
        wingGenerator:startBatch()

        for _, p in pairs(_WingSpawnTable) do
            wingGenerator:createScaledPirateByName(p, wingPositions[posCounter])
            posCounter = posCounter + 1
        end

        wingGenerator:endBatch()
    end

    --spawn alpha
    _spawnFunc("_thedig_alpha_wing", theDig_onEnemyAlphaWingFinished)

    --spawn beta
    _spawnFunc("_thedig_beta_wing", theDig_onEnemyBetaWingFinished)
end

function theDig_getFactionWingTable(wingScriptValue)
    local methodName = "Get Faction Wing Spawn Table"
    mission.Log(methodName, "Beginning...")

    local _Enemies = {Sector():getEntitiesByScriptValue(wingScriptValue)}

    local _SpawnCt = 3 - #_Enemies

    local _SpawnTable = {}
    if _SpawnCt > 0 then
        local _DefenderShips = 1
        if _SpawnCt > 1 and random():test(0.05 * mission.data.custom.dangerLevel) then --50% chance @ danger 10
            _DefenderShips = _DefenderShips + 1
        end

        _SpawnTable = ESCCUtil.getStandardWave(mission.data.custom.dangerLevel, _DefenderShips, "Standard", true)
    end

    while #_SpawnTable < _SpawnCt do
        table.insert(_SpawnTable, "MS")
    end

    return _SpawnTable
end

function theDig_spawnFactionWave()
    local methodName = "Spawn Faction Wave"
    mission.Log(methodName, "Running.")

    --standard alpha / beta wing setup. 3/3 split because heavy defenders are a nightmare to deal with.
    local distance = 2500 --_#FACTDistAdj

    local _spawnFunc = function(wingScriptValue, wingOnSpawnFunc)
        local wingSpawnTable = theDig_getFactionWingTable(wingScriptValue)
        local wingGenerator = AsyncShipGenerator(nil, wingOnSpawnFunc)
        local enemyFaction = Faction(mission.data.custom.enemyFaction)

        local posCounter = 1
        local wingPositions = wingGenerator:getStandardPositions(#wingSpawnTable, distance)

        wingGenerator:startBatch()

        for _, es in pairs(wingSpawnTable) do
            wingGenerator:createDefenderByName(enemyFaction, wingPositions[posCounter], es)
            posCounter = posCounter + 1
        end

        wingGenerator:endBatch()
    end

    --spawn alpha
    _spawnFunc("_thedig_alpha_wing", theDig_onEnemyAlphaWingFinished)

    --spawn beta
    _spawnFunc("_thedig_beta_wing", theDig_onEnemyBetaWingFinished)
end

function theDig_onEnemyAlphaWingFinished(generated)
    for _, enemyShip in pairs(generated) do
        enemyShip:setValue("_thedig_alpha_wing", true)

        --This is for performance reasons, so there aren't dozens and dozens of items scattered around the sector.
        local enemiesSpawned = mission.data.custom.enemyShipsSpawned + 1
        local _Factor = 2
        if enemiesSpawned >= 20 then
            _Factor = 3
        end
        if enemiesSpawned % _Factor ~= 0 then
            enemyShip:setDropsLoot(false)
        end
        mission.data.custom.enemyShipsSpawned = enemiesSpawned

        if mission.data.custom.threatType == 1 then
            enemyShip:removeScript("patrol.lua")
            enemyShip:removeScript("antismuggle.lua")

            local enemyShipAI = ShipAI(enemyShip)
            enemyShipAI:setAggressive()
        end
    end

    if mission.data.custom.threatType == 2 then --defender ship + buff = nightmare
        SpawnUtility.addEnemyBuffs(generated)
    end

    Placer.resolveIntersections(generated)
end

function theDig_onEnemyBetaWingFinished(generated)
    local methodName = "On Enemy Beta Wing Finished"

    local _sector = Sector()
    local _random = random()
    local x, y = _sector:getCoordinates()
    local specialEnemyCtMax = 1
    local addSpecialEnemy = _random:test(0.025 * mission.data.custom.dangerLevel)

    local torpedoEnemies = { _sector:getEntitiesByScript("torpedoslammer.lua") }
    local laserEnemies = { _sector:getEntitiesByScript("lasersniper.lua") }
    local specialPirates = #torpedoEnemies + #laserEnemies
    local specialAdded = 0

    for _, enemyShip in pairs(generated) do
        enemyShip:setValue("_thedig_beta_wing", true)
        enemyShip:addScript("ai/priorityattacker.lua", { _TargetPriority = 1, _TargetTag = "_thedig_defendobjective" })

        --This is for performance reasons, so there aren't dozens and dozens of items scattered around the sector.
        local enemiesSpawned = mission.data.custom.enemyShipsSpawned + 1
        local _Factor = 2
        if enemiesSpawned >= 20 then
            _Factor = 3
        end
        if enemiesSpawned % _Factor ~= 0 then
            enemyShip:setDropsLoot(false)
        end
        mission.data.custom.enemyShipsSpawned = enemiesSpawned

        --Add torpedo slammer / deadshot scripts if necessary.
        if (specialPirates + specialAdded) < specialEnemyCtMax and addSpecialEnemy then
            if _random:test(0.5) then
                local _TorpSlammerValues = {
                    _TimeToActive = 30,
                    _ROF = 8,
                    _UpAdjust = false,
                    _ForwardAdjustFactor = 2,
                    _PreferWarheadType = _random:getInt(1,3), --nuclear, fusion, or neutron picked at random
                    _TargetPriority = 2, --Target tag.
                    _TargetTag = "_thedig_defendobjective"
                }

                if mission.data.custom.threatType == 1 then --faction
                    ESCCUtil.setFusilier(enemyShip)
                elseif mission.data.custom.threatType == 2 then --pirate
                    ESCCUtil.setBombardier(enemyShip)
                end
                enemyShip:addScript("torpedoslammer.lua", _TorpSlammerValues)
            else
                local _dpf = Balancing_GetSectorWeaponDPS(x, y) * 125 --Same as a Xsotan Longinus.
            
                mission.Log(methodName,"Setting dpf to " .. tostring(_dpf))

                local _LaserSniperValues = { --#LONGINUS_SNIPER
                    _DamagePerFrame = _dpf,
                    _TimeToActive = 30,
                    _TargetCycle = 15,
                    _TargetingTime = 2.25, --Take longer than normal to target.
                    _TargetPriority = 3, --Target tag.
                    _TargetTag = "_thedig_defendobjective"
                }

                if mission.data.custom.threatType == 1 then --faction
                    ESCCUtil.setMarksman(enemyShip)
                elseif mission.data.custom.threatType == 2 then --pirate
                    ESCCUtil.setDeadshot(enemyShip)
                end
                enemyShip:addScriptOnce("lasersniper.lua", _LaserSniperValues)
            end

            specialAdded = specialAdded + 1
        end

        if mission.data.custom.threatType == 1 then
            enemyShip:removeScript("patrol.lua")
            enemyShip:removeScript("antismuggle.lua")

            local enemyShipAI = ShipAI(enemyShip)
            enemyShipAI:setAggressive()
        end
    end

    if mission.data.custom.threatType == 2 then --defender ship + buff = nightmare
        SpawnUtility.addEnemyBuffs(generated)
    end
    
    Placer.resolveIntersections(generated)
end

function theDig_spawnXsotanWave()
    local methodName = "Spawn Xsotan Wave"
    mission.Log(methodName, "Running.")

    local _sector = Sector()
    local _random = random()
    local secGenerator = SectorGenerator(_sector:getCoordinates())
    local players = {_sector:getPlayers()}

    local xsotanByNameTable = {}
    local xsotanTable = {}

    --spawn in a group of 5. Add a 6th @ danger 10.
    local waveSize = 5
    if mission.data.custom.dangerLevel == 10 then
        waveSize = waveSize + 1
    end

    --Only allow up to 25 Xsotan in the sector for performance reasons
    local xsotanCt = ESCCUtil.countEntitiesByValue("is_xsotan")
    local maxXsotanCt = 25
    if xsotanCt + waveSize > maxXsotanCt then
        waveSize = maxXsotanCt - xsotanCt
    end

    --up to a 20% chance for a special and/or quantum xsotan inside the barrier - 10% outside.
    --10% chance for a summoner at danger level 10 regardless of inside or outside of barrier.
    local addSummoner = false
    local addQuantum = false
    local addSpecial = false

    local summoners = {_sector:getEntitiesByScript("enemies/summoner.lua")}
    if #summoners == 0 and mission.data.custom.dangerLevel == 10 and _random:test(0.1) then
        addSummoner = true
    end

    local quantumSpecialChance = 0.02 * mission.data.custom.dangerLevel
    if _random:test(quantumSpecialChance) then
        addQuantum = true
    end
    if _random:test(quantumSpecialChance) then
        addSpecial = true
    end

    if addSummoner then
        table.insert(xsotanByNameTable, "Summoner")
    end
    if addQuantum then
        table.insert(xsotanByNameTable, "Quantum")
    end
    if addSpecial then
        table.insert(xsotanByNameTable, "Special")
    end
    for _ = 1, waveSize - #xsotanByNameTable do
        table.insert(xsotanByNameTable, "Ship")
    end

    local dist = 1500
    for _, xsotanName in pairs(xsotanByNameTable) do
        local sizeFactor = 1 + random():getInt(mission.data.custom.minXsotanSizeBonus, mission.data.custom.maxXsotanSizeBonus)

        local nXsotan = nil
        if xsotanName == "Summoner" then
            nXsotan = Xsotan.createSummoner(secGenerator:getPositionInSector(dist), sizeFactor)
        elseif xsotanName == "Quantum" then
            nXsotan = Xsotan.createQuantum(secGenerator:getPositionInSector(dist), sizeFactor)
        elseif xsotanName == "Special" then
            local xsotanFunction = getRandomEntry(Xsotan.getSpecialXsotanFunctions())

            nXsotan = xsotanFunction(secGenerator:getPositionInSector(dist), sizeFactor)
        else
            nXsotan = Xsotan.createShip(secGenerator:getPositionInSector(dist), sizeFactor)
        end

        if nXsotan and valid(nXsotan) then
            local xsotanAI = ShipAI(nXsotan.id)

            for _, p in pairs(players) do
                xsotanAI:registerEnemyFaction(p.index)
            end

            xsotanAI:registerEnemyFaction(mission.data.custom.friendlyFaction)
            
            xsotanAI:setAggressive()

            table.insert(xsotanTable, nXsotan)
        end
    end

    SpawnUtility.addEnemyBuffs(xsotanTable)

    Placer.resolveIntersections(xsotanTable)
end

function theDig_doMissionEndCleanup()
    if mission.data.custom.threatType == 1 then --enemy faction
        local _MissionDoer = Player().craftFaction or Player()
        local _Faction = Faction(mission.data.custom.enemyFaction)
        local _FriendlyFaction = Faction(mission.data.custom.friendlyFaction)
        local _Galaxy = Galaxy()

        _Galaxy:setFactionRelations(_Faction, _FriendlyFaction, mission.data.custom.enemyRelationLevel2Giver)
        _Galaxy:setFactionRelationStatus(_Faction, _FriendlyFaction, mission.data.custom.enemyRelationStatus2Giver)
        _Galaxy:setFactionRelations(_Faction, _MissionDoer, mission.data.custom.enemyRelationLevel - 10000)
        _Galaxy:setFactionRelationStatus(_Faction, _MissionDoer, mission.data.custom.enemyRelationStatus)
    end

    theDig_minersDepart()
end

function theDig_spawnKickoutWave()
    local methodName = "Spawn Kickout Wave"
    mission.Log(methodName, "Starting")

    local _sector = Sector()
    local dist = 1500

    local secGenerator = SectorGenerator(_sector:getCoordinates())
    local players = {_sector:getPlayers()}

    if mission.data.custom.threatType == 1 then --1 = faction
        --can't do this async or the script is terminated before we make the ship.
        local enemyFaction = Faction(mission.data.custom.enemyFaction)

        local flagShip = ShipGenerator.createFlagShip(enemyFaction, secGenerator:getPositionInSector(dist))

        flagShip:addScriptOnce("ironcurtain.lua", { _Duration = math.huge })
        flagShip:addScriptOnce("avenger.lua", { _Multiplier = 1.5 })
        flagShip:addScriptOnce("warcountdown.lua")
        flagShip:setValue("_DefenseController_Manage_Own_Invincibility", true)

        mission.Log(methodName, "Adding defense controller")
        local defControlValues = {
            _DefenseLeader = flagShip.index,
            _DefenderCycleTime = 60,
            _DangerLevel = 10,
            _MaxDefenders = 12,
            _AllDefenderDamageScale = 2,
            _MaxDefendersSpawn = 6,
            _DefenderDistance = 1500,
            _LowTable = "High",
            _IsPirate = false,
            _Factionid = flagShip.factionIndex,
            _DefenderHPThreshold = 0.5,
            _DefenderOmicronThreshold = 0.5
        }
    
        _sector:addScriptOnce("sector/background/defensecontroller.lua", defControlValues)
    elseif mission.data.custom.threatType == 2 then --2 = pirates
        --can't do this async or the script is terminated before we make the ship.
        local motherShip = PirateGenerator.createScaledFlagship(PirateGenerator.getGenericPosition())

        motherShip:addScriptOnce("ironcurtain.lua", { _Duration = math.huge })
        motherShip:addScriptOnce("avenger.lua", { _Multiplier = 1.5 })
        motherShip:addScriptOnce("allybooster.lua")
        motherShip:setValue("_DefenseController_Manage_Own_Invincibility", true)

        mission.Log(methodName, "Adding defense controller")
        local x, y = _sector:getCoordinates()

        local defControlValues = {
            _DefenseLeader = motherShip.index,
            _DefenderCycleTime = 60,
            _DangerLevel = 10,
            _MaxDefenders = 12,
            _AllDefenderDamageScale = 2,
            _MaxDefendersSpawn = 6,
            _DefenderDistance = 1500,
            _LowTable = "High",
            _IsPirate = true,
            _Factionid = motherShip.factionIndex,
            _PirateLevel = Balancing_GetPirateLevel(x, y),
            _DefenderHPThreshold = 0.5,
            _DefenderOmicronThreshold = 0.5
        }
    
        _sector:addScriptOnce("sector/background/defensecontroller.lua", defControlValues)
    else --3 = xsotan
        local xParthenope = Xsotan.createParthenope(secGenerator:getPositionInSector(dist), nil)

        if xParthenope and valid(xParthenope) then
            local xsotanAI = ShipAI(xParthenope.id)

            for _, p in pairs(players) do
                xsotanAI:registerEnemyFaction(p.index)
            end

            xsotanAI:registerEnemyFaction(mission.data.custom.friendlyFaction)
            
            xsotanAI:setAggressive()
        end

        --the parthenope comes with avenger baked in.
        xParthenope:addScriptOnce("ironcurtain.lua", { _Duration = math.huge })
        xParthenope:setValue("xsotan_no_despawn", true)
    end

    mission.Log(methodName, "finished")
end

function theDig_failAndPunish()
    local methodName = "Fail and Punish"
    mission.Log(methodName, "Running lose condition.")

    punish()
    fail()
end

--endregion

--region #MAKEBULLETIN CALLS

function theDig_formatDescription(_Station, _ThreatType)
    local _Faction = Faction(_Station.factionIndex)
    local _Aggressive = _Faction:getTrait("aggressive")
    local threatIdx = 1
    if _ThreatType ~= 1 then
        threatIdx = 2
    end

    local descriptionType = 1 --Neutral
    if _Aggressive > 0.5 then
        descriptionType = 2 --Aggressive.
    elseif _Aggressive <= -0.5 then
        descriptionType = 3 --Peaceful.
    end

    local descriptionTable = {
        "We've received reports that some solar wind currents have blown a number of disparate asteroid belts into a converging course. We believe they'll meet in sector (${_X}:${_Y}). We're putting together a task force to take advantage of this, and we're looking for a captain to lead it. Protect our mining operation. We'll pay you for your efforts. You're also welcome to mine as much as you want.",
        "Some asteroid fields will be converging in sector (${_X}:${_Y}) on solar currents. We're getting ready to take advantage of this, but our military is engaged elsewhere and cannot respond. It displeases us to have to turn to an independent captain, but we have no other options. You will protect our miners - for compensation, of course. You may also mine the field - how magnanimous of us, yes?",
        "Peace be upon you, captain. We've received word that a few scattered belts of asteroids will be merging in sector (${_X}:${_Y}) due to the local solar winds. We're putting together a group of miners to harvest the bounty of resources, but our military is ill-suited for anything more than peacekeeping. We need your help. Please protect our miners. You are welcome to mine as well."
    }

    local descriptionThreatTable = {
        { "\n\nA nearby faction - ${enemyName} - has claimed the sector. Protect our ships from any aggression.", "\n\nWe're not sure what threats are out there. Proceed with caution." },
        { "\n\nA nearby faction - ${enemyName} - has claimed the sector. How laughable. Crush them if they dare attack.", "\n\nThe pirate and xsotan scum are always lurking. Crush them if they dare attack us." },
        { "\n\nA nearby faciton - ${enemyName} - has claimed to the sector. We fear a peaceful solution can't be found.", "\n\nWe don't know what threats are out there. Please keep our people safe." }
    }

    return descriptionTable[descriptionType] .. descriptionThreatTable[descriptionType][threatIdx]
end

function theDig_getThreatType(rand, station)
    local methodName = "Get Threat Type"

    local threatType = rand:getInt(1, 3) --1 = faction / 2 = pirates / 3 = xsotan

    local giverFaction = station.factionIndex
    local enemyFaction = nil
    local enemyFactionName = nil
    if threatType == 1 then
        local factionNeighbors = MissionUT.getNeighboringFactions(giverFaction, 125)
        shuffle(random(), factionNeighbors)

        if #factionNeighbors > 0 then
            enemyFaction = factionNeighbors[1].index
            enemyFactionName = factionNeighbors[1].name
            mission.Log(methodName, "The enemy faction is " .. tostring(enemyFactionName))
        else
            threatType = rand:getInt(1, 2) + 1 --pirates or xsotan.
        end
        if giverFaction == enemyFaction then
            threatType = rand:getInt(1, 2) + 1 --pirates or xsotan.
        end
    end

    mission.Log(methodName, "Final threat type is " .. tostring(threatType))

    return enemyFaction, enemyFactionName, threatType
end

mission.makeBulletin = function(_Station)
    local methodName = "Make Bulletin"
    --We don't need a specific type of sector here. Just an empty one that's on the same side of the barrier as the questgiver.
    local _Rgen = ESCCUtil.getRand()
    local target = {}
    local x, y = Sector():getCoordinates()
    local insideBarrier = MissionUT.checkSectorInsideBarrier(x, y)
    target.x, target.y = MissionUT.getEmptySector(x, y, 8, 16, insideBarrier)

    if not target.x or not target.y then
        mission.Log(methodName, "Target.x or Target.y not set - returning nil.")
        return 
    end

    local dangerLevel = _Rgen:getInt(1, 10)
    local enemyFaction, enemyFactionName, threatType = theDig_getThreatType(_Rgen, _Station)

    local _Description = theDig_formatDescription(_Station, threatType)

    local _Difficulty = "Средний"
    if threatType == 1 then
        _Difficulty = "Сложный"
    end
    if dangerLevel >= 5 then 
        _Difficulty = "Сложный"
        if threatType == 1 then --the faction defenders are powerful and can blow up miners quickly.
            _Difficulty = "Экстремальный"
        end
    end
    if dangerLevel == 10 then
        _Difficulty = "Экстремальный"
    end

    local baseReward = 52500
    if dangerLevel >= 5 then
        baseReward = baseReward + 7500
    end
    if dangerLevel == 10 then
        baseReward = baseReward + 7500
    end

    if threatType == 1 then --the faction version tends to be more difficult, even at danger 1.
        baseReward = baseReward * 1.5
    end

    if insideBarrier then
        baseReward = baseReward * 2
    end

    local baseRepReward = 1000 --Why is this so low? Becasue you get a ton of extra rep from killing the enemies w/ the miners active.

    reward = baseReward * Balancing.GetSectorRewardFactor(Sector():getCoordinates()) --SET REWARD HERE
    repReward = baseRepReward

    local bulletin =
    {
        -- data for the bulletin board
        brief = mission._Name,
        description = _Description,
        difficulty =  _Difficulty,
        reward = "¢${reward}",
        script = "missions/thedig.lua",
        formatArguments = {_X = target.x, _Y = target.y, reward = createMonetaryString(reward), enemyName = enemyFactionName},
        msg = "Thank you. Please meet our miners in sector \\s(%1%:%2%).",
        giverTitle = _Station.title,
        giverTitleArgs = _Station:getTitleArguments(),
        onAccept = [[
            local self, player = ...
            player:sendChatMessage(Entity(self.arguments[1].giver), 0, self.msg, self.formatArguments._X, self.formatArguments._Y)
        ]],

        -- data that's important for our own mission
        arguments = {{
            giver = _Station.index,
            location = target,
            reward = { credits = reward, relations = repReward, paymentMessage = "Earned %1% credits for defending the miners."},
            punishment = { relations = 16000 },
            dangerLevel = dangerLevel,
            threatType = threatType,
            enemyFaction = enemyFaction,
            initialDesc = _Description,
            inBarrier = insideBarrier
        }},
    }

    return bulletin
end

--endregion