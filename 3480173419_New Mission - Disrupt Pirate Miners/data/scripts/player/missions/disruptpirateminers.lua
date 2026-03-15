--[[
    DISRUPT PIRATE MINERS
    NOTES:
        - Wanted a mission where you could fight to collect resources.
    ADDITIONAL REQUIREMENTS TO DO THIS MISSION:
        - N/A
    ROUGH OUTLINE
        - Mining sector just like The Dig. Mission succeeds / fails after 30 minutes, regardless of other circumstances.
        - While the player is out of sector, spawn a miner every 2 minutes up to 5.
        - A pirate miner comes in every 2 1/2 minutes up to 5 max. So if the player doesn't show up for 10 minutes, there are 5 miners waiting there.
        - All miners already in the sector scatter and run as soon as the escort is blown up. All Miners run on taking damage.
        - Initial pirate escort squad is 6 ships.
        - 4 ships show up per miner
        - Ships get ~20% stronger per wave. You must kill at least 5 miners, and get a +10% bonus for each subsequent miner you kill.
        - Initial miners spawn with a higher resource amount, but new ones spawn with a significant amount too.
        - So the question is how soon do you want to get in there - the sooner you show up the more miners you might be able to get, but you will be fighting harder pirates.
        - If you show up later and well prepared, you can nail a bunch of miners and collect a load of resources.
    DANGER LEVEL
        1+ - Spawn table. Maybe they get stronger faster - +15% per wave @ level 1 and +25% per wave @ level 10
]]
package.path = package.path .. ";data/scripts/lib/?.lua"
package.path = package.path .. ";data/scripts/?.lua"
include("structuredmission")
include("goodsindex")

ESCCUtil = include("esccutil")

local Balancing = include ("galaxy")
local SectorGenerator = include ("SectorGenerator")
local AsyncPirateGenerator = include ("asyncpirategenerator")
local PirateGenerator = include("pirategenerator")
local CaptainGenerator = include("captaingenerator")
local AsyncShipGenerator = include("asyncshipgenerator")
local SpawnUtility = include ("spawnutility")
local Placer = include("placer")

mission._Debug = 0
mission._Name = "Разрушить пиратских шахтеров"

--region #INIT

--Standard mission data.
mission.data.brief = mission._Name
mission.data.title = mission._Name
mission.data.autoTrackMission = true
mission.data.description = {
    { text = "Вы получили следующий запрос от ${giverTitle} из ${sectorName}:" }, --Placeholder
    { text = "..." },
    { text = "Направляйтесь в сектор (${_X}:${_Y})", bulletPoint = true, fulfilled = false },
    { text = "Уничтожьте пиратских шахтеров", bulletPoint = true, fulfilled = false, visible = false },
    { text = "${_DESTROYED}/${_MAXTODESTROY} Уничтожено", bulletPoint = true, fulfilled = false, visible = false },
    { text = "Вы можете покинуть сектор в любое время, чтобы завершить миссию", bulletPoint = true, fulfilled = false, visible = false },
    { text = "(Необязательно) Продолжайте уничтожать шахтеров для получения более высокой награды", bulletPoint = true, fulfilled = false, visible = false }
}
mission.data.timeLimit = 25 * 60 --У игрока есть 25 минут на выполнение этой миссии.
mission.data.timeLimitInDescription = true --Показывать игроку, сколько времени осталось.

mission.data.accomplishMessage = "..."
mission.data.abandonMessage = "..."
mission.data.failMessage = "..."

mission.data.custom.objectiveTag = "_disruptpirateminers_objective"
mission.data.custom.escortTag = "_disruptpirateminers_escort"
mission.data.custom.initialMinerTag = "_disruptpirateminers_initialminer"
mission.data.custom.backgroundPirateScriptValue = "_disruptpirateminers_background_pirate"
mission.data.custom.danger9CustomMultiplier = 1.1
mission.data.custom.danger10CustomMultiplier = 1.25


local DisruptPirateMiners_init = initialize
function initialize(_Data_in, bulletin)
    local _MethodName = "initialize"
    mission.Log(_MethodName, "Beginning...")

    if onServer() and not _restoring then
        mission.Log(_MethodName, "Calling on server - dangerLevel : " .. tostring(_Data_in.dangerLevel))

        local _X, _Y = _Data_in.location.x, _Data_in.location.y

        local _Sector = Sector()
        local _Giver = Entity(_Data_in.giver)
        
        --Emergency breakout just in case the player somehow got this from a player faction.
        if _Giver.playerOrAllianceOwned then
            print("ERROR: Mission from player faction - aborting.")
            terminate()
            return
        end
        --[[=====================================================
            CUSTOM MISSION DATA SETUP:
        =========================================================]]
        mission.data.custom.dangerLevel = _Data_in.dangerLevel
        mission.data.custom.inBarrier = _Data_in.inBarrier
        mission.data.custom.timePassed = 0
        mission.data.custom.piratesSpawned = 0
        local targetToDestroy = 5
        local minerHealthBoost = 1
        local backgroundRespawnTime = 90
        local maxBackgroundPirates = 6
        local backgroundPirateWaveCount = 4
        if mission.data.custom.dangerLevel > 5 then
            targetToDestroy = targetToDestroy + 1
            minerHealthBoost = minerHealthBoost + 1
            maxBackgroundPirates = maxBackgroundPirates + 2
        end
        if mission.data.custom.dangerLevel == 10 then
            targetToDestroy = targetToDestroy + 2
            minerHealthBoost = minerHealthBoost + 2
            backgroundRespawnTime = backgroundRespawnTime - 30
            maxBackgroundPirates = maxBackgroundPirates + 4
            backgroundPirateWaveCount = backgroundPirateWaveCount + 1
        end
        mission.data.custom.targetToDestroy = targetToDestroy
        mission.data.custom.destroyed = 0
        mission.data.custom.pirateWavesSpawned = 0
        mission.data.custom.minerHealthBoost = minerHealthBoost
        mission.data.custom.backgroundRespawnTime = backgroundRespawnTime
        mission.data.custom.maxBackgroundPirates = maxBackgroundPirates
        mission.data.custom.backgroundPirateWaveCount = backgroundPirateWaveCount
        mission.data.custom.phase2BackgroundTimer = 0
        mission.data.custom.pirateMinersEscaped = 0
        mission.data.custom.noLootModulusFactor = 3

        --[[=====================================================
            MISSION DESCRIPTION SETUP:
        =========================================================]]
        mission.data.description[1].arguments = { sectorName = _Sector.name, giverTitle = _Giver.translatedTitle }
        mission.data.description[2].text = _Data_in.initialDesc
        mission.data.description[2].arguments = { _X = _X, _Y = _Y, enemyName = mission.data.custom.enemyName }
        mission.data.description[3].arguments = { _X = _X, _Y = _Y }
        mission.data.description[5].arguments = { _DESTROYED = mission.data.custom.destroyed, _MAXTODESTROY = mission.data.custom.targetToDestroy }

        mission.data.accomplishMessage = _Data_in.winMsg
        mission.data.failMessage = _Data_in.loseMsg
    end

    --Run vanilla init. Managers _restoring on its own.
    DisruptPirateMiners_init(_Data_in, bulletin)
end

--endregion

--region #PHASE CALLS

mission.globalPhase.noBossEncountersTargetSector = true

mission.globalPhase.onAbandon = function()
    if mission.data.location then
        runFullSectorCleanup(true)
    end
end

mission.globalPhase.onFail = function()
    if mission.data.location then
        runFullSectorCleanup(true)
    end
end

mission.globalPhase.onAccomplish = function()
    if mission.data.location then
        runFullSectorCleanup(true)
    end
end

mission.globalPhase.updateServer = function(timeStep)
    mission.data.custom.timePassed = mission.data.custom.timePassed + timeStep
end

mission.phases[1] = {}
mission.phases[1].showUpdateOnEnd = true
mission.phases[1].onTargetLocationEntered = function(x, y)
    mission.data.description[3].fulfilled = true
    mission.data.description[4].visible = true
    mission.data.description[5].visible = true

    if onServer() then
        disruptPirateMiners_spawnMiningSector(x, y)
        disruptPirateMiners_spawnInitialMiners()
        disruptPirateMiners_spawnInitialDefenders()
    end
end

mission.phases[1].onTargetLocationArrivalConfirmed = function(x, y)
    --add the scripts to all the miners again.
    local miners = { Sector():getEntitiesByScriptValue(mission.data.custom.initialMinerTag) }
    for _, miner in pairs(miners) do
        if not miner:hasScript("ai/mine.lua") then
            --For some reason, some miners AI goes kaboom. (I think this has something to do with the mining of the asteroid spawns), so we add it again if necessary.
            miner:addScriptOnce("ai/mine.lua")
        end
    end
    nextPhase()
end

mission.phases[2] = {}
mission.phases[2].timers = {}
mission.phases[2].sectorCallbacks = {}
mission.phases[2].onTargetLocationLeft = function(x, y)
    if mission.data.custom.destroyed >= mission.data.custom.targetToDestroy then
        accomplish()
    end
end

--Strictly speaking, this doesn't really make much sense to have, but the entire point of the mission is to collect ores and I don't like how
--difficult it is to find lost ores again after the chaos of the initial strike on the miners. I don't think that "finding loot that the pirates dropped"
--should be part of the challenge of the mission. Also you could just trivialize it with a carrier and the loot command anyways, sooooo...
mission.phases[2].onPreRenderHud = function()
    if atTargetLocation() then
        disruptPirateMiners_onMarkDroppedOres()
    end
end

mission.phases[2].updateTargetLocationServer = function(timeStep)
    mission.data.custom.phase2BackgroundTimer = mission.data.custom.phase2BackgroundTimer + timeStep

    if mission.data.custom.phase2BackgroundTimer >= mission.data.custom.backgroundRespawnTime then
        disruptPirateMiners_spawnBackgroundPirates()
        mission.data.custom.phase2BackgroundTimer = 0
    end
end

mission.phases[2].onEntityDestroyed = function(_ID, _LastDamageInflictor)
    local methodName = "Phase 2 on Entity Destroyed"
    --mission.Log(methodName, "Beginning...")
    local destroyedEntity = Entity(_ID)

    if destroyedEntity:getValue(mission.data.custom.initialMinerTag) then
        mission.Log(methodName, "Was an initial miner - invoking run away method in other miners.")
        local initialMiners = { Sector():getEntitiesByScriptValue(mission.data.custom.initialMinerTag) }
        for _, miner in pairs(initialMiners) do
            miner:invokeFunction("dpmminer.lua", "runAway")
        end
    end

    if destroyedEntity:getValue(mission.data.custom.objectiveTag) then
        mission.Log(methodName, "Was an objective.")
        mission.data.custom.destroyed = mission.data.custom.destroyed + 1
        mission.data.description[5].arguments = { _DESTROYED = mission.data.custom.destroyed, _MAXTODESTROY = mission.data.custom.targetToDestroy }

        if mission.data.custom.destroyed >= mission.data.custom.targetToDestroy then
            mission.data.description[6].visible = true
            mission.data.description[7].visible = true

            mission.internals.fulfilled = true --Succeed when time runs out. Will succeed earlier if we jump out.
        end

        mission.Log(methodName, "Number of miners destroyed " .. tostring(mission.data.custom.destroyed))
        sync()
    end
end

mission.phases[2].onAccomplish = function()
    local _MethodName = "Phase 2 On Accomplish"
    mission.Log(_MethodName, "Running win condition.")

    --Player is given a 11% bonus per miner killed. So killing 7 miners would give you a 77% bonus.
    local bonusFactor = 1 + (0.11 * mission.data.custom.destroyed)
    local noEscapeBonusFactor = 1

    mission.Log(_MethodName, "Bonus factor is " .. tostring(bonusFactor))

    if mission.data.custom.pirateMinersEscaped == 0 then
        noEscapeBonusFactor = 1.1
        mission.data.reward.paymentMessage = mission.data.reward.paymentMessage .. " This includes a bonus for no miners escaping."
    end

    mission.data.reward.credits = mission.data.reward.credits * bonusFactor * noEscapeBonusFactor

    reward()
end

mission.phases[2].onFail = function()
    punish()
end

--region #PHASE 2 CALLBACK CALLS

mission.phases[2].sectorCallbacks[1] = {
    name = "disruptPirateMiners_pirateMinerEscaped",
    func = function()
        local methodName = "Phase 2 Sector Callback 1"
        mission.Log(methodName, "Miner escaped.")
        mission.data.custom.pirateMinersEscaped = mission.data.custom.pirateMinersEscaped + 1
    end
}

--endregion

--region #PHASE 2 TIMERS

if onServer() then

mission.phases[2].timers[1] = {
    time = 120,
    callback = function()
        --Every 2 minutes, spawn a pirate wave. Spawn a pirate miner if there are less than 5.
        local methodName = "Phase 2 Timer 1 Callback"
        mission.Log(methodName, "Running.")

        if atTargetLocation() then
            disruptPirateMiners_spawnPirateWave()
        end
    end,
    repeating = true
}

end

--endregion

--endregion

--region #SERVER CALLS

function disruptPirateMiners_spawnMiningSector(x, y)
    local methodName = "Spawn Mining Sector"

    local generator = SectorGenerator(x, y)
    local _random = random()

    local poiMaxCt = math.max(math.floor(mission.data.custom.dangerLevel / 3), 1)
    if mission.data.custom.dangerLevel == 10 and _random:test(0.5) then
        poiMaxCt = poiMaxCt + 1
    end

    local numFields = _random:getInt(3, 5)

    for i = 1, numFields do
        local position = generator:createAsteroidField(0.025)
    end

    local numRichFields = _random:getInt(2, 3)
    local bigAsteroidCt = 0

    for _ = 1, numRichFields do
        local position = generator:createAsteroidField(0.015 * mission.data.custom.dangerLevel)
        if _random:test(0.5) and bigAsteroidCt < poiMaxCt then 
            generator:createBigAsteroid(position) 
            bigAsteroidCt = bigAsteroidCt + 1
        end
    end

    local numSmallFields = _random:getInt(8, 15)
    local stashCt = 0
    local stashChance = 0.015 * mission.data.custom.dangerLevel
    for i = 1, numSmallFields do
        local position = generator:createSmallAsteroidField(0.05)
        if _random:test(stashChance) and stashCt < poiMaxCt then 
            generator:createStash(position) 
            stashCt = stashCt + 1
        end
    end

    mission.data.custom.cleanUpSector = true

    Placer.resolveIntersections()
end

function disruptPirateMiners_spawnInitialMiners()
    local methodName = "Spawn Initial Miners"

    local minersToSpawn = math.min(math.ceil(mission.data.custom.timePassed / 90), 5)

    if minersToSpawn > 0 then
        mission.Log(methodName, tostring(mission.data.custom.timePassed) .. " seconds have passed, spawning " .. tostring(minersToSpawn) .. " miners.")

        --Getting the pirate faction to spawn non-pirate type ships (miners, etc.) is always a bit of a pain.
        local _sector = Sector()
        local x, y = _sector:getCoordinates()

        local pirateLevel = Balancing_GetPirateLevel(x, y)
        local pirateFaction = Galaxy():getPirateFaction(pirateLevel)

        local minerGenerator = AsyncShipGenerator(nil, disruptPirateMiners_onInitialPirateMinersFinished)

        minerGenerator:startBatch()

        for _ = 1, minersToSpawn do
            minerGenerator:createMiningShip(pirateFaction, minerGenerator:getGenericPosition())
        end

        minerGenerator:endBatch()
    end
end

function disruptPirateMiners_spawnInitialDefenders()
    local _PirateTable = ESCCUtil.getStandardWave(mission.data.custom.dangerLevel, 6, "Standard", false)
    local _CreatedPirateTable = {}

    for _, _Pirate in pairs(_PirateTable) do
        table.insert(_CreatedPirateTable, PirateGenerator.createPirateByName(_Pirate, PirateGenerator.getGenericPosition()))
    end

    for _, _Pirate in pairs(_CreatedPirateTable) do
        _Pirate:setValue(mission.data.custom.escortTag, true)
    end

    SpawnUtility.addEnemyBuffs(_CreatedPirateTable)

    Placer.resolveIntersections()
end

function disruptPirateMiners_spawnPirateWave()
    --Nothing too complicated. Just a standard wave of 4 pirates.
    local methodName = "Spawn Pirate Wave"
    mission.Log(methodName, "Beginning.")

    local waveCt = 4
    if mission.data.custom.destroyed >= 5 then
        local extraDestroyed = mission.data.custom.destroyed - 5 
        local bonusSpawns = math.floor(extraDestroyed / 2)

        mission.Log(methodName, "Adding " .. tostring(bonusSpawns) .. " bonus spawns.")
        waveCt = waveCt + bonusSpawns
    end

    local waveTable = ESCCUtil.getStandardWave(mission.data.custom.dangerLevel, waveCt, "Standard", false)

    local generator = AsyncPirateGenerator(nil, disruptPirateMiners_onPirateWaveFinished)

    generator:startBatch()

    local posCounter = 1
    local distance = 250 --_#DistAdj
    local pirate_positions = generator:getStandardPositions(#waveTable, distance)
    for _, p in pairs(waveTable) do
        generator:createScaledPirateByName(p, pirate_positions[posCounter])
        posCounter = posCounter + 1
    end

    generator:endBatch()

    local first_pirate_position = pirate_positions[1].position
    local _sector = Sector()
    local _random = random()

    local miners = {_sector:getEntitiesByScriptValue(mission.data.custom.objectiveTag)}
    if #miners < 5 then
        mission.Log(methodName, "Less than 5 miners detected and miner should spawn - spawning one in.")

        local look = _random:getVector(-100, 100)
        local up = _random:getVector(-100, 100)
        local minerPosition = ESCCUtil.getVectorAtDistance(first_pirate_position, 500, false)

        --Getting the pirate faction to spawn non-pirate type ships (miners, etc.) is always a bit of a pain.
        local x, y = _sector:getCoordinates()

        local pirateLevel = Balancing_GetPirateLevel(x, y)
        local pirateFaction = Galaxy():getPirateFaction(pirateLevel)

        local minerGenerator = AsyncShipGenerator(nil, disruptPirateMiners_onWavePirateMinerFinished)
        minerGenerator:createMiningShip(pirateFaction, MatrixLookUpPosition(look, up, minerPosition))
    end
end

function disruptPirateMiners_onPirateWaveFinished(generated)
    local methodName = "On Pirate Wave Finished"

    local waveBuffFactor = disruptPirateMiners_getWavePowerBonus()

    mission.Log(methodName, tostring(mission.data.custom.pirateWavesSpawned) .. " waves spawned. Wave buff factor is " .. tostring(waveBuffFactor))

    for idx, ship in pairs(generated) do
        ESCCUtil.multiplyOverallDurability(ship, waveBuffFactor)

        ship.damageMultiplier = (ship.damageMultiplier or 1) * waveBuffFactor

        ship:setValue(mission.data.custom.escortTag, true)

        --This is for performance reasons, so there aren't dozens and dozens of items scattered around the sector. This would be in addition to scrap and ore.
        local _PiratesSpawned = mission.data.custom.piratesSpawned + 1
        local _Factor = 2
        if _PiratesSpawned >= 20 then
            _Factor = mission.data.custom.noLootModulusFactor
        end
        if _PiratesSpawned % _Factor ~= 0 then
            ship:setDropsLoot(false)
        end
        mission.data.custom.piratesSpawned = _PiratesSpawned
    end

    SpawnUtility.addEnemyBuffs(generated)

    mission.data.custom.pirateWavesSpawned = (mission.data.custom.pirateWavesSpawned or 0) + 1 --Finally, increment wave counter.
end

function disruptPirateMiners_getWavePowerBonus()
    local perLevelPowerFactor = 0.25 + (mission.data.custom.dangerLevel * 0.025)

    if mission.data.custom.dangerLevel == 9 then
        perLevelPowerFactor = perLevelPowerFactor * mission.data.custom.danger9CustomMultiplier
    end
    if mission.data.custom.dangerLevel == 10 then
        perLevelPowerFactor = perLevelPowerFactor * mission.data.custom.danger10CustomMultiplier --Give 'em some extra power at 10.
    end

    local powerFactor = 1 + ((mission.data.custom.pirateWavesSpawned or 0) * perLevelPowerFactor)

    return powerFactor
end

function disruptPirateMiners_onInitialPirateMinersFinished(generated)
    disruptPirateMiners_onPirateMinersFinished(generated, 300, true)
end

function disruptPirateMiners_onWavePirateMinerFinished(generated)
    local generatedTable = { }
    if type(generated) == "userdata" then
        generatedTable = { generated}
    else
        genratedTable = generated
    end
    disruptPirateMiners_onPirateMinersFinished(generatedTable, 150, false)
end

function disruptPirateMiners_onPirateMinersFinished(generated, baseOreAmount, isInitialWave)
    local methodName = "On Pirate Miners Finished"

    local _sector = Sector()
    local _random = random()
    local x, y = _sector:getCoordinates()
    
    local rewardFactor = Balancing.GetSectorRewardFactor(_sector:getCoordinates())

    mission.Log(methodName, "Reward factor is " .. tostring(rewardFactor))

    local waveFactor = 1
    if not isInitialWave then
        local waveFactorPerLevel = 0.0125
        if mission.data.custom.dangerLevel == 9 then
            waveFactorPerLevel = 0.01875 --Average between 0.0125 and 0.025
        end
        if mission.data.custom.dangerLevel == 10 then
            waveFactorPerLevel = 0.025
        end

        waveFactor = waveFactor + (waveFactorPerLevel * mission.data.custom.pirateWavesSpawned)
    end
    local regionFactor = disruptPirateMiners_getRegionalLootBonus()

    local matlProbabilities = Balancing_GetMaterialProbability(x, y)
    local matlGoodsTable = {
        "Iron Ore",
        "Titanium Ore",
        "Naonite Ore",
        "Trinium Ore",
        "Xanion Ore",
        "Ogonite Ore",
        "Avorion Ore"
    }

    for idx, ship in pairs(generated) do
        --Get a random factor first.
        local randomFactor = _random:getFloat(0.9, 1.1)

        --Okay we need to do a bunch of stuff here.
        --Remove appropriate scripts / values
        ESCCUtil.removeCivilScripts(ship)

        --Add flat cargo space bonus
        ship:addAbsoluteBias(StatsBonuses.CargoHold, 15000)

        --Pick a random local material
        local matlIdx = selectByWeight(random(), matlProbabilities)
        if _random:test(0.5) then
            mission.Log(methodName, "Picking highest available matl")
            matlIdx = Balancing_GetHighestAvailableMaterial(x, y)
        end
        local matlGoodName = matlGoodsTable[matlIdx + 1]
        local matlGood = goods[matlGoodName]

        --Get ore amount based on base amount * the various factors, then add to ship. Always add 1000 flat.
        local oreAmount = baseOreAmount * mission.data.custom.dangerLevel * rewardFactor * randomFactor * waveFactor * regionFactor
        oreAmount = oreAmount + 1500
        oreAmount = math.ceil(oreAmount) --round up. We can be nice sometimes too :)

        mission.Log(methodName, "Adding " .. tostring(oreAmount) .. " " .. matlGoodName)

        ship:addCargo(matlGood:good(), oreAmount)

        --Add a captain so the mining script works
        local crewComponent = CrewComponent(ship)
        crewComponent:setCaptain(CaptainGenerator():generate())

        --Adjust durability
        local durabilityBonus = mission.data.custom.minerHealthBoost + (waveFactor * 2)

        mission.Log(methodName, "Adjusting durability by " .. tostring(durabilityBonus))

        ESCCUtil.multiplyOverallDurability(ship, durabilityBonus)

        --Add appropriate scripts / values (need the custom AI script for this mission)
        ship:setValue("is_pirate", true)
        ship:setValue("bDisableXAI", true)
        ship:setValue(mission.data.custom.objectiveTag, true)
        if isInitialWave then
            ship:setValue(mission.data.custom.initialMinerTag, true)
        end
        ship:addScript("ai/mine.lua")
        ship:addScript("ai/dpmminer.lua")
    end
end

function disruptPirateMiners_spawnBackgroundPirates()
    local methodName = "Spawn Background Pirates"
    mission.Log(methodName, "Running.")

    local backgroundPirateCt = ESCCUtil.countEntitiesByValue(mission.data.custom.backgroundPirateScriptValue)
    if backgroundPirateCt < mission.data.custom.maxBackgroundPirates then
        local piratesToSpawn = mission.data.custom.maxBackgroundPirates - backgroundPirateCt
        piratesToSpawn = math.min(piratesToSpawn, mission.data.custom.backgroundPirateWaveCount) --cap at mission value. max is 5 @ danger 10.

        mission.Log(methodName, "Spawning " .. tostring(piratesToSpawn) .. " pirates.")

        local spawnTable = ESCCUtil.getStandardWave(mission.data.custom.dangerLevel, piratesToSpawn, "Low", false)

        local generator = AsyncPirateGenerator(nil, disruptPirateMiners_onBackgroundPiratesFinished)
    
        generator:startBatch()
    
        local distance = 250 --_#DistAdj
        local pirate_positions = generator:getStandardPositions(piratesToSpawn, distance)
        for idx, p in pairs(spawnTable) do
            generator:createScaledPirateByName(p, pirate_positions[idx])
        end
    
        generator:endBatch()
    end
end

function disruptPirateMiners_onBackgroundPiratesFinished(generated)
    local methodName = "On Background Pirate Wave Finished"
    mission.Log(methodName, "Running.")

    local waveBuffFactor = disruptPirateMiners_getWavePowerBonus()

    for idx, ship in pairs(generated) do
        ESCCUtil.multiplyOverallDurability(ship, waveBuffFactor)

        ship.damageMultiplier = (ship.damageMultiplier or 1) * waveBuffFactor

        ship:setValue(mission.data.custom.backgroundPirateScriptValue, true)
        ship:setDropsLoot(false)
    end

    SpawnUtility.addEnemyBuffs(generated)
end

function disruptPirateMiners_getRegionalLootBonus()
    local bonus = 1.0

    local x, y = Sector():getCoordinates()
    local dist = length(vec2(x, y))

    if dist <= 215 then
        bonus = 1.25
    end
    if mission.data.custom.inBarrier then
        bonus = 2.0
    end

    return bonus
end

--endregion

--region #CLIENT CALLS

function disruptPirateMiners_onMarkDroppedOres()
    local methodName = "On Mark Dropped Ores"

    local _player = Player()
    if not _player then
        return
    end
    if _player.state == PlayerStateType.BuildCraft or _player.state == PlayerStateType.BuildTurret or _player.state == PlayerStateType.PhotoMode then
        return
    end

    local _sector = Sector()
    local renderer = UIRenderer()

    for _, entity in pairs({_sector:getEntitiesByComponent(ComponentType.CargoLoot)}) do
        local loot = CargoLoot(entity)
        if valid(entity) then
            local indicator = TargetIndicator(entity)
            indicator.visuals = TargetIndicatorVisuals.Tilted
            local color = nil

            if loot:matches("Iron Ore") then
                color = Material(MaterialType.Iron).color
            end

            if loot:matches("Titanium Ore") then
                color = Material(MaterialType.Titanium).color
            end

            if loot:matches("Naonite Ore") then
                color = Material(MaterialType.Naonite).color
            end

            if loot:matches("Trinium Ore") then
                color = Material(MaterialType.Trinium).color
            end

            if loot:matches("Xanion Ore") then
                color = Material(MaterialType.Xanion).color
            end

            if loot:matches("Ogonite Ore") then
                color = Material(MaterialType.Ogonite).color
            end

            if loot:matches("Avorion Ore") then
                color = Material(MaterialType.Avorion).color
            end

            if color then
                indicator.color = color
                renderer:renderTargetIndicator(indicator)
            end
        end
    end

    renderer:display()
end

--endregion

--region #MAKEBULLETIN CALLS
function disruptPirateMiners_formatWinMessage(_Station)
    local _Faction = Faction(_Station.factionIndex)
    local _Aggressive = _Faction:getTrait("aggressive")
    local _MsgType = 1 --1 = Neutral / 2 = Aggressive / 3 = Peaceful

    if _Aggressive > 0.5 then
        _MsgType = 2
    elseif _Aggressive <= -0.5 then
        _MsgType = 3
    end

    local _Msgs = 
    { 
        "Спасибо за то, что разобрались с этими шахтерами. Вот ваша награда, как и было обещано.", --Neutral
        "Спасибо, что избавили нас от этого отребья. Мы перевели награду на ваш счет.", --Aggressive
        "Спасибо за ваши хлопоты. Мы перевели награду на ваш счет." --Peaceful
    }

    return _Msgs[_MsgType]
end

function disruptPirateMiners_formatLoseMessage(_Station)
    local _Faction = Faction(_Station.factionIndex)
    local _Aggressive = _Faction:getTrait("aggressive")
    local _MsgType = 1 --1 = Neutral / 2 = Aggressive / 3 = Peaceful

    if _Aggressive > 0.5 then
        _MsgType = 2
    elseif _Aggressive <= -0.5 then
        _MsgType = 3
    end

    local _Msgs = {
        "Мы видим, что вы не смогли уничтожить достаточно шахтеров вовремя. Это печально... они распространятся как чума с такой скоростью.", --Neutral
        "Тьфу. Полагаться на независимых капитанов было ошибкой. Нам придется оттянуть часть наших сил, чтобы разобраться с этим.", --Aggressive
        "Вы не смогли победить шахтеров? Это плохо. Наша оборона и так была растянута, а с пиратами, оставшимися без контроля..." --Peaceful
    }

    return _Msgs[_MsgType]
end

function disruptPirateMiners_formatDescription(_Station)
    local _Faction = Faction(_Station.factionIndex)
    local _Aggressive = _Faction:getTrait("aggressive")

    local descriptionType = 1 --Neutral
    if _Aggressive > 0.5 then
        descriptionType = 2 --Aggressive.
    elseif _Aggressive <= -0.5 then
        descriptionType = 3 --Peaceful.
    end

    local descriptionTable = {
        "Мы обнаружили группу пиратов, ведущих незаконную добычу полезных ископаемых на нашей территории. Мы не можем этого допустить, иначе больше пиратов получат сигнал о том, что они могут воспользоваться нами. Вы найдете их в (${_X}:${_Y}). Пожалуйста, ликвидируйте их незаконную деятельность. Мы заплатим вам награду за каждого уничтоженного шахтера.", --Neutral
        "Какие-то пиратские отбросы ведут добычу полезных ископаемых в близлежащем поясе астероидов. Убейте их и дайте им понять, что мы не потерпим их присутствия в наших секторах. Мы заплатим вам больше за каждого уничтоженного шахтера. За дело, капитан - вы найдете их в (${_X}:${_Y}). Отправляйтесь туда и начните резню.", --Aggressive
        "Приветствуем вас, капитан. Мы получили известие о группе пиратов, ведущих несанкционированную добычу полезных ископаемых в (${_X}:${_Y}). Если мы позволим им набраться сил, мы, возможно, не сможем их остановить. Пожалуйста... сообщите им, что добыча полезных ископаемых там запрещена. Мы заплатим вам за каждого их шахтера, которого вы прогоните." --Peaceful
    }

    return descriptionTable[descriptionType]
end
mission.makeBulletin = function(_Station)
    local methodName = "Make Bulletin"

    --We don't need a specific type of sector here. Just an empty one that's on the same side of the barrier as the questgiver.
    local _sector = Sector()
    local _Rgen = ESCCUtil.getRand()
    local target = {}
    local x, y = _sector:getCoordinates()
    local insideBarrier = MissionUT.checkSectorInsideBarrier(x, y)
    target.x, target.y = MissionUT.getEmptySector(x, y, 8, 16, insideBarrier)

    if not target.x or not target.y then
        mission.Log(methodName, "Target.x or Target.y not set - returning nil.")
        return 
    end

    local dangerLevel = _Rgen:getInt(1, 10)

    local _Difficulty = "Средний"
    if dangerLevel >= 5 then
        _Difficulty = "Сложный"
    end
    if dangerLevel == 10 then
        _Difficulty = "Экстремальный"
    end
    
    local _Description = disruptPirateMiners_formatDescription(_Station)
    local _WinMsg = disruptPirateMiners_formatWinMessage(_Station)
    local _LoseMsg = disruptPirateMiners_formatLoseMessage(_Station)

    local baseReward = 32500
    if dangerLevel >= 5 then
        baseReward = baseReward + 5000
    end
    if dangerLevel == 10 then
        baseReward = baseReward + 7500
    end

    if insideBarrier then
        baseReward = baseReward * 2
    end

    local baseRepReward = 6000
    if dangerLevel == 10 then
        baseRepReward = 8000
    end

    reward = baseReward * Balancing.GetSectorRewardFactor(_sector:getCoordinates()) --SET REWARD HERE
    repReward = baseRepReward

    local bulletin =
    {
        -- data for the bulletin board
        brief = mission._Name,
        description = _Description,
        difficulty =  _Difficulty,
        reward = "¢${reward}",
        script = "missions/disruptpirateminers.lua",
        formatArguments = {_X = target.x, _Y = target.y, reward = createMonetaryString(reward)},
        msg = "Спасибо. Незаконная добыча полезных ископаемых ведется в секторе \\s(%1%:%2%). Пожалуйста, устраните ее.",
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
            reward = { credits = reward, relations = repReward, paymentMessage = "Заработано %1% кредитов за уничтожение пиратских шахтеров."},
            punishment = { relations = 4000 },
            dangerLevel = dangerLevel,
            initialDesc = _Description,
            winMsg = _WinMsg,
            loseMsg = _LoseMsg,
            inBarrier = insideBarrier
        }},
    }

    return bulletin
end

--endregion
