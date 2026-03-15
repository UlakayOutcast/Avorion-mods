--[[
    MISSION 2: Swordfish
]]
package.path = package.path .. ";data/scripts/lib/?.lua"
package.path = package.path .. ";data/scripts/?.lua"

include("callable")
include("structuredmission")

ESCCUtil = include("esccutil")
HorizonUtil = include("horizonutil")

local SectorGenerator = include ("SectorGenerator")
local PirateGenerator = include("pirategenerator")
local AsyncPirateGenerator = include ("asyncpirategenerator")
local AsyncShipGenerator = include ("asyncshipgenerator")
local ShipGenerator = include("shipgenerator")
local Balancing = include ("galaxy")
local SpawnUtility = include ("spawnutility")
local ShipUtility = include("shiputility")
local Placer = include("placer")

mission._Debug = 0
mission._Name = "Меч-рыба"

--region #INIT / DATA

--Standard mission data.
mission.data.brief = mission._Name
mission.data.title = mission._Name
mission.data.autoTrackMission = true
mission.data.icon = "data/textures/icons/snowflake-2.png"
mission.data.priority = 9
mission.data.description = {
    { text = "После победы над пиратами вы нашли зашифрованный чип данных. Варланс сказал, что знает кого-то, кто может его взломать, но сначала вам придется их найти..." },
    { text = "Прочитать письмо Варланса", bulletPoint = true, fulfilled = false },
    { text = "Отправляйтесь в сектор (${_X}:${_Y})", bulletPoint = true, fulfilled = false, visible = false },
    { text = "Поговорите с хакером в убежище контрабандистов", bulletPoint = true, fulfilled = false, visible = false },
    { text = "Выполняйте задания в секторе - поговорите с хакером, чтобы узнать, что нужно сделать", bulletPoint = true, fulfilled = false, visible = false },
    { text = "(Необязательно) Заберите отмеченный контейнер", bulletPoint = true, fulfilled = false, visible = false },
    { text = "(Необязательно) Разверните спутник", bulletPoint = true, fulfilled = false, visible = false },
    { text = "(Необязательно) Уничтожьте астероиды", bulletPoint = true, fulfilled = false, visible = false },
    { text = "Уговорите хакера помочь вам", bulletPoint = true, fulfilled = false, visible = false },
    { text = "Заберите артефакт из убежища", bulletPoint = true, fulfilled = false, visible = false },
    { text = "Доставьте артефакт в (${_X}:${_Y})", bulletPoint = true, fulfilled = false, visible = false },
    { text = "Убейте атакующих пиратов", bulletPoint = true, fulfilled = false, visible = false },
    { text = "Вернитесь в (${_X}:${_Y}) и поговорите с Мейсом", bulletPoint = true, fulfilled = false, visible = false }
}

--Custom data that we'll want.
mission.data.custom.dangerLevel = 10 --Key everything off of danger 10.
mission.data.custom.annoyedHacker = 0
mission.data.custom.doneContainerJob = false
mission.data.custom.doneSatelliteJob = false 
mission.data.custom.destroyAsteroidJob = false
mission.data.custom.threeJobsDone = false
mission.data.custom.ambushPiratesSpawned = false

--endregion

--region #PHASE CALLS

mission.globalPhase.noBossEncountersTargetSector = true

mission.globalPhase.onAbandon = function()
    if mission.data.location then
        if atTargetLocation() then
            ESCCUtil.allPiratesDepart()
        end
        runFullSectorCleanup(true)
    end
end

mission.globalPhase.onFail = function()
    if mission.data.location then
        if atTargetLocation() then
            ESCCUtil.allPiratesDepart()
        end
        runFullSectorCleanup(true)
    end
end

mission.globalPhase.onAccomplish = function()
    if mission.data.location then
        if atTargetLocation() then
            ESCCUtil.allPiratesDepart()
        end
        runFullSectorCleanup(true)
    end
end

mission.phases[1] = {}
mission.phases[1].showUpdateOnEnd = true
mission.phases[1].onBeginServer = function()
    local _MethodName = "Phase 1 On Begin Server"
    --Get a sector that's very close to the outer edge of the barrier.
    mission.Log(_MethodName, "BlockRingMax is " .. tostring(Balancing.BlockRingMax))

    mission.data.custom.hackerSector = kothStory2_getNextLocation(true)

    local _X = mission.data.custom.hackerSector.x
    local _Y = mission.data.custom.hackerSector.y

    mission.data.description[3].arguments = { _X = mission.data.custom.hackerSector.x, _Y = mission.data.custom.hackerSector.y }
    mission.data.description[13].arguments = { _X = mission.data.custom.hackerSector.x, _Y = mission.data.custom.hackerSector.y }

    --Send mail to player.
    local _player = Player()
    local _Mail = Mail()
	_Mail.text = Format("Привет, капитан.\n\nЭто я, Варланс - твой старый приятель со времен разгрома пиратского флота. Я бы с удовольствием наверстал упущенное, но сразу перейду к делу. Нашел хакера, о котором упоминал на днях.\nОни в последнее время проводят время в местном контрабандистском форпосте. Вы найдете его в (%1%:%2%). Я встречусь с вами там.\n\nВарланс @FrostbiteCompany", _X, _Y)
	_Mail.header = "Нашел хакера"
	_Mail.sender = "Варланс @FrostbiteCompany"
	_Mail.id = "_horizon_story2_mail1"
	_player:addMail(_Mail)
end

mission.phases[1].playerCallbacks = 
{
	{
		name = "onMailRead",
		func = function(_playerIndex, _MailIndex)
			if onServer() then
				local _player = Player()
				local _Mail = _player:getMail(_MailIndex)
				if _Mail.id == "_horizon_story2_mail1" then
					nextPhase()
				end
			end
		end
	}
}

mission.phases[2] = {}
mission.phases[2].showUpdateOnEnd = true
mission.phases[2].onBegin = function()
    local _MethodName = "Phase 2 On Begin"
    mission.Log(_MethodName, "Beginning...")

    mission.data.location = mission.data.custom.hackerSector

    mission.data.description[2].fulfilled = true
    mission.data.description[3].visible = true
end

mission.phases[2].onTargetLocationEntered = function(_X, _Y)
    local _MethodName = "Phase 2 on Target Location Entered"
    mission.Log(_MethodName, "Beginning...")
    if onServer() then
        --Simulate a smuggler outpost. We can delete all of this once the player leaves the 2nd time.
        mission.data.custom.deliverToSector = kothStory2_getNextLocation(false)
        mission.data.description[11].arguments = { _X = mission.data.custom.deliverToSector.x, _Y = mission.data.custom.deliverToSector.y }
        kothStory2_buildSmugglerSector(_X, _Y)
        kothStory2_spawnVarlance()
        sync()
    end
end

mission.phases[2].onTargetLocationArrivalConfirmed = function(_X, _Y)
    HorizonUtil.varlanceChatter("Вот он. Подойдите поближе, и вы сможете связаться. Я дам вам частоту.")
    nextPhase()
end

mission.phases[3] = {}
mission.phases[3].showUpdateOnEnd = true
mission.phases[3].onBegin = function()
    local _MethodName = "Phase 3 On Begin"
    mission.Log(_MethodName, "Beginning...")

    mission.data.description[3].fulfilled = true
    mission.data.description[4].visible = true
end

mission.phases[3].onBeginServer = function()
    --We need to figure out a few important values here - first of all, how many asteroids to blow up.
    --Second, the container to fetch.
    local _Sector = Sector()

    mission.data.custom.asteroidCount = #{ _Sector:getEntitiesByType(EntityType.Asteroid) }

    local _Containers = { _Sector:getEntitiesByType(EntityType.Container) }
    shuffle(random(), _Containers)

    mission.data.custom.targetContainer = _Containers[1].id
end

local kothStory2_onPhase3DialogEnd = makeDialogServerCallback("kothStory2_onPhase3DialogEnd", 3, function()
    nextPhase()
end)

mission.phases[4] = {}
mission.phases[4].showUpdateOnEnd = true
mission.phases[4].onBegin = function()
    local _MethodName = "Phase 4 On Begin"
    mission.Log(_MethodName, "Beginning...")

    mission.data.description[4].fulfilled = true
    mission.data.description[5].visible = true
end

mission.phases[4].onBeginServer = function()
    local _SmugglerOutpost = Entity(mission.data.custom.smugglerOutpostid)
    _SmugglerOutpost:removeScript("player/missions/horizon/story2/horizonstory2dialog1.lua")
    _SmugglerOutpost:addScriptOnce("player/missions/horizon/story2/horizonstory2dialog2.lua")

    local _Varlance = Entity(mission.data.custom.varlanceID)
    _Varlance:invokeFunction("torpedoslammer.lua", "resetTimeToActive", 0)
end

mission.phases[5] = {}
mission.phases[5].timers = {}
mission.phases[5].showUpdateOnEnd = true
mission.phases[5].onBegin = function()
    local _MethodName = "Phase 5 On Begin"
    mission.Log(_MethodName, "Beginning...")

    mission.data.description[6].visible = true
    mission.data.description[7].visible = true
    mission.data.description[8].visible = true
    mission.data.description[9].visible = true
end

mission.phases[5].onBeginServer = function()
    local _dX = mission.data.custom.deliverToSector.x --_deliverX / _deliveryY
    local _dY = mission.data.custom.deliverToSector.y
    local _SmugglerOutpost = Entity(mission.data.custom.smugglerOutpostid)
    _SmugglerOutpost:removeScript("player/missions/horizon/story2/horizonstory2dialog2.lua")
    _SmugglerOutpost:addScriptOnce("player/missions/horizon/story2/horizonstory2dialog3.lua", _dX, _dY)

    --Give the player the satellite package.
    local item = UsableInventoryItem("horizon2satellitepkg.lua", Rarity(RarityType.Exceptional))
    Player():getInventory():add(item, true)
end

mission.phases[5].onPreRenderHud = function()
    if not mission.data.custom.doneContainerJob and mission.data.custom.targetContainer then
        
        local player = Player()
        if not player then return end
        if player.state == PlayerStateType.BuildCraft or player.state == PlayerStateType.BuildTurret then return end

        local renderer = UIRenderer()

        local _TargetContainer = Entity(mission.data.custom.targetContainer)

        if not _TargetContainer or not valid(_TargetContainer) then
            --Be careful about enabling this - it will spam like crazy.
            --mission.Log(_MethodName, "WARNING - Target container not valid entity.")
            return 
        else
            local _ContainerMarkOrange = ESCCUtil.getSaneColor(255, 173, 0)

            renderer:renderEntityTargeter(_TargetContainer, _ContainerMarkOrange)
            renderer:renderEntityArrow(_TargetContainer, 30, 10, 250, _ContainerMarkOrange)
        end

        renderer:display()
    end
end

--region #PHASE 5 TIMER CALLS

if onServer() then

mission.phases[5].timers[1] = { --Check asteroid job.
    time = 10,
    callback = function()
        local _MethodName = "Phase 5 Timer 1 Callback"
        local _Sector = Sector()
        if atTargetLocation() and not mission.data.custom.destroyAsteroidJob then
            local _AsteroidCt = #{ _Sector:getEntitiesByType(EntityType.Asteroid) }
            local _TargetAsteroidNumber = math.floor(mission.data.custom.asteroidCount * 0.95)

            if _AsteroidCt <= _TargetAsteroidNumber then
                mission.Log(_MethodName, "Asteroid job done.")

                local _SmugglerOutpost = Entity(mission.data.custom.smugglerOutpostid)
                _SmugglerOutpost:setValue("horizon2_asteroidjob_done", true)
                _SmugglerOutpost:setValue("horizon2_job_done", true)

                mission.data.description[8].fulfilled = true
                mission.data.custom.destroyAsteroidJob = true
                sync()

                kothStory2_spawnLocalTransport()
            end
        end
    end,
    repeating = true
}

mission.phases[5].timers[2] = { --Check satellite job
    time = 10,
    callback = function()
        local _MethodName = "Phase 5 Timer 2 Callback"
        local _Sector = Sector()
        if atTargetLocation() and not mission.data.custom.doneSatelliteJob then
            local _Satellites = { _Sector:getEntitiesByScriptValue("horizon2_research_satellite") }

            if #_Satellites > 0 then
                local _Satellite = _Satellites[1]

                local _SmugglerOutpost = Entity(mission.data.custom.smugglerOutpostid)
    
                local _Dist = _SmugglerOutpost:getNearestDistance(_Satellite)
    
                if _Dist > 5000 then
                    mission.Log(_MethodName, "Satellite job done.")

                    local _SmugglerOutpost = Entity(mission.data.custom.smugglerOutpostid)
                    _SmugglerOutpost:setValue("horizon2_satellitejob_done", true)
                    _SmugglerOutpost:setValue("horizon2_job_done", true)

                    mission.data.description[7].fulfilled = true
                    mission.data.custom.doneSatelliteJob = true
                    sync()

                    invokeClientFunction(Player(), "kothStory2_onPhase5StationDialog", mission.data.custom.smugglerOutpostid)
                end
            end
        end
    end,
    repeating = true
}

mission.phases[5].timers[3] = { --Check container job
    time = 10,
    callback = function()
        local _MethodName = "Phase 5 Timer 3 Callback"
        local _Sector = Sector()

        --If the player somehow destroys all the containers in the sector, fail. Otherwise, we just pick a new one.
        if atTargetLocation() and not mission.data.custom.doneContainerJob then
            local _Container = Entity(mission.data.custom.targetContainer)

            if not _Container or not valid(_Container) then
                local _Containers = { _Sector:getEntitiesByType(EntityType.Container) }

                if #_Containers > 0 then
                    shuffle(random(), _Containers)
            
                    mission.data.custom.targetContainer = _Containers[1].id
                    sync()
                else
                    fail()
                end
            else
                local _SmugglerOutpost = Entity(mission.data.custom.smugglerOutpostid)

                local _Dist = _SmugglerOutpost:getNearestDistance(_Container)

                if _Dist < 300 then
                    mission.Log(_MethodName, "Container job done.")

                    local _SmugglerOutpost = Entity(mission.data.custom.smugglerOutpostid)
                    _SmugglerOutpost:setValue("horizon2_containerjob_done", true)
                    _SmugglerOutpost:setValue("horizon2_job_done", true)

                    mission.data.description[6].fulfilled = true
                    mission.data.custom.doneContainerJob = true
                    sync()

                    local _SmugglerDefenders = { _Sector:getEntitiesByScriptValue("horizon2_smuggler_defender") }
                    if #_SmugglerDefenders > 0 then
                        shuffle(random(), _SmugglerDefenders)
                        invokeClientFunction(Player(), "kothStory2_onPhase5DefenderDialog",  _SmugglerDefenders[1].id)
                    else
                        kothStory2_spawnContainerJobDefender()
                    end
                end
            end
            
        end
    end,
    repeating = true
}

mission.phases[5].timers[4] = { --all three sub-jobs.
    time = 10,
    callback = function()
        if not mission.data.custom.threeJobsDone then
            if mission.data.custom.doneContainerJob and mission.data.custom.doneSatelliteJob and mission.data.custom.destroyAsteroidJob then
                mission.data.description[5].fulfilled = true
                mission.data.custom.threeJobsDone = true
                sync()
            end
        end
    end,
    repeating = true
}

end

--endregion

mission.phases[6] = {}
mission.phases[6].showUpdateOnEnd = true
mission.phases[6].onBegin = function()
    local _MethodName = "Phase 6 On Begin"
    mission.Log(_MethodName, "Beginning...")

    mission.data.description[5].fulfilled = true
    mission.data.description[6].fulfilled = true
    mission.data.description[7].fulfilled = true
    mission.data.description[8].fulfilled = true
    mission.data.description[9].fulfilled = true
    mission.data.description[10].visible = true
end

mission.phases[6].onBeginServer = function()
    local _MethodName = "Phase 6 On Begin Server"
    mission.Log(_MethodName, "Beginning...")

    local _SmugglerOutpost = Entity(mission.data.custom.smugglerOutpostid)
    _SmugglerOutpost:removeScript("player/missions/horizon/story2/horizonstory2dialog3.lua")
    _SmugglerOutpost:addScriptOnce("player/missions/horizon/story2/horizonstory2dialog4.lua")
end

mission.phases[6].updateServer = function()
    local _player = Player()
    local _Ship = Entity(_player.craftIndex)

    if _Ship then
        for good, amount in pairs(_Ship:findCargos("Ancient Artifact")) do
            if amount > 0 then
                nextPhase()
                break
            end
        end
    end
end

mission.phases[7] = {}
mission.phases[7].timers = {}
mission.phases[7].showUpdateOnEnd = true
mission.phases[7].onBegin  = function()
    local _MethodName = "Phase 7 On Begin"
    mission.Log(_MethodName, "Beginning...")

    mission.data.location = mission.data.custom.deliverToSector

    mission.data.description[10].fulfilled = true
    mission.data.description[11].visible = true
end

mission.phases[7].onBeginServer = function()
    local _MethodName = "Phase 7 On Begin Server"
    mission.Log(_MethodName, "Beginning...")

    local _SmugglerOutpost = Entity(mission.data.custom.smugglerOutpostid)
    _SmugglerOutpost:removeScript("player/missions/horizon/story2/horizonstory2dialog4.lua")
end

mission.phases[7].onTargetLocationEntered = function(_X, _Y)
    local _MethodName = "Phase 7 on Target Location Entered"
    mission.Log(_MethodName, "Beginning...")
    mission.data.description[11].fulfilled = true

    if onServer() then
        kothStory2_buildPirateAmbushSector()
    end
end

mission.phases[7].onTargetLocationLeft = function()
    mission.data.custom.ambushPiratesSpawned = false
end

mission.phases[7].onTargetLocationArrivalConfirmed = function(_X, _Y)
    --Get the player's current ship.
    local _player = Player()
    local _Ship = Entity(_player.craftIndex)

    --Then get the pirates.
    local _Pirates = { Sector():getEntitiesByScriptValue("is_pirate") }

    local _HasArtifact = false
    if _Ship then
        for good, amount in pairs(_Ship:findCargos("Ancient Artifact")) do
            if amount > 0 then
                _HasArtifact = true
                break
            end
        end
    end

    if _HasArtifact then
        invokeClientFunction(_player, "kothStory2_onPhase7PirateDialog", _Pirates[1].id)
    else
        invokeClientFunction(_player, "kothStory2_onPhase7PirateNoArtifactDialog", _Pirates[1].id)
    end
end

local onPhase7TakeArtifact = makeDialogServerCallback("onPhase7TakeArtifact", 7, function()
    --Get the player's current ship.
    local _player = Player()
    local _Ship = Entity(_player.craftIndex)

    if _Ship then
        for good, amount in pairs(_Ship:findCargos("Ancient Artifact")) do
            if amount > 0 then
                _Ship:removeCargo(good, amount)
                break
            end
        end
    end
end)

local onPhase7DialogFinish = makeDialogServerCallback("onPhase7DialogFinish", 7, function()
    mission.data.description[12].visible = true
    

    local _Pirates = { Sector():getEntitiesByScriptValue("is_pirate") }
    for _, _Pirate in pairs (_Pirates) do
        local ai = ShipAI(_Pirate)
        ai:clearFriendFactions()
    end

    sync()
end) 
--region #ВЫЗОВЫ ТАЙМЕРОВ ФАЗЫ 7

if onServer() then

mission.phases[7].timers[1] = {
    time = 10,
    callback = function()
        local _MethodName = "Обратный вызов таймера 1 фазы 7"

        local _PirateCt = ESCCUtil.countEntitiesByValue("is_pirate")

        if atTargetLocation() and _PirateCt <= 5 and not mission.data.custom.ambushPiratesSpawned then
            kothStory2_spawnPirateAmbush()
        end
    end,
    repeating = true
}

mission.phases[7].timers[2] = {
    time = 10,
    callback = function()
        local _MethodName = "Обратный вызов таймера 2 фазы 7"

        local _PirateCt = ESCCUtil.countEntitiesByValue("is_pirate")

        if atTargetLocation() and _PirateCt == 0 and mission.data.custom.ambushPiratesSpawned then
            nextPhase()
        end
    end,
    repeating = true
}

end
    
--endregion

mission.phases[8] = {}
mission.phases[8].timers = {}
mission.phases[8].onBegin = function()
    local _MethodName = "Начало фазы 8"
    mission.Log(_MethodName, "Начинается...")

    mission.data.location = mission.data.custom.hackerSector

    mission.data.description[12].fulfilled = true
    mission.data.description[13].visible = true
end

mission.phases[8].onTargetLocationEntered = function(_X, _Y)
    local _MethodName = "Фаза 8 при входе в целевую локацию"
    mission.Log(_MethodName, "Начинается...")

    if onServer() then
        local _SmugglerOutpost = Entity(mission.data.custom.smugglerOutpostid)
        _SmugglerOutpost:addScriptOnce("player/missions/horizon/story2/horizonstory2dialog5.lua")
    end
end

mission.phases[8].onSectorArrivalConfirmed = function(_X, _Y)
    if onServer() then
        HorizonUtil.varlanceChatter("С возвращением. Вижу, краска немного облупилась. Хорошо повоевал, приятель?")
    end
end

local kothStory2_onPhase8DialogFinish = makeDialogServerCallback("kothStory2_onPhase8DialogFinish", 8, function()
    kothStory2_finishAndReward()
end)

--endregion

--region #СЕРВЕРНЫЕ ВЫЗОВЫ

function kothStory2_getNextLocation(_onBlockRing)
    local _MethodName = "Получить следующую локацию"
    
    mission.Log(_MethodName, "Получение локации.")
    local x, y = Sector():getCoordinates()
    local target = {}

    if _onBlockRing then
        --Получить сектор, который очень близко к внешнему краю барьера.
        mission.Log(_MethodName, "BlockRingMax is " .. tostring(Balancing.BlockRingMax))
        local _Nx, _Ny = ESCCUtil.getPosOnRing(x, y, Balancing.BlockRingMax + 10)
        target.x, target.y = MissionUT.getEmptySector(_Nx,_Ny, 3, 6, false)
        local _safetyBreakout = 0
        while target.x == x and target.y == y and _safetyBreakout <= 100 do
            target.x, target.y = MissionUT.getEmptySector(_Nx,_Ny, 3, 6, false)
            _safetyBreakout = _safetyBreakout + 1
        end
    else
        target.x, target.y = MissionUT.getEmptySector(x, y, 6, 12, false)
    end

    mission.Log(_MethodName, "X координата следующей локации: " .. tostring(target.x) .. " Y координата следующей локации: " .. tostring(target.y))
    if not target or not target.x or not target.y then
        mission.Log(_MethodName, "Не удалось найти подходящую локацию для миссии. Завершение скрипта.")
        terminate()
        return
    end

    return target
end

function kothStory2_buildSmugglerSector(_X, _Y)
    local _MethodName = "Построить главный сектор"
    
    mission.Log(_MethodName, "Сектор еще не построен. Начинается...")

    --Сектор всегда должен иметь 2-3 небольших поля астероидов, 1 большое поле астероидов и аванпост контрабандистов.
    local _Generator = SectorGenerator(_X, _Y)
    local _Rgen = random()

    --Получить фракцию контрабандистов.
    mission.Log(_MethodName, "Строительство аванпоста контрабандистов.")
    local _SmugglerFaction = ESCCUtil.getNeutralSmugglerFaction()

    local _SmugglerOutpost = _Generator:createStation(_SmugglerFaction, "merchants/smugglersmarket.lua")
    _SmugglerOutpost.title = "Укрытие контрабандистов"%_t
    _SmugglerOutpost:setValue("horizon_story_player", Player().index)
    _SmugglerOutpost:setValue("horizon_story_jobs_done", 0)
    _SmugglerOutpost:addScript("merchants/tradingpost.lua")
    _SmugglerOutpost:addScriptOnce("player/missions/horizon/story2/horizonstory2dialog1.lua")
    mission.data.custom.smugglerOutpostid = _SmugglerOutpost.id

    _Generator:createShipyard(_SmugglerFaction)

    for _ = 1, 3 do
        local ship = ShipGenerator.createDefender(_SmugglerFaction, _Generator:getPositionInSector())
        ship:setValue("horizon2_smuggler_defender", true)
        ship:removeScript("antismuggle.lua")
    end

    for _ = 1, _Rgen:getInt(3, 5) do
        _Generator:createSmallAsteroidField()
    end

    _Generator:createAsteroidField()

    _Generator:createContainerField()

    _Generator:addOffgridAmbientEvents()
    Placer.resolveIntersections()

    mission.data.custom.cleanUpSector = true

    sync()
end

function kothStory2_spawnContainerJobDefender()
    local xrand = random()

    local dir = xrand:getDirection()
    local pos = dir * xrand:getInt(1000, 1200)

    local onContainerDefenderFinished = function(ships)
        local _Defender = ships[1]

        _Defender:setValue("horizon2_smuggler_defender", true)
        _Defender:removeScript("antismuggle.lua")

        invokeClientFunction(Player(), "kothStory2_onPhase5DefenderDialog",  _Defender.id)
    end

    local _Faction = ESCCUtil.getNeutralSmugglerFaction()

    local generator = AsyncShipGenerator(nil, onContainerDefenderFinished)
    generator:startBatch()

    pos = pos + dir * 200
    local matrix = MatrixLookUpPosition(-dir, vec3(0, 1, 0), pos)

    generator:createDefender(_Faction, matrix)

    generator:endBatch()
end

function kothStory2_spawnVarlance()
    local _MethodName = "Появление Варланса"

    local _spawnVarlance = true
    if mission.data.custom.varlanceID then
        local _Varlance = Entity(mission.data.custom.varlanceID)
        if _Varlance and valid(_Varlance) and not _Varlance:getValue("varlance_withdrawing") then
            _spawnVarlance = false
        end
    end

    if _spawnVarlance then
        mission.Log(_MethodName, "В секторе нет Варланса - добавляем его.")

        local _Varlance = HorizonUtil.spawnVarlanceNormal(false)
        local _VarlanceAI = ShipAI(_Varlance)
    
        _VarlanceAI:setIdle()
        _VarlanceAI:setPassiveShooting(true)

        local _SmugglerHideout = Entity(mission.data.custom.smugglerOutpostid)
        local _Radius = _SmugglerHideout:getBoundingSphere().radius * 3

        local _VarlanceDurability = Durability(_Varlance)
        _VarlanceDurability.invincibility = 0.5

        local _VarlanceSlammerValues = {
            _ROF = 8,
            _DurabilityFactor = 50,
            _TimeToActive = math.huge,
            _DamageFactor = 10,
            _TargetPriority = 6,
            _ReachFactor = 2,
            _UseEntityDamageMult = true,
            _PreferBodyType = 9, --Hawk
            _PreferWarheadType = 4 --Tandem
        }

        _Varlance:addScriptOnce("torpedoslammer.lua", _VarlanceSlammerValues)

        _VarlanceAI:setFlyLinear(_SmugglerHideout.translationf, _Radius, false)

        mission.data.custom.varlanceID = _Varlance.index
    end
end

function kothStory2_spawnLocalTransport()
    local _MethodName = "Появление местного транспорта"

    mission.Log(_MethodName, "Выполняется.")

    -- это позиция, где появляется торговец
    local dir = random():getDirection()
    local pos = dir * 1500

    -- это позиция, куда торговец прыгнет в гиперпространство
    local destination = -pos + vec3(math.random(), math.random(), math.random()) * 1000
    destination = normalize(destination) * 1500

    --использовать это для onfinished.
    local onTransportFinished = function(ships)
        local _MethodName = "Транспорт завершен"
        local _Transport = ships[1]

        mission.Log(_MethodName, "Транспорт появился. Установка пункта назначения.")

		ShipUtility.addCargoToCraft(_Transport)
        _Transport:addScriptOnce("ai/passsector.lua", destination)
        _Transport:setValue("passing_ship", true)

        Placer.resolveIntersections(ships)

        invokeClientFunction(Player(), "kothStory2_onPhase5FreighterDialog", _Transport.id, _Transport.translatedTitle)
    end

    local _Faction = ESCCUtil.getNeutralSmugglerFaction()

    local generator = AsyncShipGenerator(nil, onTransportFinished)
    generator:startBatch()

    pos = pos + dir * 200
    local matrix = MatrixLookUpPosition(-dir, vec3(0, 1, 0), pos)

    generator:createFreighterShip(_Faction, matrix)

    generator:endBatch()
end

function kothStory2_buildPirateAmbushSector()
    local _PirateTable = ESCCUtil.getStandardWave(mission.data.custom.dangerLevel, 8, "Standard")
    local _CreatedPirateTable = {}

    for _, _Pirate in pairs(_PirateTable) do
        _Pirate = PirateGenerator.createScaledPirateByName(_Pirate, PirateGenerator.getGenericPosition())

        local _player = Player()
        local allianceIndex = _player.allianceIndex
        local ai = ShipAI(_Pirate)
        ai:registerFriendFaction(_player.index)
        if allianceIndex then
            ai:registerFriendFaction(allianceIndex)
        end

        MissionUT.deleteOnPlayersLeft(_Pirate)
        table.insert(_CreatedPirateTable, _Pirate)
    end

    SpawnUtility.addEnemyBuffs(_CreatedPirateTable)
end

function kothStory2_spawnPirateAmbush()
    local _MethodName = "Создание засады."
    local _Generator = AsyncPirateGenerator(nil, kothStory2_onPirateAmbushFinished)
    local _WaveTable = ESCCUtil.getStandardWave(mission.data.custom.dangerLevel, 5, "High")

    mission.Log(_MethodName, "Создание первой группы.")
    _Generator:startBatch()

    local posCounter = 1
    local distance = 250 --_#DistAdj

    local pirate_positions = _Generator:getStandardPositions(#_WaveTable, distance)
    for _, p in pairs(_WaveTable) do
        _Generator:createScaledPirateByName(p, pirate_positions[posCounter])
        posCounter = posCounter + 1
    end

    _Generator:endBatch()

    --Создать ударную группу торпедами.
    local _Generator2 = AsyncPirateGenerator(nil, kothStory2_onTorpStrikePirateSpawned)
    local _WaveTable2 = ESCCUtil.getStandardWave(mission.data.custom.dangerLevel, 2, "High")

    mission.Log(_MethodName, "Создание ударной группы торпедами.")
    _Generator2:startBatch()

    for _, p in pairs(_WaveTable2) do
        _Generator2:createScaledPirateByName(p, _Generator2:getGenericPosition())
    end

    _Generator2:endBatch()

    mission.data.custom.ambushPiratesSpawned = true
end

function kothStory2_onPirateAmbushFinished(_Generated)
    local _MethodName = "Засада пиратов завершена"
    SpawnUtility.addEnemyBuffs(_Generated)

    mission.Log(_MethodName, "Трансляция пиратской насмешки в сектор")

    local _Lines = {
        "Ты далеко от дома, не так ли?",
        "Мы разорвем тебя на куски!",
        "Всем кораблям, оружие на полную! В бой! В бой! В бой!",
        "Убить их всех! Ха-ха-ха!"
    }

    Sector():broadcastChatMessage(_Generated[1], ChatMessageType.Chatter, getRandomEntry(_Lines))  
end

function kothStory2_onTorpStrikePirateSpawned(_Generated)
    for _, _Ship in pairs(_Generated) do
        local _TorpSlamValues = {
            _ROF = 2,
            _DurabilityFactor = 2,
            _TimeToActive = 0,
            _DamageFactor = 3,
            _UseEntityDamageMult = true,
            _TargetPriority = 4
        }

        _Ship:addScriptOnce("torpedoslammer.lua", _TorpSlamValues)
        _Ship:addScriptOnce("utility/delayeddelete.lua", random():getFloat(8, 9)) --Должно дать достаточно времени, чтобы выстрелить 3 раза и уйти.
        ESCCUtil.setBombardier(_Ship)
    end

    Placer.resolveIntersections(_Generated)

    SpawnUtility.addEnemyBuffs(_Generated)
end

function kothStory2_finishAndReward()
    local _MethodName = "Завершение и награда"
    mission.Log(_MethodName, "Выполнение условия победы.")

    local _player = Player()

    local _AccomplishMessage = "Компания Frostbite благодарит вас. Вот ваша компенсация."
    local _BaseReward = 10000000
    local _BonusReward = 0
    if mission.data.custom.doneContainerJob then
        _BonusReward = _BonusReward + 300000
        mission.Log(_MethodName, "Работа с контейнером выполнена - увеличение награды до " .. tostring(_BonusReward))
    end
    if mission.data.custom.doneSatelliteJob then
        _BonusReward = _BonusReward + 300000
        mission.Log(_MethodName, "Работа со спутником выполнена - увеличение награды до " .. tostring(_BonusReward))
    end
    if mission.data.custom.destroyAsteroidJob then
        _BonusReward = _BonusReward + 300000
        mission.Log(_MethodName, "Работа с астероидом выполнена - увеличение награды до " .. tostring(_BonusReward))
    end
    if mission.data.custom.threeJobsDone then
        _AccomplishMessage = "Компания Frostbite благодарит вас. Вот ваша компенсация. Мейс также передает привет."
        _BonusReward = _BonusReward * 3
    end

    _player:setValue("_horizonkeepers_story_stage", 3)

    _player:sendChatMessage("Frostbite Company", 0, _AccomplishMessage)
    mission.data.reward = {credits = _BaseReward + _BonusReward, paymentMessage = "Заработан %1% кредитов за расшифровку чипа." }

    HorizonUtil.addFriendlyFactionRep(_player, 12500)

    reward()
    accomplish()
end

--endregion

--region #ВЫЗОВЫ ДИАЛОГОВ КЛИЕНТА / СЕРВЕРА

function kothStory2_contactedHacker()
    local _MethodName = "Связался с хакером"
    if onClient() then
        mission.Log(_MethodName, "Вызов на клиенте => Вызов на сервере.")

        invokeServerFunction("kothStory2_contactedHacker")
        return
    end

    mission.Log(_MethodName, "Вызов на сервере")

    invokeClientFunction(Player(), "kothStory2_onPhase3Dialog", mission.data.custom.varlanceID)
end
callable(nil, "kothStory2_contactedHacker")

function kothStory2_contactedHacker2(_proceed)
    local _MethodName = "Связался с хакером 2"
    if onClient() then
        mission.Log(_MethodName, "Вызов на клиенте => Вызов на сервере.")

        invokeServerFunction("kothStory2_contactedHacker2", _proceed)
        return
    end

    mission.Log(_MethodName, "Вызов на сервере")

    if _proceed then
        if mission.internals.phaseIndex == 4 then
            nextPhase() --Переводит нас в фазу 5 - фазу подзадач.
        end
    else
        mission.data.custom.annoyedHacker = mission.data.custom.annoyedHacker + 1

        if mission.data.custom.annoyedHacker % 2 == 1 then
            local _VarlanceLines = {
                "Постарайся не раздражать их. Нам нужна их помощь.",
                "Сохраняй спокойствие. Я бы не хотел их злить.",
                "Не провоцируй их. Наш лучший шанс - сохранить мир."
            }

            shuffle(random(), _VarlanceLines)

            HorizonUtil.varlanceChatter(_VarlanceLines[1])
        end
    end
end
callable(nil, "kothStory2_contactedHacker2")

function kothStory2_contactedHackerGiveSat()
    local _MethodName = "Связался с хакером, отдал спутник"
    if onClient() then
        mission.Log(_MethodName, "Вызов на клиенте => Вызов на сервере.")

        invokeServerFunction("kothStory2_contactedHackerGiveSat")
        return
    end

    mission.Log(_MethodName, "Вызов на сервере")

    local item = UsableInventoryItem("horizon2satellitepkg.lua", Rarity(RarityType.Exceptional))
    Player():getInventory():add(item, true)
end
callable(nil, "kothStory2_contactedHackerGiveSat")

function kothStory2_contactedHacker3()
    local _MethodName = "Связался с хакером 3"
    if onClient() then
        mission.Log(_MethodName, "Вызов на клиенте => Вызов на сервере.")

        invokeServerFunction("kothStory2_contactedHacker3")
        return
    end

    mission.Log(_MethodName, "Вызов на сервере - переход к следующей фазе.")

    if mission.internals.phaseIndex == 5 then
        nextPhase() --Переводит нас в фазу 6 - где мы захватываем спутник.
    end
end
callable(nil, "kothStory2_contactedHacker3")

function kothStory2_contactedHacker4()
    local _MethodName = "Связался с хакером 4"
    if onClient() then
        mission.Log(_MethodName, "Вызов на клиенте => Вызов на сервере.")

        invokeServerFunction("kothStory2_contactedHacker4")
        return
    end

    mission.Log(_MethodName, "Вызов на сервере - переход к следующей фазе.")

    if mission.internals.phaseIndex == 8 then
        invokeClientFunction(Player(), "kothStory2_onPhase8Dialog", mission.data.custom.varlanceID)
    end
end
callable(nil, "kothStory2_contactedHacker4")
function kothStory2_onPhase3Dialog(varlanceID)
    local d0 = {}
    local d1 = {}
    local d2 = {}
    local d3 = {}
    local d4 = {}

    d0.text = "Черт. Раньше они не были такими несговорчивыми. Попробуй разговорить их. Может, есть какая-то работа по мелочи, которую ты можешь сделать в этом секторе. Создай немного доброй воли."
    d0.answers = {
        { answer = "Я должен бегать на побегушках?", followUp = d1 },
        { answer = "Ладно.", followUp = d2 }
    }

    d1.text = "Это лучший способ получить то, что мы хотим."
    d1.answers = {
        { answer = "Я мог бы им пригрозить.", followUp = d3 },
        { answer = "Ладно. Ты прав.", followUp = d4 }
    }

    d2.text = "Я буду держать оборону, пока ты работаешь, приятель. Не беспокойся о пиратах или ксотанах."
    d2.onEnd = kothStory2_onPhase3DialogEnd

    d3.text = "Не сработает. Они просто снова уйдут в подполье, и ни один из других хакеров в этом районе не будет с нами работать после этого."
    d3.followUp = d4

    d4.text = "Я понимаю твое разочарование. К сожалению, нам нужно играть по-хорошему. Я буду держать оборону, пока ты работаешь, приятель. Не беспокойся о пиратах или ксотанах."
    d4.onEnd = kothStory2_onPhase3DialogEnd

    ESCCUtil.setTalkerTextColors({d0, d1, d2, d3, d4}, "Varlance", HorizonUtil.getDialogVarlanceTalkerColor(), HorizonUtil.getDialogVarlanceTextColor())

    ScriptUI(varlanceID):interactShowDialog(d0, false)
end

function kothStory2_onPhase5FreighterDialog(freighterID, freighterTitle)
    local d0 = {}
    local d1 = {}
    local d2 = {}
    local d3 = {}

    --Я думаю, если диалог вызывается слишком быстро, заголовок говорящего не успевает "зарегистрироваться" на клиенте, поэтому мы отправляем заголовок.
    d0.text = "Хм. Здесь меньше астероидов, чем я помню. Это твоих рук дело? Спасибо. В этом секторе будет намного легче ориентироваться."
    d0.talker = freighterTitle
    d0.followUp = d1

    d1.text = "Мы должны летать осторожно, потому что перевозим жизненно важные товары для станций в этом секторе - и других. Если наш корабль будет поврежден, кто знает, сколько людей пострадает?"
    d1.talker = freighterTitle
    d1.followUp = d2    

    d2.text = "Иногда лучший способ помочь другим - это помочь себе. Сначала надень кислородную маску на себя и все такое."
    d2.talker = freighterTitle
    d2.followUp = d3

    d3.text = "Извините за болтовню. Я вас отпускаю. Удачи и еще раз спасибо."
    d3.talker = freighterTitle

    ScriptUI(freighterID):interactShowDialog(d0, false)
end

function kothStory2_onPhase5DefenderDialog(defenderID)
    local d0 = {}
    local d1 = {}
    local d2 = {}
    local d3 = {}

    d0.text = "Вы сбрасываете ящик для кого-то на станции, не так ли?"
    d0.answers = {
        { answer = "Они не хотят, чтобы их видели, когда они получают к нему доступ.", followUp = d1 }
    }

    d1.text = "Это смешно."
    d1.followUp = d2    

    d2.text = "На прошлой неделе пираты совершили интенсивную атаку на этот сектор. В их флоте было несколько Мародеров и Опалителей. Мы боялись, но бросились в бой и начали стрелять."
    d2.followUp = d3

    d3.text = "Если бы мы поддались своим сомнениям... мы бы все были мертвы. Бояться - это естественно, храбрость - это не отсутствие страха, а готовность действовать, несмотря на этот страх. Возможно, ваш друг, получающий доступ к ящику, мог бы кое-чему научиться."

    ScriptUI(defenderID):interactShowDialog(d0, false)
end

function kothStory2_onPhase5StationDialog(stationID)
    local d0 = {}
    local d1 = {}
    local d2 = {}
    local d3 = {}

    d0.text = "Уф! Кто настроил этот дурацкий спутник на повторение 'Boots, Beer, and a Broken Heart'?! Эта песня устарела сто лет назад!"
    d0.followUp = d1

    d1.text = "Мэйс снова это сделал? Помните спутник, настроенный на воспроизведение 'Whiskey, Wildflowers, and Tears'? Клянусь, если они снова устраивают отвлекающий маневр, чтобы ограбить продовольственные бары..."
    d1.followUp = d2    

    d2.talker = "Начальник станции"
    d2.text = "К черту это! Мы больше не будем этого делать. Просто вырежьте эту штуку из локальной сети!"
    d2.followUp = d3

    d3.text = "Есть! Отключаю прямо сейчас!"

    ScriptUI(stationID):interactShowDialog(d0, false)
end

function kothStory2_onPhase7PirateDialog(pirateID)
    local d0 = {}
    local d1 = {}
    local d2 = {}
    local d3 = {}
    local d4 = {}
    local d5 = {}

    d0.text = "... Кто ты?"
    d0.answers = {
        { answer = "Я работаю с Мэйсом.", followUp = d1 }
    }

    d1.text = "Хм. Наверное, он слишком труслив, чтобы делать свою грязную работу. Ладно. У тебя есть артефакт?"
    d1.answers = {
        { answer = "Да. Вот он.", followUp = d2, onSelect = onPhase7TakeArtifact }
    }

    d2.text = "Хех. Спасибо."
    d2.followUp = d3

    d3.text = "Ага. Это настоящая вещь. Такую технику, как эта, больше не найти до исхода."
    d3.followUp = d4

    d4.text = "Жаль. Мы собирались убить этого ботаника после того, как он передаст товар."
    d4.followUp = d5

    d5.text = "Я полагаю, что твое убийство послужит достаточно хорошим посланием. Время умирать, капитан."
    d5.onEnd = onPhase7DialogFinish

    ScriptUI(pirateID):interactShowDialog(d0, false)
end

function kothStory2_onPhase7PirateNoArtifactDialog(pirateID)
    local d0 = {}
    local d1 = {}
    local d2 = {}
    local d3 = {}

    d0.text = "... Кто ты?"
    d0.answers = {
        { answer = "Я работаю с Мэйсом.", followUp = d1 }
    }

    d1.text = "Хм. Наверное, он слишком труслив, чтобы делать свою грязную работу. Ладно. У тебя есть артефакт?"
    d1.answers = {
        { answer = "Нет. Я его выбросил.", followUp = d2 }
    }

    d2.text = "Идиот!"
    d2.followUp = d3

    d3.text = "Ты хоть представляешь, сколько это стоило?! Мы тебя убьем!"
    d3.onEnd = onPhase7DialogFinish

    ScriptUI(pirateID):interactShowDialog(d0, false)
end

function kothStory2_onPhase8Dialog(varlanceID)
    local d0 = {}
    local d1 = {}

    d0.text = "Я получил дамп данных. На первый взгляд, это похоже на какое-то расписание."
    d0.followUp = d1

    d1.text = "Потребуется некоторое время, чтобы просмотреть это и разработать план действий. Я свяжусь с тобой. Будь начеку, приятель."
    d1.onEnd = kothStory2_onPhase8DialogFinish

    ESCCUtil.setTalkerTextColors({d0, d1}, "Varlance", HorizonUtil.getDialogVarlanceTalkerColor(), HorizonUtil.getDialogVarlanceTextColor())

    ScriptUI(varlanceID):interactShowDialog(d0, false)
end

--endregion