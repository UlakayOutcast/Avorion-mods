--[[
    MISSION 3: Chasing Shadows
]]
package.path = package.path .. ";data/scripts/lib/?.lua"
package.path = package.path .. ";data/scripts/?.lua"

include("callable")
include("structuredmission")

ESCCUtil = include("esccutil")
HorizonUtil = include("horizonutil")

local AsyncPirateGenerator = include ("asyncpirategenerator")
local ShipGenerator = include("shipgenerator")
local Balancing = include ("galaxy")
local SpawnUtility = include ("spawnutility")
local ShipUtility = include("shiputility")
local Placer = include("placer")

mission._Debug = 0
mission._Name = "В погоне за тенями"

--region #INIT / DATA

--Стандартные данные миссии.
mission.data.brief = mission._Name
mission.data.title = mission._Name
mission.data.autoTrackMission = true
mission.data.icon = "data/textures/icons/snowflake-2.png"
mission.data.priority = 9
mission.data.description = {
    { text = "Мейс расшифровал чип для тебя. Варланс сказал, что свяжется с тобой, когда у него будет план действий." },
    { text = "Прочитать письмо Варланса", bulletPoint = true, fulfilled = false },
    { text = "Отправляйся в сектор (${_X}:${_Y}) и жди грузовые корабли", bulletPoint = true, fulfilled = false, visible = false },
    { text = "Уничтожь грузовые корабли до того, как они совершат прыжок", bulletPoint = true, fulfilled = false, visible = false },
    { text = "Преследуй грузовые корабли до (${_X}:${_Y})", bulletPoint = true, fulfilled = false, visible = false },
    { text = "Уничтожь грузовые корабли до того, как они снова совершат прыжок", bulletPoint = true, fulfilled = false, visible = false },
    { text = "Прочитать второе письмо Варланса", bulletPoint = true, fulfilled = false, visible = false },
    { text = "Встретиться с Варлансом в секторе (${_X}:${_Y})", bulletPoint = true, fulfilled = false, visible = false },
    { text = "Уничтожить пиратов", bulletPoint = true, fulfilled = false, visible = false },
    { text = "Допросить выживших", bulletPoint = true, fulfilled = false, visible = false }
}

--Пользовательские данные, которые нам понадобятся.
mission.data.custom.dangerLevel = 10 --Все основано на уровне опасности 10.
mission.data.custom.transportsSpawned = false
mission.data.custom.phase3PirateGroupSpawned = false
mission.data.custom.phase5PirateKOd = false
mission.data.custom.phase5MiniBossTimer = 0
mission.data.custom.phase5MiniBossesSpawned = false
mission.data.custom.phase6VarlanceDialogTimer = 0
mission.data.custom.phase6VarlanceDialogAllowed = false
mission.data.custom.hyperspaceCounter = 0

--endregion

--region #PHASE CALLS

mission.globalPhase.noBossEncountersTargetSector = true

mission.globalPhase.onAbandon = function()
    kothStory3_handleSectorCleanup(true)
end

mission.globalPhase.onFail = function()
    kothStory3_handleSectorCleanup(true)
end

mission.globalPhase.onAccomplish = function()
    kothStory3_handleSectorCleanup(false)
end

mission.globalPhase.onTargetLocationEntered = function(_X, _Y)
    mission.data.timeLimit = nil 
    mission.data.timeLimitInDescription = false
end

mission.globalPhase.onTargetLocationLeft = function(_X, _Y)
    mission.data.timeLimit = mission.internals.timePassed + (5 * 60) --У игрока есть 5 минут, чтобы вернуться в сектор.
    mission.data.timeLimitInDescription = true --Показать игроку, сколько времени осталось.
end

mission.phases[1] = {}
mission.phases[1].showUpdateOnEnd = true
mission.phases[1].onBeginServer = function()
    local _MethodName = "Phase 1 On Begin Server"
    --Получить сектор, который очень близок к внешнему краю барьера.
    mission.Log(_MethodName, "BlockRingMax is " .. tostring(Balancing.BlockRingMax))

    mission.data.custom.firstLocation = kothStory3_getNextLocation(true)

    local _X = mission.data.custom.firstLocation.x
    local _Y = mission.data.custom.firstLocation.y

    mission.data.custom.pirateLevel = Balancing_GetPirateLevel(_X, _Y) --Установить уровень пиратов на основе первого местоположения.

    mission.data.description[3].arguments = { _X = mission.data.custom.firstLocation.x, _Y = mission.data.custom.firstLocation.y }
    
    --Отправить письмо игроку.
    local _Player = Player()
    local _Mail = Mail()
	_Mail.text = Format("Привет, приятель.\n\nЭто Варланс. Я был прав насчет данных, которые мы получили с этого чипа. Похоже, это расписание поставок. Все они сходятся в одном секторе. Я думаю, нам следует убедиться, что пара из них задержатся... навсегда. Я нашел два, которые должны прибыть в ближайшее время. Я собираюсь атаковать один из них, и я хотел бы, чтобы ты атаковал другой. Они будут проезжать через (%1%:%2%) в ближайшее время. Отправляйся туда и уничтожь их. Убедись, что ты атаковал их быстро - к тому времени они будут всего в паре прыжков от места назначения.\n\nЯ уже атаковал другую группу пиратов и подбросил фальшивый чип данных в обломки их верфи, а затем подбросил обломки от третьей группы. Если повезет, владельцы чипа - кто бы они ни были - подумают, что вторая группа пиратов уничтожила их грузовые корабли, а затем была уничтожена какими-то соперниками.\n\nУдачной охоты, приятель.\n\nВарланс", _X, _Y)
	_Mail.header = "План действий"
	_Mail.sender = "Варланс @FrostbiteCompany"
	_Mail.id = "_horizon_story3_mail1"
	_Player:addMail(_Mail)
end

mission.phases[1].playerCallbacks = {
	{
		name = "onMailRead",
		func = function(_PlayerIndex, _MailIndex)
			if onServer() then
				local _Player = Player()
				local _Mail = _Player:getMail(_MailIndex)
				if _Mail.id == "_horizon_story3_mail1" then
					nextPhase()
				end
			end
		end
	}
}

mission.phases[2] = {}
mission.phases[2].timers = {}
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
        mission.data.custom.secondLocation = kothStory3_getNextLocation(false)

        mission.data.description[5].arguments = { _X = mission.data.custom.secondLocation.x, _Y = mission.data.custom.secondLocation.y }
        sync()
    end
end

mission.phases[2].updateTargetLocationServer = function(_timestep)
    local _hsctimer = (mission.data.custom.hyperspaceCounter or 0) + _timestep
    mission.data.custom.hyperspaceCounter = _hsctimer

    local _FreighterCount = ESCCUtil.countEntitiesByValue("_horizon3_freighter")

    if _FreighterCount == 0 and mission.data.custom.transportsSpawned then
        setPhase(4) -- мы переходим сразу к фазе 4.
    end
end

--region #PHASE 2 TIMER CALLS

if onServer() then

mission.phases[2].timers[1] = {
    time = 15,
    callback = function()
        if atTargetLocation() and not mission.data.custom.transportsSpawned then
            mission.data.description[3].fulfilled = true
            mission.data.description[4].visible = true

            kothStory3_spawnTransports()
            kothStory3_spawnEscorts(6, true)
            
            mission.data.custom.hyperspaceCounter = 0
            mission.data.custom.transportsSpawned = true
            sync()
        end
    end,
    repeating = true
}

mission.phases[2].timers[2] = {
    time = 5,
    callback = function()
        if atTargetLocation() and mission.data.custom.transportsSpawned and mission.data.custom.hyperspaceCounter >= 180 then
            kothStory3_jumpTransports()
            
            mission.data.custom.hyperspaceCounter = 0

            nextPhase()
        end
    end,
    repeating = true
}

end

--endregion

mission.phases[3] = {}
mission.phases[3].timers = {}
mission.phases[3].showUpdateOnEnd = true
mission.phases[3].onBegin = function()
    local _MethodName = "Phase 3 On Begin"
    mission.Log(_MethodName, "Начинаем...")

    mission.data.location = mission.data.custom.secondLocation

    mission.data.description[4].fulfilled = true
    mission.data.description[5].visible = true
    mission.data.description[6].visible = true
end

mission.phases[3].onTargetLocationEntered = function(_x, _y)
    if onServer() then
        if not mission.data.custom.phase3PirateGroupSpawned then
            kothStory3_spawnEscorts(8, false)
            mission.data.custom.phase3PirateGroupSpawned = true
        end
        local _Freighters = { Sector():getEntitiesByScriptValue("_horizon3_freighter") }
        for _, _ship in pairs(_Freighters) do
            local _ShipAI = ShipAI(_ship)
            local _ShipPos = _ship.position

            _ShipAI:setFlyLinear(_ShipPos.look * 20000, 0, false)
        end
    end
end

mission.phases[3].updateTargetLocationServer = function(_timestep)
    local _hsctimer = (mission.data.custom.hyperspaceCounter or 0) + _timestep
    mission.data.custom.hyperspaceCounter = _hsctimer

    local _FreighterCount = ESCCUtil.countEntitiesByValue("_horizon3_freighter")

    if _FreighterCount == 0 and mission.data.custom.transportsSpawned then
        nextPhase()
    end
end

--region #PHASE 3 TIMER CALLS

if onServer() then

mission.phases[3].timers[2] = {
    time = 5,
    callback = function()
        if atTargetLocation() and mission.data.custom.transportsSpawned and mission.data.custom.hyperspaceCounter >= 180 then
            kothStory3_jumpTransports2() --Это проваливает миссию, поэтому не нужно ни о чем беспокоиться.
        end
    end,
    repeating = true
}

end

--endregion

mission.phases[4] = {}
mission.phases[4].timers = {}
mission.phases[4].showUpdateOnEnd = true
mission.phases[4].onBegin = function()
    local _MethodName = "Phase 4 On Begin"
    mission.Log(_MethodName, "Начинаем...")

    mission.data.location = nil

    mission.data.description[4].fulfilled = true
    mission.data.description[5].fulfilled = true
    mission.data.description[6].fulfilled = true
    mission.data.description[7].visible = true
end

mission.phases[4].onBeginServer = function()
    local _MethodName = "Phase 4 On Begin Server"
    mission.Log(_MethodName, "Начинаем...")

    mission.data.custom.thirdLocation = kothStory3_getNextLocation(false)
    
    local _X = mission.data.custom.thirdLocation.x
    local _Y = mission.data.custom.thirdLocation.y

    mission.data.description[8].arguments = { _X = mission.data.custom.firstLocation.x, _Y = mission.data.custom.firstLocation.y }
    
    --Отправить письмо игроку.
    local _Player = Player()
    local _Mail = Mail()
	_Mail.text = Format("Хорошие новости, приятель. Есть еще одна группа пиратов, которая собиралась соединиться с грузовыми кораблями, которые ты уничтожил. Если мы будем двигаться достаточно быстро, мы сможем застать их врасплох. Отправляйся в (%1%:%2%). Я встречу тебя там.\n\nКстати... ты заметил странный корабль в их караване? Он был в группе, которую я уничтожил - он не похож ни на один пиратский корабль, который я видел. Нам нужно больше информации. Постарайся оставить некоторых из них в живых, чтобы поговорить.\n\nВарланс", _X, _Y)
	_Mail.header = "Встреча"
	_Mail.sender = "Варланс @FrostbiteCompany"
	_Mail.id = "_horizon_story3_mail2"
	_Player:addMail(_Mail)

    _Player:setValue("_horizonkeepers_story3_cargolooted", true)
end

mission.phases[4].playerCallbacks = {
	{
		name = "onMailRead",
		func = function(_PlayerIndex, _MailIndex)
			if onServer() then
				local _Player = Player()
				local _Mail = _Player:getMail(_MailIndex)
				if _Mail.id == "_horizon_story3_mail2" then
					nextPhase()
				end
			end
		end
	}
}

mission.phases[5] = {}
mission.phases[5].timers = {}
mission.phases[5].sectorCallbacks = {}
mission.phases[5].showUpdateOnEnd = true
mission.phases[5].onBegin = function()
    local _MethodName = "Phase 5 On Begin"
    mission.Log(_MethodName, "Начинаем...")

    mission.data.location = mission.data.custom.thirdLocation

    mission.data.description[7].fulfilled = true
    mission.data.description[8].visible = true
end

mission.phases[5].onTargetLocationEntered = function(_x, _y)
    local _MethodName = "Phase 5 On Target Location Entered"
    mission.Log(_MethodName, "Начинаем...")

    mission.data.description[8].fulfilled = true
    mission.data.description[9].visible = true

    mission.data.custom.phase5MiniBossesSpawned = false
    mission.data.custom.phase5MiniBossTimer = 0
    mission.data.custom.phase5PirateKOd = false

    mission.data.custom.cleanUpSector = true

    if onServer() then
        kothStory3_spawnPirateGroup()
        kothStory3_spawnVarlance()
    end
end

mission.phases[5].onTargetLocationArrivalConfirmed = function(_x, _y)
    HorizonUtil.varlanceChatter("Я прикрою тебя, приятель. Надеюсь, ты прикроешь меня.")
end

mission.phases[5].updateTargetLocationServer = function(_timeStep)
    mission.data.custom.phase5MiniBossTimer = mission.data.custom.phase5MiniBossTimer + _timeStep
end

--region #PHASE 5 CALLBACK CALLS

mission.phases[5].sectorCallbacks[1] = {
    name = "onEntityKOed",
    func = function(_shipID, _reviveID)
        local _MethodName = "Phase 5 Custom Callback 1"
        mission.Log(_MethodName, "Вызываем.")
        mission.data.custom.phase5PirateKOd = true
    end
}

--endregion

--region #PHASE 5 TIMER CALLS

if onServer() then

mission.phases[5].timers[1] = {
    time = 10,
    callback = function()
        local _MethodName = "Phae 5 Timer 1 Callback"
        if atTargetLocation() and mission.data.custom.phase5MiniBossTimer >= 10 and not mission.data.custom.phase5MiniBossesSpawned then
            local _pirateCt = ESCCUtil.countEntitiesByValue("is_pirate")
            mission.Log(_MethodName, "Игрок находится в локации, а мини-боссы еще не появились - там " .. tostring(_pirateCt) .. " пиратов.")

            if _pirateCt <= 6 then
                kothStory3_spawnPirateBosses()

                HorizonUtil.varlanceChatter("Еще один Deadshot... Показания энергии от этого Bombardier вызывают беспокойство, однако. Будь начеку.")
            end
        end
    end,
    repeating = true
}

mission.phases[5].timers[2] = {
    time = 180, --У него нет ресурсов Адрианы, не может возродиться так быстро.
    callback = function()
        local _MethodName = "Phase 5 Timer 2 Callback"

        if atTargetLocation() then
            mission.Log(_MethodName, "В локации - возрождаем Варланса, если необходимо.")

            kothStory3_spawnVarlance()
        end
    end,
    repeating = true
}

mission.phases[5].timers[3] = {
    time = 10,
    callback = function()
        local _MethodName = "Phase 7 Timer 3 Callback"

        local _PirateCt = ESCCUtil.countEntitiesByValue("is_pirate")

        if atTargetLocation() and _PirateCt == 1 and mission.data.custom.phase5PirateKOd and mission.data.custom.phase5MiniBossesSpawned then
            nextPhase()
        end
    end,
    repeating = true
}

end

--endregion

mission.phases[6] = {}
mission.phases[6].onBegin = function()
    local _MethodName = "Phase 5 On Begin"
    mission.Log(_MethodName, "Начинаем...")

    mission.data.description[9].fulfilled = true
    mission.data.description[10].visible = true
end

mission.phases[6].onBeginServer = function()
    kothStory3_spawnVarlance()
    local _Pirates = { Sector():getEntitiesByScriptValue("is_pirate") }
    invokeClientFunction(Player(), "kothStory3_onPhase6PirateDialog", _Pirates[1].id, _Pirates[1].translatedTitle)
end

mission.phases[6].updateTargetLocationServer = function(_timeStep)
    --Дайте игроку несколько секунд, чтобы это обработать.
    if mission.data.custom.phase6VarlanceDialogAllowed then
        mission.data.custom.phase6VarlanceDialogTimer = mission.data.custom.phase6VarlanceDialogTimer + _timeStep

        if mission.data.custom.phase6VarlanceDialogAllowed and mission.data.custom.phase6VarlanceDialogTimer >= 5 then
            --мы уже в диалоге, поэтому нет необходимости разрешать его снова. Он БУДЕТ продолжать вызываться, если мы этого не сделаем.
            mission.data.custom.phase6VarlanceDialogAllowed = false 

            invokeClientFunction(Player(), "kothStory3_onPhase6VarlanceDialog", mission.data.custom.varlanceID)
        end
    end
end

local kothStory3_onPhase6PirateDialogEnd = makeDialogServerCallback("kothStory3_onPhase6PirateDialogEnd", 6, function()
    local _Pirates = { Sector():getEntitiesByScriptValue("is_pirate") }
    local _Pirate = _Pirates[1]

    _Pirate:removeScript("entity/utility/kobehavior.lua")

    local _PirateDura = Durability(_Pirate)
    _PirateDura.invincibility = 0.0

    _Pirate:destroy(mission.data.custom.varlanceID)

    mission.data.custom.phase6VarlanceDialogAllowed = true
end)

local kothStory3_onPhase6VarlanceDialogEnd = makeDialogServerCallback("kothStory3_onPhase6VarlanceDialogEnd", 6, function()
    local _Varlance = Entity(mission.data.custom.varlanceID)
    _Varlance:addScriptOnce("entity/utility/delayeddelete.lua", random():getFloat(4, 7))

    kothStory3_finishAndReward()
end)

--endregion

--region #SERVER CALLS

function kothStory3_getNextLocation(_onBlockRing)
    local _MethodName = "Get Next Location"
    
    mission.Log(_MethodName, "Получаем местоположение.")
    local x, y = Sector():getCoordinates()
    local target = {}

    if _onBlockRing then
        --Получить сектор, который очень близок к внешнему краю барьера.
        mission.Log(_MethodName, "BlockRingMax is " .. tostring(Balancing.BlockRingMax))
        local _Nx, _Ny = ESCCUtil.getPosOnRing(x, y, Balancing.BlockRingMax + 10)
        target.x, target.y = MissionUT.getEmptySector(_Nx,_Ny, 3, 6, false)
        local _safetyBreakout = 0
        while target.x == x and target.y == y and _safetyBreakout <= 100 do
            target.x, target.y = MissionUT.getEmptySector(_Nx,_Ny, 3, 6, false)
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
function kothStory3_spawnTransports()
    local _Sector = Sector()
    local _X, _Y = _Sector:getCoordinates()
    local _random = random()
    --Spawn 5 large freighters and 6 escorts. Start a jump timer that's equal to the # of shipment 1 jumps * 15 seconds.
    --Создать 5 больших грузовых кораблей и 6 эскортов. Запустить таймер прыжка, равный количеству прыжков 1-й партии * 15 секунд.
    local _SectorVol = Balancing_GetSectorShipVolume(_X, _Y)
    local _Vol1 = _SectorVol * 8
    local _Vol2 = _SectorVol * 11
    local _Faction = Galaxy():getPirateFaction(mission.data.custom.pirateLevel)

    local look = _random:getVector(-100, 100)
    local up = _random:getVector(-100, 100)
    local pos = vec3(0, 0, 0)
    local _Player = Player()
    local _Ship = Entity(_Player.craftIndex)

    if _Ship then
        pos = _Ship.translationf
    end

    local _basepos = ESCCUtil.getVectorAtDistance(pos, 4000, true)
    local _unit = 90
    local _p1 = vec3(_basepos.x + (_unit*2), _basepos.y + (_unit*1), _basepos.z + (_unit*1))
    local _p2 = vec3(_basepos.x, _basepos.y + (_unit*-1), _basepos.z)
    local _p3 = vec3(_basepos.x + (_unit*-2), _basepos.y + (_unit*-1), _basepos.z + (_unit*-1))
    local _p4 = vec3(_basepos.x + (_unit*-4), _basepos.y + (_unit*1), _basepos.z + (_unit*-1))
    local _p5 = vec3(_basepos.x + (_unit*-6), _basepos.y + (_unit*-1), _basepos.z + (_unit*1))

    local _Freighters = {}

    table.insert(_Freighters, ShipGenerator.createFreighterShip(_Faction, MatrixLookUpPosition(look, up, _p1), _Vol1))
    table.insert(_Freighters, ShipGenerator.createTradingShip(_Faction, MatrixLookUpPosition(look, up, _p2), _Vol1))
    table.insert(_Freighters, HorizonUtil.spawnHorizonFreighter(false, MatrixLookUpPosition(look, up, _p3), _Faction))
    table.insert(_Freighters, ShipGenerator.createFreighterShip(_Faction, MatrixLookUpPosition(look, up, _p4), _Vol2))
    table.insert(_Freighters, ShipGenerator.createFreighterShip(_Faction, MatrixLookUpPosition(look, up, _p5), _Vol2))

    for _, _ship in pairs(_Freighters) do
        _ship:setValue("_horizon3_freighter", true)
        _ship:setValue("is_pirate", true)
        _ship:setValue("bDisableXAI", true) --Disable any Xavorion AI
        --Отключить любой Xavorion AI
        ESCCUtil.removeCivilScripts(_ship)
        Boarding(_ship).boardable = false

        if not _Player:getValue("_horizonkeepers_story3_cargolooted") then
            ShipUtility.addCargoToCraft(_ship)
        end

        local _ShipAI = ShipAI(_ship)
        local _ShipPos = _ship.position

        _ShipAI:setPassiveShooting(true)
        _ShipAI:setFlyLinear(_ShipPos.look * 20000, 0, false)
    end

    shuffle(_random, _Freighters)

    if _Player:getValue("_horizonkeepers_story3_cargolooted") then
        ShipUtility.addCargoToCraft(_Freighters[1])
    end

    Сектор:broadcastChatMessage(_Freighters[1], ChatMessageType.Chatter, "Враги, здесь?! Как они нас нашли? Заряжайте гипердвигатели сейчас!")
end

function kothStory3_jumpTransports()
    local _Sector = Sector()
    local _Freighters = {_Sector:getEntitiesByScriptValue("_horizon3_freighter")}
    --This isn't timed for failure because of the amount of work the player has to do to get here. Imagine failing after going through phase 1-4.
    --Это не рассчитано на провал, потому что игроку приходится проделать много работы, чтобы добраться сюда. Представьте себе провал после прохождения фаз 1-4.
    --That would SUCK. So since we're not timed, we don't particularly care about getting a non-blocked jumping route. The player will have more than
    --Это было бы ОТСТОЙНО. Поэтому, поскольку у нас нет времени, нас не особо волнует получение незаблокированного маршрута прыжка. У игрока будет более чем
    --enough time to go around the rifts.
    --достаточно времени, чтобы обойти разломы.
    local _JumpTo = mission.data.custom.secondLocation

    --This should be one of the last things we do before syncing to prevent premature ending of the mission due to freighters still being left.
    --Это должно быть одним из последних действий, которые мы делаем перед синхронизацией, чтобы предотвратить преждевременное завершение миссии из-за оставшихся грузовых кораблей.
    for _, _F in pairs(_Freighters) do
        _Sector:transferEntity(_F, _JumpTo.x, _JumpTo.y, SectorChangeType.Jump)
    end

    sync()
    Player():sendChatMessage("Навигационный компьютер", 0, "Грузовые корабли перешли в \\s(%1%,%2%).", _JumpTo.x, _JumpTo.y)
end

function kothStory3_jumpTransports2()
    local _Sector = Sector()
    local _Freighters = {_Sector:getEntitiesByScriptValue("_horizon3_freighter")}

    for _, _F in pairs(_Freighters) do
        _F:addScriptOnce("utility/delayeddelete.lua", random():getFloat(2, 4))
    end

    Player():sendChatMessage("Варланс", 0, "Они достигли пункта назначения. Нам придется ударить по следующей партии.")
    fail()
end

function kothStory3_spawnEscorts(_EscortCt, _SpawnNearTransports)
    local _MethodName = "Spawn Shipment Escort"
    mission.Log(_MethodName, "Создание эскортов на уровне опасности " .. tostring(mission.data.custom.dangerLevel))

    --Pick a random transport and use that as the centerpiece in our formation. Spawn the pirates in a rough sphere around it.
    --Выберите случайный транспорт и используйте его в качестве центрального элемента в нашей формации. Создайте пиратов в приблизительной сфере вокруг него.
    local _Freighters = { Sector():getEntitiesByScriptValue("_horizon3_freighter") }
    shuffle(random(), _Freighters)
    local _Centerpos = _Freighters[1].translationf

    local _PirateGenerator = AsyncPirateGenerator(nil, kothStory3_onEscortsFinished)
    local _PirateTable = ESCCUtil.getStandardWave(mission.data.custom.dangerLevel, _EscortCt, "Standard")

    _PirateGenerator:startBatch()
    _PirateGenerator.pirateLevel = mission.data.custom.pirateLevel

    local _GetEscortPosition = function(_cpos, _pgen)
        return _pgen:getGenericPosition()
    end
    if _SpawnNearTransports then
        _GetEscortPosition = function(_cpos, _pgen)
            local vec = ESCCUtil.getVectorAtDistance(_cpos, 1000, false)
            local look = vec3(math.random(), math.random(), math.random())
            local up = vec3(math.random(), math.random(), math.random())

            return MatrixLookUpPosition(look, up, vec)
        end
    end

    for _, _Pirate in pairs(_PirateTable) do
        _PirateGenerator:createPirateByName(_Pirate, _GetEscortPosition(_Centerpos, _PirateGenerator))
    end

    _PirateGenerator:endBatch()
end

function kothStory3_onEscortsFinished(_Generated)
    local _MethodName = "On Freighter Escorts Generated"
    SpawnUtility.addEnemyBuffs(_Generated)

    Placer.resolveIntersections()
end

function kothStory3_spawnPirateGroup()
    local _PirateGenerator = AsyncPirateGenerator(nil, kothStory3_onPirateGroupFinished)
    local _PirateTable = ESCCUtil.getStandardWave(mission.data.custom.dangerLevel, 8, "Standard")

    _PirateGenerator:startBatch()
    _PirateGenerator.pirateLevel = mission.data.custom.pirateLevel

    for _, _Pirate in pairs(_PirateTable) do
        _PirateGenerator:createPirateByName(_Pirate, _PirateGenerator:getGenericPosition())
    end

    _PirateGenerator:endBatch()
end

function kothStory3_onPirateGroupFinished(_Generated)
    local _MethodName = "On Pirate Ambush Group Finished"
    _Generated[1]:addScriptOnce("entity/utility/kobehavior.lua")

    for _, pirate in pairs(_Generated) do
        MissionUT.deleteOnPlayersLeft(pirate)
    end

    SpawnUtility.addEnemyBuffs(_Generated)

    Placer.resolveIntersections()
end

function kothStory3_spawnPirateBosses()
    local _MethodName = "Spawn Shipment Escort"
    mission.Log(_MethodName, "Создание эскортов на уровне опасности " .. tostring(mission.data.custom.dangerLevel))
    local _PirateGenerator = AsyncPirateGenerator(nil, kothStory3_onPirateBossesSpawned)
    local _PirateTable = { "Devastator", "Devastator" }

    _PirateGenerator:startBatch()
    _PirateGenerator.pirateLevel = mission.data.custom.pirateLevel

    for _, _Pirate in pairs(_PirateTable) do
        _PirateGenerator:createPirateByName(_Pirate, _PirateGenerator:getGenericPosition())
    end

    _PirateGenerator:endBatch()
end

function kothStory3_spawnVarlance()
    local _MethodName = "Создать Варланса"
    
    local _spawnVarlance = true
    if mission.data.custom.varlanceID then
        local _Varlance = Entity(mission.data.custom.varlanceID)
        if _Varlance and valid(_Varlance) and not _Varlance:getValue("varlance_withdrawing") then
            _spawnVarlance = false
        end
    end

    if _spawnVarlance then
        mission.Log(_MethodName, "В секторе нет Варланса - создаю его.")

        local _Varlance = HorizonUtil.spawnVarlanceNormal(true)
        local _VarlanceAI = ShipAI(_Varlance)
    
        _VarlanceAI:setAggressive()

        mission.data.custom.varlanceID = _Varlance.index
    end
end

function kothStory3_onPirateBossesSpawned(_Generated)

    local _Deadshot = _Generated[1]
    local _Sector = Sector()
    local x, y = _Sector:getCoordinates()
    local _dpf = Balancing_GetSectorWeaponDPS(x, y) * 250

    local _LaserSniperValues = { --#LONGINUS_SNIPER
        _DamagePerFrame = _dpf,
        _TimeToActive = 10,
        _TargetCycle = 15,
        _TargetingTime = 2.25, --Take longer than normal to target.
        --Требуется больше времени, чем обычно, для прицеливания.
        _TargetPriority = 1,
        _UseEntityDamageMult = true
    }

    ESCCUtil.setDeadshot(_Deadshot)
    _Deadshot:addScriptOnce("lasersniper.lua", _LaserSniperValues)
    _Deadshot:addScriptOnce("player/missions/horizon/story3/horizonstory3miniboss.lua")

    local _Bombard = _Generated[2]

    local _TorpSlamValues = {
        _ROF = 4,
        _DurabilityFactor = 2,
        _TimeToActive = 10,
        _TargetPriority = 4,
        _UseEntityDamageMult = true,
        _PreferBodyType = 6, --Panther
        --Panther
        _PreferWarheadType = 10 --Anti-matter.
        --Антиматерия.
    }

    ESCCUtil.setBombardier(_Bombard)
    _Bombard:addScriptOnce("torpedoslammer.lua", _TorpSlamValues)
    _Bombard:addScriptOnce("player/missions/horizon/story3/horizonstory3miniboss.lua")

    for _, pirate in pairs(_Generated) do
        MissionUT.deleteOnPlayersLeft(pirate)
    end

    SpawnUtility.addEnemyBuffs(_Generated)

    mission.data.custom.phase5MiniBossesSpawned = true
end

function kothStory3_handleSectorCleanup(cleanAll)
    if atTargetLocation() then
        ESCCUtil.allPiratesDepart()
    end
    if mission.internals.phaseIndex >= 5 and mission.data.location then
        runFullSectorCleanup(cleanAll)
    end
end

function kothStory3_finishAndReward()
    local _MethodName = "Finish and Reward"
    mission.Log(_MethodName, "Выполнение условия победы.")

    local _player = Player()

    local _AccomplishMessage = "Компания Frostbite благодарит вас. Вот ваша компенсация."
    local _BaseReward = 14000000

    _player:setValue("_horizonkeepers_story_stage", 4)

    _player:sendChatMessage("Frostbite Company", 0, _AccomplishMessage)
    mission.data.reward = {credits = _BaseReward, paymentMessage = "Заработано %1% кредитов за уничтожение пиратских грузовых кораблей." }

    HorizonUtil.addFriendlyFactionRep(_player, 12500)

    reward()
    accomplish()
end

--endregion

--region #CLIENT / SERVER DIALOG CALLS

function kothStory3_onPhase6PirateDialog(_PirateID, _PirateTitle)
    local d0 = {}
    local d1 = {}
    local d2 = {}
    local d3 = {}
    local d4 = {}
    local d5 = {}
    local d6 = {}
    local d7 = {}
    local d8 = {}
    local d9 = {}
    local d10 = {}
    local d11 = {}
    local d12 = {}
    local d13 = {}
    local d14 = {}
    local d15 = {}
    local d16 = {}

    --branch for 'where are the keepers?'
    --ветвь для 'где хранители?'
    local d11_a_1 = {}
    --branch for 'why did you turn to piracy?'
    --ветвь для 'почему вы обратились к пиратству?'
    local d11_b_1 = {}
    local d11_b_2 = {}

    d0.text = "Тч. Вы победили. Пришли поиздеваться перед тем, как убить нас?"
    d0.followUp = d1

    d1.text = "Для вас может быть выход. Расскажите нам то, что мы хотим знать." --v
    d1.followUp = d2

    d2.text = "Почему мы должны сотрудничать с вами?"
    d2.followUp = d3

    d3.text = "Поставим вопрос так. Сотрудничайте с нами, вы можете жить. Не будете, умрете. Чувствуете себя счастливчиком?" --v
    d3.followUp = d4

    d4.text = "... Ладно. Что вы хотите знать?"
    d4.answers = {
        { answer = "Что это был за странный корабль?", followUp = d5 }
    }

    d5.text = "Я понятия не имею, о чем вы говорите."
    d5.answers = {
        { answer = "Он был быстрым и тяжело бронированным.", followUp = d6 }
    }

    d6.text = "О да. Потому что это сильно сужает круг поиска."
    d6.answers = {
        { answer = "Он был зеленым и оранжевым.", followUp = d7 }
    }

    d7.text = "... А. Этот."
    d7.followUp = d8

    d8.text = "Это был грузовой корабль от одного из наших деловых партнеров. Крепче, чем то, к чему вы привыкли, да?"
    d8.answers = {
        { answer = "Расскажите нам о ваших деловых партнерах.", followUp = d9 }
    }

    d9.text = "Они хранители горизонта. Те, кто увидел дальше мелких дрязг в этой галактике и нашел способ превзойти их."
    d9.answers = {
        { answer = "Хватит говорить загадками.", followUp = d10 }
    }

    d10.text = "Нет. Компания буквально называется Horizon Keepers, LTD. Вы можете поискать ее сами."
    d10.followUp = d11

    d11.text = "... Что-нибудь еще?"
    d11.answers = {
        { answer = "Где хранители?", followUp = d11_a_1 },
        { answer = "Почему вы обратились к пиратству?", followUp = d11_b_1 },
        { answer = "Вы готовы умереть?", followUp = d12 }
    }

    d11_a_1.text = "Хех. Вы думаете, они бы сказали кому-то вроде меня? Вне вашей досягаемости, капитан. Вне вашей досягаемости."
    d11_a_1.followUp = d11

    d11_b_1.text = "Разве это не очевидно? Жадные фракции высасывают все ресурсы, которые видят. Они обогащаются за счет остальных из нас. Мы отбросы, брошенные галактическим порядком, который вы так цените."
    d11_b_1.followUp = d11_b_2

    d11_b_2.text = "Какой у нас еще выбор?"
    d11_b_2.followUp = d11

    d12.text = "Подождите."
    d12.followUp = d13

    d13.text = "Вы сказали, что пощадите нас, если мы будем сотрудничать."
    d13.followUp = d14

    d14.text = "Вы сдержите свое обещание и отпустите нас? Если вы думаете, что сможете заставить нас унижаться ради нашей жизни, вы ошибаетесь."
    d14.followUp = d15

    local d15values = { _PIRATE = _PirateTitle }
    d15.text = "Я ничего такого не говорил. Оружие, полный залп по ${_PIRATE}." % d15values
    d15.followUp = d16

    d16.text = "Я должен был знать. Увидимся в аду, кусок д-"
    d16.onEnd = kothStory3_onPhase6PirateDialogEnd

    ESCCUtil.setTalkerTextColors({d1, d3, d15}, "Varlance", HorizonUtil.getDialogVarlanceTalkerColor(), HorizonUtil.getDialogVarlanceTextColor())

    --Fade out the music, then show the script.
    --Заглушить музыку, затем показать скрипт.
    Music():fadeOut(1.5)

    ScriptUI(_PirateID):interactShowDialog(d0, false)
end

function kothStory3_onPhase6VarlanceDialog(_VarlanceID)
    local d0 = {}
    local d1 = {}
    local d2 = {}
    local d3 = {}
    local d4 = {}
    local d5 = {}
    local d6 = {}
    local d7 = {}
    local d8 = {}
    local d9 = {}
    local d10 = {}
    local d11 = {}

    d0.text = "Horizon Keepers, LTD, да?"
    d0.followUp = d1

    d1.text = "Мне придется их изучить. Любая информация, полученная под дулом пистолета, подозрительна."
    d1.followUp = d2

    d2.text = "Пока будьте начеку. Я свяжусь с вами."
    d2.answers = {
        { answer = "Понял.", onSelect = kothStory3_onPhase6VarlanceDialogEnd },
        { answer = "Подождите.", followUp = d3 }
    }

    d3.text = "... Хммм? Что у вас на уме?"
    d3.answers = {
        { answer = "Почему вы убили этих пиратов?", followUp = d4 },
        { answer = "Неважно.", onSelect = kothStory3_onPhase6VarlanceDialogEnd }
    }

    d4.text = "Они мусор. Вы можете приводить любые социально-экономические аргументы, какие захотите - галактике лучше без таких, как они."
    d4.answers = {
        { answer = "Они были беззащитны.", followUp = d5 },
        { answer = "Вы правы.", onSelect = kothStory3_onPhase6VarlanceDialogEnd }
    }

    d5.text = "Хм. Не размякайте сейчас, приятель. Вы когда-нибудь слышали историю о Своксе? Не о подражателе в железных пустошах... о первом."
    d5.followUp = d6

    d6.text = "Действительно мерзкий тип. Брал людей в заложники. Пытал и убивал всех, кто осмеливался перейти ему дорогу. Легче перечислить преступления, которые он не совершал."
    d6.followUp = d7

    d7.text = "Некоторое время назад его поймал какой-то капитан. Настоящий благодетель. Отвез его в местный военный форпост и бросил там."
    d7.followUp = d8

    d8.text = "В течение недели он сбежал и вернулся к своим старым трюкам. Грабил и убивал, как будто ксотаны вернутся завтра."
    d8.followUp = d9

   d9.text = "Он нашел капитана, который его поймал. Убил всю его семью. Заставил его смотреть записи, а затем выбросил в космос. Новости не умолкали об этом месяцами."
    d9.followUp = d10

    d10.text = "Вы думаете, что пираты проявили бы к вам такую же милость, если бы вы оказались на другом конце лезвия? Я гарантирую вам, что нет."
    d10.followUp = d11

    d11.text = "Я свяжусь с вами."
    d11.onEnd = kothStory3_onPhase6VarlanceDialogEnd

    ESCCUtil.setTalkerTextColors({d0, d1, d2, d3, d4, d5, d6, d7, d8, d9, d10, d11}, "Varlance", HorizonUtil.getDialogVarlanceTalkerColor(), HorizonUtil.getDialogVarlanceTextColor())

    ScriptUI(_VarlanceID):interactShowDialog(d0, false)
end

--endregion