--[[
    MISSION 5: Scipio's Triumph
]]
package.path = package.path .. ";data/scripts/lib/?.lua"
package.path = package.path .. ";data/scripts/?.lua"

include("callable")
include("structuredmission")

ESCCUtil = include("esccutil")
HorizonUtil = include("horizonutil")

local SectorGenerator = include ("SectorGenerator")
local PirateGenerator = include("pirategenerator")
local Balancing = include ("galaxy")
local SpawnUtility = include ("spawnutility")
local Placer = include("placer")

mission._Debug = 0
mission._Name = "Триумф Сципиона"

--region #INIT / DATA

--Стандартные данные миссии.
mission.data.brief = mission._Name
mission.data.title = mission._Name
mission.data.autoTrackMission = true
mission.data.icon = "data/textures/icons/snowflake-2.png"
mission.data.priority = 9
mission.data.description = {
    { text = "Вы успешно угнали линкор, принадлежащий Horizon Keepers, LTD. Варланс сказал, что свяжется с вами, когда найдет что-нибудь полезное в его банках данных." },
    { text = "Прочитать письмо Варланса", bulletPoint = true, fulfilled = false },
    { text = "Направляйтесь в сектор (${_X}:${_Y})", bulletPoint = true, fulfilled = false, visible = false },
    { text = "Защитите AWACS «Frostbite»", bulletPoint = true, fulfilled = false, visible = false },
    { text = "Уничтожьте защитников Horizon", bulletPoint = true, fulfilled = false, visible = false },
    { text = "Повредите установку Horizon", bulletPoint = true, fulfilled = false, visible = false },
    { text = "Разбейте флот Horizon", bulletPoint = true, fulfilled = false, visible = false },
    { text = "Зачистите территорию", bulletPoint = true, fulfilled = false, visible = false }
}

--Пользовательские данные, которые нам понадобятся.
mission.data.custom.dangerLevel = 10 --Все зависит от уровня опасности 10.
mission.data.custom.phase3Timer1 = 0
mission.data.custom.phase3AWACSOrderSent = false
mission.data.custom.awacsRewardBonus = true
mission.data.custom.phase3DialogAllowed = false
mission.data.custom.varlanceP4ChatterSent = false
mission.data.custom.waveNumber = 1

--endregion

--region #PHASE CALLS

mission.globalPhase.timers = {}

mission.globalPhase.noBossEncountersTargetSector = true

mission.globalPhase.onAbandon = function()
    if mission.data.location then
        if atTargetLocation() then
            kothStory5_frostbiteDeparts()
        end
        runFullSectorCleanup(true)
    end
end

mission.globalPhase.onFail = function()
    if mission.data.location then
        if atTargetLocation() then
            kothStory5_frostbiteDeparts()
        end
        runFullSectorCleanup(true)
    end
end

mission.globalPhase.onAccomplish = function()
    if mission.data.location then
        runFullSectorCleanup(false)
    end
end

mission.globalPhase.onTargetLocationEntered = function(_X, _Y)
    mission.data.timeLimit = nil 
    mission.data.timeLimitInDescription = false
end

mission.globalPhase.onTargetLocationLeft = function(_X, _Y)
    mission.data.timeLimit = mission.internals.timePassed + (5 * 60) --У игрока есть 5 минут, чтобы вернуться в сектор.
    mission.data.timeLimitInDescription = true --Показать игроку, сколько времени осталось.
end

--region #GLOBALPHASE TIMERS

if onServer() then

mission.globalPhase.timers[1] = {
    time = 180, --У него нет ресурсов Адрианы, он не может так быстро возродиться.
    callback = function()
        local _MethodName = "Global Phase Timer 1 Callback"

        if atTargetLocation() then
            mission.Log(_MethodName, "На месте - возрождаем Варланса, если нужно.")

            kothStory5_spawnVarlance()
        end
    end,
    repeating = true
}

end
    
--endregion

mission.phases[1] = {}
mission.phases[1].showUpdateOnEnd = true
mission.phases[1].onBeginServer = function()
    local _MethodName = "Phase 1 On Begin Server"
    --Получить сектор, который очень близок к внешнему краю барьера.
    mission.Log(_MethodName, "BlockRingMax is " .. tostring(Balancing.BlockRingMax))

    mission.data.custom.firstLocation = kothStory5_getNextLocation(true)

    local _X = mission.data.custom.firstLocation.x
    local _Y = mission.data.custom.firstLocation.y

    mission.data.custom.pirateLevel = Balancing_GetPirateLevel(_X, _Y) --Установить уровень пиратства на основе первого местоположения.

    mission.data.description[3].arguments = { _X = mission.data.custom.firstLocation.x, _Y = mission.data.custom.firstLocation.y }
    
    --Отправить письмо игроку.
    local _Player = Player()
    local _Mail = Mail()
	_Mail.text = Format("Привет, приятель.\n\nНе думаю, что капитан этого корабля был в почете у своих корпоративных повелителей. Еще бы, ведь этот идиот разбил свой корабль в разломе. Не так уж много зацепок, но нам хватит. Я нашел верфь, куда они собирались отбуксировать эту штуку для ремонта - похоже, это была одна из их собственных. Логично, я бы тоже не доверил эту крошку пиратской верфи. Мы также нашли больше деталей Ксотан, что... вызывает беспокойство. Я хотел бы изучить это подробнее.\n\nПосмотрев график поставок, мы можем воспользоваться одним окном - мы можем отправить отряд на одном из их грузовых кораблей и украсть данные из их сети, прежде чем они узнают, что происходит. Есть только одна проблема. Эта верфь слишком хорошо защищена, чтобы провернуть такой трюк. Нам нужно заставить их перебросить слишком много сил, чтобы мы могли ввести свои войска, и у меня есть идея.\n\nНа этом корабле также есть данные об исследовательском форпосте, который находится довольно далеко отсюда. Он слабо защищен, но как только мы его атакуем, он начнет звать на помощь. Мы можем использовать это, чтобы выманить их силы и разбить их по частям. Я подготовлю корабль AWACS - встретимся у (%1%:%2%) и приготовьтесь к бою.\n\nВарланс", _X, _Y)
	_Mail.header = "Следующие шаги"
	_Mail.sender = "Варланс @FrostbiteCompany"
	_Mail.id = "_horizon_story5_mail"
	_Player:addMail(_Mail)
end

mission.phases[1].playerCallbacks = {
	{
		name = "onMailRead",
		func = function(_PlayerIndex, _MailIndex)
			if onServer() then
				local _Player = Player()
				local _Mail = _Player:getMail(_MailIndex)
				if _Mail.id == "_horizon_story5_mail" then
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
    mission.Log(_MethodName, "Начинаем...")

    mission.data.location = mission.data.custom.firstLocation

    mission.data.description[2].fulfilled = true
    mission.data.description[3].visible = true
end

mission.phases[2].onTargetLocationEntered = function(_x, _y)
    if onServer() then
        kothStory5_buildObjectiveSector(_x, _y)
    end
end

mission.phases[2].onTargetLocationArrivalConfirmed = function(_x, _y)
    HorizonUtil.varlanceChatter("Защитите AWACS. Он понадобится нам, чтобы узнать, когда установка пошлет сигнал бедствия. Сначала убейте защитников, а потом мы закинем наживку.")
    nextPhase()
end

mission.phases[3] = {}
mission.phases[3].showUpdateOnEnd = true
mission.phases[3].onBegin = function()
    local _MethodName = "Phase 3 On Begin"
    mission.Log(_MethodName, "Начинаем...")

    mission.data.description[3].fulfilled = true
    mission.data.description[4].visible = true
    mission.data.description[5].visible = true
    mission.data.description[6].visible = true
end

mission.phases[3].onBeginServer = function()
    mission.data.custom.phase3DialogAllowed = true
end

mission.phases[3].updateTargetLocationServer = function(timeStep)
    local methodName = "Phase 3 Update Target Location Server"

    mission.data.custom.phase3Timer1 = mission.data.custom.phase3Timer1 + timeStep

    --Нам все равно, находимся мы на месте или нет - если игрок выпрыгнет из сектора на этом этапе миссии, она провалится.
    local _sector = Sector()
    local awacsEntities = { _sector:getEntitiesByScriptValue("is_frostbite_awacs") }
    local station = Entity(mission.data.custom.horizonStationID)

    if #awacsEntities == 0 then
        fail()
    else
        local _awacs = awacsEntities[1]

        --AWACS дает вам немного времени, прежде чем начать подлетать.
        if not mission.data.custom.phase3AWACSOrderSent then
            if mission.data.custom.phase3Timer1 >= 10 and #awacsEntities > 0 and station and valid(station) then
                mission.Log(methodName, "Отправляем AWACS приказ о перемещении.")
    
                local awacsAI = ShipAI(_awacs)
                awacsAI:setIdle()
                awacsAI:setPassiveShooting(true)
                awacsAI:setFlyLinear(station.translationf, 1000, false)

                mission.data.custom.phase3AWACSOrderSent = true
            end
        end

        --Если игрок сможет удержать AWACS выше 50% HP, он получит бонус.
        local awacsHPThreshold = _awacs.durability / _awacs.maxDurability
        if awacsHPThreshold < 0.5 then
            mission.data.custom.awacsRewardBonus = false
        end
    end

    --3-я фаза заканчивается, и мы переходим к 4-й фазе после того, как установка пошлет сигнал бедствия.
    local defenderCt = ESCCUtil.countEntitiesByValue("is_horizon_defender")
    local defenderObjectiveDone = false
    local stationObjectiveDone = false

    if defenderCt == 0 then
        defenderObjectiveDone = true
        mission.data.description[5].fulfilled = true
        kothStory5_setVarlancePhase3Orders()
    end

    local stationHPThreshold = station.durability / station.maxDurability
    if stationHPThreshold < 0.96 then
        stationObjectiveDone = true
        mission.data.description[6].fulfilled = true
    end

    if defenderObjectiveDone and stationObjectiveDone and mission.data.custom.phase3DialogAllowed then
        mission.Log(methodName, "Задачи по защитникам и станции выполнены - начинаем диалог и переходим к следующей фазе.")

        mission.data.custom.phase3DialogAllowed = false 
        invokeClientFunction(Player(), "kothStory5_onPhase3Dialog", mission.data.custom.horizonStationID)
    end

    sync()
end

local kothStory5_onPhase3DialogFireTorp = makeDialogServerCallback("kothStory5_onPhase3DialogFireTorp", 3, function()
    local _MethodName = "Oh Phase 3 Dialog Fire Torp"
    mission.Log(_MethodName, "Начинаем.")

    local _Varlance = Entity(mission.data.custom.varlanceID)
    _Varlance:invokeFunction("torpedoslammer.lua", "resetTimeToActive", 0)
end)

local kothStory5_onPhase3DialogEnd = makeDialogServerCallback("kothStory5_onPhase3DialogEnd", 3, function()
    kothStory5_awacsDeparts()
    nextPhase()
end)

mission.phases[4] = {}
mission.phases[4].timers = {}
mission.phases[4].showUpdateOnEnd = true
mission.phases[4].onBegin = function()
    mission.data.description[7].visible = true
end

mission.phases[4].onBeginServer = function()
    HorizonUtil.varlanceChatter("А теперь ждем...")
    kothStory5_setVarlancePhase4Orders()
end

--region #PHASE 4 TIMERS

if onServer() then

mission.phases[4].timers[1] = {
    time = 60,
    callback = function()
        --Ничего не делать, если мы не в нужном секторе.
        if atTargetLocation() then
            --Отправить сообщение, если нужно.
            if not mission.data.custom.varlanceP4ChatterSent then
                HorizonUtil.varlanceChatter("Вот они. Уничтожьте их, как только они выпрыгнут. Зачистите и установку, если будет возможность - она уже выполнила свою задачу.")
                
                mission.data.description[8].visible = true
    
                mission.data.custom.varlanceP4ChatterSent = true
                sync()
            end
    
            --Породить следующую волну, если нужно.
            local horizonCt = ESCCUtil.countEntitiesByValue("is_horizon_ship")
            if horizonCt == 0 and mission.data.custom.waveNumber <= 3 then
                kothStory5_spawnHorizonWave()
    
                mission.data.custom.waveNumber = mission.data.custom.waveNumber + 1
            end
        end
    end,
    repeating = true
}

mission.phases[4].timers[2] = {
    time = 5,
    callback = function()
        --Ничего не делать, если не на месте.
        if atTargetLocation() then
            --Отметить флот как уничтоженный, если применимо.
            local horizonShipCt = ESCCUtil.countEntitiesByValue("is_horizon_ship")
            if horizonShipCt == 0 and mission.data.custom.waveNumber == 4 then
                mission.data.description[7].fulfilled = true
            end
    
            --Отметить станцию как уничтоженную, если применимо.
            local horizonStationCt = ESCCUtil.countEntitiesByValue("is_horizon_station")
            if horizonStationCt == 0 then
                mission.data.description[8].fulfilled = true
            end
    
            --Перейти к следующей фазе, если обе вышеуказанные задачи выполнены.
            local horizonCt = ESCCUtil.countEntitiesByValue("is_horizon")
            if horizonCt == 0 and mission.data.custom.waveNumber == 4 then
                nextPhase()
            end

            --Нужна синхронизация для задач миссии.
            sync()
        end
    end,
    repeating = true
}

end

--endregion

mission.phases[5] = {}
mission.phases[5].onBeginServer = function()
    kothStory5_spawnVarlance()

    invokeClientFunction(Player(), "kothStory5_onPhase5Dialog", mission.data.custom.varlanceID)
end

local kothStory5_onPhase5DialogEnd = makeDialogServerCallback("kothStory5_onPhase5DialogEnd", 5, function()
    local _Varlance = Entity(mission.data.custom.varlanceID)
    _Varlance:addScriptOnce("entity/utility/delayeddelete.lua", random():getFloat(4, 7))

    kothStory5_finishAndReward()
end)

--endregion

--region #SERVER CALLS

function kothStory5_getNextLocation(_onBlockRing)
    local _MethodName = "Get Next Location"
    
    mission.Log(_MethodName, "Получаем местоположение.")
    local x, y = Sector():getCoordinates()
    local target = {}

    if _onBlockRing then
        --Получить сектор, который очень близок к внешнему краю барьера.
        mission.Log(_MethodName, "BlockRingMax is " .. tostring(Balancing.BlockRingMax))
        local _Nx, _Ny = ESCCUtil.getPosOnRing(x, y, Balancing.BlockRingMax + 10)
        target.x, target.y = MissionUT.getEmptySector(_Nx,_Ny, 6, 12, false)
        local _safetyBreakout = 0
        while target.x == x and target.y == y and _safetyBreakout <= 100 do
            target.x, target.y = MissionUT.getEmptySector(_Nx,_Ny, 6, 12, false)
            _safetyBreakout = _safetyBreakout + 1
        end
    else
        target.x, target.y = MissionUT.getEmptySector(x, y, 6, 16, false)
    end

    mission.Log(_MethodName, "X координата следующего местоположения: " .. tostring(target.x) .. " Y координата следующего местоположения: " .. tostring(target.y))
    if not target or not target.x or not target.y then
        mission.Log(_MethodName, "Не удалось найти подходящее место для миссии. Завершаем скрипт.")
        terminate()
        return
    end

    return target
end

function kothStory5_buildObjectiveSector(x, y)
    local _MethodName = "Build Objective Sector"
    mission.Log(_MethodName, "Начинаем.")

    local _random = random()

    local _Generator = SectorGenerator(x, y)

    _Generator:createAsteroidField()

    local _fields = _random:getInt(3, 5)
    --Добавить: 3-5 небольших астероидных поля.
    for _ = 1, _fields do
        _Generator:createSmallAsteroidField()
    end

    local look = _random:getVector(-100, 100)
    local up = _random:getVector(-100, 100)
    local pos = vec3(0, 0, 0)
    local _Player = Player()
    local _Ship = Entity(_Player.craftIndex)

    if _Ship then
        pos = _Ship.translationf
    end

    local _basepos = ESCCUtil.getVectorAtDistance(pos, 4500, true)
    local matrix = MatrixLookUpPosition(look, up, _basepos)
    
    --Породить станцию Horizon.
    local _Station = HorizonUtil.spawnHorizonResearchStation(false, matrix)
    mission.data.custom.horizonStationID = _Station.index

    --Породить Ice Nova
    kothStory5_spawnVarlance()

    --Породить AWACS
    HorizonUtil.spawnFrostbiteAWACS(false)

    --Породить защитников
    local _HorizonFaction = HorizonUtil.getEnemyFaction()
    local _PirateTable = ESCCUtil.getStandardWave(mission.data.custom.dangerLevel, 6, "Low")
    local _CreatedPirateTable = {}

    for _, _Pirate in pairs(_PirateTable) do
        local pLook = _random:getVector(-100, 100)
        local pUp = _random:getVector(-100, 100)
        local pPos = ESCCUtil.getVectorAtDistance(_Station.translationf, 1000, false)

        local _ship = PirateGenerator.createScaledPirateByName(_Pirate, MatrixLookUpPosition(pLook, pUp, pPos))
        _ship.factionIndex = _HorizonFaction.index
        _ship:setValue("is_horizon_defender", true)

        local _attackerData = {
            _TargetPriority = 1,
            _TargetTag = "is_frostbite_awacs"
        }

        _ship:addScriptOnce("ai/priorityattacker.lua", _attackerData)

        table.insert(_CreatedPirateTable, _ship)
    end

    SpawnUtility.addEnemyBuffs(_CreatedPirateTable)

    Placer.resolveIntersections()

    mission.data.custom.cleanUpSector = true
end

function kothStory5_spawnVarlance()
    local _MethodName = "Spawn Varlance"
    
    local _spawnVarlance = true
    if mission.data.custom.varlanceID then
        local _Varlance = Entity(mission.data.custom.varlanceID)
        if _Varlance and valid(_Varlance) and not _Varlance:getValue("varlance_withdrawing") then
            _spawnVarlance = false
        end
    end

    if _spawnVarlance then
        mission.Log(_MethodName, "В секторе нет Варланса - порождаем его.")

        local _Varlance = HorizonUtil.spawnVarlanceBattleship(false)
        local _VarlanceAI = ShipAI(_Varlance)

        --дать ему очень особенный torpedoslammer
        local _SlammerData = {
            _ROF = 2,
            _DurabilityFactor = 999,
            _TimeToActive = math.huge,
            _TargetPriority = 2,
            _TargetTag = "is_horizon_station",
            _ReachFactor = 999,
            _TurningSpeedFactor = 999,
            _ShockwaveFactor = 6,
            _AccelFactor = 4,
            _VelocityFactor = 4,
            _PreferBodyType = 9, --Hawk
            _PreferWarheadType = 9, --EMP
            _LimitAmmo = true,
            _Ammo = 1
        }

        _Varlance:addScript("torpedoslammer.lua", _SlammerData)
    
        _VarlanceAI:setAggressive()

        mission.data.custom.varlanceID = _Varlance.index
    end
end

function kothStory5_awacsDeparts()
    local _awacsPlural = { Sector():getEntitiesByScriptValue("is_frostbite_awacs") }
    if #_awacsPlural > 0 then
        local _awacs = _awacsPlural[1]
        _awacs:addScriptOnce("entity/utility/delayeddelete.lua", random():getFloat(3, 6))
        mission.data.description[4].fulfilled = true
    end
end

function kothStory5_frostbiteDeparts()
    local _frostbiteShips = { Sector():getEntitiesByScriptValue("is_frostbite") }
    for _, _ship in pairs(_frostbiteShips) do
        _ship:addScriptOnce("entity/utility/delayeddelete.lua", random():getFloat(3, 6))
    end
end

function kothStory5_setVarlancePhase3Orders()
    local _Varlance = Entity(mission.data.custom.varlanceID)
    local _VarlanceAI = ShipAI(_Varlance)

    local horizonStation = Entity(mission.data.custom.horizonStationID)

    _VarlanceAI:stop()
    _VarlanceAI:setIdle()
    _VarlanceAI:setPassiveShooting(true)
    _VarlanceAI:setFlyLinear(horizonStation.translationf, 800, false)
end

function kothStory5_setVarlancePhase4Orders()
    local _Varlance = Entity(mission.data.custom.varlanceID)
    local _VarlanceAI = ShipAI(_Varlance)

    _VarlanceAI:setPassiveShooting(false)
    _VarlanceAI:setAggressive()
end
function kothStory5_spawnHorizonWave()
    local shipsSpawned = {}

    local shipPositions = PirateGenerator.getStandardPositions(5, 500, nil)

    local attackScript = "ai/priorityattacker.lua"

    local priorityPlayerAttackerValues = {
        _TargetPriority = 2
    }

    local priorityVarlanceAttackerValues = {
        _TargetPriority = 1,
        _TargetTag = "is_varlance"
    }

    local torpSlammerValuesTargetPlayer = {
        _TimeToActive = 5,
        _ROF = 6,
        _PreferWarheadType = 3, --Fusion
        _PreferBodyType = 7, --Osprey
        _DurabilityFactor = 4,
        _TargetPriority = 5, --Текущий корабль игрока.
        _pindex = Player().index
    }

    local torpSlammerValuesTargetVarlance = {
        _TimeToActive = 5,
        _ROF = 6,
        _PreferWarheadType = 3, --Fusion
        _PreferBodyType = 7, --Osprey
        _DurabilityFactor = 4,
        _TargetPriority = 2, --Значение скрипта
        _TargetTag = "is_varlance"
    }

    local spawnFuncTable = {
        function() --w1 = 2 боевых крейсера / 2 арты
            local _arty1 = HorizonUtil.spawnHorizonArtyCruiser(false, shipPositions[1], nil)

            local _combat1 = HorizonUtil.spawnHorizonCombatCruiser(false, shipPositions[2], nil)

            local _combat2 = HorizonUtil.spawnHorizonCombatCruiser(false, shipPositions[3], nil)

            local _arty2 = HorizonUtil.spawnHorizonArtyCruiser(false, shipPositions[4], nil)

            --Равное разделение - arty1 / combat1 идут за игроком, arty2 / combat2 идут за Varlance
            _arty1:addScriptOnce(attackScript, priorityPlayerAttackerValues)
            _arty2:addScriptOnce(attackScript, priorityVarlanceAttackerValues)
            _combat1:addScriptOnce(attackScript, priorityPlayerAttackerValues)
            _combat2:addScriptOnce(attackScript, priorityVarlanceAttackerValues)

            _arty1:addScriptOnce("torpedoslammer.lua", torpSlammerValuesTargetPlayer)
            _arty2:addScriptOnce("torpedoslammer.lua", torpSlammerValuesTargetVarlance)

            table.insert(shipsSpawned, _arty1)
            table.insert(shipsSpawned, _arty2)
            table.insert(shipsSpawned, _combat1)
            table.insert(shipsSpawned, _combat2)
        end,
        function() --w2 = 2 боевых / 2 арты / 1 линкор
            local _combat1 = HorizonUtil.spawnHorizonCombatCruiser(false, shipPositions[1], nil)

            local _arty1 = HorizonUtil.spawnHorizonArtyCruiser(false, shipPositions[2], nil)

            local _bship1 = HorizonUtil.spawnHorizonBattleship(false, shipPositions[3], nil)

            local _arty2 = HorizonUtil.spawnHorizonArtyCruiser(false, shipPositions[4], nil)

            local _combat2 = HorizonUtil.spawnHorizonCombatCruiser(false, shipPositions[5], nil)

            --равное разделение на combat / arty, идущих за игроком, как в w1 - линкор идет за игроком.
            _arty1:addScriptOnce(attackScript, priorityPlayerAttackerValues)
            _arty2:addScriptOnce(attackScript, priorityVarlanceAttackerValues)
            _combat1:addScriptOnce(attackScript, priorityVarlanceAttackerValues)
            _combat2:addScriptOnce(attackScript, priorityVarlanceAttackerValues)
            _bship1:addScriptOnce(attackScript, priorityPlayerAttackerValues)

            _arty1:addScriptOnce("torpedoslammer.lua", torpSlammerValuesTargetPlayer)
            _arty2:addScriptOnce("torpedoslammer.lua", torpSlammerValuesTargetVarlance)

            table.insert(shipsSpawned, _arty1)
            table.insert(shipsSpawned, _arty2)
            table.insert(shipsSpawned, _combat1)
            table.insert(shipsSpawned, _combat2)
            table.insert(shipsSpawned, _bship1)
        end,
        function() --w3 = 3 боевых / 2 линкора
            local _combat1 = HorizonUtil.spawnHorizonCombatCruiser(false, shipPositions[1], nil)

            local _bship1 = HorizonUtil.spawnHorizonBattleship(false, shipPositions[2], nil)

            local _bship2 = HorizonUtil.spawnHorizonBattleship(false, shipPositions[3], nil)

            local _combat2 = HorizonUtil.spawnHorizonCombatCruiser(false, shipPositions[4], nil)

            local _combat3 = HorizonUtil.spawnHorizonCombatCruiser(false, shipPositions[5], nil)

            --combat1 / combat2 идут за varlance, все оставшиеся корабли идут за игроком.
            _combat1:addScriptOnce(attackScript, priorityVarlanceAttackerValues)
            _combat2:addScriptOnce(attackScript, priorityVarlanceAttackerValues)
            _combat3:addScriptOnce(attackScript, priorityPlayerAttackerValues)
            _bship1:addScriptOnce(attackScript, priorityPlayerAttackerValues)
            _bship2:addScriptOnce(attackScript, priorityPlayerAttackerValues)

            local withdrawData = {
                _Threshold = 0.10,
                _Invincibility = 0.01
            }

            _bship1:addScriptOnce("ai/withdrawatlowhealth.lua", withdrawData)
            _bship2:addScriptOnce("ai/withdrawatlowhealth.lua", withdrawData)            

            table.insert(shipsSpawned, _combat1)
            table.insert(shipsSpawned, _combat2)
            table.insert(shipsSpawned, _combat3)
            table.insert(shipsSpawned, _bship1)
            table.insert(shipsSpawned, _bship2)
        end
    }

    local waveidx = mission.data.custom.waveNumber

    spawnFuncTable[waveidx]()

    for _, _ship in pairs(shipsSpawned) do
        --Это будет довольно быстро переопределено скриптом ИИ, но это необходимо.
        local _shipAI = ShipAI(_ship)
        _shipAI:setAggressive()        
    end

    SpawnUtility.addEnemyBuffs(shipsSpawned)

    Placer.resolveIntersections()
end

function kothStory5_finishAndReward()
    local _MethodName = "Завершение и награда"
    mission.Log(_MethodName, "Выполнение условия победы.")

    local _player = Player()

    local _AccomplishMessage = "Компания Frostbite благодарит вас. Вот ваша компенсация."
    local _Reward = 27440000
    local _PaymentMessage = "Заработано %1% кредитов за уничтожение флота Horizon Keeper."

    if mission.data.custom.awacsRewardBonus then
        _Reward = _Reward * 1.1
        _PaymentMessage = "Заработано %1% кредитов за уничтожение флота Horizon Keeper. Это включает бонус за отличную работу."
    end

    _player:setValue("_horizonkeepers_story_stage", 6)

    _player:sendChatMessage("Frostbite Company", 0, _AccomplishMessage)
    mission.data.reward = {credits = _Reward, paymentMessage = _PaymentMessage }

    HorizonUtil.addFriendlyFactionRep(_player, 12500)

    reward()
    accomplish()
end

--endregion

--region #CLIENT CALLS

function kothStory5_onPhase3Dialog(_StationID)
    local d0 = {}
    local d1 = {}
    local d2 = {}
    local d3 = {}
    local d4 = {}
    local d5 = {}

    d0.text = "<Перехвачено> Штаб, это исследовательская установка HRI-7873-SRD6F6C. Наши защитники уничтожены мощной независимой ударной группой. Запрашиваем немедленную помощь. Отправьте все группы реагирования!"
    d0.followUp = d1

    d1.text = "Вот сигнал бедствия. Давайте его отключим. Оружейники, огонь модифицированной ЭМИ-торпедой."
    d1.followUp = d2
    d1.onStart = kothStory5_onPhase3DialogFireTorp

    d2.text = "Отлично. Это заставит замолчать нашу приманку."
    d2.followUp = d3

    d3.text = "Мы отредактируем это при повторной передаче и преуменьшим наше нападение. Если повезет, когда первая волна осознает свою ошибку, будет слишком поздно для реорганизации их развертывания."
    d3.followUp = d4

    d4.text= "AWACS, вам разрешено отбыть. Мы не сможем защитить вас от того, что Horizon решит прислать следующим."
    d4.followUp = d5

    d5.text = "Понял! Удачи, капитан Varlance! И вам тоже, капитан. Активирую гипердвигатель сейчас."
    d5.talker = "Frostbite AWACS"
    d5.onEnd = kothStory5_onPhase3DialogEnd

    ESCCUtil.setTalkerTextColors({d1, d2, d3, d4}, "Varlance", HorizonUtil.getDialogVarlanceTalkerColor(), HorizonUtil.getDialogVarlanceTextColor())

    ScriptUI(_StationID):interactShowDialog(d0, false)
end

function kothStory5_onPhase5Dialog(varlanceID)
    local d0 = {}
    local d1 = {}
    local d2 = {}
    local d3 = {}

    d0.text = "Больше нет входящих подпространственных векторов."
    d0.followUp = d1

    d1.text = "Это должна быть значительная часть их местных активов. Не могу представить, что у них будет что-то еще, на что можно положиться - особенно с учетом потери двух их линкоров и еще двух критически поврежденных."
    d1.followUp = d2

    d2.text = "Кстати, нам нужно выследить их, прежде чем предпринимать какие-либо дальнейшие наступательные действия против Horizon Keepers."
    d2.followUp = d3

    d3.text = "Хорошая работа сегодня, приятель. Я свяжусь с тобой, как только выясню, где они прячутся. Это не займет много времени - скорее всего, они совершили аварийный прыжок, чтобы сбежать."
    d3.onEnd = kothStory5_onPhase5DialogEnd

    ESCCUtil.setTalkerTextColors({d0, d1, d2, d3}, "Varlance", HorizonUtil.getDialogVarlanceTalkerColor(), HorizonUtil.getDialogVarlanceTextColor())

    ScriptUI(varlanceID):interactShowDialog(d0, false)
end

--endregion